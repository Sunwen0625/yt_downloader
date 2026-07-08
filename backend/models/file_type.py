from pydantic import BaseModel
from typing import Optional


def format_duration(seconds) -> str:
    seconds = int(seconds or 0)
    hours, remainder = divmod(seconds, 3600)
    minutes, secs = divmod(remainder, 60)
    if hours:
        return f'{hours:02d}:{minutes:02d}:{secs:02d}'
    return f'{minutes:02d}:{secs:02d}'


class FormatInfo(BaseModel):
    format_id: str
    ext: str
    quality: str
    filesize: Optional[int] = None
    vcodec: Optional[str] = None
    acodec: Optional[str] = None
    fps: Optional[float] = None
    has_video: bool = False
    has_audio: bool = False


class VideoInfo(BaseModel):
    id: str
    title: str
    duration: str
    thumbnail: str
    description: Optional[str] = None
    uploader: Optional[str] = None
    upload_date: Optional[str] = None
    combined_formats: list[FormatInfo] = []
    video_formats: list[FormatInfo] = []
    audio_formats: list[FormatInfo] = []


class PlaylistVideo(BaseModel):
    id: str
    title: str
    duration: str
    thumbnail: str
    url: str


class PlaylistInfo(BaseModel):
    playlist_id: str
    playlist_title: str
    videos: list[PlaylistVideo]
