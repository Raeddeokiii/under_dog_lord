"""GML 코드 생성기"""
import re
from pathlib import Path
from typing import List
from datetime import datetime

from ..models import Unit, Skill


class GMLExporter:
    """GameMaker Language 코드 익스포터"""

    def __init__(self, project_path: Path):
        self.project_path = project_path
        self.output_dir = project_path / "scripts" / "scr_data"
        self.scr_data_file = self.output_dir / "scr_data.gml"

    def export_units(self, units: List[Unit]) -> int:
        """유닛 데이터를 GML로 내보내기"""
        if not units:
            return 0

        gml_code = self._generate_unit_gml(units)
        self._write_to_file("scr_unit_data.gml", gml_code)
        return len(units)

    def export_skills(self, skills: List[Skill]) -> int:
        """스킬 데이터를 GML로 내보내기"""
        if not skills:
            return 0

        gml_code = self._generate_skill_gml(skills)
        self._write_to_file("scr_skill_data.gml", gml_code)
        return len(skills)

    def export_races(self, races: dict) -> int:
        """종족 데이터를 scr_data.gml의 init_race_data 함수 교체"""
        if not races:
            return 0

        new_func = self._generate_race_function(races)
        self._replace_function_in_scr_data("init_race_data", new_func)
        return len(races)

    def export_classes(self, classes: dict) -> int:
        """직업 데이터를 scr_data.gml의 init_class_data 함수 교체"""
        if not classes:
            return 0

        new_func = self._generate_class_function(classes)
        self._replace_function_in_scr_data("init_class_data", new_func)
        return len(classes)

    def _replace_function_in_scr_data(self, func_name: str, new_func_body: str):
        """scr_data.gml에서 기존 함수를 새 함수로 교체 (중괄호 카운팅 방식)"""
        if not self.scr_data_file.exists():
            print(f"scr_data.gml not found: {self.scr_data_file}")
            return

        with open(self.scr_data_file, 'r', encoding='utf-8') as f:
            content = f.read()

        # 함수 시작 위치 찾기
        func_pattern = rf'function\s+{func_name}\s*\(\s*\)\s*\{{'
        match = re.search(func_pattern, content)

        if match:
            start_idx = match.start()
            # 첫 번째 { 위치부터 중괄호 카운팅
            brace_start = match.end() - 1
            brace_count = 1
            end_idx = brace_start + 1

            while end_idx < len(content) and brace_count > 0:
                if content[end_idx] == '{':
                    brace_count += 1
                elif content[end_idx] == '}':
                    brace_count -= 1
                end_idx += 1

            # 기존 함수 교체
            content = content[:start_idx] + new_func_body + content[end_idx:]
        else:
            # 함수가 없으면 파일 끝에 추가
            content += f"\n\n{new_func_body}"

        with open(self.scr_data_file, 'w', encoding='utf-8') as f:
            f.write(content)

    def _generate_unit_gml(self, units: List[Unit]) -> str:
        """유닛 GML 코드 생성"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        lines = [
            f"/// @file scr_unit_data.gml",
            f"/// @desc 유닛 데이터 (자동 생성: {timestamp})",
            f"/// @generated UDL Content Editor",
            "",
            "function init_unit_data_generated() {",
            "    // 기존 데이터에 추가",
            "    if (!variable_global_exists(\"unit_templates\")) {",
            "        global.unit_templates = {};",
            "    }",
            "",
        ]

        for unit in units:
            lines.extend(self._generate_unit_struct(unit))
            lines.append("")

        lines.append("}")
        return "\n".join(lines)

    def _generate_unit_struct(self, unit: Unit) -> List[str]:
        """단일 유닛 구조체 생성"""
        indent = "    "
        stats = unit.base_stats
        lines = [
            f"{indent}// {unit.name}",
            f"{indent}global.unit_templates.{unit.id} = {{",
            f"{indent}    type: \"{unit.id}\",",
            f"{indent}    name: \"{unit.name}\",",
            f"{indent}    race: \"{unit.race.id}\",",
            f"{indent}    class: \"{unit.unit_class.id}\",",
            f"{indent}    rarity: \"{unit.rarity.id}\",",
            f"{indent}    ai_type: \"{unit.ai_type.id}\",",
            f"{indent}    deploy_position: \"{unit.preferred_position.id}\",",
            "",
            f"{indent}    base_stats: {{",
            f"{indent}        hp: {stats.hp},",
            f"{indent}        max_mana: {stats.max_mana},",
            f"{indent}        physical_attack: {stats.physical_attack},",
            f"{indent}        magic_attack: {stats.magic_attack},",
            f"{indent}        physical_defense: {stats.physical_defense},",
            f"{indent}        magic_defense: {stats.magic_defense},",
            f"{indent}        attack_speed: {stats.attack_speed},",
            f"{indent}        movement_speed: {stats.movement_speed},",
            f"{indent}        attack_range: {stats.attack_range}",
            f"{indent}    }},",
            "",
            f"{indent}    secondary_stats: {{",
            f"{indent}        crit_chance: {stats.crit_chance},",
            f"{indent}        crit_damage: {stats.crit_damage},",
            f"{indent}        dodge_chance: {stats.dodge_chance},",
            f"{indent}        accuracy: {stats.accuracy},",
            f"{indent}        physical_lifesteal: {stats.physical_lifesteal},",
            f"{indent}        magic_lifesteal: {stats.magic_lifesteal},",
            f"{indent}        healing_power: {stats.healing_power},",
            f"{indent}        physical_penetration: {stats.physical_penetration},",
            f"{indent}        magic_penetration: {stats.magic_penetration},",
            f"{indent}        cooldown_reduction: {stats.cooldown_reduction},",
            f"{indent}        mana_regen: {stats.mana_regen},",
            f"{indent}        hp_regen: {stats.hp_regen}",
            f"{indent}    }},",
            "",
            f"{indent}    resistance: {{",
            f"{indent}        cc_resist: {stats.cc_resist},",
            f"{indent}        debuff_resist: {stats.debuff_resist}",
            f"{indent}    }},",
            "",
            f"{indent}    growth_per_level: {{",
        ]

        # 성장 스탯
        growth = unit.growth
        growth_parts = []
        if growth.hp > 0:
            growth_parts.append(f"{indent}        hp: {growth.hp}")
        if growth.mana > 0:
            growth_parts.append(f"{indent}        mana: {growth.mana}")
        if growth.physical_attack > 0:
            growth_parts.append(f"{indent}        physical_attack: {growth.physical_attack}")
        if growth.magic_attack > 0:
            growth_parts.append(f"{indent}        magic_attack: {growth.magic_attack}")
        if growth.physical_defense > 0:
            growth_parts.append(f"{indent}        physical_defense: {growth.physical_defense}")
        if growth.magic_defense > 0:
            growth_parts.append(f"{indent}        magic_defense: {growth.magic_defense}")

        if growth_parts:
            lines.append(",\n".join(growth_parts))

        lines.append(f"{indent}    }},")
        lines.append("")

        # 스프라이트
        lines.append(f"{indent}    sprites: {{")
        sprite_parts = []
        sprites = unit.sprites
        if sprites.idle:
            sprite_parts.append(f"{indent}        idle: \"{sprites.idle}\"")
        if sprites.walk:
            sprite_parts.append(f"{indent}        walk: \"{sprites.walk}\"")
        if sprites.attack:
            sprite_parts.append(f"{indent}        attack: \"{sprites.attack}\"")
        if sprites.skill:
            sprite_parts.append(f"{indent}        skill: \"{sprites.skill}\"")
        if sprites.hit:
            sprite_parts.append(f"{indent}        hit: \"{sprites.hit}\"")
        if sprites.death:
            sprite_parts.append(f"{indent}        death: \"{sprites.death}\"")
        if sprite_parts:
            lines.append(",\n".join(sprite_parts))
        lines.append(f"{indent}    }},")
        lines.append("")

        # 스킬
        skill_items = []
        for slot in unit.skills:
            skill_items.append(f"{{ skill_id: \"{slot.skill_id}\", unlock_level: {slot.unlock_level} }}")

        lines.append(f"{indent}    skills: [{', '.join(skill_items)}],")

        # 태그
        tag_str = ", ".join([f"\"{t}\"" for t in unit.tags])
        lines.append(f"{indent}    tags: [{tag_str}]")

        lines.append(f"{indent}}};")

        return lines

    def _generate_skill_gml(self, skills: List[Skill]) -> str:
        """스킬 GML 코드 생성"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        lines = [
            f"/// @file scr_skill_data.gml",
            f"/// @desc 스킬 데이터 (자동 생성: {timestamp})",
            f"/// @generated UDL Content Editor",
            "",
            "function init_skill_data_generated() {",
            "    // 기존 데이터에 추가",
            "    if (!variable_global_exists(\"skills\")) {",
            "        global.skills = {};",
            "    }",
            "",
        ]

        for skill in skills:
            lines.extend(self._generate_skill_struct(skill))
            lines.append("")

        lines.append("}")
        return "\n".join(lines)

    def _generate_skill_struct(self, skill: Skill) -> List[str]:
        """단일 스킬 구조체 생성"""
        indent = "    "
        lines = [
            f"{indent}// {skill.name}",
            f"{indent}global.skills.{skill.id} = {{",
            f"{indent}    id: \"{skill.id}\",",
            f"{indent}    name: \"{skill.name}\",",
            f"{indent}    description: \"{skill.description}\",",
            f"{indent}    mana_cost: {skill.mana_cost},",
            f"{indent}    cooldown: {skill.cooldown},",
            f"{indent}    cast_time: {skill.cast_time},",
            "",
            f"{indent}    targeting: {{",
            f"{indent}        base: \"{skill.targeting.base.id}\",",
            f"{indent}        select_method: \"{skill.targeting.select.id}\",",
            f"{indent}        count: {skill.targeting.count},",
            f"{indent}        range: {skill.targeting.range or 5}",
            f"{indent}    }},",
            "",
        ]

        # 이펙트
        lines.append(f"{indent}    effects: [")
        for i, effect in enumerate(skill.effects):
            effect_lines = self._generate_effect_struct(effect, indent + "        ")
            if i < len(skill.effects) - 1:
                effect_lines[-1] = effect_lines[-1] + ","
            lines.extend(effect_lines)
        lines.append(f"{indent}    ],")

        # VFX/SFX
        if skill.vfx_on_cast:
            lines.append(f"{indent}    vfx_on_cast: \"{skill.vfx_on_cast}\",")
        if skill.vfx_on_hit:
            lines.append(f"{indent}    vfx_on_hit: \"{skill.vfx_on_hit}\",")
        if skill.sfx_on_cast:
            lines.append(f"{indent}    sfx_on_cast: \"{skill.sfx_on_cast}\",")
        if skill.sfx_on_hit:
            lines.append(f"{indent}    sfx_on_hit: \"{skill.sfx_on_hit}\",")

        # AI 힌트
        if skill.ai_hints:
            lines.append(f"{indent}    ai_hints: {{")
            lines.append(f"{indent}        priority: {skill.ai_hints.priority},")
            lines.append(f"{indent}        use_when: \"{skill.ai_hints.use_when}\",")
            lines.append(f"{indent}        min_targets: {skill.ai_hints.min_targets}")
            lines.append(f"{indent}    }}")

        lines.append(f"{indent}}};")

        return lines

    def _generate_effect_struct(self, effect, indent: str) -> List[str]:
        """이펙트 구조체 생성"""
        from ..models.enums import EffectType

        lines = [f"{indent}{{"]
        lines.append(f"{indent}    type: \"{effect.effect_type.id}\",")

        # 이펙트 타입별 파라미터
        if effect.effect_type == EffectType.DAMAGE:
            lines.append(f"{indent}    amount: {effect.amount},")
            lines.append(f"{indent}    damage_type: \"{effect.damage_type.id}\"")
            if effect.scale_stat:
                lines.append(f",\n{indent}    scale_stat: \"{effect.scale_stat}\"")
                lines.append(f",\n{indent}    scale_percent: {effect.scale_percent}")

        elif effect.effect_type == EffectType.HEAL:
            lines.append(f"{indent}    amount: {effect.amount}")
            if effect.scale_stat:
                lines.append(f",\n{indent}    scale_stat: \"{effect.scale_stat}\"")
                lines.append(f",\n{indent}    scale_percent: {effect.scale_percent}")

        elif effect.effect_type == EffectType.DOT:
            lines.append(f"{indent}    amount: {effect.amount},")
            lines.append(f"{indent}    duration: {effect.duration},")
            lines.append(f"{indent}    tick_rate: {effect.tick_rate},")
            lines.append(f"{indent}    damage_type: \"{effect.damage_type.id}\"")

        elif effect.effect_type == EffectType.HOT:
            lines.append(f"{indent}    amount: {effect.amount},")
            lines.append(f"{indent}    duration: {effect.duration},")
            lines.append(f"{indent}    tick_rate: {effect.tick_rate}")

        elif effect.effect_type in (EffectType.BUFF, EffectType.DEBUFF):
            lines.append(f"{indent}    stat: \"{effect.stat}\",")
            lines.append(f"{indent}    value: {effect.value},")
            lines.append(f"{indent}    percent: {str(effect.percent).lower()},")
            lines.append(f"{indent}    duration: {effect.duration}")

        elif effect.effect_type in (EffectType.STUN, EffectType.SILENCE, EffectType.ROOT, EffectType.FEAR):
            lines.append(f"{indent}    duration: {effect.cc_duration}")

        elif effect.effect_type == EffectType.SLOW:
            lines.append(f"{indent}    percent: {effect.value},")
            lines.append(f"{indent}    duration: {effect.duration}")

        elif effect.effect_type == EffectType.SHIELD:
            lines.append(f"{indent}    amount: {effect.amount},")
            lines.append(f"{indent}    duration: {effect.duration}")

        elif effect.effect_type == EffectType.AOE:
            lines.append(f"{indent}    radius: {effect.radius},")
            lines.append(f"{indent}    shape: \"{effect.shape}\"")

        elif effect.effect_type == EffectType.CHAIN:
            lines.append(f"{indent}    max_targets: {effect.max_targets},")
            lines.append(f"{indent}    range: {effect.chain_range},")
            lines.append(f"{indent}    damage_falloff: {effect.damage_falloff}")

        elif effect.effect_type == EffectType.PROJECTILE:
            lines.append(f"{indent}    speed: {effect.speed},")
            lines.append(f"{indent}    pierce: {str(effect.pierce).lower()}")

        lines.append(f"{indent}}}")

        return lines

    def _generate_race_function(self, races: dict) -> str:
        """종족 함수 본문 생성 (scr_data.gml 교체용)"""
        lines = [
            "function init_race_data() {",
            "    global.races = {};",
            "",
        ]

        indent = "    "
        for race_id, race in races.items():
            tag_str = ", ".join([f'"{t}"' for t in race.get('tags', [])])
            lines.append(f'{indent}global.races.{race_id} = {{ id: "{race_id}", name: "{race.get("name", "")}", '
                        f'hp: {race.get("hp", 0)}, mana: {race.get("mana", 0)}, '
                        f'phys_atk: {race.get("phys_atk", 0)}, mag_atk: {race.get("mag_atk", 0)}, '
                        f'phys_def: {race.get("phys_def", 0)}, mag_def: {race.get("mag_def", 0)}, '
                        f'atk_speed: {race.get("atk_speed", 0)}, move_speed: {race.get("move_speed", 0)}, '
                        f'crit_chance: {race.get("crit_chance", 0)}, crit_damage: {race.get("crit_damage", 0)}, '
                        f'dodge: {race.get("dodge", 0)}, accuracy: {race.get("accuracy", 0)}, '
                        f'lifesteal: {race.get("lifesteal", 0)}, healing_power: {race.get("healing_power", 0)}, '
                        f'hp_regen: {race.get("hp_regen", 0)}, mana_regen: {race.get("mana_regen", 0)}, '
                        f'cc_resist: {race.get("cc_resist", 0)}, debuff_resist: {race.get("debuff_resist", 0)}, '
                        f'tags: [{tag_str}] }};')

        lines.append("}")
        return "\n".join(lines)

    def _generate_class_function(self, classes: dict) -> str:
        """직업 함수 본문 생성 (scr_data.gml 교체용)"""
        lines = [
            "function init_class_data() {",
            "    global.classes = {};",
            "",
        ]

        indent = "    "
        for class_id, cls in classes.items():
            tag_str = ", ".join([f'"{t}"' for t in cls.get('tags', [])])
            lines.append(f'{indent}global.classes.{class_id} = {{ id: "{class_id}", name: "{cls.get("name", "")}", '
                        f'hp_mod: {cls.get("hp_mod", 0)}, phys_atk_mod: {cls.get("phys_atk_mod", 0)}, '
                        f'mag_atk_mod: {cls.get("mag_atk_mod", 0)}, phys_def_mod: {cls.get("phys_def_mod", 0)}, '
                        f'mag_def_mod: {cls.get("mag_def_mod", 0)}, speed_mod: {cls.get("speed_mod", 0)}, '
                        f'atk_range_mod: {cls.get("atk_range_mod", 0)}, tags: [{tag_str}] }};')

        lines.append("}")
        return "\n".join(lines)

    def _write_to_file(self, filename: str, content: str):
        """파일 쓰기"""
        self.output_dir.mkdir(parents=True, exist_ok=True)
        file_path = self.output_dir / filename

        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
