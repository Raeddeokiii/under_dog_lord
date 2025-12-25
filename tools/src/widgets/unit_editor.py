"""유닛 에디터 위젯"""
from PyQt6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QTabWidget, QLabel,
    QLineEdit, QComboBox, QSpinBox, QDoubleSpinBox, QSlider,
    QPushButton, QFrame, QGridLayout, QScrollArea, QListWidget,
    QListWidgetItem, QGroupBox, QSplitter, QFormLayout, QTextEdit,
    QRadioButton, QButtonGroup, QMessageBox
)
from PyQt6.QtCore import Qt, pyqtSignal
from PyQt6.QtGui import QFont

from ..models import Unit, UnitStats, UnitGrowth, UnitSprites, UnitSkillSlot
from ..models.enums import Race, UnitClass, Rarity, AIType, DeployPosition, SpriteState


class StatSlider(QWidget):
    """스탯 슬라이더"""
    valueChanged = pyqtSignal(int)

    def __init__(self, name: str, min_val: int, max_val: int, default: int = 0, parent=None):
        super().__init__(parent)
        self.name = name

        layout = QHBoxLayout(self)
        layout.setContentsMargins(0, 4, 0, 4)

        self.label = QLabel(name)
        self.label.setFixedWidth(100)

        self.slider = QSlider(Qt.Orientation.Horizontal)
        self.slider.setMinimum(min_val)
        self.slider.setMaximum(max_val)
        self.slider.setValue(default)
        self.slider.valueChanged.connect(self._on_value_changed)

        self.value_label = QLabel(str(default))
        self.value_label.setFixedWidth(60)
        self.value_label.setAlignment(Qt.AlignmentFlag.AlignRight)
        self.value_label.setStyleSheet("font-weight: bold; color: #e94560;")

        layout.addWidget(self.label)
        layout.addWidget(self.slider)
        layout.addWidget(self.value_label)

    def _on_value_changed(self, value):
        self.value_label.setText(str(value))
        self.valueChanged.emit(value)

    def value(self) -> int:
        return self.slider.value()

    def setValue(self, value: int):
        self.slider.setValue(value)


class StatSliderFloat(QWidget):
    """실수형 스탯 슬라이더"""
    valueChanged = pyqtSignal(float)

    def __init__(self, name: str, min_val: float, max_val: float, default: float = 0, step: float = 0.1, parent=None):
        super().__init__(parent)
        self.step = step
        self.multiplier = int(1 / step)

        layout = QHBoxLayout(self)
        layout.setContentsMargins(0, 4, 0, 4)

        self.label = QLabel(name)
        self.label.setFixedWidth(100)

        self.slider = QSlider(Qt.Orientation.Horizontal)
        self.slider.setMinimum(int(min_val * self.multiplier))
        self.slider.setMaximum(int(max_val * self.multiplier))
        self.slider.setValue(int(default * self.multiplier))
        self.slider.valueChanged.connect(self._on_value_changed)

        self.value_label = QLabel(f"{default:.1f}")
        self.value_label.setFixedWidth(60)
        self.value_label.setAlignment(Qt.AlignmentFlag.AlignRight)
        self.value_label.setStyleSheet("font-weight: bold; color: #e94560;")

        layout.addWidget(self.label)
        layout.addWidget(self.slider)
        layout.addWidget(self.value_label)

    def _on_value_changed(self, value):
        real_value = value / self.multiplier
        self.value_label.setText(f"{real_value:.1f}")
        self.valueChanged.emit(real_value)

    def value(self) -> float:
        return self.slider.value() / self.multiplier

    def setValue(self, value: float):
        self.slider.setValue(int(value * self.multiplier))


class BasicInfoTab(QWidget):
    """기본 정보 탭"""
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setup_ui()

    def setup_ui(self):
        layout = QVBoxLayout(self)
        layout.setContentsMargins(24, 24, 24, 24)
        layout.setSpacing(20)

        # 상단 - 미리보기 + 기본정보
        top_layout = QHBoxLayout()

        # 미리보기 (왼쪽)
        preview_group = QGroupBox("미리보기")
        preview_layout = QVBoxLayout(preview_group)
        preview_layout.setAlignment(Qt.AlignmentFlag.AlignCenter)

        self.preview_label = QLabel("🧙")
        self.preview_label.setFont(QFont("Segoe UI Emoji", 64))
        self.preview_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.preview_label.setStyleSheet("""
            background-color: #0d1b2a;
            border-radius: 16px;
            padding: 32px;
            min-width: 150px;
            min-height: 150px;
        """)

        preview_layout.addWidget(self.preview_label)
        top_layout.addWidget(preview_group)

        # 기본 정보 (오른쪽)
        info_group = QGroupBox("기본 정보")
        info_layout = QFormLayout(info_group)
        info_layout.setSpacing(12)

        self.name_edit = QLineEdit()
        self.name_edit.setPlaceholderText("예: 화염 마법사")
        info_layout.addRow("이름:", self.name_edit)

        self.id_edit = QLineEdit()
        self.id_edit.setPlaceholderText("자동 생성 (영문)")
        self.id_edit.setStyleSheet("color: #a0a0a0;")
        info_layout.addRow("ID:", self.id_edit)

        self.name_edit.textChanged.connect(self._update_id)

        self.desc_edit = QTextEdit()
        self.desc_edit.setPlaceholderText("유닛 설명...")
        self.desc_edit.setMaximumHeight(80)
        info_layout.addRow("설명:", self.desc_edit)

        top_layout.addWidget(info_group, stretch=1)
        layout.addLayout(top_layout)

        # 종족/직업/등급
        class_group = QGroupBox("분류")
        class_layout = QGridLayout(class_group)
        class_layout.setSpacing(16)

        # 종족
        class_layout.addWidget(QLabel("종족:"), 0, 0)
        self.race_combo = QComboBox()
        for race in Race:
            self.race_combo.addItem(race.display_name, race)
        class_layout.addWidget(self.race_combo, 0, 1)

        # 직업
        class_layout.addWidget(QLabel("직업:"), 0, 2)
        self.class_combo = QComboBox()
        for unit_class in UnitClass:
            self.class_combo.addItem(unit_class.display_name, unit_class)
        class_layout.addWidget(self.class_combo, 0, 3)

        # 등급
        class_layout.addWidget(QLabel("등급:"), 1, 0)
        rarity_layout = QHBoxLayout()
        self.rarity_group = QButtonGroup(self)
        for i, rarity in enumerate(Rarity):
            radio = QRadioButton(rarity.display_name)
            radio.setStyleSheet(f"color: {rarity.color};")
            self.rarity_group.addButton(radio, i)
            rarity_layout.addWidget(radio)
            if rarity == Rarity.C:
                radio.setChecked(True)
        rarity_layout.addStretch()
        class_layout.addLayout(rarity_layout, 1, 1, 1, 3)

        layout.addWidget(class_group)

        # AI 설정
        ai_group = QGroupBox("AI 설정")
        ai_layout = QHBoxLayout(ai_group)

        ai_layout.addWidget(QLabel("AI 타입:"))
        self.ai_combo = QComboBox()
        for ai in AIType:
            self.ai_combo.addItem(ai.display_name, ai)
        ai_layout.addWidget(self.ai_combo)

        ai_layout.addSpacing(32)

        ai_layout.addWidget(QLabel("선호 위치:"))
        self.position_combo = QComboBox()
        for pos in DeployPosition:
            self.position_combo.addItem(f"{pos.id} - {pos.display_name}", pos)
        ai_layout.addWidget(self.position_combo)

        ai_layout.addStretch()
        layout.addWidget(ai_group)

        # 태그
        tag_group = QGroupBox("태그")
        tag_layout = QVBoxLayout(tag_group)

        self.tag_edit = QLineEdit()
        self.tag_edit.setPlaceholderText("태그 입력 후 Enter (예: fire, magical)")
        self.tag_edit.returnPressed.connect(self._add_tag)
        tag_layout.addWidget(self.tag_edit)

        self.tag_list = QListWidget()
        self.tag_list.setFlow(QListWidget.Flow.LeftToRight)
        self.tag_list.setWrapping(True)
        self.tag_list.setMaximumHeight(60)
        tag_layout.addWidget(self.tag_list)

        layout.addWidget(tag_group)
        layout.addStretch()

    def _update_id(self, text: str):
        import re
        id_str = text.lower().replace(" ", "_")
        id_str = re.sub(r'[^a-z0-9_가-힣]', '', id_str)
        # 한글은 임시로 유지, 나중에 영문 입력 유도
        self.id_edit.setText(id_str)

    def _add_tag(self):
        tag = self.tag_edit.text().strip()
        if tag:
            item = QListWidgetItem(tag)
            item.setBackground(Qt.GlobalColor.darkCyan)
            self.tag_list.addItem(item)
            self.tag_edit.clear()

    def get_data(self) -> dict:
        """입력된 데이터 반환"""
        tags = [self.tag_list.item(i).text() for i in range(self.tag_list.count())]
        rarity_idx = self.rarity_group.checkedId()
        rarity = list(Rarity)[rarity_idx] if rarity_idx >= 0 else Rarity.C

        return {
            'name': self.name_edit.text(),
            'id': self.id_edit.text(),
            'description': self.desc_edit.toPlainText(),
            'race': self.race_combo.currentData(),
            'unit_class': self.class_combo.currentData(),
            'rarity': rarity,
            'ai_type': self.ai_combo.currentData(),
            'position': self.position_combo.currentData(),
            'tags': tags,
        }

    def set_data(self, unit: Unit):
        """데이터 설정"""
        self.name_edit.setText(unit.name)
        self.id_edit.setText(unit.id)
        self.desc_edit.setPlainText(unit.description)

        # 콤보박스 설정
        for i in range(self.race_combo.count()):
            if self.race_combo.itemData(i) == unit.race:
                self.race_combo.setCurrentIndex(i)
                break

        for i in range(self.class_combo.count()):
            if self.class_combo.itemData(i) == unit.unit_class:
                self.class_combo.setCurrentIndex(i)
                break

        # 등급
        for i, rarity in enumerate(Rarity):
            if rarity == unit.rarity:
                self.rarity_group.button(i).setChecked(True)
                break

        # 태그
        self.tag_list.clear()
        for tag in unit.tags:
            item = QListWidgetItem(tag)
            self.tag_list.addItem(item)


class StatsTab(QWidget):
    """스탯 탭"""
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setup_ui()

    def setup_ui(self):
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setFrameShape(QFrame.Shape.NoFrame)

        content = QWidget()
        layout = QVBoxLayout(content)
        layout.setContentsMargins(24, 24, 24, 24)
        layout.setSpacing(20)

        # 1차 스탯
        primary_group = QGroupBox("1차 스탯")
        primary_layout = QVBoxLayout(primary_group)

        self.hp_slider = StatSlider("HP", 100, 5000, 500)
        self.mana_slider = StatSlider("마나", 0, 500, 100)
        self.phys_atk_slider = StatSlider("물리 공격력", 0, 500, 50)
        self.mag_atk_slider = StatSlider("마법 공격력", 0, 500, 50)
        self.phys_def_slider = StatSlider("물리 방어력", 0, 200, 30)
        self.mag_def_slider = StatSlider("마법 방어력", 0, 200, 30)
        self.atk_speed_slider = StatSliderFloat("공격 속도", 0.1, 3.0, 1.0, 0.1)
        self.move_speed_slider = StatSlider("이동 속도", 50, 200, 100)
        self.range_slider = StatSlider("사거리", 1, 10, 1)

        for slider in [self.hp_slider, self.mana_slider, self.phys_atk_slider,
                       self.mag_atk_slider, self.phys_def_slider, self.mag_def_slider,
                       self.atk_speed_slider, self.move_speed_slider, self.range_slider]:
            primary_layout.addWidget(slider)

        layout.addWidget(primary_group)

        # 2차 스탯
        secondary_group = QGroupBox("2차 스탯")
        secondary_layout = QVBoxLayout(secondary_group)

        self.crit_chance_slider = StatSlider("치명타 확률", 0, 100, 10)
        self.crit_damage_slider = StatSlider("치명타 데미지", 100, 300, 150)
        self.dodge_slider = StatSlider("회피율", 0, 50, 5)
        self.accuracy_slider = StatSlider("명중률", 50, 150, 100)
        self.phys_pen_slider = StatSlider("물리 관통", 0, 50, 0)
        self.mag_pen_slider = StatSlider("마법 관통", 0, 50, 0)
        self.mana_regen_slider = StatSlider("마나 재생", 0, 30, 5)
        self.hp_regen_slider = StatSlider("HP 재생", 0, 50, 0)

        for slider in [self.crit_chance_slider, self.crit_damage_slider,
                       self.dodge_slider, self.accuracy_slider,
                       self.phys_pen_slider, self.mag_pen_slider,
                       self.mana_regen_slider, self.hp_regen_slider]:
            secondary_layout.addWidget(slider)

        layout.addWidget(secondary_group)

        # 레벨당 성장
        growth_group = QGroupBox("레벨당 성장")
        growth_layout = QVBoxLayout(growth_group)

        self.hp_growth = StatSlider("HP 성장", 0, 100, 30)
        self.mana_growth = StatSlider("마나 성장", 0, 30, 5)
        self.phys_atk_growth = StatSlider("물리공격 성장", 0, 20, 3)
        self.mag_atk_growth = StatSlider("마법공격 성장", 0, 20, 3)
        self.phys_def_growth = StatSlider("물리방어 성장", 0, 10, 2)
        self.mag_def_growth = StatSlider("마법방어 성장", 0, 10, 2)

        for slider in [self.hp_growth, self.mana_growth,
                       self.phys_atk_growth, self.mag_atk_growth,
                       self.phys_def_growth, self.mag_def_growth]:
            growth_layout.addWidget(slider)

        layout.addWidget(growth_group)
        layout.addStretch()

        scroll.setWidget(content)

        main_layout = QVBoxLayout(self)
        main_layout.setContentsMargins(0, 0, 0, 0)
        main_layout.addWidget(scroll)

    def get_stats(self) -> UnitStats:
        return UnitStats(
            hp=self.hp_slider.value(),
            max_mana=self.mana_slider.value(),
            physical_attack=self.phys_atk_slider.value(),
            magic_attack=self.mag_atk_slider.value(),
            physical_defense=self.phys_def_slider.value(),
            magic_defense=self.mag_def_slider.value(),
            attack_speed=self.atk_speed_slider.value(),
            movement_speed=self.move_speed_slider.value(),
            attack_range=self.range_slider.value(),
            crit_chance=self.crit_chance_slider.value(),
            crit_damage=self.crit_damage_slider.value(),
            dodge_chance=self.dodge_slider.value(),
            accuracy=self.accuracy_slider.value(),
            physical_penetration=self.phys_pen_slider.value(),
            magic_penetration=self.mag_pen_slider.value(),
            mana_regen=self.mana_regen_slider.value(),
            hp_regen=self.hp_regen_slider.value(),
        )

    def get_growth(self) -> UnitGrowth:
        return UnitGrowth(
            hp=self.hp_growth.value(),
            mana=self.mana_growth.value(),
            physical_attack=self.phys_atk_growth.value(),
            magic_attack=self.mag_atk_growth.value(),
            physical_defense=self.phys_def_growth.value(),
            magic_defense=self.mag_def_growth.value(),
        )

    def set_data(self, unit: Unit):
        self.hp_slider.setValue(unit.base_stats.hp)
        self.mana_slider.setValue(unit.base_stats.max_mana)
        self.phys_atk_slider.setValue(unit.base_stats.physical_attack)
        self.mag_atk_slider.setValue(unit.base_stats.magic_attack)
        self.phys_def_slider.setValue(unit.base_stats.physical_defense)
        self.mag_def_slider.setValue(unit.base_stats.magic_defense)
        self.atk_speed_slider.setValue(unit.base_stats.attack_speed)
        self.move_speed_slider.setValue(unit.base_stats.movement_speed)
        self.range_slider.setValue(unit.base_stats.attack_range)

        self.crit_chance_slider.setValue(unit.base_stats.crit_chance)
        self.crit_damage_slider.setValue(unit.base_stats.crit_damage)
        self.dodge_slider.setValue(unit.base_stats.dodge_chance)
        self.accuracy_slider.setValue(unit.base_stats.accuracy)
        self.phys_pen_slider.setValue(unit.base_stats.physical_penetration)
        self.mag_pen_slider.setValue(unit.base_stats.magic_penetration)
        self.mana_regen_slider.setValue(unit.base_stats.mana_regen)
        self.hp_regen_slider.setValue(unit.base_stats.hp_regen)

        self.hp_growth.setValue(unit.growth.hp)
        self.mana_growth.setValue(unit.growth.mana)
        self.phys_atk_growth.setValue(unit.growth.physical_attack)
        self.mag_atk_growth.setValue(unit.growth.magic_attack)
        self.phys_def_growth.setValue(unit.growth.physical_defense)
        self.mag_def_growth.setValue(unit.growth.magic_defense)


class SpritesTab(QWidget):
    """스프라이트 탭"""
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setup_ui()

    def setup_ui(self):
        layout = QHBoxLayout(self)
        layout.setContentsMargins(24, 24, 24, 24)
        layout.setSpacing(20)

        # 왼쪽: 상태별 스프라이트 목록
        left_group = QGroupBox("상태별 스프라이트")
        left_layout = QVBoxLayout(left_group)

        self.sprite_inputs = {}
        for state in SpriteState:
            row = QHBoxLayout()
            label = QLabel(f"{state.display_name}:")
            label.setFixedWidth(60)
            edit = QLineEdit()
            edit.setPlaceholderText(f"spr_unit_{state.id}")
            browse_btn = QPushButton("...")
            browse_btn.setFixedWidth(40)

            row.addWidget(label)
            row.addWidget(edit)
            row.addWidget(browse_btn)

            left_layout.addLayout(row)
            self.sprite_inputs[state] = edit

        left_layout.addStretch()
        layout.addWidget(left_group)

        # 오른쪽: 미리보기
        right_group = QGroupBox("미리보기")
        right_layout = QVBoxLayout(right_group)
        right_layout.setAlignment(Qt.AlignmentFlag.AlignCenter)

        self.preview = QLabel("스프라이트 미리보기")
        self.preview.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.preview.setStyleSheet("""
            background-color: #0d1b2a;
            border-radius: 16px;
            padding: 64px;
            min-width: 200px;
            min-height: 200px;
        """)
        right_layout.addWidget(self.preview)

        state_combo = QComboBox()
        for state in SpriteState:
            state_combo.addItem(state.display_name, state)
        right_layout.addWidget(state_combo)

        layout.addWidget(right_group)

    def get_sprites(self) -> UnitSprites:
        sprites = UnitSprites()
        for state, edit in self.sprite_inputs.items():
            sprites.set(state, edit.text())
        return sprites

    def set_data(self, unit: Unit):
        for state, edit in self.sprite_inputs.items():
            edit.setText(unit.sprites.get(state))


class SkillsTab(QWidget):
    """스킬 탭"""
    def __init__(self, main_window, parent=None):
        super().__init__(parent)
        self.main_window = main_window
        self.skill_slots: list[UnitSkillSlot] = []
        self.setup_ui()

    def setup_ui(self):
        layout = QVBoxLayout(self)
        layout.setContentsMargins(24, 24, 24, 24)
        layout.setSpacing(20)

        # 스킬 타임라인
        timeline_group = QGroupBox("스킬 해금 타임라인")
        timeline_layout = QVBoxLayout(timeline_group)

        info_label = QLabel("레벨별로 해금되는 스킬을 설정합니다.")
        info_label.setObjectName("mutedLabel")
        timeline_layout.addWidget(info_label)

        # 스킬 목록
        self.skill_list = QListWidget()
        self.skill_list.setMaximumHeight(200)
        timeline_layout.addWidget(self.skill_list)

        # 추가 버튼
        add_layout = QHBoxLayout()
        self.level_spin = QSpinBox()
        self.level_spin.setMinimum(1)
        self.level_spin.setMaximum(100)
        self.level_spin.setValue(1)
        add_layout.addWidget(QLabel("레벨:"))
        add_layout.addWidget(self.level_spin)

        self.skill_combo = QComboBox()
        self.skill_combo.setMinimumWidth(200)
        self.skill_combo.addItem("스킬 선택...", None)
        # TODO: 스킬 목록 로드
        add_layout.addWidget(self.skill_combo)

        add_btn = QPushButton("+ 스킬 추가")
        add_btn.clicked.connect(self._add_skill)
        add_layout.addWidget(add_btn)

        remove_btn = QPushButton("선택 삭제")
        remove_btn.setObjectName("dangerButton")
        remove_btn.clicked.connect(self._remove_skill)
        add_layout.addWidget(remove_btn)

        add_layout.addStretch()
        timeline_layout.addLayout(add_layout)

        layout.addWidget(timeline_group)

        # 새 스킬 만들기
        new_skill_btn = QPushButton("✨ 새 스킬 만들기")
        new_skill_btn.setObjectName("primaryButton")
        new_skill_btn.clicked.connect(self._new_skill)
        layout.addWidget(new_skill_btn)

        layout.addStretch()

    def _add_skill(self):
        skill_data = self.skill_combo.currentData()
        if skill_data is None:
            return

        level = self.level_spin.value()
        slot = UnitSkillSlot(skill_id=skill_data, unlock_level=level)
        self.skill_slots.append(slot)

        item = QListWidgetItem(f"Lv.{level}: {skill_data}")
        self.skill_list.addItem(item)

    def _remove_skill(self):
        row = self.skill_list.currentRow()
        if row >= 0:
            self.skill_list.takeItem(row)
            del self.skill_slots[row]

    def _new_skill(self):
        self.main_window.new_skill()

    def get_skills(self) -> list[UnitSkillSlot]:
        return self.skill_slots

    def set_data(self, unit: Unit):
        self.skill_list.clear()
        self.skill_slots = list(unit.skills)
        for slot in self.skill_slots:
            item = QListWidgetItem(f"Lv.{slot.unlock_level}: {slot.skill_id}")
            self.skill_list.addItem(item)

    def refresh_skill_list(self):
        """스킬 콤보박스 갱신"""
        self.skill_combo.clear()
        self.skill_combo.addItem("스킬 선택...", None)
        for skill_id, skill in self.main_window.skills.items():
            self.skill_combo.addItem(skill.name, skill_id)


class UnitEditor(QWidget):
    """유닛 에디터"""
    def __init__(self, main_window):
        super().__init__()
        self.main_window = main_window
        self.current_unit: Unit | None = None
        self.setup_ui()

    def setup_ui(self):
        layout = QHBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(0)

        # 왼쪽: 유닛 목록
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
        header_label = QLabel("유닛 목록")
        header_label.setStyleSheet("font-weight: bold; font-size: 14px;")
        header_layout.addWidget(header_label)

        new_btn = QPushButton("+")
        new_btn.setFixedSize(30, 30)
        new_btn.clicked.connect(self.new_unit)
        header_layout.addWidget(new_btn)

        left_layout.addWidget(header)

        # 검색
        search_edit = QLineEdit()
        search_edit.setPlaceholderText("🔍 검색...")
        search_edit.setStyleSheet("margin: 8px; border-radius: 16px;")
        left_layout.addWidget(search_edit)

        # 목록
        self.unit_list = QListWidget()
        self.unit_list.itemClicked.connect(self._on_unit_selected)
        left_layout.addWidget(self.unit_list)

        layout.addWidget(left_panel)

        # 오른쪽: 에디터
        right_panel = QWidget()
        right_layout = QVBoxLayout(right_panel)
        right_layout.setContentsMargins(0, 0, 0, 0)

        # 탭
        self.tabs = QTabWidget()
        self.basic_tab = BasicInfoTab()
        self.stats_tab = StatsTab()
        self.sprites_tab = SpritesTab()
        self.skills_tab = SkillsTab(self.main_window)

        self.tabs.addTab(self.basic_tab, "기본정보")
        self.tabs.addTab(self.stats_tab, "스탯")
        self.tabs.addTab(self.sprites_tab, "스프라이트")
        self.tabs.addTab(self.skills_tab, "스킬")

        right_layout.addWidget(self.tabs)

        # 하단 버튼
        button_layout = QHBoxLayout()
        button_layout.setContentsMargins(16, 8, 16, 16)

        save_btn = QPushButton("💾 저장")
        save_btn.setObjectName("successButton")
        save_btn.clicked.connect(self.save_current)
        button_layout.addWidget(save_btn)

        cancel_btn = QPushButton("↩️ 취소")
        cancel_btn.clicked.connect(self.cancel_edit)
        button_layout.addWidget(cancel_btn)

        delete_btn = QPushButton("🗑️ 삭제")
        delete_btn.setObjectName("dangerButton")
        delete_btn.clicked.connect(self.delete_current)
        button_layout.addWidget(delete_btn)

        button_layout.addStretch()
        right_layout.addLayout(button_layout)

        layout.addWidget(right_panel)

    def new_unit(self):
        """새 유닛"""
        self.current_unit = Unit()
        self._clear_form()
        self.tabs.setCurrentIndex(0)

    def _clear_form(self):
        """폼 초기화"""
        self.basic_tab.name_edit.clear()
        self.basic_tab.id_edit.clear()
        self.basic_tab.desc_edit.clear()
        self.basic_tab.tag_list.clear()

    def _on_unit_selected(self, item: QListWidgetItem):
        """유닛 선택"""
        unit_id = item.data(Qt.ItemDataRole.UserRole)
        if unit_id and unit_id in self.main_window.units:
            self.current_unit = self.main_window.units[unit_id]
            self._load_unit(self.current_unit)

    def _load_unit(self, unit: Unit):
        """유닛 로드"""
        self.basic_tab.set_data(unit)
        self.stats_tab.set_data(unit)
        self.sprites_tab.set_data(unit)
        self.skills_tab.set_data(unit)

    def save_current(self):
        """현재 유닛 저장"""
        basic_data = self.basic_tab.get_data()

        if not basic_data['name']:
            QMessageBox.warning(self, "경고", "유닛 이름을 입력하세요.")
            return

        if not basic_data['id']:
            QMessageBox.warning(self, "경고", "유닛 ID를 입력하세요.")
            return

        unit = Unit(
            id=basic_data['id'],
            name=basic_data['name'],
            description=basic_data['description'],
            race=basic_data['race'],
            unit_class=basic_data['unit_class'],
            rarity=basic_data['rarity'],
            tags=basic_data['tags'],
            ai_type=basic_data['ai_type'],
            preferred_position=basic_data['position'],
            base_stats=self.stats_tab.get_stats(),
            growth=self.stats_tab.get_growth(),
            sprites=self.sprites_tab.get_sprites(),
            skills=self.skills_tab.get_skills(),
        )

        self.main_window.add_unit(unit)
        self._refresh_list()

        QMessageBox.information(self, "저장 완료", f"유닛 '{unit.name}'이(가) 저장되었습니다.")

    def cancel_edit(self):
        """편집 취소"""
        if self.current_unit and self.current_unit.id:
            self._load_unit(self.current_unit)
        else:
            self._clear_form()

    def delete_current(self):
        """현재 유닛 삭제"""
        if not self.current_unit or not self.current_unit.id:
            return

        reply = QMessageBox.question(
            self, "삭제 확인",
            f"'{self.current_unit.name}'을(를) 삭제하시겠습니까?",
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No
        )

        if reply == QMessageBox.StandardButton.Yes:
            del self.main_window.units[self.current_unit.id]
            self._refresh_list()
            self.new_unit()

    def _refresh_list(self):
        """목록 갱신"""
        self.unit_list.clear()
        for unit_id, unit in self.main_window.units.items():
            item = QListWidgetItem(f"⚔️ {unit.name}")
            item.setData(Qt.ItemDataRole.UserRole, unit_id)
            self.unit_list.addItem(item)

        # 스킬 탭의 스킬 목록도 갱신
        self.skills_tab.refresh_skill_list()

    def load_units(self, units: list):
        """유닛 목록 로드"""
        self.unit_list.clear()
        for unit in units:
            item = QListWidgetItem(f"⚔️ {unit.name}")
            item.setData(Qt.ItemDataRole.UserRole, unit.id)
            self.unit_list.addItem(item)

        # 스킬 탭의 스킬 목록도 갱신
        self.skills_tab.refresh_skill_list()
