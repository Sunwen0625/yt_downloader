import json
import os

SETTINGS_FILE = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'config.json')
DEFAULT_DOWNLOAD_PATH = os.path.expanduser('~/Downloads')


class Settings:
    def __init__(self, download_path: str = DEFAULT_DOWNLOAD_PATH, dark_mode: bool = False, character: str = '星奈'):
        self.download_path = download_path
        self.dark_mode = dark_mode
        self.character = character


def load_settings() -> Settings:
    if not os.path.exists(SETTINGS_FILE):
        return Settings()
    try:
        with open(SETTINGS_FILE, encoding='utf-8') as f:
            data = json.load(f)
        return Settings(
            download_path=data.get('download_path', DEFAULT_DOWNLOAD_PATH),
            dark_mode=data.get('dark_mode', False),
            character=data.get('character', '星奈'),
        )
    except (json.JSONDecodeError, OSError):
        return Settings()


def save_settings(settings: Settings) -> None:
    os.makedirs(os.path.dirname(SETTINGS_FILE) or '.', exist_ok=True)
    with open(SETTINGS_FILE, 'w', encoding='utf-8') as f:
        json.dump({
            'download_path': settings.download_path,
            'dark_mode': settings.dark_mode,
            'character': settings.character,
        }, f, indent=2)
