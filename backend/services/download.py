import os
import re
import shutil
import tempfile
import yt_dlp
from fastapi import HTTPException
from fastapi.responses import StreamingResponse


def _sanitize_filename(title: str) -> str:
    return re.sub(r'[\\/*?:"<>|]', '', title).strip() or 'video'


def stream_download(url: str, format_id: str) -> StreamingResponse:
    ydl_opts = {
        'format': format_id,
        'noplaylist': True,
        'quiet': True,
        'no_warnings': True,
        'nocheckcertificate': True,
    }

    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        info = ydl.extract_info(url, download=False)

        if 'requested_formats' in info:
            stream_url = info['requested_formats'][0].get('url')
            ext = info['requested_formats'][0].get('ext', info.get('ext', 'mp4'))
        else:
            stream_url = info.get('url')
            ext = info.get('ext', 'mp4')

        if not stream_url:
            raise HTTPException(
                status_code=400,
                detail='Selected format does not support direct streaming. Try a combined format (e.g. 22, 18).',
            )

        title = info.get('title', 'video')

    content_type_map = {
        'mp4': 'video/mp4',
        'm4a': 'audio/mp4',
        'webm': 'video/webm',
        'opus': 'audio/opus',
        'mp3': 'audio/mpeg',
        '3gp': 'video/3gpp',
    }
    content_type = content_type_map.get(ext, 'application/octet-stream')

    response = ydl.urlopen(stream_url)

    def iter_file():
        while True:
            chunk = response.read(8192)
            if not chunk:
                break
            yield chunk

    sanitized_title = _sanitize_filename(title)
    return StreamingResponse(
        iter_file(),
        media_type=content_type,
        headers={
            'Content-Disposition': f'attachment; filename="{sanitized_title}.{ext}"'
        },
    )


def download_video(url: str, fmt: str, quality: str, output_dir: str) -> str:
    height = quality.replace('p', '')
    format_id = f'bestvideo[ext={fmt}][height<={height}]+bestaudio[ext=m4a]/best[ext={fmt}][height<={height}]'
    ydl_opts = {
        'format': format_id,
        'outtmpl': os.path.join(output_dir, '%(title)s.%(ext)s'),
        'merge_output_format': fmt,
        'noplaylist': True,
        'quiet': True,
        'no_warnings': True,
        'nocheckcertificate': True,
    }
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        info = ydl.extract_info(url, download=True)
        title = _sanitize_filename(info.get('title', 'video'))
        ext = info.get('ext', fmt)
    return f'{title}.{ext}'


def download_mp3(url: str, output_dir: str) -> str:
    tmpdir = tempfile.mkdtemp()
    try:
        ydl_opts = {
            'format': 'bestaudio/best',
            'outtmpl': os.path.join(tmpdir, '%(title)s.%(ext)s'),
            'postprocessors': [{
                'key': 'FFmpegExtractAudio',
                'preferredcodec': 'mp3',
            }],
            'noplaylist': True,
            'quiet': True,
            'no_warnings': True,
            'nocheckcertificate': True,
        }
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=True)
            title = _sanitize_filename(info.get('title', 'video'))

        mp3_file = None
        for f in os.listdir(tmpdir):
            if f.endswith('.mp3'):
                mp3_file = f
                break

        if not mp3_file:
            raise HTTPException(status_code=400, detail='Failed to convert audio to MP3')

        dest = os.path.join(output_dir, f'{title}.mp3')
        shutil.move(os.path.join(tmpdir, mp3_file), dest)
        return f'{title}.mp3'
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)
