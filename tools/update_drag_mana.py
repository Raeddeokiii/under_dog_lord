#!/usr/bin/env python3
"""Add mana bar and drag functionality"""

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
    race_x: 240,
    race_y: 10,
    class_x: 400,
    class_y: 10,
    width: 140,
    item_height: 22
};

// 드래그 상태
global.drag = {
    active: false,
    target: undefined,
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
global.debug.player_unit.x = 600;
global.debug.player_unit.y = 500;

// 타겟 더미 생성
global.debug.target_dummy = create_unit_from_template("target_dummy", "enemy", 1);
global.debug.target_dummy.x = 1300;
global.debug.target_dummy.y = 500;

debug_log("=== 유닛 디버그룸 ===");
debug_log("화염 마법사 (Lv.1) 생성됨");
debug_log("타겟 더미 생성됨");
debug_log("");
debug_log("[조작법]");
debug_log("SPACE: 파이어볼 시전");
debug_log("R: 더미 HP 리셋");
debug_log("1~9: 레벨 변경");
debug_log("마우스 드래그: 유닛 이동");
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
var unit_size = 40;

// 드래그 처리
if (mouse_check_button_pressed(mb_left)) {
    // 드롭다운이 열려있지 않을 때만 드래그 시작 체크
    if (!dd.race_open && !dd.class_open) {
        // 플레이어 유닛 클릭 체크
        if (point_in_rectangle(mx, my, player.x - unit_size, player.y - unit_size, player.x + unit_size, player.y + unit_size)) {
            drag.active = true;
            drag.target = player;
            drag.offset_x = player.x - mx;
            drag.offset_y = player.y - my;
        }
        // 타겟 더미 클릭 체크
        else if (point_in_rectangle(mx, my, dummy.x - unit_size, dummy.y - unit_size, dummy.x + unit_size, dummy.y + unit_size)) {
            drag.active = true;
            drag.target = dummy;
            drag.offset_x = dummy.x - mx;
            drag.offset_y = dummy.y - my;
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
}

// === 드롭다운 마우스 입력 처리 ===
if (mouse_check_button_pressed(mb_left) && !drag.active) {
    var race_btn_x1 = dd.race_x;
    var race_btn_y1 = dd.race_y;
    var race_btn_x2 = dd.race_x + dd.width;
    var race_btn_y2 = dd.race_y + dd.item_height;

    var class_btn_x1 = dd.class_x;
    var class_btn_y1 = dd.class_y;
    var class_btn_x2 = dd.class_x + dd.width;
    var class_btn_y2 = dd.class_y + dd.item_height;

    // 종족 드롭다운 버튼 클릭
    if (point_in_rectangle(mx, my, race_btn_x1, race_btn_y1, race_btn_x2, race_btn_y2)) {
        dd.race_open = !dd.race_open;
        dd.class_open = false;
    }
    // 직업 드롭다운 버튼 클릭
    else if (point_in_rectangle(mx, my, class_btn_x1, class_btn_y1, class_btn_x2, class_btn_y2)) {
        dd.class_open = !dd.class_open;
        dd.race_open = false;
    }
    // 종족 리스트 아이템 클릭
    else if (dd.race_open) {
        var list_y = dd.race_y + dd.item_height;
        for (var i = 0; i < array_length(global.race_list); i++) {
            var item_y1 = list_y + i * dd.item_height;
            var item_y2 = item_y1 + dd.item_height;
            if (point_in_rectangle(mx, my, dd.race_x, item_y1, dd.race_x + dd.width, item_y2)) {
                global.current_race_idx = i;
                dd.race_open = false;
                debug_recreate_player();
                break;
            }
        }
        dd.race_open = false;
    }
    // 직업 리스트 아이템 클릭
    else if (dd.class_open) {
        var list_y = dd.class_y + dd.item_height;
        for (var i = 0; i < array_length(global.class_list); i++) {
            var item_y1 = list_y + i * dd.item_height;
            var item_y2 = item_y1 + dd.item_height;
            if (point_in_rectangle(mx, my, dd.class_x, item_y1, dd.class_x + dd.width, item_y2)) {
                global.current_class_idx = i;
                dd.class_open = false;
                debug_recreate_player();
                break;
            }
        }
        dd.class_open = false;
    }
    else {
        dd.race_open = false;
        dd.class_open = false;
    }
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

if __name__ == "__main__":
    with open('D:/gml_game/under_dog_lord/objects/obj_debug_controller/Create_0.gml', 'w', encoding='utf-8') as f:
        f.write(create_content)
    print("Updated Create_0.gml")

    with open('D:/gml_game/under_dog_lord/objects/obj_debug_controller/Step_0.gml', 'w', encoding='utf-8') as f:
        f.write(step_content)
    print("Updated Step_0.gml")

    print("Done! Added drag functionality.")
