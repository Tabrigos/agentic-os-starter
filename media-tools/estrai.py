#!/usr/bin/env python3
"""Estrae testo markdown da un documento (docx, pptx, xlsx, pdf, txt, md).

Uso:   estrai.py /vault/00-Inbox/documento.docx
Output in /work/<slug>/: metadata.json, estratto.md

Gemello di transcribe.py per le fonti-documento: l'orchestratore passa il
percorso (il vault è montato in sola lettura su /vault), il distillatore
lavora poi su estratto.md. I formati già testuali passano invariati.
"""
import json
import re
import shutil
import sys
from pathlib import Path

WORK = Path("/work")
PASSTHROUGH = {".txt", ".md", ".markdown"}


def slugify(name):
    s = re.sub(r"[^\w\-]+", "-", name.strip().lower()).strip("-")
    return s[:60] or "documento"


def main():
    if len(sys.argv) < 2:
        sys.exit("uso: estrai.py <percorso documento>")
    src = Path(sys.argv[1])
    if not src.exists():
        sys.exit(f"file non trovato: {src}")

    outdir = WORK / slugify(src.stem)
    outdir.mkdir(parents=True, exist_ok=True)
    dest = outdir / "estratto.md"

    ext = src.suffix.lower()
    if ext in PASSTHROUGH:
        shutil.copyfile(src, dest)
        metodo = "copia diretta"
    else:
        from markitdown import MarkItDown
        result = MarkItDown().convert(str(src))
        dest.write_text(result.text_content, encoding="utf-8")
        metodo = "markitdown"

    testo = dest.read_text(encoding="utf-8", errors="ignore")
    meta = {"file": src.name, "estensione": ext, "metodo": metodo, "chars": len(testo)}
    (outdir / "metadata.json").write_text(
        json.dumps(meta, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(json.dumps({**meta, "outdir": f"media-work/{outdir.name}"}, ensure_ascii=False))


main()
