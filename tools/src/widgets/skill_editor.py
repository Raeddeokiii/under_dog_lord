"""스킬 에디터 위젯"""
from PyQt6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QTabWidget, QLabel,
    QLineEdit, QComboBox, QSpinBox, QDoubleSpinBox,
    QPushButton, QFrame, QGridLayout, QScrollArea, QListWidget,
    QListWidgetItem, QGroupBox, QFormLayout, QTextEdit,
    QCheckBox, QMessageBox, QSplitter
)
from PyQt6.QtCore import Qt, pyqtSignal
from PyQt6.QtGui import QFont

from ..models import Skill, Effect, Targeting, AIHint
from ..models.enums import EffectType, DamageType, TargetBase, SelectMethod


class EffectWidget(QFrame):
    """효과 위젯"""
    removed = pyqtSignal(object)

    def __init__(self, effect: Effect = None, parent=None):
        super().__init__(parent)
        self.effect = effect or Effect()
        self.setObjectName("card")
        self.setup_ui()

    def setup_ui(self):
        layout = QVBoxLayout(self)
        layout.setContentsMargins(12, 12, 12, 12)
        layout.setSpacing(8)

        # 헤더
        header = QHBoxLayout()
        self.type_combo = QComboBox()
        for etype in EffectType:
            self.type_combo.addItem(etype.display_name, etype)
        self.type_combo.currentIndexChanged.connect(self._on_type_changed)
        header.addWidget(self.type_combo)

        remove_btn = QPushButton("✕")
        remove_btn.setFixedSize(24, 24)
        remove_btn.setStyleSheet("background: #dc3545; border-radius: 12px;")
        remove_btn.clicked.connect(lambda: self.removed.emit(self))
        header.addWidget(remove_btn)

        layout.addLayout(header)

        # 동적 필드 영역
        self.fields_widget = QWidget()
        self.fields_layout = QFormLayout(self.fields_widget)
        self.fields_layout.setSpacing(8)
        layout.addWidget(self.fields_widget)

        self._update_fields()

    def _on_type_changed(self, index):
        self.effect.effect_type = self.type_combo.itemData(index)
        self._update_fields()

    def _update_fields(self):
        # 기존 필드 제거
        while self.fields_layout.count():
            item = self.fields_layout.takeAt(0)
            if item.widget():
                item.widget().deleteLater()

        etype = self.effect.effect_type

        if etype in (EffectType.DAMAGE, EffectType.HEAL):
            self.amount_spin = QSpinBox()
            self.amount_spin.setMaximum(9999)
            self.amount_spin.setValue(self.effect.amount)
            self.fields_layout.addRow("수치:", self.amount_spin)

            if etype == EffectType.DAMAGE:
                self.dmg_type_combo = QComboBox()
                for dt in DamageType:
                    self.dmg_type_combo.addItem(dt.display_name, dt)
                self.fields_layout.addRow("데미지 타입:", self.dmg_type_combo)

        elif etype in (EffectType.BUFF, EffectType.DEBUFF):
            self.stat_edit = QLineEdit()
            self.stat_edit.setPlaceholderText("attack, defense, etc.")
            self.fields_layout.addRow("스탯:", self.stat_edit)

            self.value_spin = QSpinBox()
            self.value_spin.setMinimum(-999)
            self.value_spin.setMaximum(999)
            self.fields_layout.addRow("수치:", self.value_spin)

            self.duration_spin = QDoubleSpinBox()
            self.duration_spin.setMaximum(999)
            self.duration_spin.setValue(5.0)
            self.fields_layout.addRow("지속시간:", self.duration_spin)

        elif etype == EffectType.DOT:
            self.amount_spin = QSpinBox()
            self.amount_spin.setMaximum(9999)
            self.fields_layout.addRow("틱당 데미지:", self.amount_spin)

            self.duration_spin = QDoubleSpinBox()
            self.duration_spin.setMaximum(60)
            self.duration_spin.setValue(3.0)
            self.fields_layout.addRow("지속시간:", self.duration_spin)

            self.tick_spin = QDoubleSpinBox()
            self.tick_spin.setMinimum(0.1)
            self.tick_spin.setMaximum(10)
            self.tick_spin.setValue(1.0)
            self.fields_layout.addRow("틱 간격:", self.tick_spin)

        elif etype in (EffectType.STUN, EffectType.SILENCE, EffectType.ROOT, EffectType.FEAR):
            self.duration_spin = QDoubleSpinBox()
            self.duration_spin.setMaximum(30)
            self.duration_spin.setValue(2.0)
            self.fields_layout.addRow("지속시간:", self.duration_spin)

        elif etype == EffectType.SLOW:
            self.value_spin = QSpinBox()
            self.value_spin.setMaximum(99)
            self.value_spin.setValue(30)
            self.fields_layout.addRow("둔화 %:", self.value_spin)

            self.duration_spin = QDoubleSpinBox()
            self.duration_spin.setMaximum(30)
            self.duration_spin.setValue(3.0)
            self.fields_layout.addRow("지속시간:", self.duration_spin)

        elif etype == EffectType.SHIELD:
            self.amount_spin = QSpinBox()
            self.amount_spin.setMaximum(9999)
            self.amount_spin.setValue(100)
            self.fields_layout.addRow("보호막:", self.amount_spin)

            self.duration_spin = QDoubleSpinBox()
            self.duration_spin.setMaximum(60)
            self.duration_spin.setValue(5.0)
            self.fields_layout.addRow("지속시간:", self.duration_spin)

        elif etype == EffectType.AOE:
            self.radius_spin = QSpinBox()
            self.radius_spin.setMinimum(1)
            self.radius_spin.setMaximum(10)
            self.radius_spin.setValue(2)
            self.fields_layout.addRow("범위:", self.radius_spin)

            info = QLabel("(하위 효과는 별도 추가)")
            info.setObjectName("mutedLabel")
            self.fields_layout.addRow("", info)

    def get_effect(self) -> Effect:
        """효과 데이터 반환"""
        effect = Effect()
        effect.effect_type = self.type_combo.currentData()

        if hasattr(self, 'amount_spin'):
            effect.amount = self.amount_spin.value()
        if hasattr(self, 'dmg_type_combo'):
            effect.damage_type = self.dmg_type_combo.currentData()
        if hasattr(self, 'stat_edit'):
            effect.stat = self.stat_edit.text()
        if hasattr(self, 'value_spin'):
            effect.value = self.value_spin.value()
        if hasattr(self, 'duration_spin'):
            effect.duration = self.duration_spin.value()
            effect.cc_duration = self.duration_spin.value()
        if hasattr(self, 'tick_spin'):
            effect.tick_rate = self.tick_spin.value()
        if hasattr(self, 'radius_spin'):
            effect.radius = self.radius_spin.value()

        return effect


class SkillEditor(QWidget):
    """스킬 에디터"""
    def __init__(self, main_window):
        super().__init__()
        self.main_window = main_window
        self.current_skill: Skill | None = None
        self.effect_widgets: list[EffectWidget] = []
        self.setup_ui()

    def setup_ui(self):
        layout = QHBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(0)

        # 왼쪽: 스킬 목록
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
        header_label = QLabel("스킬 목록")
        header_label.setStyleSheet("font-weight: bold; font-size: 14px;")
        header_layout.addWidget(header_label)

        new_btn = QPushButton("+")
        new_btn.setFixedSize(30, 30)
        new_btn.clicked.connect(self.new_skill)
        header_layout.addWidget(new_btn)

        left_layout.addWidget(header)

        # 검색
        search_edit = QLineEdit()
        search_edit.setPlaceholderText("🔍 검색...")
        search_edit.setStyleSheet("margin: 8px; border-radius: 16px;")
        left_layout.addWidget(search_edit)

        # 목록
        self.skill_list = QListWidget()
        self.skill_list.itemClicked.connect(self._on_skill_selected)
        left_layout.addWidget(self.skill_list)

        layout.addWidget(left_panel)

        # 오른쪽: 에디터
        right_panel = QWidget()
        right_layout = QVBoxLayout(right_panel)
        right_layout.setContentsMargins(24, 24, 24, 24)
        right_layout.setSpacing(16)

        # 스크롤
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setFrameShape(QFrame.Shape.NoFrame)

        scroll_content = QWidget()
        scroll_layout = QVBoxLayout(scroll_content)
        scroll_layout.setSpacing(20)

        # 기본 정보
        basic_group = QGroupBox("기본 정보")
        basic_layout = QFormLayout(basic_group)
        basic_layout.setSpacing(12)

        self.name_edit = QLineEdit()
        self.name_edit.setPlaceholderText("예: 파이어볼")
        self.name_edit.textChanged.connect(self._update_id)
        basic_layout.addRow("이름:", self.name_edit)

        self.id_edit = QLineEdit()
        self.id_edit.setPlaceholderText("자동 생성")
        self.id_edit.setStyleSheet("color: #a0a0a0;")
        basic_layout.addRow("ID:", self.id_edit)

        self.desc_edit = QTextEdit()
        self.desc_edit.setPlaceholderText("스킬 설명...")
        self.desc_edit.setMaximumHeight(60)
        basic_layout.addRow("설명:", self.desc_edit)

        self.icon_edit = QLineEdit()
        self.icon_edit.setPlaceholderText("spr_skill_icon")
        basic_layout.addRow("아이콘:", self.icon_edit)

        scroll_layout.addWidget(basic_group)

        # 비용
        cost_group = QGroupBox("비용 및 쿨다운")
        cost_layout = QHBoxLayout(cost_group)

        cost_layout.addWidget(QLabel("마나:"))
        self.mana_spin = QSpinBox()
        self.mana_spin.setMaximum(999)
        self.mana_spin.setValue(30)
        cost_layout.addWidget(self.mana_spin)

        cost_layout.addSpacing(20)

        cost_layout.addWidget(QLabel("쿨다운:"))
        self.cooldown_spin = QDoubleSpinBox()
        self.cooldown_spin.setMaximum(300)
        self.cooldown_spin.setValue(5.0)
        self.cooldown_spin.setSuffix(" 초")
        cost_layout.addWidget(self.cooldown_spin)

        cost_layout.addStretch()
        scroll_layout.addWidget(cost_group)

        # 타겟팅
        target_group = QGroupBox("타겟팅")
        target_layout = QHBoxLayout(target_group)

        target_layout.addWidget(QLabel("대상:"))
        self.target_combo = QComboBox()
        for tb in TargetBase:
            self.target_combo.addItem(tb.display_name, tb)
        target_layout.addWidget(self.target_combo)

        target_layout.addWidget(QLabel("선택:"))
        self.select_combo = QComboBox()
        for sm in SelectMethod:
            self.select_combo.addItem(sm.display_name, sm)
        target_layout.addWidget(self.select_combo)

        target_layout.addWidget(QLabel("개수:"))
        self.count_spin = QSpinBox()
        self.count_spin.setMinimum(1)
        self.count_spin.setMaximum(99)
        self.count_spin.setValue(1)
        target_layout.addWidget(self.count_spin)

        target_layout.addStretch()
        scroll_layout.addWidget(target_group)

        # 효과 체인
        effects_group = QGroupBox("효과 체인")
        self.effects_layout = QVBoxLayout(effects_group)

        add_effect_btn = QPushButton("+ 효과 추가")
        add_effect_btn.clicked.connect(self._add_effect)
        self.effects_layout.addWidget(add_effect_btn)

        self.effects_container = QVBoxLayout()
        self.effects_layout.addLayout(self.effects_container)

        scroll_layout.addWidget(effects_group)

        # 연출
        vfx_group = QGroupBox("연출")
        vfx_layout = QFormLayout(vfx_group)

        self.vfx_cast_edit = QLineEdit()
        self.vfx_cast_edit.setPlaceholderText("vfx_cast_fire")
        vfx_layout.addRow("시전 VFX:", self.vfx_cast_edit)

        self.vfx_hit_edit = QLineEdit()
        self.vfx_hit_edit.setPlaceholderText("vfx_hit_fire")
        vfx_layout.addRow("적중 VFX:", self.vfx_hit_edit)

        self.sfx_cast_edit = QLineEdit()
        self.sfx_cast_edit.setPlaceholderText("sfx_fireball")
        vfx_layout.addRow("시전 SFX:", self.sfx_cast_edit)

        self.sfx_hit_edit = QLineEdit()
        self.sfx_hit_edit.setPlaceholderText("sfx_explosion")
        vfx_layout.addRow("적중 SFX:", self.sfx_hit_edit)

        scroll_layout.addWidget(vfx_group)
        scroll_layout.addStretch()

        scroll.setWidget(scroll_content)
        right_layout.addWidget(scroll)

        # 하단 버튼
        button_layout = QHBoxLayout()

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

    def _update_id(self, text: str):
        import re
        id_str = text.lower().replace(" ", "_")
        id_str = re.sub(r'[^a-z0-9_가-힣]', '', id_str)
        self.id_edit.setText(id_str)

    def _add_effect(self):
        widget = EffectWidget()
        widget.removed.connect(self._remove_effect)
        self.effect_widgets.append(widget)
        self.effects_container.addWidget(widget)

    def _remove_effect(self, widget: EffectWidget):
        self.effect_widgets.remove(widget)
        self.effects_container.removeWidget(widget)
        widget.deleteLater()

    def new_skill(self):
        """새 스킬"""
        self.current_skill = Skill()
        self._clear_form()

    def _clear_form(self):
        self.name_edit.clear()
        self.id_edit.clear()
        self.desc_edit.clear()
        self.icon_edit.clear()
        self.mana_spin.setValue(30)
        self.cooldown_spin.setValue(5.0)
        self.vfx_cast_edit.clear()
        self.vfx_hit_edit.clear()
        self.sfx_cast_edit.clear()
        self.sfx_hit_edit.clear()

        # 효과 위젯 제거
        for widget in self.effect_widgets[:]:
            self._remove_effect(widget)

    def _on_skill_selected(self, item: QListWidgetItem):
        skill_id = item.data(Qt.ItemDataRole.UserRole)
        if skill_id and skill_id in self.main_window.skills:
            self.current_skill = self.main_window.skills[skill_id]
            self._load_skill(self.current_skill)

    def _load_skill(self, skill: Skill):
        self.name_edit.setText(skill.name)
        self.id_edit.setText(skill.id)
        self.desc_edit.setPlainText(skill.description)
        self.icon_edit.setText(skill.icon)
        self.mana_spin.setValue(skill.mana_cost)
        self.cooldown_spin.setValue(skill.cooldown)
        self.vfx_cast_edit.setText(skill.vfx_on_cast)
        self.vfx_hit_edit.setText(skill.vfx_on_hit)
        self.sfx_cast_edit.setText(skill.sfx_on_cast)
        self.sfx_hit_edit.setText(skill.sfx_on_hit)

        # 타겟팅
        for i in range(self.target_combo.count()):
            if self.target_combo.itemData(i) == skill.targeting.base:
                self.target_combo.setCurrentIndex(i)
                break
        for i in range(self.select_combo.count()):
            if self.select_combo.itemData(i) == skill.targeting.select:
                self.select_combo.setCurrentIndex(i)
                break
        self.count_spin.setValue(skill.targeting.count)

        # 효과 로드 (TODO)

    def save_current(self):
        if not self.name_edit.text():
            QMessageBox.warning(self, "경고", "스킬 이름을 입력하세요.")
            return
        if not self.id_edit.text():
            QMessageBox.warning(self, "경고", "스킬 ID를 입력하세요.")
            return

        targeting = Targeting(
            base=self.target_combo.currentData(),
            select=self.select_combo.currentData(),
            count=self.count_spin.value()
        )

        effects = [w.get_effect() for w in self.effect_widgets]

        skill = Skill(
            id=self.id_edit.text(),
            name=self.name_edit.text(),
            description=self.desc_edit.toPlainText(),
            icon=self.icon_edit.text(),
            mana_cost=self.mana_spin.value(),
            cooldown=self.cooldown_spin.value(),
            targeting=targeting,
            effects=effects,
            vfx_on_cast=self.vfx_cast_edit.text(),
            vfx_on_hit=self.vfx_hit_edit.text(),
            sfx_on_cast=self.sfx_cast_edit.text(),
            sfx_on_hit=self.sfx_hit_edit.text(),
        )

        self.main_window.add_skill(skill)
        self._refresh_list()

        QMessageBox.information(self, "저장 완료", f"스킬 '{skill.name}'이(가) 저장되었습니다.")

    def cancel_edit(self):
        if self.current_skill and self.current_skill.id:
            self._load_skill(self.current_skill)
        else:
            self._clear_form()

    def delete_current(self):
        if not self.current_skill or not self.current_skill.id:
            return

        reply = QMessageBox.question(
            self, "삭제 확인",
            f"'{self.current_skill.name}'을(를) 삭제하시겠습니까?",
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No
        )

        if reply == QMessageBox.StandardButton.Yes:
            del self.main_window.skills[self.current_skill.id]
            self._refresh_list()
            self.new_skill()

    def _refresh_list(self):
        self.skill_list.clear()
        for skill_id, skill in self.main_window.skills.items():
            item = QListWidgetItem(f"✨ {skill.name}")
            item.setData(Qt.ItemDataRole.UserRole, skill_id)
            self.skill_list.addItem(item)

    def load_skills(self, skills: list):
        """스킬 목록 로드"""
        self.skill_list.clear()
        for skill in skills:
            item = QListWidgetItem(f"✨ {skill.name}")
            item.setData(Qt.ItemDataRole.UserRole, skill.id)
            self.skill_list.addItem(item)
