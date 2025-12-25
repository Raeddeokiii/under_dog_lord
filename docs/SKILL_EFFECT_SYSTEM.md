# 스킬/효과 시스템

> 스킬 정의, 효과 타입, 타겟팅, 버프/디버프, 트리거, 스택 시스템

---

## 목차

1. [스킬 기본 구조](#1-스킬-기본-구조)
2. [효과(Effect) 시스템](#2-효과effect-시스템)
3. [타겟팅 시스템](#3-타겟팅-시스템)
4. [버프/디버프 시스템](#4-버프디버프-시스템)
5. [트리거/패시브 시스템](#5-트리거패시브-시스템)
6. [스택/누적 시스템](#6-스택누적-시스템)
7. [구현 가이드](#7-구현-가이드)

---

## 1. 스킬 기본 구조

### 1.1 스킬 정의

```gml
skill = {
    // 기본 정보
    id: "skill_fireball",
    name: "파이어볼",
    description: "적에게 불덩이를 발사하여 데미지를 주고 주변 적에게도 피해를 입힌다",
    icon: "spr_skill_fireball",

    // 비용
    mana_cost: 50,
    cooldown: 5,

    // 시전 타입
    cast_type: "instant",       // "instant", "channel", "charge"
    cast_time: 0,
    interruptible: false,

    // 타겟팅
    targeting: {
        base: "enemy",
        select: "nearest",
        count: 1
    },

    // 효과 목록
    effects: [
        { type: "projectile", speed: 8, visual: "spr_fireball" },
        { type: "damage", amount: 200, damage_type: "fire" },
        { type: "aoe", radius: 1, effects: [
            { type: "damage", amount: 100, damage_type: "fire" }
        ]}
    ],

    // AI 힌트 (유닛 AI가 스킬 사용 판단에 활용)
    ai_hints: {
        use_when: "enemies_grouped",
        min_targets: 2,
        priority: 80,
        save_for_wave: false
    },

    // 연출
    vfx: { on_cast: "vfx_cast_fire", on_hit: "vfx_explosion_fire" },
    sfx: { on_cast: "sfx_fireball_cast", on_hit: "sfx_explosion" }
}
```

### 1.2 시전 타입

| 타입 | 설명 | 중단 시 |
|------|------|---------|
| `instant` | 즉시 발동 | - |
| `channel` | 지속 시전 (틱 효과) | 효과 중단 |
| `charge` | 충전 후 발동 | 취소 또는 약화 발동 |

```gml
// 채널링 스킬 예시
skill_laser = {
    cast_type: "channel",
    channel_duration: 3,
    interruptible: true,
    effects_per_tick: [
        { type: "damage", amount: 50, tick_rate: 0.5 }
    ],
    on_interrupt: [
        { type: "stun", target: "caster", duration: 0.5 }
    ]
}

// 충전 스킬 예시
skill_charge_shot = {
    cast_type: "charge",
    min_charge: 0.5,
    max_charge: 3.0,
    charge_scaling: {
        damage: { base: 100, per_second: 100 }
    }
}
```

---

## 2. 효과(Effect) 시스템

### 2.1 효과 타입 전체 목록

#### 기본 효과

| 타입 | 설명 | 주요 파라미터 |
|------|------|---------------|
| `damage` | 데미지 | amount, damage_type, crit_chance |
| `heal` | 회복 | amount, percent |
| `buff` | 버프 | stat, value, duration, tags |
| `debuff` | 디버프 | stat, value, duration, tags |
| `cleanse` | 효과 해제 (아군) | target_tags, count |
| `dispel` | 효과 해제 (적) | target_tags, count |
| `shield` | 보호막 | amount, duration, absorb_type |

#### 상태 효과 (CC)

| 타입 | 설명 | 주요 파라미터 |
|------|------|---------------|
| `stun` | 기절 | duration |
| `silence` | 침묵 | duration |
| `root` | 속박 | duration |
| `slow` | 둔화 | percent, duration |
| `fear` | 공포 | duration, behavior |
| `charm` | 매혹 | duration, switch_team |
| `taunt` | 도발 | duration, force_target |
| `blind` | 실명 | duration, miss_chance |

#### 위치/공간 효과

| 타입 | 설명 | 주요 파라미터 |
|------|------|---------------|
| `displace` | 밀치기/당기기 | direction, distance |
| `swap_position` | 위치 교환 | target |
| `teleport` | 순간이동 | destination |

#### 자원 효과

| 타입 | 설명 | 주요 파라미터 |
|------|------|---------------|
| `mana_modify` | 마나 변경 | amount, damage_per_mana |
| `mana_drain` | 마나 흡수 | amount, give_to_caster |
| `reset_cooldown` | 쿨다운 초기화 | skill_filter |

#### 조건부/확률 효과

| 타입 | 설명 | 주요 파라미터 |
|------|------|---------------|
| `conditional` | 조건부 효과 | condition, then_effects, else_effects |
| `chance` | 확률 효과 | percent, success_effects, fail_effects |
| `random_one` | 랜덤 선택 | options (weight, effects) |

#### 범위 효과

| 타입 | 설명 | 주요 파라미터 |
|------|------|---------------|
| `aoe` | 범위 효과 | shape, radius, effects |
| `chain` | 연쇄 효과 | max_targets, range, effects |
| `projectile` | 투사체 | speed, pierce, on_hit |

#### 희생/자폭 효과

| 타입 | 설명 | 주요 파라미터 |
|------|------|---------------|
| `sacrifice` | 자폭 (시전자 사망) | no_corpse, on_death_effects |
| `sacrifice_hp` | HP 희생 (생존) | amount, percent, scale_sacrifice |
| `sacrifice_ally` | 아군 희생 | target_filter, on_death_effects |
| `kill_self` | 즉시 자살 | no_corpse, trigger_on_death |
| `detonate` | 소환물 폭파 | summon_filter, on_death_effects |

### 2.2 효과 정의 예시

```gml
// 데미지 효과
effect_damage = {
    type: "damage",
    amount: 200,
    damage_type: "fire",

    // 스케일링
    scale_stat: "attack",
    scale_percent: 100,

    // 추가 옵션
    crit_chance: 0,
    crit_damage: 150,
    armor_penetration: 0,
    true_damage: false,

    // 조건부 보너스
    bonus_vs_tags: {
        undead: { damage_mult: 1.5 },
        boss: { damage_mult: 0.8 }
    }
}

// 힐 효과
effect_heal = {
    type: "heal",
    amount: 150,
    // 또는 퍼센트
    percent: 30,

    // 힐 증폭 적용 여부
    affected_by_healing_power: true,

    // 과힐 시 보호막 전환
    overheal_to_shield: true,
    overheal_shield_percent: 50
}

// 범위 효과
effect_aoe = {
    type: "aoe",
    shape: "circle",            // "circle", "line", "cone", "cross"
    radius: 2,
    center: "target",           // "caster", "target", "between"
    affect_allies: false,
    affect_enemies: true,
    affect_caster: false,
    effects: [
        { type: "damage", amount: 150 },
        { type: "slow", percent: 30, duration: 2 }
    ]
}

// 조건부 효과
effect_conditional = {
    type: "conditional",
    condition: { target_hp_percent: "<", value: 30 },
    then_effects: [
        { type: "damage", amount: 500, damage_type: "true" }     // 처형
    ],
    else_effects: [
        { type: "damage", amount: 200 }
    ]
}

// 다중 조건
effect_multi_condition = {
    type: "conditional",
    conditions: [
        { check: "target_hp_percent", op: "<", value: 50 },
        { check: "caster_has_buff_tag", tag: "enraged" }
    ],
    condition_logic: "all",     // "all" (AND) 또는 "any" (OR)
    then_effects: [...],
    else_effects: [...]
}

// 확률 효과
effect_chance = {
    type: "chance",
    percent: 30,
    success_effects: [
        { type: "stun", duration: 2 }
    ],
    fail_effects: []
}

// 연쇄 효과
effect_chain = {
    type: "chain",
    max_targets: 5,
    range: 3,
    damage_falloff: 0.8,        // 연쇄마다 80%로 감소
    can_return: false,          // 이미 맞은 대상 재타격 불가
    effects: [
        { type: "damage", amount: 200, damage_type: "electric" }
    ]
}
```

### 2.3 희생/자폭 효과 상세

> 시전자 또는 아군을 희생하여 강력한 효과 발동

#### 자폭 (sacrifice)

```gml
// 자폭 - 시전자 사망 + 주변 폭발
effect_sacrifice = {
    type: "sacrifice",

    // 사망 옵션
    kill_caster: true,
    no_corpse: true,                    // 시체 안 남김 (부활 불가)
    bypass_immortal: false,             // 불사 상태 무시 여부

    // 사망 시 발동 효과
    on_death_effects: [
        {
            type: "aoe",
            radius: 3,
            center: "caster_position",  // 시전자 위치 기준
            target_filter: "enemy",
            effects: [
                { type: "damage", amount: 300, damage_type: "fire" },
                { type: "stun", duration: 1 }
            ]
        }
    ],

    // 데미지 스케일링 옵션
    scale_options: {
        source: "caster_max_hp",        // 시전자 최대 HP 기준
        percent: 50,                    // 최대 HP의 50%를 데미지로
        // 또는
        source: "caster_missing_hp",    // 잃은 HP 기준
        percent: 100                    // 잃은 HP만큼 데미지
    }
}

// 스킬 예시: 고블린 자폭
skill_goblin_bomb = {
    id: "goblin_bomb",
    name: "자폭",
    mana_cost: 0,
    cooldown: 0,
    targeting: { base: "self" },
    effects: [
        {
            type: "sacrifice",
            kill_caster: true,
            no_corpse: true,
            on_death_effects: [
                {
                    type: "aoe",
                    radius: 2,
                    center: "caster_position",
                    effects: [
                        {
                            type: "damage",
                            amount: 0,
                            scale_stat: "caster_max_hp",
                            scale_percent: 100      // 최대 HP의 100% 데미지
                        }
                    ]
                }
            ]
        }
    ],
    ai_hints: {
        use_when: "surrounded",
        min_enemies_nearby: 3,
        hp_threshold: 30                // HP 30% 이하일 때 사용
    }
}
```

#### HP 희생 (sacrifice_hp)

```gml
// HP 희생 - 죽지 않고 HP를 소모하여 효과 강화
effect_sacrifice_hp = {
    type: "sacrifice_hp",

    // 희생량
    amount: 200,                        // 고정값
    // 또는
    percent: 30,                        // 현재 HP의 30%
    percent_of: "current",              // "current", "max", "missing"

    // 안전장치
    min_hp_after: 1,                    // 최소 1 HP는 남김
    can_kill: false,                    // true면 자살 가능

    // 희생량 비례 효과
    effects: [
        {
            type: "damage",
            amount: 100,
            bonus_per_hp_sacrificed: 2  // 희생 HP 1당 데미지 +2
        }
    ]
}

// 스킬 예시: 피의 마법
skill_blood_magic = {
    id: "blood_magic",
    name: "피의 마법",
    mana_cost: 0,                       // 마나 대신 HP 소모
    cooldown: 8,
    targeting: { base: "enemy", select: "nearest", count: 1 },
    effects: [
        {
            type: "sacrifice_hp",
            percent: 25,
            percent_of: "current",
            min_hp_after: 1,
            effects: [
                {
                    type: "damage",
                    amount: 50,
                    bonus_per_hp_sacrificed: 3,  // HP 100 희생 → +300 데미지
                    damage_type: "shadow"
                },
                {
                    type: "lifesteal",
                    percent: 50                  // 데미지의 50% 회복
                }
            ]
        }
    ]
}

// 스킬 예시: 광전사의 분노
skill_berserker_rage = {
    id: "berserker_rage",
    name: "광전사의 분노",
    targeting: { base: "self" },
    effects: [
        {
            type: "sacrifice_hp",
            percent: 50,
            percent_of: "current",
            min_hp_after: 100,
            effects: [
                {
                    type: "buff",
                    stat: "attack",
                    percent: true,              // 퍼센트 증가
                    value: 100,                 // 공격력 100% 증가
                    duration: 10,
                    tags: ["berserk", "self_buff"]
                },
                {
                    type: "buff",
                    stat: "attack_speed",
                    value: 50,
                    duration: 10
                }
            ]
        }
    ]
}
```

#### 아군 희생 (sacrifice_ally)

```gml
// 아군 희생 - 다른 아군을 희생시켜 효과 발동
effect_sacrifice_ally = {
    type: "sacrifice_ally",

    // 대상 선택
    target_filter: {
        base: "ally",
        filters: [
            { type: "is_summoned" },    // 소환물만 희생 가능
            { type: "not_has_tag", tags: ["boss", "hero"] }
        ],
        select: "lowest_hp",
        count: 1
    },

    // 희생 옵션
    no_corpse: false,                   // 시체는 남김
    grant_revenge_buff: true,           // 주변 아군에게 복수 버프

    // 희생 시 효과
    on_death_effects: [
        {
            type: "heal",
            target: "caster",
            percent: 50,
            percent_of: "sacrificed_max_hp"  // 희생된 유닛 최대 HP의 50%
        }
    ]
}

// 스킬 예시: 영혼 흡수
skill_consume_soul = {
    id: "consume_soul",
    name: "영혼 흡수",
    mana_cost: 30,
    targeting: { base: "ally", filters: [{ type: "is_summoned" }], count: 1 },
    effects: [
        {
            type: "sacrifice_ally",
            no_corpse: true,            // 완전 소멸
            on_death_effects: [
                {
                    type: "heal",
                    target: "caster",
                    percent: 100,
                    percent_of: "sacrificed_max_hp"
                },
                {
                    type: "buff",
                    target: "caster",
                    stat: "spell_power",
                    value: 50,
                    duration: 15
                }
            ]
        }
    ]
}
```

#### 소환물 폭파 (detonate)

```gml
// 소환물 폭파 - 내 소환물을 터뜨려 폭발
effect_detonate = {
    type: "detonate",

    // 대상 소환물
    summon_filter: {
        tags: ["explosive", "minion"],  // 특정 태그 소환물만
        count: "all"                    // 전부 폭파
    },

    // 폭발 효과
    on_death_effects: [
        {
            type: "aoe",
            radius: 2,
            center: "each_summon",      // 각 소환물 위치에서
            effects: [
                {
                    type: "damage",
                    amount: 100,
                    scale_stat: "summon_max_hp",
                    scale_percent: 50
                }
            ]
        }
    ],

    // 시전자 버프 (소환물당)
    per_summon_effects: [
        {
            type: "buff",
            target: "caster",
            stat: "attack",
            value: 10,
            duration: 8,
            stacking: true              // 중첩 가능
        }
    ]
}

// 스킬 예시: 연쇄 폭발
skill_chain_explosion = {
    id: "chain_explosion",
    name: "연쇄 폭발",
    mana_cost: 80,
    targeting: { base: "self" },
    effects: [
        {
            type: "detonate",
            summon_filter: { tags: ["bomb"] },
            on_death_effects: [
                {
                    type: "aoe",
                    radius: 2,
                    effects: [
                        { type: "damage", amount: 200, damage_type: "fire" },
                        { type: "create_tile_effect", effect: "fire_ground", duration: 3 }
                    ]
                }
            ]
        }
    ]
}
```

#### 조건부 자폭 (트리거 기반)

```gml
// 패시브: 죽을 때 자폭
passive_death_explosion = {
    id: "death_explosion",
    trigger: "on_self_death",
    effects: [
        {
            type: "aoe",
            radius: 2,
            center: "trigger_position",
            effects: [
                { type: "damage", amount: 150, damage_type: "fire" }
            ]
        }
    ]
}

// 패시브: HP 낮을 때 자동 자폭
passive_low_hp_detonate = {
    id: "low_hp_detonate",
    trigger: "on_hp_below",
    trigger_threshold: 10,              // HP 10% 이하
    trigger_once: true,                 // 1회만 발동
    effects: [
        {
            type: "sacrifice",
            kill_caster: true,
            no_corpse: true,
            on_death_effects: [
                {
                    type: "aoe",
                    radius: 3,
                    effects: [
                        { type: "damage", amount: 500 }
                    ]
                }
            ]
        }
    ]
}
```

#### 자폭형 유닛 예시

```gml
// 자폭 고블린 유닛
unit_goblin_bomber = {
    type: "goblin_bomber",
    name: "자폭 고블린",
    race: "orc",
    class: "bomber",

    hp: 100,
    max_hp: 100,
    attack: 10,
    defense: 0,
    movement_speed: 150,                // 빠른 이동

    // AI 타입
    ai_type: "ai_suicide_bomber",       // 특수 AI

    // 스킬
    skills: ["goblin_bomb"],

    // 패시브 (죽을 때 폭발)
    passives: ["death_explosion"],

    // 특수 태그
    tags: ["explosive", "kamikaze", "no_retreat"]
}

// 자폭 AI
ai_suicide_bomber = {
    role: "suicide",
    priority_actions: [
        // 1순위: 적 3마리 이상 근처면 자폭
        { action: "use_skill", skill: "goblin_bomb",
          condition: "enemies_nearby >= 3" },
        // 2순위: HP 낮으면 자폭
        { action: "use_skill", skill: "goblin_bomb",
          condition: "hp_percent <= 30" },
        // 3순위: 그냥 돌진
        { action: "move_to_nearest_enemy" }
    ],
    target_priority: [
        { type: "enemy", filter: "highest_value", weight: 100 },  // 고가치 타겟
        { type: "enemy", filter: "grouped", weight: 80 }          // 뭉쳐있는 적
    ],
    position: { row: "front", hold_position: false, chase_range: 99 }
}
```

---

## 3. 타겟팅 시스템

### 3.1 타겟팅 구조

```gml
targeting = {
    // 기본 대상 풀
    base: "enemy",              // 누구를 대상으로?

    // 필터 (AND 조합)
    filters: [                  // 조건 추가
        { type: "range", value: 5 },
        { type: "has_tag", tags: ["undead"] }
    ],

    // 최종 선택
    select: "lowest_hp",        // 어떤 기준으로?
    count: 1                    // 몇 명?
}
```

### 3.2 기본 대상 타입 (base)

| 값 | 설명 |
|----|------|
| `self` | 시전자 자신 |
| `ally` | 아군 유닛 |
| `enemy` | 적군 유닛 |
| `all` | 모든 유닛 |
| `corpse` | 시체 |
| `ally_corpse` | 아군 시체 |
| `enemy_corpse` | 적군 시체 |
| `tile` | 타일 |
| `tile_object` | 타일 오브젝트 |
| `summon` | 내 소환물 |
| `unit_or_corpse` | 유닛 또는 시체 |

### 3.3 필터 타입

| 필터 | 설명 | 파라미터 |
|------|------|----------|
| `range` | 사거리 내 | value |
| `nearest` | 가장 가까운 N개 | count |
| `furthest` | 가장 먼 N개 | count |
| `hp_percent` | 체력 비율 | op (<, >, =), value |
| `has_tag` | 태그 보유 | tags[] |
| `not_has_tag` | 태그 미보유 | tags[] |
| `has_buff_tag` | 특정 버프 보유 | tags[] |
| `has_debuff_tag` | 특정 디버프 보유 | tags[] |
| `is_summoned` | 소환물 여부 | - |
| `role` | 역할 | role |
| `on_terrain` | 특정 지형 위 | terrain |
| `on_terrain_tag` | 지형 태그 | tags[] |

### 3.4 선택 기준 (select)

| 값 | 설명 |
|----|------|
| `nearest` | 가장 가까운 |
| `furthest` | 가장 먼 |
| `lowest_hp` | 현재 체력 낮은 |
| `highest_hp` | 현재 체력 높은 |
| `lowest_hp_percent` | 체력 비율 낮은 |
| `most_buffs` | 버프 많은 |
| `most_debuffs` | 디버프 많은 |
| `highest_attack` | 공격력 높은 |
| `highest_threat` | 위협도 높은 |
| `random` | 무작위 |
| `all` | 모두 (필터 통과한 전부) |

### 3.5 타겟팅 예시

```gml
// 가장 가까운 적 1명
targeting_nearest = {
    base: "enemy",
    select: "nearest",
    count: 1
}

// 체력 낮은 아군 3명
targeting_low_hp_allies = {
    base: "ally",
    select: "lowest_hp",
    count: 3
}

// 5칸 내 언데드 적 전부
targeting_undead = {
    base: "enemy",
    filters: [
        { type: "range", value: 5 },
        { type: "has_tag", tags: ["undead"] }
    ],
    select: "all"
}

// 버프 있는 적 중 가장 가까운 1명
targeting_buffed_enemy = {
    base: "enemy",
    filters: [
        { type: "has_buff_tag", tags: ["buff"] }
    ],
    select: "nearest",
    count: 1
}

// 힐러 역할 아군
targeting_healer_ally = {
    base: "ally",
    filters: [
        { type: "role", role: "healer" }
    ],
    select: "all"
}
```

---

## 4. 버프/디버프 시스템

### 4.1 버프/디버프 구조

```gml
active_effect = {
    // 식별자
    id: "attack_up_001",
    effect_type: "buff",            // "buff" 또는 "debuff"

    // 효과
    stat: "attack",
    value: 30,
    percent: false,                 // true면 % 증가

    // 시간
    duration: 5,
    remaining: 5,
    tick_rate: 0,                   // 0이면 지속, >0이면 틱 효과

    // 태그 (필터링용)
    tags: ["buff", "magic", "dispellable", "attack_mod"],

    // 출처
    source_unit: 1001,
    source_skill: "warcry",

    // 스택
    stacks: 1,
    max_stacks: 1,
    stackable: false,

    // 특수
    unique: true,                   // 같은 id 중복 불가
    refresh_on_apply: true          // 재적용 시 지속시간 갱신
}
```

### 4.2 스탯 목록

| 스탯 | 설명 |
|------|------|
| `attack` | 공격력 |
| `defense` | 방어력 |
| `attack_speed` | 공격 속도 |
| `movement_speed` | 이동 속도 |
| `crit_chance` | 크리티컬 확률 |
| `crit_damage` | 크리티컬 데미지 |
| `dodge_chance` | 회피율 |
| `hp_regen` | 체력 재생 |
| `mana_regen` | 마나 재생 |
| `spell_power` | 주문력 |
| `lifesteal` | 생명력 흡수 |
| `damage_reduction` | 피해 감소 |
| `cc_resist` | CC 저항 |
| `range` | 사거리 |

### 4.3 태그 기반 해제

```gml
// CC 해제 (정화)
effect_cleanse_cc = {
    type: "cleanse",
    target_tags: ["debuff", "cc"],
    count: 99                       // 전부 해제
}

// 마법 버프만 해제 (적에게)
effect_dispel_magic = {
    type: "dispel",
    target_tags: ["buff", "magic"],
    count: 2                        // 최대 2개
}

// DoT만 해제
effect_cure_dot = {
    type: "cleanse",
    target_tags: ["dot"],
    count: 99
}
```

### 4.4 버프 훔치기/전이

```gml
// 버프 훔치기
effect_steal = {
    type: "steal_buff",
    target_tags: ["buff", "magic"],
    count: 1,
    transfer_to: "caster"
}

// 디버프 전이
effect_transfer = {
    type: "transfer_effects",
    from: "caster",
    to: "target",
    filter_tags: ["debuff"],
    count: 99
}

// 버프 복사
effect_copy = {
    type: "copy_effects",
    from: "target",
    to: "caster",
    filter_tags: ["buff"],
    count: 2
}
```

---

## 5. 트리거/패시브 시스템

### 5.1 트리거 구조

```gml
passive = {
    id: "passive_thorns",
    name: "가시",

    // 발동 조건
    trigger: "on_hit_received",

    // 추가 조건
    condition: {
        damage_type: "physical",
        damage_min: 50
    },

    // 확률
    chance: 100,

    // 쿨다운
    cooldown: 0,

    // 발동 횟수 제한
    max_triggers_per_battle: -1,    // -1이면 무제한

    // 효과
    effects: [
        { type: "damage", amount: 50, target: "attacker" }
    ]
}
```

### 5.2 트리거 타입

| 트리거 | 설명 | 특수 파라미터 |
|--------|------|---------------|
| `battle_start` | 전투 시작 시 | delay |
| `battle_end` | 전투 종료 시 | condition |
| `on_hit_received` | 피격 시 | damage_type, damage_min |
| `on_hit_dealt` | 공격 적중 시 | - |
| `on_crit` | 크리티컬 시 | - |
| `on_dodge` | 회피 시 | - |
| `on_kill` | 적 처치 시 | target_tags |
| `on_ally_death` | 아군 사망 시 | range |
| `on_enemy_death` | 적 사망 시 | range |
| `on_hp_threshold` | 체력 임계점 | threshold, once |
| `on_mana_full` | 마나 가득 | - |
| `on_buff_received` | 버프 받을 때 | buff_tags |
| `on_debuff_received` | 디버프 받을 때 | debuff_tags |
| `on_skill_cast` | 스킬 시전 시 | skill_tags |
| `on_heal_received` | 힐 받을 때 | - |
| `on_heal_dealt` | 힐 시전 시 | - |
| `periodic` | 주기적 | interval |

### 5.3 패시브 예시

```gml
// 피격 시 반격
passive_thorns = {
    trigger: "on_hit_received",
    effects: [
        { type: "damage", amount: 50, target: "attacker" }
    ]
}

// 처치 시 회복
passive_bloodlust = {
    trigger: "on_kill",
    effects: [
        { type: "heal", percent: 20 },
        { type: "buff", stat: "attack_speed", value: 30, duration: 3 }
    ]
}

// 체력 30% 이하 시 광폭화 (1회)
passive_berserk = {
    trigger: "on_hp_threshold",
    threshold: 30,
    once_per_battle: true,
    effects: [
        { type: "buff", stat: "attack", value: 100, duration: -1 },
        { type: "buff", stat: "attack_speed", value: 50, duration: -1 }
    ]
}

// 아군 사망 시 복수
passive_avenger = {
    trigger: "on_ally_death",
    effects: [
        { type: "buff", stat: "attack", value: 25, duration: -1, stackable: true }
    ]
}

// 주기적 회복 오라
passive_healing_aura = {
    trigger: "periodic",
    interval: 2,
    effects: [
        { type: "heal", amount: 30, target: "allies_in_range", range: 2 }
    ]
}

// 크리티컬 시 추가 공격
passive_crit_chain = {
    trigger: "on_crit",
    chance: 50,
    effects: [
        { type: "extra_attack", target: "random_enemy" }
    ]
}

// 회피 시 반격
passive_counter = {
    trigger: "on_dodge",
    effects: [
        { type: "damage", amount: 100, target: "attacker" }
    ]
}
```

---

## 6. 스택/누적 시스템

### 6.1 스택 구조

```gml
stack = {
    id: "poison_stack",
    name: "독",

    // 현재 값
    current: 3,
    max: 10,

    // 만료
    duration: 5,
    refresh_on_apply: true,

    // 출처
    source_unit: 1001,

    // 스택당 효과
    effect_per_stack: [
        { type: "dot", damage: 10, tick_rate: 1 }
    ],

    // 최대 스택 도달 시
    on_max_stack: {
        consume: true,
        effects: [
            { type: "stun", duration: 2 }
        ]
    }
}
```

### 6.2 스택 효과

```gml
// 스택 쌓기
effect_apply_stack = {
    type: "apply_stack",
    stack_id: "poison",
    amount: 1,
    max_stacks: 5,
    duration: 5,
    duration_refresh: true
}

// 스택 비례 데미지
effect_stack_damage = {
    type: "damage",
    base_amount: 50,
    multiply_by_stacks: "poison",
    consume_stacks: true
}

// 스택 소모
effect_consume = {
    type: "consume_stacks",
    stack_id: "rage",
    amount: 5,
    effects_per_stack: [
        { type: "damage", amount: 100 }
    ]
}

// 최대 스택 시 폭발
on_max_stack_bomb = {
    type: "on_max_stack",
    stack_id: "bomb",
    consume_stacks: true,
    effects: [
        { type: "aoe", radius: 2, effects: [
            { type: "damage", amount: 500 }
        ]}
    ]
}
```

### 6.3 영구 스택 (전투 간 유지)

```gml
// 베테랑 스택 (라운드 간 유지)
stack_veteran = {
    id: "veteran",
    persistent: true,
    max: 99,
    stat_per_stack: {
        attack: 5,
        defense: 3
    },
    gain_condition: {
        trigger: "on_battle_survive"
    }
}
```

---

## 7. 구현 가이드

### 7.1 스킬 실행 함수

```gml
/// @func execute_skill(caster, skill_data)
/// @desc 스킬 실행 메인 함수
function execute_skill(caster, skill_data) {
    // 1. 비용 체크
    if (caster.mana < skill_data.mana_cost) return false;
    if (skill_data.cooldown_remaining > 0) return false;

    // 2. 마나 소모
    caster.mana -= skill_data.mana_cost;

    // 3. 타겟 획득
    var targets = get_targets(caster, skill_data.targeting);
    if (array_length(targets) == 0 && skill_data.requires_target) return false;

    // 4. 효과 순차 적용
    for (var i = 0; i < array_length(skill_data.effects); i++) {
        apply_effect(caster, targets, skill_data.effects[i]);
    }

    // 5. 쿨다운 설정
    skill_data.cooldown_remaining = skill_data.cooldown;

    // 6. 트리거 발동
    trigger_event("on_skill_cast", caster, skill_data);

    return true;
}
```

### 7.2 효과 적용 함수

```gml
/// @func apply_effect(caster, targets, effect)
/// @desc 효과 적용
function apply_effect(caster, targets, effect) {
    switch(effect.type) {
        // 기본
        case "damage":      apply_damage(caster, targets, effect); break;
        case "heal":        apply_heal(caster, targets, effect); break;
        case "buff":        apply_buff(caster, targets, effect); break;
        case "debuff":      apply_debuff(caster, targets, effect); break;
        case "shield":      apply_shield(caster, targets, effect); break;

        // 해제
        case "cleanse":     apply_cleanse(targets, effect); break;
        case "dispel":      apply_dispel(targets, effect); break;

        // CC
        case "stun":        apply_cc(targets, "stun", effect); break;
        case "silence":     apply_cc(targets, "silence", effect); break;
        case "slow":        apply_cc(targets, "slow", effect); break;
        case "root":        apply_cc(targets, "root", effect); break;
        case "fear":        apply_cc(targets, "fear", effect); break;
        case "taunt":       apply_cc(targets, "taunt", effect); break;

        // 위치
        case "displace":    apply_displace(caster, targets, effect); break;
        case "teleport":    apply_teleport(caster, targets, effect); break;

        // 스택
        case "apply_stack":     apply_stack(caster, targets, effect); break;
        case "consume_stacks":  consume_stacks(caster, targets, effect); break;

        // 조건부
        case "conditional": apply_conditional(caster, targets, effect); break;
        case "chance":      apply_chance(caster, targets, effect); break;

        // 범위
        case "aoe":         apply_aoe(caster, targets, effect); break;
        case "chain":       apply_chain(caster, targets, effect); break;
    }
}
```

### 7.3 타겟팅 함수

```gml
/// @func get_targets(caster, targeting)
/// @desc 타겟 획득
function get_targets(caster, targeting) {
    var pool = [];

    // 1. 기본 풀 생성
    switch(targeting.base) {
        case "self":    pool = [caster]; break;
        case "ally":    pool = get_all_allies(caster.team); break;
        case "enemy":   pool = get_all_enemies(caster.team); break;
        case "all":     pool = get_all_units(); break;
        case "corpse":  pool = get_all_corpses(); break;
    }

    // 2. 필터 적용
    if (variable_struct_exists(targeting, "filters")) {
        for (var i = 0; i < array_length(targeting.filters); i++) {
            pool = apply_filter(pool, targeting.filters[i], caster);
        }
    }

    // 3. 선택
    var select = targeting.select ?? "nearest";
    var count = targeting.count ?? 1;
    pool = select_targets(pool, select, count, caster);

    return pool;
}
```

### 7.4 태그 기반 해제

```gml
/// @func apply_cleanse(targets, effect)
function apply_cleanse(targets, effect) {
    var required_tags = effect.target_tags;
    var max_count = effect.count ?? 99;

    for (var i = 0; i < array_length(targets); i++) {
        var unit = targets[i];
        var removed = 0;

        for (var j = array_length(unit.active_effects) - 1; j >= 0; j--) {
            var eff = unit.active_effects[j];

            if (has_all_tags(eff.tags, required_tags)) {
                array_delete(unit.active_effects, j, 1);
                removed++;
                if (removed >= max_count) break;
            }
        }
    }
}

/// @func has_all_tags(target_tags, required_tags)
function has_all_tags(target_tags, required_tags) {
    for (var i = 0; i < array_length(required_tags); i++) {
        if (!array_contains(target_tags, required_tags[i])) {
            return false;
        }
    }
    return true;
}
```

---

## 스킬 예시 모음

### 기본 스킬

```gml
// 화염구
skill_fireball = {
    id: "fireball",
    name: "화염구",
    mana_cost: 50,
    targeting: { base: "enemy", select: "nearest", count: 1 },
    effects: [
        { type: "damage", amount: 200, damage_type: "fire" },
        { type: "aoe", radius: 1, effects: [
            { type: "damage", amount: 100, damage_type: "fire" }
        ]}
    ]
}

// 치유
skill_heal = {
    id: "heal",
    name: "치유의 손길",
    mana_cost: 40,
    targeting: { base: "ally", select: "lowest_hp", count: 1 },
    effects: [
        { type: "heal", amount: 300 }
    ]
}

// 전투 함성
skill_warcry = {
    id: "warcry",
    name: "전투 함성",
    mana_cost: 80,
    targeting: { base: "ally", select: "all" },
    effects: [
        { type: "buff", stat: "attack", value: 30, duration: 5,
          tags: ["buff", "physical", "dispellable"] }
    ]
}

// 처형
skill_execute = {
    id: "execute",
    name: "처형",
    mana_cost: 60,
    targeting: { base: "enemy", select: "lowest_hp", count: 1 },
    effects: [
        { type: "conditional",
          condition: { target_hp_percent: "<", value: 25 },
          then_effects: [
              { type: "damage", amount: 9999, damage_type: "true" }
          ],
          else_effects: [
              { type: "damage", amount: 200 }
          ]
        }
    ]
}

// 정화
skill_cleanse = {
    id: "cleanse",
    name: "정화",
    mana_cost: 40,
    targeting: { base: "ally", select: "most_debuffs", count: 1 },
    effects: [
        { type: "cleanse", target_tags: ["debuff", "cc"], count: 99 },
        { type: "buff", stat: "cc_resist", value: 100, duration: 2,
          tags: ["buff", "undispellable"] }
    ]
}
```
