# 전투 시스템

> 전투 흐름, 출전, 웨이브, 타일/지형, 오브, 딜레이, 미러매치 시스템

---

## 목차

1. [전투 흐름](#1-전투-흐름)
2. [웨이브 시스템](#2-웨이브-시스템)
   - 2.1 웨이브 구조
   - 2.2 웨이브 타입
   - 2.3 웨이브 이벤트
   - 2.4 보스 웨이브 예시
   - 2.5 몬스터 AI 및 경로
3. [타일/지형 시스템](#3-타일지형-시스템)
4. [오브(Orb) 시스템](#4-오브orb-시스템)
5. [딜레이 스킬 시스템](#5-딜레이-스킬-시스템)
6. [미러매치 시스템](#6-미러매치-시스템)
7. [구현 가이드](#7-구현-가이드)

---

## 1. 전투 흐름

### 1.1 전투 시작 프로세스

```
┌─────────────────────────────────────────────────────────────┐
│                      전투 시작 흐름                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [웨이브 시작]                                              │
│       ↓                                                     │
│  [건물 버프 계산] → 각 건물의 주둔 유닛에게 버프 적용        │
│       ↓                                                     │
│  [유닛 출전] → 딜레이에 따라 순차적으로 전장에 배치          │
│       ↓                                                     │
│  [출전 위치 배치] → 유닛별 설정된 위치(FL/FC/FR 등)로 이동  │
│       ↓                                                     │
│  [전투 시작] → AI 활성화, 적 스폰 시작                      │
│       ↓                                                     │
│  [전투 진행] → 자동 전투                                    │
│       ↓                                                     │
│  [웨이브 종료] → 보상 지급, 유닛 복귀                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 전장 구조

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

                   [ 왕국 영지 ]
```

> 출전 위치 상세는 [UNIT_SYSTEM.md - 출전 위치 시스템](./UNIT_SYSTEM.md#3-출전-위치-시스템) 참조

### 1.3 전투 시작 함수

```gml
/// @function battle_start(wave_data)
function battle_start(wave_data) {
    // 1. 전투 상태 초기화
    global.battle_state = {
        wave: wave_data,
        phase: "deploying",
        allies: [],
        enemies: [],
        corpses: [],
        elapsed_time: 0
    };

    // 2. 건물 버프 계산 및 유닛 출전
    battle_deploy_all_units();

    // 3. 성문 HP 설정
    global.gate_hp = global.gate_max_hp;

    // 4. 웨이브 스폰 시작
    call_later(2000, function() {
        global.battle_state.phase = "combat";
        wave_start_spawning(wave_data);
    });
}

/// @function battle_deploy_all_units()
function battle_deploy_all_units() {
    var deploy_queue = [];

    // 모든 전투 건물에서 유닛 수집
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
                buffs: building_get_garrison_buffs(building)
            });
        }
    }

    // 딜레이순 정렬 및 출전
    array_sort(deploy_queue, function(a, b) {
        return a.delay - b.delay;
    });

    for (var i = 0; i < array_length(deploy_queue); i++) {
        schedule_unit_deploy(deploy_queue[i]);
    }
}
```

### 1.4 성문 시스템

```gml
/// 성문 구조
gate = {
    hp: 1000,
    max_hp: 1000,
    defense: 50,
    regen: 0,               // 웨이브 간 회복량

    // 상태
    is_destroyed: false,

    // 파괴 시 효과
    on_destroy: {
        effect: "game_over",
        message: "성문이 파괴되었습니다!"
    }
}

/// 성문 피해 처리
function gate_take_damage(amount) {
    var actual = max(0, amount - global.gate.defense);
    global.gate.hp -= actual;

    if (global.gate.hp <= 0) {
        global.gate.is_destroyed = true;
        trigger_game_over();
    }
}
```

### 1.5 전투 종료

```gml
/// @function battle_end(result)
function battle_end(result) {
    global.battle_state.phase = "ended";

    if (result == "victory") {
        // 보상 계산
        var rewards = wave_calculate_rewards(
            global.battle_state.wave,
            get_battle_performance()
        );

        // 보상 지급
        apply_rewards(rewards);

        // 유닛 복귀
        for (var i = 0; i < array_length(global.battle_state.allies); i++) {
            var unit = global.battle_state.allies[i];
            unit_return_to_garrison(unit);
        }

        // 성문 회복
        global.gate.hp = min(global.gate.max_hp,
                            global.gate.hp + global.gate.regen);
    }
}

/// @function get_battle_performance()
function get_battle_performance() {
    return {
        monsters_killed: global.battle_state.monsters_killed,
        boss_killed: global.battle_state.boss_killed,
        total_damage_taken: global.battle_state.total_damage_taken,
        units_lost: global.battle_state.units_lost,
        clear_time: global.battle_state.elapsed_time,
        no_damage: global.battle_state.total_damage_taken == 0
    };
}
```

---

## 2. 웨이브 시스템

### 2.1 웨이브 구조

```gml
wave = {
    wave_number: 5,
    wave_type: "normal",

    // 스폰 정보 (ai_type 지정 가능)
    spawns: [
        { unit_type: "goblin", count: 10, delay: 0, interval: 0.5, ai_type: "ai_rush" },
        { unit_type: "orc", count: 5, delay: 3, interval: 1, ai_type: "ai_rush" },
        { unit_type: "skeleton_archer", count: 3, delay: 5, interval: 1, ai_type: "ai_ranged" },
        { unit_type: "troll", count: 2, delay: 8, interval: 2, ai_type: "ai_rush" }
    ],

    // 스폰 위치
    spawn_points: ["north", "east"],
    spawn_pattern: "sequential",        // "sequential", "random", "all_at_once"

    // 웨이브 버프
    modifiers: [
        { type: "speed_boost", value: 20 },
        { type: "armor_boost", value: 10 }
    ],

    // 보상
    rewards: {
        gold: 100,
        exp: 50,
        items: [{ item: "health_potion", chance: 30 }]
    },

    next_wave_delay: 15
}
```

### 2.2 웨이브 타입

| 타입 | 설명 | 특징 |
|------|------|------|
| `normal` | 일반 | 기본 몬스터 구성 |
| `elite` | 정예 | 강화 몬스터, 높은 보상 |
| `boss` | 보스 | 보스(ai_boss) + 호위 몬스터 |
| `swarm` | 대군 | 약한 몬스터 대량 |
| `ambush` | 기습 | 다방향 동시 스폰 |
| `siege` | 공성 | 건물 공격 유닛 포함 |
| `mirror` | 미러 | 플레이어 유닛 복제 |

### 2.3 웨이브 이벤트

```gml
wave_events = {
    on_wave_start: {
        trigger: "wave_start",
        wave_number: 10,
        effects: [
            { type: "spawn_boss", boss: "demon_lord" },
            { type: "global_buff", stat: "attack", value: 20, target: "all_allies" },
            { type: "play_cutscene", cutscene: "boss_intro" }
        ]
    },

    on_wave_clear: {
        trigger: "wave_clear",
        effects: [
            { type: "heal_all_allies", percent: 20 },
            { type: "grant_gold", amount: 50 },
            { type: "refresh_skills" }
        ]
    },

    on_enemy_reach_goal: {
        trigger: "enemy_at_goal",
        effects: [
            { type: "damage_base", amount: 1 },
            { type: "despawn_enemy" }
        ]
    }
}
```

### 2.4 보스 웨이브 예시

```gml
wave_boss_demon_lord = {
    wave_number: 10,
    wave_type: "boss",

    spawns: [
        // 호위 몬스터 (ai_rush)
        { unit_type: "demon_guard", count: 4, delay: 0, interval: 1, ai_type: "ai_rush" },
        // 원거리 지원 (ai_ranged)
        { unit_type: "imp", count: 6, delay: 2, interval: 0.5, ai_type: "ai_ranged" },
        // 보스 (ai_boss) - 페이즈 기반
        { unit_type: "demon_lord", count: 1, delay: 5, interval: 0, ai_type: "ai_boss" }
    ],

    // 보스 페이즈 정의
    boss_phases: {
        phase1: { hp_threshold: 100, skills: ["skill_slash", "skill_fire_breath"] },
        phase2: { hp_threshold: 60, skills: ["skill_aoe_slam"], spawn_adds: true },
        phase3: { hp_threshold: 30, skills: ["skill_ultimate"], enrage: true }
    },

    rewards: {
        gold: 500,
        exp: 200,
        items: [{ item: "demon_essence", chance: 100 }]
    }
}
```

### 2.5 몬스터 AI 및 경로

> 적 AI는 단순하게 설계. 플레이어가 패턴을 파악하고 전술로 대응할 수 있어야 함.

#### 적 AI 타입 (3가지)

| AI 타입 | 행동 패턴 | 적용 대상 | 플레이어 대응 |
|---------|----------|----------|--------------|
| `ai_rush` | 가장 가까운 적 돌진 | 좀비, 고블린, 오크, 늑대 | 탱커로 유인 |
| `ai_ranged` | 거리 유지, 원거리 공격 | 궁수, 마법사, 임프 | 암살자로 침투 |
| `ai_boss` | 페이즈별 패턴 (HP 기반) | 보스 몬스터 | 패턴 숙지 |

> 상세 AI 로직은 [UNIT_SYSTEM.md - 4.2 적 AI](./UNIT_SYSTEM.md#42-적-ai-단순) 참조

#### 경로 탐색

```gml
monster_pathing = {
    default_behavior: "move_to_goal",
    path_type: "shortest",              // "shortest", "random", "avoid_danger"
    on_blocked: "attack_blocker",       // "attack_blocker", "wait", "find_alt_path"
    aggro_range: 3,

    // ai_rush: priority_targets 무시, 가장 가까운 적만 추적
    // ai_ranged: 거리 유지하며 사거리 내 적 공격
    // ai_boss: 위협도(threat) 기반 타겟 선정

    priority_targets: [
        { type: "unit", role: "healer", weight: 100 },
        { type: "building", building_type: "wall", weight: 50 },
        { type: "goal", weight: 30 }
    ]
}
```

#### 스폰 시 AI 할당

```gml
/// @function spawn_enemy(spawn_data)
function spawn_enemy(spawn_data) {
    var enemy = create_unit(spawn_data.unit_type, spawn_pos.x, spawn_pos.y);
    enemy.team = "enemy";

    // AI 타입 할당 (스폰 데이터에서 지정, 없으면 유닛 기본값)
    enemy.ai_type = spawn_data.ai_type ?? enemy.default_ai_type ?? "ai_rush";

    array_push(global.battle_state.enemies, enemy);
    global.wave_enemies_remaining++;

    return enemy;
}
```

---

## 3. 타일/지형 시스템

### 3.1 타일 구조

```gml
tile = {
    x: 3,
    y: 5,

    // 기본 지형
    terrain: "grass",

    // 현재 효과들
    active_effects: [],

    // 오브젝트
    object: null,
    object_data: {},

    // 속성
    walkable: true,
    flyable: true,
    blocks_projectile: false,

    // 태그
    tags: ["natural", "outdoor"],

    // 높이
    elevation: 0
}
```

### 3.2 지형 타입

```gml
terrain_grass = {
    name: "초원",
    walkable: true,
    movement_cost: 1,
    tags: ["natural", "outdoor"],
    on_enter: [],
    on_stay: [],
    modifiers: {}
}

terrain_water = {
    name: "물",
    walkable: false,
    walkable_for_tags: ["aquatic", "flying"],
    movement_cost: 2,
    tags: ["natural", "wet"],
    on_enter: [
        { type: "cleanse", target_tags: ["fire", "burning"] }
    ],
    on_stay: [
        { type: "debuff", stat: "attack_speed", value: -20 }
    ],
    modifiers: {
        fire_damage_received: -50,
        electric_damage_received: 50
    }
}

terrain_lava = {
    name: "용암",
    walkable: false,
    walkable_for_tags: ["fire_immune", "flying"],
    tags: ["hazard", "fire"],
    on_stay: [
        { type: "damage", amount: 100, damage_type: "fire", tick_rate: 1 }
    ]
}

terrain_ice = {
    name: "얼음",
    walkable: true,
    movement_cost: 0.5,
    tags: ["slippery", "cold"],
    on_enter: [
        { type: "slide", direction: "momentum", distance: 1 }
    ],
    modifiers: { dodge_chance: -20 }
}

terrain_void = {
    name: "구멍",
    walkable: false,
    walkable_for_tags: ["flying"],
    on_enter: [
        { type: "instant_death" }
    ]
}
```

### 3.3 타일 효과 (장판)

```gml
tile_effect_fire = {
    name: "불바닥",
    duration: 5,
    visual: "spr_fire_ground",
    tags: ["fire", "hazard", "magic"],

    on_enter: [
        { type: "damage", amount: 50, damage_type: "fire" }
    ],
    on_stay: [
        { type: "damage", amount: 30, damage_type: "fire", tick_rate: 1 }
    ],

    // 다른 효과와 상호작용
    interactions: {
        ice_ground: "cancel_both",
        oil_ground: "explode",
        water_ground: "create_steam"
    }
}

tile_effect_ice = {
    name: "얼음 장판",
    duration: 8,
    tags: ["ice", "slow", "magic"],
    on_enter: [
        { type: "debuff", stat: "movement_speed", value: -40, duration: 2 }
    ],
    modifiers: { fire_damage_received: -30 },
    interactions: { fire_ground: "cancel_both" }
}

tile_effect_poison = {
    name: "독구름",
    duration: 6,
    tags: ["poison", "gas", "blocks_vision"],
    blocks_vision: true,
    on_stay: [
        { type: "apply_stack", stack_id: "poison", amount: 1, tick_rate: 1 }
    ],
    interactions: { wind_gust: "disperse" }
}

tile_effect_heal = {
    name: "치유의 샘",
    duration: 10,
    tags: ["heal", "buff", "sacred"],
    on_stay: [
        { type: "heal", percent: 5, tick_rate: 1, target_filter: ["ally"] }
    ]
}
```

### 3.4 타일 오브젝트

```gml
object_wall = {
    name: "벽",
    hp: 500,
    destructible: true,
    blocks_movement: true,
    blocks_projectile: true,
    blocks_vision: true,
    on_destroy: []
}

object_trap = {
    name: "함정",
    visible_to: "owner",
    trigger: "enemy_enter",
    one_time: true,
    on_trigger: [
        { type: "damage", amount: 200 },
        { type: "root", duration: 2 }
    ]
}

object_totem = {
    name: "토템",
    hp: 300,
    team: "caster",
    aura_radius: 2,
    aura_effects: [
        { type: "buff", stat: "attack", value: 20, target_filter: ["ally"] }
    ],
    duration: 10
}

object_turret = {
    name: "포탑",
    hp: 400,
    team: "caster",
    attack_range: 3,
    attack_damage: 80,
    attack_speed: 1.0,
    target_priority: "nearest_enemy",
    duration: 15
}

object_barrel = {
    name: "폭발 배럴",
    hp: 100,
    destructible: true,
    on_destroy: [
        { type: "aoe", radius: 1, effects: [
            { type: "damage", amount: 300, damage_type: "fire" }
        ]},
        { type: "create_tile_effect", effect: "fire_ground", radius: 1, duration: 3 }
    ]
}
```

### 3.5 지형 조작 효과

```gml
// 지형 변환
effect_terraform = {
    type: "change_terrain",
    from: "water",
    to: "ice",
    radius: 2,
    duration: 10,
    revert_after: true
}

// 장판 생성
effect_create_zone = {
    type: "create_tile_effect",
    effect: "fire_ground",
    shape: "circle",
    radius: 2,
    duration: 5,
    position: "target",
    interact_with_existing: true
}

// 오브젝트 설치
effect_place = {
    type: "place_object",
    object: "turret",
    position: "target_tile",
    inherit_stats: true,
    stat_scale: 0.5
}

// 오브젝트 파괴
effect_destroy = {
    type: "destroy_tile_object",
    target_tags: ["destructible"],
    radius: 2,
    trigger_on_destroy: true
}
```

---

## 4. 오브(Orb) 시스템

### 4.1 오브 구조

```gml
orb = {
    id: "fire_orb",
    name: "화염 오브",

    // 시각적
    visual: "spr_orb_fire",
    rotation_speed: 60,
    orbit_radius: 32,

    // 최대 보유
    max_orbs: 4,

    // 패시브 (상시)
    passive_effects: [
        { type: "buff", stat: "spell_power", value: 10 }
    ],

    // 패시브 (스택)
    passive_per_orb: [
        { type: "buff", stat: "fire_damage", value: 5 }
    ],

    // 발동 (소모)
    on_evoke: {
        consume: 1,
        effects: [
            { type: "damage", amount: 150, damage_type: "fire" }
        ]
    },

    // 자동 발동
    auto_evoke: {
        trigger: "on_hit_received",
        chance: 30,
        effects: [
            { type: "damage", amount: 50, target: "attacker" }
        ]
    },

    // 획득 조건
    gain_condition: {
        trigger: "on_fire_kill",
        chance: 100,
        max_per_trigger: 1
    }
}
```

### 4.2 오브 타입

```gml
// 방어 오브
orb_frost = {
    id: "frost_orb",
    max_orbs: 6,
    passive_per_orb: [
        { type: "buff", stat: "defense", value: 5 }
    ],
    on_evoke: {
        consume: 1,
        effects: [{ type: "shield", amount: 100, duration: 5 }]
    },
    auto_evoke: {
        trigger: "on_hp_below",
        threshold: 50,
        consume_all: true,
        effects: [
            { type: "shield", amount_per_orb: 50 },
            { type: "freeze_nearby_enemies", radius: 2, duration: 2 }
        ]
    }
}

// 공격 오브
orb_lightning = {
    id: "lightning_orb",
    max_orbs: 10,
    passive_per_orb: [
        { type: "buff", stat: "attack_speed", value: 3 }
    ],
    on_max_orbs: {
        consume_all: true,
        effects: [
            { type: "chain_lightning", targets: 5, damage: 200 }
        ]
    },
    gain_condition: { trigger: "on_basic_attack", chance: 50 }
}

// 힐링 오브
orb_nature = {
    id: "nature_orb",
    max_orbs: 5,
    passive_per_orb: [
        { type: "hot", heal: 5, tick_rate: 1 }
    ],
    on_evoke: {
        consume: 3,
        effects: [
            { type: "heal", target: "lowest_hp_ally", percent: 30 }
        ]
    },
    gain_condition: { trigger: "on_heal_cast", amount: 1 }
}

// 영혼 오브
orb_soul = {
    id: "soul_orb",
    max_orbs: 3,
    on_evoke: {
        consume: 1,
        effects: [
            { type: "link", target: "ally", link_type: "damage_share",
              percent: 30, duration: 10 }
        ]
    },
    gain_condition: { trigger: "on_ally_death_nearby", range: 5 }
}
```

### 4.3 오브 스킬 연동

```gml
// 오브 소모 스킬
skill_orb_barrage = {
    name: "오브 난사",
    mana_cost: 50,
    requires: { orb_count: 3 },
    effects: [
        { type: "consume_orbs", count: "all",
          per_orb_effect: [{ type: "projectile", damage: 100 }] }
    ]
}

// 오브 생성 스킬
skill_conjure = {
    name: "오브 소환",
    mana_cost: 80,
    effects: [
        { type: "grant_orbs", orb_type: "fire_orb", count: 3 }
    ]
}
```

---

## 5. 딜레이 스킬 시스템

### 5.1 딜레이 스킬 구조

```gml
skill_meteor = {
    name: "운석 낙하",
    mana_cost: 100,

    delay: 3.0,
    show_warning: true,
    warning_visual: "spr_meteor_warning",
    warning_sound: "sfx_incoming",

    lock_target_position: true,
    cancelable: false,
    cancel_refund_percent: 50,

    during_delay: [
        { type: "slow", target: "enemies_in_area", value: 20 }
    ],

    effects: [
        { type: "damage", amount: 800, damage_type: "fire" },
        { type: "create_tile_effect", effect: "fire_ground", duration: 5 }
    ]
}
```

### 5.2 딜레이 타입

```gml
// 충전형
skill_charge = {
    name: "집중 사격",
    cast_type: "charge",
    min_charge: 0.5,
    max_charge: 3.0,
    charge_scaling: {
        damage: { base: 100, per_second: 100 },
        range: { base: 3, per_second: 1 },
        aoe_radius: { base: 0, per_second: 0.5 }
    },
    while_charging: {
        movement: "disabled",
        can_be_interrupted: true,
        take_extra_damage: 20
    }
}

// 연속 발동형
skill_barrage = {
    name: "포격 지원",
    mana_cost: 150,
    delay: 1.0,
    repeat_count: 5,
    per_hit_effects: [
        { type: "damage", amount: 150 },
        { type: "stun", duration: 0.5, chance: 30 }
    ],
    position_variation: { type: "random_in_radius", radius: 2 }
}

// 예언형
skill_prophecy = {
    name: "멸망의 예언",
    mana_cost: 200,
    delay_type: "conditional",
    delay_condition: {
        type: "enemy_hp_below",
        threshold: 30,
        target: "marked_enemy"
    },
    max_delay: 30,
    effects: [
        { type: "execute", damage_type: "true" }
    ],
    on_timeout: [
        { type: "damage", amount: 500 }
    ]
}
```

### 5.3 딜레이 상호작용

```gml
// 딜레이 가속
effect_accelerate = {
    type: "modify_delayed_skills",
    target: "caster",
    speed_multiplier: 2.0,
    duration: 5
}

// 딜레이 취소
skill_counterspell = {
    name: "주문 방해",
    effects: [
        { type: "cancel_delayed_skills", target: "enemy", range: 5, refund: false }
    ]
}

// 딜레이 복제
skill_echo = {
    name: "주문 반향",
    effects: [
        { type: "copy_delayed_skill", target: "last_ally_delayed", delay_modifier: 0.5 }
    ]
}
```

---

## 6. 미러매치 시스템

### 6.1 유닛 복제

```gml
skill_mirror_image = {
    name: "거울상",
    mana_cost: 100,
    targeting: { base: "enemy", select: "nearest", count: 1 },
    effects: [
        { type: "create_mirror",
          copy_stats: true,
          stat_modifier: 0.7,
          copy_skills: true,
          copy_items: false,
          duration: 20,
          team: "caster",
          max_mirrors: 1,
          replace_existing: true,
          mirror_traits: {
              takes_double_damage: true,
              no_drops: true,
              fades_on_original_death: true
          }
        }
    ]
}
```

### 6.2 능력 복제

```gml
// 스킬 복제
skill_learn = {
    name: "학습",
    mana_cost: 150,
    effects: [
        { type: "copy_skill",
          skill_filter: "last_used",
          duration: -1,
          replace_slot: 3,
          power_modifier: 0.8 }
    ]
}

// 패시브 복제
skill_absorb = {
    name: "정수 흡수",
    trigger: "on_kill",
    effects: [
        { type: "copy_passive",
          from: "killed_enemy",
          passive_filter: "random",
          duration: 60,
          max_copied: 3 }
    ]
}
```

### 6.3 형태 복제

```gml
skill_doppelganger = {
    name: "도플갱어",
    mana_cost: 200,
    targeting: { base: "unit", count: 1 },
    effects: [
        { type: "transform_into_copy",
          duration: 30,
          copy_appearance: true,
          copy_stats: true,
          copy_skills: true,
          copy_role: true,
          keep_hp_percent: true,
          keep_team: true,
          on_revert: [{ type: "stun", duration: 1 }]
        }
    ]
}
```

### 6.4 미러 웨이브

```gml
wave_mirror = {
    wave_type: "mirror",
    description: "당신의 유닛들이 적으로 나타납니다",
    spawn_rule: {
        type: "copy_player_units",
        stat_modifier: 0.8,
        copy_positions: true,
        copy_items: false
    },
    special_rules: {
        no_friendly_fire: true,
        original_vs_mirror_bonus: 50
    }
}
```

### 6.5 미러 패시브

```gml
// 데미지 반사
passive_mirror_shield = {
    name: "거울 방패",
    trigger: "on_hit_received",
    chance: 20,
    effects: [
        { type: "reflect_damage", percent: 100, damage_type: "same" },
        { type: "negate_damage" }
    ]
}

// 스킬 반사
passive_spell_mirror = {
    name: "주문 반사",
    trigger: "on_skill_received",
    condition: { skill_type: "projectile" },
    chance: 30,
    effects: [
        { type: "reflect_skill", target: "caster", power_modifier: 1.0 }
    ]
}

// 사후 복제
passive_death_mirror = {
    name: "사후 복제",
    trigger: "on_death",
    effects: [
        { type: "create_mirror", copy_from: "self", stat_modifier: 0.5,
          duration: 10, team: "same" }
    ]
}
```

---

## 7. 구현 가이드

### 7.1 웨이브 관리

```gml
/// @func start_wave(wave_data)
function start_wave(wave_data) {
    global.current_wave = wave_data;
    global.wave_enemies_remaining = 0;

    // 웨이브 버프 적용
    for (var i = 0; i < array_length(wave_data.modifiers); i++) {
        apply_wave_modifier(wave_data.modifiers[i]);
    }

    // 스폰 스케줄링
    for (var i = 0; i < array_length(wave_data.spawns); i++) {
        var spawn = wave_data.spawns[i];
        schedule_spawns(spawn);
    }

    trigger_event("on_wave_start", wave_data);
}

/// @func check_wave_clear()
function check_wave_clear() {
    if (global.wave_enemies_remaining <= 0) {
        trigger_event("on_wave_clear", global.current_wave);
        grant_wave_rewards(global.current_wave.rewards);
        schedule_next_wave(global.current_wave.next_wave_delay);
    }
}
```

### 7.2 타일 효과 처리

```gml
/// @func process_tile_effects()
function process_tile_effects() {
    for (var i = 0; i < array_length(global.tiles); i++) {
        var tile = global.tiles[i];

        // 타일 위 유닛 처리
        var units = get_units_at(tile.x, tile.y);
        for (var j = 0; j < array_length(units); j++) {
            // 지형 효과
            apply_terrain_stay(tile.terrain, units[j]);

            // 장판 효과
            for (var k = 0; k < array_length(tile.active_effects); k++) {
                apply_tile_effect_stay(tile.active_effects[k], units[j]);
            }
        }

        // 장판 지속시간 감소
        update_tile_effects(tile);
    }
}

/// @func check_tile_interactions(tile, new_effect)
function check_tile_interactions(tile, new_effect) {
    for (var i = array_length(tile.active_effects) - 1; i >= 0; i--) {
        var existing = tile.active_effects[i];
        var interaction = get_interaction(existing.type, new_effect.type);

        if (interaction != undefined) {
            handle_interaction(tile, existing, new_effect, interaction);
        }
    }
}
```

### 7.3 오브 관리

```gml
/// @func update_orbs(unit)
function update_orbs(unit) {
    // 패시브 효과 적용
    for (var i = 0; i < array_length(unit.orbs); i++) {
        var orb = unit.orbs[i];
        apply_orb_passive(unit, orb);
    }

    // 자동 발동 체크
    check_orb_auto_evoke(unit);

    // 최대 스택 체크
    check_orb_max_stack(unit);
}

/// @func evoke_orbs(unit, count)
function evoke_orbs(unit, count) {
    var orbs_to_consume = min(count, array_length(unit.orbs));
    var effects = [];

    for (var i = 0; i < orbs_to_consume; i++) {
        var orb = unit.orbs[0];
        array_concat(effects, orb.on_evoke.effects);
        array_delete(unit.orbs, 0, 1);
    }

    apply_effects(unit, effects);
}
```

### 7.4 딜레이 스킬 관리

```gml
/// @func schedule_delayed_skill(caster, skill, target_pos)
function schedule_delayed_skill(caster, skill, target_pos) {
    var delayed = {
        caster: caster,
        skill: skill,
        target_pos: target_pos,
        remaining: skill.delay,
        warning_shown: false
    };

    if (skill.show_warning) {
        create_warning_vfx(target_pos, skill.warning_visual, skill.delay);
    }

    array_push(global.delayed_skills, delayed);
}

/// @func update_delayed_skills(delta_time)
function update_delayed_skills(delta_time) {
    for (var i = array_length(global.delayed_skills) - 1; i >= 0; i--) {
        var delayed = global.delayed_skills[i];
        delayed.remaining -= delta_time;

        if (delayed.remaining <= 0) {
            execute_delayed_skill(delayed);
            array_delete(global.delayed_skills, i, 1);
        }
    }
}
```

### 7.5 미러 생성

```gml
/// @func create_mirror(original, effect)
function create_mirror(original, effect) {
    var mirror = create_unit(original.type, original.x, original.y);

    if (effect.copy_stats) {
        copy_stats(mirror, original, effect.stat_modifier);
    }

    if (effect.copy_skills) {
        mirror.skills = array_copy(original.skills);
    }

    mirror.team = effect.team == "caster" ? original.team : get_opposite_team(original.team);
    mirror.is_mirror = true;
    mirror.mirror_original = original.id;
    mirror.mirror_duration = effect.duration;

    if (effect.mirror_traits.takes_double_damage) {
        apply_buff(mirror, { stat: "damage_taken", value: 100 });
    }

    return mirror;
}
```
