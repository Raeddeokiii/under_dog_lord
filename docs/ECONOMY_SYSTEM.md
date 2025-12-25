# ECONOMY_SYSTEM.md - 경제 시스템

> **참조**: [INDEX.md](./INDEX.md)로 돌아가기

---

## 개요

왕국 경영과 자원 관리 시스템. 웨이브 방어를 통해 자원을 획득하고, 건물/유닛 강화에 투자.

```
┌─────────────────────────────────────────────────────────────┐
│                      경제 순환 구조                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   [웨이브 클리어] ──► [보상 획득] ──► [투자/강화]           │
│         │                │                │                 │
│         │                ▼                ▼                 │
│         │         골드, 경험치,      건물, 유닛,            │
│         │         특수 자원         장비, 스킬              │
│         │                                 │                 │
│         └─────────────────────────────────┘                 │
│                     다음 웨이브 준비                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 자원 시스템

### 기본 자원 구조

```gml
/// 자원 정의
enum RESOURCE {
    GOLD,           // 골드 - 기본 통화
    CRYSTAL,        // 크리스탈 - 프리미엄/희귀 통화
    SOUL,           // 영혼 - 유닛 강화용
    WOOD,           // 목재 - 건물용
    STONE,          // 석재 - 건물용
    IRON,           // 철광석 - 장비용
    FOOD,           // 식량 - 유닛 유지비
    MANA_CRYSTAL,   // 마나 결정 - 스킬 강화용
    REPUTATION      // 명성 - 특수 언락용
}

/// 플레이어 자원
global.player_resources = {
    gold: 1000,
    crystal: 0,
    soul: 0,
    wood: 500,
    stone: 300,
    iron: 100,
    food: 200,
    mana_crystal: 0,
    reputation: 0
}
```

### 자원 획득 방식

```gml
/// 자원 획득 소스
resource_sources = {
    // 웨이브 클리어 보상
    wave_clear: {
        base_gold: 100,
        per_wave_bonus: 50,     // 웨이브 번호 * 50
        perfect_bonus: 1.5,     // 무피해 클리어 시
        speed_bonus: 1.2        // 빠른 클리어 시
    },

    // 몬스터 처치
    monster_kill: {
        gold_per_hp: 0.1,       // 몬스터 HP 비례
        soul_chance: 0.1,       // 영혼 드롭 확률
        elite_multiplier: 3,    // 엘리트 몬스터
        boss_multiplier: 10     // 보스 몬스터
    },

    // 건물 생산
    building_production: {
        interval: 60,           // 초 단위
        affected_by_buffs: true
    },

    // 퀘스트/업적
    quest_rewards: true,

    // 무역/교환
    trade_system: true
}
```

### 자원 조작 함수

```gml
/// @function resource_add(type, amount, source)
/// @param {RESOURCE} type - 자원 타입
/// @param {real} amount - 수량
/// @param {string} source - 획득 출처 (로깅용)
function resource_add(type, amount, source) {
    var key = resource_type_to_key(type);
    var old_value = global.player_resources[$ key];
    global.player_resources[$ key] += amount;

    // 이벤트 트리거
    trigger_event("on_resource_gain", {
        type: type,
        amount: amount,
        source: source,
        old_value: old_value,
        new_value: global.player_resources[$ key]
    });

    return true;
}

/// @function resource_spend(type, amount)
/// @param {RESOURCE} type - 자원 타입
/// @param {real} amount - 수량
/// @returns {bool} 성공 여부
function resource_spend(type, amount) {
    var key = resource_type_to_key(type);

    if (global.player_resources[$ key] < amount) {
        return false;  // 자원 부족
    }

    global.player_resources[$ key] -= amount;

    trigger_event("on_resource_spend", {
        type: type,
        amount: amount
    });

    return true;
}

/// @function resource_can_afford(costs)
/// @param {struct} costs - { gold: 100, wood: 50 } 형태
/// @returns {bool}
function resource_can_afford(costs) {
    var keys = variable_struct_get_names(costs);
    for (var i = 0; i < array_length(keys); i++) {
        var key = keys[i];
        if (global.player_resources[$ key] < costs[$ key]) {
            return false;
        }
    }
    return true;
}
```

---

## 주둔 건물 시스템

> 유닛들은 영지 내 건물에 주둔하며, 전투 시작 시 성문 밖으로 출전
> **직업 건물**에 우선 배치, 불가 시 **종족 건물**로 배치

### 건물 배치 우선순위

```
┌─────────────────────────────────────────────────────────────┐
│                    건물 배치 우선순위                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1순위: 직업 건물 (해당 직업 보너스 받음)                     │
│         → 마법사 → 마법사탑                                  │
│         → 전사 → 병영                                        │
│                                                             │
│  2순위: 종족 건물 (직업 건물 불가 시)                         │
│         → 슬라임 전사 → 슬라임 소굴                          │
│         → 언데드 암살자 → 묘지                               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 건물 기본 구조

```gml
/// 주둔 건물 데이터 구조
building_template = {
    id: "building_id",
    name: "건물 이름",
    description: "설명",

    // ★ 건물 타입 (NEW)
    building_type: "job",           // "job" (직업 건물) 또는 "race" (종족 건물)

    // 건설 정보
    build_cost: { gold: 500, wood: 200, stone: 100 },
    build_time: 60,
    requires_building: [],
    requires_reputation: 0,
    max_level: 5,

    // ★ 주둔 시스템 (NEW: 직업/종족 기반)
    garrison: {
        enabled: true,
        slots: 4,
        slots_per_level: 1,

        // 직업 건물용
        allowed_classes: ["warrior", "tank"],    // 허용 직업
        allowed_race_types: ["humanoid"],        // 허용 종족 타입
        forbidden_races: [],                     // 금지 종족

        // 종족 건물용
        required_race: undefined,                // 필수 종족 (종족 건물만)

        deploy_to_battle: true,
        deploy_delay: 0
    },

    // 주둔 유닛 버프
    garrison_buffs: [],

    // 유지비
    upkeep: {
        resource: RESOURCE.FOOD,
        base_cost: 0,
        per_unit_cost: 3
    },

    // 특수 기능
    features: [],

    // 전투 지원
    battle_support: undefined,

    tags: ["military", "garrison"]
}
```

### 직업 건물 (Job Buildings)

> 해당 직업 유닛에게 특화 버프 제공. humanoid 종족이 아닌 경우 일부 제한.

| 건물 | ID | 허용 직업 | 허용 종족 | 금지 종족 | 슬롯 | 유지비 |
|------|-----|----------|----------|----------|------|--------|
| 병영 | `barracks` | warrior, tank | humanoid | - | 4~8 | 식량 3/유닛 |
| 마법사탑 | `mage_tower` | mage | 모든 종족 | - | 3~7 | 마나결정 1/유닛 |
| 신전 | `temple` | priest, paladin | holy 친화 | undead, demon | 3~7 | 골드 4/유닛 |
| 암살자 길드 | `assassin_guild` | rogue, assassin | humanoid | - | 2~5 | 골드 10/유닛 |
| 궁수 초소 | `archer_post` | ranger, archer | humanoid | - | 4~8 | 식량 2/유닛 |

### 종족 건물 (Race Buildings)

> 해당 종족 유닛만 입장 가능. 직업에 관계없이 모든 유닛 수용.

| 건물 | ID | 필수 종족 | 허용 직업 | 슬롯 | 유지비 |
|------|-----|----------|----------|------|--------|
| 묘지 | `crypt` | undead | 모든 직업 | 5~13 | 영혼 1/유닛 |
| 슬라임 소굴 | `slime_den` | slime | 모든 직업 | 6~14 | 젤리 1/유닛 |
| 마족 제단 | `demon_altar` | demon | 모든 직업 | 4~10 | 피의 결정 1/유닛 |
| 야수 우리 | `beast_pen` | beast | 모든 직업 | 5~11 | 생고기 2/유닛 |
| 용의 둥지 | `dragon_nest` | dragon | 모든 직업 | 2~4 | 골드 20/유닛 |

### 건물 건설 정보

| 건물 | 타입 | 건설 비용 | 필요 명성 | 건설 시간 |
|------|------|-----------|-----------|-----------|
| 병영 | 직업 | 골드 500, 목재 200, 석재 100 | - | 60초 |
| 마법사 탑 | 직업 | 골드 800, 석재 300, 크리스탈 5 | - | 90초 |
| 신전 | 직업 | 골드 600, 석재 400 | - | 75초 |
| 암살자 길드 | 직업 | 골드 1000, 목재 100, 크리스탈 10 | 200 | 120초 |
| 궁수 초소 | 직업 | 골드 400, 목재 300 | - | 45초 |
| 묘지 | 종족 | 골드 600, 석재 500, 영혼 50 | 100 | 100초 |
| 슬라임 소굴 | 종족 | 골드 400, 젤리 100 | 50 | 60초 |
| 마족 제단 | 종족 | 골드 1000, 피의 결정 50 | 300 | 150초 |
| 야수 우리 | 종족 | 골드 300, 목재 400 | - | 50초 |
| 용의 둥지 | 종족 | 골드 2000, 크리스탈 50 | 500 | 200초 |

---

## 병영 (Barracks) - 직업 건물

> 전사들이 주둔하는 곳. 전투 시 최전선에서 싸움.

### 기본 정보

```gml
building_barracks = {
    id: "barracks",
    name: "병영",
    description: "전사들이 주둔하는 곳. 전투 시 최전선에서 싸움.",

    building_type: "job",           // ★ 직업 건물

    build_cost: { gold: 500, wood: 200, stone: 100 },
    build_time: 60,
    max_level: 5,

    garrison: {
        enabled: true,
        slots: 4,
        slots_per_level: 1,

        // ★ 직업 기반 배치
        allowed_classes: ["warrior", "tank", "knight", "berserker"],
        allowed_race_types: ["humanoid"],  // human, elf, dwarf, orc 등
        forbidden_races: [],

        deploy_to_battle: true,
        deploy_delay: 0
    },

    upkeep: {
        resource: RESOURCE.FOOD,
        base_cost: 5,
        per_unit_cost: 3
    }
}
```

### 버프 목록

| 버프명 | 타입 | Lv1 | Lv2 | Lv3 | Lv4 | Lv5 | 설명 |
|--------|------|-----|-----|-----|-----|-----|------|
| 전투 훈련 | 공격력% | +5% | +7% | +9% | +11% | +13% | 기본 공격력에 곱연산 |
| 방어 태세 | 방어력 | +10 | +15 | +20 | +25 | +30 | 고정 방어력 추가 |
| 사기 충천 | 시작 버프 | 3초 | 3초 | 4초 | 4초 | 5초 | 전투 시작 시 받는 피해 -20% |
| 전우애 | 연계 | +3% | +4% | +5% | +6% | +7% | 병영 유닛끼리 인접 시 공격력 추가 |
| 저항력 강화 | CC저항 | - | - | +10% | +15% | +20% | Lv3 해금. 스턴/슬로우 지속시간 감소 |

### 특수 기능

| 기능명 | 해금 | 비용 | 쿨다운 | 설명 |
|--------|------|------|--------|------|
| 기본 훈련 | Lv1 | 골드 100 | 즉시 | 유닛 1명 경험치 +50 |
| 집중 훈련 | Lv2 | 골드 300 | 웨이브 3회 | 병영 전체 유닛 경험치 +100 |
| 진형 훈련 | Lv3 | 골드 500 | 영구 해금 | 병영 유닛 2명 이상 인접 시 방어력 +20 추가 |
| 무기 숙련 | Lv4 | 골드 400, 철 50 | 웨이브 5회 | 유닛 1명 공격력 영구 +5% |
| 정예 승급 | Lv5 | 골드 1000, 철 100 | 웨이브 10회 | 유닛 1명 "정예" 등급. 모든 스탯 +20%, 스킬 강화 |

---

## 마법사 탑 (Mage Tower) - 직업 건물

> 마법사들이 연구하며 대기. 전투 시 후열에서 마법 지원.

### 기본 정보

```gml
building_mage_tower = {
    id: "mage_tower",
    name: "마법사 탑",
    description: "마법사들이 연구하며 대기. 전투 시 후열에서 마법 지원.",

    building_type: "job",           // ★ 직업 건물

    build_cost: { gold: 800, stone: 300, crystal: 5 },
    build_time: 90,
    max_level: 5,

    garrison: {
        enabled: true,
        slots: 3,
        slots_per_level: 1,

        // ★ 직업 기반 배치 - 종족 제한 없음
        allowed_classes: ["mage", "warlock", "elementalist", "enchanter"],
        allowed_race_types: [],     // 모든 종족 허용
        forbidden_races: [],

        deploy_to_battle: true,
        deploy_delay: 1.0
    },

    upkeep: {
        resource: RESOURCE.MANA_CRYSTAL,
        base_cost: 2,
        per_unit_cost: 1
    },

    battle_support: {
        type: "periodic_spell",
        spell: "arcane_bolt",
        interval: 10,
        damage: 50,
        per_level_damage: 25
    }
}
```

### 버프 목록

| 버프명 | 타입 | Lv1 | Lv2 | Lv3 | Lv4 | Lv5 | 설명 |
|--------|------|-----|-----|-----|-----|-----|------|
| 마력 증폭 | 주문력% | +10% | +15% | +20% | +25% | +30% | 스킬 데미지 곱연산 |
| 마나 샘 | 최대MP% | +20% | +30% | +40% | +50% | +60% | 최대 마나 증가 |
| 마나 친화 | MP회복 | +2/초 | +3/초 | +4/초 | +5/초 | +6/초 | 전투 중 마나 자연 회복 |
| 주문 가속 | 시전시간 | - | - | -10% | -15% | -20% | Lv3 해금. 스킬 시전 시간 감소 |
| 마법 관통 | 저항무시 | - | - | - | +10% | +15% | Lv4 해금. 적 마법 저항 무시 |

**전투 지원**: 10초마다 가장 HP 높은 적에게 마법탄 발사 (피해: 50 + 25/Lv)

### 특수 기능

| 기능명 | 해금 | 비용 | 쿨다운 | 설명 |
|--------|------|------|--------|------|
| 마법 연구 | Lv1 | 마나결정 5 | 웨이브 5회 | 랜덤 스킬 강화 스크롤 1개 획득 |
| 장비 마법부여 | Lv2 | 마나결정 10, 골드 200 | 즉시 | 장비에 랜덤 마법 효과 부여 |
| 마나 충전 | Lv2 | 마나결정 3 | 전투 1회 | 다음 전투 마법사탑 유닛 MP 100% 시작 |
| 원소 친화 | Lv3 | 마나결정 15 | 영구 | 유닛 1명 원소 속성 부여. 해당 속성 스킬 +25% |
| 비전 돌파 | Lv4 | 마나결정 20, 크리스탈 5 | 웨이브 10회 | 유닛 1명 스킬 쿨다운 영구 -15% |
| 궁극의 마법 | Lv5 | 마나결정 50 | 웨이브 20회 | 전투 중 1회 "대마법" 사용 가능. 맵 전체 대량 피해 |

---

## 신전 (Temple) - 직업 건물

> 성직자들이 기도하며 대기. 전투 시 아군을 치유하고 보호.

### 기본 정보

```gml
building_temple = {
    id: "temple",
    name: "신전",
    description: "성직자들이 기도하며 대기. 전투 시 아군을 치유하고 보호.",

    building_type: "job",           // ★ 직업 건물

    build_cost: { gold: 600, stone: 400 },
    build_time: 75,
    max_level: 5,

    garrison: {
        enabled: true,
        slots: 3,
        slots_per_level: 1,

        // ★ 직업 기반 배치 - 언데드/데몬 금지
        allowed_classes: ["priest", "paladin", "cleric", "support"],
        allowed_race_types: ["holy_affinity"],  // human, elf 등 신성 친화
        forbidden_races: ["undead", "demon"],   // 언데드/데몬 입장 불가

        deploy_to_battle: true,
        deploy_delay: 0.5
    },

    upkeep: {
        resource: RESOURCE.GOLD,
        base_cost: 10,
        per_unit_cost: 4
    },

    battle_support: {
        type: "periodic_heal",
        heal_amount: 30,
        per_level_heal: 15,
        interval: 8,
        target: "lowest_hp_ally"
    }
}
```

### 버프 목록

| 버프명 | 타입 | Lv1 | Lv2 | Lv3 | Lv4 | Lv5 | 설명 |
|--------|------|-----|-----|-----|-----|-----|------|
| 신의 축복 | 치유력% | +15% | +20% | +25% | +30% | +35% | 힐 스킬 효과 곱연산 |
| 성스러운 보호 | 피해감소% | +5% | +7% | +9% | +11% | +13% | 신전 유닛 받는 피해 감소 |
| 정화의 빛 | 디버프저항 | +15% | +20% | +25% | +30% | +35% | 디버프 걸릴 확률 감소 |
| 신성 오라 | HP회복 오라 | - | - | 범위150 | 범위180 | 범위210 | Lv3 해금. 주변 아군 초당 HP 5 회복 |
| 부활 준비 | 자동부활 | - | - | - | - | 1회 | Lv5 해금. 첫 사망 시 HP 30% 부활 (웨이브당 1회) |

**전투 지원**: 8초마다 가장 HP% 낮은 아군 힐 (회복량: 30 + 15/Lv)

### 특수 기능

| 기능명 | 해금 | 비용 | 쿨다운 | 설명 |
|--------|------|------|--------|------|
| 축복 | Lv1 | 골드 100 | 전투 1회 | 유닛 1명 다음 전투 받는 피해 -10% |
| 정화 | Lv1 | 골드 150 | 즉시 | 유닛 1명 저주/영구 디버프 제거 |
| 신성한 물 | Lv2 | 골드 200 | 웨이브 3회 | 소모품 생성. 전투 중 HP 30% 즉시 회복 |
| 부활 의식 | Lv3 | 골드 500, 영혼 30 | 웨이브 10회 | 영구 사망 유닛 1명 부활 |
| 성역 선포 | Lv4 | 골드 400 | 전투 1회 | 신전 유닛 주변 3칸 성역. 아군 피해-20%, 언데드 적 피해+30% |
| 신의 기적 | Lv5 | 골드 1000, 크리스탈 10 | 웨이브 25회 | 전투 중 1회. 모든 아군 HP 전체 회복 + 5초 무적 |

---

## 암살자 길드 (Assassin Guild) - 직업 건물

> 그림자 속 암살자들. 전투 시 적 후열을 기습.

### 기본 정보

```gml
building_assassin_guild = {
    id: "assassin_guild",
    name: "암살자 길드",
    description: "그림자 속 암살자들. 전투 시 적 후열을 기습.",

    building_type: "job",           // ★ 직업 건물

    build_cost: { gold: 1000, wood: 100, crystal: 10 },
    build_time: 120,
    max_level: 5,
    requires_reputation: 200,

    garrison: {
        enabled: true,
        slots: 2,
        slots_per_level: 1,

        // ★ 직업 기반 배치 - humanoid만
        allowed_classes: ["rogue", "assassin", "thief", "ninja"],
        allowed_race_types: ["humanoid"],
        forbidden_races: [],

        deploy_to_battle: true,
        deploy_delay: 3.0
    },

    upkeep: {
        resource: RESOURCE.GOLD,
        base_cost: 20,
        per_unit_cost: 10
    }
}
```

### 버프 목록

| 버프명 | 타입 | Lv1 | Lv2 | Lv3 | Lv4 | Lv5 | 설명 |
|--------|------|-----|-----|-----|-----|-----|------|
| 급소 공략 | 치명타확률 | +10% | +15% | +20% | +25% | +30% | 크리티컬 발생 확률 |
| 치명적 일격 | 치명타피해% | +25% | +40% | +55% | +70% | +85% | 크리티컬 데미지 배율 (기본 150%) |
| 첫 번째 칼날 | 첫공격 | x2.0 | x2.0 | x2.0 | x2.5 | x2.5 | 전투 첫 공격 데미지 배율 |
| 그림자 숙달 | 은신 지속 | +1초 | +1.5초 | +2초 | +2.5초 | +3초 | 은신 스킬 지속시간 증가 |
| 독 강화 | 독 데미지% | - | +20% | +35% | +50% | +65% | Lv2 해금. 독 스킬 데미지 증가 |
| 처형자 | 즉사 | - | - | - | - | HP 15% | Lv5 해금. 적 HP 15% 이하 즉사 (보스 제외) |

### 특수 기능

| 기능명 | 해금 | 비용 | 쿨다운 | 설명 |
|--------|------|------|--------|------|
| 독 제조 | Lv1 | 골드 150 | 웨이브 3회 | 독 소모품 생성. 5회 공격 독 피해 추가 |
| 정보 수집 | Lv1 | 골드 100 | 웨이브 1회 | 다음 웨이브 몬스터 구성 미리 확인 |
| 암살 임무 | Lv2 | 골드 300 | 웨이브 5회 | 다음 웨이브 랜덤 엘리트 1마리 HP -50% 시작 |
| 은신 훈련 | Lv2 | 골드 400 | 영구 | 유닛 1명 "은신" 스킬 부여. 3초 타겟팅 불가, 다음 공격 +50% |
| 치명적 약점 | Lv3 | 골드 500 | 웨이브 10회 | 다음 전투 보스 방어력 -30% |
| 그림자 계약 | Lv4 | 골드 1000, 크리스탈 5 | 웨이브 20회 | 전투 시작 시 적 1명 즉사 (보스 제외) |
| 암흑 결사 | Lv5 | 골드 1500, 크리스탈 10 | 웨이브 30회 | 길드 유닛 전원 첫 5초간 완전 은신 + 첫 공격 3배 |

---

## 궁수 초소 (Archer Post) - 직업 건물

> 궁수들의 감시 초소. 전투 시 성벽 위에서 지원 사격.

### 기본 정보

```gml
building_archer_post = {
    id: "archer_post",
    name: "궁수 초소",
    description: "궁수들의 감시 초소. 전투 시 성벽 위에서 지원 사격.",

    building_type: "job",           // ★ 직업 건물

    build_cost: { gold: 400, wood: 300 },
    build_time: 45,
    max_level: 5,

    garrison: {
        enabled: true,
        slots: 4,
        slots_per_level: 1,

        // ★ 직업 기반 배치 - humanoid만
        allowed_classes: ["ranger", "archer", "hunter", "crossbow", "gunner"],
        allowed_race_types: ["humanoid"],
        forbidden_races: [],

        deploy_to_battle: true,
        deploy_delay: 0
    },

    upkeep: {
        resource: RESOURCE.FOOD,
        base_cost: 3,
        per_unit_cost: 2
    }
}
```

### 버프 목록

| 버프명 | 타입 | Lv1 | Lv2 | Lv3 | Lv4 | Lv5 | 설명 |
|--------|------|-----|-----|-----|-----|-----|------|
| 정밀 조준 | 사거리% | +10% | +15% | +20% | +25% | +30% | 기본 사거리 곱연산 |
| 속사 | 공격속도% | +5% | +7% | +9% | +11% | +13% | 공격 간격 감소 |
| 관통 사격 | 방어무시 | - | +5% | +8% | +11% | +14% | Lv2 해금. 적 방어력 무시 |
| 약점 포착 | 치명타확률 | - | - | +5% | +7% | +9% | Lv3 해금. 원거리 크리티컬 확률 |
| 연발 사격 | 추가공격 | - | - | - | 10% | 15% | Lv4 해금. 공격 시 확률적 추가 1회 |
| 화살비 | 광역 | - | - | - | - | 활성화 | Lv5 해금. 5번째 공격마다 주변 50% 튐 |

### 특수 기능

| 기능명 | 해금 | 비용 | 쿨다운 | 설명 |
|--------|------|------|--------|------|
| 화살 제작 | Lv1 | 목재 50 | 웨이브 3회 | 특수 화살 생성 (불/얼음/독 선택) |
| 정찰 | Lv1 | 골드 50 | 웨이브 1회 | 다음 웨이브 적 이동 경로 확인 |
| 사격 집중 | Lv2 | 골드 200 | 전투 1회 | 유닛 1명 다음 전투 10% 확률 2배 피해 |
| 연막 화살 | Lv3 | 골드 300, 목재 30 | 전투 2회 | 지정 지역 3초 연막. 적 명중률 -50% |
| 화염 화살비 | Lv4 | 골드 400, 목재 50 | 전투 3회 | 지정 지역 범위 피해 + 화상 |
| 명사수 칭호 | Lv5 | 골드 600 | 영구 | 유닛 1명 사거리 +50%, 치명타 시 적 이동속도 -30% |
| 일제 사격 | Lv5 | 골드 800 | 전투 1회 | 초소 전 유닛 동시 사격. 3초간 공속 +100% |

---

## 묘지 (Crypt) - 종족 건물

> 언데드들이 잠드는 지하 묘지. 전투 시 땅에서 솟아오름.

### 기본 정보

```gml
building_crypt = {
    id: "crypt",
    name: "묘지",
    description: "언데드들이 잠드는 지하 묘지. 전투 시 땅에서 솟아오름.",

    building_type: "race",          // ★ 종족 건물

    build_cost: { gold: 600, stone: 500, soul: 50 },
    build_time: 100,
    max_level: 5,
    requires_reputation: 100,

    garrison: {
        enabled: true,
        slots: 5,
        slots_per_level: 2,

        // ★ 종족 기반 배치 - undead만
        allowed_classes: [],        // 직업 제한 없음
        allowed_race_types: [],
        forbidden_races: [],
        required_race: "undead",    // undead 종족만 입장 가능

        deploy_to_battle: true,
        deploy_delay: 1.5
    },

    upkeep: {
        resource: RESOURCE.SOUL,
        base_cost: 2,
        per_unit_cost: 1
    },

    battle_support: {
        type: "corpse_collector",
        collect_range: 300,
        convert_chance: 20,
        convert_chance_per_level: 5,
        skeleton_stats_percent: 50
    }
}
```

### 버프 목록

| 버프명 | 타입 | Lv1 | Lv2 | Lv3 | Lv4 | Lv5 | 설명 |
|--------|------|-----|-----|-----|-----|-----|------|
| 죽음의 껍질 | HP% | +15% | +20% | +25% | +30% | +35% | 최대 체력 증가 |
| 불사의 의지 | 불사 | 1회 | 1회 | 1회 | 1회 | 2회 | 치명타 시 HP 1 생존 (쿨다운 60초) |
| 죽음의 손길 | 공격 부가 | 10% | 12% | 14% | 16% | 18% | 공격 시 확률로 적 공속 -20% (3초) |
| 공포의 출현 | 출현 공포 | - | 30% | 40% | 50% | 60% | Lv2 해금. 출현 시 주변 적 공포 1초 |
| 시체 흡수 | HP회복 | - | - | 10% | 12% | 15% | Lv3 해금. 주변 시체 소모 HP 회복 |
| 영혼 수확 | 자원 획득 | - | - | - | - | +1 | Lv5 해금. 적 처치 시 영혼 +1 |

**전투 지원**: 전투 중 시체 자동 수집, 20% (+5%/Lv) 확률로 스켈레톤 부활 (원본 50% 스탯)

### 특수 기능

| 기능명 | 해금 | 비용 | 쿨다운 | 설명 |
|--------|------|------|--------|------|
| 시체 수집 | Lv1 | - | 자동 | 전투 후 적 시체 자동 수집. 시체당 영혼 1-3 |
| 해골 소환 | Lv1 | 영혼 20 | 웨이브 3회 | 스켈레톤 병사 1마리 생성 (일반 유닛 50% 스탯) |
| 부활 의식 | Lv2 | 영혼 50 | 웨이브 8회 | 최근 사망 아군을 언데드로 부활 (70% 스탯) |
| 죽음의 권능 | Lv2 | 영혼 30 | 전투 2회 | 언데드 1명 적 처치 시 HP 20% 회복 |
| 역병 퍼뜨리기 | Lv3 | 영혼 40, 골드 300 | 웨이브 10회 | 다음 웨이브 전 적 "역병". 매초 최대HP 1% (5초) |
| 죽음의 군단 | Lv4 | 영혼 100 | 웨이브 15회 | 스켈레톤 5마리 일시 소환 (3웨이브 지속) |
| 리치 강림 | Lv5 | 영혼 200, 크리스탈 20 | 웨이브 30회 | 리치 1마리 소환 (5웨이브). 마법공격 + 언데드 강화 오라 |

---

## 건물 관리 함수

```gml
/// @function building_construct(building_id)
function building_construct(building_id) {
    var template = get_building_template(building_id);

    if (!resource_can_afford(template.build_cost)) {
        return { success: false, reason: "insufficient_resources" };
    }

    if (!building_check_requirements(template)) {
        return { success: false, reason: "requirements_not_met" };
    }

    resource_spend_multi(template.build_cost);

    var construction = {
        building_id: building_id,
        start_time: current_time,
        complete_time: current_time + template.build_time * 1000,
        level: 1,
        stationed_units: []
    };

    array_push(global.constructions_in_progress, construction);

    return { success: true, construction: construction };
}

/// @function building_upgrade(building_instance)
function building_upgrade(building_instance) {
    var template = get_building_template(building_instance.building_id);

    if (building_instance.level >= template.max_level) {
        return { success: false, reason: "max_level_reached" };
    }

    var upgrade_cost = calculate_upgrade_cost(template, building_instance.level);

    if (!resource_can_afford(upgrade_cost)) {
        return { success: false, reason: "insufficient_resources" };
    }

    resource_spend_multi(upgrade_cost);
    building_instance.level++;

    building_recalculate_effects();

    return { success: true, new_level: building_instance.level };
}

/// @function building_get_garrison_buffs(building)
function building_get_garrison_buffs(building) {
    var template = get_building_template(building.building_id);
    var buffs = [];

    for (var i = 0; i < array_length(template.garrison_buffs); i++) {
        var buff = template.garrison_buffs[i];
        var value = buff.base_value + (building.level - 1) * buff.per_level;

        array_push(buffs, {
            type: buff.type,
            stat: buff.stat,
            value: value
        });
    }

    return buffs;
}
```

---

## 유닛 경제

### 유닛 고용/해고

```gml
/// 유닛 고용 비용 구조
unit_hiring = {
    // 기본 고용비
    base_cost: {
        common: { gold: 100 },
        uncommon: { gold: 250 },
        rare: { gold: 500, crystal: 1 },
        epic: { gold: 1000, crystal: 5 },
        legendary: { gold: 2500, crystal: 20 }
    },

    // 유닛 유지비 (웨이브당)
    upkeep: {
        common: { food: 1 },
        uncommon: { food: 2 },
        rare: { food: 3 },
        epic: { food: 5 },
        legendary: { food: 10 }
    },

    // 해고 시 환불
    dismiss_refund: 0.5  // 고용비의 50%
}

/// @function unit_hire(unit_id)
function unit_hire(unit_id) {
    var unit_data = get_unit_data(unit_id);
    var cost = unit_hiring.base_cost[$ unit_data.rarity];

    // 슬롯 확인
    if (get_current_unit_count() >= get_max_unit_slots()) {
        return { success: false, reason: "no_slots" };
    }

    // 비용 확인
    if (!resource_can_afford(cost)) {
        return { success: false, reason: "insufficient_resources" };
    }

    resource_spend_multi(cost);

    var new_unit = create_unit_instance(unit_id);
    array_push(global.player_units, new_unit);

    return { success: true, unit: new_unit };
}

/// @function unit_dismiss(unit_instance)
function unit_dismiss(unit_instance) {
    var unit_data = get_unit_data(unit_instance.unit_id);
    var base_cost = unit_hiring.base_cost[$ unit_data.rarity];

    // 환불
    var refund = {};
    var keys = variable_struct_get_names(base_cost);
    for (var i = 0; i < array_length(keys); i++) {
        var key = keys[i];
        refund[$ key] = floor(base_cost[$ key] * unit_hiring.dismiss_refund);
    }

    resource_add_multi(refund, "unit_dismiss");

    // 유닛 제거
    array_delete_value(global.player_units, unit_instance);

    return { success: true, refund: refund };
}
```

### 유닛 강화 비용

```gml
/// 유닛 레벨업 비용
unit_levelup_cost = {
    // 경험치 기반
    exp_required: function(current_level) {
        return 100 * power(1.5, current_level - 1);
    },

    // 골드 추가 비용 (즉시 레벨업 시)
    instant_levelup_gold: function(current_level) {
        return 50 * current_level;
    }
}

/// 장비 강화 비용
equipment_upgrade_cost = {
    // 등급별 기본 비용
    base_by_tier: {
        common: { gold: 50, iron: 10 },
        uncommon: { gold: 100, iron: 25 },
        rare: { gold: 250, iron: 50, mana_crystal: 1 },
        epic: { gold: 500, iron: 100, mana_crystal: 5 },
        legendary: { gold: 1000, iron: 200, mana_crystal: 20 }
    },

    // 강화 단계별 배율
    level_multiplier: [1.0, 1.2, 1.5, 2.0, 3.0, 5.0]
}

/// 스킬 강화 비용
skill_upgrade_cost = {
    base: { gold: 200, mana_crystal: 2 },
    per_level_multiplier: 1.5
}
```

---

## 시너지 시스템

### 유닛 시너지

```gml
/// 시너지 정의
synergy_definitions = {
    // 종족 시너지
    human_alliance: {
        name: "인간 연합",
        required_tag: "human",
        thresholds: [
            { count: 2, effect: { type: "stat_bonus", stat: "def", value: 10 } },
            { count: 4, effect: { type: "stat_bonus", stat: "def", value: 25 } },
            { count: 6, effect: { type: "stat_bonus", stat: "all", value: 15 } }
        ]
    },

    undead_legion: {
        name: "언데드 군단",
        required_tag: "undead",
        thresholds: [
            { count: 2, effect: { type: "lifesteal", value: 10 } },
            { count: 4, effect: { type: "on_kill", effect: "raise_skeleton" } },
            { count: 6, effect: { type: "aura", aura: "death_aura" } }
        ]
    },

    // 역할 시너지
    frontline: {
        name: "전선 수비",
        required_tag: "tank",
        thresholds: [
            { count: 2, effect: { type: "taunt_chance", value: 30 } },
            { count: 3, effect: { type: "damage_reduction", value: 15 } }
        ]
    },

    assassins: {
        name: "암살단",
        required_tag: "assassin",
        thresholds: [
            { count: 2, effect: { type: "crit_chance", value: 15 } },
            { count: 3, effect: { type: "crit_damage", value: 50 } },
            { count: 4, effect: { type: "execute", threshold: 15 } }
        ]
    },

    // 속성 시너지
    fire_affinity: {
        name: "화염 친화",
        required_tag: "fire",
        thresholds: [
            { count: 2, effect: { type: "element_damage", element: "fire", value: 20 } },
            { count: 3, effect: { type: "burn_spread", chance: 30 } }
        ]
    }
}

/// @function synergy_calculate_active()
/// @description 현재 활성화된 시너지 계산
function synergy_calculate_active() {
    var active_synergies = [];
    var tag_counts = count_unit_tags(global.deployed_units);

    var synergy_keys = variable_struct_get_names(synergy_definitions);

    for (var i = 0; i < array_length(synergy_keys); i++) {
        var key = synergy_keys[i];
        var synergy = synergy_definitions[$ key];
        var tag = synergy.required_tag;

        if (variable_struct_exists(tag_counts, tag)) {
            var count = tag_counts[$ tag];
            var active_threshold = undefined;

            // 가장 높은 충족 단계 찾기
            for (var j = array_length(synergy.thresholds) - 1; j >= 0; j--) {
                if (count >= synergy.thresholds[j].count) {
                    active_threshold = synergy.thresholds[j];
                    break;
                }
            }

            if (active_threshold != undefined) {
                array_push(active_synergies, {
                    synergy_id: key,
                    name: synergy.name,
                    current_count: count,
                    threshold: active_threshold.count,
                    effect: active_threshold.effect
                });
            }
        }
    }

    return active_synergies;
}
```

### 건물 시너지

```gml
/// 건물 시너지
building_synergies = {
    // 인접 보너스
    adjacent_bonus: {
        gold_mine: {
            near: "refinery",
            bonus: { production_percent: 25 }
        },
        barracks: {
            near: "armory",
            bonus: { unit_stat: { atk: 10 } }
        }
    },

    // 세트 보너스
    set_bonus: {
        military_complex: {
            buildings: ["barracks", "armory", "training_ground"],
            bonus: {
                unit_training_speed: 50,
                military_unit_stats: { all: 10 }
            }
        },
        economic_hub: {
            buildings: ["gold_mine", "market", "bank"],
            bonus: {
                gold_production: 100,
                trade_discount: 20
            }
        }
    }
}
```

---

## 무역/교환 시스템

### 자원 교환

```gml
/// 자원 교환 비율
exchange_rates = {
    // 기본 교환 (골드 기준)
    gold_value: {
        crystal: 100,       // 1 크리스탈 = 100 골드
        soul: 50,
        wood: 2,
        stone: 3,
        iron: 5,
        food: 1,
        mana_crystal: 75
    },

    // 교환 수수료
    exchange_fee: 0.1,  // 10%

    // 시장 가격 변동
    price_fluctuation: {
        enabled: true,
        min_multiplier: 0.7,
        max_multiplier: 1.5,
        update_interval: 300  // 5분마다
    }
}

/// @function resource_exchange(from_type, from_amount, to_type)
function resource_exchange(from_type, from_amount, to_type) {
    var from_key = resource_type_to_key(from_type);
    var to_key = resource_type_to_key(to_type);

    // 보유량 확인
    if (global.player_resources[$ from_key] < from_amount) {
        return { success: false, reason: "insufficient_resources" };
    }

    // 교환량 계산
    var from_value = from_amount * get_current_value(from_type);
    var to_value = from_value * (1 - exchange_rates.exchange_fee);
    var to_amount = floor(to_value / get_current_value(to_type));

    if (to_amount <= 0) {
        return { success: false, reason: "exchange_too_small" };
    }

    // 교환 실행
    global.player_resources[$ from_key] -= from_amount;
    global.player_resources[$ to_key] += to_amount;

    return {
        success: true,
        exchanged: to_amount,
        rate: to_amount / from_amount
    };
}
```

### 상점 시스템

```gml
/// 상점 구조
shop_system = {
    // 상점 종류
    shops: {
        general: {
            name: "일반 상점",
            refresh_cost: { gold: 50 },
            item_count: 5,
            pool: "general_pool"
        },
        equipment: {
            name: "장비 상점",
            refresh_cost: { gold: 100 },
            item_count: 4,
            pool: "equipment_pool",
            requires_building: "blacksmith"
        },
        unit: {
            name: "용병 상점",
            refresh_cost: { gold: 200 },
            item_count: 3,
            pool: "mercenary_pool",
            requires_building: "tavern"
        },
        special: {
            name: "신비한 상점",
            refresh_cost: { crystal: 5 },
            item_count: 2,
            pool: "special_pool",
            requires_reputation: 500
        }
    },

    // 자동 새로고침
    auto_refresh: {
        interval: "wave_end",
        free_refreshes_per_wave: 1
    }
}

/// @function shop_generate_items(shop_id)
function shop_generate_items(shop_id) {
    var shop = shop_system.shops[$ shop_id];
    var pool = get_item_pool(shop.pool);
    var items = [];

    for (var i = 0; i < shop.item_count; i++) {
        var item = weighted_random_select(pool);
        var price = calculate_item_price(item);

        array_push(items, {
            item_data: item,
            price: price,
            sold: false
        });
    }

    return items;
}
```

---

## 퀘스트/업적 보상

### 퀘스트 시스템

```gml
/// 퀘스트 구조
quest_template = {
    id: "quest_id",
    name: "퀘스트 이름",
    description: "설명",

    // 조건
    objectives: [
        { type: "kill_monster", monster_tag: "undead", count: 50 },
        { type: "clear_wave", wave_number: 10 },
        { type: "build_building", building_id: "barracks" }
    ],

    // 보상
    rewards: {
        gold: 1000,
        crystal: 5,
        reputation: 50,
        items: ["rare_sword"],
        unlocks: ["special_unit"]
    },

    // 타입
    quest_type: "main",  // main, side, daily, weekly
    repeatable: false,
    time_limit: undefined
}

/// 퀘스트 목표 타입
quest_objective_types = {
    kill_monster: { params: ["monster_tag", "count"] },
    kill_boss: { params: ["boss_id"] },
    clear_wave: { params: ["wave_number"] },
    clear_wave_no_damage: { params: ["wave_number"] },
    build_building: { params: ["building_id"] },
    upgrade_building: { params: ["building_id", "level"] },
    collect_resource: { params: ["resource", "amount"] },
    hire_unit: { params: ["unit_tag", "count"] },
    reach_reputation: { params: ["amount"] },
    activate_synergy: { params: ["synergy_id"] },
    use_skill: { params: ["skill_tag", "count"] }
}
```

### 업적 시스템

```gml
/// 업적 정의
achievements = {
    // 진행 업적
    monster_slayer: {
        name: "몬스터 사냥꾼",
        tiers: [
            { requirement: 100, reward: { gold: 500 } },
            { requirement: 1000, reward: { gold: 2000, crystal: 5 } },
            { requirement: 10000, reward: { gold: 10000, crystal: 50, title: "슬레이어" } }
        ],
        track: "total_monsters_killed"
    },

    // 일회성 업적
    first_boss: {
        name: "첫 보스 처치",
        requirement: { type: "kill_boss", count: 1 },
        reward: { gold: 1000, crystal: 10 }
    },

    // 숨겨진 업적
    secret_synergy: {
        name: "???",
        hidden: true,
        requirement: { type: "activate_synergy", synergy: "secret_combo" },
        reward: { unlock: "secret_unit" }
    }
}
```

---

## 웨이브 보상 시스템

### 보상 계산

```gml
/// @function wave_calculate_rewards(wave_data, performance)
/// @param {struct} wave_data - 웨이브 정보
/// @param {struct} performance - 클리어 성과
function wave_calculate_rewards(wave_data, performance) {
    var rewards = {
        gold: 0,
        exp: 0,
        items: [],
        resources: {}
    };

    // 기본 보상
    rewards.gold = wave_data.base_gold + (wave_data.wave_number * 50);
    rewards.exp = wave_data.base_exp + (wave_data.wave_number * 20);

    // 몬스터 처치 보상
    rewards.gold += performance.monsters_killed * 5;
    rewards.exp += performance.monsters_killed * 2;

    // 보스 보상
    if (performance.boss_killed) {
        rewards.gold += wave_data.boss_bonus_gold;
        array_push(rewards.items, wave_data.boss_drop);
    }

    // 성과 보너스
    if (performance.no_damage) {
        rewards.gold = floor(rewards.gold * 1.5);
        rewards.exp = floor(rewards.exp * 1.5);
    }

    if (performance.speed_clear) {
        rewards.gold = floor(rewards.gold * 1.2);
    }

    // 건물 보너스 적용
    var building_bonus = building_get_wave_reward_bonus();
    rewards.gold = floor(rewards.gold * (1 + building_bonus / 100));

    // 시너지 보너스 적용
    var synergy_bonus = synergy_get_reward_bonus();
    rewards.gold = floor(rewards.gold * (1 + synergy_bonus / 100));

    return rewards;
}

/// 성과 평가 기준
wave_performance_criteria = {
    no_damage: {
        description: "아군 유닛 무피해 클리어",
        condition: function(performance) {
            return performance.total_damage_taken == 0;
        }
    },
    speed_clear: {
        description: "제한 시간 내 클리어",
        condition: function(performance, wave_data) {
            return performance.clear_time < wave_data.par_time;
        }
    },
    full_clear: {
        description: "모든 몬스터 처치",
        condition: function(performance, wave_data) {
            return performance.monsters_killed >= wave_data.total_monsters;
        }
    },
    no_casualties: {
        description: "아군 유닛 생존",
        condition: function(performance) {
            return performance.units_lost == 0;
        }
    }
}
```

---

## 경제 밸런스 참고

### 수치 밸런스 가이드

```gml
/// 게임 진행 단계별 기대 자원
economy_progression = {
    early_game: {  // 웨이브 1-10
        gold_per_wave: 150,
        expected_gold_total: 1500,
        unit_slots: 3,
        building_slots: 2
    },
    mid_game: {    // 웨이브 11-30
        gold_per_wave: 400,
        expected_gold_total: 8000,
        unit_slots: 6,
        building_slots: 5
    },
    late_game: {   // 웨이브 31-50
        gold_per_wave: 800,
        expected_gold_total: 24000,
        unit_slots: 10,
        building_slots: 8
    },
    end_game: {    // 웨이브 51+
        gold_per_wave: 1500,
        expected_gold_total: "unlimited",
        unit_slots: 15,
        building_slots: 12
    }
}

/// 비용 밸런스 원칙
cost_balance_principles = {
    // 1. 유닛 고용비 = 웨이브 2~3회 보상
    // 2. 건물 건설비 = 웨이브 5~10회 보상
    // 3. 업그레이드 비용 = 이전 단계의 1.5배
    // 4. 프리미엄 자원은 보스/업적에서 주로 획득
    // 5. 유지비는 총 수입의 20-30%를 넘지 않도록
}
```

---

## 관련 문서

- [INDEX.md](./INDEX.md) - 전체 시스템 개요
- [UNIT_SYSTEM.md](./UNIT_SYSTEM.md) - 유닛 시스템 (고용/강화 대상)
- [BATTLE_SYSTEM.md](./BATTLE_SYSTEM.md) - 전투 시스템 (웨이브 보상)
- [SKILL_EFFECT_SYSTEM.md](./SKILL_EFFECT_SYSTEM.md) - 스킬 시스템 (강화 대상)

---

## 구현 시 체크리스트

- [ ] 기본 자원 타입 정의 및 저장소 구현
- [ ] 자원 획득/소모 함수 구현
- [ ] 건물 데이터 구조 정의
- [ ] 건물 건설/업그레이드 로직 구현
- [ ] 건물 효과 적용 시스템 구현
- [ ] 유닛 고용/해고 시스템 구현
- [ ] 유닛 유지비 시스템 구현
- [ ] 시너지 계산 로직 구현
- [ ] 상점 시스템 구현
- [ ] 퀘스트/업적 시스템 구현
- [ ] 웨이브 보상 계산 로직 구현
- [ ] 경제 밸런스 테스트

---

## 변경 이력

| 버전 | 날짜 | 내용 |
|------|------|------|
| 1.0 | 2024-12-23 | SKILL_SYSTEM.md에서 분리하여 생성 |
