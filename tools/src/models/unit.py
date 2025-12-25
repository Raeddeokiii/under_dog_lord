"""유닛 데이터 모델"""
from dataclasses import dataclass, field
from typing import Optional
from .enums import Race, UnitClass, Rarity, AIType, DeployPosition, SpriteState


@dataclass
class UnitStats:
    """유닛 스탯"""
    # 1차 스탯
    hp: int = 500
    max_mana: int = 100
    physical_attack: int = 50
    magic_attack: int = 50
    physical_defense: int = 30
    magic_defense: int = 30
    attack_speed: float = 1.0
    movement_speed: int = 100
    attack_range: int = 1

    # 2차 스탯
    crit_chance: int = 10
    crit_damage: int = 150
    dodge_chance: int = 5
    accuracy: int = 100
    physical_lifesteal: int = 0
    magic_lifesteal: int = 0
    healing_power: int = 0
    physical_penetration: int = 0
    magic_penetration: int = 0
    cooldown_reduction: int = 0
    mana_regen: int = 5
    hp_regen: int = 0

    # 저항
    cc_resist: int = 0
    debuff_resist: int = 0


@dataclass
class UnitGrowth:
    """레벨당 스탯 성장"""
    hp: int = 30
    mana: int = 5
    physical_attack: int = 3
    magic_attack: int = 3
    physical_defense: int = 2
    magic_defense: int = 2


@dataclass
class UnitSprites:
    """유닛 스프라이트 매핑"""
    idle: str = ""
    walk: str = ""
    attack: str = ""
    skill: str = ""
    hit: str = ""
    death: str = ""

    def get(self, state: SpriteState) -> str:
        return getattr(self, state.id, "")

    def set(self, state: SpriteState, sprite: str):
        setattr(self, state.id, sprite)


@dataclass
class UnitSkillSlot:
    """스킬 슬롯"""
    skill_id: str
    unlock_level: int = 1
    replaces: Optional[str] = None  # 이 스킬이 대체하는 스킬 ID


@dataclass
class UnitSounds:
    """유닛 사운드"""
    spawn: str = ""
    attack: str = ""
    skill: str = ""
    hit: str = ""
    death: str = ""


@dataclass
class UnitEvolution:
    """진화/변이 정보"""
    evolves_to: str = ""
    level_required: int = 20
    item_required: str = ""


@dataclass
class Unit:
    """유닛 데이터"""
    # 기본 정보
    id: str = ""
    name: str = ""
    description: str = ""
    race: Race = Race.HUMAN
    unit_class: UnitClass = UnitClass.WARRIOR
    rarity: Rarity = Rarity.C

    # 태그
    tags: list[str] = field(default_factory=list)

    # 스탯
    base_stats: UnitStats = field(default_factory=UnitStats)
    growth: UnitGrowth = field(default_factory=UnitGrowth)

    # 스프라이트
    sprites: UnitSprites = field(default_factory=UnitSprites)

    # 스킬
    skills: list[UnitSkillSlot] = field(default_factory=list)

    # AI
    ai_type: AIType = AIType.AI_MELEE_DPS
    preferred_position: DeployPosition = DeployPosition.FC

    # 사운드
    sounds: UnitSounds = field(default_factory=UnitSounds)

    # 진화
    evolution: Optional[UnitEvolution] = None

    def generate_id(self) -> str:
        """이름에서 ID 자동 생성"""
        # 한글 이름을 영문 ID로 변환하는 간단한 규칙
        # 실제로는 사용자가 직접 입력하거나 영문 이름 사용
        import re
        id_str = self.name.lower().replace(" ", "_")
        id_str = re.sub(r'[^a-z0-9_]', '', id_str)
        return id_str if id_str else "unit"

    def to_dict(self) -> dict:
        """딕셔너리로 변환"""
        return {
            "id": self.id,
            "type": self.id,
            "name": self.name,
            "description": self.description,
            "race": self.race.id,
            "class": self.unit_class.id,
            "rarity": self.rarity.id,
            "tags": self.tags,
            "base_stats": {
                "hp": self.base_stats.hp,
                "max_mana": self.base_stats.max_mana,
                "physical_attack": self.base_stats.physical_attack,
                "magic_attack": self.base_stats.magic_attack,
                "physical_defense": self.base_stats.physical_defense,
                "magic_defense": self.base_stats.magic_defense,
                "attack_speed": self.base_stats.attack_speed,
                "movement_speed": self.base_stats.movement_speed,
                "attack_range": self.base_stats.attack_range,
            },
            "secondary_stats": {
                "crit_chance": self.base_stats.crit_chance,
                "crit_damage": self.base_stats.crit_damage,
                "dodge_chance": self.base_stats.dodge_chance,
                "accuracy": self.base_stats.accuracy,
                "physical_lifesteal": self.base_stats.physical_lifesteal,
                "magic_lifesteal": self.base_stats.magic_lifesteal,
                "healing_power": self.base_stats.healing_power,
                "physical_penetration": self.base_stats.physical_penetration,
                "magic_penetration": self.base_stats.magic_penetration,
                "cooldown_reduction": self.base_stats.cooldown_reduction,
                "mana_regen": self.base_stats.mana_regen,
                "hp_regen": self.base_stats.hp_regen,
            },
            "resistance": {
                "cc_resist": self.base_stats.cc_resist,
                "debuff_resist": self.base_stats.debuff_resist,
            },
            "growth_per_level": {
                "hp": self.growth.hp,
                "mana": self.growth.mana,
                "physical_attack": self.growth.physical_attack,
                "magic_attack": self.growth.magic_attack,
                "physical_defense": self.growth.physical_defense,
                "magic_defense": self.growth.magic_defense,
            },
            "sprites": {
                "idle": self.sprites.idle,
                "walk": self.sprites.walk,
                "attack": self.sprites.attack,
                "skill": self.sprites.skill,
                "hit": self.sprites.hit,
                "death": self.sprites.death,
            },
            "skills": [
                {"skill_id": s.skill_id, "unlock_level": s.unlock_level, "replaces": s.replaces}
                for s in self.skills
            ],
            "ai_type": self.ai_type.id,
            "preferred_position": self.preferred_position.id,
            "sounds": {
                "spawn": self.sounds.spawn,
                "attack": self.sounds.attack,
                "skill": self.sounds.skill,
                "hit": self.sounds.hit,
                "death": self.sounds.death,
            },
        }
