import urllib.parse
import yt_dlp

from models.file_type import PlaylistInfo, PlaylistVideo


def _normalize_playlist_url(url: str) -> str:
    parsed = urllib.parse.urlparse(url)
    params = urllib.parse.parse_qs(parsed.query)
    if 'list' in params:
        playlist_id = params['list'][0]
        return f'https://www.youtube.com/playlist?list={playlist_id}'
    return url


def get_playlist(url: str) -> PlaylistInfo:
    playlist_url = _normalize_playlist_url(url)

    ydl_opts = {
        'quiet': True,
        'no_warnings': True,
        'extract_flat': True,
        'nocheckcertificate': True,
    }

    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        info = ydl.extract_info(playlist_url, download=False)

    if 'entries' not in info:
        return PlaylistInfo(
            playlist_id=info.get('id', ''),
            playlist_title=info.get('title', 'Single Video'),
            videos=[
                PlaylistVideo(
                    id=info.get('id', ''),
                    title=info.get('title', 'Unknown'),
                    duration=info.get('duration', 0),
                    thumbnail=info.get('thumbnail', ''),
                    url=info.get('webpage_url', url),
                )
            ],
        )

    playlist_id = info.get('id', '')
    playlist_title = info.get('title', 'Untitled')

    videos = []
    for entry in info.get('entries', []):
        if entry is None:
            continue
        video_id = entry.get('id', '')
        videos.append(
            PlaylistVideo(
                id=video_id,
                title=entry.get('title', 'Unknown'),
                duration=entry.get('duration', 0),
                thumbnail=entry.get('thumbnail', f"https://img.youtube.com/vi/{video_id}/maxresdefault.jpg"),
                url=entry.get('url', f'https://youtube.com/watch?v={video_id}'),
            )
        )

    return PlaylistInfo(
        playlist_id=playlist_id,
        playlist_title=playlist_title,
        videos=videos,
    )
