import yt_dlp
from fastapi import HTTPException
from fastapi.responses import StreamingResponse


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

    sanitized_title = title.replace('"', "'").replace('/', '_')
    return StreamingResponse(
        iter_file(),
        media_type=content_type,
        headers={
            'Content-Disposition': f'attachment; filename="{sanitized_title}.{ext}"'
        },
    )
