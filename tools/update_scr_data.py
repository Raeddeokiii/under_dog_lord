#!/usr/bin/env python3
"""Update scr_data.gml with race/class bonus system"""

content = '''/// @file scr_data.gml
/// @desc 스킬 및 유닛 데이터

// ============================================
// 종족 데이터
// ============================================

function init_race_data() {
    global.races = {};

    global.races.human = { id: "human", name: "인간", hp_bonus: 0, atk_bonus: 0, def_bonus: 0, speed_bonus: 0, tags: [] };
    global.races.elf = { id: "elf", name: "엘프", hp_bonus: -10, atk_bonus: 0, def_bonus: -5, speed_bonus: 15, tags: ["elf"] };
    global.races.dwarf = { id: "dwarf", name: "드워프", hp_bonus: 15, atk_bonus: 5, def_bonus: 10, speed_bonus: -10, tags: ["dwarf"] };
    global.races.orc = { id: "orc", name: "오크", hp_bonus: 10, atk_bonus: 15, def_bonus: 0, speed_bonus: -5, tags: ["orc", "greenskin"] };
    global.races.undead = { id: "undead", name: "언데드", hp_bonus: 0, atk_bonus: 0, def_bonus: 5, speed_bonus: -5, tags: ["undead", "dark"] };
    global.races.demon = { id: "demon", name: "악마", hp_bonus: 5, atk_bonus: 10, def_bonus: 0, speed_bonus: 5, tags: ["demon", "dark", "evil"] };
    global.races.slime = { id: "slime", name: "슬라임", hp_bonus: 20, atk_bonus: -20, def_bonus: 15, speed_bonus: -15, tags: ["slime", "amorphous"] };
    global.races.beast = { id: "beast", name: "야수", hp_bonus: 5, atk_bonus: 10, def_bonus: 0, speed_bonus: 10, tags: ["beast", "animal"] };
    global.races.dragon = { id: "dragon", name: "용족", hp_bonus: 20, atk_bonus: 15, def_bonus: 10, speed_bonus: 0, tags: ["dragon", "flying"] };
    global.races.construct = { id: "construct", name: "구조물", hp_bonus: 30, atk_bonus: 0, def_bonus: 20, speed_bonus: -20, tags: ["construct", "mechanical"] };
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
    if (race == undefined) return { hp_bonus: 0, atk_bonus: 0, def_bonus: 0, speed_bonus: 0 };
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

    var g = t.growth_per_level;
    var hp_growth = variable_struct_exists(g, "hp") ? g.hp : 0;
    var mana_growth = variable_struct_exists(g, "mana") ? g.mana : 0;
    var patk_growth = variable_struct_exists(g, "physical_attack") ? g.physical_attack : 0;
    var matk_growth = variable_struct_exists(g, "magic_attack") ? g.magic_attack : 0;
    var pdef_growth = variable_struct_exists(g, "physical_defense") ? g.physical_defense : 0;
    var mdef_growth = variable_struct_exists(g, "magic_defense") ? g.magic_defense : 0;

    var base_hp = t.base_stats.hp + hp_growth * (level - 1);
    var base_mana = t.base_stats.max_mana + mana_growth * (level - 1);
    var base_patk = t.base_stats.physical_attack + patk_growth * (level - 1);
    var base_matk = t.base_stats.magic_attack + matk_growth * (level - 1);
    var base_pdef = t.base_stats.physical_defense + pdef_growth * (level - 1);
    var base_mdef = t.base_stats.magic_defense + mdef_growth * (level - 1);
    var base_speed = t.base_stats.movement_speed;
    var base_range = t.base_stats.attack_range;

    // 종족 보너스 적용
    var hp_r = base_hp * (1 + race.hp_bonus / 100);
    var patk_r = base_patk * (1 + race.atk_bonus / 100);
    var matk_r = base_matk * (1 + race.atk_bonus / 100);
    var pdef_r = base_pdef * (1 + race.def_bonus / 100);
    var mdef_r = base_mdef * (1 + race.def_bonus / 100);
    var speed_r = base_speed * (1 + race.speed_bonus / 100);

    // 직업 보너스 적용
    var final_hp = floor(hp_r * (1 + cls.hp_mod / 100));
    var final_patk = floor(patk_r * (1 + cls.phys_atk_mod / 100));
    var final_matk = floor(matk_r * (1 + cls.mag_atk_mod / 100));
    var final_pdef = floor(pdef_r * (1 + cls.phys_def_mod / 100));
    var final_mdef = floor(mdef_r * (1 + cls.mag_def_mod / 100));
    var final_speed = floor(speed_r * (1 + cls.speed_mod / 100));
    var final_range = base_range + cls.atk_range_mod;

    var unit = {
        id: global.next_unit_id, type: t.type, name: t.name, team: team, level: level, race: t.race, class: t.class,
        hp: final_hp, max_hp: final_hp, mana: base_mana, max_mana: base_mana,
        physical_attack: final_patk, magic_attack: final_matk, physical_defense: final_pdef, magic_defense: final_mdef,
        attack_speed: t.base_stats.attack_speed, movement_speed: final_speed, attack_range: final_range,
        crit_chance: t.secondary_stats.crit_chance, crit_damage: t.secondary_stats.crit_damage,
        dodge_chance: t.secondary_stats.dodge_chance, accuracy: t.secondary_stats.accuracy,
        physical_lifesteal: t.secondary_stats.physical_lifesteal, magic_lifesteal: t.secondary_stats.magic_lifesteal,
        healing_power: t.secondary_stats.healing_power, physical_penetration: t.secondary_stats.physical_penetration,
        magic_penetration: t.secondary_stats.magic_penetration, cooldown_reduction: t.secondary_stats.cooldown_reduction,
        mana_regen: t.secondary_stats.mana_regen, hp_regen: t.secondary_stats.hp_regen,
        cc_resist: t.resistance.cc_resist, debuff_resist: t.resistance.debuff_resist,
        skills: [], skill_cooldowns: {}, x: 0, y: 0, is_alive: true
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
}
'''

if __name__ == "__main__":
    with open('D:/gml_game/under_dog_lord/scripts/scr_data/scr_data.gml', 'w', encoding='utf-8') as f:
        f.write(content)
    print("scr_data.gml updated successfully!")
