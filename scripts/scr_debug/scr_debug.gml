/// @file scr_debug.gml
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

    var bar_w = size * 2;
    var bar_h = 10;
    var bar_y = unit.y + size + 5;

    // HP 바
    var hp_pct = unit.hp / unit.max_hp;
    draw_set_color(c_maroon);
    draw_rectangle(unit.x - size, bar_y, unit.x + size, bar_y + bar_h, false);
    draw_set_color(c_red);
    draw_rectangle(unit.x - size, bar_y, unit.x - size + bar_w * hp_pct, bar_y + bar_h, false);
    draw_set_color(c_white);
    draw_rectangle(unit.x - size, bar_y, unit.x + size, bar_y + bar_h, true);

    // 마나 바
    var mana_y = bar_y + bar_h + 2;
    if (unit.max_mana > 0) {
        var mana_pct = unit.mana / unit.max_mana;
        draw_set_color(c_navy);
        draw_rectangle(unit.x - size, mana_y, unit.x + size, mana_y + bar_h, false);
        draw_set_color(c_aqua);
        draw_rectangle(unit.x - size, mana_y, unit.x - size + bar_w * mana_pct, mana_y + bar_h, false);
        draw_set_color(c_white);
        draw_rectangle(unit.x - size, mana_y, unit.x + size, mana_y + bar_h, true);
    }

    // HP/MP 텍스트
    draw_set_color(c_white);
    draw_text(unit.x, mana_y + bar_h + 5, string(floor(unit.hp)) + "/" + string(unit.max_hp));
    if (unit.max_mana > 0) {
        draw_set_color(c_aqua);
        draw_text(unit.x, mana_y + bar_h + 20, string(floor(unit.mana)) + "/" + string(unit.max_mana));
    }
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
            dodge_chance: 10, accuracy: 100,
            physical_lifesteal: 0, magic_lifesteal: 0,
            healing_power: 100, physical_penetration: 0,
            magic_penetration: 0, cooldown_reduction: 0,
            mana_regen: 5, hp_regen: 2
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

/// @func format_bonus(val)
/// @desc 보너스 값을 문자열로 포맷 (+/-% 형태)
function format_bonus(val) {
    if (val > 0) return "+" + string(val) + "%";
    else if (val < 0) return string(val) + "%";
    else return "0%";
}

/// @func draw_stat_panel_with_bonus(x, y, unit, title)
/// @desc 보너스 정보가 포함된 스탯 패널
function draw_stat_panel_with_bonus(xx, yy, unit, title) {
    var w = 220;
    var h = 520;

    draw_set_color(c_black);
    draw_set_alpha(0.8);
    draw_rectangle(xx, yy, xx + w, yy + h, false);
    draw_set_alpha(1);

    draw_set_color(c_gray);
    draw_rectangle(xx, yy, xx + w, yy + h, true);

    draw_set_color(c_yellow);
    draw_text(xx + 10, yy + 5, title);

    var ty = yy + 28;
    var lh = 16;

    var race = get_race_bonus(unit.race);
    var cls = get_class_bonus(unit.class);

    // 종족/직업 정보
    draw_set_color(c_orange);
    draw_text(xx + 10, ty, "종족: " + race.name); ty += lh;
    draw_set_color(c_white);
    draw_text(xx + 10, ty, "직업: " + cls.name + " (Lv." + string(unit.level) + ")"); ty += lh;
    ty += 5;

    // 1차 스탯
    draw_set_color(c_lime);
    draw_text(xx + 10, ty, "[ 1차 스탯 ]"); ty += lh;
    draw_set_color(c_white);
    draw_text(xx + 10, ty, "HP: " + string(floor(unit.hp)) + "/" + string(unit.max_hp)); ty += lh;
    draw_text(xx + 10, ty, "마나: " + string(floor(unit.mana)) + "/" + string(unit.max_mana)); ty += lh;
    draw_text(xx + 10, ty, "물리 공격력: " + string(unit.physical_attack)); ty += lh;
    draw_text(xx + 10, ty, "마법 공격력: " + string(unit.magic_attack)); ty += lh;
    draw_text(xx + 10, ty, "물리 방어력: " + string(unit.physical_defense)); ty += lh;
    draw_text(xx + 10, ty, "마법 방어력: " + string(unit.magic_defense)); ty += lh;
    draw_text(xx + 10, ty, "공격 속도: " + string_format(unit.attack_speed, 1, 2)); ty += lh;
    draw_text(xx + 10, ty, "이동 속도: " + string(unit.movement_speed)); ty += lh;
    ty += 5;

    // 2차 스탯
    draw_set_color(c_aqua);
    draw_text(xx + 10, ty, "[ 2차 스탯 ]"); ty += lh;
    draw_set_color(c_white);
    draw_text(xx + 10, ty, "치명타 확률: " + string(unit.crit_chance) + "%"); ty += lh;
    draw_text(xx + 10, ty, "치명타 피해: " + string(unit.crit_damage) + "%"); ty += lh;
    draw_text(xx + 10, ty, "회피율: " + string(unit.dodge_chance) + "%"); ty += lh;
    draw_text(xx + 10, ty, "명중률: " + string(unit.accuracy) + "%"); ty += lh;
    draw_text(xx + 10, ty, "물리 흡혈: " + string(unit.physical_lifesteal) + "%"); ty += lh;
    draw_text(xx + 10, ty, "마법 흡혈: " + string(unit.magic_lifesteal) + "%"); ty += lh;
    draw_text(xx + 10, ty, "치유력: " + string(unit.healing_power)); ty += lh;
    draw_text(xx + 10, ty, "물리 관통: " + string(unit.physical_penetration)); ty += lh;
    draw_text(xx + 10, ty, "마법 관통: " + string(unit.magic_penetration)); ty += lh;
    draw_text(xx + 10, ty, "쿨다운 감소: " + string(unit.cooldown_reduction) + "%"); ty += lh;
    draw_text(xx + 10, ty, "HP 재생: " + string_format(unit.hp_regen, 1, 1) + "/s"); ty += lh;
    draw_text(xx + 10, ty, "마나 재생: " + string_format(unit.mana_regen, 1, 1) + "/s"); ty += lh;
    ty += 5;

    // 저항
    draw_set_color(c_fuchsia);
    draw_text(xx + 10, ty, "[ 저항 ]"); ty += lh;
    draw_set_color(c_white);
    draw_text(xx + 10, ty, "CC 저항: " + string(unit.cc_resist) + "%"); ty += lh;
    draw_text(xx + 10, ty, "디버프 저항: " + string(unit.debuff_resist) + "%"); ty += lh;
}

/// @func draw_race_bonus_panel(x, y)
/// @desc 종족 보너스 상세 패널
function draw_race_bonus_panel(xx, yy) {
    var race_id = global.race_list[global.current_race_idx];
    var race = get_race_bonus(race_id);

    var w = 200;
    var h = 280;

    draw_set_color(c_black);
    draw_set_alpha(0.85);
    draw_rectangle(xx, yy, xx + w, yy + h, false);
    draw_set_alpha(1);

    draw_set_color(c_gray);
    draw_rectangle(xx, yy, xx + w, yy + h, true);

    draw_set_color(c_orange);
    draw_text(xx + 10, yy + 5, "[ " + race.name + " 종족 보너스 ]");

    var ty = yy + 28;
    var lh = 15;

    draw_set_color(c_white);
    draw_text(xx + 10, ty, "HP: " + format_bonus(race.hp)); ty += lh;
    draw_text(xx + 10, ty, "마나: " + format_bonus(race.mana)); ty += lh;
    draw_text(xx + 10, ty, "물리공격: " + format_bonus(race.phys_atk)); ty += lh;
    draw_text(xx + 10, ty, "마법공격: " + format_bonus(race.mag_atk)); ty += lh;
    draw_text(xx + 10, ty, "물리방어: " + format_bonus(race.phys_def)); ty += lh;
    draw_text(xx + 10, ty, "마법방어: " + format_bonus(race.mag_def)); ty += lh;
    draw_text(xx + 10, ty, "공격속도: " + format_bonus(race.atk_speed)); ty += lh;
    draw_text(xx + 10, ty, "이동속도: " + format_bonus(race.move_speed)); ty += lh;
    ty += 3;
    draw_text(xx + 10, ty, "치명타: " + format_bonus(race.crit_chance)); ty += lh;
    draw_text(xx + 10, ty, "치명타피해: " + format_bonus(race.crit_damage)); ty += lh;
    draw_text(xx + 10, ty, "회피: " + format_bonus(race.dodge)); ty += lh;
    draw_text(xx + 10, ty, "명중: " + format_bonus(race.accuracy)); ty += lh;
    draw_text(xx + 10, ty, "흡혈: " + format_bonus(race.lifesteal)); ty += lh;
    draw_text(xx + 10, ty, "치유력: " + format_bonus(race.healing_power)); ty += lh;
    draw_text(xx + 10, ty, "HP재생: " + format_bonus(race.hp_regen)); ty += lh;
    draw_text(xx + 10, ty, "CC저항: " + format_bonus(race.cc_resist)); ty += lh;
    draw_text(xx + 10, ty, "디버프저항: " + format_bonus(race.debuff_resist)); ty += lh;
}

/// @func draw_dropdown_ui()
function draw_dropdown_ui() {
    var dd = global.dropdown;

    draw_dropdown("종족", dd.race_x, dd.race_y, dd.width, dd.item_height,
                  global.race_list, global.current_race_idx, dd.race_open, true);

    draw_dropdown("직업", dd.class_x, dd.class_y, dd.width, dd.item_height,
                  global.class_list, global.current_class_idx, dd.class_open, false);
}

/// @func draw_dropdown_only()
/// @desc 드롭다운만 그리기 (패널 분리용)
function draw_dropdown_only() {
    var dd = global.dropdown;

    draw_dropdown("종족", dd.race_x, dd.race_y, dd.width, dd.item_height,
                  global.race_list, global.current_race_idx, dd.race_open, true);

    draw_dropdown("직업", dd.class_x, dd.class_y, dd.width, dd.item_height,
                  global.class_list, global.current_class_idx, dd.class_open, false);
}

/// @func draw_panel_header(x, y, w, title, collapsed)
/// @desc 패널 헤더 (드래그/접기 버튼 포함)
function draw_panel_header(xx, yy, w, title, collapsed) {
    var h = 24;

    // 헤더 배경
    draw_set_color(c_navy);
    draw_rectangle(xx, yy, xx + w, yy + h, false);
    draw_set_color(c_white);
    draw_rectangle(xx, yy, xx + w, yy + h, true);

    // 제목
    draw_set_color(c_yellow);
    draw_text(xx + 8, yy + 5, title);

    // 접기/펴기 버튼
    draw_set_color(c_white);
    var btn_x = xx + w - 20;
    draw_text(btn_x, yy + 5, collapsed ? "+" : "-");

    return h;
}

/// @func draw_panel_stat_with_bonus(x, y, w, collapsed, unit, title)
/// @desc 보너스 포함 스탯 패널 (접기 가능)
function draw_panel_stat_with_bonus(xx, yy, w, collapsed, unit, title) {
    var header_h = draw_panel_header(xx, yy, w, title, collapsed);

    if (collapsed) return;

    var h = 500;
    var content_y = yy + header_h;

    draw_set_color(c_black);
    draw_set_alpha(0.8);
    draw_rectangle(xx, content_y, xx + w, content_y + h, false);
    draw_set_alpha(1);
    draw_set_color(c_gray);
    draw_rectangle(xx, content_y, xx + w, content_y + h, true);

    var ty = content_y + 8;
    var lh = 16;

    var race = get_race_bonus(unit.race);
    var cls = get_class_bonus(unit.class);

    // 종족/직업 정보
    draw_set_color(c_orange);
    draw_text(xx + 10, ty, "종족: " + race.name); ty += lh;
    draw_set_color(c_white);
    draw_text(xx + 10, ty, "직업: " + cls.name + " (Lv." + string(unit.level) + ")"); ty += lh;
    ty += 5;

    // 1차 스탯
    draw_set_color(c_lime);
    draw_text(xx + 10, ty, "[ 1차 스탯 ]"); ty += lh;
    draw_set_color(c_white);
    draw_text(xx + 10, ty, "HP: " + string(floor(unit.hp)) + "/" + string(unit.max_hp)); ty += lh;
    draw_text(xx + 10, ty, "마나: " + string(floor(unit.mana)) + "/" + string(unit.max_mana)); ty += lh;
    draw_text(xx + 10, ty, "물리 공격력: " + string(unit.physical_attack)); ty += lh;
    draw_text(xx + 10, ty, "마법 공격력: " + string(unit.magic_attack)); ty += lh;
    draw_text(xx + 10, ty, "물리 방어력: " + string(unit.physical_defense)); ty += lh;
    draw_text(xx + 10, ty, "마법 방어력: " + string(unit.magic_defense)); ty += lh;
    draw_text(xx + 10, ty, "공격 속도: " + string_format(unit.attack_speed, 1, 2)); ty += lh;
    draw_text(xx + 10, ty, "이동 속도: " + string(unit.movement_speed)); ty += lh;
    ty += 5;

    // 2차 스탯
    draw_set_color(c_aqua);
    draw_text(xx + 10, ty, "[ 2차 스탯 ]"); ty += lh;
    draw_set_color(c_white);
    draw_text(xx + 10, ty, "치명타 확률: " + string(unit.crit_chance) + "%"); ty += lh;
    draw_text(xx + 10, ty, "치명타 피해: " + string(unit.crit_damage) + "%"); ty += lh;
    draw_text(xx + 10, ty, "회피율: " + string(unit.dodge_chance) + "%"); ty += lh;
    draw_text(xx + 10, ty, "명중률: " + string(unit.accuracy) + "%"); ty += lh;
    draw_text(xx + 10, ty, "물리 흡혈: " + string(unit.physical_lifesteal) + "%"); ty += lh;
    draw_text(xx + 10, ty, "마법 흡혈: " + string(unit.magic_lifesteal) + "%"); ty += lh;
    draw_text(xx + 10, ty, "치유력: " + string(unit.healing_power)); ty += lh;
    draw_text(xx + 10, ty, "물리 관통: " + string(unit.physical_penetration)); ty += lh;
    draw_text(xx + 10, ty, "마법 관통: " + string(unit.magic_penetration)); ty += lh;
    draw_text(xx + 10, ty, "쿨다운 감소: " + string(unit.cooldown_reduction) + "%"); ty += lh;
    draw_text(xx + 10, ty, "HP 재생: " + string_format(unit.hp_regen, 1, 1) + "/s"); ty += lh;
    draw_text(xx + 10, ty, "마나 재생: " + string_format(unit.mana_regen, 1, 1) + "/s"); ty += lh;
    ty += 5;

    // 저항
    draw_set_color(c_fuchsia);
    draw_text(xx + 10, ty, "[ 저항 ]"); ty += lh;
    draw_set_color(c_white);
    draw_text(xx + 10, ty, "CC 저항: " + string(unit.cc_resist) + "%"); ty += lh;
    draw_text(xx + 10, ty, "디버프 저항: " + string(unit.debuff_resist) + "%"); ty += lh;
}

/// @func draw_panel_race_bonus(x, y, w, collapsed, title)
/// @desc 종족 보너스 패널 (접기 가능)
function draw_panel_race_bonus(xx, yy, w, collapsed, title) {
    var race_id = global.race_list[global.current_race_idx];
    var race = get_race_bonus(race_id);

    var full_title = title + " [" + race.name + "]";
    var header_h = draw_panel_header(xx, yy, w, full_title, collapsed);

    if (collapsed) return;

    var h = 280;
    var content_y = yy + header_h;

    draw_set_color(c_black);
    draw_set_alpha(0.85);
    draw_rectangle(xx, content_y, xx + w, content_y + h, false);
    draw_set_alpha(1);
    draw_set_color(c_gray);
    draw_rectangle(xx, content_y, xx + w, content_y + h, true);

    var ty = content_y + 8;
    var lh = 15;

    draw_set_color(c_white);
    draw_text(xx + 10, ty, "HP: " + format_bonus(race.hp)); ty += lh;
    draw_text(xx + 10, ty, "마나: " + format_bonus(race.mana)); ty += lh;
    draw_text(xx + 10, ty, "물리공격: " + format_bonus(race.phys_atk)); ty += lh;
    draw_text(xx + 10, ty, "마법공격: " + format_bonus(race.mag_atk)); ty += lh;
    draw_text(xx + 10, ty, "물리방어: " + format_bonus(race.phys_def)); ty += lh;
    draw_text(xx + 10, ty, "마법방어: " + format_bonus(race.mag_def)); ty += lh;
    draw_text(xx + 10, ty, "공격속도: " + format_bonus(race.atk_speed)); ty += lh;
    draw_text(xx + 10, ty, "이동속도: " + format_bonus(race.move_speed)); ty += lh;
    ty += 3;
    draw_text(xx + 10, ty, "치명타: " + format_bonus(race.crit_chance)); ty += lh;
    draw_text(xx + 10, ty, "치명타피해: " + format_bonus(race.crit_damage)); ty += lh;
    draw_text(xx + 10, ty, "회피: " + format_bonus(race.dodge)); ty += lh;
    draw_text(xx + 10, ty, "명중: " + format_bonus(race.accuracy)); ty += lh;
    draw_text(xx + 10, ty, "흡혈: " + format_bonus(race.lifesteal)); ty += lh;
    draw_text(xx + 10, ty, "치유력: " + format_bonus(race.healing_power)); ty += lh;
    draw_text(xx + 10, ty, "HP재생: " + format_bonus(race.hp_regen)); ty += lh;
    draw_text(xx + 10, ty, "CC저항: " + format_bonus(race.cc_resist)); ty += lh;
    draw_text(xx + 10, ty, "디버프저항: " + format_bonus(race.debuff_resist)); ty += lh;
}

/// @func draw_panel_class_bonus(x, y, w, collapsed, title)
/// @desc 직업 보너스 패널 (접기 가능)
function draw_panel_class_bonus(xx, yy, w, collapsed, title) {
    var class_id = global.class_list[global.current_class_idx];
    var cls = get_class_bonus(class_id);

    var full_title = title + " [" + cls.name + "]";
    var header_h = draw_panel_header(xx, yy, w, full_title, collapsed);

    if (collapsed) return;

    var h = 140;
    var content_y = yy + header_h;

    draw_set_color(c_black);
    draw_set_alpha(0.85);
    draw_rectangle(xx, content_y, xx + w, content_y + h, false);
    draw_set_alpha(1);
    draw_set_color(c_gray);
    draw_rectangle(xx, content_y, xx + w, content_y + h, true);

    var ty = content_y + 8;
    var lh = 15;

    draw_set_color(c_white);
    draw_text(xx + 10, ty, "HP: " + format_bonus(cls.hp_mod)); ty += lh;
    draw_text(xx + 10, ty, "물리공격: " + format_bonus(cls.phys_atk_mod)); ty += lh;
    draw_text(xx + 10, ty, "마법공격: " + format_bonus(cls.mag_atk_mod)); ty += lh;
    draw_text(xx + 10, ty, "물리방어: " + format_bonus(cls.phys_def_mod)); ty += lh;
    draw_text(xx + 10, ty, "마법방어: " + format_bonus(cls.mag_def_mod)); ty += lh;
    draw_text(xx + 10, ty, "이동속도: " + format_bonus(cls.speed_mod)); ty += lh;
    draw_text(xx + 10, ty, "공격 사거리: " + format_bonus(cls.atk_range_mod)); ty += lh;
}

/// @func draw_panel_stat(x, y, w, collapsed, unit, title)
/// @desc 기본 스탯 패널 (접기 가능)
function draw_panel_stat(xx, yy, w, collapsed, unit, title) {
    var header_h = draw_panel_header(xx, yy, w, title, collapsed);

    if (collapsed) return;

    var h = 180;
    var content_y = yy + header_h;

    draw_set_color(c_black);
    draw_set_alpha(0.8);
    draw_rectangle(xx, content_y, xx + w, content_y + h, false);
    draw_set_alpha(1);
    draw_set_color(c_gray);
    draw_rectangle(xx, content_y, xx + w, content_y + h, true);

    var ty = content_y + 8;
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

/// @func draw_status_icons(unit, x, y)
/// @desc 유닛의 상태이상 아이콘 표시
function draw_status_icons(unit, xx, yy) {
    var effects = get_status_effect_list(unit);
    if (array_length(effects) == 0) return;

    var icon_size = 18;
    var spacing = 4;
    var total_width = array_length(effects) * (icon_size + spacing) - spacing;
    var start_x = xx - total_width / 2;

    for (var i = 0; i < array_length(effects); i++) {
        var eff = effects[i];
        var icon_x = start_x + i * (icon_size + spacing);
        var icon_color = get_status_icon_color(eff.type);
        var icon_char = "?";

        switch (eff.type) {
            case "stun": icon_char = "S"; break;
            case "root": icon_char = "R"; break;
            case "silence": icon_char = "X"; break;
            case "slow": icon_char = "~"; break;
            case "dot": icon_char = "!"; break;
            case "hot": icon_char = "+"; break;
            case "weaken": icon_char = "W"; break;
            case "vulnerable": icon_char = "V"; break;
            case "haste": icon_char = "H"; break;
            case "might": icon_char = "M"; break;
            case "shield": icon_char = "O"; break;
        }

        draw_set_color(c_black);
        draw_set_alpha(0.7);
        draw_rectangle(icon_x, yy, icon_x + icon_size, yy + icon_size, false);
        draw_set_alpha(1);

        draw_set_color(icon_color);
        draw_rectangle(icon_x, yy, icon_x + icon_size, yy + icon_size, true);

        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text(icon_x + icon_size/2, yy + icon_size/2, icon_char);

        if (eff.max_duration > 0) {
            var pct = eff.duration / eff.max_duration;
            draw_set_color(icon_color);
            draw_rectangle(icon_x, yy + icon_size + 1, icon_x + icon_size * pct, yy + icon_size + 3, false);
        }
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

/// @func debug_show_status_text(unit, text, color)
function debug_show_status_text(unit, text, color) {
    array_push(global.debug.effects, {
        type: "status_text",
        x: unit.x,
        y: unit.y - 80,
        text: text,
        color: color,
        timer: 45,
        max_timer: 45
    });
}
