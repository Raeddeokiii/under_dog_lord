/// @description 디버그룸 업데이트

var player = global.debug.player_unit;
var dummy = global.debug.target_dummy;
var delta = 1/60;

// === 상태이상 업데이트 ===
update_status_effects(player, delta);
update_status_effects(dummy, delta);

// === 이펙트 업데이트 ===
for (var i = array_length(global.debug.effects) - 1; i >= 0; i--) {
    var fx = global.debug.effects[i];

    if (fx.type == "fireball") {
        var dx = fx.target_x - fx.x;
        var dy = fx.target_y - fx.y;
        var dist = sqrt(dx*dx + dy*dy);

        if (dist < fx.speed) {
            fx.type = "explosion";
            fx.x = fx.target_x;
            fx.y = fx.target_y;
            fx.timer = 0;
            fx.max_timer = 20;
            fx.radius = 10;
        } else {
            fx.x += (dx / dist) * fx.speed;
            fx.y += (dy / dist) * fx.speed;

            if (fx.trail_timer <= 0) {
                array_push(global.debug.effects, {
                    type: "particle",
                    x: fx.x + random_range(-5, 5),
                    y: fx.y + random_range(-5, 5),
                    timer: 15,
                    size: random_range(3, 8),
                    color: choose(c_orange, c_red, c_yellow)
                });
                fx.trail_timer = 2;
            } else {
                fx.trail_timer--;
            }
        }
    }
    else if (fx.type == "explosion") {
        fx.timer++;
        fx.radius = 10 + fx.timer * 3;
        if (fx.timer >= fx.max_timer) {
            array_delete(global.debug.effects, i, 1);
        }
    }
    else if (fx.type == "particle") {
        fx.timer--;
        fx.size *= 0.9;
        if (fx.timer <= 0) {
            array_delete(global.debug.effects, i, 1);
        }
    }
    else if (fx.type == "dot_tick") {
        fx.timer--;
        fx.y -= 1;
        if (fx.timer <= 0) {
            array_delete(global.debug.effects, i, 1);
        }
    }
    else if (fx.type == "status_text") {
        fx.timer--;
        fx.y -= 0.5;
        if (fx.timer <= 0) {
            array_delete(global.debug.effects, i, 1);
        }
    }
}

// 스킬 쿨다운 감소
var keys = variable_struct_get_names(player.skill_cooldowns);
for (var i = 0; i < array_length(keys); i++) {
    var key = keys[i];
    var cd = player.skill_cooldowns[$ key];
    if (cd > 0) {
        player.skill_cooldowns[$ key] = max(0, cd - delta);
    }
}

// 마나 재생
player.mana = min(player.max_mana, player.mana + player.mana_regen * delta);

// 더미 HP 재생
dummy.hp = min(dummy.max_hp, dummy.hp + dummy.hp_regen * delta);

// === 마우스 입력 처리 ===
var mx = mouse_x;
var my = mouse_y;
var dd = global.dropdown;
var drag = global.drag;
var panels = global.panels;
var unit_size = 40;
var header_h = 24;

// 마우스 클릭
if (mouse_check_button_pressed(mb_left)) {
    var clicked_something = false;

    // 드롭다운 처리 (우선순위 높음)
    if (dd.race_open || dd.class_open) {
        // 드롭다운 리스트 클릭 처리
        if (dd.race_open) {
            var list_y = dd.race_y + dd.item_height;
            for (var i = 0; i < array_length(global.race_list); i++) {
                var item_y1 = list_y + i * dd.item_height;
                var item_y2 = item_y1 + dd.item_height;
                if (point_in_rectangle(mx, my, dd.race_x, item_y1, dd.race_x + dd.width, item_y2)) {
                    global.current_race_idx = i;
                    dd.race_open = false;
                    debug_recreate_player();
                    clicked_something = true;
                    break;
                }
            }
            if (!clicked_something) dd.race_open = false;
        }
        if (dd.class_open) {
            var list_y = dd.class_y + dd.item_height;
            for (var i = 0; i < array_length(global.class_list); i++) {
                var item_y1 = list_y + i * dd.item_height;
                var item_y2 = item_y1 + dd.item_height;
                if (point_in_rectangle(mx, my, dd.class_x, item_y1, dd.class_x + dd.width, item_y2)) {
                    global.current_class_idx = i;
                    dd.class_open = false;
                    debug_recreate_player();
                    clicked_something = true;
                    break;
                }
            }
            if (!clicked_something) dd.class_open = false;
        }
        clicked_something = true;
    }

    // 드롭다운 버튼 클릭
    if (!clicked_something) {
        if (point_in_rectangle(mx, my, dd.race_x, dd.race_y, dd.race_x + dd.width, dd.race_y + dd.item_height)) {
            dd.race_open = !dd.race_open;
            dd.class_open = false;
            clicked_something = true;
        }
        else if (point_in_rectangle(mx, my, dd.class_x, dd.class_y, dd.class_x + dd.width, dd.class_y + dd.item_height)) {
            dd.class_open = !dd.class_open;
            dd.race_open = false;
            clicked_something = true;
        }
    }

    // 패널 헤더 클릭 (토글 또는 드래그 시작)
    if (!clicked_something) {
        var panel_names = variable_struct_get_names(panels);
        for (var i = 0; i < array_length(panel_names); i++) {
            var pname = panel_names[i];
            var p = panels[$ pname];
            if (point_in_rectangle(mx, my, p.x, p.y, p.x + p.w, p.y + header_h)) {
                // 더블클릭 체크를 위한 간단한 토글 (일단 단일 클릭으로 처리)
                // 오른쪽 끝 20px는 접기 버튼
                if (mx > p.x + p.w - 25) {
                    p.collapsed = !p.collapsed;
                } else {
                    // 드래그 시작
                    drag.active = true;
                    drag.target = p;
                    drag.target_type = "panel";
                    drag.offset_x = p.x - mx;
                    drag.offset_y = p.y - my;
                }
                clicked_something = true;
                break;
            }
        }
    }

    // 유닛 클릭 (드래그 시작)
    if (!clicked_something) {
        if (point_in_rectangle(mx, my, player.x - unit_size, player.y - unit_size, player.x + unit_size, player.y + unit_size)) {
            drag.active = true;
            drag.target = player;
            drag.target_type = "unit";
            drag.offset_x = player.x - mx;
            drag.offset_y = player.y - my;
            clicked_something = true;
        }
        else if (point_in_rectangle(mx, my, dummy.x - unit_size, dummy.y - unit_size, dummy.x + unit_size, dummy.y + unit_size)) {
            drag.active = true;
            drag.target = dummy;
            drag.target_type = "unit";
            drag.offset_x = dummy.x - mx;
            drag.offset_y = dummy.y - my;
            clicked_something = true;
        }
    }
}

// 드래그 중
if (drag.active && mouse_check_button(mb_left)) {
    drag.target.x = mx + drag.offset_x;
    drag.target.y = my + drag.offset_y;
}

// 드래그 종료
if (mouse_check_button_released(mb_left)) {
    drag.active = false;
    drag.target = undefined;
    drag.target_type = "";
}

// === 키보드 입력 처리 ===

// SPACE: 파이어볼 사용
if (keyboard_check_pressed(vk_space)) {
    if (can_use_skill(player)) {
        debug_use_skill(player, "fireball", dummy);
    } else {
        debug_log("스킬 사용 불가! (기절/침묵 상태)");
    }
}

// R: 더미 리셋
if (keyboard_check_pressed(ord("R"))) {
    dummy.hp = dummy.max_hp;
    remove_status_effect(dummy);  // 모든 상태이상 제거
    debug_log("타겟 더미 HP 리셋 및 상태이상 해제");
}

// 1~9: 레벨 변경
for (var i = 1; i <= 9; i++) {
    if (keyboard_check_pressed(ord(string(i)))) {
        debug_set_level(player, i);
    }
}

// === 상태이상 테스트 키 ===
// T: 플레이어에게 기절 2초
if (keyboard_check_pressed(ord("T"))) {
    var result = apply_status_effect(player, {
        type: "stun",
        duration: 2.0,
        source_id: -1
    });
    if (result) {
        debug_log("플레이어 기절! (2초, CC저항 적용됨)");
        debug_show_status_text(player, "기절!", c_yellow);
    } else {
        debug_log("기절 면역!");
        debug_show_status_text(player, "면역!", c_gray);
    }
}

// Y: 플레이어에게 둔화 50% 3초
if (keyboard_check_pressed(ord("Y"))) {
    var result = apply_status_effect(player, {
        type: "slow",
        duration: 3.0,
        amount: 50,
        source_id: -1
    });
    if (result) {
        var slow_amt = get_slow_amount(player);
        debug_log("플레이어 둔화! (" + string(floor(slow_amt)) + "%, 디버프저항 적용됨)");
        debug_show_status_text(player, "둔화!", c_aqua);
    } else {
        debug_log("둔화 면역!");
    }
}

// U: 플레이어에게 속박 1.5초
if (keyboard_check_pressed(ord("U"))) {
    var result = apply_status_effect(player, {
        type: "root",
        duration: 1.5,
        source_id: -1
    });
    if (result) {
        debug_log("플레이어 속박! (CC저항 적용됨)");
        debug_show_status_text(player, "속박!", c_green);
    } else {
        debug_log("속박 면역!");
    }
}

// I: 플레이어에게 침묵 2초
if (keyboard_check_pressed(ord("I"))) {
    var result = apply_status_effect(player, {
        type: "silence",
        duration: 2.0,
        source_id: -1
    });
    if (result) {
        debug_log("플레이어 침묵! (CC저항 적용됨)");
        debug_show_status_text(player, "침묵!", c_purple);
    } else {
        debug_log("침묵 면역!");
    }
}

// C: 모든 CC 해제 (정화)
if (keyboard_check_pressed(ord("C"))) {
    cleanse_cc(player);
    debug_log("CC 정화!");
    debug_show_status_text(player, "정화!", c_white);
}
