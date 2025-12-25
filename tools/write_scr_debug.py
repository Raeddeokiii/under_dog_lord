#!/usr/bin/env python3
"""Write scr_debug.gml with dropdown functions"""

debug_content = '''/// @file scr_debug.gml
/// @desc 디버그 유틸리티 함수들

/// @func debug_log(message)
function debug_log(message) {
    array_push(global.debug.combat_log, message);
    while (array_length(global.debug.combat_log) > global.debug.max_log_lines) {
        array_delete(global.debug.combat_log, 0, 1);
    }
}

/// @func debug_use_skill(caster, skill_id, target)
function debug_use_skill(caster, skill_id, target) {
    var skill = get_skill(skill_id);
    if (skill == undefined) {
        debug_log("스킬을 찾을 수 없음: " + skill_id);
        return;
    }

    var cd = caster.skill_cooldowns[$ skill_id] ?? 0;
    if (cd > 0) {
        debug_log(skill.name + " 쿨다운 중: " + string_format(cd, 1, 1) + "초");
        return;
    }

    if (caster.mana < skill.mana_cost) {
        debug_log("마나 부족! (" + string(floor(caster.mana)) + "/" + string(skill.mana_cost) + ")");
        return;
    }

    caster.mana -= skill.mana_cost;
    caster.skill_cooldowns[$ skill_id] = skill.cooldown * (1 - caster.cooldown_reduction / 100);

    debug_log("");
    debug_log("=== " + skill.name + " 시전! ===");
    debug_log("마나 소모: " + string(skill.mana_cost) + " (남은 마나: " + string(floor(caster.mana)) + ")");

    array_push(global.debug.effects, {
        type: "fireball",
        x: caster.x,
        y: caster.y,
        target_x: target.x,
        target_y: target.y,
        speed: 12,
        trail_timer: 0
    });

    for (var i = 0; i < array_length(skill.effects); i++) {
        var eff = skill.effects[i];

        if (eff.type == "damage") {
            var stat_val = 0;
            if (eff.scale_stat == "magic_attack") stat_val = caster.magic_attack;
            else if (eff.scale_stat == "physical_attack") stat_val = caster.physical_attack;

            var raw_damage = eff.base_amount + stat_val * (eff.scale_percent / 100);
            var is_crit = random(100) < caster.crit_chance;

            if (is_crit) {
                raw_damage *= (caster.crit_damage / 100);
            }

            var defense = target.magic_defense;
            var pen = caster.magic_penetration;
            var effective_def = max(0, defense - pen);
            var reduction = effective_def / (effective_def + 100);
            var final_damage = floor(raw_damage * (1 - reduction));

            target.hp = max(0, target.hp - final_damage);

            var crit_text = is_crit ? " [치명타!]" : "";
            debug_log("피해량: " + string(final_damage) + crit_text);
            debug_log("  (기본: " + string(eff.base_amount) + " + 마공 " + string(stat_val) + " x " + string(eff.scale_percent) + "%)");
            debug_log("  (방어: " + string(defense) + " - 관통 " + string(pen) + " = " + string_format(reduction * 100, 1, 1) + "% 감소)");
            debug_log("타겟 HP: " + string(floor(target.hp)) + "/" + string(target.max_hp));
        }
        else if (eff.type == "dot") {
            debug_log("지속 피해: " + string(eff.amount) + " x " + string(eff.duration) + "초");
        }
    }
}

/// @func debug_set_level(unit, level)
function debug_set_level(unit, level) {
    debug_recreate_player_with_level(level);
    debug_log("레벨 " + string(level) + "로 변경됨");
}

/// @func draw_unit_box(unit, color, label)
function draw_unit_box(unit, color, label) {
    var size = 40;
    draw_set_color(color);
    draw_rectangle(unit.x - size, unit.y - size, unit.x + size, unit.y + size, false);
    draw_set_color(c_white);
    draw_rectangle(unit.x - size, unit.y - size, unit.x + size, unit.y + size, true);

    draw_set_halign(fa_center);
    draw_text(unit.x, unit.y - size - 25, label);

    var hp_pct = unit.hp / unit.max_hp;
    var bar_w = size * 2;
    draw_set_color(c_maroon);
    draw_rectangle(unit.x - size, unit.y + size + 5, unit.x + size, unit.y + size + 15, false);
    draw_set_color(c_red);
    draw_rectangle(unit.x - size, unit.y + size + 5, unit.x - size + bar_w * hp_pct, unit.y + size + 15, false);
    draw_set_color(c_white);
    draw_text(unit.x, unit.y + size + 20, string(floor(unit.hp)) + "/" + string(unit.max_hp));
    draw_set_halign(fa_left);
}

/// @func draw_stat_panel(x, y, unit, title)
function draw_stat_panel(xx, yy, unit, title) {
    var w = 210;
    var h = 200;

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

    draw_set_color(c_white);
    draw_text(xx + 10, ty, "레벨: " + string(unit.level)); ty += lh;
    draw_text(xx + 10, ty, "HP: " + string(floor(unit.hp)) + "/" + string(unit.max_hp)); ty += lh;
    draw_text(xx + 10, ty, "마나: " + string(floor(unit.mana)) + "/" + string(unit.max_mana)); ty += lh;
    draw_text(xx + 10, ty, "물리 공격력: " + string(unit.physical_attack)); ty += lh;
    draw_text(xx + 10, ty, "마법 공격력: " + string(unit.magic_attack)); ty += lh;
    draw_text(xx + 10, ty, "물리 방어력: " + string(unit.physical_defense)); ty += lh;
    draw_text(xx + 10, ty, "마법 방어력: " + string(unit.magic_defense)); ty += lh;
    draw_text(xx + 10, ty, "HP 재생: " + string(unit.hp_regen) + "/s"); ty += lh;
}

/// @func draw_combat_log(x, y)
function draw_combat_log(xx, yy) {
    var w = room_width - 20;
    var h = 220;

    draw_set_color(c_black);
    draw_set_alpha(0.7);
    draw_rectangle(xx, yy, xx + w, yy + h, false);
    draw_set_alpha(1);

    draw_set_color(c_gray);
    draw_rectangle(xx, yy, xx + w, yy + h, true);

    draw_set_color(c_yellow);
    draw_text(xx + 10, yy + 5, "=== 전투 로그 ===");

    draw_set_color(c_white);
    for (var i = 0; i < array_length(global.debug.combat_log); i++) {
        draw_text(xx + 10, yy + 25 + i * 13, global.debug.combat_log[i]);
    }
}

/// @func debug_recreate_player()
function debug_recreate_player() {
    debug_recreate_player_with_level(global.debug.player_unit.level);
}

/// @func debug_recreate_player_with_level(level)
function debug_recreate_player_with_level(level) {
    var race_id = global.race_list[global.current_race_idx];
    var class_id = global.class_list[global.current_class_idx];
    var old_x = global.debug.player_unit.x;
    var old_y = global.debug.player_unit.y;

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

    global.unit_templates.custom_unit = custom_template;

    global.debug.player_unit = create_unit_from_template("custom_unit", "ally", level);
    global.debug.player_unit.x = old_x;
    global.debug.player_unit.y = old_y;

    var race = get_race_bonus(race_id);
    var cls = get_class_bonus(class_id);

    debug_log("");
    debug_log("=== 유닛 변경 ===");
    debug_log("종족: " + race.name + " | 직업: " + cls.name + " | 레벨: " + string(level));
    debug_log("HP: " + string(global.debug.player_unit.max_hp) + " | 마공: " + string(global.debug.player_unit.magic_attack));
}

/// @func draw_stat_panel_with_bonus(x, y, unit, title)
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

    draw_set_color(c_aqua);
    draw_text(xx + 10, ty, "[ 2차 스탯 ]"); ty += lh;
    draw_set_color(c_white);
    draw_text(xx + 10, ty, "치명타: " + string(unit.crit_chance) + "%"); ty += lh;
    draw_text(xx + 10, ty, "마나 재생: " + string(unit.mana_regen) + "/s"); ty += lh;
}

/// @func draw_dropdown_ui()
function draw_dropdown_ui() {
    var dd = global.dropdown;

    draw_dropdown("종족", dd.race_x, dd.race_y, dd.width, dd.item_height,
                  global.race_list, global.current_race_idx, dd.race_open, true);

    draw_dropdown("직업", dd.class_x, dd.class_y, dd.width, dd.item_height,
                  global.class_list, global.current_class_idx, dd.class_open, false);
}

/// @func draw_dropdown(label, x, y, w, h, items, selected_idx, is_open, is_race)
function draw_dropdown(label, xx, yy, w, h, items, selected_idx, is_open, is_race) {
    var mx = mouse_x;
    var my = mouse_y;

    draw_set_color(c_yellow);
    draw_text(xx, yy - 18, label);

    var selected_id = items[selected_idx];
    var selected_name = "";
    if (is_race) {
        selected_name = get_race_bonus(selected_id).name;
    } else {
        selected_name = get_class_bonus(selected_id).name;
    }

    var hover_btn = point_in_rectangle(mx, my, xx, yy, xx + w, yy + h);
    draw_set_color(hover_btn ? c_gray : c_dkgray);
    draw_rectangle(xx, yy, xx + w, yy + h, false);
    draw_set_color(c_white);
    draw_rectangle(xx, yy, xx + w, yy + h, true);

    draw_set_color(c_white);
    draw_text(xx + 8, yy + 4, selected_name);

    draw_set_color(c_yellow);
    var arrow = is_open ? "^" : "v";
    draw_text(xx + w - 16, yy + 4, arrow);

    if (is_open) {
        var list_y = yy + h;
        var list_h = array_length(items) * h;

        draw_set_color(c_black);
        draw_set_alpha(0.95);
        draw_rectangle(xx, list_y, xx + w, list_y + list_h, false);
        draw_set_alpha(1);
        draw_set_color(c_white);
        draw_rectangle(xx, list_y, xx + w, list_y + list_h, true);

        for (var i = 0; i < array_length(items); i++) {
            var item_y = list_y + i * h;
            var item_id = items[i];
            var item_name = "";
            if (is_race) {
                item_name = get_race_bonus(item_id).name;
            } else {
                item_name = get_class_bonus(item_id).name;
            }

            var hover = point_in_rectangle(mx, my, xx, item_y, xx + w, item_y + h);
            var selected = (i == selected_idx);

            if (hover || selected) {
                draw_set_color(selected ? c_navy : c_gray);
                draw_set_alpha(0.8);
                draw_rectangle(xx + 1, item_y + 1, xx + w - 1, item_y + h - 1, false);
                draw_set_alpha(1);
            }

            draw_set_color(hover ? c_yellow : c_white);
            draw_text(xx + 8, item_y + 4, item_name);
        }
    }
}
'''

if __name__ == "__main__":
    with open('D:/gml_game/under_dog_lord/scripts/scr_debug/scr_debug.gml', 'w', encoding='utf-8') as f:
        f.write(debug_content)
    print("Updated scr_debug.gml")
