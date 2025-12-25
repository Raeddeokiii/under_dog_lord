"""다크 테마 스타일시트"""
from dataclasses import dataclass


@dataclass
class Theme:
    """테마 색상"""
    # 배경
    bg_primary: str = "#1a1a2e"
    bg_secondary: str = "#16213e"
    bg_tertiary: str = "#0f3460"
    bg_card: str = "#1f2940"
    bg_input: str = "#0d1b2a"
    bg_hover: str = "#2a3f5f"

    # 텍스트
    text_primary: str = "#ffffff"
    text_secondary: str = "#a0a0a0"
    text_muted: str = "#606060"

    # 강조색
    accent_primary: str = "#e94560"
    accent_secondary: str = "#0f4c75"
    accent_success: str = "#00bf63"
    accent_warning: str = "#ffc107"
    accent_danger: str = "#dc3545"
    accent_info: str = "#17a2b8"

    # 등급 색상
    rarity_common: str = "#9e9e9e"
    rarity_uncommon: str = "#4caf50"
    rarity_rare: str = "#2196f3"
    rarity_epic: str = "#9c27b0"
    rarity_legendary: str = "#ff9800"

    # 테두리
    border_color: str = "#2a3f5f"
    border_radius: int = 8

    # 폰트
    font_family: str = "Segoe UI"
    font_size_small: int = 11
    font_size_normal: int = 13
    font_size_large: int = 16
    font_size_title: int = 20
    font_size_header: int = 24


DARK_THEME = Theme()


def apply_theme(theme: Theme = DARK_THEME) -> str:
    """PyQt6 스타일시트 생성"""
    return f"""
    /* 전역 스타일 */
    QMainWindow, QWidget {{
        background-color: {theme.bg_primary};
        color: {theme.text_primary};
        font-family: "{theme.font_family}";
        font-size: {theme.font_size_normal}px;
    }}

    /* 메뉴바 */
    QMenuBar {{
        background-color: {theme.bg_secondary};
        border-bottom: 1px solid {theme.border_color};
        padding: 4px;
    }}
    QMenuBar::item {{
        padding: 6px 12px;
        border-radius: 4px;
    }}
    QMenuBar::item:selected {{
        background-color: {theme.bg_hover};
    }}
    QMenu {{
        background-color: {theme.bg_secondary};
        border: 1px solid {theme.border_color};
        border-radius: {theme.border_radius}px;
        padding: 4px;
    }}
    QMenu::item {{
        padding: 8px 24px;
        border-radius: 4px;
    }}
    QMenu::item:selected {{
        background-color: {theme.accent_primary};
    }}

    /* 탭 위젯 */
    QTabWidget::pane {{
        background-color: {theme.bg_card};
        border: 1px solid {theme.border_color};
        border-radius: {theme.border_radius}px;
        margin-top: -1px;
    }}
    QTabBar {{
        background-color: transparent;
    }}
    QTabBar::tab {{
        background-color: {theme.bg_secondary};
        color: {theme.text_secondary};
        border: 1px solid {theme.border_color};
        border-bottom: none;
        padding: 10px 20px;
        margin-right: 2px;
        border-top-left-radius: {theme.border_radius}px;
        border-top-right-radius: {theme.border_radius}px;
    }}
    QTabBar::tab:selected {{
        background-color: {theme.bg_card};
        color: {theme.text_primary};
        border-bottom: 2px solid {theme.accent_primary};
    }}
    QTabBar::tab:hover:!selected {{
        background-color: {theme.bg_hover};
    }}

    /* 입력 필드 */
    QLineEdit, QTextEdit, QPlainTextEdit {{
        background-color: {theme.bg_input};
        border: 1px solid {theme.border_color};
        border-radius: {theme.border_radius}px;
        padding: 8px 12px;
        color: {theme.text_primary};
        selection-background-color: {theme.accent_primary};
    }}
    QLineEdit:focus, QTextEdit:focus, QPlainTextEdit:focus {{
        border: 1px solid {theme.accent_primary};
    }}
    QLineEdit:disabled {{
        background-color: {theme.bg_tertiary};
        color: {theme.text_muted};
    }}

    /* 스핀박스 */
    QSpinBox, QDoubleSpinBox {{
        background-color: {theme.bg_input};
        border: 1px solid {theme.border_color};
        border-radius: {theme.border_radius}px;
        padding: 8px 12px;
        color: {theme.text_primary};
    }}
    QSpinBox:focus, QDoubleSpinBox:focus {{
        border: 1px solid {theme.accent_primary};
    }}
    QSpinBox::up-button, QDoubleSpinBox::up-button {{
        background-color: {theme.bg_hover};
        border-left: 1px solid {theme.border_color};
        border-top-right-radius: {theme.border_radius}px;
        width: 24px;
    }}
    QSpinBox::down-button, QDoubleSpinBox::down-button {{
        background-color: {theme.bg_hover};
        border-left: 1px solid {theme.border_color};
        border-bottom-right-radius: {theme.border_radius}px;
        width: 24px;
    }}
    QSpinBox::up-button:hover, QDoubleSpinBox::up-button:hover,
    QSpinBox::down-button:hover, QDoubleSpinBox::down-button:hover {{
        background-color: {theme.accent_secondary};
    }}

    /* 콤보박스 */
    QComboBox {{
        background-color: {theme.bg_input};
        border: 1px solid {theme.border_color};
        border-radius: {theme.border_radius}px;
        padding: 8px 12px;
        color: {theme.text_primary};
        min-width: 120px;
    }}
    QComboBox:focus {{
        border: 1px solid {theme.accent_primary};
    }}
    QComboBox::drop-down {{
        border: none;
        width: 30px;
    }}
    QComboBox::down-arrow {{
        image: none;
        border-left: 5px solid transparent;
        border-right: 5px solid transparent;
        border-top: 6px solid {theme.text_secondary};
        margin-right: 10px;
    }}
    QComboBox QAbstractItemView {{
        background-color: {theme.bg_secondary};
        border: 1px solid {theme.border_color};
        border-radius: {theme.border_radius}px;
        selection-background-color: {theme.accent_primary};
        outline: none;
    }}
    QComboBox QAbstractItemView::item {{
        padding: 8px 12px;
        min-height: 28px;
    }}

    /* 버튼 */
    QPushButton {{
        background-color: {theme.bg_tertiary};
        border: 1px solid {theme.border_color};
        border-radius: {theme.border_radius}px;
        padding: 10px 20px;
        color: {theme.text_primary};
        font-weight: bold;
    }}
    QPushButton:hover {{
        background-color: {theme.bg_hover};
        border-color: {theme.accent_primary};
    }}
    QPushButton:pressed {{
        background-color: {theme.accent_secondary};
    }}
    QPushButton:disabled {{
        background-color: {theme.bg_secondary};
        color: {theme.text_muted};
    }}
    QPushButton#primaryButton {{
        background-color: {theme.accent_primary};
        border: none;
    }}
    QPushButton#primaryButton:hover {{
        background-color: #ff6b7d;
    }}
    QPushButton#successButton {{
        background-color: {theme.accent_success};
        border: none;
    }}
    QPushButton#successButton:hover {{
        background-color: #00d970;
    }}
    QPushButton#dangerButton {{
        background-color: {theme.accent_danger};
        border: none;
    }}
    QPushButton#dangerButton:hover {{
        background-color: #e35d6a;
    }}

    /* 슬라이더 */
    QSlider::groove:horizontal {{
        border: none;
        height: 8px;
        background-color: {theme.bg_tertiary};
        border-radius: 4px;
    }}
    QSlider::handle:horizontal {{
        background-color: {theme.accent_primary};
        border: none;
        width: 18px;
        height: 18px;
        margin: -5px 0;
        border-radius: 9px;
    }}
    QSlider::handle:horizontal:hover {{
        background-color: #ff6b7d;
    }}
    QSlider::sub-page:horizontal {{
        background-color: {theme.accent_primary};
        border-radius: 4px;
    }}

    /* 체크박스 */
    QCheckBox {{
        spacing: 8px;
        color: {theme.text_primary};
    }}
    QCheckBox::indicator {{
        width: 20px;
        height: 20px;
        border-radius: 4px;
        border: 2px solid {theme.border_color};
        background-color: {theme.bg_input};
    }}
    QCheckBox::indicator:checked {{
        background-color: {theme.accent_primary};
        border-color: {theme.accent_primary};
    }}
    QCheckBox::indicator:hover {{
        border-color: {theme.accent_primary};
    }}

    /* 라디오버튼 */
    QRadioButton {{
        spacing: 8px;
        color: {theme.text_primary};
    }}
    QRadioButton::indicator {{
        width: 20px;
        height: 20px;
        border-radius: 10px;
        border: 2px solid {theme.border_color};
        background-color: {theme.bg_input};
    }}
    QRadioButton::indicator:checked {{
        background-color: {theme.accent_primary};
        border-color: {theme.accent_primary};
    }}
    QRadioButton::indicator:hover {{
        border-color: {theme.accent_primary};
    }}

    /* 그룹박스 */
    QGroupBox {{
        background-color: {theme.bg_card};
        border: 1px solid {theme.border_color};
        border-radius: {theme.border_radius}px;
        margin-top: 16px;
        padding: 16px;
        padding-top: 24px;
        font-weight: bold;
    }}
    QGroupBox::title {{
        subcontrol-origin: margin;
        left: 16px;
        padding: 0 8px;
        color: {theme.accent_primary};
    }}

    /* 스크롤바 */
    QScrollBar:vertical {{
        background-color: {theme.bg_secondary};
        width: 12px;
        margin: 0;
        border-radius: 6px;
    }}
    QScrollBar::handle:vertical {{
        background-color: {theme.bg_hover};
        min-height: 30px;
        border-radius: 6px;
        margin: 2px;
    }}
    QScrollBar::handle:vertical:hover {{
        background-color: {theme.accent_secondary};
    }}
    QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical {{
        height: 0;
    }}
    QScrollBar:horizontal {{
        background-color: {theme.bg_secondary};
        height: 12px;
        margin: 0;
        border-radius: 6px;
    }}
    QScrollBar::handle:horizontal {{
        background-color: {theme.bg_hover};
        min-width: 30px;
        border-radius: 6px;
        margin: 2px;
    }}
    QScrollBar::handle:horizontal:hover {{
        background-color: {theme.accent_secondary};
    }}
    QScrollBar::add-line:horizontal, QScrollBar::sub-line:horizontal {{
        width: 0;
    }}

    /* 리스트/트리 */
    QListWidget, QTreeWidget, QTableWidget {{
        background-color: {theme.bg_input};
        border: 1px solid {theme.border_color};
        border-radius: {theme.border_radius}px;
        outline: none;
    }}
    QListWidget::item, QTreeWidget::item {{
        padding: 8px;
        border-radius: 4px;
    }}
    QListWidget::item:selected, QTreeWidget::item:selected {{
        background-color: {theme.accent_primary};
    }}
    QListWidget::item:hover:!selected, QTreeWidget::item:hover:!selected {{
        background-color: {theme.bg_hover};
    }}

    /* 헤더 */
    QHeaderView::section {{
        background-color: {theme.bg_tertiary};
        border: none;
        border-right: 1px solid {theme.border_color};
        border-bottom: 1px solid {theme.border_color};
        padding: 8px;
        font-weight: bold;
    }}

    /* 레이블 */
    QLabel {{
        color: {theme.text_primary};
    }}
    QLabel#titleLabel {{
        font-size: {theme.font_size_title}px;
        font-weight: bold;
        color: {theme.accent_primary};
    }}
    QLabel#headerLabel {{
        font-size: {theme.font_size_header}px;
        font-weight: bold;
    }}
    QLabel#mutedLabel {{
        color: {theme.text_muted};
        font-size: {theme.font_size_small}px;
    }}

    /* 프로그레스바 */
    QProgressBar {{
        background-color: {theme.bg_tertiary};
        border: none;
        border-radius: {theme.border_radius}px;
        height: 20px;
        text-align: center;
    }}
    QProgressBar::chunk {{
        background-color: {theme.accent_primary};
        border-radius: {theme.border_radius}px;
    }}

    /* 프레임 */
    QFrame#card {{
        background-color: {theme.bg_card};
        border: 1px solid {theme.border_color};
        border-radius: {theme.border_radius}px;
    }}
    QFrame#separator {{
        background-color: {theme.border_color};
    }}

    /* 툴팁 */
    QToolTip {{
        background-color: {theme.bg_secondary};
        border: 1px solid {theme.border_color};
        border-radius: 4px;
        padding: 8px;
        color: {theme.text_primary};
    }}

    /* 상태바 */
    QStatusBar {{
        background-color: {theme.bg_secondary};
        border-top: 1px solid {theme.border_color};
    }}

    /* 도킹 */
    QDockWidget {{
        titlebar-close-icon: none;
        titlebar-normal-icon: none;
    }}
    QDockWidget::title {{
        background-color: {theme.bg_tertiary};
        padding: 8px;
        border-bottom: 1px solid {theme.border_color};
    }}
    """
