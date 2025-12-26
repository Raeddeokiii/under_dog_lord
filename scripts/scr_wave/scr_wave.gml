/// @file scr_wave.gml
/// @desc M2-1 웨이브 시스템 - 적 스폰, 웨이브 관리

// ========================================
// 웨이브 상태 머신
// ========================================
// idle → preparing → spawning → in_progress → completed → preparing ...
//                                    ↓
//                               game_over

/// @func init_wave_system()
/// @desc 웨이브 시스템 초기화
function init_wave_system() {
    global.wave = {
        // 상태
        state: "idle",          // idle, preparing, spawning, in_progress, completed, game_over
        current_wave: 0,
        max_waves: 30,          // -1 = 무한

        // 스폰 설정
        spawn_queue: [],
        spawn_timer: 0,
        spawn_point_x: room_width / 2,
        spawn_point_y: 80,

        // 웨이브 간 휴식
        prepare_time: 5,        // 초
        prepare_timer: 0,

        // UI
        announcement: "",
        announcement_timer: 0,

        // 통계
        total_enemies_spawned: 0,
        total_enemies_killed: 0
    };

    return global.wave;
}

// ========================================
// 웨이브 시작
// ========================================

/// @func start_wave(wave_num)
/// @desc 특정 웨이브 시작
function start_wave(wave_num) {
    global.wave.current_wave = wave_num;
    global.wave.state = "preparing";
    global.wave.prepare_timer = global.wave.prepare_time;

    global.wave.announcement = "웨이브 " + string(wave_num) + " 준비";
    global.wave.announcement_timer = global.wave.prepare_time;

    combat_log("웨이브 " + string(wave_num) + " 준비 시작");
}

/// @func start_next_wave()
/// @desc 다음 웨이브 시작
function start_next_wave() {
    start_wave(global.wave.current_wave + 1);
}

/// @func start_first_wave()
/// @desc 첫 웨이브 시작 (게임 시작)
function start_first_wave() {
    if (global.wave.state == "idle") {
        start_wave(1);
    }
}

// ========================================
// 웨이브 업데이트 (메인 루프)
// ========================================

/// @func update_wave_system(delta)
/// @desc 웨이브 시스템 메인 업데이트
function update_wave_system(delta) {
    if (!variable_global_exists("wave")) return;

    switch (global.wave.state) {
        case "idle":
            // 대기 상태
            break;

        case "preparing":
            wave_preparing_update(delta);
            break;

        case "spawning":
            wave_spawning_update(delta);
            break;

        case "in_progress":
            wave_in_progress_update(delta);
            break;

        case "completed":
            wave_completed_update(delta);
            break;

        case "game_over":
            // 게임 오버 상태
            break;
    }

    // 알림 타이머 감소
    if (global.wave.announcement_timer > 0) {
        global.wave.announcement_timer -= delta;
    }
}

// ========================================
// 상태별 업데이트
// ========================================

/// @func wave_preparing_update(delta)
function wave_preparing_update(delta) {
    global.wave.prepare_timer -= delta;

    // 카운트다운 알림
    var seconds_left = ceil(global.wave.prepare_timer);
    if (seconds_left > 0 && seconds_left <= 3) {
        global.wave.announcement = string(seconds_left);
    }

    if (global.wave.prepare_timer <= 0) {
        begin_wave_spawning();
    }
}

/// @func begin_wave_spawning()
function begin_wave_spawning() {
    global.wave.state = "spawning";

    // 웨이브 구성 생성
    global.wave.spawn_queue = generate_wave_composition(global.wave.current_wave);
    global.wave.spawn_timer = 0;

    global.wave.announcement = "웨이브 " + string(global.wave.current_wave) + " 시작!";
    global.wave.announcement_timer = 2;

    // 영혼 수집 (이전 웨이브 영혼)
    collect_souls_to_sanctuary();

    // 영혼 타이머 업데이트
    update_soul_timers();

    combat_log("웨이브 " + string(global.wave.current_wave) + " 스폰 시작 (적 수: " + string(array_length(global.wave.spawn_queue)) + ")");
}

/// @func wave_spawning_update(delta)
function wave_spawning_update(delta) {
    global.wave.spawn_timer += delta;

    var all_spawned = true;

    for (var i = 0; i < array_length(global.wave.spawn_queue); i++) {
        var entry = global.wave.spawn_queue[i];

        if (!entry.spawned) {
            all_spawned = false;

            if (global.wave.spawn_timer >= entry.delay) {
                spawn_wave_enemy(entry);
                entry.spawned = true;
            }
        }
    }

    if (all_spawned) {
        global.wave.state = "in_progress";
        combat_log("웨이브 " + string(global.wave.current_wave) + " 스폰 완료");
    }
}

/// @func wave_in_progress_update(delta)
function wave_in_progress_update(delta) {
    // 적 전멸 체크
    var enemy_count = count_alive_enemies();

    if (enemy_count == 0) {
        complete_wave();
    }

    // 성문 파괴 체크
    if (is_gate_destroyed()) {
        trigger_game_over();
    }
}

/// @func wave_completed_update(delta)
function wave_completed_update(delta) {
    // 알림 타이머 끝나면 다음 웨이브
    if (global.wave.announcement_timer <= 0) {
        // 최대 웨이브 체크
        if (global.wave.max_waves > 0 && global.wave.current_wave >= global.wave.max_waves) {
            trigger_victory();
        } else {
            start_next_wave();
        }
    }
}

// ========================================
// 웨이브 클리어/게임 오버
// ========================================

/// @func complete_wave()
function complete_wave() {
    global.wave.state = "completed";

    global.wave.announcement = "웨이브 " + string(global.wave.current_wave) + " 클리어!";
    global.wave.announcement_timer = 3;

    // 보상 (M4에서 확장)
    var gold_reward = 50 + (global.wave.current_wave * 10);
    combat_log("웨이브 클리어! 보상: 골드 +" + string(gold_reward));
}

/// @func trigger_game_over()
function trigger_game_over() {
    global.wave.state = "game_over";
    global.wave.announcement = "게임 오버";
    global.wave.announcement_timer = 999;

    combat_log("★ 게임 오버 - 성문 파괴됨");
}

/// @func trigger_victory()
function trigger_victory() {
    global.wave.state = "game_over";
    global.wave.announcement = "승리!";
    global.wave.announcement_timer = 999;

    combat_log("★ 승리! 모든 웨이브 클리어");
}

// ========================================
// 웨이브 구성 생성
// ========================================

/// @func generate_wave_composition(wave_num)
/// @desc 웨이브 번호에 따른 적 구성 생성
function generate_wave_composition(wave_num) {
    var queue = [];

    // 기본 공식
    var base_count = 3 + floor(wave_num * 1.5);
    var enemy_level = 1 + floor(wave_num / 5);

    // 웨이브별 적 풀
    var enemy_pool = get_enemy_pool_for_wave(wave_num);

    // 적 생성
    var spawn_interval = 0.5;
    var current_delay = 0;

    for (var i = 0; i < base_count; i++) {
        var selected = select_weighted_random(enemy_pool);

        array_push(queue, {
            unit_id: selected,
            level: enemy_level,
            delay: current_delay,
            spawned: false,
            is_boss: false
        });

        current_delay += spawn_interval;
    }

    // 보스 웨이브 (10의 배수)
    if (wave_num % 10 == 0 && wave_num > 0) {
        array_push(queue, {
            unit_id: "orc_warrior",
            level: enemy_level + 5,
            delay: current_delay + 2,
            spawned: false,
            is_boss: true
        });
    }

    return queue;
}

/// @func get_enemy_pool_for_wave(wave_num)
function get_enemy_pool_for_wave(wave_num) {
    if (wave_num <= 5) {
        return [{ id: "goblin", weight: 100 }];
    } else if (wave_num <= 10) {
        return [
            { id: "goblin", weight: 70 },
            { id: "goblin_archer", weight: 30 }
        ];
    } else if (wave_num <= 15) {
        return [
            { id: "goblin", weight: 50 },
            { id: "goblin_archer", weight: 25 },
            { id: "orc_warrior", weight: 25 }
        ];
    } else if (wave_num <= 20) {
        return [
            { id: "goblin", weight: 30 },
            { id: "goblin_archer", weight: 20 },
            { id: "orc_warrior", weight: 30 },
            { id: "shadow_wolf", weight: 20 }
        ];
    } else {
        return [
            { id: "goblin", weight: 20 },
            { id: "goblin_archer", weight: 15 },
            { id: "orc_warrior", weight: 25 },
            { id: "shadow_wolf", weight: 20 },
            { id: "skeleton_mage", weight: 20 }
        ];
    }
}

/// @func select_weighted_random(pool)
function select_weighted_random(pool) {
    var total = 0;
    for (var i = 0; i < array_length(pool); i++) {
        total += pool[i].weight;
    }

    var roll = random(total);
    var cumulative = 0;

    for (var i = 0; i < array_length(pool); i++) {
        cumulative += pool[i].weight;
        if (roll < cumulative) {
            return pool[i].id;
        }
    }

    return pool[0].id;
}

// ========================================
// 적 스폰
// ========================================

/// @func spawn_wave_enemy(entry)
function spawn_wave_enemy(entry) {
    var sx = global.wave.spawn_point_x + random_range(-80, 80);
    var sy = global.wave.spawn_point_y + random_range(-20, 20);

    // 유닛 생성 (struct 기반)
    var enemy = create_enemy_unit(entry.unit_id, sx, sy, entry.level);

    if (enemy != undefined) {
        // 보스 강화
        if (entry.is_boss) {
            enemy.is_boss = true;
            enemy.max_hp *= 3;
            enemy.hp = enemy.max_hp;
            enemy.display_name = "★ " + enemy.display_name;
        }

        enemy.spawn_wave = global.wave.current_wave;
        global.wave.total_enemies_spawned++;

        combat_log("스폰: " + enemy.display_name + " Lv." + string(entry.level));
    }
}

/// @func create_enemy_unit(unit_id, x, y, level)
/// @desc 적 유닛 struct 생성
function create_enemy_unit(unit_id, _x, _y, level) {
    // 기본 스탯 (단순화)
    var base_stats = get_enemy_base_stats(unit_id);

    var enemy = {
        // 식별
        unit_id: unit_id,
        display_name: base_stats.name,
        team: "enemy",

        // 위치
        x: _x,
        y: _y,
        facing: 1,

        // 스탯 (레벨 스케일링)
        level: level,
        hp: base_stats.hp * (1 + (level - 1) * 0.1),
        max_hp: base_stats.hp * (1 + (level - 1) * 0.1),
        physical_attack: base_stats.atk * (1 + (level - 1) * 0.1),
        physical_defense: base_stats.def * (1 + (level - 1) * 0.05),
        magic_attack: base_stats.matk ?? 0,
        magic_defense: base_stats.mdef ?? 0,
        attack_range: base_stats.range ?? 80,
        attack_speed: base_stats.aspd ?? 1.0,
        movement_speed: base_stats.mspd ?? 80,

        // 상태
        is_alive: true,
        is_boss: false,
        is_summon: false,

        // AI
        ai_state: "idle",
        ai_target: undefined,
        attack_timer: 0,
        attack_cooldown: 0
    };

    // 전역 적 목록에 추가
    if (!variable_global_exists("enemy_units")) {
        global.enemy_units = [];
    }
    array_push(global.enemy_units, enemy);

    return enemy;
}

/// @func get_enemy_base_stats(unit_id)
function get_enemy_base_stats(unit_id) {
    switch (unit_id) {
        case "goblin":
            return { name: "고블린", hp: 80, atk: 15, def: 5, range: 60, aspd: 1.2, mspd: 90 };
        case "goblin_archer":
            return { name: "고블린 궁수", hp: 60, atk: 20, def: 3, range: 200, aspd: 0.8, mspd: 70 };
        case "orc_warrior":
            return { name: "오크 전사", hp: 200, atk: 35, def: 15, range: 70, aspd: 0.7, mspd: 60 };
        case "shadow_wolf":
            return { name: "그림자 늑대", hp: 100, atk: 25, def: 8, range: 50, aspd: 1.5, mspd: 120 };
        case "skeleton_mage":
            return { name: "해골 마법사", hp: 70, atk: 10, def: 5, matk: 40, mdef: 20, range: 250, aspd: 0.6, mspd: 50 };
        default:
            return { name: "적", hp: 50, atk: 10, def: 5, range: 60, aspd: 1.0, mspd: 80 };
    }
}

// ========================================
// 유틸리티
// ========================================

/// @func count_alive_enemies()
function count_alive_enemies() {
    if (!variable_global_exists("enemy_units")) return 0;

    var count = 0;
    for (var i = 0; i < array_length(global.enemy_units); i++) {
        if (global.enemy_units[i].hp > 0) {
            count++;
        }
    }
    return count;
}

/// @func count_alive_allies()
function count_alive_allies() {
    if (!variable_global_exists("ally_units")) return 0;

    var count = 0;
    for (var i = 0; i < array_length(global.ally_units); i++) {
        if (global.ally_units[i].hp > 0) {
            count++;
        }
    }
    return count;
}

/// @func get_wave_state()
function get_wave_state() {
    if (!variable_global_exists("wave")) return "idle";
    return global.wave.state;
}

/// @func get_current_wave()
function get_current_wave() {
    if (!variable_global_exists("wave")) return 0;
    return global.wave.current_wave;
}

// ========================================
// 웨이브 UI 그리기
// ========================================

/// @func draw_wave_ui()
function draw_wave_ui() {
    if (!variable_global_exists("wave")) return;

    // 웨이브 정보 (상단)
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_set_color(c_white);

    var wave_text = "웨이브 " + string(global.wave.current_wave);
    if (global.wave.max_waves > 0) {
        wave_text += " / " + string(global.wave.max_waves);
    }
    draw_text(room_width / 2, 10, wave_text);

    // 적 수
    var enemy_count = count_alive_enemies();
    draw_set_color(c_red);
    draw_text(room_width / 2, 30, "적: " + string(enemy_count));

    // 알림 (중앙)
    if (global.wave.announcement_timer > 0) {
        var alpha = min(global.wave.announcement_timer, 1);
        draw_set_alpha(alpha);
        draw_set_color(c_yellow);
        draw_text(room_width / 2, room_height / 2 - 50, global.wave.announcement);
        draw_set_alpha(1);
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}
