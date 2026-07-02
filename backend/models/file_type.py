from pydantic import BaseModel
from typing import Optional


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
    duration: int
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
    duration: int
    thumbnail: str
    url: str


class PlaylistInfo(BaseModel):
    playlist_id: str
    playlist_title: str
    videos: list[PlaylistVideo]
