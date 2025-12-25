"""직업 에디터 위젯"""
from PyQt6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QLabel,
    QLineEdit, QPushButton, QFrame, QListWidget,
    QListWidgetItem, QGroupBox, QFormLayout, QMessageBox,
    QComboBox, QTextEdit, QSpinBox
)
from PyQt6.QtCore import Qt


class ClassEditor(QWidget):
    """직업 에디터"""
    def __init__(self, main_window):
        super().__init__()
        self.main_window = main_window
        self.current_class = None
        self.setup_ui()
        self.load_classes()

    def setup_ui(self):
        layout = QHBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(0)

        # 왼쪽: 직업 목록
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
        header_label = QLabel("직업 목록")
        header_label.setStyleSheet("font-weight: bold; font-size: 14px;")
        header_layout.addWidget(header_label)

        new_btn = QPushButton("+")
        new_btn.setFixedSize(30, 30)
        new_btn.clicked.connect(self.new_class)
        header_layout.addWidget(new_btn)

        left_layout.addWidget(header)

        # 목록
        self.class_list = QListWidget()
        self.class_list.itemClicked.connect(self._on_class_selected)
        left_layout.addWidget(self.class_list)

        layout.addWidget(left_panel)

        # 오른쪽: 에디터
        right_panel = QWidget()
        right_layout = QVBoxLayout(right_panel)
        right_layout.setContentsMargins(24, 24, 24, 24)
        right_layout.setSpacing(16)

        # 기본 정보
        info_group = QGroupBox("직업 정보")
        info_layout = QFormLayout(info_group)
        info_layout.setSpacing(12)

        self.name_edit = QLineEdit()
        self.name_edit.setPlaceholderText("예: 전사")
        self.name_edit.textChanged.connect(self._update_id)
        info_layout.addRow("이름:", self.name_edit)

        self.id_edit = QLineEdit()
        self.id_edit.setPlaceholderText("예: warrior")
        info_layout.addRow("ID:", self.id_edit)

        self.desc_edit = QTextEdit()
        self.desc_edit.setPlaceholderText("직업 설명...")
        self.desc_edit.setMaximumHeight(80)
        info_layout.addRow("설명:", self.desc_edit)

        # 역할
        self.role_combo = QComboBox()
        self.role_combo.addItems(["딜러", "탱커", "힐러", "서포터", "컨트롤러"])
        info_layout.addRow("역할:", self.role_combo)

        # 공격 유형
        self.attack_type = QComboBox()
        self.attack_type.addItems(["근거리", "원거리", "마법"])
        info_layout.addRow("공격 유형:", self.attack_type)

        right_layout.addWidget(info_group)

        # 기본 스탯 보정
        stats_group = QGroupBox("기본 스탯 보정 (%)")
        stats_layout = QFormLayout(stats_group)

        self.hp_mod = QSpinBox()
        self.hp_mod.setRange(-50, 100)
        self.hp_mod.setValue(0)
        stats_layout.addRow("HP:", self.hp_mod)

        self.phys_atk_mod = QSpinBox()
        self.phys_atk_mod.setRange(-50, 100)
        stats_layout.addRow("물리 공격:", self.phys_atk_mod)

        self.mag_atk_mod = QSpinBox()
        self.mag_atk_mod.setRange(-50, 100)
        stats_layout.addRow("마법 공격:", self.mag_atk_mod)

        self.phys_def_mod = QSpinBox()
        self.phys_def_mod.setRange(-50, 100)
        stats_layout.addRow("물리 방어:", self.phys_def_mod)

        self.mag_def_mod = QSpinBox()
        self.mag_def_mod.setRange(-50, 100)
        stats_layout.addRow("마법 방어:", self.mag_def_mod)

        self.speed_mod = QSpinBox()
        self.speed_mod.setRange(-50, 100)
        stats_layout.addRow("이동 속도:", self.speed_mod)

        self.atk_range_mod = QSpinBox()
        self.atk_range_mod.setRange(-5, 10)
        stats_layout.addRow("공격 사거리:", self.atk_range_mod)

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
        self.tag_list.setMaximumHeight(80)
        tags_layout.addWidget(self.tag_list)

        remove_tag_btn = QPushButton("선택 태그 삭제")
        remove_tag_btn.clicked.connect(self._remove_tag)
        tags_layout.addWidget(remove_tag_btn)

        right_layout.addWidget(tags_group)
        right_layout.addStretch()

        # 하단 버튼
        button_layout = QHBoxLayout()

        save_btn = QPushButton("💾 저장")
        save_btn.setObjectName("successButton")
        save_btn.clicked.connect(self.save_current)
        button_layout.addWidget(save_btn)

        delete_btn = QPushButton("🗑️ 삭제")
        delete_btn.setObjectName("dangerButton")
        delete_btn.clicked.connect(self.delete_current)
        button_layout.addWidget(delete_btn)

        button_layout.addStretch()
        right_layout.addLayout(button_layout)

        layout.addWidget(right_panel)

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

    def load_classes(self):
        """직업 목록 로드"""
        self.class_list.clear()
        if hasattr(self.main_window, 'classes'):
            for class_id, cls in self.main_window.classes.items():
                icon = self._get_role_icon(cls.get('role', '딜러'))
                item = QListWidgetItem(f"{icon} {cls['name']}")
                item.setData(Qt.ItemDataRole.UserRole, class_id)
                self.class_list.addItem(item)

    def _get_role_icon(self, role: str) -> str:
        icons = {
            "딜러": "⚔️",
            "탱커": "🛡️",
            "힐러": "💚",
            "서포터": "✨",
            "컨트롤러": "🎯"
        }
        return icons.get(role, "⚔️")

    def new_class(self):
        """새 직업"""
        self.current_class = None
        self._clear_form()

    def _clear_form(self):
        self.name_edit.clear()
        self.id_edit.clear()
        self.desc_edit.clear()
        self.role_combo.setCurrentIndex(0)
        self.attack_type.setCurrentIndex(0)
        self.hp_mod.setValue(0)
        self.phys_atk_mod.setValue(0)
        self.mag_atk_mod.setValue(0)
        self.phys_def_mod.setValue(0)
        self.mag_def_mod.setValue(0)
        self.speed_mod.setValue(0)
        self.atk_range_mod.setValue(0)
        self.tag_list.clear()

    def _on_class_selected(self, item: QListWidgetItem):
        class_id = item.data(Qt.ItemDataRole.UserRole)
        if class_id and hasattr(self.main_window, 'classes') and class_id in self.main_window.classes:
            self.current_class = class_id
            cls = self.main_window.classes[class_id]
            self._load_class(cls)

    def _load_class(self, cls: dict):
        self.name_edit.setText(cls.get('name', ''))
        self.id_edit.setText(cls.get('id', ''))
        self.desc_edit.setPlainText(cls.get('description', ''))

        role_idx = self.role_combo.findText(cls.get('role', '딜러'))
        if role_idx >= 0:
            self.role_combo.setCurrentIndex(role_idx)

        atk_idx = self.attack_type.findText(cls.get('attack_type', '근거리'))
        if atk_idx >= 0:
            self.attack_type.setCurrentIndex(atk_idx)

        self.hp_mod.setValue(cls.get('hp_mod', 0))
        self.phys_atk_mod.setValue(cls.get('phys_atk_mod', 0))
        self.mag_atk_mod.setValue(cls.get('mag_atk_mod', 0))
        self.phys_def_mod.setValue(cls.get('phys_def_mod', 0))
        self.mag_def_mod.setValue(cls.get('mag_def_mod', 0))
        self.speed_mod.setValue(cls.get('speed_mod', 0))
        self.atk_range_mod.setValue(cls.get('atk_range_mod', 0))

        self.tag_list.clear()
        for tag in cls.get('tags', []):
            self.tag_list.addItem(tag)

    def save_current(self):
        if not self.name_edit.text():
            QMessageBox.warning(self, "경고", "직업 이름을 입력하세요.")
            return
        if not self.id_edit.text():
            QMessageBox.warning(self, "경고", "직업 ID를 입력하세요.")
            return

        cls = {
            'id': self.id_edit.text(),
            'name': self.name_edit.text(),
            'description': self.desc_edit.toPlainText(),
            'role': self.role_combo.currentText(),
            'attack_type': self.attack_type.currentText(),
            'hp_mod': self.hp_mod.value(),
            'phys_atk_mod': self.phys_atk_mod.value(),
            'mag_atk_mod': self.mag_atk_mod.value(),
            'phys_def_mod': self.phys_def_mod.value(),
            'mag_def_mod': self.mag_def_mod.value(),
            'speed_mod': self.speed_mod.value(),
            'atk_range_mod': self.atk_range_mod.value(),
            'tags': [self.tag_list.item(i).text() for i in range(self.tag_list.count())]
        }

        if not hasattr(self.main_window, 'classes'):
            self.main_window.classes = {}

        self.main_window.classes[cls['id']] = cls
        self.main_window.save_classes_csv()
        self.load_classes()
        QMessageBox.information(self, "저장 완료", f"직업 '{cls['name']}'이(가) 저장되었습니다.")

    def delete_current(self):
        if not self.current_class:
            return

        reply = QMessageBox.question(
            self, "삭제 확인",
            f"이 직업을 삭제하시겠습니까?",
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No
        )

        if reply == QMessageBox.StandardButton.Yes:
            if hasattr(self.main_window, 'classes') and self.current_class in self.main_window.classes:
                del self.main_window.classes[self.current_class]
                self.main_window.save_classes_csv()
            self.load_classes()
            self.new_class()
