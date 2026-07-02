# YT Downloader

YouTube 影片下載器後端 API，基於 **FastAPI** 與 **yt-dlp** 實現串流代理下載（不佔用伺服器硬碟空間）。

## 功能

- 取得播放清單／頻道影片列表
- 取得單一影片資訊與可用格式
- 串流下載影片或音檔

## 技術棧

| 套件 | 用途 |
|------|------|
| FastAPI | Web 框架 |
| uvicorn | ASGI 伺服器 |
| yt-dlp | YouTube 資料提取與串流 |

## API 端點

### `GET /playlist`
取得播放清單或頻道內的所有影片。

| 參數 | 型態 | 說明 |
|------|------|------|
| `url` | query | YouTube 播放清單或頻道網址 |
| `list` | query | 播放清單 ID（當 `url` 被截斷時作為備援） |

### `GET /video/info`
取得單一影片的詳細資訊與可用格式。

| 參數 | 型態 | 說明 |
|------|------|------|
| `url` | query | YouTube 影片網址 |

**回應欄位：**
- `combined_formats` — 影音合一格式
- `video_formats` — 純影片格式（無音軌）
- `audio_formats` — 純音訊格式

### `GET /video/download`
串流下載指定格式的影片或音檔。  
（不佔用伺服器磁碟，直接代理 YouTube 串流至客戶端）

| 參數 | 型態 | 說明 |
|------|------|------|
| `url` | query | YouTube 影片網址 |
| `format_id` | query | 要下載的格式 ID（從 `/video/info` 取得） |

## 快速開始

### 前置需求

- Python 3.11+
- Poetry（建議）或 pip

### 安裝

```bash
cd backend
poetry install
```

### 啟動

```bash
poetry run uvicorn main:app --host 127.0.0.1 --port 8000 --reload
```

或直接執行：

```bash
poetry run python main.py
```

服務將啟動於 `http://127.0.0.1:8000`，API 文件可於 `http://127.0.0.1:8000/docs` 檢視。

## 使用範例

### 取得播放清單

```bash
curl "http://127.0.0.1:8000/playlist?url=https://www.youtube.com/playlist?list=YOUR_PLAYLIST_ID"
```

### 取得影片資訊

```bash
curl "http://127.0.0.1:8000/video/info?url=https://www.youtube.com/watch?v=VIDEO_ID"
```

### 下載影片

```bash
curl -o "output.mp4" "http://127.0.0.1:8000/video/download?url=https://www.youtube.com/watch?v=VIDEO_ID&format_id=18"
```
