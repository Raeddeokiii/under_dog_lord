#!/usr/bin/env python3
"""Under Dog Lord 콘텐츠 에디터"""
import sys
from PyQt6.QtWidgets import QApplication
from PyQt6.QtGui import QFont

from src.main_window import MainWindow
from src.styles import apply_theme


def main():
    """메인 함수"""
    # 고해상도 디스플레이 지원
    QApplication.setHighDpiScaleFactorRoundingPolicy(
        Qt.HighDpiScaleFactorRoundingPolicy.PassThrough
    )

    app = QApplication(sys.argv)

    # 기본 폰트 설정
    font = QFont("Segoe UI", 10)
    app.setFont(font)

    # 테마 적용
    app.setStyleSheet(apply_theme())

    # 메인 윈도우 생성 및 표시
    window = MainWindow()
    window.show()

    sys.exit(app.exec())


if __name__ == "__main__":
    from PyQt6.QtCore import Qt
    main()
