#!/usr/bin/env python3
"""Expand race bonus system with more stat types"""

content = '''/// @file scr_data.gml
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
}
'''

if __name__ == "__main__":
    with open('D:/gml_game/under_dog_lord/scripts/scr_data/scr_data.gml', 'w', encoding='utf-8') as f:
        f.write(content)
    print("Updated scr_data.gml with expanded race bonus system!")
