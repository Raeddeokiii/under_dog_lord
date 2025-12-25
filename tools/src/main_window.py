"""메인 윈도우"""
import json
import csv
import os
from pathlib import Path
from PyQt6.QtWidgets import (
    QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QTabWidget,
    QPushButton, QLabel, QFrame, QListWidget, QListWidgetItem,
    QSplitter, QMessageBox, QFileDialog, QStatusBar, QMenuBar,
    QMenu, QScrollArea, QGridLayout
)
from PyQt6.QtCore import Qt, QSize
from PyQt6.QtGui import QAction, QIcon, QFont

from .widgets.unit_editor import UnitEditor
from .widgets.skill_editor import SkillEditor
from .widgets.race_editor import RaceEditor
from .widgets.class_editor import ClassEditor
from .models import Unit, Skill
from .exporters.gml_exporter import GMLExporter
from .parsers.gml_parser import GMLParser


class QuickActionCard(QFrame):
    """빠른 작업 카드"""
    def __init__(self, icon: str, title: str, subtitle: str, parent=None):
        super().__init__(parent)
        self.setObjectName("card")
        self.setCursor(Qt.CursorShape.PointingHandCursor)
        self.setFixedSize(200, 100)

        layout = QVBoxLayout(self)
        layout.setContentsMargins(16, 16, 16, 16)

        icon_label = QLabel(icon)
        icon_label.setFont(QFont("Segoe UI Emoji", 24))
        icon_label.setAlignment(Qt.AlignmentFlag.AlignCenter)

        title_label = QLabel(title)
        title_label.setObjectName("titleLabel")
        title_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        title_label.setStyleSheet("font-size: 14px;")

        subtitle_label = QLabel(subtitle)
        subtitle_label.setObjectName("mutedLabel")
        subtitle_label.setAlignment(Qt.AlignmentFlag.AlignCenter)

        layout.addWidget(icon_label)
        layout.addWidget(title_label)
        layout.addWidget(subtitle_label)


class RecentItemWidget(QFrame):
    """최근 작업 아이템"""
    def __init__(self, icon: str, name: str, item_type: str, action: str, parent=None):
        super().__init__(parent)
        self.setObjectName("card")
        self.setCursor(Qt.CursorShape.PointingHandCursor)

        layout = QHBoxLayout(self)
        layout.setContentsMargins(12, 8, 12, 8)

        icon_label = QLabel(icon)
        icon_label.setFont(QFont("Segoe UI Emoji", 16))

        info_layout = QVBoxLayout()
        info_layout.setSpacing(2)

        name_label = QLabel(name)
        name_label.setStyleSheet("font-weight: bold;")

        meta_label = QLabel(f"{item_type} · {action}")
        meta_label.setObjectName("mutedLabel")

        info_layout.addWidget(name_label)
        info_layout.addWidget(meta_label)

        layout.addWidget(icon_label)
        layout.addLayout(info_layout)
        layout.addStretch()


class HomeTab(QWidget):
    """홈 탭"""
    def __init__(self, main_window: "MainWindow"):
        super().__init__()
        self.main_window = main_window
        self.setup_ui()

    def setup_ui(self):
        layout = QVBoxLayout(self)
        layout.setContentsMargins(40, 40, 40, 40)
        layout.setSpacing(32)

        # 헤더
        header = QLabel("Under Dog Lord")
        header.setObjectName("headerLabel")
        header.setStyleSheet("font-size: 32px; color: #e94560;")

        subtitle = QLabel("콘텐츠 에디터")
        subtitle.setStyleSheet("font-size: 18px; color: #a0a0a0;")

        layout.addWidget(header)
        layout.addWidget(subtitle)
        layout.addSpacing(16)

        # 빠른 생성
        quick_label = QLabel("빠른 생성")
        quick_label.setStyleSheet("font-size: 16px; font-weight: bold;")
        layout.addWidget(quick_label)

        quick_layout = QHBoxLayout()
        quick_layout.setSpacing(16)

        cards = [
            ("⚔️", "새 유닛", "유닛 만들기", self.main_window.new_unit),
            ("✨", "새 스킬", "스킬 만들기", self.main_window.new_skill),
            ("🏠", "새 건물", "건물 만들기", None),
            ("🌊", "새 웨이브", "웨이브 만들기", None),
        ]

        for icon, title, subtitle, callback in cards:
            card = QuickActionCard(icon, title, subtitle)
            if callback:
                card.mousePressEvent = lambda e, cb=callback: cb()
            quick_layout.addWidget(card)

        quick_layout.addStretch()
        layout.addLayout(quick_layout)

        # 최근 작업
        recent_label = QLabel("최근 작업")
        recent_label.setStyleSheet("font-size: 16px; font-weight: bold; margin-top: 16px;")
        layout.addWidget(recent_label)

        recent_layout = QVBoxLayout()
        recent_layout.setSpacing(8)

        # TODO: 실제 최근 작업 불러오기
        sample_recent = [
            ("🔥", "화염 마법사", "유닛", "수정됨"),
            ("⚔️", "파이어볼", "스킬", "생성됨"),
            ("🏰", "병영", "건물", "수정됨"),
        ]

        for icon, name, item_type, action in sample_recent:
            item = RecentItemWidget(icon, name, item_type, action)
            recent_layout.addWidget(item)

        layout.addLayout(recent_layout)
        layout.addStretch()


class MainWindow(QMainWindow):
    """메인 윈도우"""
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Under Dog Lord - 콘텐츠 에디터")
        self.setMinimumSize(1400, 900)
        self.resize(1600, 1000)

        # 데이터
        self.units: dict[str, Unit] = {}
        self.skills: dict[str, Skill] = {}
        self.races: dict[str, dict] = {}
        self.classes: dict[str, dict] = {}
        self.buildings: dict[str, dict] = {}
        self.project_path = self._find_project_path()
        self._load_races_classes_csv()
        self._load_skills_csv()
        self._load_units_csv()
        self._load_buildings_csv()

        # GML 익스포터
        self.exporter = GMLExporter(self.project_path)

        self.setup_ui()
        self.setup_menu()
        self.load_existing_data()

    def _find_project_path(self) -> Path:
        """프로젝트 경로 찾기 (EXE와 소스 모두 지원)"""
        import sys

        # PyInstaller로 번들된 경우
        if getattr(sys, 'frozen', False):
            # EXE 실행 위치에서 프로젝트 루트 찾기
            exe_dir = Path(sys.executable).parent

            # dist 폴더 안에 있으면 상위로
            if exe_dir.name == 'dist':
                project_path = exe_dir.parent.parent
            else:
                # EXE가 프로젝트 루트에 있는 경우
                project_path = exe_dir

            # scripts/scr_data 폴더가 있는지 확인
            if (project_path / "scripts" / "scr_data").exists():
                return project_path

            # 현재 작업 디렉토리 확인
            cwd = Path.cwd()
            if (cwd / "scripts" / "scr_data").exists():
                return cwd

            # 상위 폴더들 탐색
            for parent in exe_dir.parents:
                if (parent / "scripts" / "scr_data").exists():
                    return parent

            return exe_dir
        else:
            # 소스에서 실행하는 경우
            return Path(__file__).parent.parent.parent

    def _load_races_classes_csv(self):
        """CSV 파일에서 종족/직업 로드"""
        data_dir = self.project_path / "datafiles" / "data"

        # 종족 로드 (races.csv)
        races_file = data_dir / "races.csv"
        if races_file.exists():
            try:
                with open(races_file, 'r', encoding='utf-8') as f:
                    reader = csv.DictReader(f)
                    for row in reader:
                        if not row.get('id'):
                            continue
                        race_id = row['id']
                        # 숫자 필드 변환
                        race = {'id': race_id, 'name': row.get('name', '')}
                        for key in ['hp', 'mana', 'phys_atk', 'mag_atk', 'phys_def', 'mag_def',
                                    'atk_speed', 'move_speed', 'crit_chance', 'crit_damage',
                                    'dodge', 'accuracy', 'lifesteal', 'healing_power',
                                    'hp_regen', 'mana_regen', 'cc_resist', 'debuff_resist']:
                            race[key] = int(row.get(key, 0) or 0)
                        # 태그 파싱 (| 구분)
                        tags_str = row.get('tags', '')
                        race['tags'] = [t.strip() for t in tags_str.split('|') if t.strip()]
                        self.races[race_id] = race
            except Exception as e:
                print(f"종족 CSV 로드 실패: {e}")

        # 직업 로드 (classes.csv)
        classes_file = data_dir / "classes.csv"
        if classes_file.exists():
            try:
                with open(classes_file, 'r', encoding='utf-8') as f:
                    reader = csv.DictReader(f)
                    for row in reader:
                        if not row.get('id'):
                            continue
                        class_id = row['id']
                        cls = {'id': class_id, 'name': row.get('name', '')}
                        for key in ['hp_mod', 'phys_atk_mod', 'mag_atk_mod', 'phys_def_mod',
                                    'mag_def_mod', 'speed_mod', 'atk_range_mod']:
                            cls[key] = int(row.get(key, 0) or 0)
                        # 태그 파싱 (| 구분)
                        tags_str = row.get('tags', '')
                        cls['tags'] = [t.strip() for t in tags_str.split('|') if t.strip()]
                        self.classes[class_id] = cls
            except Exception as e:
                print(f"직업 CSV 로드 실패: {e}")

    def save_races_csv(self):
        """종족 데이터를 CSV로 저장"""
        data_dir = self.project_path / "datafiles" / "data"
        data_dir.mkdir(parents=True, exist_ok=True)

        races_file = data_dir / "races.csv"
        fieldnames = ['id', 'name', 'hp', 'mana', 'phys_atk', 'mag_atk', 'phys_def', 'mag_def',
                      'atk_speed', 'move_speed', 'crit_chance', 'crit_damage', 'dodge', 'accuracy',
                      'lifesteal', 'healing_power', 'hp_regen', 'mana_regen', 'cc_resist', 'debuff_resist', 'tags']

        with open(races_file, 'w', encoding='utf-8', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            for race_id, race in self.races.items():
                row = {key: race.get(key, 0) for key in fieldnames if key not in ['id', 'name', 'tags']}
                row['id'] = race_id
                row['name'] = race.get('name', '')
                row['tags'] = '|'.join(race.get('tags', []))
                writer.writerow(row)

    def save_classes_csv(self):
        """직업 데이터를 CSV로 저장"""
        data_dir = self.project_path / "datafiles" / "data"
        data_dir.mkdir(parents=True, exist_ok=True)

        classes_file = data_dir / "classes.csv"
        fieldnames = ['id', 'name', 'hp_mod', 'phys_atk_mod', 'mag_atk_mod', 'phys_def_mod',
                      'mag_def_mod', 'speed_mod', 'atk_range_mod', 'tags']

        with open(classes_file, 'w', encoding='utf-8', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            for class_id, cls in self.classes.items():
                row = {key: cls.get(key, 0) for key in fieldnames if key not in ['id', 'name', 'tags']}
                row['id'] = class_id
                row['name'] = cls.get('name', '')
                row['tags'] = '|'.join(cls.get('tags', []))
                writer.writerow(row)

    # JSON 호환 함수 (기존 코드 호환성)
    def save_races_json(self):
        """종족 데이터를 CSV로 저장 (JSON 호환 래퍼)"""
        self.save_races_csv()

    def save_classes_json(self):
        """직업 데이터를 CSV로 저장 (JSON 호환 래퍼)"""
        self.save_classes_csv()

    def _load_skills_csv(self):
        """CSV 파일에서 스킬 로드"""
        data_dir = self.project_path / "datafiles" / "data"
        skills_file = data_dir / "skills.csv"
        if skills_file.exists():
            try:
                with open(skills_file, 'r', encoding='utf-8') as f:
                    reader = csv.DictReader(f)
                    for row in reader:
                        if not row.get('id'):
                            continue
                        skill_id = row['id']
                        skill = Skill(
                            id=skill_id,
                            name=row.get('name', ''),
                            mana_cost=int(row.get('mana_cost', 0) or 0),
                            cooldown=float(row.get('cooldown', 1) or 1)
                        )
                        skill.damage_type = row.get('damage_type', 'physical')
                        skill.effect_type = row.get('effect_type', 'damage')
                        skill.base_amount = int(row.get('base_amount', 0) or 0)
                        skill.scale_stat = row.get('scale_stat', '')
                        skill.scale_percent = int(row.get('scale_percent', 0) or 0)
                        skill.tags = [t.strip() for t in row.get('tags', '').split('|') if t.strip()]
                        self.skills[skill_id] = skill
            except Exception as e:
                print(f"스킬 CSV 로드 실패: {e}")

    def save_skills_csv(self):
        """스킬 데이터를 CSV로 저장"""
        data_dir = self.project_path / "datafiles" / "data"
        data_dir.mkdir(parents=True, exist_ok=True)

        skills_file = data_dir / "skills.csv"
        fieldnames = ['id', 'name', 'mana_cost', 'cooldown', 'damage_type', 'effect_type',
                      'base_amount', 'scale_stat', 'scale_percent', 'dot_amount', 'dot_duration',
                      'heal_amount', 'buff_stat', 'buff_value', 'buff_duration', 'cc_type',
                      'cc_duration', 'aoe_radius', 'target_type', 'tags']

        with open(skills_file, 'w', encoding='utf-8', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            for skill_id, skill in self.skills.items():
                row = {
                    'id': skill_id,
                    'name': skill.name if hasattr(skill, 'name') else '',
                    'mana_cost': skill.mana_cost if hasattr(skill, 'mana_cost') else 0,
                    'cooldown': skill.cooldown if hasattr(skill, 'cooldown') else 1,
                    'damage_type': getattr(skill, 'damage_type', 'physical'),
                    'effect_type': getattr(skill, 'effect_type', 'damage'),
                    'base_amount': getattr(skill, 'base_amount', 0),
                    'scale_stat': getattr(skill, 'scale_stat', ''),
                    'scale_percent': getattr(skill, 'scale_percent', 0),
                    'dot_amount': 0, 'dot_duration': 0,
                    'heal_amount': 0, 'buff_stat': '', 'buff_value': 0, 'buff_duration': 0,
                    'cc_type': '', 'cc_duration': 0, 'aoe_radius': 0, 'target_type': 'enemy',
                    'tags': '|'.join(getattr(skill, 'tags', []))
                }
                writer.writerow(row)

    def _load_units_csv(self):
        """CSV 파일에서 유닛 로드"""
        data_dir = self.project_path / "datafiles" / "data"
        units_file = data_dir / "units.csv"
        if units_file.exists():
            try:
                with open(units_file, 'r', encoding='utf-8') as f:
                    reader = csv.DictReader(f)
                    for row in reader:
                        if not row.get('id'):
                            continue
                        unit_id = row['id']
                        unit = Unit(
                            id=unit_id,
                            name=row.get('name', ''),
                            description=''
                        )
                        unit.race_id = row.get('race', 'human')
                        unit.class_id = row.get('class', 'warrior')
                        unit.hp = int(row.get('hp', 100) or 100)
                        unit.max_mana = int(row.get('max_mana', 0) or 0)
                        unit.phys_atk = int(row.get('phys_atk', 10) or 10)
                        unit.mag_atk = int(row.get('mag_atk', 0) or 0)
                        unit.phys_def = int(row.get('phys_def', 5) or 5)
                        unit.mag_def = int(row.get('mag_def', 5) or 5)
                        unit.atk_speed = float(row.get('atk_speed', 1) or 1)
                        unit.move_speed = int(row.get('move_speed', 80) or 80)
                        unit.atk_range = int(row.get('atk_range', 1) or 1)
                        unit.skills = [s.strip() for s in row.get('skills', '').split('|') if s.strip()]
                        unit.tags = [t.strip() for t in row.get('tags', '').split('|') if t.strip()]
                        self.units[unit_id] = unit
            except Exception as e:
                print(f"유닛 CSV 로드 실패: {e}")

    def save_units_csv(self):
        """유닛 데이터를 CSV로 저장"""
        data_dir = self.project_path / "datafiles" / "data"
        data_dir.mkdir(parents=True, exist_ok=True)

        units_file = data_dir / "units.csv"
        fieldnames = ['id', 'name', 'race', 'class', 'hp', 'max_mana', 'phys_atk', 'mag_atk',
                      'phys_def', 'mag_def', 'atk_speed', 'move_speed', 'atk_range',
                      'crit_chance', 'crit_damage', 'dodge', 'accuracy', 'phys_ls', 'mag_ls',
                      'heal_power', 'phys_pen', 'mag_pen', 'cdr', 'mana_regen', 'hp_regen',
                      'cc_resist', 'debuff_resist', 'growth_hp', 'growth_mana', 'growth_patk',
                      'growth_matk', 'growth_pdef', 'growth_mdef', 'skills', 'tags']

        with open(units_file, 'w', encoding='utf-8', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            for unit_id, unit in self.units.items():
                row = {
                    'id': unit_id,
                    'name': unit.name if hasattr(unit, 'name') else '',
                    'race': getattr(unit, 'race_id', 'human'),
                    'class': getattr(unit, 'class_id', 'warrior'),
                    'hp': getattr(unit, 'hp', 100),
                    'max_mana': getattr(unit, 'max_mana', 0),
                    'phys_atk': getattr(unit, 'phys_atk', 10),
                    'mag_atk': getattr(unit, 'mag_atk', 0),
                    'phys_def': getattr(unit, 'phys_def', 5),
                    'mag_def': getattr(unit, 'mag_def', 5),
                    'atk_speed': getattr(unit, 'atk_speed', 1),
                    'move_speed': getattr(unit, 'move_speed', 80),
                    'atk_range': getattr(unit, 'atk_range', 1),
                    'crit_chance': 0, 'crit_damage': 150, 'dodge': 0, 'accuracy': 100,
                    'phys_ls': 0, 'mag_ls': 0, 'heal_power': 0, 'phys_pen': 0, 'mag_pen': 0,
                    'cdr': 0, 'mana_regen': 0, 'hp_regen': 0, 'cc_resist': 0, 'debuff_resist': 0,
                    'growth_hp': 0, 'growth_mana': 0, 'growth_patk': 0, 'growth_matk': 0,
                    'growth_pdef': 0, 'growth_mdef': 0,
                    'skills': '|'.join(getattr(unit, 'skills', [])),
                    'tags': '|'.join(getattr(unit, 'tags', []))
                }
                writer.writerow(row)

    def _load_buildings_csv(self):
        """CSV 파일에서 건물 로드"""
        data_dir = self.project_path / "datafiles" / "data"
        buildings_file = data_dir / "buildings.csv"
        if buildings_file.exists():
            try:
                with open(buildings_file, 'r', encoding='utf-8') as f:
                    reader = csv.DictReader(f)
                    for row in reader:
                        if not row.get('id'):
                            continue
                        building_id = row['id']
                        building = {
                            'id': building_id,
                            'name': row.get('name', ''),
                            'hp': int(row.get('hp', 100) or 100),
                            'build_cost_gold': int(row.get('build_cost_gold', 0) or 0),
                            'build_cost_wood': int(row.get('build_cost_wood', 0) or 0),
                            'build_cost_stone': int(row.get('build_cost_stone', 0) or 0),
                            'build_time': int(row.get('build_time', 10) or 10),
                            'size_x': int(row.get('size_x', 1) or 1),
                            'size_y': int(row.get('size_y', 1) or 1),
                            'produces': [p.strip() for p in row.get('produces', '').split('|') if p.strip()],
                            'income_gold': int(row.get('income_gold', 0) or 0),
                            'income_wood': int(row.get('income_wood', 0) or 0),
                            'income_stone': int(row.get('income_stone', 0) or 0),
                            'income_interval': int(row.get('income_interval', 0) or 0),
                            'max_garrison': int(row.get('max_garrison', 0) or 0),
                            'defense_bonus': int(row.get('defense_bonus', 0) or 0),
                            'requirements': [r.strip() for r in row.get('requirements', '').split('|') if r.strip()],
                            'tags': [t.strip() for t in row.get('tags', '').split('|') if t.strip()]
                        }
                        self.buildings[building_id] = building
            except Exception as e:
                print(f"건물 CSV 로드 실패: {e}")

    def save_buildings_csv(self):
        """건물 데이터를 CSV로 저장"""
        data_dir = self.project_path / "datafiles" / "data"
        data_dir.mkdir(parents=True, exist_ok=True)

        buildings_file = data_dir / "buildings.csv"
        fieldnames = ['id', 'name', 'hp', 'build_cost_gold', 'build_cost_wood', 'build_cost_stone',
                      'build_time', 'size_x', 'size_y', 'produces', 'income_gold', 'income_wood',
                      'income_stone', 'income_interval', 'max_garrison', 'defense_bonus',
                      'requirements', 'tags']

        with open(buildings_file, 'w', encoding='utf-8', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            for building_id, building in self.buildings.items():
                row = {
                    'id': building_id,
                    'name': building.get('name', ''),
                    'hp': building.get('hp', 100),
                    'build_cost_gold': building.get('build_cost_gold', 0),
                    'build_cost_wood': building.get('build_cost_wood', 0),
                    'build_cost_stone': building.get('build_cost_stone', 0),
                    'build_time': building.get('build_time', 10),
                    'size_x': building.get('size_x', 1),
                    'size_y': building.get('size_y', 1),
                    'produces': '|'.join(building.get('produces', [])),
                    'income_gold': building.get('income_gold', 0),
                    'income_wood': building.get('income_wood', 0),
                    'income_stone': building.get('income_stone', 0),
                    'income_interval': building.get('income_interval', 0),
                    'max_garrison': building.get('max_garrison', 0),
                    'defense_bonus': building.get('defense_bonus', 0),
                    'requirements': '|'.join(building.get('requirements', [])),
                    'tags': '|'.join(building.get('tags', []))
                }
                writer.writerow(row)

    def setup_ui(self):
        """UI 설정"""
        central = QWidget()
        self.setCentralWidget(central)

        layout = QHBoxLayout(central)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(0)

        # 사이드바
        sidebar = QFrame()
        sidebar.setObjectName("card")
        sidebar.setFixedWidth(200)
        sidebar.setStyleSheet("""
            QFrame#card {
                border-radius: 0;
                border-right: 1px solid #2a3f5f;
            }
        """)

        sidebar_layout = QVBoxLayout(sidebar)
        sidebar_layout.setContentsMargins(0, 16, 0, 16)
        sidebar_layout.setSpacing(4)

        # 로고
        logo = QLabel("🏰")
        logo.setFont(QFont("Segoe UI Emoji", 32))
        logo.setAlignment(Qt.AlignmentFlag.AlignCenter)
        sidebar_layout.addWidget(logo)

        title = QLabel("UDL Editor")
        title.setAlignment(Qt.AlignmentFlag.AlignCenter)
        title.setStyleSheet("font-weight: bold; color: #e94560; margin-bottom: 16px;")
        sidebar_layout.addWidget(title)

        # 네비게이션 버튼
        self.nav_buttons = []
        nav_items = [
            ("🏠", "홈", 0),
            ("👤", "종족", 1),
            ("🎭", "직업", 2),
            ("⚔️", "유닛", 3),
            ("✨", "스킬", 4),
            ("🏗️", "건물", 5),
            ("🌊", "웨이브", 6),
        ]

        for icon, name, index in nav_items:
            btn = QPushButton(f"  {icon}  {name}")
            btn.setCheckable(True)
            btn.setStyleSheet("""
                QPushButton {
                    text-align: left;
                    padding: 12px 20px;
                    border: none;
                    border-radius: 0;
                    background: transparent;
                }
                QPushButton:hover {
                    background-color: #2a3f5f;
                }
                QPushButton:checked {
                    background-color: #e94560;
                    border-left: 3px solid #ff6b7d;
                }
            """)
            btn.clicked.connect(lambda checked, idx=index: self.switch_tab(idx))
            sidebar_layout.addWidget(btn)
            self.nav_buttons.append(btn)

        sidebar_layout.addStretch()

        # 가져오기 버튼
        import_btn = QPushButton("📥  GML에서 가져오기")
        import_btn.clicked.connect(self.import_from_gml)
        import_btn.setStyleSheet("""
            QPushButton {
                margin: 8px 8px 4px 8px;
                padding: 12px;
                background-color: #2a3f5f;
            }
            QPushButton:hover {
                background-color: #3a5070;
            }
        """)
        sidebar_layout.addWidget(import_btn)

        # 내보내기 버튼
        export_btn = QPushButton("📤  GML 내보내기")
        export_btn.setObjectName("successButton")
        export_btn.clicked.connect(self.export_to_gml)
        export_btn.setStyleSheet("""
            QPushButton {
                margin: 4px 8px 8px 8px;
                padding: 12px;
            }
        """)
        sidebar_layout.addWidget(export_btn)

        layout.addWidget(sidebar)

        # 메인 콘텐츠
        self.content_stack = QTabWidget()
        self.content_stack.setTabBarAutoHide(True)
        self.content_stack.tabBar().hide()

        # 탭 추가
        self.home_tab = HomeTab(self)
        self.race_editor = RaceEditor(self)
        self.class_editor = ClassEditor(self)
        self.unit_editor = UnitEditor(self)
        self.skill_editor = SkillEditor(self)

        self.content_stack.addTab(self.home_tab, "홈")
        self.content_stack.addTab(self.race_editor, "종족")
        self.content_stack.addTab(self.class_editor, "직업")
        self.content_stack.addTab(self.unit_editor, "유닛")
        self.content_stack.addTab(self.skill_editor, "스킬")
        self.content_stack.addTab(QLabel("건물 에디터 (준비 중)"), "건물")
        self.content_stack.addTab(QLabel("웨이브 에디터 (준비 중)"), "웨이브")

        layout.addWidget(self.content_stack)

        # 상태바
        self.statusBar().showMessage("준비됨")

        # 첫 번째 버튼 선택
        self.nav_buttons[0].setChecked(True)

    def setup_menu(self):
        """메뉴 설정"""
        menubar = self.menuBar()

        # 파일 메뉴
        file_menu = menubar.addMenu("파일(&F)")

        new_unit_action = QAction("새 유닛(&U)", self)
        new_unit_action.setShortcut("Ctrl+Shift+U")
        new_unit_action.triggered.connect(self.new_unit)
        file_menu.addAction(new_unit_action)

        new_skill_action = QAction("새 스킬(&S)", self)
        new_skill_action.setShortcut("Ctrl+Shift+S")
        new_skill_action.triggered.connect(self.new_skill)
        file_menu.addAction(new_skill_action)

        file_menu.addSeparator()

        import_action = QAction("GML에서 가져오기(&I)", self)
        import_action.setShortcut("Ctrl+I")
        import_action.triggered.connect(self.import_from_gml)
        file_menu.addAction(import_action)

        export_action = QAction("GML로 내보내기(&E)", self)
        export_action.setShortcut("Ctrl+E")
        export_action.triggered.connect(self.export_to_gml)
        file_menu.addAction(export_action)

        file_menu.addSeparator()

        exit_action = QAction("종료(&X)", self)
        exit_action.setShortcut("Alt+F4")
        exit_action.triggered.connect(self.close)
        file_menu.addAction(exit_action)

        # 편집 메뉴
        edit_menu = menubar.addMenu("편집(&E)")

        save_action = QAction("저장(&S)", self)
        save_action.setShortcut("Ctrl+S")
        save_action.triggered.connect(self.save_current)
        edit_menu.addAction(save_action)

        # 도움말 메뉴
        help_menu = menubar.addMenu("도움말(&H)")

        about_action = QAction("정보(&A)", self)
        about_action.triggered.connect(self.show_about)
        help_menu.addAction(about_action)

    def switch_tab(self, index: int):
        """탭 전환"""
        for i, btn in enumerate(self.nav_buttons):
            btn.setChecked(i == index)
        self.content_stack.setCurrentIndex(index)

    def new_unit(self):
        """새 유닛 생성"""
        self.switch_tab(3)
        self.unit_editor.new_unit()

    def new_skill(self):
        """새 스킬 생성"""
        self.switch_tab(4)
        self.skill_editor.new_skill()

    def save_current(self):
        """현재 편집 중인 항목 저장"""
        current = self.content_stack.currentWidget()
        if hasattr(current, 'save_current'):
            current.save_current()

    def export_to_gml(self):
        """모든 데이터를 CSV로 내보내기 (게임에서 직접 CSV 로드)"""
        try:
            # 종족/직업/스킬/유닛 모두 CSV 저장
            self.save_races_csv()
            race_count = len(self.races)

            self.save_classes_csv()
            class_count = len(self.classes)

            self.save_skills_csv()
            skill_count = len(self.skills)

            self.save_units_csv()
            unit_count = len(self.units)

            self.save_buildings_csv()
            building_count = len(self.buildings)

            QMessageBox.information(
                self,
                "내보내기 완료",
                f"데이터 내보내기 완료!\n\n"
                f"종족: {race_count}개\n"
                f"직업: {class_count}개\n"
                f"스킬: {skill_count}개\n"
                f"유닛: {unit_count}개\n"
                f"건물: {building_count}개\n\n"
                f"위치: datafiles/data/"
            )
            self.statusBar().showMessage(
                f"내보내기 완료: 종족 {race_count}개, 직업 {class_count}개, "
                f"스킬 {skill_count}개, 유닛 {unit_count}개, 건물 {building_count}개"
            )
        except Exception as e:
            QMessageBox.critical(self, "오류", f"내보내기 실패:\n{str(e)}")

    def import_from_gml(self):
        """GML 파일에서 데이터 가져오기 (동기화)"""
        reply = QMessageBox.question(
            self,
            "GML 가져오기",
            "GML 파일에서 데이터를 가져옵니다.\n\n"
            "IDE에서 직접 수정한 종족/직업/유닛/스킬이\n"
            "에디터에 동기화됩니다.\n\n"
            "기존 CSV 데이터와 병합됩니다.\n"
            "계속하시겠습니까?",
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No
        )

        if reply != QMessageBox.StandardButton.Yes:
            return

        try:
            parser = GMLParser(self.project_path)
            imported = {'races': 0, 'classes': 0, 'units': 0, 'skills': 0}

            # 종족 가져오기
            gml_races = parser.parse_races()
            for race_id, race_data in gml_races.items():
                if race_id not in self.races:
                    self.races[race_id] = race_data
                    imported['races'] += 1
                else:
                    # 기존 데이터 업데이트 (GML 우선)
                    self.races[race_id].update(race_data)
                    imported['races'] += 1

            # 직업 가져오기
            gml_classes = parser.parse_classes()
            for class_id, class_data in gml_classes.items():
                if class_id not in self.classes:
                    self.classes[class_id] = class_data
                    imported['classes'] += 1
                else:
                    self.classes[class_id].update(class_data)
                    imported['classes'] += 1

            # 유닛/스킬 가져오기
            units, skills = parser.parse_all()
            for unit in units:
                self.units[unit.id] = unit
                imported['units'] += 1
            for skill in skills:
                self.skills[skill.id] = skill
                imported['skills'] += 1

            # CSV 저장
            self.save_races_csv()
            self.save_classes_csv()

            # 에디터 새로고침
            self.race_editor.load_races()
            self.class_editor.load_classes()
            self.unit_editor.load_units(list(self.units.values()))
            self.skill_editor.load_skills(list(self.skills.values()))

            QMessageBox.information(
                self,
                "가져오기 완료",
                f"GML에서 데이터를 가져왔습니다!\n\n"
                f"종족: {imported['races']}개\n"
                f"직업: {imported['classes']}개\n"
                f"유닛: {imported['units']}개\n"
                f"스킬: {imported['skills']}개"
            )
            self.statusBar().showMessage(
                f"가져오기 완료: 종족 {imported['races']}개, 직업 {imported['classes']}개, "
                f"유닛 {imported['units']}개, 스킬 {imported['skills']}개"
            )

        except Exception as e:
            QMessageBox.critical(self, "오류", f"가져오기 실패:\n{str(e)}")

    def load_existing_data(self):
        """기존 데이터 로드 (CSV 우선, 없으면 GML 파싱)"""
        # CSV에서 이미 로드한 데이터가 없으면 GML에서 파싱 시도
        if not self.units and not self.skills:
            parser = GMLParser(self.project_path)
            try:
                units, skills = parser.parse_all()

                # 유닛 등록
                for unit in units:
                    self.units[unit.id] = unit

                # 스킬 등록
                for skill in skills:
                    self.skills[skill.id] = skill

                if units or skills:
                    self.statusBar().showMessage(
                        f"GML에서 로드: 유닛 {len(units)}개, 스킬 {len(skills)}개"
                    )
            except Exception as e:
                print(f"GML 데이터 로드 실패: {e}")

        # 에디터에 데이터 전달
        self.unit_editor.load_units(list(self.units.values()))
        self.skill_editor.load_skills(list(self.skills.values()))

        # CSV에서 로드한 데이터 표시
        if self.units or self.skills:
            self.statusBar().showMessage(
                f"로드 완료: 유닛 {len(self.units)}개, 스킬 {len(self.skills)}개"
            )

    def _load_json_data(self):
        """JSON 파일에서 데이터 로드"""
        data_dir = self.project_path / "tools" / "data"

        # 유닛 로드
        units_dir = data_dir / "units"
        if units_dir.exists():
            for file in units_dir.glob("*.json"):
                try:
                    with open(file, 'r', encoding='utf-8') as f:
                        data = json.load(f)
                        unit = self._json_to_unit(data)
                        if unit and unit.id not in self.units:
                            self.units[unit.id] = unit
                except Exception as e:
                    print(f"유닛 JSON 로드 실패: {file}: {e}")

        # 스킬 로드
        skills_dir = data_dir / "skills"
        if skills_dir.exists():
            for file in skills_dir.glob("*.json"):
                try:
                    with open(file, 'r', encoding='utf-8') as f:
                        data = json.load(f)
                        skill = self._json_to_skill(data)
                        if skill and skill.id not in self.skills:
                            self.skills[skill.id] = skill
                except Exception as e:
                    print(f"스킬 JSON 로드 실패: {file}: {e}")

        # 에디터 갱신
        self.unit_editor.load_units(list(self.units.values()))
        self.skill_editor.load_skills(list(self.skills.values()))

    def _json_to_unit(self, data: dict) -> Unit:
        """JSON을 Unit 객체로 변환"""
        from .models import (
            Unit, UnitStats, UnitGrowth, UnitSprites, UnitSkillSlot,
            Race, UnitClass, Rarity, AIType, DeployPosition
        )

        unit = Unit(
            id=data.get('id', ''),
            name=data.get('name', ''),
            description=data.get('description', '')
        )

        # Enum 필드
        for member in Race:
            if member.id == data.get('race'):
                unit.race = member
                break

        for member in UnitClass:
            if member.id == data.get('class'):
                unit.unit_class = member
                break

        for member in Rarity:
            if member.id == data.get('rarity'):
                unit.rarity = member
                break

        unit.tags = data.get('tags', [])

        return unit

    def _json_to_skill(self, data: dict) -> Skill:
        """JSON을 Skill 객체로 변환"""
        from .models import Skill, DamageType

        skill = Skill(
            id=data.get('id', ''),
            name=data.get('name', ''),
            description=data.get('description', ''),
            mana_cost=data.get('mana_cost', 0),
            cooldown=data.get('cooldown', 1.0)
        )

        for member in DamageType:
            if member.id == data.get('damage_type'):
                skill.damage_type = member
                break

        return skill

    def add_unit(self, unit: Unit):
        """유닛 추가"""
        self.units[unit.id] = unit
        self.save_unit_json(unit)
        self.statusBar().showMessage(f"유닛 저장됨: {unit.name}")

    def add_skill(self, skill: Skill):
        """스킬 추가"""
        self.skills[skill.id] = skill
        self.save_skill_json(skill)
        self.statusBar().showMessage(f"스킬 저장됨: {skill.name}")

    def save_unit_json(self, unit: Unit):
        """유닛을 JSON으로 저장"""
        data_dir = self.project_path / "tools" / "data" / "units"
        data_dir.mkdir(parents=True, exist_ok=True)

        file_path = data_dir / f"{unit.id}.json"
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(unit.to_dict(), f, ensure_ascii=False, indent=2)

    def save_skill_json(self, skill: Skill):
        """스킬을 JSON으로 저장"""
        data_dir = self.project_path / "tools" / "data" / "skills"
        data_dir.mkdir(parents=True, exist_ok=True)

        file_path = data_dir / f"{skill.id}.json"
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(skill.to_dict(), f, ensure_ascii=False, indent=2)

    def show_about(self):
        """정보 대화상자"""
        QMessageBox.about(
            self,
            "Under Dog Lord 콘텐츠 에디터",
            "Under Dog Lord 콘텐츠 에디터 v1.0\n\n"
            "유닛, 스킬, 건물, 웨이브를 쉽게 만들고\n"
            "GameMaker 프로젝트로 바로 내보낼 수 있습니다."
        )
