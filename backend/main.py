from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware

from services.playlist import get_playlist
from services.info import get_video_info
from services.download import stream_download

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


if __name__ == '__main__':
    import uvicorn
    uvicorn.run('main:app', host='127.0.0.1', port=8000, reload=True)
