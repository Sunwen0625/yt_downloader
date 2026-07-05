import os
from fastapi import FastAPI, HTTPException, Query, Request
from fastapi.middleware.cors import CORSMiddleware

from services.playlist import get_playlist
from services.info import get_video_info
from services.download import stream_download, download_video, download_mp3
from services.settings import load_settings, save_settings, Settings

app = FastAPI(title='YT Downloader API')

app.add_middleware(
    CORSMiddleware,
    allow_origins=['*'],
    allow_methods=['*'],
    allow_headers=['*'],
)


@app.get('/playlist')
def playlist(
    url: str = Query(..., description='YouTube playlist or channel URL'),
    playlist_id: str = Query(None, alias='list', description='Playlist ID (fallback when url param gets truncated)'),
):
    try:
        if playlist_id and 'list=' not in url:
            url = f'{url}&list={playlist_id}' if '?' in url else f'https://www.youtube.com/playlist?list={playlist_id}'
        return get_playlist(url)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get('/video/info')
def video_info(url: str = Query(..., description='YouTube video URL')):
    try:
        return get_video_info(url)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get('/video/download')
def video_download(
    url: str = Query(..., description='YouTube video URL'),
    format_id: str = Query(..., description='Format ID from /video/info endpoint'),
):
    try:
        return stream_download(url, format_id)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.post('/video/download')
async def video_download_post(request: Request):
    try:
        body = await request.json()
        video_id = body['video_id']
        fmt = body.get('format', 'mp4')
        quality = body.get('quality', '720p')

        url = f'https://youtube.com/watch?v={video_id}'
        settings = load_settings()
        output_dir = settings.download_path
        os.makedirs(output_dir, exist_ok=True)

        if fmt == 'mp3':
            filename = download_mp3(url, output_dir)
        else:
            filename = download_video(url, fmt, quality, output_dir)

        return {'success': True, 'filename': filename}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get('/settings')
def get_settings():
    s = load_settings()
    return {'download_path': s.download_path}


@app.put('/settings')
def update_settings(data: dict):
    download_path = data.get('download_path', '')
    if not download_path:
        raise HTTPException(status_code=400, detail='download_path is required')
    os.makedirs(download_path, exist_ok=True)
    save_settings(Settings(download_path=download_path))
    return {'success': True, 'download_path': download_path}


if __name__ == '__main__':
    import uvicorn
    uvicorn.run('main:app', host='127.0.0.1', port=8000, reload=True)
