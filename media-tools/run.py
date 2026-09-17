#!/usr/bin/env python3
"""Dispatcher di media-tools: stesso comando per video e documenti.

URL http(s)  -> transcribe.py (video YouTube)
percorso file -> estrai.py    (docx, pdf, txt, ...)
"""
import runpy
import sys

if len(sys.argv) < 2:
    sys.exit("uso: run.py <url YouTube | percorso documento> [opzioni]")

if sys.argv[1].startswith(("http://", "https://")):
    runpy.run_path("/app/transcribe.py", run_name="__main__")
else:
    runpy.run_path("/app/estrai.py", run_name="__main__")
