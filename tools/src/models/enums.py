"""게임 데이터 열거형 정의"""
from enum import Enum


class Race(Enum):
    """종족"""
    HUMAN = ("human", "인간")
    ELF = ("elf", "엘프")
    DWARF = ("dwarf", "드워프")
    ORC = ("orc", "오크")
    UNDEAD = ("undead", "언데드")
    DEMON = ("demon", "악마")
    SLIME = ("slime", "슬라임")
    BEAST = ("beast", "야수")
    DRAGON = ("dragon", "용족")
    CONSTRUCT = ("construct", "구조물")

    def __init__(self, id: str, display_name: str):
        self.id = id
        self.display_name = display_name


class UnitClass(Enum):
    """직업"""
    WARRIOR = ("warrior", "전사")
    TANK = ("tank", "탱커")
    KNIGHT = ("knight", "기사")
    BERSERKER = ("berserker", "광전사")
    MAGE = ("mage", "마법사")
    WARLOCK = ("warlock", "흑마법사")
    ELEMENTALIST = ("elementalist", "정령술사")
    PRIEST = ("priest", "사제")
    PALADIN = ("paladin", "성기사")
    CLERIC = ("cleric", "성직자")
    ROGUE = ("rogue", "도적")
    ASSASSIN = ("assassin", "암살자")
    NINJA = ("ninja", "닌자")
    RANGER = ("ranger", "레인저")
    ARCHER = ("archer", "궁수")
    HUNTER = ("hunter", "사냥꾼")
    SUPPORT = ("support", "서포터")
    SUMMONER = ("summoner", "소환사")

    def __init__(self, id: str, display_name: str):
        self.id = id
        self.display_name = display_name


class Rarity(Enum):
    """등급"""
    SSR = ("ssr", "SSR", "#FF4444")
    SR = ("sr", "SR", "#FFD700")
    S = ("s", "S", "#AA55FF")
    A = ("a", "A", "#5555FF")
    B = ("b", "B", "#55CC55")
    C = ("c", "C", "#55AAAA")
    D = ("d", "D", "#AAAAAA")
    F = ("f", "F", "#666666")

    def __init__(self, id: str, display_name: str, color: str):
        self.id = id
        self.display_name = display_name
        self.color = color


class DamageType(Enum):
    """데미지 타입"""
    PHYSICAL = ("physical", "물리")
    MAGICAL = ("magical", "마법")
    FIRE = ("fire", "화염")
    ICE = ("ice", "냉기")
    ELECTRIC = ("electric", "전기")
    SHADOW = ("shadow", "암흑")
    HOLY = ("holy", "신성")
    TRUE = ("true", "고정")

    def __init__(self, id: str, display_name: str):
        self.id = id
        self.display_name = display_name


class EffectType(Enum):
    """효과 타입"""
    DAMAGE = ("damage", "데미지")
    HEAL = ("heal", "회복")
    BUFF = ("buff", "버프")
    DEBUFF = ("debuff", "디버프")
    DOT = ("dot", "도트")
    HOT = ("hot", "지속회복")
    SHIELD = ("shield", "보호막")
    STUN = ("stun", "기절")
    SILENCE = ("silence", "침묵")
    SLOW = ("slow", "둔화")
    ROOT = ("root", "속박")
    FEAR = ("fear", "공포")
    TAUNT = ("taunt", "도발")
    CLEANSE = ("cleanse", "정화")
    DISPEL = ("dispel", "해제")
    SUMMON = ("summon", "소환")
    TELEPORT = ("teleport", "순간이동")
    PROJECTILE = ("projectile", "투사체")
    AOE = ("aoe", "범위효과")
    CHAIN = ("chain", "연쇄")

    def __init__(self, id: str, display_name: str):
        self.id = id
        self.display_name = display_name


class TargetBase(Enum):
    """타겟 기본 대상"""
    SELF = ("self", "자신")
    ALLY = ("ally", "아군")
    ENEMY = ("enemy", "적")
    ALL = ("all", "전체")

    def __init__(self, id: str, display_name: str):
        self.id = id
        self.display_name = display_name


class SelectMethod(Enum):
    """타겟 선택 방법"""
    NEAREST = ("nearest", "가장 가까운")
    FURTHEST = ("furthest", "가장 먼")
    LOWEST_HP = ("lowest_hp", "HP 가장 낮은")
    HIGHEST_HP = ("highest_hp", "HP 가장 높은")
    LOWEST_HP_PERCENT = ("lowest_hp_percent", "HP% 가장 낮은")
    RANDOM = ("random", "무작위")
    ALL = ("all", "전부")

    def __init__(self, id: str, display_name: str):
        self.id = id
        self.display_name = display_name


class AIType(Enum):
    """AI 타입"""
    # 적 AI
    AI_RUSH = ("ai_rush", "돌진형")
    AI_RANGED = ("ai_ranged", "원거리형")
    AI_BOSS = ("ai_boss", "보스형")
    # 아군 AI
    AI_TANK = ("ai_tank", "탱커")
    AI_HEALER = ("ai_healer", "힐러")
    AI_RANGED_DPS = ("ai_ranged_dps", "원거리 딜러")
    AI_MELEE_DPS = ("ai_melee_dps", "근거리 딜러")
    AI_ASSASSIN = ("ai_assassin", "암살자")
    AI_SUPPORT = ("ai_support", "서포터")
    AI_SUMMONER = ("ai_summoner", "소환사")

    def __init__(self, id: str, display_name: str):
        self.id = id
        self.display_name = display_name


class DeployPosition(Enum):
    """출전 위치"""
    FL = ("FL", "전열 좌측")
    FC = ("FC", "전열 중앙")
    FR = ("FR", "전열 우측")
    BL = ("BL", "후열 좌측")
    BC = ("BC", "후열 중앙")
    BR = ("BR", "후열 우측")
    WL = ("WL", "성벽 좌측")
    WC = ("WC", "성벽 중앙")
    WR = ("WR", "성벽 우측")

    def __init__(self, id: str, display_name: str):
        self.id = id
        self.display_name = display_name


class SpriteState(Enum):
    """스프라이트 상태"""
    IDLE = ("idle", "대기")
    WALK = ("walk", "이동")
    ATTACK = ("attack", "공격")
    SKILL = ("skill", "스킬")
    HIT = ("hit", "피격")
    DEATH = ("death", "사망")

    def __init__(self, id: str, display_name: str):
        self.id = id
        self.display_name = display_name
