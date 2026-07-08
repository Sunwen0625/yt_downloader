# YT Downloader Frontend

Flutter 跨平台桌面應用，為 [YT Downloader](../README.md) 後端提供圖形化操作介面。

## 功能

- **貼入網址、解析清單** — 支援 YouTube 影片、播放清單與頻道網址
- **影片列表** — 顯示縮圖、標題、長度，可選擇格式（MP3 / MP4）與畫質（1080p / 720p / 480p）
- **一鍵下載** — 呼叫後端下載至伺服器指定目錄，下載時顯示動態角色動畫與進度條
- **下載完成標記** — 已下載影片標示綠色勾勾，可重新下載
- **黑夜模式** — 切換深色主題，設定自動儲存
- **下載路徑設定** — 透過檔案選擇器設定伺服器端儲存目錄
- **角色切換** — 可在「星奈」與「彩奈」之間切換下載動畫角色

## 截圖

| 首頁輸入 | 影片列表與下載 |
|:---:|:---:|
| ![首頁輸入](../img/螢幕擷取畫面%202026-07-08%20200603.png) | ![影片列表](../img/螢幕擷取畫面%202026-07-08%20200722.png) |

| 下載進行 | 設定頁面 |
|:---:|:---:|
| ![下載進行中](../img/螢幕擷取畫面%202026-07-08%20200758.png) | ![設定](../img/螢幕擷取畫面%202026-07-08%20200819.png) |

## 技術棧

| 套件 | 用途 |
|------|------|
| Flutter 3.44.2 | UI 框架 |
| Material 3 | 主題系統（紅色主色） |
| `http` | 後端 API 呼叫 |
| `window_manager` | 桌面視窗大小與位置管理 |
| `file_picker` | 目錄選擇器 |

## 前置需求

- Flutter SDK 3.12.2+（建議使用 FVM）
- 後端服務執行於 `http://127.0.0.1:8000`

## 執行

```bash
cd frontend
flutter run
```

支援平台：Windows / Linux / macOS（桌面模式自動設定 1200x800 初始視窗，最小 700x600）。

## 建置

```bash
# Windows
flutter build windows

# Linux
flutter build linux

# macOS
flutter build macos

# Web
flutter build web
```

## 專案結構

```
lib/
├── main.dart                     # 進入點、視窗初始化
├── app.dart                      # MaterialApp、主題切換、底部導航
├── models/
│   └── video_item.dart           # 影片資料模型
├── services/
│   └── youtube_api.dart          # 後端 API 客戶端
├── screens/
│   ├── home_screen.dart          # 首頁（搜尋與下載邏輯）
│   ├── home_screen/
│   │   ├── input_view.dart       # 網址輸入元件
│   │   └── results_view.dart     # 影片列表元件
│   └── settings_screen.dart      # 設定頁面
├── widgets/
│   └── video_item.dart           # 單一影片卡片元件
└── theme/
    └── app_theme.dart            # 淺色／深色主題
```

## 打包為單一 Windows 應用程式

前端已內建 `BackendManager`，啟動時會自動在背景啟動後端服務（bundled executable 或開發環境中的 poetry），關閉時自動終止。

### 前置需求（打包用）

- Python 3.11+ & Poetry
- Flutter SDK 3.12.2+
- FFmpeg（MP3 轉換需要）
- PyInstaller（`pip install pyinstaller`）

### 一鍵打包

```batch
scripts\build_windows.bat
```

腳本會依序：
1. 重置 `config.json` 為預設值
2. 用 PyInstaller 將後端打包為 `yt-downloader-backend.exe`
3. 用 `flutter build windows --release` 建置前端
4. 將兩者與啟動腳本合併至 `dist/yt-downloader-win64/`

### 手動打包步驟

```bash
# 步驟 1：打包後端
cd backend
pyinstaller build.spec

# 步驟 2：建置前端
cd frontend
flutter build windows --release

# 步驟 3：合併
copy "backend\dist\yt-downloader-backend.exe" "frontend\build\windows\x64\runner\Release\"
```

最終 `frontend\build\windows\x64\runner\Release\` 即為可直接執行的應用程式資料夾，執行 `flutter_window.exe` 即會自動啟動後端。

### 開發模式（不需打包）

```bash
# 終端 1：啟動後端
cd backend
poetry run uvicorn main:app --host 127.0.0.1 --port 8000

# 終端 2：啟動前端
cd frontend
flutter run
```

前端啟動時會先檢查 `http://127.0.0.1:8000` 是否已就緒，若已就緒則跳過啟動後端。

## 注意事項

- 後端 URL 由 `BackendManager` 動態提供（預設 `http://127.0.0.1:8000`），不再寫死
- 下載進度條為前端模擬（每 500ms 增加 5%），非真實串流進度
