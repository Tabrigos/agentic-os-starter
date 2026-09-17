FROM python:3.12-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ffmpeg curl unzip \
    && rm -rf /var/lib/apt/lists/*

# deno: runtime JS richiesto da yt-dlp per l'estrazione YouTube affidabile
RUN curl -fsSL https://deno.land/install.sh | sh -s -- -y \
    && ln -s /root/.deno/bin/deno /usr/local/bin/deno

RUN pip install --no-cache-dir yt-dlp faster-whisper "markitdown[docx,pdf,pptx,xlsx]"

COPY transcribe.py estrai.py run.py /app/

WORKDIR /work
# run.py smista: URL -> transcribe.py (video), percorso -> estrai.py (documenti)
ENTRYPOINT ["python", "/app/run.py"]
