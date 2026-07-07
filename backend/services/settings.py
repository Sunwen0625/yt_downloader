import json
import os

SETTINGS_FILE = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'config.json')
DEFAULT_DOWNLOAD_PATH = os.path.expanduser('~/Downloads')


class Settings:
    def __init__(self, download_path: str = DEFAULT_DOWNLOAD_PATH, dark_mode: bool = False):
        self.download_path = download_path
        self.dark_mode = dark_mode


def load_settings() -> Settings:
    if not os.path.exists(SETTINGS_FILE):
        return Settings()
    try:
        with open(SETTINGS_FILE) as f:
            data = json.load(f)
        return Settings(
            download_path=data.get('download_path', DEFAULT_DOWNLOAD_PATH),
            dark_mode=data.get('dark_mode', False),
        )
    except (json.JSONDecodeError, OSError):
        return Settings()


def save_settings(settings: Settings) -> None:
    os.makedirs(os.path.dirname(SETTINGS_FILE) or '.', exist_ok=True)
    with open(SETTINGS_FILE, 'w') as f:
        json.dump({
            'download_path': settings.download_path,
            'dark_mode': settings.dark_mode,
        }, f, indent=2)
