# -*- mode: python ; coding: utf-8 -*-

from pathlib import Path
import sys


project_root = Path.cwd()

a = Analysis(
    ['main.py'],
    pathex=[
        str(project_root)
    ],
    binaries=[],
    datas=[
        ('services', 'services'),
    ],
    hiddenimports=[
        'fastapi',
        'uvicorn',
        'uvicorn.logging',
        'yt_dlp',
        'multipart',
        
        'services.playlist',
        'services.info',
        'services.download',
        'services.settings',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
)

pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='yt-downloader-backend',
    debug=False,
    console=True,
)