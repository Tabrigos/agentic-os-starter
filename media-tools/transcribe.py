#!/usr/bin/env python3
"""Scarica metadati e trascrizione di un video YouTube.

Uso:   transcribe.py URL [--force-whisper]
Output in /work/<video_id>/: metadata.json, transcript.txt

Strategia captions-first: sottotitoli YouTube se esistono (manuali, poi
automatici), altrimenti download audio + faster-whisper su CPU (modello da
env WHISPER_MODEL, default "small"). In entrambe le vie i segmenti sponsor,
autopromo, intro/outro segnalati dal database SponsorBlock vengono scartati.
"""
import json
import os
import re
import sys
import urllib.parse
import urllib.request
from pathlib import Path

import yt_dlp

WORK = Path("/work")
SPONSORBLOCK_CATS = ["sponsor", "selfpromo", "interaction", "intro", "outro"]
SUB_LANGS = ["en", "it"]
MIN_TRANSCRIPT_CHARS = 200  # sotto questa soglia i sottotitoli sono considerati inutilizzabili


def sponsorblock_segments(video_id):
    url = (
        "https://sponsor.ajay.app/api/skipSegments?videoID=" + video_id
        + "&categories=" + urllib.parse.quote(json.dumps(SPONSORBLOCK_CATS))
    )
    try:
        with urllib.request.urlopen(url, timeout=10) as r:
            data = json.load(r)
        return [(s["segment"][0], s["segment"][1]) for s in data]
    except Exception:
        return []  # 404 = nessun segmento segnalato per questo video


def in_segments(t, segments):
    return any(a <= t <= b for a, b in segments)


def parse_vtt(path, segments):
    """Testo pulito da un .vtt: via tag, timestamp, righe duplicate e segmenti sponsor."""
    ts = re.compile(r"(\d+):(\d+):(\d+)\.\d+ -->")
    text_lines, seen = [], set()
    cur_start = None
    for line in Path(path).read_text(encoding="utf-8", errors="ignore").splitlines():
        m = ts.match(line.strip())
        if m:
            h, mnt, s = (int(x) for x in m.groups())
            cur_start = h * 3600 + mnt * 60 + s
            continue
        line = re.sub(r"<[^>]+>", "", line).strip()
        if not line or "-->" in line or line.startswith(("WEBVTT", "Kind:", "Language:")):
            continue
        if cur_start is not None and in_segments(cur_start, segments):
            continue
        if line not in seen:  # i vtt automatici di YouTube ripetono le righe
            seen.add(line)
            text_lines.append(line)
    return "\n".join(text_lines)


def main():
    if len(sys.argv) < 2:
        print("uso: transcribe.py URL [--force-whisper]", file=sys.stderr)
        sys.exit(2)
    url = sys.argv[1]
    force_whisper = "--force-whisper" in sys.argv

    with yt_dlp.YoutubeDL({"skip_download": True, "quiet": True}) as ydl:
        info = ydl.extract_info(url, download=False)
    vid = info["id"]
    out = WORK / vid
    out.mkdir(parents=True, exist_ok=True)

    meta = {k: info.get(k) for k in (
        "id", "title", "channel", "upload_date", "duration", "webpage_url", "language")}
    segments = sponsorblock_segments(vid)
    meta["sponsorblock_segments"] = len(segments)

    transcript, source = None, None

    if not force_whisper:
        # una lingua alla volta: chiederne piu' d'una insieme provoca 429 da YouTube
        for lang in SUB_LANGS:
            subs_opts = {
                "skip_download": True, "writesubtitles": True, "writeautomaticsub": True,
                "subtitleslangs": [lang], "subtitlesformat": "vtt",
                "outtmpl": str(out / "subs"), "quiet": True, "ignoreerrors": True,
            }
            try:
                with yt_dlp.YoutubeDL(subs_opts) as ydl:
                    ydl.download([url])
            except Exception:
                pass  # sottotitoli mancanti o rate-limit: si prova la lingua dopo
            vtts = sorted(out.glob("subs*.vtt"))
            if vtts:
                transcript = parse_vtt(vtts[0], segments)
                source = f"sottotitoli YouTube ({vtts[0].name})"
                break

    if not transcript or len(transcript) < MIN_TRANSCRIPT_CHARS:
        audio_opts = {
            "format": "bestaudio/best",
            "outtmpl": str(out / "audio.%(ext)s"), "quiet": True,
        }
        with yt_dlp.YoutubeDL(audio_opts) as ydl:
            ydl.download([url])
        audio = next(out.glob("audio.*"))
        from faster_whisper import WhisperModel
        model_name = os.environ.get("WHISPER_MODEL", "small")
        model = WhisperModel(model_name, device="cpu", compute_type="int8")
        segs, _ = model.transcribe(str(audio))
        lines = [s.text.strip() for s in segs if not in_segments(s.start, segments)]
        transcript = "\n".join(lines)
        source = f"faster-whisper {model_name} (cpu)"
        audio.unlink()  # l'audio non serve piu'

    (out / "transcript.txt").write_text(transcript, encoding="utf-8")
    meta["transcript_source"] = source
    (out / "metadata.json").write_text(
        json.dumps(meta, ensure_ascii=False, indent=2), encoding="utf-8")

    print(json.dumps({
        "id": vid, "title": meta["title"], "source": source,
        "chars": len(transcript), "sponsorblock": len(segments),
        "outdir": f"media-work/{vid}",
    }, ensure_ascii=False))


if __name__ == "__main__":
    main()
