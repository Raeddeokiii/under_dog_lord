# 탐험 시스템

> 미개척 영역 탐험, 탐험대 운영, 주둔지 건설

---

## 목차

1. [월드 구조](#1-월드-구조)
2. [탐험대 시스템](#2-탐험대-시스템)
3. [스테미나 시스템](#3-스테미나-시스템)
4. [주둔지 시스템](#4-주둔지-시스템)
5. [탐험 보상](#5-탐험-보상)
6. [구현 가이드](#6-구현-가이드)

---

## 1. 월드 구조

### 1.1 영역 개요

```
                    ┌─────────────────────────────┐
                    │                             │
                    │        심연의 경계           │
                    │     (몬스터 웨이브 출현)      │
                    │                             │
                    └──────────────┬──────────────┘
                                   │
                                   ▼
    ┌───────────────┐    ┌─────────────────┐    ┌───────────────┐
    │               │    │                 │    │               │
    │   미개척 영역  │◄───│    왕국 영지     │───►│   미개척 영역  │
    │     (서쪽)    │    │      (성)       │    │     (동쪽)    │
    │    ░░░░░░░    │    │                 │    │    ░░░░░░░    │
    │   [안개]      │    └────────┬────────┘    │   [안개]      │
    └───────────────┘             │             └───────────────┘
                                  │
                                  ▼
                    ┌─────────────────────────────┐
                    │                             │
                    │         미개척 영역          │
                    │           (남쪽)            │
                    │          ░░░░░░░            │
                    │          [안개]             │
                    └─────────────────────────────┘
```

### 1.2 영역 정의

| 영역 | 방향 | 설명 | 주요 콘텐츠 |
|------|------|------|------------|
| **심연의 경계** | 북쪽 | 몬스터 웨이브 출현지 | 웨이브 디펜스, 보스 |
| **왕국 영지** | 중앙 | 플레이어 본거지 | 건물, 유닛 주둔, 성문 |
| **미개척 영역** | 동/서/남 | 안개로 둘러싸인 미지의 땅 | 탐험, 자원, 던전 |

### 1.3 영역 데이터 구조

```gml
/// 월드 영역 정의
world_regions = {
    abyss_border: {
        id: "abyss_border",
        name: "심연의 경계",
        direction: "north",
        type: "hostile",

        // 몬스터 웨이브 관련
        wave_spawn_enabled: true,
        ambient_danger: 100,        // 기본 위험도

        // 탐험 불가
        explorable: false
    },

    kingdom: {
        id: "kingdom",
        name: "왕국 영지",
        direction: "center",
        type: "safe",

        // 본거지 기능
        is_home_base: true,
        full_stamina_recovery: true,

        explorable: false
    },

    unexplored_east: {
        id: "unexplored_east",
        name: "동쪽 미개척 영역",
        direction: "east",
        type: "fog",

        // 탐험 관련
        explorable: true,
        fog_density: 100,           // 안개 밀도 (탐험 시 감소)
        discovery_progress: 0,      // 발견 진행도 (0~100%)

        // 콘텐츠
        possible_discoveries: ["resource_node", "dungeon", "ruin", "npc_camp"]
    },

    unexplored_west: {
        id: "unexplored_west",
        name: "서쪽 미개척 영역",
        direction: "west",
        type: "fog",
        explorable: true,
        fog_density: 100,
        discovery_progress: 0,
        possible_discoveries: ["resource_node", "dungeon", "ancient_shrine", "hidden_village"]
    },

    unexplored_south: {
        id: "unexplored_south",
        name: "남쪽 미개척 영역",
        direction: "south",
        type: "fog",
        explorable: true,
        fog_density: 100,
        discovery_progress: 0,
        possible_discoveries: ["resource_node", "dungeon", "merchant_caravan", "monster_nest"]
    }
}
```

---

## 2. 탐험대 시스템

### 2.1 탐험대 구조

```gml
/// 탐험대 정의
expedition = {
    id: 1,
    name: "제1 탐험대",

    // 구성원 (유닛 배열)
    members: [],
    max_members: 4,

    // 상태
    status: "idle",                 // "idle", "exploring", "returning", "resting"
    current_region: "kingdom",
    current_position: { x: 0, y: 0 },

    // 스테미나
    stamina: 100,
    max_stamina: 100,

    // 탐험 진행
    exploration_target: undefined,  // 목표 지역
    distance_traveled: 0,
    discoveries: [],

    // 인벤토리 (탐험 중 획득물)
    inventory: [],
    inventory_capacity: 20
}
```

### 2.2 탐험대 상태

| 상태 | 설명 | 스테미나 변화 |
|------|------|--------------|
| `idle` | 성에서 대기 중 | 자동 회복 |
| `exploring` | 미개척 영역 탐험 중 | 이동 시 소모 |
| `returning` | 성/주둔지로 귀환 중 | 이동 시 소모 |
| `resting` | 성/주둔지에서 휴식 중 | 빠른 회복 |
| `combat` | 탐험 중 전투 발생 | 소모 없음 (전투 후 소모) |

### 2.3 탐험대 생성 및 관리

```gml
/// @function expedition_create(name, members)
function expedition_create(name, members) {
    global.next_expedition_id++;

    var exp = {
        id: global.next_expedition_id,
        name: name,
        members: [],
        max_members: 4,

        status: "idle",
        current_region: "kingdom",
        current_position: { x: global.kingdom_center_x, y: global.kingdom_center_y },

        stamina: 100,
        max_stamina: 100,

        exploration_target: undefined,
        distance_traveled: 0,
        discoveries: [],

        inventory: [],
        inventory_capacity: 20
    };

    // 유닛 추가
    for (var i = 0; i < min(array_length(members), exp.max_members); i++) {
        var unit = members[i];

        // 유닛을 탐험대에 배정
        unit.assigned_to = "expedition";
        unit.expedition_id = exp.id;

        array_push(exp.members, unit);

        // 스테미나 보너스 (특정 유닛 특성)
        if (unit_has_trait(unit, "explorer")) {
            exp.max_stamina += 20;
        }
        if (unit_has_trait(unit, "ranger")) {
            exp.max_stamina += 10;
        }
    }

    exp.stamina = exp.max_stamina;

    array_push(global.expeditions, exp);
    return exp;
}

/// @function expedition_disband(expedition)
function expedition_disband(expedition) {
    // 탐험 중이면 해산 불가
    if (expedition.status != "idle") {
        return { success: false, reason: "expedition_not_idle" };
    }

    // 유닛 해제
    for (var i = 0; i < array_length(expedition.members); i++) {
        var unit = expedition.members[i];
        unit.assigned_to = "none";
        unit.expedition_id = undefined;
    }

    // 인벤토리 아이템 성으로 이동
    transfer_inventory_to_kingdom(expedition.inventory);

    // 탐험대 제거
    array_delete_value(global.expeditions, expedition);

    return { success: true };
}
```

### 2.4 탐험 시작 및 진행

```gml
/// @function expedition_start(expedition, target_region)
function expedition_start(expedition, target_region) {
    // 검증
    if (expedition.status != "idle" && expedition.status != "resting") {
        return { success: false, reason: "expedition_busy" };
    }

    if (array_length(expedition.members) == 0) {
        return { success: false, reason: "no_members" };
    }

    if (expedition.stamina < 10) {
        return { success: false, reason: "insufficient_stamina" };
    }

    var region = world_regions[$ target_region];
    if (region == undefined || !region.explorable) {
        return { success: false, reason: "invalid_region" };
    }

    // 탐험 시작
    expedition.status = "exploring";
    expedition.exploration_target = target_region;
    expedition.distance_traveled = 0;

    trigger_event("on_expedition_start", expedition);

    return { success: true };
}

/// @function expedition_update(expedition, delta_time)
/// @desc 매 프레임 탐험대 상태 업데이트
function expedition_update(expedition, delta_time) {
    switch (expedition.status) {
        case "exploring":
            expedition_process_exploration(expedition, delta_time);
            break;

        case "returning":
            expedition_process_return(expedition, delta_time);
            break;

        case "resting":
            expedition_process_rest(expedition, delta_time);
            break;

        case "idle":
            // 성에서 대기 중 - 느린 스테미나 회복
            expedition_recover_stamina(expedition, delta_time, 0.5);
            break;
    }
}
```

---

## 3. 스테미나 시스템

### 3.1 스테미나 개요

```
┌─────────────────────────────────────────────────────────┐
│                    스테미나 시스템                        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  [이동]  ────────►  스테미나 소모                        │
│                         │                               │
│                         ▼                               │
│                    스테미나 0?                           │
│                    /        \                           │
│                  Yes         No                         │
│                   │           │                         │
│                   ▼           ▼                         │
│           강제 귀환 or     탐험 계속                     │
│           주둔지 휴식                                    │
│                                                         │
│  [휴식]  ────────►  스테미나 회복                        │
│   (성 / 주둔지)                                         │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 3.2 스테미나 수치

| 행동 | 스테미나 변화 | 비고 |
|------|-------------|------|
| 이동 (1칸) | -1 | 기본 소모량 |
| 험지 이동 | -2 | 늪, 산악 등 |
| 전투 후 | -10 | 전투 피로 |
| 발견물 조사 | -5 | 던전, 유적 등 |
| 성에서 휴식 | +10/초 | 최대 회복 |
| 주둔지 휴식 | +5/초 | 주둔지 레벨에 따라 증가 |
| 성에서 대기 | +0.5/초 | 느린 자동 회복 |

### 3.3 스테미나 관련 함수

```gml
/// @function expedition_consume_stamina(expedition, amount)
function expedition_consume_stamina(expedition, amount) {
    expedition.stamina = max(0, expedition.stamina - amount);

    // 스테미나 고갈 시 처리
    if (expedition.stamina <= 0) {
        expedition_on_stamina_depleted(expedition);
    }

    return expedition.stamina;
}

/// @function expedition_recover_stamina(expedition, delta_time, rate)
function expedition_recover_stamina(expedition, delta_time, rate) {
    var recovery = rate * delta_time;
    expedition.stamina = min(expedition.max_stamina, expedition.stamina + recovery);
}

/// @function expedition_on_stamina_depleted(expedition)
function expedition_on_stamina_depleted(expedition) {
    // 근처 주둔지 탐색
    var nearest_outpost = find_nearest_outpost(expedition.current_position);

    if (nearest_outpost != undefined) {
        // 주둔지로 이동 (강제)
        expedition.status = "returning";
        expedition.return_target = nearest_outpost;
        expedition.forced_return = true;

        trigger_event("on_expedition_exhausted", {
            expedition: expedition,
            destination: "outpost",
            outpost: nearest_outpost
        });
    } else {
        // 성으로 귀환 (강제)
        expedition.status = "returning";
        expedition.return_target = "kingdom";
        expedition.forced_return = true;

        // 강제 귀환 페널티 (이동 속도 감소 등)
        expedition.movement_penalty = 0.5;

        trigger_event("on_expedition_exhausted", {
            expedition: expedition,
            destination: "kingdom"
        });
    }
}

/// @function expedition_get_stamina_cost(expedition, terrain_type)
function expedition_get_stamina_cost(expedition, terrain_type) {
    var base_cost = 1;

    // 지형별 비용
    switch (terrain_type) {
        case "plain":
        case "road":
            base_cost = 1;
            break;
        case "forest":
            base_cost = 1.5;
            break;
        case "swamp":
        case "mountain":
            base_cost = 2;
            break;
        case "desert":
            base_cost = 1.8;
            break;
    }

    // 탐험대 특성 보너스
    var reduction = 1.0;
    for (var i = 0; i < array_length(expedition.members); i++) {
        var unit = expedition.members[i];

        if (unit_has_trait(unit, "pathfinder")) {
            reduction -= 0.1;   // 10% 감소
        }
        if (unit_has_trait(unit, "endurance")) {
            reduction -= 0.05;  // 5% 감소
        }
    }

    return max(0.5, base_cost * reduction);
}
```

---

## 4. 주둔지 시스템

### 4.1 주둔지 개요

> 미개척 영역에 건설하여 탐험대의 스테미나 보충 거점으로 활용

```
┌─────────────────────────────────────────────────────────┐
│                      주둔지 기능                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  1. 스테미나 회복 거점                                    │
│     └─ 탐험대가 주둔지에서 휴식하여 스테미나 보충          │
│                                                         │
│  2. 탐험 범위 확장                                        │
│     └─ 주둔지 기준으로 더 먼 곳까지 탐험 가능              │
│                                                         │
│  3. 안개 제거                                            │
│     └─ 주둔지 주변 영구적 시야 확보                       │
│                                                         │
│  4. 자원 수집                                            │
│     └─ 주변 자원 노드 자동 수집 (업그레이드 시)            │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 4.2 주둔지 타입

| 주둔지 | ID | 건설 비용 | 스테미나 회복 | 시야 범위 | 특수 기능 |
|--------|-----|----------|--------------|----------|----------|
| 초소 | `outpost_basic` | 목재 200, 골드 100 | +3/초 | 2칸 | 기본 휴식 |
| 정찰 기지 | `outpost_scout` | 목재 300, 석재 100, 골드 200 | +5/초 | 4칸 | 적 탐지, 빠른 회복 |
| 보급 캠프 | `outpost_supply` | 목재 400, 골드 300 | +4/초 | 3칸 | 인벤토리 +10, 자원 보관 |
| 요새 | `outpost_fortress` | 석재 500, 철 200, 골드 500 | +6/초 | 5칸 | 방어 가능, 유닛 주둔 |

### 4.3 주둔지 데이터 구조

```gml
/// 주둔지 템플릿
outpost_templates = {
    outpost_basic: {
        id: "outpost_basic",
        name: "초소",
        description: "간단한 휴식 거점. 탐험대의 스테미나를 보충할 수 있다.",

        // 건설
        build_cost: { wood: 200, gold: 100 },
        build_time: 30,             // 초

        // 스테미나 회복
        stamina_recovery_rate: 3,   // 초당

        // 시야
        vision_radius: 2,           // 타일 단위
        removes_fog: true,

        // 레벨업
        max_level: 3,
        upgrade_cost_multiplier: 1.5,

        // 레벨별 보너스
        level_bonuses: {
            1: { stamina_recovery_rate: 3, vision_radius: 2 },
            2: { stamina_recovery_rate: 4, vision_radius: 3 },
            3: { stamina_recovery_rate: 5, vision_radius: 4 }
        },

        // 유지비
        upkeep: { gold: 5 },        // 웨이브당

        // 제한
        max_per_region: 3,
        requires_discovery: true    // 해당 지역 발견 후 건설 가능
    },

    outpost_scout: {
        id: "outpost_scout",
        name: "정찰 기지",
        description: "넓은 시야와 빠른 회복을 제공하는 정찰 거점.",

        build_cost: { wood: 300, stone: 100, gold: 200 },
        build_time: 60,

        stamina_recovery_rate: 5,
        vision_radius: 4,
        removes_fog: true,

        max_level: 3,

        // 특수 기능
        features: [
            { type: "enemy_detection", range: 6 },      // 적 조기 탐지
            { type: "discovery_bonus", value: 20 }      // 발견 확률 +20%
        ],

        upkeep: { gold: 10 }
    },

    outpost_supply: {
        id: "outpost_supply",
        name: "보급 캠프",
        description: "탐험대의 물자를 보관하고 보급하는 거점.",

        build_cost: { wood: 400, gold: 300 },
        build_time: 45,

        stamina_recovery_rate: 4,
        vision_radius: 3,
        removes_fog: true,

        max_level: 3,

        features: [
            { type: "inventory_expansion", value: 10 },     // 인벤토리 +10
            { type: "resource_storage", capacity: 100 },    // 자원 보관
            { type: "auto_collect", radius: 2 }             // 주변 자원 자동 수집
        ],

        upkeep: { gold: 8 }
    },

    outpost_fortress: {
        id: "outpost_fortress",
        name: "요새",
        description: "강력한 방어 시설을 갖춘 전초 기지. 유닛을 주둔시킬 수 있다.",

        build_cost: { stone: 500, iron: 200, gold: 500 },
        build_time: 120,

        stamina_recovery_rate: 6,
        vision_radius: 5,
        removes_fog: true,

        max_level: 5,

        features: [
            { type: "garrison", slots: 4 },                 // 유닛 주둔 가능
            { type: "defense", value: 100 },                // 방어력
            { type: "auto_repair", rate: 5 }                // 자동 수리
        ],

        // 적 습격 방어 가능
        can_be_attacked: true,
        hp: 500,
        defense: 50,

        upkeep: { gold: 20 }
    }
};

/// 주둔지 인스턴스
outpost_instance = {
    id: 1,
    template_id: "outpost_basic",
    name: "동쪽 초소",

    // 위치
    region: "unexplored_east",
    position: { x: 150, y: 80 },

    // 상태
    level: 1,
    hp: 100,
    max_hp: 100,
    is_active: true,

    // 현재 휴식 중인 탐험대
    resting_expeditions: [],

    // 보관 자원 (보급 캠프만)
    stored_resources: {},

    // 주둔 유닛 (요새만)
    garrisoned_units: []
}
```

### 4.4 주둔지 건설 및 관리

```gml
/// @function outpost_build(template_id, region, position)
function outpost_build(template_id, region, position) {
    var template = outpost_templates[$ template_id];
    if (template == undefined) {
        return { success: false, reason: "invalid_template" };
    }

    var region_data = world_regions[$ region];
    if (region_data == undefined || !region_data.explorable) {
        return { success: false, reason: "invalid_region" };
    }

    // 발견된 지역인지 확인
    if (template.requires_discovery && region_data.discovery_progress < 100) {
        return { success: false, reason: "region_not_discovered" };
    }

    // 해당 지역 주둔지 수 확인
    var current_count = count_outposts_in_region(region);
    if (current_count >= template.max_per_region) {
        return { success: false, reason: "max_outposts_reached" };
    }

    // 비용 확인
    if (!resource_can_afford(template.build_cost)) {
        return { success: false, reason: "insufficient_resources" };
    }

    // 건설 시작
    resource_spend_multi(template.build_cost);

    global.next_outpost_id++;
    var outpost = {
        id: global.next_outpost_id,
        template_id: template_id,
        name: region_data.name + " " + template.name,

        region: region,
        position: position,

        level: 1,
        hp: template.hp ?? 100,
        max_hp: template.hp ?? 100,
        is_active: false,           // 건설 완료 후 활성화

        build_progress: 0,
        build_complete_time: current_time + template.build_time * 1000,

        resting_expeditions: [],
        stored_resources: {},
        garrisoned_units: []
    };

    array_push(global.outposts, outpost);

    return { success: true, outpost: outpost };
}

/// @function outpost_get_recovery_rate(outpost)
function outpost_get_recovery_rate(outpost) {
    var template = outpost_templates[$ outpost.template_id];
    var level_data = template.level_bonuses[$ outpost.level];

    return level_data.stamina_recovery_rate;
}

/// @function outpost_start_rest(outpost, expedition)
function outpost_start_rest(outpost, expedition) {
    if (!outpost.is_active) {
        return { success: false, reason: "outpost_not_active" };
    }

    expedition.status = "resting";
    expedition.resting_at = outpost.id;

    array_push(outpost.resting_expeditions, expedition.id);

    trigger_event("on_expedition_rest_start", {
        expedition: expedition,
        outpost: outpost
    });

    return { success: true };
}

/// @function outpost_end_rest(outpost, expedition)
function outpost_end_rest(outpost, expedition) {
    expedition.status = "idle";
    expedition.resting_at = undefined;

    array_delete_value(outpost.resting_expeditions, expedition.id);

    trigger_event("on_expedition_rest_end", {
        expedition: expedition,
        outpost: outpost,
        stamina: expedition.stamina
    });

    return { success: true };
}
```

---

## 5. 탐험 보상

### 5.1 발견물 타입

| 발견물 | 설명 | 보상 |
|--------|------|------|
| `resource_node` | 자원 노드 | 목재, 석재, 철 등 자원 |
| `dungeon` | 던전 입구 | 전투 + 희귀 아이템/유닛 |
| `ruin` | 고대 유적 | 마나 결정, 스킬 스크롤 |
| `npc_camp` | NPC 캠프 | 상인, 퀘스트 NPC |
| `hidden_village` | 숨겨진 마을 | 특수 유닛 고용, 교역 |
| `ancient_shrine` | 고대 신전 | 영구 버프, 희귀 유물 |
| `monster_nest` | 몬스터 둥지 | 제거 시 위협 감소 + 보상 |
| `merchant_caravan` | 상인 캐러밴 | 희귀 아이템 구매 기회 |

### 5.2 발견 시스템

```gml
/// @function expedition_check_discovery(expedition)
function expedition_check_discovery(expedition) {
    var region = world_regions[$ expedition.current_region];
    var base_chance = 5;    // 기본 5% 발견 확률

    // 정찰 기지 보너스
    var outpost_bonus = get_outpost_discovery_bonus(expedition.current_region);

    // 유닛 특성 보너스
    var unit_bonus = 0;
    for (var i = 0; i < array_length(expedition.members); i++) {
        if (unit_has_trait(expedition.members[i], "keen_eye")) {
            unit_bonus += 5;
        }
    }

    var total_chance = base_chance + outpost_bonus + unit_bonus;

    if (random(100) < total_chance) {
        var discovery = generate_discovery(region);
        array_push(expedition.discoveries, discovery);

        // 스테미나 소모
        expedition_consume_stamina(expedition, 5);

        trigger_event("on_discovery", {
            expedition: expedition,
            discovery: discovery
        });

        return discovery;
    }

    return undefined;
}

/// @function generate_discovery(region)
function generate_discovery(region) {
    var pool = region.possible_discoveries;
    var type = pool[irandom(array_length(pool) - 1)];

    var discovery = {
        id: global.next_discovery_id++,
        type: type,
        region: region.id,
        position: {
            x: expedition.current_position.x + random_range(-10, 10),
            y: expedition.current_position.y + random_range(-10, 10)
        },
        discovered_at: current_time,
        explored: false
    };

    // 타입별 추가 데이터
    switch (type) {
        case "dungeon":
            discovery.difficulty = choose("easy", "normal", "hard");
            discovery.rooms = irandom_range(3, 8);
            break;
        case "resource_node":
            discovery.resource_type = choose("wood", "stone", "iron", "crystal");
            discovery.yield = irandom_range(50, 200);
            break;
        case "npc_camp":
            discovery.npc_type = choose("merchant", "blacksmith", "sage");
            break;
    }

    return discovery;
}
```

---

## 6. 구현 가이드

### 6.1 탐험 프로세스 흐름

```gml
/// @function expedition_process_exploration(expedition, delta_time)
function expedition_process_exploration(expedition, delta_time) {
    // 이동 처리
    var move_speed = expedition_get_move_speed(expedition);
    var direction = point_direction(
        expedition.current_position.x,
        expedition.current_position.y,
        expedition.target_position.x,
        expedition.target_position.y
    );

    var move_x = lengthdir_x(move_speed * delta_time, direction);
    var move_y = lengthdir_y(move_speed * delta_time, direction);

    expedition.current_position.x += move_x;
    expedition.current_position.y += move_y;

    // 이동 거리 계산
    var distance_moved = point_distance(0, 0, move_x, move_y);
    expedition.distance_traveled += distance_moved;

    // 스테미나 소모 (일정 거리마다)
    var terrain = get_terrain_at(expedition.current_position);
    var stamina_cost = expedition_get_stamina_cost(expedition, terrain);

    if (expedition.distance_traveled >= 10) {   // 10 단위 거리당
        expedition_consume_stamina(expedition, stamina_cost);
        expedition.distance_traveled -= 10;

        // 발견 체크
        expedition_check_discovery(expedition);

        // 안개 제거
        reveal_fog_at(expedition.current_position, 2);

        // 지역 발견 진행도 증가
        increase_region_discovery(expedition.current_region, 1);
    }

    // 랜덤 이벤트 체크
    if (random(100) < 2) {  // 2% 확률
        expedition_trigger_random_event(expedition);
    }
}
```

### 6.2 주둔지 네트워크 시각화

```
        [심연의 경계]
              │
              │
    ┌─────────┴─────────┐
    │                   │
    │    [왕국 영지]     │
    │        ◆          │ ◆ = 성 (스테미나 완전 회복)
    │                   │
    └────┬────┬────┬────┘
         │    │    │
    ┌────┘    │    └────┐
    │         │         │
    ▼         ▼         ▼
[서쪽]     [남쪽]     [동쪽]
  ○          ○          ○     ○ = 초소 (스테미나 부분 회복)
  │          │          │
  ○──────────○──────────○     주둔지 네트워크로 탐험 범위 확장
             │
             ○
             │
           [더 깊은 미개척 영역]
```

### 6.3 탐험 UI 정보

```gml
/// 탐험 화면에 표시할 정보
expedition_ui_data = {
    // 탐험대 상태
    expedition_name: expedition.name,
    status: expedition.status,
    members: expedition.members,

    // 스테미나 바
    stamina_current: expedition.stamina,
    stamina_max: expedition.max_stamina,
    stamina_percent: expedition.stamina / expedition.max_stamina * 100,

    // 예상 이동 가능 거리
    estimated_range: expedition.stamina / average_stamina_cost,

    // 가장 가까운 휴식 지점
    nearest_rest_point: find_nearest_rest_point(expedition.current_position),
    distance_to_rest: calculate_distance_to(nearest_rest_point),

    // 발견물
    discoveries_count: array_length(expedition.discoveries),
    inventory_count: array_length(expedition.inventory),
    inventory_capacity: expedition.inventory_capacity
}
```

---

## 관련 문서

- [INDEX.md](./INDEX.md) - 전체 시스템 개요
- [UNIT_SYSTEM.md](./UNIT_SYSTEM.md) - 유닛 시스템 (탐험대 구성원)
- [ECONOMY_SYSTEM.md](./ECONOMY_SYSTEM.md) - 경제 시스템 (주둔지 건설 비용)
- [BATTLE_SYSTEM.md](./BATTLE_SYSTEM.md) - 전투 시스템 (탐험 중 전투)

---

## 변경 이력

| 버전 | 날짜 | 내용 |
|------|------|------|
| 1.0 | 2024-12-24 | 탐험 시스템 초안 - 월드 구조, 탐험대, 스테미나, 주둔지 |
