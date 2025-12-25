"""EXE 빌드 스크립트"""
import PyInstaller.__main__
import os

# 현재 디렉토리를 tools로 설정
os.chdir(os.path.dirname(os.path.abspath(__file__)))

PyInstaller.__main__.run([
    'main.py',
    '--name=UDL_ContentEditor',
    '--onefile',
    '--windowed',
    '--icon=NONE',
    '--add-data=src;src',
    '--hidden-import=PyQt6.QtCore',
    '--hidden-import=PyQt6.QtGui',
    '--hidden-import=PyQt6.QtWidgets',
    '--clean',
    '--noconfirm',
])
