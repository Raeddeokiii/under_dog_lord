/// @description 디버그룸 렌더링

if (global.font_korean != -1) {
    draw_set_font(global.font_korean);
}

// 유닛 유효성 체크 (초기화 전이면 스킵)
if (!variable_struct_exists(global, "debug")) exit;
if (!variable_struct_exists(global.debug, "player_unit")) exit;
if (global.debug.player_unit == undefined || !is_struct(global.debug.player_unit)) exit;

var player = global.debug.player_unit;
var ally = global.debug.ally_unit;
var dummy = global.debug.target_dummy;
var dummy2 = global.debug.enemy_dummy2;
var panels = global.panels;

// display_name 없으면 기본값 설정
if (!variable_struct_exists(player, "display_name")) player.display_name = "플레이어";
if (ally != undefined && is_struct(ally) && !variable_struct_exists(ally, "display_name")) ally.display_name = "아군";
if (dummy != undefined && is_struct(dummy) && !variable_struct_exists(dummy, "display_name")) dummy.display_name = "적1";
if (dummy2 != undefined && is_struct(dummy2) && !variable_struct_exists(dummy2, "display_name")) dummy2.display_name = "적2";

var selected_ally = global.debug.selected_ally;
var selected_enemy = global.debug.selected_enemy;

// 배경
draw_set_color(c_dkgray);
draw_rectangle(0, 0, room_width, room_height, false);

// === 진영 구분 배경 ===
var center_x = room_width / 2;

// 아군 진영 (왼쪽) - 파란 톤
draw_set_alpha(0.08);
draw_set_color(c_blue);
draw_rectangle(center_x - 350, 280, center_x - 50, 720, false);

// 적군 진영 (오른쪽) - 빨간 톤
draw_set_color(c_red);
draw_rectangle(center_x + 50, 280, center_x + 350, 720, false);
draw_set_alpha(1);

// 중앙 구분선
draw_set_color(c_gray);
draw_set_alpha(0.5);
draw_line_width(center_x, 280, center_x, 720, 2);
draw_set_alpha(1);

// 진영 라벨
draw_set_halign(fa_center);
draw_set_color(c_aqua);
draw_text(center_x - 200, 290, "[ 아군 진영 ]");
draw_set_color(c_red);
draw_text(center_x + 200, 290, "[ 적군 진영 ]");
draw_set_halign(fa_left);

// === 현재 선택 상태 표시 (상단 중앙) ===
var sel_panel_x = center_x;
var sel_panel_y = 50;

// 배경
draw_set_alpha(0.8);
draw_set_color(c_black);
draw_roundrect(sel_panel_x - 200, sel_panel_y - 5, sel_panel_x + 200, sel_panel_y + 45, false);
draw_set_color(c_white);
draw_roundrect(sel_panel_x - 200, sel_panel_y - 5, sel_panel_x + 200, sel_panel_y + 45, true);
draw_set_alpha(1);

// 선택 정보
draw_set_halign(fa_center);

var caster_name = (selected_ally != undefined) ? selected_ally.display_name : "없음";
var target_name = (selected_enemy != undefined) ? selected_enemy.display_name : "없음";

// 시전자
draw_set_color(c_yellow);
draw_text(sel_panel_x - 80, sel_panel_y + 5, "시전자");
draw_set_color(c_white);
draw_text(sel_panel_x - 80, sel_panel_y + 22, caster_name);

// 화살표
draw_set_color(c_gray);
draw_text(sel_panel_x, sel_panel_y + 13, "→");

// 타겟
draw_set_color(c_red);
draw_text(sel_panel_x + 80, sel_panel_y + 5, "타겟");
draw_set_color(c_white);
draw_text(sel_panel_x + 80, sel_panel_y + 22, target_name);

draw_set_halign(fa_left);

// 길찾기 시각화 (배경 위, 유닛 아래)
if (global.debug.show_pathfinding) {
    pf_draw_debug(0.2);
    if (global.debug.current_path != undefined) {
        pf_draw_path(global.debug.current_path, c_lime);
    }

    // AI 경로 시각화 (AI가 켜져있을 때) - 모든 유닛
    if (global.debug.ai_enabled) {
        var path_colors = [c_aqua, c_lime, c_orange, c_fuchsia];  // 유닛별 색상
        for (var p_idx = 0; p_idx < array_length(global.debug.all_units); p_idx++) {
            var path_unit = global.debug.all_units[p_idx];
            if (variable_struct_exists(path_unit, "ai") && path_unit.ai != undefined && path_unit.ai.path != undefined) {
                pf_draw_path(path_unit.ai.path, path_colors[p_idx mod 4]);
            }
        }
    }

    // 벽 편집 모드 표시
    if (global.debug.wall_edit_mode) {
        // 마우스 위치에 미리보기
        var grid = pf_pixel_to_grid(mouse_x, mouse_y);
        var px = grid.x * global.pf_cell_size;
        var py = grid.y * global.pf_cell_size;
        draw_set_alpha(0.5);
        draw_set_color(c_white);
        draw_rectangle(px, py, px + global.pf_cell_size - 1, py + global.pf_cell_size - 1, false);
        draw_set_alpha(1.0);
    }
}

// === 사거리 시각화 (선택된 시전자 기준) ===
if (selected_ally != undefined) {
    // 기본 공격 사거리 (파란색)
    var caster_range = selected_ally.attack_range ?? 400;
    draw_set_alpha(0.1);
    draw_set_color(c_blue);
    draw_circle(selected_ally.x, selected_ally.y, caster_range, false);
    draw_set_alpha(0.4);
    draw_circle(selected_ally.x, selected_ally.y, caster_range, true);
    draw_set_alpha(1);

    // 선택된 스킬 사거리 (종족/직업 보정 적용)
    var selected_skill_id = global.skill_list[global.current_skill_idx];
    var selected_skill = get_skill(selected_skill_id);
    if (selected_skill != undefined && variable_struct_exists(selected_skill, "range") && selected_skill.range > 0) {
        // 보정된 스킬 사거리 계산
        var skill_range = get_modified_skill_range(selected_ally, selected_skill);
        var base_range = selected_skill.range;

        // 스킬 타입별 색상
        var skill_color = c_lime;
        var skill_type = selected_skill.damage_type ?? "";
        switch (skill_type) {
            case "fire": skill_color = c_orange; break;
            case "ice": skill_color = c_aqua; break;
            case "physical": skill_color = c_silver; break;
            case "holy": skill_color = c_yellow; break;
        }

        // 보정된 사거리 (채워진 원)
        draw_set_alpha(0.15);
        draw_set_color(skill_color);
        draw_circle(selected_ally.x, selected_ally.y, skill_range, false);
        draw_set_alpha(0.6);
        draw_circle(selected_ally.x, selected_ally.y, skill_range, true);

        // 기본 사거리와 다르면 기본 사거리도 점선으로 표시
        if (base_range != skill_range) {
            draw_set_alpha(0.3);
            draw_set_color(c_gray);
            draw_circle(selected_ally.x, selected_ally.y, base_range, true);
        }
        draw_set_alpha(1);
    }
}

// === 보호자 시각화 (모든 유닛 체크) ===
for (var gi = 0; gi < array_length(global.debug.all_units); gi++) {
    var check_unit = global.debug.all_units[gi];

    // 이 유닛이 보호자인지 확인
    if (is_guardian(check_unit)) {
        var protected_unit = get_protected_unit(check_unit);
        if (protected_unit != undefined) {
            var guardian_unit = check_unit;

            // 보호 연결선 (점선 스타일)
            draw_set_color(c_aqua);
            draw_set_alpha(0.7);

            var gx_diff = protected_unit.x - guardian_unit.x;
            var gy_diff = protected_unit.y - guardian_unit.y;
            var g_dist = sqrt(gx_diff*gx_diff + gy_diff*gy_diff);
            var g_segments = floor(g_dist / 20);

            for (var seg = 0; seg < g_segments; seg++) {
                if (seg mod 2 == 0) {
                    var t1 = seg / g_segments;
                    var t2 = (seg + 1) / g_segments;
                    var x1 = guardian_unit.x + gx_diff * t1;
                    var y1 = guardian_unit.y + gy_diff * t1;
                    var x2 = guardian_unit.x + gx_diff * t2;
                    var y2 = guardian_unit.y + gy_diff * t2;
                    draw_line_width(x1, y1, x2, y2, 2);
                }
            }

            // 보호자 방패 오라
            draw_set_color(c_aqua);
            draw_set_alpha(0.25);
            draw_circle(guardian_unit.x, guardian_unit.y, 55, false);
            draw_set_alpha(0.5);
            draw_circle(guardian_unit.x, guardian_unit.y, 55, true);

            // 보호받는 유닛 보호막
            draw_set_color(c_lime);
            draw_set_alpha(0.2);
            draw_circle(protected_unit.x, protected_unit.y, 50, false);
            draw_set_alpha(0.6);
            draw_circle(protected_unit.x, protected_unit.y, 50, true);

            draw_set_alpha(1);

            // 상태 텍스트
            draw_set_halign(fa_center);
            draw_set_color(c_aqua);
            draw_text(guardian_unit.x, guardian_unit.y - 85, "[보호 중]");
            draw_set_color(c_lime);
            draw_text(protected_unit.x, protected_unit.y - 85, "[보호받음]");
            draw_set_halign(fa_left);
        }
    }
}

// === 결투 시각화 (모든 유닛 체크) ===
var duel_drawn = ds_map_create();  // 이미 그린 결투 쌍 추적

for (var di = 0; di < array_length(global.debug.all_units); di++) {
    var duel_unit = global.debug.all_units[di];

    if (is_in_duel(duel_unit)) {
        var duel_opp = get_duel_opponent(duel_unit);
        if (duel_opp != undefined) {
            // 이미 그린 쌍인지 확인 (display_name 기반)
            var name1 = duel_unit.display_name ?? string(di);
            var name2 = duel_opp.display_name ?? "opponent";
            // 정렬된 순서로 키 생성 (중복 방지)
            var pair_key = (name1 < name2) ? (name1 + "_" + name2) : (name2 + "_" + name1);

            if (!ds_map_exists(duel_drawn, pair_key)) {
                ds_map_add(duel_drawn, pair_key, true);

                // 결투 연결선
                draw_set_color(c_orange);
                draw_set_alpha(0.6);
                draw_line_width(duel_unit.x, duel_unit.y, duel_opp.x, duel_opp.y, 3);
                draw_set_alpha(1);

                // 결투 영역 표시
                draw_set_alpha(0.15);
                draw_circle(duel_unit.x, duel_unit.y, 60, false);
                draw_circle(duel_opp.x, duel_opp.y, 60, false);
                draw_set_alpha(1);

                // 중앙에 결투 텍스트
                var mid_x = (duel_unit.x + duel_opp.x) / 2;
                var mid_y = (duel_unit.y + duel_opp.y) / 2;
                draw_set_halign(fa_center);
                draw_set_color(c_orange);
                draw_text(mid_x, mid_y - 15, "[ 결투 중 ]");
                draw_set_halign(fa_left);
            }
        }
    }
}
ds_map_destroy(duel_drawn);

// === 유닛 그리기 (선택 표시 포함) ===

// 선택 표시 함수 (로컬)
var draw_selection_indicator = function(unit, is_caster, is_target) {
    if (!is_caster && !is_target) return;

    var sel_size = 55;
    var pulse = (sin(current_time / 150) + 1) / 2;  // 0~1 펄스

    // 선택 테두리
    if (is_caster) {
        // 시전자 = 노란 테두리 + 화살표
        draw_set_color(c_yellow);
        draw_set_alpha(0.6 + pulse * 0.4);
        draw_rectangle(unit.x - sel_size, unit.y - sel_size, unit.x + sel_size, unit.y + sel_size, true);
        draw_rectangle(unit.x - sel_size - 2, unit.y - sel_size - 2, unit.x + sel_size + 2, unit.y + sel_size + 2, true);

        // 위쪽 화살표 표시
        draw_set_halign(fa_center);
        draw_text(unit.x, unit.y - sel_size - 20, "▼ 시전자");
        draw_set_halign(fa_left);
    }
    if (is_target) {
        // 타겟 = 빨간 테두리 + 타겟 마크
        draw_set_color(c_red);
        draw_set_alpha(0.6 + pulse * 0.4);
        draw_circle(unit.x, unit.y, sel_size + 5, true);
        draw_circle(unit.x, unit.y, sel_size + 10, true);

        // 타겟 마크
        draw_line_width(unit.x - 15, unit.y, unit.x - 5, unit.y, 3);
        draw_line_width(unit.x + 5, unit.y, unit.x + 15, unit.y, 3);
        draw_line_width(unit.x, unit.y - 15, unit.x, unit.y - 5, 3);
        draw_line_width(unit.x, unit.y + 5, unit.x, unit.y + 15, 3);

        draw_set_halign(fa_center);
        draw_text(unit.x, unit.y - sel_size - 20, "◎ 타겟");
        draw_set_halign(fa_left);
    }
    draw_set_alpha(1);
};

// 선택 표시 그리기 (활성화된 유닛만)
draw_selection_indicator(player, player == selected_ally, player == selected_enemy);
if (global.debug.ally_count >= 2) {
    draw_selection_indicator(ally, ally == selected_ally, ally == selected_enemy);
}
draw_selection_indicator(dummy, dummy == selected_ally, dummy == selected_enemy);
if (global.debug.enemy_count >= 2) {
    draw_selection_indicator(dummy2, dummy2 == selected_ally, dummy2 == selected_enemy);
}

// 유닛 박스 그리기 (활성화된 유닛만)
draw_unit_box(player, c_blue, player.display_name ?? "플레이어");
if (global.debug.ally_count >= 2) {
    draw_unit_box(ally, c_aqua, ally.display_name ?? "아군");
}
draw_unit_box(dummy, c_red, dummy.display_name ?? "적1");
if (global.debug.enemy_count >= 2) {
    draw_unit_box(dummy2, c_maroon, dummy2.display_name ?? "적2");
}

// === 상태이상 아이콘 그리기 (활성화된 유닛만) ===
draw_status_icons(player, player.x, player.y - 70);
if (global.debug.ally_count >= 2) {
    draw_status_icons(ally, ally.x, ally.y - 70);
}
draw_status_icons(dummy, dummy.x, dummy.y - 70);
if (global.debug.enemy_count >= 2) {
    draw_status_icons(dummy2, dummy2.x, dummy2.y - 70);
}

// === 시전자 → 타겟 연결선 ===
if (selected_ally != undefined && selected_enemy != undefined) {
    var ax = selected_ally.x;
    var ay = selected_ally.y;
    var ex = selected_enemy.x;
    var ey = selected_enemy.y;

    // 점선으로 연결
    draw_set_color(c_yellow);
    draw_set_alpha(0.4);
    var dist = point_distance(ax, ay, ex, ey);
    var segments = floor(dist / 30);
    var dx = (ex - ax) / dist;
    var dy = (ey - ay) / dist;

    for (var seg = 0; seg < segments; seg++) {
        if (seg mod 2 == 0) {
            var t1 = seg / segments;
            var t2 = (seg + 0.5) / segments;
            draw_line_width(ax + dx * dist * t1, ay + dy * dist * t1,
                          ax + dx * dist * t2, ay + dy * dist * t2, 2);
        }
    }

    // 화살표 머리
    var arrow_x = ex - dx * 60;
    var arrow_y = ey - dy * 60;
    draw_set_alpha(0.7);
    draw_triangle(ex - dx * 55 - dy * 10, ey - dy * 55 + dx * 10,
                  ex - dx * 55 + dy * 10, ey - dy * 55 - dx * 10,
                  ex - dx * 45, ey - dy * 45, false);
    draw_set_alpha(1);
}

// === 이펙트 그리기 ===
for (var i = 0; i < array_length(global.debug.effects); i++) {
    var fx = global.debug.effects[i];

    if (fx.type == "fireball") {
        draw_set_alpha(0.3);
        draw_set_color(c_red);
        draw_circle(fx.x, fx.y, 20, false);
        draw_set_alpha(1);
        draw_set_color(c_orange);
        draw_circle(fx.x, fx.y, 12, false);
        draw_set_color(c_yellow);
        draw_circle(fx.x, fx.y, 6, false);
    }
    else if (fx.type == "projectile") {
        var proj_color = variable_struct_exists(fx, "color") ? fx.color : c_white;
        draw_set_alpha(0.3);
        draw_set_color(proj_color);
        draw_circle(fx.x, fx.y, 20, false);
        draw_set_alpha(1);
        draw_circle(fx.x, fx.y, 12, false);
        draw_set_color(c_white);
        draw_circle(fx.x, fx.y, 6, false);
    }
    else if (fx.type == "explosion") {
        var progress = fx.timer / fx.max_timer;
        var exp_color = variable_struct_exists(fx, "color") ? fx.color : c_red;
        draw_set_alpha(1 - progress);
        draw_set_color(exp_color);
        draw_circle(fx.x, fx.y, fx.radius, true);
        draw_circle(fx.x, fx.y, fx.radius * 0.7, true);
        draw_set_alpha((1 - progress) * 0.5);
        draw_circle(fx.x, fx.y, fx.radius * 0.5, false);
        draw_set_color(c_white);
        draw_circle(fx.x, fx.y, fx.radius * 0.2, false);
    }
    else if (fx.type == "heal_effect") {
        var heal_color = variable_struct_exists(fx, "color") ? fx.color : c_lime;
        var progress = fx.timer / fx.max_timer;
        draw_set_alpha(progress);
        draw_set_color(heal_color);
        // 상승하는 + 기호
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text(fx.x, fx.y, "+");
        draw_text(fx.x - 15, fx.y + 10, "+");
        draw_text(fx.x + 15, fx.y + 10, "+");
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        // 원형 이펙트
        draw_set_alpha(progress * 0.3);
        draw_circle(fx.x, fx.y + 20, 30 * (1 - progress * 0.5), true);
    }
    else if (fx.type == "particle") {
        draw_set_alpha(fx.timer / 15);
        draw_set_color(fx.color);
        draw_circle(fx.x, fx.y, fx.size, false);
    }
    else if (fx.type == "dot_tick") {
        draw_set_alpha(fx.timer / 30);
        draw_set_color(c_orange);
        draw_set_halign(fa_center);
        draw_text(fx.x, fx.y, fx.text);
        draw_set_halign(fa_left);
    }
    else if (fx.type == "status_text") {
        draw_set_alpha(fx.timer / fx.max_timer);
        draw_set_color(fx.color);
        draw_set_halign(fa_center);
        draw_text(fx.x, fx.y, fx.text);
        draw_set_halign(fa_left);
    }
    else if (fx.type == "buff_effect") {
        var progress = 1 - (fx.timer / fx.max_timer);
        var buff_color = variable_struct_exists(fx, "color") ? fx.color : c_lime;
        // 확산하는 원 이펙트
        draw_set_alpha((1 - progress) * 0.6);
        draw_set_color(buff_color);
        draw_circle(fx.x, fx.y, 30 + progress * 40, true);
        draw_circle(fx.x, fx.y, 20 + progress * 30, true);
        // 중앙 빛
        draw_set_alpha((1 - progress) * 0.4);
        draw_circle(fx.x, fx.y, 15, false);
    }
    else if (fx.type == "damage_redirect") {
        // 피해가 보호자에게 날아가는 애니메이션
        var prog = fx.progress;
        var cur_x = lerp(fx.start_x, fx.end_x, prog);
        var cur_y = lerp(fx.start_y, fx.end_y, prog);

        // 빨간 피해 구체
        draw_set_alpha(1 - prog * 0.5);
        draw_set_color(c_red);
        draw_circle(cur_x, cur_y, 12, false);
        draw_set_color(c_orange);
        draw_circle(cur_x, cur_y, 8, false);
        draw_set_color(c_yellow);
        draw_circle(cur_x, cur_y, 4, false);

        // 이동 궤적
        draw_set_alpha(0.3);
        draw_set_color(c_red);
        draw_line_width(fx.start_x, fx.start_y, cur_x, cur_y, 2);

        // "대신!" 텍스트
        draw_set_alpha(1);
        draw_set_halign(fa_center);
        draw_set_color(c_red);
        draw_text(cur_x, cur_y - 20, "대신!");
        draw_set_halign(fa_left);
    }
    else if (fx.type == "redirect_impact") {
        // 보호자가 피해를 받는 임팩트 이펙트
        var prog = 1 - (fx.timer / fx.max_timer);
        draw_set_alpha(1 - prog);
        draw_set_color(c_red);
        draw_circle(fx.x, fx.y, 20 + prog * 30, true);
        draw_set_color(c_orange);
        draw_circle(fx.x, fx.y, 10 + prog * 20, true);

        // 중앙 플래시
        draw_set_alpha((1 - prog) * 0.5);
        draw_set_color(c_white);
        draw_circle(fx.x, fx.y, 15, false);
    }
    else if (fx.type == "slash") {
        // 근접 슬래시 이펙트
        var prog = fx.timer / fx.max_timer;  // 0 → 1
        var slash_alpha = 1 - prog;
        var slash_size = fx.size * (0.5 + prog * 0.5);
        var slash_width = 8 - prog * 6;
        var dir = fx.direction;

        // 슬래시 아크 그리기 (3개의 호로 구성)
        draw_set_alpha(slash_alpha);

        // 메인 슬래시
        draw_set_color(fx.color);
        var arc_start = dir - 45 + prog * 30;
        var arc_end = dir + 45 - prog * 30;
        var arc_steps = 8;

        for (var ai = 0; ai < arc_steps; ai++) {
            var t1 = ai / arc_steps;
            var t2 = (ai + 1) / arc_steps;
            var a1 = lerp(arc_start, arc_end, t1);
            var a2 = lerp(arc_start, arc_end, t2);

            var x1 = fx.x + lengthdir_x(slash_size, a1);
            var y1 = fx.y + lengthdir_y(slash_size, a1);
            var x2 = fx.x + lengthdir_x(slash_size, a2);
            var y2 = fx.y + lengthdir_y(slash_size, a2);

            draw_line_width(x1, y1, x2, y2, slash_width);
        }

        // 치명타면 추가 이펙트
        if (fx.is_crit) {
            draw_set_color(c_orange);
            draw_set_alpha(slash_alpha * 0.6);
            var inner_size = slash_size * 0.7;
            for (var ai = 0; ai < arc_steps; ai++) {
                var t1 = ai / arc_steps;
                var t2 = (ai + 1) / arc_steps;
                var a1 = lerp(arc_start, arc_end, t1);
                var a2 = lerp(arc_start, arc_end, t2);

                var x1 = fx.x + lengthdir_x(inner_size, a1);
                var y1 = fx.y + lengthdir_y(inner_size, a1);
                var x2 = fx.x + lengthdir_x(inner_size, a2);
                var y2 = fx.y + lengthdir_y(inner_size, a2);

                draw_line_width(x1, y1, x2, y2, slash_width * 0.6);
            }

            // 스파크 파티클
            draw_set_color(c_yellow);
            draw_set_alpha(slash_alpha);
            for (var sp = 0; sp < 3; sp++) {
                var spark_dir = dir + random_range(-60, 60);
                var spark_dist = slash_size * (0.3 + random(0.5));
                var spark_x = fx.x + lengthdir_x(spark_dist, spark_dir);
                var spark_y = fx.y + lengthdir_y(spark_dist, spark_dir);
                draw_circle(spark_x, spark_y, 2 + random(2), false);
            }
        }

        // 임팩트 플래시 (시작 시)
        if (prog < 0.3) {
            draw_set_alpha((0.3 - prog) * 2);
            draw_set_color(c_white);
            draw_circle(fx.x, fx.y, 15 * (1 - prog), false);
        }
    }
}
draw_set_alpha(1);

// === 패널 그리기 ===
// === 좌측 - 아군 패널 (선택된 아군 기준) ===
var panel_unit = selected_ally ?? player;
var panel_title = (panel_unit != undefined) ? panel_unit.display_name : "유닛";

var p = panels.ally_stat;
draw_panel_stat_with_bonus(p.x, p.y, p.w, p.collapsed, panel_unit, panel_title);

p = panels.ally_race;
draw_panel_race_bonus(p.x, p.y, p.w, p.collapsed, p.title, panel_unit);

p = panels.ally_class;
draw_panel_class_bonus(p.x, p.y, p.w, p.collapsed, p.title, panel_unit);

p = panels.ally_talent;
draw_panel_talent(p.x, p.y, p.w, p.collapsed, panel_unit, p.title);

// === 우측 - 적군 패널 (선택된 적군 기준) ===
var target_unit = selected_enemy ?? dummy;
var target_title = (target_unit != undefined) ? target_unit.display_name : "적";

p = panels.enemy_stat;
draw_panel_stat_with_bonus(p.x, p.y, p.w, p.collapsed, target_unit, target_title);

p = panels.enemy_race;
draw_panel_race_bonus(p.x, p.y, p.w, p.collapsed, p.title, target_unit);

p = panels.enemy_class;
draw_panel_class_bonus(p.x, p.y, p.w, p.collapsed, p.title, target_unit);

p = panels.enemy_talent;
draw_panel_talent(p.x, p.y, p.w, p.collapsed, target_unit, p.title);

// === 종족/직업/재능 드롭다운 UI ===
// 현재 설정 대상 유닛 표시
var dropdown_target = undefined;
var dropdown_side = global.debug.last_selected_side ?? "ally";
if (dropdown_side == "ally") {
    dropdown_target = selected_ally;
} else {
    dropdown_target = selected_enemy;
}
var dropdown_name = (dropdown_target != undefined) ? dropdown_target.display_name : "없음";
var dropdown_color = (dropdown_side == "ally") ? c_aqua : c_red;

draw_set_halign(fa_right);
draw_set_color(dropdown_color);
draw_text(global.dropdown.race_x - 10, global.dropdown.race_y + 3, "설정 대상: " + dropdown_name);
draw_set_halign(fa_left);

draw_dropdown_only();

// === 전투 로그 ===
draw_combat_log(300, room_height - 250);

// === 버튼 패널 렌더링 ===
var panel_y = room_height - 200;
var left_panel_x = 50;
var right_panel_x = room_width - 350;
center_x = room_width / 2;

// 왼쪽 패널 배경 (아군 조작)
draw_set_alpha(0.8);
draw_set_color(c_black);
draw_roundrect(left_panel_x - 15, panel_y - 35, left_panel_x + 310, panel_y + 100, false);
draw_set_color(c_blue);
draw_roundrect(left_panel_x - 15, panel_y - 35, left_panel_x + 310, panel_y + 100, true);
draw_set_alpha(1);

// 왼쪽 패널 제목
draw_set_halign(fa_left);
draw_set_color(c_aqua);
draw_text(left_panel_x, panel_y - 30, "[ 아군 조작 ]");

// 오른쪽 패널 배경 (적군 조작)
draw_set_alpha(0.8);
draw_set_color(c_black);
draw_roundrect(right_panel_x - 15, panel_y - 35, right_panel_x + 210, panel_y + 100, false);
draw_set_color(c_red);
draw_roundrect(right_panel_x - 15, panel_y - 35, right_panel_x + 210, panel_y + 100, true);
draw_set_alpha(1);

// 오른쪽 패널 제목
draw_set_color(c_red);
draw_text(right_panel_x, panel_y - 30, "[ 적군 조작 ]");

// 중앙 패널 배경 (공용)
draw_set_alpha(0.8);
draw_set_color(c_black);
draw_roundrect(center_x - 130, panel_y - 15, center_x + 130, panel_y + 85, false);
draw_set_color(c_white);
draw_roundrect(center_x - 130, panel_y - 15, center_x + 130, panel_y + 85, true);
draw_set_alpha(1);

// 버튼 그리기
for (var bi = 0; bi < array_length(global.debug.buttons); bi++) {
    var btn = global.debug.buttons[bi];

    // 동적 라벨 업데이트
    if (btn.id == "ally_count") btn.label = string(global.debug.ally_count) + "명";
    if (btn.id == "enemy_count") btn.label = string(global.debug.enemy_count) + "명";
    if (btn.id == "target_mode") {
        var mode_labels = ["타겟:모두", "타겟:플레이어", "타겟:아군"];
        btn.label = mode_labels[global.debug.enemy_target_mode];
    }

    // 토글 버튼 상태 체크
    var is_active = false;
    if (btn.id == "auto_attack") is_active = global.debug.enemy_auto_attack;
    if (btn.id == "ignore_cd") is_active = global.debug.enemy_ignore_cooldown;
    if (btn.id == "infinite_mana") is_active = global.debug.enemy_infinite_mana;
    if (btn.id == "ally_count") is_active = (global.debug.ally_count == 2);
    if (btn.id == "enemy_count") is_active = (global.debug.enemy_count == 2);
    if (btn.id == "target_mode") is_active = (global.debug.enemy_target_mode != 0);
    if (btn.id == "ally_auto_attack") is_active = global.debug.ally_auto_attack;

    // 버튼 배경
    var btn_color = btn.color;
    if (btn.hover) {
        draw_set_alpha(1);
        btn_color = merge_color(btn.color, c_white, 0.3);
    } else {
        draw_set_alpha(0.8);
    }

    // 토글 버튼은 활성화시 더 밝게
    if (is_active) {
        btn_color = merge_color(btn.color, c_white, 0.5);
        draw_set_alpha(1);
    }

    draw_set_color(btn_color);
    draw_roundrect(btn.x, btn.y, btn.x + btn.w, btn.y + btn.h, false);

    // 버튼 테두리
    draw_set_color(c_white);
    draw_set_alpha(btn.hover ? 1 : 0.5);
    draw_roundrect(btn.x, btn.y, btn.x + btn.w, btn.y + btn.h, true);
    draw_set_alpha(1);

    // 버튼 텍스트
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_black);
    draw_text(btn.x + btn.w/2 + 1, btn.y + btn.h/2 + 1, btn.label);  // 그림자
    draw_set_color(c_white);
    draw_text(btn.x + btn.w/2, btn.y + btn.h/2, btn.label);
    draw_set_valign(fa_top);
    draw_set_halign(fa_left);
}

draw_set_halign(fa_left);

// === 부활 타이머 표시 (죽은 유닛 위에) ===
for (var rti = 0; rti < array_length(global.debug.all_units); rti++) {
    var rt_unit = global.debug.all_units[rti];
    var rt_key = string(rti);

    if (rt_unit.hp <= 0 && ds_map_exists(global.debug.respawn_timers, rt_key)) {
        var remain = ds_map_find_value(global.debug.respawn_timers, rt_key);

        // 죽은 유닛 표시 (어둡게)
        draw_set_alpha(0.3);
        draw_set_color(c_gray);
        draw_circle(rt_unit.x, rt_unit.y, 40, false);
        draw_set_alpha(1);

        // 부활 타이머 표시
        draw_set_halign(fa_center);
        draw_set_color(c_yellow);
        draw_text(rt_unit.x, rt_unit.y - 20, "부활: " + string_format(remain, 1, 1) + "초");
        draw_set_color(c_red);
        draw_text(rt_unit.x, rt_unit.y, "X");
        draw_set_halign(fa_left);
    }
}

// === 선택된 스킬 정보 표시 ===
var caster = global.debug.selected_ally;
var skill_id = global.skill_list[global.current_skill_idx];
var skill_info = get_skill(skill_id);

draw_set_halign(fa_center);

if (caster != undefined && skill_info != undefined) {
    var cd = caster.skill_cooldowns[$ skill_id] ?? 0;
    var skill_name = skill_info.name ?? skill_id;

    // 스킬 이름 + 사거리 표시
    var base_range = skill_info.range ?? 0;
    var modified_range = get_modified_skill_range(caster, skill_info);
    var range_text = "";
    if (base_range > 0) {
        if (base_range != modified_range) {
            range_text = " [사거리: " + string(modified_range) + " (기본:" + string(base_range) + ")]";
        } else {
            range_text = " [사거리: " + string(base_range) + "]";
        }
    }

    draw_set_color(c_white);
    draw_text(room_width/2, room_height - 345, "선택 스킬: " + skill_name + range_text);

    // 쿨다운/사용 가능 상태
    if (cd > 0) {
        draw_set_color(c_red);
        draw_text(room_width/2, room_height - 328, "쿨다운: " + string_format(cd, 1, 1) + "초");
    } else if (!can_use_skill(caster)) {
        draw_set_color(c_orange);
        draw_text(room_width/2, room_height - 328, caster.display_name + " 스킬 불가 (CC 상태)");
    } else {
        draw_set_color(c_lime);
        draw_text(room_width/2, room_height - 328, "사용 가능! [SPACE]");
    }
} else {
    draw_set_color(c_gray);
    draw_text(room_width/2, room_height - 340, "시전자를 선택하세요");
}
draw_set_halign(fa_left);
