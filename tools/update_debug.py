#!/usr/bin/env python3
"""Update debug controller with race/class selection"""

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
global.current_race_idx = 0;  // human
global.current_class_idx = 2; // mage

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
global.debug.player_unit.x = 300;
global.debug.player_unit.y = 400;

// 타겟 더미 생성
global.debug.target_dummy = create_unit_from_template("target_dummy", "enemy", 1);
global.debug.target_dummy.x = 700;
global.debug.target_dummy.y = 400;

debug_log("=== 유닛 디버그룸 ===");
debug_log("화염 마법사 (Lv.1) 생성됨");
debug_log("타겟 더미 생성됨");
debug_log("");
debug_log("[조작법]");
debug_log("SPACE: 파이어볼 시전");
debug_log("R: 더미 HP 리셋");
debug_log("1~9: 레벨 변경");
debug_log("Q/W: 종족 변경");
debug_log("A/S: 직업 변경");
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

// === 입력 처리 ===

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

// Q/W: 종족 변경
if (keyboard_check_pressed(ord("Q"))) {
    global.current_race_idx = (global.current_race_idx - 1 + array_length(global.race_list)) % array_length(global.race_list);
    debug_recreate_player();
}
if (keyboard_check_pressed(ord("W"))) {
    global.current_race_idx = (global.current_race_idx + 1) % array_length(global.race_list);
    debug_recreate_player();
}

// A/S: 직업 변경
if (keyboard_check_pressed(ord("A"))) {
    global.current_class_idx = (global.current_class_idx - 1 + array_length(global.class_list)) % array_length(global.class_list);
    debug_recreate_player();
}
if (keyboard_check_pressed(ord("S"))) {
    global.current_class_idx = (global.current_class_idx + 1) % array_length(global.class_list);
    debug_recreate_player();
}
'''

# Update Draw_0.gml
draw_content = '''/// @description 디버그룸 렌더링

if (global.font_korean != -1) {
    draw_set_font(global.font_korean);
}

var player = global.debug.player_unit;
var dummy = global.debug.target_dummy;

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

// === 스탯 패널 (보너스 포함) ===
draw_stat_panel_with_bonus(10, 10, player, "플레이어 유닛");
draw_stat_panel(room_width - 220, 10, dummy, "타겟 더미");

// === 종족/직업 선택 UI ===
draw_race_class_selector(240, 10);

// === 전투 로그 ===
draw_combat_log(10, room_height - 250);

// === 조작법 ===
draw_set_color(c_yellow);
draw_set_halign(fa_center);
draw_text(room_width/2, room_height - 270, "[SPACE] 파이어볼  [R] 더미 리셋  [1-9] 레벨  [Q/W] 종족  [A/S] 직업");
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

# Append to scr_debug.gml
debug_append = '''

/// @func debug_recreate_player()
/// @desc 현재 종족/직업으로 플레이어 재생성
function debug_recreate_player() {
    var race_id = global.race_list[global.current_race_idx];
    var class_id = global.class_list[global.current_class_idx];
    var level = global.debug.player_unit.level;
    var old_x = global.debug.player_unit.x;
    var old_y = global.debug.player_unit.y;

    // 커스텀 유닛 템플릿 생성
    var custom_template = {
        type: "custom_unit",
        name: get_race_bonus(race_id).name + " " + get_class_bonus(class_id).name,
        race: race_id,
        class: class_id,
        base_stats: {
            hp: 300, max_mana: 100,
            physical_attack: 50, magic_attack: 50,
            physical_defense: 30, magic_defense: 30,
            attack_speed: 1.0, movement_speed: 100, attack_range: 1
        },
        secondary_stats: {
            crit_chance: 10, crit_damage: 150,
            dodge_chance: 5, accuracy: 100,
            physical_lifesteal: 0, magic_lifesteal: 0,
            healing_power: 0, physical_penetration: 0,
            magic_penetration: 0, cooldown_reduction: 0,
            mana_regen: 5, hp_regen: 0
        },
        resistance: { cc_resist: 0, debuff_resist: 0 },
        growth_per_level: { hp: 30, mana: 5, physical_attack: 5, magic_attack: 5, physical_defense: 2, magic_defense: 2 },
        skills: ["fireball"]
    };

    // 임시로 템플릿 등록
    global.unit_templates.custom_unit = custom_template;

    // 유닛 재생성
    global.debug.player_unit = create_unit_from_template("custom_unit", "ally", level);
    global.debug.player_unit.x = old_x;
    global.debug.player_unit.y = old_y;

    var race = get_race_bonus(race_id);
    var cls = get_class_bonus(class_id);

    debug_log("");
    debug_log("=== 유닛 변경 ===");
    debug_log("종족: " + race.name + " (HP:" + string(race.hp_bonus) + "%, 공:" + string(race.atk_bonus) + "%, 방:" + string(race.def_bonus) + "%, 속:" + string(race.speed_bonus) + "%)");
    debug_log("직업: " + cls.name + " (HP:" + string(cls.hp_mod) + "%, 물공:" + string(cls.phys_atk_mod) + "%, 마공:" + string(cls.mag_atk_mod) + "%)");
    debug_log("최종 HP: " + string(global.debug.player_unit.max_hp) + ", 마공: " + string(global.debug.player_unit.magic_attack));
}

/// @func draw_stat_panel_with_bonus(x, y, unit, title)
/// @desc 보너스 정보가 포함된 스탯 패널
function draw_stat_panel_with_bonus(xx, yy, unit, title) {
    var w = 220;
    var h = 340;

    draw_set_color(c_black);
    draw_set_alpha(0.8);
    draw_rectangle(xx, yy, xx + w, yy + h, false);
    draw_set_alpha(1);

    draw_set_color(c_gray);
    draw_rectangle(xx, yy, xx + w, yy + h, true);

    draw_set_color(c_yellow);
    draw_text(xx + 10, yy + 5, title);

    var ty = yy + 30;
    var lh = 18;

    // 종족/직업 정보
    var race = get_race_bonus(unit.race);
    var cls = get_class_bonus(unit.class);

    draw_set_color(c_orange);
    draw_text(xx + 10, ty, "종족: " + race.name); ty += lh;
    draw_set_color(c_gray);
    draw_text(xx + 20, ty, "HP:" + string(race.hp_bonus) + "% 공:" + string(race.atk_bonus) + "% 방:" + string(race.def_bonus) + "%"); ty += lh;

    draw_set_color(c_orange);
    draw_text(xx + 10, ty, "직업: " + cls.name); ty += lh;
    draw_set_color(c_gray);
    draw_text(xx + 20, ty, "HP:" + string(cls.hp_mod) + "% 마공:" + string(cls.mag_atk_mod) + "%"); ty += lh;

    draw_set_color(c_white);
    draw_text(xx + 10, ty, "레벨: " + string(unit.level)); ty += lh;
    ty += 5;

    // 1차 스탯
    draw_set_color(c_lime);
    draw_text(xx + 10, ty, "[ 최종 스탯 ]"); ty += lh;
    draw_set_color(c_white);
    draw_text(xx + 10, ty, "HP: " + string(floor(unit.hp)) + "/" + string(unit.max_hp)); ty += lh;
    draw_text(xx + 10, ty, "마나: " + string(floor(unit.mana)) + "/" + string(unit.max_mana)); ty += lh;
    draw_text(xx + 10, ty, "물리 공격력: " + string(unit.physical_attack)); ty += lh;
    draw_text(xx + 10, ty, "마법 공격력: " + string(unit.magic_attack)); ty += lh;
    draw_text(xx + 10, ty, "물리 방어력: " + string(unit.physical_defense)); ty += lh;
    draw_text(xx + 10, ty, "마법 방어력: " + string(unit.magic_defense)); ty += lh;
    draw_text(xx + 10, ty, "이동 속도: " + string(unit.movement_speed)); ty += lh;
    draw_text(xx + 10, ty, "공격 사거리: " + string(unit.attack_range)); ty += lh;
    ty += 5;

    // 2차 스탯
    draw_set_color(c_aqua);
    draw_text(xx + 10, ty, "[ 2차 스탯 ]"); ty += lh;
    draw_set_color(c_white);
    draw_text(xx + 10, ty, "치명타: " + string(unit.crit_chance) + "%"); ty += lh;
    draw_text(xx + 10, ty, "마나 재생: " + string(unit.mana_regen) + "/s"); ty += lh;
}

/// @func draw_race_class_selector(x, y)
/// @desc 종족/직업 선택 UI 그리기
function draw_race_class_selector(xx, yy) {
    var w = 300;
    var h = 80;

    draw_set_color(c_black);
    draw_set_alpha(0.8);
    draw_rectangle(xx, yy, xx + w, yy + h, false);
    draw_set_alpha(1);

    draw_set_color(c_gray);
    draw_rectangle(xx, yy, xx + w, yy + h, true);

    var race_id = global.race_list[global.current_race_idx];
    var class_id = global.class_list[global.current_class_idx];
    var race = get_race_bonus(race_id);
    var cls = get_class_bonus(class_id);

    draw_set_color(c_yellow);
    draw_text(xx + 10, yy + 5, "[Q/W] 종족 선택");
    draw_set_color(c_white);
    draw_text(xx + 10, yy + 25, "< " + race.name + " >");

    draw_set_color(c_yellow);
    draw_text(xx + 150, yy + 5, "[A/S] 직업 선택");
    draw_set_color(c_white);
    draw_text(xx + 150, yy + 25, "< " + cls.name + " >");

    draw_set_color(c_gray);
    draw_text(xx + 10, yy + 50, string(global.current_race_idx + 1) + "/" + string(array_length(global.race_list)));
    draw_text(xx + 150, yy + 50, string(global.current_class_idx + 1) + "/" + string(array_length(global.class_list)));
}
'''

if __name__ == "__main__":
    # Write Create_0.gml
    with open('D:/gml_game/under_dog_lord/objects/obj_debug_controller/Create_0.gml', 'w', encoding='utf-8') as f:
        f.write(create_content)
    print("Updated Create_0.gml")

    # Write Step_0.gml
    with open('D:/gml_game/under_dog_lord/objects/obj_debug_controller/Step_0.gml', 'w', encoding='utf-8') as f:
        f.write(step_content)
    print("Updated Step_0.gml")

    # Write Draw_0.gml
    with open('D:/gml_game/under_dog_lord/objects/obj_debug_controller/Draw_0.gml', 'w', encoding='utf-8') as f:
        f.write(draw_content)
    print("Updated Draw_0.gml")

    # Append to scr_debug.gml
    with open('D:/gml_game/under_dog_lord/scripts/scr_debug/scr_debug.gml', 'a', encoding='utf-8') as f:
        f.write(debug_append)
    print("Updated scr_debug.gml")

    print("\nDone! Debug controller now supports race/class selection.")
