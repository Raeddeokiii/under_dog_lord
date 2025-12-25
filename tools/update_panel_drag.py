#!/usr/bin/env python3
"""Add panel drag and toggle functionality"""

# Update Create_0.gml
create_content = '''/// @description 디버그룸 초기화

// 폰트 로드
global.font_korean = font_add("fonts/DungGeunMo.ttf", 14, false, false, 0xAC00, 0xD7A3);
if (global.font_korean != -1) {
    draw_set_font(global.font_korean);
}

// 데이터 초기화 (종족, 직업, 스킬, 유닛)
init_all_data();

// 종족/직업 목록
global.race_list = ["human", "elf", "dwarf", "orc", "undead", "demon", "slime", "beast", "dragon", "construct"];
global.class_list = ["warrior", "tank", "mage", "priest", "rogue", "archer", "support"];
global.current_race_idx = 0;
global.current_class_idx = 2;

// 드롭다운 상태
global.dropdown = {
    race_open: false,
    class_open: false,
    race_x: 560,
    race_y: 10,
    class_x: 720,
    class_y: 10,
    width: 140,
    item_height: 22
};

// 패널 상태
global.panels = {
    player_stat: { x: 10, y: 10, w: 220, h: 520, collapsed: false, title: "플레이어 유닛" },
    race_bonus: { x: 240, y: 10, w: 200, h: 300, collapsed: false, title: "종족 보너스" },
    target_stat: { x: 1690, y: 10, w: 210, h: 200, collapsed: false, title: "타겟 더미" }
};

// 드래그 상태
global.drag = {
    active: false,
    target: undefined,
    target_type: "",  // "unit" or "panel"
    offset_x: 0,
    offset_y: 0
};

// 디버그 상태
global.debug = {
    player_unit: undefined,
    target_dummy: undefined,
    combat_log: [],
    max_log_lines: 15,
    show_stats: true,
    effects: []
};

// 화염 마법사 생성 (플레이어 유닛)
global.debug.player_unit = create_unit_from_template("fire_mage", "ally", 1);
global.debug.player_unit.x = 700;
global.debug.player_unit.y = 550;

// 타겟 더미 생성
global.debug.target_dummy = create_unit_from_template("target_dummy", "enemy", 1);
global.debug.target_dummy.x = 1200;
global.debug.target_dummy.y = 550;

debug_log("=== 유닛 디버그룸 ===");
debug_log("SPACE: 파이어볼 | R: 더미 리셋");
debug_log("1~9: 레벨 변경");
debug_log("드래그: 유닛/패널 이동");
debug_log("패널 제목 클릭: 접기/펴기");
'''

# Update Step_0.gml
step_content = '''/// @description 디버그룸 업데이트

var player = global.debug.player_unit;
var dummy = global.debug.target_dummy;

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
}

// 스킬 쿨다운 감소
var keys = variable_struct_get_names(player.skill_cooldowns);
for (var i = 0; i < array_length(keys); i++) {
    var key = keys[i];
    var cd = player.skill_cooldowns[$ key];
    if (cd > 0) {
        player.skill_cooldowns[$ key] = max(0, cd - (1/60));
    }
}

// 마나 재생
player.mana = min(player.max_mana, player.mana + player.mana_regen * (1/60));

// 더미 HP 재생
dummy.hp = min(dummy.max_hp, dummy.hp + dummy.hp_regen * (1/60));

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
    debug_use_skill(player, "fireball", dummy);
}

// R: 더미 리셋
if (keyboard_check_pressed(ord("R"))) {
    dummy.hp = dummy.max_hp;
    debug_log("타겟 더미 HP 리셋");
}

// 1~9: 레벨 변경
for (var i = 1; i <= 9; i++) {
    if (keyboard_check_pressed(ord(string(i)))) {
        debug_set_level(player, i);
    }
}
'''

# Update Draw_0.gml
draw_content = '''/// @description 디버그룸 렌더링

if (global.font_korean != -1) {
    draw_set_font(global.font_korean);
}

var player = global.debug.player_unit;
var dummy = global.debug.target_dummy;
var panels = global.panels;

// 배경
draw_set_color(c_dkgray);
draw_rectangle(0, 0, room_width, room_height, false);

// === 유닛 그리기 ===
draw_unit_box(player, c_blue, "플레이어");
draw_unit_box(dummy, c_red, "타겟");

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
    else if (fx.type == "explosion") {
        var progress = fx.timer / fx.max_timer;
        draw_set_alpha(1 - progress);
        draw_set_color(c_red);
        draw_circle(fx.x, fx.y, fx.radius, true);
        draw_circle(fx.x, fx.y, fx.radius * 0.7, true);
        draw_set_alpha((1 - progress) * 0.5);
        draw_set_color(c_orange);
        draw_circle(fx.x, fx.y, fx.radius * 0.5, false);
        draw_set_color(c_yellow);
        draw_circle(fx.x, fx.y, fx.radius * 0.2, false);
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
}
draw_set_alpha(1);

// === 패널 그리기 ===
var p = panels.player_stat;
draw_panel_stat_with_bonus(p.x, p.y, p.w, p.collapsed, player, p.title);

p = panels.race_bonus;
draw_panel_race_bonus(p.x, p.y, p.w, p.collapsed, p.title);

p = panels.target_stat;
draw_panel_stat(p.x, p.y, p.w, p.collapsed, dummy, p.title);

// === 종족/직업 드롭다운 UI ===
draw_dropdown_only();

// === 전투 로그 ===
draw_combat_log(10, room_height - 250);

// === 조작법 ===
draw_set_color(c_yellow);
draw_set_halign(fa_center);
draw_text(room_width/2, room_height - 270, "[SPACE] 파이어볼  [R] 더미 리셋  [1-9] 레벨");
draw_set_halign(fa_left);

// === 쿨다운 표시 ===
var cd = player.skill_cooldowns[$ "fireball"] ?? 0;
if (cd > 0) {
    draw_set_color(c_red);
    draw_text(room_width/2 - 50, room_height - 290, "쿨다운: " + string_format(cd, 1, 1) + "초");
} else {
    draw_set_color(c_lime);
    draw_text(room_width/2 - 50, room_height - 290, "스킬 준비됨!");
}
'''

if __name__ == "__main__":
    with open('D:/gml_game/under_dog_lord/objects/obj_debug_controller/Create_0.gml', 'w', encoding='utf-8') as f:
        f.write(create_content)
    print("Updated Create_0.gml")

    with open('D:/gml_game/under_dog_lord/objects/obj_debug_controller/Step_0.gml', 'w', encoding='utf-8') as f:
        f.write(step_content)
    print("Updated Step_0.gml")

    with open('D:/gml_game/under_dog_lord/objects/obj_debug_controller/Draw_0.gml', 'w', encoding='utf-8') as f:
        f.write(draw_content)
    print("Updated Draw_0.gml")

    print("Done! Added panel drag and toggle.")
