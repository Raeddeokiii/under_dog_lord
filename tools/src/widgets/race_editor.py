"""종족 에디터 위젯"""
from PyQt6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QLabel,
    QLineEdit, QPushButton, QFrame, QListWidget,
    QListWidgetItem, QGroupBox, QFormLayout, QMessageBox,
    QColorDialog, QTextEdit, QSpinBox, QScrollArea, QGridLayout
)
from PyQt6.QtCore import Qt
from PyQt6.QtGui import QColor


class RaceEditor(QWidget):
    """종족 에디터"""
    def __init__(self, main_window):
        super().__init__()
        self.main_window = main_window
        self.current_race = None
        self.stat_inputs = {}
        self.setup_ui()
        self.load_races()

    def setup_ui(self):
        layout = QHBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(0)

        # 왼쪽: 종족 목록
        left_panel = QFrame()
        left_panel.setObjectName("card")
        left_panel.setFixedWidth(250)
        left_panel.setStyleSheet("QFrame#card { border-radius: 0; }")

        left_layout = QVBoxLayout(left_panel)
        left_layout.setContentsMargins(0, 0, 0, 0)
        left_layout.setSpacing(0)

        # 헤더
        header = QFrame()
        header.setStyleSheet("background-color: #0f3460; padding: 16px;")
        header_layout = QHBoxLayout(header)
        header_label = QLabel("종족 목록")
        header_label.setStyleSheet("font-weight: bold; font-size: 14px;")
        header_layout.addWidget(header_label)

        new_btn = QPushButton("+")
        new_btn.setFixedSize(30, 30)
        new_btn.clicked.connect(self.new_race)
        header_layout.addWidget(new_btn)

        left_layout.addWidget(header)

        # 목록
        self.race_list = QListWidget()
        self.race_list.itemClicked.connect(self._on_race_selected)
        left_layout.addWidget(self.race_list)

        layout.addWidget(left_panel)

        # 오른쪽: 에디터 (스크롤 가능)
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setHorizontalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAlwaysOff)

        right_panel = QWidget()
        right_layout = QVBoxLayout(right_panel)
        right_layout.setContentsMargins(24, 24, 24, 24)
        right_layout.setSpacing(16)

        # 기본 정보
        info_group = QGroupBox("종족 정보")
        info_layout = QFormLayout(info_group)
        info_layout.setSpacing(12)

        self.name_edit = QLineEdit()
        self.name_edit.setPlaceholderText("예: 인간")
        self.name_edit.textChanged.connect(self._update_id)
        info_layout.addRow("이름:", self.name_edit)

        self.id_edit = QLineEdit()
        self.id_edit.setPlaceholderText("예: human")
        info_layout.addRow("ID:", self.id_edit)

        self.desc_edit = QTextEdit()
        self.desc_edit.setPlaceholderText("종족 설명...")
        self.desc_edit.setMaximumHeight(80)
        info_layout.addRow("설명:", self.desc_edit)

        right_layout.addWidget(info_group)

        # 기본 스탯 보너스 (그리드 레이아웃)
        stats_group = QGroupBox("기본 스탯 보너스 (%)")
        stats_grid = QGridLayout(stats_group)
        stats_grid.setSpacing(8)

        # 스탯 정의 (키, 라벨, 행, 열)
        stat_defs = [
            ('hp', 'HP', 0, 0),
            ('mana', '마나', 0, 1),
            ('phys_atk', '물리 공격', 1, 0),
            ('mag_atk', '마법 공격', 1, 1),
            ('phys_def', '물리 방어', 2, 0),
            ('mag_def', '마법 방어', 2, 1),
            ('atk_speed', '공격 속도', 3, 0),
            ('move_speed', '이동 속도', 3, 1),
            ('crit_chance', '치명타 확률', 4, 0),
            ('crit_damage', '치명타 피해', 4, 1),
            ('dodge', '회피', 5, 0),
            ('accuracy', '명중', 5, 1),
            ('lifesteal', '생명력 흡수', 6, 0),
            ('healing_power', '치유력', 6, 1),
            ('hp_regen', 'HP 재생', 7, 0),
            ('mana_regen', '마나 재생', 7, 1),
            ('cc_resist', 'CC 저항', 8, 0),
            ('debuff_resist', '디버프 저항', 8, 1),
        ]

        for key, label, row, col in stat_defs:
            stat_widget = QWidget()
            stat_layout = QHBoxLayout(stat_widget)
            stat_layout.setContentsMargins(0, 0, 0, 0)
            stat_layout.setSpacing(4)

            lbl = QLabel(f"{label}:")
            lbl.setFixedWidth(80)
            stat_layout.addWidget(lbl)

            spinbox = QSpinBox()
            spinbox.setRange(-100, 100)
            spinbox.setValue(0)
            spinbox.setFixedWidth(70)
            self.stat_inputs[key] = spinbox
            stat_layout.addWidget(spinbox)

            stats_grid.addWidget(stat_widget, row, col)

        right_layout.addWidget(stats_group)

        # 태그
        tags_group = QGroupBox("기본 태그")
        tags_layout = QVBoxLayout(tags_group)

        tag_input_layout = QHBoxLayout()
        self.tag_input = QLineEdit()
        self.tag_input.setPlaceholderText("태그 입력 후 Enter")
        self.tag_input.returnPressed.connect(self._add_tag)
        tag_input_layout.addWidget(self.tag_input)

        add_tag_btn = QPushButton("추가")
        add_tag_btn.clicked.connect(self._add_tag)
        tag_input_layout.addWidget(add_tag_btn)

        tags_layout.addLayout(tag_input_layout)

        self.tag_list = QListWidget()
        self.tag_list.setMaximumHeight(100)
        tags_layout.addWidget(self.tag_list)

        remove_tag_btn = QPushButton("선택 태그 삭제")
        remove_tag_btn.clicked.connect(self._remove_tag)
        tags_layout.addWidget(remove_tag_btn)

        right_layout.addWidget(tags_group)
        right_layout.addStretch()

        # 하단 버튼
        button_layout = QHBoxLayout()

        save_btn = QPushButton("저장")
        save_btn.setObjectName("successButton")
        save_btn.clicked.connect(self.save_current)
        button_layout.addWidget(save_btn)

        delete_btn = QPushButton("삭제")
        delete_btn.setObjectName("dangerButton")
        delete_btn.clicked.connect(self.delete_current)
        button_layout.addWidget(delete_btn)

        button_layout.addStretch()
        right_layout.addLayout(button_layout)

        scroll.setWidget(right_panel)
        layout.addWidget(scroll)

    def _update_id(self, text: str):
        import re
        id_str = text.lower().replace(" ", "_")
        id_str = re.sub(r'[^a-z0-9_]', '', id_str)
        self.id_edit.setText(id_str)

    def _add_tag(self):
        tag = self.tag_input.text().strip()
        if tag:
            self.tag_list.addItem(tag)
            self.tag_input.clear()

    def _remove_tag(self):
        current = self.tag_list.currentRow()
        if current >= 0:
            self.tag_list.takeItem(current)

    def load_races(self):
        """종족 목록 로드"""
        self.race_list.clear()
        if hasattr(self.main_window, 'races'):
            for race_id, race in self.main_window.races.items():
                item = QListWidgetItem(f"  {race['name']}")
                item.setData(Qt.ItemDataRole.UserRole, race_id)
                self.race_list.addItem(item)

    def new_race(self):
        """새 종족"""
        self.current_race = None
        self._clear_form()

    def _clear_form(self):
        self.name_edit.clear()
        self.id_edit.clear()
        self.desc_edit.clear()
        for spinbox in self.stat_inputs.values():
            spinbox.setValue(0)
        self.tag_list.clear()

    def _on_race_selected(self, item: QListWidgetItem):
        race_id = item.data(Qt.ItemDataRole.UserRole)
        if race_id and hasattr(self.main_window, 'races') and race_id in self.main_window.races:
            self.current_race = race_id
            race = self.main_window.races[race_id]
            self._load_race(race)

    def _load_race(self, race: dict):
        self.name_edit.setText(race.get('name', ''))
        self.id_edit.setText(race.get('id', ''))
        self.desc_edit.setPlainText(race.get('description', ''))

        # 모든 스탯 로드
        for key, spinbox in self.stat_inputs.items():
            spinbox.setValue(race.get(key, 0))

        self.tag_list.clear()
        for tag in race.get('tags', []):
            self.tag_list.addItem(tag)

    def save_current(self):
        if not self.name_edit.text():
            QMessageBox.warning(self, "경고", "종족 이름을 입력하세요.")
            return
        if not self.id_edit.text():
            QMessageBox.warning(self, "경고", "종족 ID를 입력하세요.")
            return

        race = {
            'id': self.id_edit.text(),
            'name': self.name_edit.text(),
            'description': self.desc_edit.toPlainText(),
            'tags': [self.tag_list.item(i).text() for i in range(self.tag_list.count())]
        }

        # 모든 스탯 저장
        for key, spinbox in self.stat_inputs.items():
            race[key] = spinbox.value()

        if not hasattr(self.main_window, 'races'):
            self.main_window.races = {}

        self.main_window.races[race['id']] = race
        self.main_window.save_races_csv()
        self.load_races()
        QMessageBox.information(self, "저장 완료", f"종족 '{race['name']}'이(가) 저장되었습니다.")

    def delete_current(self):
        if not self.current_race:
            return

        reply = QMessageBox.question(
            self, "삭제 확인",
            f"이 종족을 삭제하시겠습니까?",
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No
        )

        if reply == QMessageBox.StandardButton.Yes:
            if hasattr(self.main_window, 'races') and self.current_race in self.main_window.races:
                del self.main_window.races[self.current_race]
                self.main_window.save_races_csv()
            self.load_races()
            self.new_race()
