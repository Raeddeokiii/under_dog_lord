/// @file scr_ui.gml
/// @desc M2-3 최소 UI - HP바, 웨이브 정보, 전투 로그

// ========================================
// 전체 UI 그리기
// ========================================

/// @func draw_battle_ui()
/// @desc 전투 UI 전체 그리기
function draw_battle_ui() {
    // 1. 웨이브 정보 (상단)
    draw_wave_info_ui();

    // 2. 성문 (하단)
    draw_gate();

    // 3. 배치 슬롯
    draw_deploy_slots();

    // 4. 유닛들
    draw_all_units();

    // 5. 영혼 (전투 중)
    draw_souls();

    // 6. 데미지 숫자
    draw_damage_numbers();

    // 7. 웨이브 알림 (중앙)
    draw_wave_announcement();

    // 8. 전투 로그 (좌하단)
    draw_combat_log_ui();

    // 9. 미니 상태창 (우상단)
    draw_mini_status_ui();
}

// ========================================
// 웨이브 정보 UI
// ========================================

/// @func draw_wave_info_ui()
function draw_wave_info_ui() {
    if (!variable_global_exists("wave")) return;

    var panel_x = room_width / 2;
    var panel_y = 10;

    // 배경 패널
    draw_set_alpha(0.7);
    draw_set_color(c_black);
    draw_roundrect(panel_x - 100, panel_y, panel_x + 100, panel_y + 50, false);
    draw_set_alpha(1);

    // 웨이브 번호
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_set_color(c_white);

    var wave_text = "WAVE " + string(global.wave.current_wave);
    if (global.wave.max_waves > 0) {
        wave_text += " / " + string(global.wave.max_waves);
    }
    draw_text(panel_x, panel_y + 5, wave_text);

    // 상태
    var state_text = "";
    var state_color = c_white;

    switch (global.wave.state) {
        case "idle":
            state_text = "대기 중";
            state_color = c_gray;
            break;
        case "preparing":
            state_text = "준비 중... " + string(ceil(global.wave.prepare_timer));
            state_color = c_yellow;
            break;
        case "spawning":
            state_text = "적 출현!";
            state_color = c_orange;
            break;
        case "in_progress":
            state_text = "전투 중 (적: " + string(count_alive_enemies()) + ")";
            state_color = c_red;
            break;
        case "completed":
            state_text = "클리어!";
            state_color = c_lime;
            break;
        case "game_over":
            state_text = global.wave.announcement;
            state_color = (global.wave.announcement == "승리!") ? c_lime : c_red;
            break;
    }

    draw_set_color(state_color);
    draw_text(panel_x, panel_y + 25, state_text);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

/// @func draw_wave_announcement()
function draw_wave_announcement() {
    if (!variable_global_exists("wave")) return;
    if (global.wave.announcement_timer <= 0) return;

    var alpha = min(global.wave.announcement_timer, 1);
    var scale = 1 + (1 - alpha) * 0.3;

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_alpha(alpha);

    // 그림자
    draw_set_color(c_black);
    draw_text_transformed(room_width / 2 + 2, room_height / 2 - 80 + 2,
        global.wave.announcement, scale, scale, 0);

    // 텍스트
    draw_set_color(c_yellow);
    draw_text_transformed(room_width / 2, room_height / 2 - 80,
        global.wave.announcement, scale, scale, 0);

    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

// ========================================
// 미니 상태 UI
// ========================================

/// @func draw_mini_status_ui()
function draw_mini_status_ui() {
    var panel_x = room_width - 150;
    var panel_y = 10;
    var panel_w = 140;
    var panel_h = 80;

    // 배경
    draw_set_alpha(0.7);
    draw_set_color(c_black);
    draw_roundrect(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, false);
    draw_set_alpha(1);

    // 내용
    draw_set_color(c_white);
    var y_offset = panel_y + 10;

    // 아군 수
    var ally_count = count_alive_allies();
    draw_set_color(c_aqua);
    draw_text(panel_x + 10, y_offset, "아군: " + string(ally_count));
    y_offset += 20;

    // 적 수
    var enemy_count = count_alive_enemies();
    draw_set_color(c_red);
    draw_text(panel_x + 10, y_offset, "적: " + string(enemy_count));
    y_offset += 20;

    // 성문 HP
    if (variable_global_exists("gate") && global.gate != undefined) {
        var gate_percent = floor(get_gate_hp_percent());
        var gate_color = (gate_percent > 50) ? c_lime : ((gate_percent > 25) ? c_yellow : c_red);
        draw_set_color(gate_color);
        draw_text(panel_x + 10, y_offset, "성문: " + string(gate_percent) + "%");
    }

    draw_set_color(c_white);
}

// ========================================
// 전투 로그 UI
// ========================================

/// @func draw_combat_log_ui()
function draw_combat_log_ui() {
    if (!variable_global_exists("debug")) return;
    if (!variable_struct_exists(global.debug, "combat_log")) return;

    var log = global.debug.combat_log;
    var log_x = 10;
    var log_y = room_height - 150;
    var log_w = 350;
    var log_h = 140;

    // 배경
    draw_set_alpha(0.5);
    draw_set_color(c_black);
    draw_rectangle(log_x, log_y, log_x + log_w, log_y + log_h, false);
    draw_set_alpha(1);

    // 로그 내용 (최근 7개)
    draw_set_color(c_white);
    var start_idx = max(0, array_length(log) - 7);
    var y_offset = log_y + 5;

    for (var i = start_idx; i < array_length(log); i++) {
        var alpha = 0.5 + (i - start_idx) * 0.1;
        draw_set_alpha(alpha);
        draw_text(log_x + 5, y_offset, log[i]);
        y_offset += 18;
    }

    draw_set_alpha(1);
}

// ========================================
// 게임 시작 함수
// ========================================

/// @func start_battle()
/// @desc 전투 시작 (모든 시스템 초기화)
function start_battle() {
    // 전투 시스템 초기화
    init_combat_system();

    // 웨이브 시스템 초기화
    init_wave_system();

    // 배치 시스템 초기화
    init_deploy_system();

    // 성문 초기화
    init_gate();

    // 디버그 로그 초기화
    if (!variable_global_exists("debug")) {
        global.debug = {};
    }
    global.debug.combat_log = [];
    global.debug.damage_numbers = [];
    global.debug.effects = [];

    // 시작 아군 배치
    spawn_starting_allies();

    // 첫 웨이브 시작
    start_first_wave();

    combat_log("=== 전투 시작 ===");
}

/// @func update_battle(delta)
/// @desc 전투 메인 업데이트
function update_battle(delta) {
    // 웨이브 시스템 업데이트
    update_wave_system(delta);

    // 적 AI 업데이트
    if (variable_global_exists("enemy_units")) {
        for (var i = array_length(global.enemy_units) - 1; i >= 0; i--) {
            var enemy = global.enemy_units[i];
            if (enemy.hp > 0) {
                ai_rush_update(enemy, delta);
            }
        }
    }

    // 아군 AI 업데이트
    if (variable_global_exists("ally_units")) {
        for (var i = array_length(global.ally_units) - 1; i >= 0; i--) {
            var ally = global.ally_units[i];
            if (ally.hp > 0) {
                ai_ally_basic_update(ally, delta);
            }
        }
    }

    // 쿨다운 업데이트
    update_attack_cooldowns(delta);

    // 데미지 숫자 업데이트
    update_damage_numbers();

    // 영혼 시각 효과 업데이트
    update_souls_visual(delta);

    // 죽은 유닛 정리
    cleanup_dead_units();
}

/// @func cleanup_dead_units()
/// @desc 죽은 유닛 목록에서 제거
function cleanup_dead_units() {
    // 적군
    if (variable_global_exists("enemy_units")) {
        for (var i = array_length(global.enemy_units) - 1; i >= 0; i--) {
            if (global.enemy_units[i].hp <= 0) {
                array_delete(global.enemy_units, i, 1);
            }
        }
    }

    // 아군은 영혼으로 변환되므로 kill_unit에서 처리됨
}
