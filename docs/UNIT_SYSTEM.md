# 유닛 시스템

> 유닛 구조, 건물 주둔, 출전 위치, AI, 소환, 시체, 진화/변이 시스템

---

## 목차

1. [유닛 기본 구조](#1-유닛-기본-구조)
   - 1.1 유닛 정의
   - 1.2 종족 (Race)
   - 1.3 직업 (Class)
   - 1.4 전투 속성 (Combat)
   - 1.5 유닛 예시
   - 1.6 AI 역할 매핑
   - 1.7 스탯 시스템 (1차/2차/저항 스탯, 전투 공식, 종족 보정)
2. [건물 주둔 시스템](#2-건물-주둔-시스템)
   - 2.1~2.5 건물 배치 규칙
   - 2.6 유닛 주둔 관리
3. [출전 위치 시스템](#3-출전-위치-시스템)
4. [유닛 AI 시스템](#4-유닛-ai-시스템)
   - 4.1 AI 설계 원칙
   - 4.2 적 AI (단순): ai_rush, ai_ranged, ai_boss
   - 4.3 아군 AI (복잡): 7가지 역할별 AI
   - 4.4 타겟 선정 시스템
   - 4.5 스킬 사용 판단
   - 4.6 위협도 시스템
   - 4.7 포지셔닝 AI
   - 4.8 길찾기 및 이동 시스템
     - Spatial Grid, A* 8방향, Steering, 전선 인식, 진형
5. [소환 시스템](#5-소환-시스템)
6. [시체 시스템](#6-시체-시스템)
7. [진화/변이 시스템](#7-진화변이-시스템)
8. [구현 가이드](#8-구현-가이드)

---

## 1. 유닛 기본 구조

### 1.1 유닛 정의

```gml
unit = {
    // 식별
    id: 1001,
    type: "knight",
    name: "기사",
    team: "ally",               // "ally", "enemy"

    // ★ 정체성 (NEW)
    race: "human",              // 종족 - 건물 배치 1차 결정
    class: "warrior",           // 직업 - 건물 배치 우선, 스킬셋 결정

    // ★ 전투 속성 (NEW)
    combat: {
        range: "melee",         // melee, ranged, hybrid
        function: "tank",       // damage, tank, healer, support (복수 가능)
        damage_type: "physical" // physical, magical, holy, shadow, elemental (복수 가능)
    },

    // 스탯
    level: 1,
    hp: 1000,
    max_hp: 1000,
    mana: 0,
    max_mana: 100,

    attack: 80,
    defense: 50,
    attack_speed: 1.0,
    movement_speed: 100,
    attack_range: 1,            // 공격 사거리

    crit_chance: 10,
    crit_damage: 150,
    dodge_chance: 5,

    // 추가 태그 (세부 특성)
    tags: ["armored", "knight"],

    // 스킬
    skills: ["skill_shield_bash", "skill_taunt"],
    passives: ["passive_block"],

    // 현재 상태
    active_effects: [],         // 버프/디버프
    stacks: {},                 // 스택들
    orbs: [],                   // 오브

    // ★ 건물 주둔 정보
    assigned_building: null,    // 주둔 중인 건물 참조

    // ★ 출전 위치 (유닛 개별 설정)
    deploy_position: "FC",      // FL, FC, FR, BL, BC, BR, WL, WC, WR
    deploy_options: {
        delay: 0,               // 추가 출전 딜레이 (초)
        entry_style: "walk"     // walk, charge, stealth, rise, teleport, fly
    },

    // 소환 관련
    summoned_units: [],         // 내가 소환한 유닛
    summoner_id: -1,            // 나를 소환한 유닛 (-1이면 소환물 아님)
    is_summon: false,

    // AI
    ai_type: "ai_tank",

    // 위협도
    threat_table: {},

    // 진화
    evolution_progress: {},
    can_evolve: false
}
```

### 1.2 종족 (Race)

> 건물 배치 가능 여부의 1차 기준. 직업 건물에 못 들어가면 종족 건물로 배치.

| 종족 | 설명 | 기본 건물 | 특수 건물 |
|------|------|----------|----------|
| `human` | 인간 | 직업 기반 | - |
| `elf` | 엘프 | 직업 기반 | - |
| `dwarf` | 드워프 | 직업 기반 | - |
| `orc` | 오크 | 직업 기반 | - |
| `undead` | 언데드 | 묘지 | 신전 금지 |
| `demon` | 악마 | 마족 제단 | 신전 금지 |
| `slime` | 슬라임 | 슬라임 소굴 | - |
| `beast` | 야수 | 야수 우리 | - |
| `elemental` | 정령 | 직업 기반 | - |
| `construct` | 구조물 | 작업장 | - |
| `dragon` | 용족 | 용의 둥지 | - |

### 1.3 직업 (Class)

> 건물 배치 우선 기준. 직업에 맞는 건물이 있으면 그곳에 우선 배치.

| 직업 | 대응 건물 | 주요 역할 | 예시 유닛 |
|------|----------|----------|----------|
| `warrior` | 병영 | 근접 전투, 탱킹 | 전사, 기사, 버서커 |
| `mage` | 마법사탑 | 마법 공격, 원거리 | 마법사, 흑마법사, 배틀메이지 |
| `priest` | 신전 | 치유, 버프 | 성직자, 수도사 |
| `paladin` | 신전 또는 병영 | 탱킹 + 치유 하이브리드 | 성기사 |
| `rogue` | 암살자 길드 | 암살, 은신 | 도적, 암살자 |
| `ranger` | 궁수 초소 | 원거리 물리 | 궁수, 사냥꾼 |
| `necromancer` | 묘지 | 소환, 언데드 조종 | 강령술사, 사령술사 |
| `summoner` | 직업 따라 | 소환수 관리 | 소환사 |

### 1.4 전투 속성 (Combat Attributes)

> 유닛의 전투 스타일을 세분화. 복수 값 허용.

#### 전투 거리 (range)

| 값 | 설명 | AI 행동 |
|----|------|---------|
| `melee` | 근접 전투 | 적에게 돌진, 사거리 1 |
| `ranged` | 원거리 전투 | 거리 유지, 사거리 4+ |
| `hybrid` | 근/원거리 혼합 | 상황에 따라 변경 |

#### 주요 기능 (function)

| 값 | 설명 | AI 우선순위 |
|----|------|-------------|
| `damage` | 딜러 | 적 처치 우선 |
| `tank` | 탱커 | 아군 보호, 도발 |
| `healer` | 힐러 | 아군 치유 우선 |
| `support` | 서포터 | 버프/디버프 우선 |

#### 공격 속성 (damage_type)

| 값 | 설명 | 상성 |
|----|------|------|
| `physical` | 물리 | 방어력으로 감소 |
| `magical` | 마법 | 마법저항으로 감소 |
| `holy` | 신성 | 언데드/악마에 강함 |
| `shadow` | 암흑 | 성스러운 존재에 강함 |
| `elemental` | 원소 | 화/빙/전기 등 세부 분류 |

### 1.5 유닛 예시

```gml
// 인간 기사 (일반적)
unit_knight = {
    race: "human",
    class: "warrior",
    combat: { range: "melee", function: "tank", damage_type: "physical" }
    // → 병영에 배치
}

// 슬라임 마법사 (종족 특수)
unit_slime_mage = {
    race: "slime",
    class: "mage",
    combat: { range: "ranged", function: "damage", damage_type: "magical" }
    // → 1순위: 마법사탑 (직업), 2순위: 슬라임 소굴 (종족)
}

// 성기사 (하이브리드)
unit_paladin = {
    race: "human",
    class: ["warrior", "priest"],       // 복합 직업
    combat: {
        range: "melee",
        function: ["tank", "healer"],   // 복합 기능
        damage_type: ["physical", "holy"]
    }
    // → 병영 또는 신전 선택 가능
}

// 배틀메이지 (비전형)
unit_battle_mage = {
    race: "human",
    class: "mage",
    combat: { range: "melee", function: "damage", damage_type: "magical" }
    // → 마법사탑 (마법사지만 근접)
}

// 언데드 암살자 (종족 제한)
unit_undead_assassin = {
    race: "undead",
    class: "rogue",
    combat: { range: "melee", function: "damage", damage_type: ["physical", "shadow"] }
    // → 암살자 길드 금지 (humanoid only) → 묘지로 배치
}

// 데몬 힐러 (금지 조합)
unit_demon_priest = {
    race: "demon",
    class: "priest",
    combat: { range: "ranged", function: "healer", damage_type: "shadow" }
    // → 신전 금지 (demon 금지) → 마족 제단으로 배치
}
```

### 1.6 AI 역할 매핑

> `combat.function`을 기반으로 AI 행동 패턴 결정

| function | AI 타입 | 기본 행동 |
|----------|---------|----------|
| `tank` | ai_tank | 가장 가까운 적 저지, 도발 우선 |
| `damage` + melee | ai_melee_dps | 적진 돌입, 낮은 체력 적 우선 |
| `damage` + ranged | ai_ranged_dps | 후열 유지, 사거리 내 공격 |
| `healer` | ai_healer | 후열 유지, 낮은 체력 아군 우선 |
| `support` | ai_support | 중열 유지, 버프/디버프 우선 |
| `damage` + rogue | ai_assassin | 적 후열 침투, 원거리/힐러 우선 |

### 1.7 스탯 시스템

> 유닛의 전투력을 결정하는 수치 체계

#### 1.7.1 스탯 분류

```
┌───────────────────────────────────────────────────────────────────────┐
│                           스탯 체계                                    │
├───────────────────┬─────────────────┬─────────────────────────────────┤
│   1차 스탯        │   2차 스탯       │   상태이상 저항                  │
│   (Primary)       │   (Secondary)    │   (Resistance)                  │
├───────────────────┼─────────────────┼─────────────────────────────────┤
│ • HP / 마나       │ • 치명타 확률    │ • CC 저항                       │
│ • 물리 공격력     │ • 치명타 데미지  │ • 디버프 저항                   │
│ • 마법 공격력     │ • 회피율         │                                 │
│ • 물리 방어력     │ • 명중률         │                                 │
│ • 마법 방어력     │ • 흡혈 / 주술흡수│                                 │
│ • 공격 속도       │ • 치유력         │                                 │
│ • 이동 속도       │ • 관통 (물리/마법)│                                │
│ • 사거리          │ • 쿨감 / 재생    │                                 │
└───────────────────┴─────────────────┴─────────────────────────────────┘
```

> **단순화된 방어 체계**: 물리 방어력 / 마법 방어력 2개로 모든 피해 감소 처리
> 속성(화염, 냉기 등)은 데미지 타입만 구분, 별도 저항 없음

#### 1.7.2 1차 스탯 (Primary Stats)

| 스탯 | 코드 | 설명 | 기본값 범위 |
|------|------|------|------------|
| **체력** | `hp`, `max_hp` | 0이 되면 사망 | 100 ~ 5000 |
| **마나** | `mana`, `max_mana` | 스킬 사용 자원 | 0 ~ 500 |
| **물리 공격력** | `physical_attack` | 물리 데미지 기준 (전사, 궁수, 도적) | 10 ~ 500 |
| **마법 공격력** | `magic_attack` | 마법 데미지 기준 (마법사, 힐러) | 0 ~ 500 |
| **물리 방어력** | `physical_defense` | 물리 피해 감소 | 0 ~ 300 |
| **마법 방어력** | `magic_defense` | 마법 피해 감소 | 0 ~ 300 |
| **공격 속도** | `attack_speed` | 초당 공격 횟수 (1.0 = 1초 1회) | 0.5 ~ 3.0 |
| **이동 속도** | `movement_speed` | 픽셀/초 이동량 | 50 ~ 200 |
| **사거리** | `attack_range` | 타일 단위 공격 거리 | 1 ~ 8 |

```gml
// 1차 스탯 정의
stats_primary = {
    hp: 1000,
    max_hp: 1000,
    mana: 100,
    max_mana: 100,

    // 공격력 (물리/마법 분리)
    physical_attack: 100,   // 물리 공격 스킬 스케일링
    magic_attack: 0,        // 마법 공격/힐 스킬 스케일링

    // 방어력 (물리/마법 분리)
    physical_defense: 50,   // 물리 피해 감소
    magic_defense: 20,      // 마법 피해 감소

    attack_speed: 1.0,      // 1.0 = 1초에 1회 공격
    movement_speed: 100,    // 픽셀/초
    attack_range: 1         // 타일 (1 = 근접)
}
```

##### 직업별 공격력 분배 가이드

| 직업 | 물리 공격력 | 마법 공격력 | 비고 |
|------|------------|------------|------|
| 전사/기사 | ★★★ | - | 순수 물리 |
| 궁수/사냥꾼 | ★★★ | - | 순수 물리 |
| 도적/암살자 | ★★★ | - | 순수 물리 |
| 마법사 | - | ★★★ | 순수 마법 |
| 힐러/사제 | - | ★★★ | 마공 = 힐량 스케일 |
| 성기사 | ★★ | ★ | 하이브리드 |
| 배틀메이지 | ★ | ★★ | 하이브리드 |
| 흑마법사 | - | ★★★ | 순수 마법 + 암흑 |

#### 1.7.3 2차 스탯 (Secondary Stats)

| 스탯 | 코드 | 설명 | 기본값 | 최대값 |
|------|------|------|--------|--------|
| **치명타 확률** | `crit_chance` | 크리티컬 발동 확률 (%) | 5 | 100 |
| **치명타 데미지** | `crit_damage` | 크리티컬 시 데미지 배율 (%) | 150 | 500 |
| **회피율** | `dodge_chance` | 공격 회피 확률 (%) | 0 | 75 |
| **명중률** | `accuracy` | 기본 명중률 (%) | 100 | 150 |
| **물리 흡혈** | `physical_lifesteal` | 물리 데미지의 N% HP 회복 | 0 | 100 |
| **마법 흡수** | `magic_lifesteal` | 마법 데미지의 N% HP 회복 | 0 | 100 |
| **치유력** | `healing_power` | 힐량 증가 (%) | 0 | 200 |
| **물리 관통** | `physical_penetration` | 적 물리 방어력 무시 (%) | 0 | 100 |
| **마법 관통** | `magic_penetration` | 적 마법 방어력 무시 (%) | 0 | 100 |
| **쿨다운 감소** | `cooldown_reduction` | 스킬 쿨다운 감소 (%) | 0 | 50 |
| **마나 재생** | `mana_regen` | 초당 마나 회복량 | 0 | 50 |
| **체력 재생** | `hp_regen` | 초당 HP 회복량 | 0 | 100 |

```gml
// 2차 스탯 정의
stats_secondary = {
    // 치명타
    crit_chance: 10,            // 10%
    crit_damage: 150,           // 150% (1.5배)

    // 회피/명중
    dodge_chance: 5,            // 5%
    accuracy: 100,              // 100% (기본)

    // 흡혈 (물리/마법 분리)
    physical_lifesteal: 0,      // 물리 공격 시 흡혈
    magic_lifesteal: 0,         // 마법 공격 시 흡혈

    // 치유
    healing_power: 0,           // 힐량 증가 %

    // 관통 (물리/마법 분리)
    physical_penetration: 0,    // 물리 방어 관통 %
    magic_penetration: 0,       // 마법 방어 관통 %

    // 재생/쿨다운
    cooldown_reduction: 0,      // 쿨다운 감소 %
    mana_regen: 5,              // 초당 마나 회복
    hp_regen: 0                 // 초당 HP 회복
}
```

> **힐량 스케일링**: 힐 스킬은 `magic_attack`을 기준으로 스케일링되며, `healing_power`로 추가 증폭

#### 1.7.4 저항 스탯 (Resistance Stats)

> 피해 감소는 물리/마법 방어력(1차 스탯)에서 처리, 여기는 **상태이상 저항**만 관리

| 스탯 | 코드 | 설명 | 기본값 | 최대값 |
|------|------|------|--------|--------|
| **CC 저항** | `cc_resist` | CC 지속시간 감소 (%) | 0 | 80 |
| **디버프 저항** | `debuff_resist` | 디버프 적용 확률 감소 (%) | 0 | 50 |

```gml
// 저항 스탯 정의
stats_resistance = {
    cc_resist: 0,           // CC 지속시간 감소
    debuff_resist: 0        // 디버프 적용 확률 감소
}
```

##### 데미지 타입 분류

| 타입 | 스케일링 | 방어 적용 | 비고 |
|------|----------|----------|------|
| `physical` | 물리 공격력 | 물리 방어력 | 전사, 궁수, 도적 |
| `magical` | 마법 공격력 | 마법 방어력 | 순수 마법 |
| `fire` | 마법 공격력 | 마법 방어력 | 화염 (추가 효과: 도트) |
| `ice` | 마법 공격력 | 마법 방어력 | 냉기 (추가 효과: 슬로우) |
| `electric` | 마법 공격력 | 마법 방어력 | 번개 (추가 효과: 연쇄) |
| `poison` | 마법 공격력 | 마법 방어력 | 독 (추가 효과: 도트) |
| `shadow` | 마법 공격력 | 마법 방어력 | 암흑 (추가 효과: 흡혈) |
| `holy` | 마법 공격력 | 마법 방어력 | 신성 (추가 효과: 힐감소) |
| `true` | 없음 | **무시** | 고정 피해 (방어 관통) |

> **속성의 역할**: 저항이 아닌 **추가 효과**로 차별화
> - 화염: 지속 데미지 (도트)
> - 냉기: 이동속도 감소
> - 번개: 주변 적에게 연쇄
> - 독: 지속 데미지 + 힐량 감소
> - 암흑: 시전자 흡혈
> - 신성: 언데드/악마에게 추가 피해

#### 1.7.5 스탯 계산 공식

> 최종 스탯 = (기본값 + 고정 보너스) × (1 + 퍼센트 보너스)

```gml
/// @func calculate_final_stat(unit, stat_name)
/// @desc 버프/디버프 적용된 최종 스탯 계산
function calculate_final_stat(unit, stat_name) {
    var base = unit.base_stats[$ stat_name] ?? 0;
    var flat_bonus = 0;
    var percent_bonus = 0;

    // 모든 활성 효과에서 보너스 수집
    for (var i = 0; i < array_length(unit.active_effects); i++) {
        var effect = unit.active_effects[i];
        if (effect.stat == stat_name) {
            if (effect.is_percent) {
                percent_bonus += effect.value;
            } else {
                flat_bonus += effect.value;
            }
        }
    }

    // 장비, 건물 버프 등 추가 보너스
    flat_bonus += get_equipment_bonus(unit, stat_name, false);
    flat_bonus += get_building_bonus(unit, stat_name, false);
    percent_bonus += get_equipment_bonus(unit, stat_name, true);
    percent_bonus += get_building_bonus(unit, stat_name, true);

    // 최종 계산
    var final = (base + flat_bonus) * (1 + percent_bonus / 100);

    // 스탯별 최소/최대 적용
    final = clamp_stat(stat_name, final);

    return final;
}

/// @func clamp_stat(stat_name, value)
function clamp_stat(stat_name, value) {
    switch(stat_name) {
        case "attack_speed":    return clamp(value, 0.1, 5.0);
        case "crit_chance":     return clamp(value, 0, 100);
        case "dodge_chance":    return clamp(value, 0, 75);
        case "cc_resist":       return clamp(value, 0, 80);
        case "cooldown_reduction": return clamp(value, 0, 50);
        default:                return max(0, value);
    }
}
```

#### 1.7.6 전투 공식

##### 데미지 계산 흐름

```
┌──────────────────────────────────────────────────────────────────┐
│                     데미지 계산 순서                              │
├──────────────────────────────────────────────────────────────────┤
│ 1. 기본 데미지 + 공격력 스케일링 (물공 or 마공)                   │
│    ↓                                                             │
│ 2. 방어력 감소 (물방 or 마방) - 관통 적용                         │
│    ↓                                                             │
│ 3. 크리티컬 체크                                                  │
│    ↓                                                             │
│ 4. 최종 피해 감소/증가 버프                                       │
│    ↓                                                             │
│ 5. 흡혈 처리 (물리 흡혈 or 마법 흡수)                             │
└──────────────────────────────────────────────────────────────────┘
```

```gml
/// @func calculate_damage(attacker, defender, base_damage, damage_type, scale_percent)
/// @desc 최종 데미지 계산
function calculate_damage(attacker, defender, base_damage, damage_type, scale_percent) {
    var damage = base_damage;
    var is_crit = false;
    var is_physical = (damage_type == "physical");
    var is_magical = (damage_type != "physical") && (damage_type != "true");

    // === 1. 공격력 스케일링 ===
    if (is_physical) {
        damage += attacker.physical_attack * (scale_percent / 100);
    } else if (is_magical) {
        // 모든 마법 타입(magical, fire, ice 등)은 마공 스케일링
        damage += attacker.magic_attack * (scale_percent / 100);
    }
    // true 데미지는 스케일링 없음

    // === 2. 방어력 감소 ===
    if (is_physical) {
        var pen = attacker.physical_penetration / 100;
        var effective_def = defender.physical_defense * (1 - pen);
        damage = damage * (100 / (100 + effective_def));
    } else if (is_magical) {
        var pen = attacker.magic_penetration / 100;
        var effective_def = defender.magic_defense * (1 - pen);
        damage = damage * (100 / (100 + effective_def));
    }
    // true 데미지는 방어 무시

    // === 3. 크리티컬 체크 ===
    if (random(100) < attacker.crit_chance) {
        damage = damage * (attacker.crit_damage / 100);
        is_crit = true;
    }

    // === 4. 최종 피해 증감 ===
    damage = damage * (1 + attacker.damage_bonus / 100);
    damage = damage * (1 - defender.damage_reduction / 100);

    // === 5. 최종 데미지 (최소 1) ===
    damage = max(1, floor(damage));

    // === 6. 흡혈 처리 ===
    var lifesteal_amount = 0;
    if (is_physical && attacker.physical_lifesteal > 0) {
        lifesteal_amount = damage * (attacker.physical_lifesteal / 100);
    } else if (is_magical && attacker.magic_lifesteal > 0) {
        lifesteal_amount = damage * (attacker.magic_lifesteal / 100);
    }
    if (lifesteal_amount > 0) {
        heal_unit(attacker, floor(lifesteal_amount));
    }

    return {
        damage: damage,
        is_crit: is_crit,
        damage_type: damage_type,
        lifesteal: floor(lifesteal_amount)
    };
}
```

##### 예시: 물리 공격 vs 마법 공격

```gml
// 전사의 물리 공격 (물공 100, 스킬 계수 150%)
// 대상: 물방 50
damage = 50 + 100 * 1.5 = 200
damage = 200 * (100 / 150) = 133

// 마법사의 화염 공격 (마공 120, 스킬 계수 200%)
// 대상: 마방 30
damage = 100 + 120 * 2.0 = 340
damage = 340 * (100 / 130) = 261
// → 화염 속성은 추가 효과(도트)로 차별화, 저항 없음
```

##### 명중/회피 계산

```gml
/// @func check_hit(attacker, defender)
/// @desc 공격 명중 여부 판정
function check_hit(attacker, defender) {
    // 명중률 - 회피율 = 실제 명중 확률
    var hit_chance = attacker.accuracy - defender.dodge_chance;
    hit_chance = clamp(hit_chance, 10, 100);  // 최소 10% 명중

    return random(100) < hit_chance;
}
```

##### 힐량 계산

```gml
/// @func calculate_heal(healer, target, base_heal, scale_percent)
function calculate_heal(healer, target, base_heal, scale_percent) {
    // 기본 힐 + 마법 공격력 스케일링
    var heal = base_heal + healer.magic_attack * (scale_percent / 100);

    // 치유력 보너스 (힐러 특화 스탯)
    heal = heal * (1 + healer.healing_power / 100);

    // 대상의 받는 힐량 증가/감소
    heal = heal * (1 + target.healing_received_bonus / 100);

    return floor(heal);
}

// 예시: 사제의 치유 (마공 80, 스킬 계수 150%, 치유력 +30%)
// heal = 100 + 80 * 1.5 = 220
// heal = 220 * 1.3 = 286 (치유력 적용)
```

##### CC 지속시간 계산

```gml
/// @func calculate_cc_duration(base_duration, target)
function calculate_cc_duration(base_duration, target) {
    var duration = base_duration * (1 - target.cc_resist / 100);
    return max(0.5, duration);  // 최소 0.5초
}
```

#### 1.7.7 스탯 성장 (레벨업)

```gml
// 유닛별 성장률 정의
unit_growth = {
    type: "knight",
    base_stats: {
        hp: 500,
        mana: 50,
        attack: 40,
        defense: 30
    },
    growth_per_level: {
        hp: 80,             // 레벨당 +80 HP
        mana: 5,            // 레벨당 +5 마나
        attack: 5,          // 레벨당 +5 공격력
        defense: 4          // 레벨당 +4 방어력
    }
}

/// @func get_stat_at_level(unit_type, stat, level)
function get_stat_at_level(unit_type, stat, level) {
    var data = unit_data[$ unit_type];
    var base = data.base_stats[$ stat] ?? 0;
    var growth = data.growth_per_level[$ stat] ?? 0;

    return base + growth * (level - 1);
}
```

#### 1.7.8 역할별 스탯 가이드라인

| 역할 | 주요 스탯 | HP | 물공 | 마공 | 물방 | 마방 | 공속 |
|------|----------|-----|------|------|------|------|------|
| **탱커** | HP, 물방, 마방 | ★★★ | ★ | - | ★★★ | ★★ | ★ |
| **근접 딜러** | 물공, 치명타 | ★★ | ★★★ | - | ★★ | ★ | ★★★ |
| **원거리 딜러** | 물공, 사거리 | ★ | ★★★ | - | ★ | ★ | ★★ |
| **마법사** | 마공, 마나 | ★ | - | ★★★ | ★ | ★ | ★ |
| **힐러** | 마공, 치유력 | ★ | - | ★★★ | ★ | ★★ | ★ |
| **암살자** | 물공, 치명타, 이속 | ★ | ★★★ | - | ★ | ★ | ★★ |
| **하이브리드** | 물공+마공 | ★★ | ★★ | ★★ | ★★ | ★★ | ★★ |

#### 1.7.9 종족별 스탯 보정

| 종족 | 보정 스탯 | 약점 |
|------|----------|------|
| `human` | 균형 (보정 없음) | 없음 |
| `elf` | 이속 +10%, 회피 +5% | HP -10% |
| `dwarf` | 물방 +15%, HP +10% | 이속 -10% |
| `orc` | 물공 +15%, HP +10% | 마방 -10% |
| `undead` | HP재생 무효 (좀비) | 신성 스킬에 추가 피해 |
| `demon` | 물공 +10%, 물리흡혈 +10% | 신성 스킬에 추가 피해 |
| `beast` | 이속 +20%, 공속 +10% | 마방 -15% |
| `dragon` | 전 스탯 +10% | 없음 (희귀) |

> **신성 약점 처리**: 속성 저항 대신 스킬에 `bonus_vs_tags` 사용
> ```gml
> // 신성 스킬 예시
> skill_holy_smite = {
>     damage_type: "holy",
>     bonus_vs_tags: { undead: 1.5, demon: 1.3 }  // 50%, 30% 추가 피해
> }
> ```

```gml
/// @func apply_race_modifier(unit)
function apply_race_modifier(unit) {
    switch(unit.race) {
        case "elf":
            unit.movement_speed *= 1.1;
            unit.dodge_chance += 5;
            unit.max_hp *= 0.9;
            break;
        case "dwarf":
            unit.physical_defense *= 1.15;
            unit.max_hp *= 1.1;
            unit.movement_speed *= 0.9;
            break;
        case "orc":
            unit.physical_attack *= 1.15;
            unit.max_hp *= 1.1;
            unit.magic_defense *= 0.9;
            break;
        case "undead":
            unit.hp_regen = 0;              // HP 재생 불가
            array_push(unit.tags, "undead"); // 신성 추가피해 태그
            break;
        case "demon":
            unit.physical_attack *= 1.1;
            unit.physical_lifesteal += 10;
            array_push(unit.tags, "demon");  // 신성 추가피해 태그
            break;
        case "beast":
            unit.movement_speed *= 1.2;
            unit.attack_speed *= 1.1;
            unit.magic_defense *= 0.85;
            break;
        case "dragon":
            unit.max_hp *= 1.1;
            unit.physical_attack *= 1.1;
            unit.magic_attack *= 1.1;
            unit.physical_defense *= 1.1;
            unit.magic_defense *= 1.1;
            break;
    }
}
```

#### 1.7.10 전체 스탯 구조 예시

```gml
// 완전한 유닛 스탯 구조
unit_stats = {
    // === 1차 스탯 ===
    hp: 1000,
    max_hp: 1000,
    mana: 100,
    max_mana: 100,

    // 공격력 (물리/마법)
    physical_attack: 80,
    magic_attack: 0,

    // 방어력 (물리/마법)
    physical_defense: 50,
    magic_defense: 20,

    attack_speed: 1.0,
    movement_speed: 100,
    attack_range: 1,

    // === 2차 스탯 ===
    crit_chance: 10,
    crit_damage: 150,
    dodge_chance: 5,
    accuracy: 100,

    // 흡혈 (물리/마법)
    physical_lifesteal: 0,
    magic_lifesteal: 0,
    healing_power: 0,

    // 관통 (물리/마법)
    physical_penetration: 0,
    magic_penetration: 0,

    cooldown_reduction: 0,
    mana_regen: 5,
    hp_regen: 0,

    // === 상태이상 저항 ===
    cc_resist: 0,
    debuff_resist: 0,

    // === 특수 스탯 (상황별) ===
    damage_reduction: 0,        // 최종 피해 감소
    healing_received_bonus: 0,  // 받는 힐량 증가
    damage_bonus: 0,            // 주는 피해 증가
    exp_bonus: 0,               // 경험치 획득 증가
    gold_bonus: 0               // 골드 획득 증가
}
```

---

## 2. 건물 주둔 시스템

> 유닛들은 영지 내 건물에 주둔하며, 전투 시작 시 성문 밖으로 출전

### 2.1 주둔 개요

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           영지 (Kingdom)                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐     │
│   │  병영   │  │ 마법사탑│  │  신전   │  │ 암살자  │  │  궁수   │     │
│   │Barracks │  │M. Tower │  │ Temple  │  │ Guild   │  │  Post   │     │
│   ├─────────┤  ├─────────┤  ├─────────┤  ├─────────┤  ├─────────┤     │
│   │ 슬롯: 4 │  │ 슬롯: 3 │  │ 슬롯: 3 │  │ 슬롯: 2 │  │ 슬롯: 4 │     │
│   │ 근접유닛│  │ 마법유닛│  │ 힐러   │  │ 암살자  │  │ 궁수    │     │
│   └─────────┘  └─────────┘  └─────────┘  └─────────┘  └─────────┘     │
│                                                                         │
│   ══════════════════════ 성   문 ══════════════════════                │
│                              ↓                                          │
│                     [ 전투 시작 시 출전 ]                               │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.2 건물 배치 우선순위

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
│  ※ 종족 건물은 "직업 건물에 못 들어가는 유닛"을 위한 대안     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2.3 직업 건물 (Job Buildings)

| 건물 | ID | 허용 직업 | 허용 종족 | 금지 종족 | 유지비 |
|------|-----|----------|----------|----------|--------|
| 병영 | `barracks` | warrior, tank | humanoid | - | 식량 3/유닛 |
| 마법사탑 | `mage_tower` | mage | 모든 종족 | - | 마나결정 1/유닛 |
| 신전 | `temple` | priest, paladin | holy 친화 | undead, demon | 골드 4/유닛 |
| 암살자 길드 | `assassin_guild` | rogue, assassin | humanoid | - | 골드 10/유닛 |
| 궁수 초소 | `archer_post` | ranger, archer | humanoid | - | 식량 2/유닛 |

### 2.4 종족 건물 (Race Buildings)

| 건물 | ID | 허용 종족 | 허용 직업 | 유지비 |
|------|-----|----------|----------|--------|
| 묘지 | `crypt` | undead | 모든 직업 | 영혼 1/유닛 |
| 슬라임 소굴 | `slime_den` | slime | 모든 직업 | 젤리 1/유닛 |
| 마족 제단 | `demon_altar` | demon | 모든 직업 | 피의 결정 1/유닛 |
| 야수 우리 | `beast_pen` | beast | 모든 직업 | 생고기 2/유닛 |
| 용의 둥지 | `dragon_nest` | dragon | 모든 직업 | 골드 20/유닛 |

### 2.5 배치 판정 흐름

| 유닛 | 종족 | 직업 | 1순위 시도 | 결과 | 2순위 |
|------|------|------|------------|------|-------|
| 인간 전사 | human | warrior | 병영 | ✓ 성공 | - |
| 인간 마법사 | human | mage | 마법사탑 | ✓ 성공 | - |
| 슬라임 마법사 | slime | mage | 마법사탑 | ✓ 성공 | 슬라임 소굴 |
| 슬라임 전사 | slime | warrior | 병영 | ✗ humanoid만 | 슬라임 소굴 ✓ |
| 언데드 암살자 | undead | rogue | 암살자 길드 | ✗ humanoid만 | 묘지 ✓ |
| 언데드 마법사 | undead | mage | 마법사탑 | ✓ 성공 | 묘지 |
| 데몬 성직자 | demon | priest | 신전 | ✗ demon 금지 | 마족 제단 ✓ |

> 상세 건물 정보는 [ECONOMY_SYSTEM.md](./ECONOMY_SYSTEM.md) 참조

### 2.6 유닛 주둔 관리

```gml
/// @function get_available_buildings(unit)
/// @description 유닛이 배치 가능한 건물 목록 반환 (우선순위 순)
function get_available_buildings(unit) {
    var result = [];

    // 1순위: 직업 건물 체크
    for (var i = 0; i < array_length(global.job_buildings); i++) {
        var building = global.job_buildings[i];
        var template = get_building_template(building.building_id);

        if (unit_matches_class(unit, template.allowed_classes) &&
            !unit_blocked_by_race(unit, template.forbidden_races) &&
            unit_matches_race_type(unit, template.allowed_race_types)) {
            array_push(result, { building: building, priority: 1, type: "job" });
        }
    }

    // 2순위: 종족 건물 체크
    for (var i = 0; i < array_length(global.race_buildings); i++) {
        var building = global.race_buildings[i];
        var template = get_building_template(building.building_id);

        if (unit.race == template.required_race) {
            array_push(result, { building: building, priority: 2, type: "race" });
        }
    }

    // 우선순위 정렬
    array_sort(result, function(a, b) { return a.priority - b.priority; });

    return result;
}

/// @function unit_assign_to_building(unit, building)
function unit_assign_to_building(unit, building) {
    var template = get_building_template(building.building_id);

    // 슬롯 확인
    var current_count = array_length(building.stationed_units);
    var max_slots = template.garrison.slots +
                   (building.level - 1) * template.garrison.slots_per_level;

    if (current_count >= max_slots) {
        return { success: false, reason: "building_full" };
    }

    // 직업/종족 확인
    if (!unit_can_enter_building(unit, template)) {
        return { success: false, reason: "unit_not_allowed" };
    }

    // 기존 건물에서 제거
    if (unit.assigned_building != undefined) {
        unit_remove_from_building(unit);
    }

    // 새 건물에 배치
    array_push(building.stationed_units, unit);
    unit.assigned_building = building;

    return { success: true };
}

/// @function unit_can_enter_building(unit, building_template)
function unit_can_enter_building(unit, template) {
    // 종족 건물인 경우
    if (template.building_type == "race") {
        return unit.race == template.required_race;
    }

    // 직업 건물인 경우
    // 1. 금지 종족 확인
    if (array_contains(template.forbidden_races, unit.race)) {
        return false;
    }

    // 2. 허용 종족 타입 확인 (humanoid, holy 친화 등)
    if (array_length(template.allowed_race_types) > 0) {
        if (!unit_matches_race_type(unit, template.allowed_race_types)) {
            return false;
        }
    }

    // 3. 허용 직업 확인
    return unit_matches_class(unit, template.allowed_classes);
}

/// @function unit_matches_class(unit, allowed_classes)
function unit_matches_class(unit, allowed_classes) {
    // 단일 직업
    if (is_string(unit.class)) {
        return array_contains(allowed_classes, unit.class);
    }
    // 복합 직업 (배열)
    for (var i = 0; i < array_length(unit.class); i++) {
        if (array_contains(allowed_classes, unit.class[i])) {
            return true;
        }
    }
    return false;
}
```

---

## 3. 출전 위치 시스템

> 유닛마다 개별적으로 출전 위치 설정 가능

### 3.1 출전 위치 맵

```
                        [ 몬스터 웨이브 → ]

     ┌─────────┐    ┌─────────┐    ┌─────────┐
     │ 전열    │    │ 전열    │    │ 전열    │
     │ 좌측 FL │    │ 중앙 FC │    │ 우측 FR │
     └─────────┘    └─────────┘    └─────────┘

     ┌─────────┐    ┌─────────┐    ┌─────────┐
     │ 후열    │    │ 후열    │    │ 후열    │
     │ 좌측 BL │    │ 중앙 BC │    │ 우측 BR │
     └─────────┘    └─────────┘    └─────────┘

══════════════════════════════════════════════════════
     ┌─────┐      ┌────┬────┐      ┌─────┐
     │ WL  │      │ WC │ WC │      │ WR  │
     └─────┘      └────┴────┘      └─────┘
════════════════════╣ 성문 ╠════════════════════
```

### 3.2 위치 코드 정의

```gml
enum DEPLOY_POSITION {
    FL,     // Front Left - 전열 좌측
    FC,     // Front Center - 전열 중앙
    FR,     // Front Right - 전열 우측
    BL,     // Back Left - 후열 좌측
    BC,     // Back Center - 후열 중앙
    BR,     // Back Right - 후열 우측
    WL,     // Wall Left - 성벽 좌측
    WC,     // Wall Center - 성벽 중앙 (성문 양옆)
    WR      // Wall Right - 성벽 우측
}
```

### 3.3 전열 (Front Line) 특성

| 위치 | 코드 | 피격 우선도 | 공격 보너스 | 방어 보너스 | 특수 효과 |
|------|------|-------------|-------------|-------------|-----------|
| 전열 좌측 | FL | 30% | - | - | 좌측 접근 적 우선 교전. 측면 피격 시 회피 -10% |
| 전열 중앙 | FC | 50% | - | 방어력 +10 | 최우선 타겟. 탱커 최적. 도발 효과 유사 |
| 전열 우측 | FR | 20% | 공격력 +5% | - | 우측 접근 적 우선 교전. 측면 기습 담당 |

**공통 특성**:
- 적과 직접 근접 교전
- 후열/성벽 유닛 보호
- 전열 전멸 시 후열이 타겟팅됨
- 근접 공격 유닛 배치 권장

### 3.4 후열 (Back Line) 특성

| 위치 | 코드 | 피격 우선도 | 공격 보너스 | 방어 보너스 | 특수 효과 |
|------|------|-------------|-------------|-------------|-----------|
| 후열 좌측 | BL | 0% (전열 생존 시) | 스킬 범위 +10% | - | FL 유닛에게 버프/힐 우선. 서포터 위치 |
| 후열 중앙 | BC | 0% (전열 생존 시) | 스킬 위력 +5% | 받는 피해 -10% | 가장 안전. 핵심 딜러/힐러 배치 |
| 후열 우측 | BR | 0% (전열 생존 시) | 공격속도 +5% | - | FR 유닛에게 버프/힐 우선. 딜러 위치 |

**공통 특성**:
- 전열 1명 이상 생존 시 일반 타겟팅 안됨
- 암살자/돌진 유닛은 후열 직접 타겟 가능
- 원거리/마법 공격 유닛 배치 권장

### 3.5 성벽 (Wall) 특성

| 위치 | 코드 | 피격 우선도 | 공격 보너스 | 방어 보너스 | 특수 효과 |
|------|------|-------------|-------------|-------------|-----------|
| 성벽 좌측 | WL | 5% | 사거리 +100 | 회피 +25% | 좌측 적 우선 공격. FL 엄호 사격 |
| 성벽 중앙 | WC | 5% | 사거리 +150, 공격력 +10% | 회피 +30% | 성문 양옆 2칸. 최고 시야. 어느 방향이든 공격 |
| 성벽 우측 | WR | 5% | 사거리 +100 | 회피 +25% | 우측 적 우선 공격. FR 엄호 사격 |

**공통 특성**:
- 고지대 보너스: 사거리 대폭 증가
- 엄폐 보너스: 회피율 증가
- 비행 유닛만 직접 공격 가능
- 근접 유닛 배치 불가 (공격 불가)
- 성벽 파괴 시 낙하 (데미지 + 스턴 1초)

### 3.6 위치 상호작용

| 상황 | 효과 |
|------|------|
| 전열 전멸 | 후열 → 새 전열 (타겟 우선도 상승) |
| 후열 전멸 | 성벽만 생존. 적이 성문 공격 시작 |
| 성벽만 생존 | 성문 HP 0 → 게임 오버 |
| 같은 열 인접 | 연계: 상호 받는 피해 -5% |
| 힐러 → 같은 열 | 힐 효율 +20% |
| 힐러 → 다른 열 | 힐 효율 기본 |
| 버퍼 → 같은 열 | 버프 효과 +10% |
| 탱커 FC 배치 | "수호자": 인접 유닛 대신 피격 30% |

### 3.7 적 타겟팅 AI

| 우선순위 | 대상 | 조건 |
|----------|------|------|
| 1 | 도발 유닛 | Taunt 상태 시 무조건 |
| 2 | 전열 중앙 (FC) | 50% 확률 |
| 3 | 전열 좌/우 (FL/FR) | 접근 방향 기준 |
| 4 | 후열 | 전열 전멸 또는 암살자/비행 |
| 5 | 성벽 | 비행 유닛 또는 성문 파괴 후 |

**예외**:
- 암살자 몬스터: BC 우선
- 비행 몬스터: 성벽 타겟 가능
- 보스: 가장 가까운 유닛

### 3.8 출전 스타일

| 스타일 | 설명 | 효과 | 추천 유닛 |
|--------|------|------|-----------|
| `walk` | 일반 걸어서 출전 | 기본 | 대부분 |
| `charge` | 돌진 출전 | 이동속도 2배, 첫공격 +50% | 야수, 전사 |
| `stealth` | 은신 출전 | 2초간 은신 | 암살자 |
| `rise` | 땅에서 솟아오름 | 주변 적 30% 공포 (1초) | 언데드 |
| `teleport` | 순간이동 출전 | 즉시 위치 도착 | 마법사 |
| `fly` | 비행 출전 | 장애물 무시 | 비행유닛 |

### 3.9 출전 프로세스

```gml
/// @function battle_deploy_all_units()
/// @description 전투 시작 시 모든 주둔 유닛 출전
function battle_deploy_all_units() {
    var deploy_queue = [];

    // 1. 모든 전투 건물에서 유닛 수집
    for (var i = 0; i < array_length(global.player_buildings); i++) {
        var building = global.player_buildings[i];
        var template = get_building_template(building.building_id);

        if (!template.garrison.deploy_to_battle) continue;

        for (var j = 0; j < array_length(building.stationed_units); j++) {
            var unit = building.stationed_units[j];

            array_push(deploy_queue, {
                unit: unit,
                building: building,
                position: unit.deploy_position,
                delay: template.garrison.deploy_delay + unit.deploy_options.delay,
                entry_style: unit.deploy_options.entry_style,
                buffs: calculate_garrison_buffs(template, building.level)
            });
        }
    }

    // 2. 딜레이순 정렬
    array_sort(deploy_queue, function(a, b) {
        return a.delay - b.delay;
    });

    // 3. 순차 출전
    for (var i = 0; i < array_length(deploy_queue); i++) {
        schedule_unit_deploy(deploy_queue[i]);
    }
}

/// @function get_deploy_world_position(position_code)
function get_deploy_world_position(position_code) {
    var gate = global.castle_gate_position;

    switch (position_code) {
        case "FL": return { x: gate.x + 120, y: gate.y - 80 };
        case "FC": return { x: gate.x + 150, y: gate.y };
        case "FR": return { x: gate.x + 120, y: gate.y + 80 };
        case "BL": return { x: gate.x + 50, y: gate.y - 80 };
        case "BC": return { x: gate.x + 80, y: gate.y };
        case "BR": return { x: gate.x + 50, y: gate.y + 80 };
        case "WL": return { x: gate.x - 20, y: gate.y - 120 };
        case "WC": return { x: gate.x - 20, y: gate.y };
        case "WR": return { x: gate.x - 20, y: gate.y + 120 };
    }
}
```

---

## 4. 유닛 AI 시스템

### 4.1 AI 설계 원칙

> **적 AI는 단순, 아군 AI는 복잡** - 플레이어가 전술로 이길 수 있도록

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         AI 복잡도 분리                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   적 AI (Enemy)                    아군 AI (Ally)                       │
│   ┌───────────────┐                ┌───────────────┐                   │
│   │  • 단순 패턴   │                │  • 역할별 행동  │                   │
│   │  • 예측 가능   │                │  • 상태 기반    │                   │
│   │  • 3가지 타입  │                │  • 7가지 역할   │                   │
│   └───────────────┘                └───────────────┘                   │
│                                                                         │
│   목적: 플레이어가 패턴 파악        목적: 유닛 배치의 전략적 의미         │
│         → 전술로 극복 가능                 → 역할 조합이 중요             │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

### 4.2 적 AI (단순)

> 적은 3가지 AI 타입만 사용. 플레이어가 패턴을 읽고 대응할 수 있어야 함.

#### 적 AI 타입 요약

| AI 타입 | 설명 | 행동 패턴 | 대응 전략 |
|---------|------|----------|-----------|
| `ai_rush` | 돌진형 | 가장 가까운 적에게 돌진 | 탱커로 유인 |
| `ai_ranged` | 원거리형 | 거리 유지, 사거리 내 공격 | 암살자로 침투 |
| `ai_boss` | 보스형 | 페이즈별 패턴 | 패턴 숙지 필수 |

#### 4.2.1 돌진형 (ai_rush)

```gml
/// @function enemy_ai_rush(unit)
/// @description 가장 단순한 적 AI - 무조건 가장 가까운 대상 공격
function enemy_ai_rush(unit) {
    // 1. 도발 상태면 도발자 공격
    var taunter = get_taunting_unit(unit);
    if (taunter != undefined) {
        unit.target = taunter;
        move_toward_target(unit);
        if (in_attack_range(unit, taunter)) {
            attack_target(unit, taunter);
        }
        return;
    }

    // 2. 가장 가까운 적 찾기
    var nearest = find_nearest_enemy(unit);
    if (nearest == undefined) return;

    unit.target = nearest;

    // 3. 이동 → 공격
    if (in_attack_range(unit, nearest)) {
        attack_target(unit, nearest);
    } else {
        move_toward_target(unit);
    }
}

// 적용 대상: 좀비, 고블린, 오크 전사, 늑대 등
```

**특징**:
- 타겟 우선순위 계산 없음
- 거리만 계산
- 플레이어는 탱커 배치로 쉽게 유인 가능

#### 4.2.2 원거리형 (ai_ranged)

```gml
/// @function enemy_ai_ranged(unit)
/// @description 거리 유지하며 원거리 공격
function enemy_ai_ranged(unit) {
    // 1. 도발 상태 체크
    var taunter = get_taunting_unit(unit);
    if (taunter != undefined) {
        unit.target = taunter;
        // 도발 당해도 사거리 유지 시도
        if (distance_to(unit, taunter) < unit.preferred_range * 0.5) {
            move_away_from(unit, taunter);
        } else if (in_attack_range(unit, taunter)) {
            attack_target(unit, taunter);
        }
        return;
    }

    // 2. 적이 너무 가까우면 후퇴
    var nearest_threat = find_nearest_enemy(unit);
    if (nearest_threat != undefined) {
        var dist = distance_to(unit, nearest_threat);

        if (dist < unit.preferred_range * 0.5) {
            // 거리가 너무 가까움 → 후퇴
            move_away_from(unit, nearest_threat);
            return;
        }
    }

    // 3. 사거리 내 아무나 공격
    var target = find_enemy_in_range(unit);
    if (target != undefined) {
        attack_target(unit, target);
    } else {
        // 사거리 내 적 없음 → 접근
        if (nearest_threat != undefined) {
            move_toward_unit(unit, nearest_threat);
        }
    }
}

// 적용 대상: 고블린 궁수, 해골 마법사, 임프 등
```

**특징**:
- 선호 거리(preferred_range) 유지
- 근접 당하면 후퇴
- 플레이어는 암살자나 돌진기로 무력화 가능

#### 4.2.3 보스형 (ai_boss)

```gml
/// @function enemy_ai_boss(unit)
/// @description 페이즈 기반 보스 AI
function enemy_ai_boss(unit) {
    var hp_percent = unit.hp / unit.max_hp * 100;

    // 페이즈 전환 체크
    if (hp_percent <= 30 && unit.boss_phase < 3) {
        unit.boss_phase = 3;
        boss_enter_phase(unit, 3);
        return;
    } else if (hp_percent <= 60 && unit.boss_phase < 2) {
        unit.boss_phase = 2;
        boss_enter_phase(unit, 2);
        return;
    }

    // 현재 페이즈 행동
    switch (unit.boss_phase) {
        case 1:     // 100% ~ 61%
            boss_phase1_behavior(unit);
            break;
        case 2:     // 60% ~ 31%
            boss_phase2_behavior(unit);
            break;
        case 3:     // 30% ~ 0%
            boss_phase3_behavior(unit);
            break;
    }
}

/// @function boss_phase1_behavior(unit)
function boss_phase1_behavior(unit) {
    // 일반 공격 패턴
    var target = find_highest_threat_target(unit);
    if (target == undefined) target = find_nearest_enemy(unit);

    if (unit.skill_cooldown <= 0) {
        // 스킬 사용 (10초마다)
        use_boss_skill(unit, "skill_slam");
        unit.skill_cooldown = 10;
    } else {
        attack_target(unit, target);
    }
}

/// @function boss_phase2_behavior(unit)
function boss_phase2_behavior(unit) {
    // 광폭화 - 공격 속도 증가, 범위 공격 추가
    if (unit.skill_cooldown <= 0) {
        use_boss_skill(unit, "skill_aoe_slam");
        unit.skill_cooldown = 7;
    } else {
        // 가장 가까운 2명 동시 공격
        var targets = find_nearest_enemies(unit, 2);
        for (var i = 0; i < array_length(targets); i++) {
            attack_target(unit, targets[i]);
        }
    }
}

/// @function boss_phase3_behavior(unit)
function boss_phase3_behavior(unit) {
    // 최후의 발악 - 패턴 강화
    if (unit.skill_cooldown <= 0) {
        // 전체 공격
        use_boss_skill(unit, "skill_ultimate_slam");
        unit.skill_cooldown = 15;
    } else {
        // 가장 체력 낮은 적 집중
        var target = find_lowest_hp_enemy(unit);
        attack_target(unit, target);
        attack_target(unit, target);  // 2연타
    }
}

// 적용 대상: 보스 몬스터
```

**특징**:
- HP에 따른 페이즈 전환
- 각 페이즈마다 명확한 패턴
- 플레이어는 패턴 숙지로 대응 (페이즈 전환 시 회피 등)

---

### 4.3 아군 AI (복잡)

> 아군은 역할(Role)에 따라 복잡한 판단 수행. 플레이어의 배치 전략이 중요해짐.

#### 아군 AI 역할 요약

| AI 역할 | 주요 행동 | 위치 | 특징 |
|---------|----------|------|------|
| `ai_tank` | 도발, 아군 보호 | 전열 | 적 어그로 집중 |
| `ai_healer` | 치유, 해제 | 후열 | 낮은 HP 아군 우선 |
| `ai_ranged_dps` | 원거리 딜링 | 후열 | 낮은 HP 적 우선 |
| `ai_melee_dps` | 근접 딜링 | 전열/측면 | 적진 돌입 |
| `ai_assassin` | 후열 침투 | 측면 | 힐러/원딜 암살 |
| `ai_support` | 버프/디버프 | 중열 | 아군 강화, 적 약화 |
| `ai_summoner` | 소환수 관리 | 후열 | 소환물 유지 |

#### 4.3.1 상태 기반 아군 AI 구조

```gml
/// @function ally_ai_update(unit)
/// @description 아군 AI 메인 업데이트 - 상태 기반
function ally_ai_update(unit) {
    // 1. 현재 상태 평가
    var state = evaluate_combat_state(unit);

    // 2. 상태에 따른 행동 분기
    switch (state) {
        case "critical":        // HP 20% 이하
            ally_ai_critical_state(unit);
            break;
        case "danger":          // HP 50% 이하
            ally_ai_danger_state(unit);
            break;
        case "normal":          // HP 50% 이상
            ally_ai_normal_state(unit);
            break;
        case "advantaged":      // 적이 열세
            ally_ai_advantaged_state(unit);
            break;
    }
}

/// @function evaluate_combat_state(unit)
function evaluate_combat_state(unit) {
    var hp_percent = unit.hp / unit.max_hp * 100;
    var ally_count = count_alive_allies();
    var enemy_count = count_alive_enemies();

    if (hp_percent <= 20) return "critical";
    if (hp_percent <= 50) return "danger";
    if (enemy_count <= ally_count * 0.3) return "advantaged";
    return "normal";
}
```

#### 4.3.2 탱커 AI (ai_tank)

```gml
ai_tank = {
    role: "tank",

    /// @function update
    update: function(unit) {
        var state = evaluate_combat_state(unit);

        // 위급 상태: 방어 스킬 우선
        if (state == "critical" || state == "danger") {
            if (try_use_skill(unit, "defensive")) return;
        }

        // 도발이 필요한 상황 체크
        if (should_taunt(unit)) {
            if (try_use_skill(unit, "taunt")) return;
        }

        // 아군 보호 체크
        var endangered_ally = find_endangered_ally(unit);
        if (endangered_ally != undefined) {
            // 아군을 공격 중인 적 저지
            var attacker = get_unit_targeting(endangered_ally);
            if (attacker != undefined) {
                unit.target = attacker;
                move_to_intercept(unit, attacker);
                if (in_attack_range(unit, attacker)) {
                    attack_target(unit, attacker);
                }
                return;
            }
        }

        // 기본: 가장 가까운 적 공격 (위치 유지)
        var nearest = find_nearest_enemy(unit);
        if (nearest != undefined && in_attack_range(unit, nearest)) {
            attack_target(unit, nearest);
        }
        // 탱커는 추격하지 않음 (hold_position)
    },

    /// @function should_taunt
    should_taunt: function(unit) {
        // 주변에 적 3마리 이상이면 도발
        var nearby_enemies = count_enemies_in_range(unit, 3);
        if (nearby_enemies >= 3) return true;

        // 아군 힐러가 공격받고 있으면 도발
        var healer = find_ally_by_role("healer");
        if (healer != undefined && is_being_attacked(healer)) {
            return true;
        }

        return false;
    },

    // 설정
    position: { row: "front", hold_position: true, chase_range: 1 }
}
```

#### 4.3.3 힐러 AI (ai_healer)

```gml
ai_healer = {
    role: "healer",

    update: function(unit) {
        // 1순위: 위급한 아군 즉시 치유
        var critical_ally = find_ally_below_hp_percent(30);
        if (critical_ally != undefined) {
            if (try_use_skill(unit, "heal", critical_ally)) return;
        }

        // 2순위: 위험한 디버프 해제
        var debuffed_ally = find_ally_with_dangerous_debuff();
        if (debuffed_ally != undefined) {
            if (try_use_skill(unit, "cleanse", debuffed_ally)) return;
        }

        // 3순위: 일반 치유 (70% 미만)
        var hurt_ally = find_ally_below_hp_percent(70);
        if (hurt_ally != undefined) {
            if (try_use_skill(unit, "heal", hurt_ally)) return;
        }

        // 4순위: 버프 (여유 있을 때)
        if (unit.mana >= unit.max_mana * 0.5) {
            var tank = find_ally_by_role("tank");
            if (tank != undefined && !has_buff(tank, "protection")) {
                if (try_use_skill(unit, "buff", tank)) return;
            }
        }

        // 5순위: 적이 가까우면 도망
        var nearest_enemy = find_nearest_enemy(unit);
        if (nearest_enemy != undefined) {
            var dist = distance_to(unit, nearest_enemy);
            if (dist < 3) {
                move_away_from(unit, nearest_enemy);
                return;
            }
        }

        // 6순위: 안전하면 공격 (마나 회복용)
        if (nearest_enemy != undefined && in_attack_range(unit, nearest_enemy)) {
            attack_target(unit, nearest_enemy);
        }
    },

    position: { row: "back", hold_position: true, flee_from_enemies: true }
}
```

#### 4.3.4 원거리 딜러 AI (ai_ranged_dps)

```gml
ai_ranged_dps = {
    role: "ranged_dps",

    update: function(unit) {
        // 1순위: 적이 너무 가까우면 후퇴
        var nearest_enemy = find_nearest_enemy(unit);
        if (nearest_enemy != undefined) {
            var dist = distance_to(unit, nearest_enemy);
            if (dist < 2) {
                move_away_from(unit, nearest_enemy);
                return;
            }
        }

        // 2순위: AOE 스킬 (적 3마리 이상 모임)
        var grouped_enemies = find_enemy_group(3, unit.attack_range);
        if (grouped_enemies != undefined) {
            if (try_use_skill(unit, "aoe", grouped_enemies.center)) return;
        }

        // 3순위: 낮은 HP 적 처치 (마무리)
        var low_hp_enemy = find_enemy_below_hp_percent(30);
        if (low_hp_enemy != undefined && in_attack_range(unit, low_hp_enemy)) {
            if (try_use_skill(unit, "damage", low_hp_enemy)) return;
            attack_target(unit, low_hp_enemy);
            return;
        }

        // 4순위: 위협도 높은 적 공격
        var high_threat = find_highest_threat_enemy(unit);
        if (high_threat != undefined && in_attack_range(unit, high_threat)) {
            attack_target(unit, high_threat);
            return;
        }

        // 5순위: 사거리 내 아무 적이나
        var target_in_range = find_enemy_in_range(unit);
        if (target_in_range != undefined) {
            attack_target(unit, target_in_range);
        }
    },

    position: { row: "back", hold_position: true, retreat_threshold: 2 }
}
```

#### 4.3.5 근접 딜러 AI (ai_melee_dps)

```gml
ai_melee_dps = {
    role: "melee_dps",

    update: function(unit) {
        var state = evaluate_combat_state(unit);

        // 위급 상태: 방어적 행동
        if (state == "critical") {
            // 생존기 사용
            if (try_use_skill(unit, "defensive")) return;
            // 후퇴
            move_toward_allies(unit);
            return;
        }

        // 1순위: 처형 (낮은 HP 적)
        var low_hp_enemy = find_enemy_below_hp_percent(20);
        if (low_hp_enemy != undefined) {
            unit.target = low_hp_enemy;
            if (!in_attack_range(unit, low_hp_enemy)) {
                move_toward_target(unit);
            } else {
                if (try_use_skill(unit, "execute", low_hp_enemy)) return;
                attack_target(unit, low_hp_enemy);
            }
            return;
        }

        // 2순위: AOE 기회
        var grouped_enemies = find_enemy_group(3, 2);
        if (grouped_enemies != undefined) {
            move_to_position(unit, grouped_enemies.center);
            if (try_use_skill(unit, "aoe")) return;
        }

        // 3순위: 현재 타겟 계속 공격
        if (unit.target != undefined && is_alive(unit.target)) {
            if (in_attack_range(unit, unit.target)) {
                attack_target(unit, unit.target);
            } else {
                move_toward_target(unit);
            }
            return;
        }

        // 4순위: 새 타겟 선정 - 탱커가 잡고 있는 적
        var tank = find_ally_by_role("tank");
        if (tank != undefined && tank.target != undefined) {
            unit.target = tank.target;
            move_toward_target(unit);
            return;
        }

        // 5순위: 가장 가까운 적
        var nearest = find_nearest_enemy(unit);
        if (nearest != undefined) {
            unit.target = nearest;
            move_toward_target(unit);
        }
    },

    position: { row: "front", hold_position: false, chase_range: 5 }
}
```

#### 4.3.6 암살자 AI (ai_assassin)

```gml
ai_assassin = {
    role: "assassin",

    update: function(unit) {
        // 위급 시 후퇴 + 은신
        if (unit.hp / unit.max_hp < 0.4) {
            if (try_use_skill(unit, "stealth")) return;
            move_toward_allies(unit);
            return;
        }

        // 은신 상태 행동
        if (has_buff(unit, "stealth")) {
            // 은신 중: 고가치 타겟 접근
            var priority_target = find_priority_target(unit);
            if (priority_target != undefined) {
                if (is_behind_target(unit, priority_target)) {
                    // 백스탭!
                    if (try_use_skill(unit, "backstab", priority_target)) return;
                } else {
                    // 뒤로 이동
                    move_to_behind(unit, priority_target);
                }
            }
            return;
        }

        // 일반 상태 행동
        // 1순위: 은신 가능하면 은신
        if (can_use_skill(unit, "stealth") && !is_in_combat(unit)) {
            try_use_skill(unit, "stealth");
            return;
        }

        // 2순위: 처형 (20% 이하 적)
        var low_hp = find_enemy_below_hp_percent(20);
        if (low_hp != undefined) {
            unit.target = low_hp;
            if (in_attack_range(unit, low_hp)) {
                if (try_use_skill(unit, "execute", low_hp)) return;
                attack_target(unit, low_hp);
            } else {
                move_toward_target(unit);
            }
            return;
        }

        // 3순위: 고가치 타겟 (힐러 > 원거리 딜러)
        var priority = find_priority_target(unit);
        if (priority != undefined) {
            unit.target = priority;
            if (in_attack_range(unit, priority)) {
                attack_target(unit, priority);
            } else {
                move_toward_target(unit);
            }
            return;
        }

        // 4순위: 아무 적이나
        var nearest = find_nearest_enemy(unit);
        if (nearest != undefined) {
            unit.target = nearest;
            move_toward_target(unit);
        }
    },

    /// @function find_priority_target
    find_priority_target: function(unit) {
        // 우선순위: 힐러 > 원거리 딜러 > 마법사 > 기타
        var targets = get_all_enemies();
        var best = undefined;
        var best_priority = 0;

        for (var i = 0; i < array_length(targets); i++) {
            var t = targets[i];
            var priority = 0;

            if (t.combat.function == "healer") priority = 100;
            else if (t.combat.range == "ranged" && t.combat.function == "damage") priority = 90;
            else if (t.class == "mage") priority = 80;

            // 낮은 HP 보너스
            priority += (100 - (t.hp / t.max_hp * 100)) * 0.5;

            if (priority > best_priority) {
                best_priority = priority;
                best = t;
            }
        }

        return best;
    },

    position: { row: "flank", hold_position: false, chase_range: 99 }
}
```

#### 4.3.7 서포터 AI (ai_support)

```gml
ai_support = {
    role: "support",

    update: function(unit) {
        // 1순위: 딜러에게 공격 버프
        var dps = find_ally_by_role("ranged_dps");
        if (dps == undefined) dps = find_ally_by_role("melee_dps");

        if (dps != undefined && !has_buff(dps, "attack_up")) {
            if (try_use_skill(unit, "attack_buff", dps)) return;
        }

        // 2순위: 공격받는 아군 보호막
        var attacked_ally = find_ally_being_attacked();
        if (attacked_ally != undefined) {
            if (try_use_skill(unit, "shield", attacked_ally)) return;
        }

        // 3순위: 위험한 적 디버프
        var priority_enemy = find_highest_threat_enemy(unit);
        if (priority_enemy != undefined && !has_debuff(priority_enemy, "weakened")) {
            if (try_use_skill(unit, "debuff", priority_enemy)) return;
        }

        // 4순위: 탱커 방어 버프
        var tank = find_ally_by_role("tank");
        if (tank != undefined && !has_buff(tank, "defense_up")) {
            if (try_use_skill(unit, "defense_buff", tank)) return;
        }

        // 5순위: 안전하면 공격
        var nearest = find_nearest_enemy(unit);
        if (nearest != undefined && in_attack_range(unit, nearest)) {
            if (distance_to(unit, nearest) > 3) {
                attack_target(unit, nearest);
            }
        }
    },

    position: { row: "mid", hold_position: true }
}
```

#### 4.3.8 소환사 AI (ai_summoner)

```gml
ai_summoner = {
    role: "summoner",

    update: function(unit) {
        var summon_count = array_length(unit.summoned_units);
        var max_summons = unit.max_summons ?? 3;

        // 1순위: 소환수 부족하면 소환
        if (summon_count < max_summons) {
            if (try_use_skill(unit, "summon")) return;
        }

        // 2순위: 소환수 버프
        if (summon_count > 0) {
            var unbuffed_summon = find_unbuffed_summon(unit);
            if (unbuffed_summon != undefined) {
                if (try_use_skill(unit, "summon_buff", unbuffed_summon)) return;
            }
        }

        // 3순위: 소환수 명령 (타겟 지정)
        if (summon_count > 0) {
            var priority_enemy = find_highest_threat_enemy(unit);
            if (priority_enemy != undefined) {
                command_summons_attack(unit, priority_enemy);
            }
        }

        // 4순위: 적 접근 시 후퇴
        var nearest = find_nearest_enemy(unit);
        if (nearest != undefined && distance_to(unit, nearest) < 3) {
            move_away_from(unit, nearest);
            return;
        }

        // 5순위: 기본 공격
        if (nearest != undefined && in_attack_range(unit, nearest)) {
            attack_target(unit, nearest);
        }
    },

    position: { row: "back", hold_position: true }
}
```

---

### 4.4 타겟 선정 시스템

> 아군 AI가 타겟을 선정할 때 사용하는 가중치 시스템

```gml
/// @function select_target(unit, priorities)
/// @description 가중치 기반 타겟 선정
function select_target(unit, priorities) {
    var candidates = get_valid_targets(unit);
    var best_target = undefined;
    var best_score = -999;

    for (var i = 0; i < array_length(candidates); i++) {
        var candidate = candidates[i];
        var score = 0;

        for (var j = 0; j < array_length(priorities); j++) {
            var p = priorities[j];
            score += evaluate_priority(unit, candidate, p);
        }

        if (score > best_score) {
            best_score = score;
            best_target = candidate;
        }
    }

    return best_target;
}

/// @function evaluate_priority
function evaluate_priority(unit, target, priority) {
    switch (priority.filter) {
        case "lowest_hp":
            return (100 - (target.hp / target.max_hp * 100)) * priority.weight / 100;

        case "highest_threat":
            var threat = unit.threat_table[$ target.id] ?? 0;
            return min(threat / 10, 100) * priority.weight / 100;

        case "nearest":
            var dist = distance_to(unit, target);
            return max(0, (10 - dist) * 10) * priority.weight / 100;

        case "role_healer":
            return (target.combat.function == "healer") ? priority.weight : 0;

        case "role_ranged_dps":
            return (target.combat.range == "ranged" && target.combat.function == "damage") ? priority.weight : 0;

        case "targeting_ally":
            var allies = get_all_allies(unit);
            for (var i = 0; i < array_length(allies); i++) {
                if (target.target == allies[i]) return priority.weight;
            }
            return 0;
    }

    return 0;
}
```

**역할별 타겟 우선순위**:

| 역할 | 우선순위 1 | 우선순위 2 | 우선순위 3 |
|------|-----------|-----------|-----------|
| 탱커 | 아군 공격 중인 적 (100) | 가장 가까운 적 (50) | - |
| 힐러 | 가장 낮은 HP 아군 (100) | 디버프 있는 아군 (80) | 탱커 (60) |
| 원거리 딜러 | 낮은 HP 적 (80) | 높은 위협 적 (60) | 가까운 적 (40) |
| 암살자 | 힐러 (100) | 원거리 딜러 (90) | 낮은 HP (70) |

---

### 4.5 스킬 사용 판단

> 스킬에 AI 힌트를 추가하여 상황별 사용 조건 정의

```gml
// 스킬에 AI 힌트 추가
skill_ai_hints = {
    skill_fireball: {
        ai_hints: {
            use_when: "enemies_grouped",
            min_targets: 2,
            priority: 80,
            save_for_wave: false
        }
    },

    skill_mass_heal: {
        ai_hints: {
            use_when: "allies_damaged",
            min_allies_hurt: 3,
            ally_hp_threshold: 60,
            priority: 100,
            save_for_emergency: true
        }
    },

    skill_ultimate: {
        ai_hints: {
            use_when: "boss_present",
            save_for_wave: true,
            priority: 50
        }
    },

    skill_taunt: {
        ai_hints: {
            use_when: "enemies_nearby",
            min_enemies: 2,
            priority: 90,
            use_when_ally_endangered: true
        }
    }
}

/// @function should_use_skill(unit, skill, context)
function should_use_skill(unit, skill, context) {
    var hints = skill.ai_hints;
    if (hints == undefined) return true;  // 힌트 없으면 항상 사용

    switch (hints.use_when) {
        case "enemies_grouped":
            var grouped = count_enemies_in_radius(context.target_pos, skill.radius);
            return grouped >= hints.min_targets;

        case "allies_damaged":
            var hurt_allies = count_allies_below_hp(hints.ally_hp_threshold);
            return hurt_allies >= hints.min_allies_hurt;

        case "boss_present":
            return is_boss_in_battle();

        case "enemies_nearby":
            var nearby = count_enemies_in_range(unit, 3);
            return nearby >= hints.min_enemies;
    }

    return true;
}
```

---

### 4.6 위협도(Threat) 시스템

> 적이 아군을 타겟팅할 때 사용하는 시스템

```gml
threat_system = {
    base_threat: 100,

    modifiers: {
        dealing_damage: 1.0,        // 데미지 1당 위협도 1
        healing: 2.0,               // 힐 1당 위협도 2
        taunted: 9999,              // 도발 시 고정
        stealth: 0,                 // 은신 시 위협도 0
        tank_role: 1.5              // 탱커 역할 보너스
    },

    decay_rate: 10                  // 초당 위협도 감소
}

/// @function update_threat(source, target, amount, action_type)
function update_threat(source, target, amount, action_type) {
    var modifier = 1.0;

    switch (action_type) {
        case "damage":
            modifier = threat_system.modifiers.dealing_damage;
            break;
        case "healing":
            modifier = threat_system.modifiers.healing;
            break;
        case "taunt":
            target.threat_table[$ source.id] = threat_system.modifiers.taunted;
            return;
    }

    // 역할 보너스
    if (source.combat.function == "tank") {
        modifier *= threat_system.modifiers.tank_role;
    }

    var current = target.threat_table[$ source.id] ?? threat_system.base_threat;
    target.threat_table[$ source.id] = current + (amount * modifier);
}

/// @function decay_threat(unit, delta_time)
function decay_threat(unit, delta_time) {
    var keys = variable_struct_get_names(unit.threat_table);
    for (var i = 0; i < array_length(keys); i++) {
        var key = keys[i];
        unit.threat_table[$ key] -= threat_system.decay_rate * delta_time;
        if (unit.threat_table[$ key] <= 0) {
            variable_struct_remove(unit.threat_table, key);
        }
    }
}
```

---

### 4.7 포지셔닝 AI

> 유닛의 위치 유지 및 이동 판단

```gml
/// @function update_positioning(unit)
function update_positioning(unit) {
    var ai = get_ai_config(unit);

    // 위치 고정 설정
    if (ai.position.hold_position) {
        var ideal_pos = get_formation_position(unit, ai.position.row);
        var dist_from_ideal = distance_to_point(unit.x, unit.y, ideal_pos.x, ideal_pos.y);

        // 너무 멀리 벗어났으면 복귀
        if (dist_from_ideal > 3 && !is_in_combat(unit)) {
            move_to_position(unit, ideal_pos);
            return true;
        }
    }

    // 도망 설정 (힐러 등)
    if (ai.position.flee_from_enemies) {
        var nearest = find_nearest_enemy(unit);
        if (nearest != undefined && distance_to(unit, nearest) < 2) {
            move_away_from(unit, nearest);
            return true;
        }
    }

    // 추격 범위 체크
    if (unit.target != undefined && !ai.position.hold_position) {
        var dist_to_target = distance_to(unit, unit.target);
        if (dist_to_target > ai.position.chase_range) {
            // 추격 범위 초과 - 타겟 포기
            unit.target = undefined;
        }
    }

    return false;
}

/// @function get_formation_position(unit, row)
function get_formation_position(unit, row) {
    var base = global.formation_center;

    switch (row) {
        case "front":
            return { x: base.x + 100, y: base.y + unit.formation_offset_y };
        case "mid":
            return { x: base.x + 50, y: base.y + unit.formation_offset_y };
        case "back":
            return { x: base.x, y: base.y + unit.formation_offset_y };
        case "flank":
            // 측면은 적 후방으로
            return { x: base.x + 150, y: base.y + (unit.formation_offset_y > 0 ? 100 : -100) };
    }

    return base;
}
```

---

### 4.8 길찾기 및 이동 시스템

> 수성전 스타일: 아군/적 모두 이동하며 전투, 전선이 밀고 밀리는 동적 전투

#### 시스템 개요

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         이동 시스템 구조                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                │
│   │ Spatial Grid│───►│ A* 길찾기   │───►│ Steering    │                │
│   │ (유닛 탐지) │    │ (경로 계산) │    │ (부드러운   │                │
│   └─────────────┘    └─────────────┘    │  이동+회피) │                │
│         │                  │            └─────────────┘                │
│         ▼                  ▼                   │                       │
│   ┌─────────────┐    ┌─────────────┐          ▼                       │
│   │ 전선 인식   │    │ 진형 유지   │    ┌─────────────┐                │
│   │ (Front Line)│    │ (Formation) │    │ 최종 위치   │                │
│   └─────────────┘    └─────────────┘    └─────────────┘                │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

#### 4.8.1 Spatial Grid (공간 분할)

> 유닛 탐지 최적화 - O(n²) → O(1) 근처 유닛 검색

```gml
/// Spatial Grid 구조
global.spatial_grid = {
    cell_size: 64,              // 타일 크기와 동일 권장
    cells: {},                  // { "x_y": [unit_ids...] }

    // 설정
    update_frequency: 3         // 3프레임마다 업데이트
}

/// @function spatial_grid_init()
function spatial_grid_init() {
    global.spatial_grid.cells = {};
}

/// @function spatial_grid_update()
/// @description 모든 유닛의 그리드 위치 갱신
function spatial_grid_update() {
    global.spatial_grid.cells = {};

    var all_units = array_concat(global.battle_state.allies, global.battle_state.enemies);

    for (var i = 0; i < array_length(all_units); i++) {
        var unit = all_units[i];
        var cell_x = floor(unit.x / global.spatial_grid.cell_size);
        var cell_y = floor(unit.y / global.spatial_grid.cell_size);
        var key = string(cell_x) + "_" + string(cell_y);

        if (!variable_struct_exists(global.spatial_grid.cells, key)) {
            global.spatial_grid.cells[$ key] = [];
        }
        array_push(global.spatial_grid.cells[$ key], unit);
    }
}

/// @function spatial_query(x, y, radius)
/// @description 특정 위치 주변 유닛 빠르게 검색
function spatial_query(px, py, radius) {
    var result = [];
    var cell_size = global.spatial_grid.cell_size;
    var cell_radius = ceil(radius / cell_size);

    var center_cx = floor(px / cell_size);
    var center_cy = floor(py / cell_size);

    // 주변 셀만 검색
    for (var cx = center_cx - cell_radius; cx <= center_cx + cell_radius; cx++) {
        for (var cy = center_cy - cell_radius; cy <= center_cy + cell_radius; cy++) {
            var key = string(cx) + "_" + string(cy);

            if (variable_struct_exists(global.spatial_grid.cells, key)) {
                var cell_units = global.spatial_grid.cells[$ key];

                for (var i = 0; i < array_length(cell_units); i++) {
                    var unit = cell_units[i];
                    var dist = point_distance(px, py, unit.x, unit.y);

                    if (dist <= radius) {
                        array_push(result, unit);
                    }
                }
            }
        }
    }

    return result;
}

/// @function find_enemies_in_range(unit, range)
function find_enemies_in_range(unit, range) {
    var nearby = spatial_query(unit.x, unit.y, range);
    var enemies = [];

    for (var i = 0; i < array_length(nearby); i++) {
        if (nearby[i].team != unit.team && nearby[i].hp > 0) {
            array_push(enemies, nearby[i]);
        }
    }

    return enemies;
}
```

#### 4.8.2 A* 길찾기

> 8방향 타일 기반 경로 탐색

```gml
/// A* 노드 구조
pathfinding_node = {
    x: 0, y: 0,
    g: 0,                       // 시작점에서 이 노드까지 비용
    h: 0,                       // 이 노드에서 목표까지 추정 비용
    f: 0,                       // g + h
    parent: undefined,
    direction: -1               // 이전 노드에서 온 방향 (방향전환 패널티용)
}

/// @function pathfind_astar(start_x, start_y, goal_x, goal_y, unit)
/// @description A* 경로 탐색 (8방향)
function pathfind_astar(start_x, start_y, goal_x, goal_y, unit) {
    var tile_size = global.tile_size;

    var start_tx = floor(start_x / tile_size);
    var start_ty = floor(start_y / tile_size);
    var goal_tx = floor(goal_x / tile_size);
    var goal_ty = floor(goal_y / tile_size);

    // 이미 목표에 있음
    if (start_tx == goal_tx && start_ty == goal_ty) {
        return [];
    }

    var open_list = ds_priority_create();
    var closed_set = {};
    var node_map = {};

    // 8방향 (dx, dy, cost)
    var directions = [
        { dx: 1, dy: 0, cost: 10 },     // 동
        { dx: -1, dy: 0, cost: 10 },    // 서
        { dx: 0, dy: 1, cost: 10 },     // 남
        { dx: 0, dy: -1, cost: 10 },    // 북
        { dx: 1, dy: 1, cost: 14 },     // 남동
        { dx: -1, dy: 1, cost: 14 },    // 남서
        { dx: 1, dy: -1, cost: 14 },    // 북동
        { dx: -1, dy: -1, cost: 14 }    // 북서
    ];

    // 시작 노드
    var start_node = {
        x: start_tx, y: start_ty,
        g: 0,
        h: heuristic_octile(start_tx, start_ty, goal_tx, goal_ty),
        parent: undefined,
        direction: -1
    };
    start_node.f = start_node.g + start_node.h;

    var start_key = string(start_tx) + "_" + string(start_ty);
    node_map[$ start_key] = start_node;
    ds_priority_add(open_list, start_key, start_node.f);

    while (!ds_priority_empty(open_list)) {
        var current_key = ds_priority_delete_min(open_list);
        var current = node_map[$ current_key];

        // 목표 도달
        if (current.x == goal_tx && current.y == goal_ty) {
            var path = reconstruct_path(current, tile_size);
            ds_priority_destroy(open_list);
            return path;
        }

        closed_set[$ current_key] = true;

        // 이웃 탐색
        for (var i = 0; i < 8; i++) {
            var dir = directions[i];
            var nx = current.x + dir.dx;
            var ny = current.y + dir.dy;
            var neighbor_key = string(nx) + "_" + string(ny);

            // 이미 방문
            if (variable_struct_exists(closed_set, neighbor_key)) continue;

            // 이동 불가 타일
            if (!tile_is_walkable(nx, ny, unit)) continue;

            // 대각선 이동 시 코너 체크
            if (abs(dir.dx) + abs(dir.dy) == 2) {
                if (!tile_is_walkable(current.x + dir.dx, current.y, unit) ||
                    !tile_is_walkable(current.x, current.y + dir.dy, unit)) {
                    continue;  // 코너 막힘
                }
            }

            // 비용 계산
            var move_cost = dir.cost;
            var tile_cost = get_tile_cost(nx, ny);
            move_cost += tile_cost;

            // 방향 전환 패널티 (지그재그 방지)
            if (current.direction != -1 && current.direction != i) {
                move_cost += 2;  // 방향 바꾸면 패널티
            }

            var tentative_g = current.g + move_cost;

            // 기존 노드보다 좋은 경로인가?
            var neighbor = node_map[$ neighbor_key];
            if (neighbor == undefined || tentative_g < neighbor.g) {
                neighbor = {
                    x: nx, y: ny,
                    g: tentative_g,
                    h: heuristic_octile(nx, ny, goal_tx, goal_ty),
                    parent: current,
                    direction: i
                };
                neighbor.f = neighbor.g + neighbor.h;
                node_map[$ neighbor_key] = neighbor;
                ds_priority_add(open_list, neighbor_key, neighbor.f);
            }
        }
    }

    // 경로 없음
    ds_priority_destroy(open_list);
    return undefined;
}

/// @function heuristic_octile(x1, y1, x2, y2)
/// @description 8방향 휴리스틱 (Octile Distance)
function heuristic_octile(x1, y1, x2, y2) {
    var dx = abs(x2 - x1);
    var dy = abs(y2 - y1);
    return 10 * (dx + dy) + (14 - 2 * 10) * min(dx, dy);
}

/// @function reconstruct_path(node, tile_size)
function reconstruct_path(node, tile_size) {
    var path = [];
    var current = node;

    while (current.parent != undefined) {
        array_insert(path, 0, {
            x: current.x * tile_size + tile_size / 2,
            y: current.y * tile_size + tile_size / 2
        });
        current = current.parent;
    }

    return path;
}
```

#### 4.8.3 Steering Behaviors (부드러운 이동)

> 경로를 따라가면서 다른 유닛과 충돌 회피

```gml
/// 유닛 이동 상태
unit.movement = {
    path: [],                   // A* 경로
    path_index: 0,              // 현재 목표 웨이포인트
    velocity: { x: 0, y: 0 },   // 현재 속도
    desired_velocity: { x: 0, y: 0 },

    // Steering 설정
    max_speed: 100,
    max_force: 200,             // 최대 조향력
    arrival_radius: 32,         // 도착 감속 시작 거리
    separation_radius: 48,      // 분리 거리
    separation_weight: 1.5,
    path_weight: 1.0
}

/// @function unit_update_movement(unit, delta)
/// @description 매 프레임 이동 업데이트
function unit_update_movement(unit, delta) {
    if (array_length(unit.movement.path) == 0) return;

    var steering = { x: 0, y: 0 };

    // 1. 경로 추종 (Path Following)
    var path_force = steering_path_follow(unit);
    steering.x += path_force.x * unit.movement.path_weight;
    steering.y += path_force.y * unit.movement.path_weight;

    // 2. 분리 (Separation) - 다른 유닛과 겹치지 않게
    var sep_force = steering_separation(unit);
    steering.x += sep_force.x * unit.movement.separation_weight;
    steering.y += sep_force.y * unit.movement.separation_weight;

    // 3. 조향력 제한
    var force_mag = point_distance(0, 0, steering.x, steering.y);
    if (force_mag > unit.movement.max_force) {
        steering.x = (steering.x / force_mag) * unit.movement.max_force;
        steering.y = (steering.y / force_mag) * unit.movement.max_force;
    }

    // 4. 속도 업데이트
    unit.movement.velocity.x += steering.x * delta;
    unit.movement.velocity.y += steering.y * delta;

    // 5. 속도 제한
    var speed = point_distance(0, 0, unit.movement.velocity.x, unit.movement.velocity.y);
    if (speed > unit.movement.max_speed) {
        unit.movement.velocity.x = (unit.movement.velocity.x / speed) * unit.movement.max_speed;
        unit.movement.velocity.y = (unit.movement.velocity.y / speed) * unit.movement.max_speed;
    }

    // 6. 위치 업데이트
    unit.x += unit.movement.velocity.x * delta;
    unit.y += unit.movement.velocity.y * delta;

    // 7. 웨이포인트 도달 체크
    check_waypoint_reached(unit);
}

/// @function steering_path_follow(unit)
function steering_path_follow(unit) {
    var path = unit.movement.path;
    var idx = unit.movement.path_index;

    if (idx >= array_length(path)) {
        return { x: 0, y: 0 };
    }

    var target = path[idx];
    var dx = target.x - unit.x;
    var dy = target.y - unit.y;
    var dist = point_distance(0, 0, dx, dy);

    // 도착 감속 (Arrival)
    var desired_speed = unit.movement.max_speed;
    if (dist < unit.movement.arrival_radius) {
        desired_speed = unit.movement.max_speed * (dist / unit.movement.arrival_radius);
    }

    // 원하는 속도
    if (dist > 0) {
        unit.movement.desired_velocity.x = (dx / dist) * desired_speed;
        unit.movement.desired_velocity.y = (dy / dist) * desired_speed;
    }

    // 조향력 = 원하는 속도 - 현재 속도
    return {
        x: unit.movement.desired_velocity.x - unit.movement.velocity.x,
        y: unit.movement.desired_velocity.y - unit.movement.velocity.y
    };
}

/// @function steering_separation(unit)
/// @description 주변 유닛과 겹치지 않게 밀어내기
function steering_separation(unit) {
    var force = { x: 0, y: 0 };
    var neighbors = spatial_query(unit.x, unit.y, unit.movement.separation_radius);
    var count = 0;

    for (var i = 0; i < array_length(neighbors); i++) {
        var other = neighbors[i];
        if (other.id == unit.id) continue;

        var dx = unit.x - other.x;
        var dy = unit.y - other.y;
        var dist = point_distance(0, 0, dx, dy);

        if (dist > 0 && dist < unit.movement.separation_radius) {
            // 가까울수록 강하게 밀어냄
            var strength = 1.0 - (dist / unit.movement.separation_radius);
            force.x += (dx / dist) * strength;
            force.y += (dy / dist) * strength;
            count++;
        }
    }

    if (count > 0) {
        force.x /= count;
        force.y /= count;

        // 정규화 후 최대 힘 적용
        var mag = point_distance(0, 0, force.x, force.y);
        if (mag > 0) {
            force.x = (force.x / mag) * unit.movement.max_force;
            force.y = (force.y / mag) * unit.movement.max_force;
        }
    }

    return force;
}
```

#### 4.8.4 전선 인식 시스템 (Front Line)

> 아군과 적의 접점(전선)을 파악하여 전술적 판단

```gml
/// 전선 정보
global.front_line = {
    // 전선 위치 (x 좌표 기준)
    position_x: 0,

    // 전선 상태
    status: "holding",          // "pushing", "holding", "retreating"

    // 전선 강도 (아군 - 적 비율)
    strength: 0,                // 양수: 아군 우세, 음수: 적 우세

    // 전선에 있는 유닛들
    frontline_allies: [],
    frontline_enemies: [],

    // 설정
    frontline_depth: 128        // 전선으로 간주하는 깊이
}

/// @function update_front_line()
/// @description 매 프레임 전선 상태 업데이트
function update_front_line() {
    var allies = global.battle_state.allies;
    var enemies = global.battle_state.enemies;

    if (array_length(allies) == 0 || array_length(enemies) == 0) {
        return;
    }

    // 1. 가장 전방에 있는 아군/적 찾기
    var frontmost_ally_x = 0;
    var frontmost_enemy_x = 9999;

    for (var i = 0; i < array_length(allies); i++) {
        if (allies[i].hp > 0 && allies[i].x > frontmost_ally_x) {
            frontmost_ally_x = allies[i].x;
        }
    }

    for (var i = 0; i < array_length(enemies); i++) {
        if (enemies[i].hp > 0 && enemies[i].x < frontmost_enemy_x) {
            frontmost_enemy_x = enemies[i].x;
        }
    }

    // 2. 전선 위치 계산 (아군과 적의 중간)
    var new_position = (frontmost_ally_x + frontmost_enemy_x) / 2;
    var old_position = global.front_line.position_x;
    global.front_line.position_x = new_position;

    // 3. 전선 상태 판단
    var position_delta = new_position - old_position;
    if (position_delta > 5) {
        global.front_line.status = "pushing";       // 아군 전진 중
    } else if (position_delta < -5) {
        global.front_line.status = "retreating";    // 아군 후퇴 중
    } else {
        global.front_line.status = "holding";       // 교착
    }

    // 4. 전선 근처 유닛 수집
    global.front_line.frontline_allies = [];
    global.front_line.frontline_enemies = [];
    var depth = global.front_line.frontline_depth;

    for (var i = 0; i < array_length(allies); i++) {
        if (abs(allies[i].x - new_position) <= depth) {
            array_push(global.front_line.frontline_allies, allies[i]);
        }
    }

    for (var i = 0; i < array_length(enemies); i++) {
        if (abs(enemies[i].x - new_position) <= depth) {
            array_push(global.front_line.frontline_enemies, enemies[i]);
        }
    }

    // 5. 전선 강도 계산
    var ally_power = calculate_combat_power(global.front_line.frontline_allies);
    var enemy_power = calculate_combat_power(global.front_line.frontline_enemies);

    if (enemy_power > 0) {
        global.front_line.strength = (ally_power - enemy_power) / enemy_power;
    } else {
        global.front_line.strength = 1;
    }
}

/// @function calculate_combat_power(units)
function calculate_combat_power(units) {
    var power = 0;
    for (var i = 0; i < array_length(units); i++) {
        var u = units[i];
        if (u.hp <= 0) continue;

        // 전투력 = HP% * (공격력 + 방어력/2)
        var hp_ratio = u.hp / u.max_hp;
        power += hp_ratio * (u.attack + u.defense * 0.5);
    }
    return power;
}

/// @function should_retreat(unit)
/// @description 후퇴 판단
function should_retreat(unit) {
    // 1. 개인 HP 위험
    if (unit.hp / unit.max_hp < 0.2) return true;

    // 2. 전선 붕괴
    if (global.front_line.strength < -0.5) return true;

    // 3. 고립됨 (주변 아군 없음)
    var nearby_allies = find_allies_in_range(unit, 100);
    if (array_length(nearby_allies) == 0) return true;

    return false;
}

/// @function should_advance(unit)
/// @description 전진 판단
function should_advance(unit) {
    // 전선 우세하고, HP 충분하면 전진
    return global.front_line.strength > 0.3 && unit.hp / unit.max_hp > 0.5;
}
```

#### 4.8.5 진형 시스템 (Formation)

> 유닛들이 역할에 맞는 위치 유지

```gml
/// 진형 정의
global.formation = {
    // 기준점 (전선 약간 뒤)
    anchor: { x: 0, y: 0 },

    // 열별 오프셋
    rows: {
        front: { offset_x: 80, spread_y: 64 },      // 전열
        mid: { offset_x: 0, spread_y: 80 },         // 중열
        back: { offset_x: -80, spread_y: 96 },      // 후열
        wall: { offset_x: -150, spread_y: 120 }     // 성벽
    },

    // 진형 상태
    state: "defensive"          // "defensive", "aggressive", "retreat"
}

/// @function update_formation()
function update_formation() {
    // 기준점 = 전선 약간 뒤
    global.formation.anchor.x = global.front_line.position_x - 100;
    global.formation.anchor.y = global.gate_position.y;

    // 전선 상태에 따라 진형 조정
    if (global.front_line.status == "pushing" && global.front_line.strength > 0.5) {
        global.formation.state = "aggressive";
        global.formation.anchor.x = global.front_line.position_x - 50;  // 더 전진
    } else if (global.front_line.status == "retreating" || global.front_line.strength < -0.3) {
        global.formation.state = "retreat";
        global.formation.anchor.x = global.front_line.position_x - 150; // 더 후퇴
    } else {
        global.formation.state = "defensive";
    }
}

/// @function get_formation_slot(unit)
/// @description 유닛의 진형 내 목표 위치 계산
function get_formation_slot(unit) {
    var anchor = global.formation.anchor;
    var role = unit.combat.function;
    var row_config;

    // 역할별 열 배정
    if (role == "tank" || (unit.combat.range == "melee" && role == "damage")) {
        row_config = global.formation.rows.front;
    } else if (role == "support") {
        row_config = global.formation.rows.mid;
    } else {
        row_config = global.formation.rows.back;
    }

    // 같은 열의 유닛 수로 Y 위치 분산
    var same_row_units = get_units_in_row(unit, row_config);
    var slot_index = array_get_index(same_row_units, unit);
    var total_in_row = array_length(same_row_units);

    // Y 분산 계산
    var y_offset = 0;
    if (total_in_row > 1) {
        y_offset = (slot_index - (total_in_row - 1) / 2) * row_config.spread_y;
    }

    return {
        x: anchor.x + row_config.offset_x,
        y: anchor.y + y_offset
    };
}

/// @function ai_maintain_formation(unit)
/// @description 진형 유지 AI
function ai_maintain_formation(unit) {
    // 전투 중이면 진형보다 전투 우선
    if (unit.target != undefined && is_alive(unit.target)) {
        return false;
    }

    var slot = get_formation_slot(unit);
    var dist = point_distance(unit.x, unit.y, slot.x, slot.y);

    // 진형 위치에서 너무 멀면 복귀
    if (dist > 50) {
        var path = pathfind_astar(unit.x, unit.y, slot.x, slot.y, unit);
        if (path != undefined) {
            unit.movement.path = path;
            unit.movement.path_index = 0;
        }
        return true;
    }

    return false;
}
```

#### 4.8.6 통합 이동 AI

```gml
/// @function unit_movement_ai(unit, delta)
/// @description 통합 이동 AI - 전투 + 진형 + 길찾기
function unit_movement_ai(unit, delta) {
    // 1. 후퇴 필요?
    if (should_retreat(unit)) {
        var retreat_pos = get_retreat_position(unit);
        request_path_to(unit, retreat_pos.x, retreat_pos.y);
        unit.ai_state = "retreating";
        return;
    }

    // 2. 타겟 있음?
    if (unit.target != undefined && is_alive(unit.target)) {
        var dist = point_distance(unit.x, unit.y, unit.target.x, unit.target.y);

        // 공격 사거리 밖이면 접근
        if (dist > unit.attack_range * 64) {
            request_path_to(unit, unit.target.x, unit.target.y);
            unit.ai_state = "chasing";
        } else {
            // 사거리 내면 공격 (이동 멈춤)
            unit.movement.path = [];
            unit.ai_state = "attacking";
        }
        return;
    }

    // 3. 타겟 없음 - 새 타겟 찾기
    var new_target = find_best_target(unit);
    if (new_target != undefined) {
        unit.target = new_target;
        return;
    }

    // 4. 타겟도 없고 위협도 없음 - 진형 유지
    if (!ai_maintain_formation(unit)) {
        // 진형 위치에 있으면 대기
        unit.movement.path = [];
        unit.ai_state = "idle";
    }
}

/// @function request_path_to(unit, target_x, target_y)
/// @description 경로 요청 (캐싱 및 재계산 최적화)
function request_path_to(unit, target_x, target_y) {
    // 같은 목표면 재계산 스킵
    if (unit.path_target_x == target_x && unit.path_target_y == target_y) {
        if (array_length(unit.movement.path) > 0) return;
    }

    // 경로 계산
    var path = pathfind_astar(unit.x, unit.y, target_x, target_y, unit);

    if (path != undefined && array_length(path) > 0) {
        unit.movement.path = path;
        unit.movement.path_index = 0;
        unit.path_target_x = target_x;
        unit.path_target_y = target_y;
    }
}

/// @function get_retreat_position(unit)
function get_retreat_position(unit) {
    // 성문 방향으로 후퇴
    var gate = global.gate_position;
    var dir_x = gate.x - unit.x;
    var dir_y = gate.y - unit.y;
    var dist = point_distance(0, 0, dir_x, dir_y);

    if (dist > 0) {
        return {
            x: unit.x + (dir_x / dist) * 150,
            y: unit.y + (dir_y / dist) * 150
        };
    }

    return gate;
}
```

---

## 5. 소환 시스템

### 5.1 소환 효과 구조

```gml
effect_summon = {
    type: "summon",
    unit_type: "skeleton_warrior",
    count: 2,

    position: "around_caster",
    duration: 15,                   // -1이면 영구

    inherit_stats: true,
    stat_scale: 0.5,                // 시전자 스탯의 50%

    summon_tags: ["undead", "minion", "summoned"],

    max_summons: 5,
    replace_oldest: true
}
```

### 5.2 소환물 추적

```gml
// 소환자 유닛
summoner = {
    ...
    summoned_units: [2001, 2002, 2003],     // 소환물 ID 목록
    max_summons: 5
}

// 소환물 유닛
summon = {
    ...
    summoner_id: 1001,              // 소환자 ID
    is_summon: true,
    summon_duration: 15,
    summon_remaining: 10
}
```

### 5.3 소환 해제

```gml
// 적 소환물 해제
effect_unsummon = {
    type: "unsummon",
    target_tags: ["minion"],
    target_team: "enemy",
    count: 99,

    on_unsummon: [
        { type: "damage", amount: 100, target: "summoner" }
    ]
}

// 내 소환물 폭파
effect_detonate = {
    type: "unsummon",
    target_team: "self_summons",
    target_tags: ["bomb"],
    on_unsummon: [
        { type: "aoe", radius: 2, effects: [
            { type: "damage", amount: 400 }
        ]}
    ]
}
```

---

## 6. 시체 시스템

### 6.1 시체 구조

```gml
corpse = {
    id: "corpse_001",
    x: 3,
    y: 5,

    // 원본 유닛 정보
    original_unit: {
        unit_type: "knight",
        team: "ally",
        level: 2,
        max_hp: 1000,
        attack: 80,
        traits: ["human", "warrior"],
        killer_id: 2001
    },

    // 시체 상태
    state: "fresh",                 // "fresh", "decaying", "skeleton"
    freshness: 100,
    decay_rate: 10,

    // 태그
    tags: ["corpse", "human", "warrior", "ally_corpse", "fresh"],

    // 시간
    duration: 30,

    // 사용 상태
    consumed: false,
    partial_uses: 0,
    max_uses: 3
}
```

### 6.2 시체 생성

```gml
function on_unit_death(unit, killer) {
    if (unit.no_corpse) return;
    if (has_debuff(unit, "disintegrate")) return;

    var corpse = {
        id: generate_corpse_id(),
        x: unit.x,
        y: unit.y,
        original_unit: {
            unit_type: unit.type,
            team: unit.team,
            level: unit.level,
            max_hp: unit.max_hp,
            attack: unit.attack,
            traits: unit.traits,
            killer_id: killer.id
        },
        state: "fresh",
        freshness: 100,
        tags: generate_corpse_tags(unit),
        duration: 30,
        consumed: false
    };

    array_push(global.corpses, corpse);
    trigger_event("on_corpse_created", corpse);
}
```

### 6.3 시체 상태 변화

```
유닛 사망
    ↓
시체 생성 (state: "fresh", freshness: 100)
    ↓
시간 경과 (freshness 감소)
    ↓
freshness <= 50 → state: "decaying"
    ↓
freshness <= 0 → state: "skeleton"
    ↓
duration <= 0 또는 consumed → 시체 소멸
```

### 6.4 시체 타겟팅

```gml
// 적 시체만
targeting_enemy_corpse = {
    base: "corpse",
    filters: [{ type: "corpse_team", team: "enemy" }]
}

// 신선한 시체
targeting_fresh = {
    base: "corpse",
    filters: [{ type: "corpse_state", states: ["fresh"] }]
}
```

### 6.5 시체 효과

```gml
// 시체 폭발 (소모)
effect_corpse_explode = {
    type: "corpse_explode",
    consume: true,
    damage_base: 50,
    damage_scale: "corpse_max_hp",
    damage_percent: 25,
    radius: 2
}

// 부활 (소모)
effect_resurrect = {
    type: "resurrect",
    consume: true,
    hp_percent: 50,
    keep_team: true,
    duration: -1
}

// 언데드 소환 (소모)
effect_raise_undead = {
    type: "raise_undead",
    consume: true,
    convert_to: "zombie",
    inherit_stats: true,
    stat_modifier: 0.7,
    team: "caster",
    duration: 20
}

// 시체 포식 (소모)
effect_devour = {
    type: "devour_corpse",
    consume: true,
    heal_percent_of_corpse_hp: 50,
    buff_on_devour: [
        { type: "buff", stat: "attack", value: 30, duration: 8 }
    ]
}

// 시체 위치 효과 (비소모)
effect_at_corpse = {
    type: "effect_at_corpse",
    consume: false,
    effects: [
        { type: "create_tile_effect", effect: "poison_cloud", duration: 5 }
    ]
}
```

---

## 7. 진화/변이 시스템

### 7.1 진화 구조

```gml
evolution = {
    id: "knight_to_paladin",
    from_unit: "knight",
    to_unit: "paladin",

    conditions: {
        level: 10,
        kills: 50,
        battles_survived: 20,
        items_required: ["holy_relic"],
        stats_required: { defense: 100 }
    },

    on_evolve: [
        { type: "full_heal" },
        { type: "grant_skill", skill: "divine_shield" },
        { type: "stat_boost", stats: { hp: 200, defense: 50 } },
        { type: "change_role", new_role: "tank_healer" }
    ],

    revert_condition: null          // null이면 영구
}
```

### 7.2 변이 (일시적)

```gml
mutation = {
    id: "berserker_rage",
    trigger: "hp_below_25",

    duration: 10,
    revert_when: "hp_above_50",

    stat_changes: {
        attack: { multiply: 2.0 },
        defense: { multiply: 0.5 },
        attack_speed: { add: 50 }
    },

    replace_skills: {
        "normal_attack": "berserk_strike",
        "defensive_stance": "reckless_charge"
    },

    visual_changes: {
        sprite: "spr_unit_berserk",
        color_tint: [255, 100, 100],
        scale: 1.2
    },

    on_revert: [
        { type: "stun", duration: 1 },
        { type: "heal", percent: 10 }
    ]
}
```

### 7.3 환경 기반 변이

```gml
terrain_mutation = {
    id: "water_elemental_form",
    unit_tags: ["elemental"],
    trigger: "standing_on_terrain",
    terrain: "water",
    delay: 3,

    mutations: {
        water: {
            stat_changes: { defense: { add: 30 }, hp_regen: { add: 20 } },
            grant_skills: ["tidal_wave"],
            remove_skills: ["fire_bolt"]
        },
        fire: {
            stat_changes: { attack: { add: 50 } },
            grant_skills: ["fire_bolt"],
            remove_skills: ["tidal_wave"]
        }
    }
}
```

### 7.4 처치 기반 진화

```gml
kill_evolution = {
    id: "demon_hunter_evolution",
    from_unit: "hunter",
    conditions: {
        kill_count: {
            demon: 100,
            boss_demon: 1
        }
    },
    to_unit: "demon_slayer",
    on_evolve: [
        { type: "grant_passive", passive: "demon_bane" },
        { type: "change_attack_type", new_type: "holy" }
    ]
}
```

### 7.5 분기 진화

```gml
branch_evolution = {
    from_unit: "mage",
    level_required: 15,

    branches: [
        {
            id: "fire_archmage",
            additional_condition: { fire_kills: 100 },
            to_unit: "fire_archmage",
            description: "화염 특화"
        },
        {
            id: "ice_archmage",
            additional_condition: { ice_kills: 100 },
            to_unit: "ice_archmage",
            description: "냉기 특화"
        },
        {
            id: "arcane_archmage",
            additional_condition: { total_mana_spent: 10000 },
            to_unit: "arcane_archmage",
            description: "순수 마력"
        }
    ],

    show_choice_ui: true
}
```

---

## 8. 구현 가이드

### 8.1 유닛 AI 메인 함수

```gml
/// @func unit_ai_update(unit)
function unit_ai_update(unit) {
    var ai = get_ai_for_role(unit.role);

    // 우선순위 행동 체크
    for (var i = 0; i < array_length(ai.priority_actions); i++) {
        var action = ai.priority_actions[i];

        // 조건 체크
        if (variable_struct_exists(action, "condition")) {
            if (!evaluate_condition(unit, action.condition)) continue;
        }

        // 행동 실행
        if (execute_action(unit, action.action)) {
            return;     // 성공하면 종료
        }
    }
}
```

### 8.2 소환 함수

```gml
/// @func apply_summon(caster, effect)
function apply_summon(caster, effect) {
    // 최대 소환수 체크
    if (array_length(caster.summoned_units) >= effect.max_summons) {
        if (effect.replace_oldest) {
            var oldest = caster.summoned_units[0];
            destroy_unit(oldest);
            array_delete(caster.summoned_units, 0, 1);
        } else {
            return;
        }
    }

    for (var i = 0; i < effect.count; i++) {
        var pos = get_summon_position(caster, effect.position, i);
        var summoned = create_unit(effect.unit_type, pos.x, pos.y);

        summoned.summoner_id = caster.id;
        summoned.is_summon = true;
        summoned.team = caster.team;
        summoned.summon_duration = effect.duration;

        if (effect.inherit_stats) {
            apply_stat_inheritance(summoned, caster, effect.stat_scale);
        }

        array_push(caster.summoned_units, summoned.id);
    }
}
```

### 8.3 시체 처리 함수

```gml
/// @func update_corpse(corpse, delta_time)
function update_corpse(corpse, delta_time) {
    corpse.duration -= delta_time;
    corpse.freshness -= corpse.decay_rate * delta_time;

    // 상태 전환
    if (corpse.freshness <= 0 && corpse.state != "skeleton") {
        corpse.state = "skeleton";
        update_corpse_tags(corpse);
    } else if (corpse.freshness <= 50 && corpse.state == "fresh") {
        corpse.state = "decaying";
        update_corpse_tags(corpse);
    }

    // 소멸
    if (corpse.duration <= 0 || corpse.consumed) {
        destroy_corpse(corpse);
    }
}
```

### 8.4 진화 체크 함수

```gml
/// @func check_evolution(unit)
function check_evolution(unit) {
    var evolutions = get_evolutions_for_unit(unit.type);

    for (var i = 0; i < array_length(evolutions); i++) {
        var evo = evolutions[i];

        if (check_evolution_conditions(unit, evo.conditions)) {
            if (array_length(evo.branches) > 0) {
                // 분기 진화 - UI 표시
                show_evolution_choice(unit, evo.branches);
            } else {
                // 단일 진화 - 즉시 실행
                apply_evolution(unit, evo);
            }
            return;
        }
    }
}
```
