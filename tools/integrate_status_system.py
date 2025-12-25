#!/usr/bin/env python3
"""Integrate status system with debug room"""

# Update scr_data.gml - add init_status_system() call and status_effects array
scr_data_content = '''/// @file scr_data.gml
/// @desc 스킬 및 유닛 데이터

// ============================================
// 종족 데이터 (확장된 보너스 시스템)
// ============================================

function init_race_data() {
    global.races = {};

    // 인간: 균형잡힌 종족, 모든 스탯 평균
    global.races.human = {
        id: "human", name: "인간",
        hp: 0, mana: 0,
        phys_atk: 0, mag_atk: 0,
        phys_def: 0, mag_def: 0,
        atk_speed: 0, move_speed: 0,
        crit_chance: 0, crit_damage: 0,
        dodge: 0, accuracy: 5,
        lifesteal: 0, healing_power: 0,
        hp_regen: 0, mana_regen: 0,
        cc_resist: 0, debuff_resist: 0,
        tags: ["humanoid"]
    };

    // 엘프: 민첩하고 마법에 능함, 체력 약함
    global.races.elf = {
        id: "elf", name: "엘프",
        hp: -15, mana: 20,
        phys_atk: -10, mag_atk: 15,
        phys_def: -10, mag_def: 10,
        atk_speed: 10, move_speed: 15,
        crit_chance: 5, crit_damage: 0,
        dodge: 15, accuracy: 10,
        lifesteal: 0, healing_power: 0,
        hp_regen: 0, mana_regen: 10,
        cc_resist: 0, debuff_resist: 0,
        tags: ["humanoid", "elf"]
    };

    // 드워프: 튼튼하고 물리에 강함, 느림
    global.races.dwarf = {
        id: "dwarf", name: "드워프",
        hp: 20, mana: -10,
        phys_atk: 10, mag_atk: -15,
        phys_def: 20, mag_def: 10,
        atk_speed: -10, move_speed: -15,
        crit_chance: 0, crit_damage: 10,
        dodge: -10, accuracy: 0,
        lifesteal: 0, healing_power: 0,
        hp_regen: 5, mana_regen: 0,
        cc_resist: 15, debuff_resist: 10,
        tags: ["humanoid", "dwarf"]
    };

    // 오크: 강력한 물리 공격, 마법에 약함
    global.races.orc = {
        id: "orc", name: "오크",
        hp: 15, mana: -20,
        phys_atk: 25, mag_atk: -20,
        phys_def: 5, mag_def: -15,
        atk_speed: 5, move_speed: 0,
        crit_chance: 10, crit_damage: 20,
        dodge: -5, accuracy: -5,
        lifesteal: 5, healing_power: -20,
        hp_regen: 10, mana_regen: -10,
        cc_resist: 10, debuff_resist: 0,
        tags: ["humanoid", "orc", "greenskin"]
    };

    // 언데드: 죽지 않는 자, 치유 불가, 디버프 면역
    global.races.undead = {
        id: "undead", name: "언데드",
        hp: 0, mana: 10,
        phys_atk: 5, mag_atk: 10,
        phys_def: 10, mag_def: 5,
        atk_speed: -5, move_speed: -10,
        crit_chance: 0, crit_damage: 0,
        dodge: -10, accuracy: 0,
        lifesteal: 10, healing_power: -50,
        hp_regen: -100, mana_regen: 5,
        cc_resist: 30, debuff_resist: 50,
        tags: ["undead", "dark"]
    };

    // 악마: 마법에 강하고 흡혈, 신성에 약함
    global.races.demon = {
        id: "demon", name: "악마",
        hp: 5, mana: 15,
        phys_atk: 5, mag_atk: 20,
        phys_def: 0, mag_def: 15,
        atk_speed: 5, move_speed: 5,
        crit_chance: 5, crit_damage: 15,
        dodge: 0, accuracy: 5,
        lifesteal: 15, healing_power: -30,
        hp_regen: 0, mana_regen: 10,
        cc_resist: 10, debuff_resist: 20,
        tags: ["demon", "dark", "evil"]
    };

    // 슬라임: 높은 체력, 물리 저항, 매우 느림
    global.races.slime = {
        id: "slime", name: "슬라임",
        hp: 30, mana: 0,
        phys_atk: -30, mag_atk: -20,
        phys_def: 25, mag_def: 15,
        atk_speed: -20, move_speed: -25,
        crit_chance: -10, crit_damage: -20,
        dodge: -20, accuracy: -10,
        lifesteal: 0, healing_power: 0,
        hp_regen: 20, mana_regen: 0,
        cc_resist: 50, debuff_resist: 30,
        tags: ["slime", "amorphous"]
    };

    // 야수: 빠르고 치명타에 강함
    global.races.beast = {
        id: "beast", name: "야수",
        hp: 5, mana: -15,
        phys_atk: 15, mag_atk: -20,
        phys_def: 0, mag_def: -10,
        atk_speed: 15, move_speed: 20,
        crit_chance: 15, crit_damage: 25,
        dodge: 10, accuracy: 5,
        lifesteal: 5, healing_power: 0,
        hp_regen: 5, mana_regen: 0,
        cc_resist: 0, debuff_resist: 0,
        tags: ["beast", "animal"]
    };

    // 용족: 전체적으로 강력, 느린 공속
    global.races.dragon = {
        id: "dragon", name: "용족",
        hp: 25, mana: 20,
        phys_atk: 15, mag_atk: 20,
        phys_def: 15, mag_def: 25,
        atk_speed: -15, move_speed: 0,
        crit_chance: 10, crit_damage: 20,
        dodge: -5, accuracy: 10,
        lifesteal: 0, healing_power: 0,
        hp_regen: 5, mana_regen: 5,
        cc_resist: 25, debuff_resist: 25,
        tags: ["dragon", "flying"]
    };

    // 구조물: 매우 튼튼, 움직이지 않음
    global.races.construct = {
        id: "construct", name: "구조물",
        hp: 50, mana: -50,
        phys_atk: 0, mag_atk: -30,
        phys_def: 40, mag_def: 20,
        atk_speed: -30, move_speed: -50,
        crit_chance: 0, crit_damage: 0,
        dodge: -50, accuracy: 0,
        lifesteal: 0, healing_power: -100,
        hp_regen: 10, mana_regen: 0,
        cc_resist: 100, debuff_resist: 100,
        tags: ["construct", "mechanical"]
    };
}

// ============================================
// 직업 데이터
// ============================================

function init_class_data() {
    global.classes = {};

    global.classes.warrior = { id: "warrior", name: "전사", hp_mod: 10, phys_atk_mod: 15, mag_atk_mod: -20, phys_def_mod: 5, mag_def_mod: 0, speed_mod: 0, atk_range_mod: 0, tags: ["melee", "physical"] };
    global.classes.tank = { id: "tank", name: "탱커", hp_mod: 30, phys_atk_mod: -10, mag_atk_mod: -20, phys_def_mod: 25, mag_def_mod: 15, speed_mod: -15, atk_range_mod: 0, tags: ["melee", "tank", "frontline"] };
    global.classes.mage = { id: "mage", name: "마법사", hp_mod: -15, phys_atk_mod: -20, mag_atk_mod: 25, phys_def_mod: -10, mag_def_mod: 15, speed_mod: 0, atk_range_mod: 2, tags: ["ranged", "magic", "caster"] };
    global.classes.priest = { id: "priest", name: "사제", hp_mod: 0, phys_atk_mod: -20, mag_atk_mod: 10, phys_def_mod: 0, mag_def_mod: 20, speed_mod: 0, atk_range_mod: 2, tags: ["ranged", "magic", "healer", "holy"] };
    global.classes.rogue = { id: "rogue", name: "도적", hp_mod: -10, phys_atk_mod: 20, mag_atk_mod: -20, phys_def_mod: -10, mag_def_mod: -5, speed_mod: 25, atk_range_mod: 0, tags: ["melee", "physical", "stealth", "fast"] };
    global.classes.archer = { id: "archer", name: "궁수", hp_mod: -10, phys_atk_mod: 25, mag_atk_mod: -20, phys_def_mod: -5, mag_def_mod: -5, speed_mod: 10, atk_range_mod: 4, tags: ["ranged", "physical", "archer"] };
    global.classes.support = { id: "support", name: "서포터", hp_mod: 5, phys_atk_mod: -20, mag_atk_mod: 10, phys_def_mod: 5, mag_def_mod: 15, speed_mod: 5, atk_range_mod: 2, tags: ["ranged", "magic", "support", "buff", "debuff"] };
    global.classes.dummy = { id: "dummy", name: "더미", hp_mod: 0, phys_atk_mod: 0, mag_atk_mod: 0, phys_def_mod: 0, mag_def_mod: 0, speed_mod: 0, atk_range_mod: 0, tags: [] };
}

function get_race_bonus(race_id) {
    var race = global.races[$ race_id];
    if (race == undefined) {
        return {
            id: "unknown", name: "알 수 없음",
            hp: 0, mana: 0, phys_atk: 0, mag_atk: 0,
            phys_def: 0, mag_def: 0, atk_speed: 0, move_speed: 0,
            crit_chance: 0, crit_damage: 0, dodge: 0, accuracy: 0,
            lifesteal: 0, healing_power: 0, hp_regen: 0, mana_regen: 0,
            cc_resist: 0, debuff_resist: 0, tags: []
        };
    }
    return race;
}

function get_class_bonus(class_id) {
    var cls = global.classes[$ class_id];
    if (cls == undefined) return { hp_mod: 0, phys_atk_mod: 0, mag_atk_mod: 0, phys_def_mod: 0, mag_def_mod: 0, speed_mod: 0, atk_range_mod: 0 };
    return cls;
}

// ============================================
// 스킬 데이터
// ============================================

function init_skill_data() {
    global.skills = {};

    global.skills.fireball = {
        id: "fireball",
        name: "파이어볼",
        mana_cost: 30,
        cooldown: 3,
        damage_type: "fire",
        effects: [
            { type: "damage", base_amount: 50, scale_stat: "magic_attack", scale_percent: 150 },
            { type: "dot", amount: 10, duration: 3 }
        ]
    };
}

function get_skill(skill_id) {
    return global.skills[$ skill_id];
}

// ============================================
// 유닛 데이터
// ============================================

function init_unit_data() {
    global.unit_templates = {};
    global.next_unit_id = 0;

    global.unit_templates.fire_mage = {
        type: "fire_mage", name: "화염 마법사", race: "human", class: "mage",
        base_stats: { hp: 300, max_mana: 100, physical_attack: 10, magic_attack: 80, physical_defense: 10, magic_defense: 30, attack_speed: 0.8, movement_speed: 80, attack_range: 5 },
        secondary_stats: { crit_chance: 15, crit_damage: 150, dodge_chance: 5, accuracy: 100, physical_lifesteal: 0, magic_lifesteal: 0, healing_power: 0, physical_penetration: 0, magic_penetration: 10, cooldown_reduction: 0, mana_regen: 5, hp_regen: 0 },
        resistance: { cc_resist: 0, debuff_resist: 0 },
        growth_per_level: { hp: 30, mana: 10, magic_attack: 8, magic_defense: 3 },
        skills: ["fireball"]
    };

    global.unit_templates.target_dummy = {
        type: "target_dummy", name: "타겟 더미", race: "construct", class: "dummy",
        base_stats: { hp: 10000, max_mana: 0, physical_attack: 0, magic_attack: 0, physical_defense: 50, magic_defense: 50, attack_speed: 0, movement_speed: 0, attack_range: 0 },
        secondary_stats: { crit_chance: 0, crit_damage: 0, dodge_chance: 0, accuracy: 0, physical_lifesteal: 0, magic_lifesteal: 0, healing_power: 0, physical_penetration: 0, magic_penetration: 0, cooldown_reduction: 0, mana_regen: 0, hp_regen: 100 },
        resistance: { cc_resist: 100, debuff_resist: 100 },
        growth_per_level: {},
        skills: []
    };
}

/// @function create_unit_from_template(template_id, team, level)
/// @desc 템플릿에서 유닛 생성 (종족/직업 보너스 적용)
function create_unit_from_template(template_id, team, level) {
    var t = global.unit_templates[$ template_id];
    if (t == undefined) return undefined;

    var race = get_race_bonus(t.race);
    var cls = get_class_bonus(t.class);

    global.next_unit_id++;

    // 레벨 성장치 계산
    var g = t.growth_per_level;
    var hp_growth = variable_struct_exists(g, "hp") ? g.hp : 0;
    var mana_growth = variable_struct_exists(g, "mana") ? g.mana : 0;
    var patk_growth = variable_struct_exists(g, "physical_attack") ? g.physical_attack : 0;
    var matk_growth = variable_struct_exists(g, "magic_attack") ? g.magic_attack : 0;
    var pdef_growth = variable_struct_exists(g, "physical_defense") ? g.physical_defense : 0;
    var mdef_growth = variable_struct_exists(g, "magic_defense") ? g.magic_defense : 0;

    // 기본 스탯 (레벨 성장 적용)
    var base_hp = t.base_stats.hp + hp_growth * (level - 1);
    var base_mana = t.base_stats.max_mana + mana_growth * (level - 1);
    var base_patk = t.base_stats.physical_attack + patk_growth * (level - 1);
    var base_matk = t.base_stats.magic_attack + matk_growth * (level - 1);
    var base_pdef = t.base_stats.physical_defense + pdef_growth * (level - 1);
    var base_mdef = t.base_stats.magic_defense + mdef_growth * (level - 1);
    var base_atk_speed = t.base_stats.attack_speed;
    var base_move_speed = t.base_stats.movement_speed;
    var base_range = t.base_stats.attack_range;

    // 2차 스탯 기본값
    var base_crit = t.secondary_stats.crit_chance;
    var base_crit_dmg = t.secondary_stats.crit_damage;
    var base_dodge = t.secondary_stats.dodge_chance;
    var base_accuracy = t.secondary_stats.accuracy;
    var base_phys_ls = t.secondary_stats.physical_lifesteal;
    var base_mag_ls = t.secondary_stats.magic_lifesteal;
    var base_heal_power = t.secondary_stats.healing_power;
    var base_hp_regen = t.secondary_stats.hp_regen;
    var base_mana_regen = t.secondary_stats.mana_regen;
    var base_cc_resist = t.resistance.cc_resist;
    var base_debuff_resist = t.resistance.debuff_resist;

    // === 종족 보너스 적용 (퍼센트 증감) ===
    var hp_r = base_hp * (1 + race.hp / 100);
    var mana_r = base_mana * (1 + race.mana / 100);
    var patk_r = base_patk * (1 + race.phys_atk / 100);
    var matk_r = base_matk * (1 + race.mag_atk / 100);
    var pdef_r = base_pdef * (1 + race.phys_def / 100);
    var mdef_r = base_mdef * (1 + race.mag_def / 100);
    var atk_speed_r = base_atk_speed * (1 + race.atk_speed / 100);
    var move_speed_r = base_move_speed * (1 + race.move_speed / 100);

    // 2차 스탯은 가산 (% 포인트 추가)
    var crit_r = base_crit + race.crit_chance;
    var crit_dmg_r = base_crit_dmg + race.crit_damage;
    var dodge_r = base_dodge + race.dodge;
    var accuracy_r = base_accuracy + race.accuracy;
    var lifesteal_r = base_phys_ls + race.lifesteal;
    var mag_lifesteal_r = base_mag_ls + race.lifesteal;
    var heal_power_r = base_heal_power * (1 + race.healing_power / 100);
    var hp_regen_r = base_hp_regen + (base_hp * race.hp_regen / 100);
    var mana_regen_r = base_mana_regen + (base_mana * race.mana_regen / 100);
    var cc_resist_r = min(100, base_cc_resist + race.cc_resist);
    var debuff_resist_r = min(100, base_debuff_resist + race.debuff_resist);

    // === 직업 보너스 적용 ===
    var final_hp = floor(hp_r * (1 + cls.hp_mod / 100));
    var final_mana = floor(mana_r);
    var final_patk = floor(patk_r * (1 + cls.phys_atk_mod / 100));
    var final_matk = floor(matk_r * (1 + cls.mag_atk_mod / 100));
    var final_pdef = floor(pdef_r * (1 + cls.phys_def_mod / 100));
    var final_mdef = floor(mdef_r * (1 + cls.mag_def_mod / 100));
    var final_atk_speed = atk_speed_r;
    var final_move_speed = floor(move_speed_r * (1 + cls.speed_mod / 100));
    var final_range = base_range + cls.atk_range_mod;

    var unit = {
        id: global.next_unit_id,
        type: t.type,
        name: t.name,
        team: team,
        level: level,
        race: t.race,
        class: t.class,

        // 1차 스탯
        hp: final_hp,
        max_hp: final_hp,
        mana: final_mana,
        max_mana: final_mana,
        physical_attack: final_patk,
        magic_attack: final_matk,
        physical_defense: final_pdef,
        magic_defense: final_mdef,
        attack_speed: final_atk_speed,
        movement_speed: final_move_speed,
        attack_range: final_range,

        // 2차 스탯 (종족 보너스 적용됨)
        crit_chance: max(0, crit_r),
        crit_damage: max(100, crit_dmg_r),
        dodge_chance: max(0, dodge_r),
        accuracy: max(0, accuracy_r),
        physical_lifesteal: max(0, lifesteal_r),
        magic_lifesteal: max(0, mag_lifesteal_r),
        healing_power: max(0, heal_power_r),
        physical_penetration: t.secondary_stats.physical_penetration,
        magic_penetration: t.secondary_stats.magic_penetration,
        cooldown_reduction: t.secondary_stats.cooldown_reduction,
        mana_regen: max(0, mana_regen_r),
        hp_regen: max(0, hp_regen_r),

        // 저항
        cc_resist: cc_resist_r,
        debuff_resist: debuff_resist_r,

        // 상태이상 배열
        status_effects: [],

        // 기타
        skills: [],
        skill_cooldowns: {},
        x: 0,
        y: 0,
        is_alive: true
    };

    for (var i = 0; i < array_length(t.skills); i++) {
        array_push(unit.skills, t.skills[i]);
    }

    return unit;
}

/// @function init_all_data()
/// @desc 모든 게임 데이터 초기화
function init_all_data() {
    init_race_data();
    init_class_data();
    init_skill_data();
    init_unit_data();
    init_status_system();  // 상태이상 시스템 초기화
}
'''

# Update Step_0.gml - add status effects update and debug keys
step_content = '''/// @description 디버그룸 업데이트

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
'''

# Update Draw_0.gml - add status effect display
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

// === 상태이상 아이콘 그리기 ===
draw_status_icons(player, player.x, player.y - 70);
draw_status_icons(dummy, dummy.x, dummy.y - 70);

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
    else if (fx.type == "status_text") {
        draw_set_alpha(fx.timer / fx.max_timer);
        draw_set_color(fx.color);
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
draw_text(room_width/2, room_height - 290, "[SPACE] 파이어볼  [R] 더미 리셋  [1-9] 레벨");
draw_text(room_width/2, room_height - 270, "[T] 기절  [Y] 둔화  [U] 속박  [I] 침묵  [C] 정화");
draw_set_halign(fa_left);

// === 쿨다운 표시 ===
var cd = player.skill_cooldowns[$ "fireball"] ?? 0;
draw_set_halign(fa_center);
if (cd > 0) {
    draw_set_color(c_red);
    draw_text(room_width/2, room_height - 310, "쿨다운: " + string_format(cd, 1, 1) + "초");
} else if (!can_use_skill(player)) {
    draw_set_color(c_orange);
    draw_text(room_width/2, room_height - 310, "스킬 사용 불가 (기절/침묵)");
} else {
    draw_set_color(c_lime);
    draw_text(room_width/2, room_height - 310, "스킬 준비됨!");
}
draw_set_halign(fa_left);
'''

# Add status icon functions to scr_debug.gml
scr_debug_addition = '''
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
'''

if __name__ == "__main__":
    with open('D:/gml_game/under_dog_lord/scripts/scr_data/scr_data.gml', 'w', encoding='utf-8') as f:
        f.write(scr_data_content)
    print("Updated scr_data.gml")

    with open('D:/gml_game/under_dog_lord/objects/obj_debug_controller/Step_0.gml', 'w', encoding='utf-8') as f:
        f.write(step_content)
    print("Updated Step_0.gml")

    with open('D:/gml_game/under_dog_lord/objects/obj_debug_controller/Draw_0.gml', 'w', encoding='utf-8') as f:
        f.write(draw_content)
    print("Updated Draw_0.gml")

    with open('D:/gml_game/under_dog_lord/scripts/scr_debug/scr_debug.gml', 'a', encoding='utf-8') as f:
        f.write(scr_debug_addition)
    print("Updated scr_debug.gml")

    print("Done! Status system integrated.")
