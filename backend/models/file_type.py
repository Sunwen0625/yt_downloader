from pydantic import BaseModel
from typing import Optional


def format_duration(seconds) -> str:
    """轉換時間

    Args:
        seconds (str): 從yt-dlp 取得的時間

    Returns:
        str: 格式化後的時間，格式為 HH:MM:SS 或 MM:SS
    """
    seconds = int(seconds or 0)
    hours, remainder = divmod(seconds, 3600)
    minutes, secs = divmod(remainder, 60)
    if hours:
        return f'{hours:02d}:{minutes:02d}:{secs:02d}'
    return f'{minutes:02d}:{secs:02d}'


class FormatInfo(BaseModel):
    """影片資訊規格

    Args:
        BaseModel (_type_): _description_
    """
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
    """影片列表接口

    Args:
        BaseModel (_type_): _description_
    """
    id: str
    title: str
    duration: str
    thumbnail: str
    url: str


class PlaylistInfo(BaseModel):
    """播放列表資訊

    Args:
        BaseModel (_type_): _description_
    """
    playlist_id: str
    playlist_title: str
    videos: list[PlaylistVideo]
