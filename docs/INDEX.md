# Under Dog Lord - 시스템 설계 문서

> **웨이브 디펜스 + 왕국 경영 + 탐험** 게임
> 건물에 유닛을 주둔시키고, 전투 시 자동 출전하여 몬스터 웨이브를 방어
> 탐험대를 조직하여 미개척 영역을 탐험하고 자원과 던전을 발견

---

## 월드 구조

```
                         ┌─────────────────────────────┐
                         │                             │
                         │        심연의 경계           │
                         │     (몬스터 웨이브 출현)      │
                         │            [북쪽]           │
                         └──────────────┬──────────────┘
                                        │
                                        ▼
 ░░░░░░░░░░░░░░░░░░░░    ┌─────────────────────────────┐    ░░░░░░░░░░░░░░░░░░░░
 ░  미개척 영역 (서쪽)  ░◄──│                             │──►░  미개척 영역 (동쪽)  ░
 ░      [안개]        ░    │         왕국 영지            │    ░      [안개]        ░
 ░░░░░░░░░░░░░░░░░░░░    │           (성)              │    ░░░░░░░░░░░░░░░░░░░░
                         │                             │
                         └──────────────┬──────────────┘
                                        │
                                        ▼
                         ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
                         ░                             ░
                         ░      미개척 영역 (남쪽)       ░
                         ░          [안개]             ░
                         ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
```

| 영역 | 방향 | 설명 |
|------|------|------|
| **심연의 경계** | 북쪽 | 몬스터 웨이브 출현지. 웨이브 디펜스 전투 |
| **왕국 영지** | 중앙 | 본거지. 건물, 유닛 주둔, 성문 방어 |
| **미개척 영역** | 동/서/남 | 안개로 덮인 미지의 땅. 탐험대로 탐험 |

---

## 게임 흐름

```
┌─────────────────────────────────────────────────────────────────────┐
│                          [ 왕국 영지 ]                               │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐       │
│  │  병영   │ │마법사탑 │ │  신전   │ │암살자길드│ │궁수초소 │ ...   │
│  │ 유닛주둔│ │ 유닛주둔│ │ 유닛주둔│ │ 유닛주둔│ │ 유닛주둔│       │
│  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘       │
│       │          │          │          │          │               │
│       └──────────┴──────────┴──────────┴──────────┘               │
│                             ↓                                      │
│                    [ 전투 시작 시 출전 ]                            │
│                             ↓                                      │
│  ════════════════════╣ 성문 ╠════════════════════                  │
│       ↓                                                            │
│  ┌─────────────────────────────────────────────────────────┐       │
│  │  FL  │  FC  │  FR  │     전열 (Front Line)              │       │
│  │  BL  │  BC  │  BR  │     후열 (Back Line)               │       │
│  │  WL  │  WC  │  WR  │     성벽 (Wall)                    │       │
│  └─────────────────────────────────────────────────────────┘       │
│                             ↑                                      │
│            [ 몬스터 웨이브 ← 심연의 경계 ]                           │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 문서 구조

| 문서 | 내용 | 언제 참조? |
|------|------|-----------|
| [SKILL_EFFECT_SYSTEM.md](./SKILL_EFFECT_SYSTEM.md) | 스킬, 효과, 타겟팅, 버프/디버프, 트리거, 스택 | 스킬 추가/수정, 효과 구현 |
| [UNIT_SYSTEM.md](./UNIT_SYSTEM.md) | 유닛 구조, AI, **건물 주둔**, **출전 위치**, 소환, 시체, 진화/변이 | 유닛 추가/수정, AI 로직, 출전 설정 |
| [BATTLE_SYSTEM.md](./BATTLE_SYSTEM.md) | **전투 흐름**, **출전 시스템**, 웨이브, 타일/지형, 오브, 딜레이, 미러매치 | 전투 메카닉 구현 |
| [ECONOMY_SYSTEM.md](./ECONOMY_SYSTEM.md) | 골드, 경험치, **주둔 건물 (6종)**, 건물 버프, 시너지 | 경제/건물 시스템 구현 |
| [EXPLORATION_SYSTEM.md](./EXPLORATION_SYSTEM.md) | **탐험대**, **스테미나**, **주둔지**, 미개척 영역, 발견물 | 탐험 시스템 구현 |

---

## 시스템 관계도

```
                              ┌─────────────────┐
                              │  BATTLE_SYSTEM  │
                              │ 전투흐름/출전/웨이브│
                              │   [심연의 경계]   │
                              └────────┬────────┘
                                       │
           ┌───────────────────────────┼───────────────────────────┐
           │                           │                           │
           ▼                           ▼                           ▼
  ┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
  │   UNIT_SYSTEM   │         │ SKILL_EFFECT    │         │ ECONOMY_SYSTEM  │
  │ 유닛/주둔/출전위치│◄───────►│ 스킬/효과/버프  │         │ 주둔건물/버프   │
  └────────┬────────┘         └─────────────────┘         └────────┬────────┘
           │                                                       │
           │        ┌─────────────────────────────┐                │
           │        │      [왕국 영지 - 성]        │                │
           └───────►│    유닛 ←→ 건물 주둔 연동    │◄───────────────┘
                    └──────────────┬──────────────┘
                                   │
                                   ▼
                    ┌─────────────────────────────┐
                    │    EXPLORATION_SYSTEM       │
                    │ 탐험대/스테미나/주둔지/발견물  │
                    │      [미개척 영역]           │
                    └─────────────────────────────┘
```

---

## 핵심 설계 원칙

### 1. 데이터 기반 (Data-Driven)
모든 스킬, 유닛, 효과는 코드가 아닌 **데이터(struct)**로 정의

```gml
// 새 스킬 추가 = 데이터만 추가
skill_fireball = {
    name: "파이어볼",
    effects: [{ type: "damage", amount: 200 }]
}
```

### 2. 태그 시스템
모든 요소에 태그를 부여하여 필터링/상호작용 구현

```gml
// 태그 카테고리
tags = {
    effect: ["buff", "debuff", "dot", "hot"],
    element: ["fire", "ice", "electric", "shadow", "holy"],
    dispel: ["dispellable", "undispellable"],
    cc: ["stun", "slow", "silence", "root", "fear"],
    race: ["human", "undead", "demon", "beast"],
    role: ["tank", "dps", "healer", "support"]
}
```

### 3. 조합 가능 (Composable)
작은 효과 단위를 조합하여 복잡한 스킬 생성

```gml
// 복잡한 스킬 = 단순 효과들의 조합
skill_meteor = {
    effects: [
        { type: "delayed", delay: 3 },
        { type: "damage", amount: 500 },
        { type: "create_tile_effect", effect: "fire_ground" },
        { type: "stun", duration: 1 }
    ]
}
```

---

## 타겟 가능 대상

| 대상 타입 | 설명 | 관련 문서 |
|-----------|------|----------|
| `unit` | 살아있는 유닛 (아군/적군/몬스터) | UNIT_SYSTEM |
| `corpse` | 시체 | UNIT_SYSTEM |
| `tile` | 타일/지형 | BATTLE_SYSTEM |
| `tile_object` | 타일 위 오브젝트 (벽, 토템 등) | BATTLE_SYSTEM |
| `summon` | 소환물 | UNIT_SYSTEM |
| `orb` | 오브 | BATTLE_SYSTEM |
| `wave_spawn` | 웨이브 스폰 지점 | BATTLE_SYSTEM |

---

## 유닛 분류 체계

### 종족 (Race) - 건물 배치 결정

| 종족 | 설명 | 배치 건물 |
|------|------|----------|
| `human`, `elf`, `dwarf`, `orc` | humanoid | 직업 건물 우선 |
| `undead` | 언데드 | 묘지 (신전 금지) |
| `demon` | 악마 | 마족 제단 (신전 금지) |
| `slime` | 슬라임 | 슬라임 소굴 |
| `beast` | 야수 | 야수 우리 |
| `dragon` | 용족 | 용의 둥지 |

### 직업 (Class) - 전투 스타일 결정

| 직업 | 대응 건물 | 주요 역할 |
|------|----------|----------|
| `warrior`, `tank` | 병영 | 근접 전투, 탱킹 |
| `mage` | 마법사탑 | 마법 공격 |
| `priest`, `paladin` | 신전 | 치유, 보호 |
| `rogue`, `assassin` | 암살자 길드 | 암살, 은신 |
| `ranger`, `archer` | 궁수 초소 | 원거리 물리 |

### 전투 속성 (Combat)

| 속성 | 값 | 설명 |
|------|-----|------|
| range | melee, ranged, hybrid | 전투 거리 |
| function | damage, tank, healer, support | 전투 역할 |
| damage_type | physical, magical, holy, shadow | 공격 속성 |

> 상세는 [UNIT_SYSTEM.md - 1.2~1.4](./UNIT_SYSTEM.md#12-종족-race) 참조

---

## 주둔 건물

### 직업 건물 (Job Buildings) - 1순위

| 건물 | 허용 직업 | 허용 종족 | 금지 종족 |
|------|----------|----------|----------|
| 병영 | warrior, tank | humanoid | - |
| 마법사탑 | mage | 모든 종족 | - |
| 신전 | priest, paladin | holy 친화 | undead, demon |
| 암살자 길드 | rogue, assassin | humanoid | - |
| 궁수 초소 | ranger, archer | humanoid | - |

### 종족 건물 (Race Buildings) - 2순위

| 건물 | 필수 종족 | 허용 직업 |
|------|----------|----------|
| 묘지 | undead | 모든 직업 |
| 슬라임 소굴 | slime | 모든 직업 |
| 마족 제단 | demon | 모든 직업 |
| 야수 우리 | beast | 모든 직업 |
| 용의 둥지 | dragon | 모든 직업 |

> 상세 버프/특수 기능은 [ECONOMY_SYSTEM.md - 주둔 건물 시스템](./ECONOMY_SYSTEM.md#주둔-건물-시스템) 참조

---

## 출전 위치 (9개)

| 위치 | 코드 | 특성 |
|------|------|------|
| 전열 좌측 | `FL` | 측면 방어, 회피 보너스 |
| 전열 중앙 | `FC` | 탱커 최적, 방어 보너스 |
| 전열 우측 | `FR` | 측면 방어, 회피 보너스 |
| 후열 좌측 | `BL` | 원거리 딜러, 공격 보너스 |
| 후열 중앙 | `BC` | 힐러 최적, 힐량 보너스 |
| 후열 우측 | `BR` | 원거리 딜러, 공격 보너스 |
| 성벽 좌측 | `WL` | 성벽 엄폐, 사거리 보너스 |
| 성벽 중앙 | `WC` | 성문 수비, 방어 최대 |
| 성벽 우측 | `WR` | 성벽 엄폐, 사거리 보너스 |

> 상세 위치별 보너스는 [UNIT_SYSTEM.md - 출전 위치 시스템](./UNIT_SYSTEM.md#3-출전-위치-시스템) 참조

---

## 유닛 AI 시스템

### 설계 원칙

> **적 AI는 단순, 아군 AI는 복잡** - 플레이어가 전술로 이길 수 있도록

```
적 AI (Enemy)                    아군 AI (Ally)
┌───────────────┐                ┌───────────────┐
│  • 단순 패턴   │                │  • 역할별 행동  │
│  • 예측 가능   │                │  • 상태 기반    │
│  • 3가지 타입  │                │  • 7가지 역할   │
└───────────────┘                └───────────────┘
```

### 적 AI (3가지)

| AI 타입 | 행동 | 적용 대상 | 대응 전략 |
|---------|------|----------|-----------|
| `ai_rush` | 가장 가까운 적 돌진 | 좀비, 고블린, 늑대 | 탱커로 유인 |
| `ai_ranged` | 거리 유지, 원거리 공격 | 궁수, 마법사 | 암살자로 침투 |
| `ai_boss` | 페이즈별 패턴 | 보스 | 패턴 숙지 |

### 아군 AI (7가지)

| AI 역할 | 주요 행동 | 위치 | 타겟 우선순위 |
|---------|----------|------|--------------|
| `ai_tank` | 도발, 아군 보호 | 전열 | 아군 공격 중인 적 |
| `ai_healer` | 치유, 디버프 해제 | 후열 | 낮은 HP 아군 |
| `ai_ranged_dps` | 원거리 딜링 | 후열 | 낮은 HP 적 |
| `ai_melee_dps` | 근접 딜링 | 전열 | 탱커 타겟 적 |
| `ai_assassin` | 후열 침투 | 측면 | 힐러 > 원거리 딜러 |
| `ai_support` | 버프/디버프 | 중열 | 딜러 아군 |
| `ai_summoner` | 소환수 관리 | 후열 | 소환물 |

> 상세는 [UNIT_SYSTEM.md - 유닛 AI 시스템](./UNIT_SYSTEM.md#4-유닛-ai-시스템) 참조

---

## 길찾기 및 이동 시스템

> 수성전 스타일 - 아군/적 모두 이동하며 전투, 전선이 밀고 밀리는 동적 전투

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ Spatial Grid│───►│ A* 길찾기   │───►│ Steering    │
│ (유닛 탐지) │    │ (8방향 경로)│    │ (부드러운   │
└─────────────┘    └─────────────┘    │  이동+회피) │
      │                  │            └─────────────┘
      ▼                  ▼
┌─────────────┐    ┌─────────────┐
│ 전선 인식   │    │ 진형 유지   │
│ (밀고 밀림) │    │ (역할별 위치)│
└─────────────┘    └─────────────┘
```

| 시스템 | 설명 |
|--------|------|
| **Spatial Grid** | 공간 분할로 O(1) 유닛 탐지 |
| **A\* 8방향** | 타일 기반 경로 탐색, 방향전환 패널티 |
| **Steering** | 경로 추종 + 유닛 분리 (겹침 방지) |
| **전선 인식** | pushing/holding/retreating 상태 판단 |
| **진형 유지** | 탱커 전열, 딜러 후열 자동 배치 |

> 상세는 [UNIT_SYSTEM.md - 4.8 길찾기 및 이동 시스템](./UNIT_SYSTEM.md#48-길찾기-및-이동-시스템) 참조

---

## 빠른 참조

### "X를 구현하려면 어디를 봐야 하나?"

| 구현 내용 | 참조 문서 | 참조 섹션 |
|----------|----------|----------|
| 새 스킬 추가 | SKILL_EFFECT_SYSTEM | 스킬 구조 |
| 데미지/힐 효과 | SKILL_EFFECT_SYSTEM | 효과 타입 |
| 버프/디버프 | SKILL_EFFECT_SYSTEM | 버프/디버프 시스템 |
| CC (스턴, 슬로우) | SKILL_EFFECT_SYSTEM | 상태 효과 |
| 조건부 효과 | SKILL_EFFECT_SYSTEM | 조건부/확률 |
| 스택 쌓기 | SKILL_EFFECT_SYSTEM | 스택 시스템 |
| 패시브/트리거 | SKILL_EFFECT_SYSTEM | 트리거 시스템 |
| **희생/자폭 스킬** | SKILL_EFFECT_SYSTEM | 희생/자폭 효과 상세 |
| **자폭형 유닛** | SKILL_EFFECT_SYSTEM | 자폭형 유닛 예시 |
| 새 유닛 추가 | UNIT_SYSTEM | 유닛 구조 |
| **스탯 시스템** | UNIT_SYSTEM | 1.7 스탯 시스템 |
| **전투 공식 (데미지/힐)** | UNIT_SYSTEM | 1.7.6 전투 공식 |
| **종족별 스탯 보정** | UNIT_SYSTEM | 1.7.9 종족별 스탯 보정 |
| **종족/직업 설정** | UNIT_SYSTEM | 종족/직업/전투속성 |
| **하이브리드 유닛** | UNIT_SYSTEM | 유닛 예시 |
| 유닛 AI 수정 | UNIT_SYSTEM | AI 시스템 |
| **적 AI (단순)** | UNIT_SYSTEM | 4.2 적 AI |
| **아군 AI (복잡)** | UNIT_SYSTEM | 4.3 아군 AI |
| **타겟 선정 로직** | UNIT_SYSTEM | 4.4 타겟 선정 |
| **위협도 시스템** | UNIT_SYSTEM | 4.6 위협도 시스템 |
| **길찾기 (A\* 8방향)** | UNIT_SYSTEM | 4.8.2 A* 길찾기 |
| **유닛 이동 (Steering)** | UNIT_SYSTEM | 4.8.3 Steering |
| **전선 인식** | UNIT_SYSTEM | 4.8.4 전선 인식 |
| **진형 유지** | UNIT_SYSTEM | 4.8.5 진형 시스템 |
| **유닛 건물 주둔** | UNIT_SYSTEM | 건물 주둔 시스템 |
| **출전 위치 설정** | UNIT_SYSTEM | 출전 위치 시스템 |
| 소환물 | UNIT_SYSTEM | 소환 시스템 |
| 시체 활용 | UNIT_SYSTEM | 시체 시스템 |
| 유닛 진화/변이 | UNIT_SYSTEM | 진화/변이 시스템 |
| **전투 흐름** | BATTLE_SYSTEM | 전투 흐름 |
| **유닛 출전** | BATTLE_SYSTEM | 전투 시작 함수 |
| **성문 시스템** | BATTLE_SYSTEM | 성문 시스템 |
| 웨이브 구성 | BATTLE_SYSTEM | 웨이브 시스템 |
| 타일/지형 효과 | BATTLE_SYSTEM | 타일 시스템 |
| 장판 (불바닥 등) | BATTLE_SYSTEM | 타일 효과 |
| 오브 시스템 | BATTLE_SYSTEM | 오브 시스템 |
| 딜레이 스킬 | BATTLE_SYSTEM | 딜레이 시스템 |
| 미러/복제 | BATTLE_SYSTEM | 미러매치 시스템 |
| 골드/경험치 | ECONOMY_SYSTEM | 자원 시스템 |
| **직업 건물 (5종)** | ECONOMY_SYSTEM | 직업 건물 |
| **종족 건물 (5종)** | ECONOMY_SYSTEM | 종족 건물 |
| **건물 버프** | ECONOMY_SYSTEM | 각 건물 섹션 |
| **탐험대 조직** | EXPLORATION_SYSTEM | 탐험대 시스템 |
| **스테미나 관리** | EXPLORATION_SYSTEM | 스테미나 시스템 |
| **주둔지 건설** | EXPLORATION_SYSTEM | 주둔지 시스템 |
| **발견물 (던전, 자원 등)** | EXPLORATION_SYSTEM | 탐험 보상 |
| **월드 영역 구조** | EXPLORATION_SYSTEM | 월드 구조 |

---

## 핵심 함수 흐름

### 전투 시작 흐름
```
[웨이브 시작]
    │
    ▼
battle_start(wave_data)                    ← BATTLE_SYSTEM
    │
    ├─► battle_deploy_all_units()          ← BATTLE_SYSTEM
    │       │
    │       ├─► 건물별 주둔 유닛 수집       ← ECONOMY_SYSTEM
    │       ├─► 건물 버프 적용              ← ECONOMY_SYSTEM
    │       └─► 출전 위치 배치              ← UNIT_SYSTEM
    │
    ├─► 성문 HP 설정
    │
    └─► wave_start_spawning()
```

### 스킬 시전 흐름
```
[스킬 시전]
    │
    ▼
execute_skill(caster, skill_data)
    │
    ├─► 마나/쿨다운 체크
    │
    ├─► get_targets(targeting)     ← SKILL_EFFECT_SYSTEM
    │
    ├─► apply_effect(effects[])    ← SKILL_EFFECT_SYSTEM
    │       │
    │       ├─► damage/heal
    │       ├─► buff/debuff
    │       ├─► summon            ← UNIT_SYSTEM
    │       ├─► create_tile_effect ← BATTLE_SYSTEM
    │       └─► grant_gold         ← ECONOMY_SYSTEM
    │
    └─► trigger_events()           ← SKILL_EFFECT_SYSTEM (트리거)
```

---

## GML 파일 구조 권장

```
scripts/
├── core/
│   ├── scr_skill_execute.gml       // 스킬 실행 메인
│   ├── scr_effect_apply.gml        // 효과 적용
│   ├── scr_targeting.gml           // 타겟팅
│   └── scr_battle_flow.gml         // 전투 흐름 (NEW)
│
├── systems/
│   ├── scr_buff_system.gml         // 버프/디버프
│   ├── scr_trigger_system.gml      // 트리거/패시브
│   ├── scr_stack_system.gml        // 스택
│   ├── scr_summon_system.gml       // 소환
│   ├── scr_corpse_system.gml       // 시체
│   ├── scr_tile_system.gml         // 타일/지형
│   ├── scr_wave_system.gml         // 웨이브
│   ├── scr_orb_system.gml          // 오브
│   ├── scr_evolution_system.gml    // 진화/변이
│   ├── scr_economy_system.gml      // 경제
│   ├── scr_garrison_system.gml     // 건물 주둔 (NEW)
│   ├── scr_deploy_system.gml       // 출전 배치 (NEW)
│   └── scr_gate_system.gml         // 성문 (NEW)
│
├── ai/
│   ├── scr_unit_ai.gml             // 유닛 AI
│   └── scr_monster_ai.gml          // 몬스터 AI
│
└── data/
    ├── data_skills.gml             // 스킬 데이터
    ├── data_effects.gml            // 효과 프리셋
    ├── data_units.gml              // 유닛 데이터
    ├── data_monsters.gml           // 몬스터 데이터
    ├── data_waves.gml              // 웨이브 데이터
    ├── data_tiles.gml              // 타일 데이터
    └── data_buildings.gml          // 주둔 건물 데이터 (6종)
```

---

## 변경 이력

| 버전 | 날짜 | 내용 |
|------|------|------|
| 1.0 | 2024-12-23 | 초안 (SKILL_SYSTEM.md) |
| 2.0 | 2024-12-23 | 문서 분리 및 INDEX 생성 |
| 3.0 | 2024-12-23 | 건물 주둔/출전 시스템 추가, 주둔 건물 6종 정의 |
| 4.0 | 2024-12-23 | 종족/직업/전투속성 시스템 추가, 직업건물/종족건물 분류 |
| 5.0 | 2024-12-23 | 전투 AI 시스템 추가: 적 AI(단순 3종), 아군 AI(복잡 7종) |
| 6.0 | 2024-12-23 | 길찾기/이동 시스템 추가: Spatial Grid, A* 8방향, Steering, 전선 인식, 진형 |
| 7.0 | 2024-12-23 | 희생/자폭 스킬 시스템 추가: sacrifice, sacrifice_hp, sacrifice_ally, detonate, 자폭형 유닛 예시 |
| 8.0 | 2024-12-23 | 기본 스탯 시스템 추가: 1차/2차/저항 스탯, 전투 공식, 스탯 성장, 종족별 보정 |
| 8.1 | 2024-12-23 | 스탯 시스템 개선: 물리/마법 공격력·방어력 분리, 흡혈·관통도 분리, 전투 공식 업데이트 |
| 8.2 | 2024-12-23 | 스탯 단순화: 속성 저항 6개 제거, 물방/마방만으로 방어 처리, 속성은 추가효과로 차별화 |
| 9.0 | 2024-12-24 | 탐험 시스템 추가: 월드 구조 (심연의 경계/미개척 영역), 탐험대, 스테미나, 주둔지, 발견물 |
