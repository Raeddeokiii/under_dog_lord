"""스킬 데이터 모델"""
from dataclasses import dataclass, field
from typing import Optional, Any
from .enums import EffectType, DamageType, TargetBase, SelectMethod


@dataclass
class Targeting:
    """타겟팅 정보"""
    base: TargetBase = TargetBase.ENEMY
    select: SelectMethod = SelectMethod.NEAREST
    count: int = 1
    range: Optional[int] = None
    filters: list[dict] = field(default_factory=list)

    def to_dict(self) -> dict:
        result = {
            "base": self.base.id,
            "select": self.select.id,
            "count": self.count,
        }
        if self.range:
            result["range"] = self.range
        if self.filters:
            result["filters"] = self.filters
        return result


@dataclass
class Effect:
    """효과"""
    effect_type: EffectType = EffectType.DAMAGE

    # 데미지/힐
    amount: int = 100
    damage_type: DamageType = DamageType.PHYSICAL
    scale_stat: str = ""
    scale_percent: int = 100

    # 버프/디버프
    stat: str = ""
    value: int = 0
    percent: bool = False
    duration: float = 5.0

    # 도트/핫
    tick_rate: float = 1.0

    # CC
    cc_duration: float = 2.0

    # AOE
    radius: int = 2
    shape: str = "circle"

    # 체인
    max_targets: int = 5
    chain_range: int = 3
    damage_falloff: float = 0.8

    # 투사체
    speed: int = 8
    pierce: bool = False

    # 중첩 효과
    sub_effects: list["Effect"] = field(default_factory=list)

    # 태그
    tags: list[str] = field(default_factory=list)

    def to_dict(self) -> dict:
        result = {"type": self.effect_type.id}

        if self.effect_type == EffectType.DAMAGE:
            result["amount"] = self.amount
            result["damage_type"] = self.damage_type.id
            if self.scale_stat:
                result["scale_stat"] = self.scale_stat
                result["scale_percent"] = self.scale_percent

        elif self.effect_type == EffectType.HEAL:
            result["amount"] = self.amount
            if self.scale_stat:
                result["scale_stat"] = self.scale_stat
                result["scale_percent"] = self.scale_percent

        elif self.effect_type in (EffectType.BUFF, EffectType.DEBUFF):
            result["stat"] = self.stat
            result["value"] = self.value
            result["percent"] = self.percent
            result["duration"] = self.duration
            if self.tags:
                result["tags"] = self.tags

        elif self.effect_type == EffectType.DOT:
            result["amount"] = self.amount
            result["duration"] = self.duration
            result["tick_rate"] = self.tick_rate
            result["damage_type"] = self.damage_type.id

        elif self.effect_type == EffectType.HOT:
            result["amount"] = self.amount
            result["duration"] = self.duration
            result["tick_rate"] = self.tick_rate

        elif self.effect_type in (EffectType.STUN, EffectType.SILENCE,
                                   EffectType.ROOT, EffectType.FEAR):
            result["duration"] = self.cc_duration

        elif self.effect_type == EffectType.SLOW:
            result["percent"] = self.value
            result["duration"] = self.duration

        elif self.effect_type == EffectType.SHIELD:
            result["amount"] = self.amount
            result["duration"] = self.duration

        elif self.effect_type == EffectType.AOE:
            result["radius"] = self.radius
            result["shape"] = self.shape
            if self.sub_effects:
                result["effects"] = [e.to_dict() for e in self.sub_effects]

        elif self.effect_type == EffectType.CHAIN:
            result["max_targets"] = self.max_targets
            result["range"] = self.chain_range
            result["damage_falloff"] = self.damage_falloff
            if self.sub_effects:
                result["effects"] = [e.to_dict() for e in self.sub_effects]

        elif self.effect_type == EffectType.PROJECTILE:
            result["speed"] = self.speed
            result["pierce"] = self.pierce
            if self.sub_effects:
                result["on_hit"] = [e.to_dict() for e in self.sub_effects]

        return result


@dataclass
class AIHint:
    """AI 힌트"""
    use_when: str = "always"  # always, enemies_grouped, ally_low_hp, etc.
    min_targets: int = 1
    priority: int = 50
    hp_threshold: Optional[int] = None
    save_for_wave: bool = False

    def to_dict(self) -> dict:
        result = {
            "use_when": self.use_when,
            "min_targets": self.min_targets,
            "priority": self.priority,
        }
        if self.hp_threshold:
            result["hp_threshold"] = self.hp_threshold
        if self.save_for_wave:
            result["save_for_wave"] = self.save_for_wave
        return result


@dataclass
class Skill:
    """스킬 데이터"""
    # 기본 정보
    id: str = ""
    name: str = ""
    description: str = ""
    icon: str = ""

    # 비용
    mana_cost: int = 30
    cooldown: float = 5.0

    # 시전 타입
    cast_type: str = "instant"  # instant, channel, charge
    cast_time: float = 0.0
    interruptible: bool = False

    # 타겟팅
    targeting: Targeting = field(default_factory=Targeting)

    # 효과
    effects: list[Effect] = field(default_factory=list)

    # AI 힌트
    ai_hints: AIHint = field(default_factory=AIHint)

    # 연출
    vfx_on_cast: str = ""
    vfx_on_hit: str = ""
    sfx_on_cast: str = ""
    sfx_on_hit: str = ""

    # 태그
    tags: list[str] = field(default_factory=list)

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "icon": self.icon,
            "mana_cost": self.mana_cost,
            "cooldown": self.cooldown,
            "cast_type": self.cast_type,
            "cast_time": self.cast_time,
            "interruptible": self.interruptible,
            "targeting": self.targeting.to_dict(),
            "effects": [e.to_dict() for e in self.effects],
            "ai_hints": self.ai_hints.to_dict(),
            "vfx": {
                "on_cast": self.vfx_on_cast,
                "on_hit": self.vfx_on_hit,
            },
            "sfx": {
                "on_cast": self.sfx_on_cast,
                "on_hit": self.sfx_on_hit,
            },
            "tags": self.tags,
        }
