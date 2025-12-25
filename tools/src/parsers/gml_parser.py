"""GML 데이터 파서"""
import re
from pathlib import Path
from typing import List, Tuple

from ..models import (
    Unit, UnitStats, UnitGrowth, UnitSprites, UnitSkillSlot,
    Skill, Effect, Targeting, AIHint,
    Race, UnitClass, Rarity, DamageType, EffectType,
    TargetBase, SelectMethod, AIType, DeployPosition
)


class GMLParser:
    """GML 파일에서 데이터를 파싱"""

    def __init__(self, project_path: Path):
        self.project_path = project_path
        self.scripts_dir = project_path / "scripts" / "scr_data"

    def parse_all(self) -> Tuple[List[Unit], List[Skill]]:
        """모든 GML 데이터 파싱"""
        units = []
        skills = []

        # 메인 데이터 파일
        main_file = self.scripts_dir / "scr_data.gml"
        if main_file.exists():
            content = main_file.read_text(encoding='utf-8')
            units.extend(self._parse_units(content))
            skills.extend(self._parse_skills(content))

        # 생성된 데이터 파일들도 확인
        for gml_file in self.scripts_dir.glob("*.gml"):
            if gml_file.name == "scr_data.gml":
                continue
            try:
                content = gml_file.read_text(encoding='utf-8')
                units.extend(self._parse_units(content))
                skills.extend(self._parse_skills(content))
            except Exception as e:
                print(f"파싱 오류 ({gml_file.name}): {e}")

        return units, skills

    def parse_races(self) -> dict:
        """종족 데이터 파싱"""
        races = {}

        for gml_file in self.scripts_dir.glob("*.gml"):
            try:
                content = gml_file.read_text(encoding='utf-8')
                parsed = self._parse_race_structs(content)
                races.update(parsed)
            except Exception as e:
                print(f"종족 파싱 오류 ({gml_file.name}): {e}")

        return races

    def parse_classes(self) -> dict:
        """직업 데이터 파싱"""
        classes = {}

        for gml_file in self.scripts_dir.glob("*.gml"):
            try:
                content = gml_file.read_text(encoding='utf-8')
                parsed = self._parse_class_structs(content)
                classes.update(parsed)
            except Exception as e:
                print(f"직업 파싱 오류 ({gml_file.name}): {e}")

        return classes

    def _parse_race_structs(self, content: str) -> dict:
        """종족 구조체 파싱"""
        races = {}

        # global.races.xxx = { ... }; 패턴 찾기
        pattern = r'global\.races\.(\w+)\s*=\s*\{([^;]+)\};'

        for match in re.finditer(pattern, content, re.DOTALL):
            race_id = match.group(1)
            struct_content = match.group(2)

            try:
                race = {
                    'id': race_id,
                    'name': self._extract_string(struct_content, 'name') or race_id,
                    'description': self._extract_string(struct_content, 'description') or '',
                    'hp_bonus': self._extract_number(struct_content, 'hp_bonus', 0),
                    'atk_bonus': self._extract_number(struct_content, 'atk_bonus', 0),
                    'def_bonus': self._extract_number(struct_content, 'def_bonus', 0),
                    'speed_bonus': self._extract_number(struct_content, 'speed_bonus', 0),
                    'tags': []
                }

                # 태그 파싱
                tags_match = re.search(r'tags\s*:\s*\[([^\]]*)\]', struct_content)
                if tags_match:
                    race['tags'] = self._parse_string_array(tags_match.group(1))

                races[race_id] = race
            except Exception as e:
                print(f"종족 파싱 오류 ({race_id}): {e}")

        return races

    def _parse_class_structs(self, content: str) -> dict:
        """직업 구조체 파싱"""
        classes = {}

        # global.classes.xxx = { ... }; 패턴 찾기
        pattern = r'global\.classes\.(\w+)\s*=\s*\{([^;]+)\};'

        for match in re.finditer(pattern, content, re.DOTALL):
            class_id = match.group(1)
            struct_content = match.group(2)

            try:
                cls = {
                    'id': class_id,
                    'name': self._extract_string(struct_content, 'name') or class_id,
                    'description': self._extract_string(struct_content, 'description') or '',
                    'role': self._extract_string(struct_content, 'role') or '딜러',
                    'attack_type': self._extract_string(struct_content, 'attack_type') or '근거리',
                    'hp_mod': self._extract_number(struct_content, 'hp_mod', 0),
                    'phys_atk_mod': self._extract_number(struct_content, 'phys_atk_mod', 0),
                    'mag_atk_mod': self._extract_number(struct_content, 'mag_atk_mod', 0),
                    'phys_def_mod': self._extract_number(struct_content, 'phys_def_mod', 0),
                    'mag_def_mod': self._extract_number(struct_content, 'mag_def_mod', 0),
                    'speed_mod': self._extract_number(struct_content, 'speed_mod', 0),
                    'atk_range_mod': self._extract_number(struct_content, 'atk_range_mod', 0),
                    'tags': []
                }

                # 태그 파싱
                tags_match = re.search(r'tags\s*:\s*\[([^\]]*)\]', struct_content)
                if tags_match:
                    cls['tags'] = self._parse_string_array(tags_match.group(1))

                classes[class_id] = cls
            except Exception as e:
                print(f"직업 파싱 오류 ({class_id}): {e}")

        return classes

    def _parse_units(self, content: str) -> List[Unit]:
        """유닛 데이터 파싱"""
        units = []

        # global.unit_templates.xxx = { ... }; 패턴 찾기
        pattern = r'global\.unit_templates\.(\w+)\s*=\s*\{([^;]+)\};'

        for match in re.finditer(pattern, content, re.DOTALL):
            unit_id = match.group(1)
            struct_content = match.group(2)

            try:
                unit = self._parse_unit_struct(unit_id, struct_content)
                if unit:
                    units.append(unit)
            except Exception as e:
                print(f"유닛 파싱 오류 ({unit_id}): {e}")

        return units

    def _parse_unit_struct(self, unit_id: str, content: str) -> Unit:
        """유닛 구조체 파싱"""
        unit = Unit(id=unit_id)

        # 기본 필드
        unit.name = self._extract_string(content, 'name') or unit_id
        unit.description = self._extract_string(content, 'description') or ""

        # Enum 필드
        race_id = self._extract_string(content, 'race')
        if race_id:
            unit.race = self._get_enum_by_id(Race, race_id, Race.HUMAN)

        class_id = self._extract_string(content, 'class')
        if class_id:
            unit.unit_class = self._get_enum_by_id(UnitClass, class_id, UnitClass.WARRIOR)

        rarity_id = self._extract_string(content, 'rarity')
        if rarity_id:
            unit.rarity = self._get_enum_by_id(Rarity, rarity_id, Rarity.C)

        ai_type_id = self._extract_string(content, 'ai_type')
        if ai_type_id:
            unit.ai_type = self._get_enum_by_id(AIType, ai_type_id, AIType.AI_MELEE_DPS)

        position_id = self._extract_string(content, 'deploy_position') or self._extract_string(content, 'preferred_position')
        if position_id:
            unit.preferred_position = self._get_enum_by_id(DeployPosition, position_id, DeployPosition.FC)

        # base_stats 파싱
        base_stats_match = re.search(r'base_stats\s*:\s*\{([^}]+)\}', content)
        if base_stats_match:
            stats_content = base_stats_match.group(1)
            unit.base_stats = self._parse_stats(stats_content)

        # secondary_stats 파싱 (base_stats에 합침)
        secondary_match = re.search(r'secondary_stats\s*:\s*\{([^}]+)\}', content)
        if secondary_match:
            self._parse_secondary_stats(secondary_match.group(1), unit.base_stats)

        # resistance 파싱
        resistance_match = re.search(r'resistance\s*:\s*\{([^}]+)\}', content)
        if resistance_match:
            self._parse_resistance(resistance_match.group(1), unit.base_stats)

        # growth_per_level 파싱
        growth_match = re.search(r'growth_per_level\s*:\s*\{([^}]*)\}', content)
        if growth_match:
            unit.growth = self._parse_growth(growth_match.group(1))

        # 스킬 파싱
        skills_match = re.search(r'skills\s*:\s*\[([^\]]*)\]', content)
        if skills_match:
            unit.skills = self._parse_skill_slots(skills_match.group(1))

        # 태그 파싱
        tags_match = re.search(r'tags\s*:\s*\[([^\]]*)\]', content)
        if tags_match:
            unit.tags = self._parse_string_array(tags_match.group(1))

        return unit

    def _parse_stats(self, content: str) -> UnitStats:
        """스탯 파싱"""
        stats = UnitStats()
        stats.hp = self._extract_number(content, 'hp', 500)
        stats.max_mana = self._extract_number(content, 'max_mana', 100)
        stats.physical_attack = self._extract_number(content, 'physical_attack', 50)
        stats.magic_attack = self._extract_number(content, 'magic_attack', 50)
        stats.physical_defense = self._extract_number(content, 'physical_defense', 30)
        stats.magic_defense = self._extract_number(content, 'magic_defense', 30)
        stats.attack_speed = self._extract_float(content, 'attack_speed', 1.0)
        stats.movement_speed = self._extract_number(content, 'movement_speed', 100)
        stats.attack_range = self._extract_number(content, 'attack_range', 1)
        return stats

    def _parse_secondary_stats(self, content: str, stats: UnitStats):
        """2차 스탯 파싱"""
        stats.crit_chance = self._extract_number(content, 'crit_chance', 10)
        stats.crit_damage = self._extract_number(content, 'crit_damage', 150)
        stats.dodge_chance = self._extract_number(content, 'dodge_chance', 5)
        stats.accuracy = self._extract_number(content, 'accuracy', 100)
        stats.physical_lifesteal = self._extract_number(content, 'physical_lifesteal', 0)
        stats.magic_lifesteal = self._extract_number(content, 'magic_lifesteal', 0)
        stats.healing_power = self._extract_number(content, 'healing_power', 0)
        stats.physical_penetration = self._extract_number(content, 'physical_penetration', 0)
        stats.magic_penetration = self._extract_number(content, 'magic_penetration', 0)
        stats.cooldown_reduction = self._extract_number(content, 'cooldown_reduction', 0)
        stats.mana_regen = self._extract_number(content, 'mana_regen', 5)
        stats.hp_regen = self._extract_number(content, 'hp_regen', 0)

    def _parse_resistance(self, content: str, stats: UnitStats):
        """저항 파싱"""
        stats.cc_resist = self._extract_number(content, 'cc_resist', 0)
        stats.debuff_resist = self._extract_number(content, 'debuff_resist', 0)

    def _parse_growth(self, content: str) -> UnitGrowth:
        """성장 스탯 파싱"""
        growth = UnitGrowth()
        growth.hp = self._extract_number(content, 'hp', 0)
        growth.mana = self._extract_number(content, 'mana', 0)
        growth.physical_attack = self._extract_number(content, 'physical_attack', 0)
        growth.magic_attack = self._extract_number(content, 'magic_attack', 0)
        growth.physical_defense = self._extract_number(content, 'physical_defense', 0)
        growth.magic_defense = self._extract_number(content, 'magic_defense', 0)
        return growth

    def _parse_skill_slots(self, content: str) -> List[UnitSkillSlot]:
        """스킬 슬롯 파싱"""
        slots = []

        # 문자열 배열 형태: ["skill1", "skill2"]
        string_skills = self._parse_string_array(content)
        for skill_id in string_skills:
            slots.append(UnitSkillSlot(skill_id=skill_id, unlock_level=1))

        # 객체 배열 형태: [{ skill_id: "x", unlock_level: 1 }]
        obj_pattern = r'\{\s*skill_id\s*:\s*"(\w+)"(?:\s*,\s*unlock_level\s*:\s*(\d+))?\s*\}'
        for match in re.finditer(obj_pattern, content):
            skill_id = match.group(1)
            unlock_level = int(match.group(2)) if match.group(2) else 1
            # 중복 방지
            if not any(s.skill_id == skill_id for s in slots):
                slots.append(UnitSkillSlot(skill_id=skill_id, unlock_level=unlock_level))

        return slots

    def _parse_skills(self, content: str) -> List[Skill]:
        """스킬 데이터 파싱"""
        skills = []

        # global.skills.xxx = { ... }; 패턴 찾기
        pattern = r'global\.skills\.(\w+)\s*=\s*\{([^;]+)\};'

        for match in re.finditer(pattern, content, re.DOTALL):
            skill_id = match.group(1)
            struct_content = match.group(2)

            try:
                skill = self._parse_skill_struct(skill_id, struct_content)
                if skill:
                    skills.append(skill)
            except Exception as e:
                print(f"스킬 파싱 오류 ({skill_id}): {e}")

        return skills

    def _parse_skill_struct(self, skill_id: str, content: str) -> Skill:
        """스킬 구조체 파싱"""
        skill = Skill(id=skill_id)

        skill.name = self._extract_string(content, 'name') or skill_id
        skill.description = self._extract_string(content, 'description') or ""
        skill.mana_cost = self._extract_number(content, 'mana_cost', 0)
        skill.cooldown = self._extract_float(content, 'cooldown', 1.0)
        skill.cast_time = self._extract_float(content, 'cast_time', 0.0)

        damage_type_id = self._extract_string(content, 'damage_type')
        if damage_type_id:
            skill.damage_type = self._get_enum_by_id(DamageType, damage_type_id, DamageType.PHYSICAL)

        skill.vfx = self._extract_string(content, 'vfx') or ""
        skill.sfx = self._extract_string(content, 'sfx') or ""

        # 타겟팅 파싱
        targeting_match = re.search(r'targeting\s*:\s*\{([^}]+)\}', content)
        if targeting_match:
            skill.targeting = self._parse_targeting(targeting_match.group(1))

        # 이펙트 파싱
        effects_match = re.search(r'effects\s*:\s*\[([^\]]+)\]', content, re.DOTALL)
        if effects_match:
            skill.effects = self._parse_effects(effects_match.group(1))

        return skill

    def _parse_targeting(self, content: str) -> Targeting:
        """타겟팅 파싱"""
        targeting = Targeting()

        base_id = self._extract_string(content, 'base')
        if base_id:
            targeting.base = self._get_enum_by_id(TargetBase, base_id, TargetBase.ENEMY)

        # select_method 또는 select 모두 지원
        method_id = self._extract_string(content, 'select_method') or self._extract_string(content, 'select')
        if method_id:
            targeting.select = self._get_enum_by_id(SelectMethod, method_id, SelectMethod.NEAREST)

        targeting.count = self._extract_number(content, 'count', 1)
        targeting.range = self._extract_number(content, 'range', 5)

        return targeting

    def _parse_effects(self, content: str) -> List[Effect]:
        """이펙트 배열 파싱"""
        effects = []

        # 각 이펙트 객체 찾기
        brace_count = 0
        current_effect = ""
        in_effect = False

        for char in content:
            if char == '{':
                brace_count += 1
                in_effect = True
            if in_effect:
                current_effect += char
            if char == '}':
                brace_count -= 1
                if brace_count == 0 and in_effect:
                    effect = self._parse_single_effect(current_effect)
                    if effect:
                        effects.append(effect)
                    current_effect = ""
                    in_effect = False

        return effects

    def _parse_single_effect(self, content: str) -> Effect:
        """단일 이펙트 파싱"""
        from ..models import Effect, DamageType

        effect_type_id = self._extract_string(content, 'type')
        if not effect_type_id:
            return None

        effect_type = self._get_enum_by_id(EffectType, effect_type_id, EffectType.DAMAGE)

        # Effect 객체 생성
        effect = Effect(effect_type=effect_type)

        # 공통 파라미터
        amount = self._extract_number(content, 'amount', 0)
        if amount == 0:
            amount = self._extract_number(content, 'base_amount', 0)
        effect.amount = amount

        effect.duration = self._extract_float(content, 'duration', 5.0)
        effect.scale_stat = self._extract_string(content, 'scale_stat') or ""
        effect.scale_percent = self._extract_number(content, 'scale_percent', 100)

        # damage_type
        damage_type_id = self._extract_string(content, 'damage_type')
        if damage_type_id:
            effect.damage_type = self._get_enum_by_id(DamageType, damage_type_id, DamageType.PHYSICAL)

        # 버프/디버프
        effect.stat = self._extract_string(content, 'stat') or ""
        effect.value = self._extract_number(content, 'value', 0)
        if effect.value == 0:
            effect.value = self._extract_number(content, 'percent', 0)
        effect.percent = 'percent: true' in content.lower() or 'is_percent: true' in content.lower()

        # DOT/HOT
        effect.tick_rate = self._extract_float(content, 'tick_rate', 1.0)
        if effect.tick_rate == 1.0:
            effect.tick_rate = self._extract_float(content, 'tick_interval', 1.0)

        # CC
        effect.cc_duration = self._extract_float(content, 'duration', 2.0)

        return effect

    # 유틸리티 메서드들
    def _extract_string(self, content: str, key: str) -> str:
        """문자열 값 추출"""
        pattern = rf'{key}\s*:\s*"([^"]*)"'
        match = re.search(pattern, content)
        return match.group(1) if match else None

    def _extract_number(self, content: str, key: str, default: int = 0) -> int:
        """숫자 값 추출"""
        pattern = rf'{key}\s*:\s*(-?\d+)'
        match = re.search(pattern, content)
        return int(match.group(1)) if match else default

    def _extract_float(self, content: str, key: str, default: float = 0.0) -> float:
        """실수 값 추출"""
        pattern = rf'{key}\s*:\s*(-?\d+\.?\d*)'
        match = re.search(pattern, content)
        return float(match.group(1)) if match else default

    def _parse_string_array(self, content: str) -> List[str]:
        """문자열 배열 파싱"""
        pattern = r'"(\w+)"'
        return re.findall(pattern, content)

    def _get_enum_by_id(self, enum_class, id_str: str, default):
        """ID로 Enum 값 찾기"""
        for member in enum_class:
            if member.id == id_str:
                return member
        return default
