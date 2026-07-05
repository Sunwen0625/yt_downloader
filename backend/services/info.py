import yt_dlp

from models.file_type import VideoInfo, FormatInfo, format_duration


def get_video_info(url: str) -> VideoInfo:
    ydl_opts = {
        'quiet': True,
        'no_warnings': True,
        'noplaylist': True,
        'nocheckcertificate': True,
    }

    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        info = ydl.extract_info(url, download=False)

    combined = []
    video_only = []
    audio_only = []

    for fmt in info.get('formats', []):
        has_video = fmt.get('vcodec', 'none') != 'none'
        has_audio = fmt.get('acodec', 'none') != 'none'

        quality = (
            fmt.get('format_note')
            or (str(fmt.get('height', '')) + 'p' if fmt.get('height') else '')
            or (str(fmt.get('abr', '')) + 'k' if fmt.get('abr') else '')
            or 'unknown'
        )

        format_info = FormatInfo(
            format_id=str(fmt['format_id']),
            ext=fmt.get('ext', ''),
            quality=quality,
            filesize=fmt.get('filesize') or fmt.get('filesize_approx'),
            vcodec=fmt.get('vcodec'),
            acodec=fmt.get('acodec'),
            fps=fmt.get('fps'),
            has_video=has_video,
            has_audio=has_audio,
        )

        if has_video and has_audio:
            combined.append(format_info)
        elif has_video and not has_audio:
            video_only.append(format_info)
        elif has_audio and not has_video:
            audio_only.append(format_info)

    return VideoInfo(
        id=info.get('id', ''),
        title=info.get('title', ''),
        duration=format_duration(info.get('duration')),
        thumbnail=info.get('thumbnail', ''),
        description=info.get('description', ''),
        uploader=info.get('uploader', ''),
        upload_date=info.get('upload_date', ''),
        combined_formats=combined,
        video_formats=video_only,
        audio_formats=audio_only,
    )
