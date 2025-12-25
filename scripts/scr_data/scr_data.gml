/// @file scr_data.gml
/// @desc 스킬 및 유닛 데이터

// ============================================
// CSV 파싱 유틸리티
// ============================================

/// @function csv_split_line(line)
/// @desc CSV 한 줄을 배열로 분리
function csv_split_line(line) {
    var result = [];
    var current = "";
    var len = string_length(line);

    for (var i = 1; i <= len; i++) {
        var ch = string_char_at(line, i);
        if (ch == ",") {
            array_push(result, current);
            current = "";
        } else {
            current += ch;
        }
    }
    array_push(result, current);
    return result;
}

/// @function parse_tags(tag_str)
/// @desc 파이프(|) 구분 태그 문자열을 배열로 변환
function parse_tags(tag_str) {
    if (tag_str == "" || tag_str == undefined) return [];
    var result = [];
    var current = "";
    var len = string_length(tag_str);

    for (var i = 1; i <= len; i++) {
        var ch = string_char_at(tag_str, i);
        if (ch == "|") {
            if (current != "") array_push(result, current);
            current = "";
        } else {
            current += ch;
        }
    }
    if (current != "") array_push(result, current);
    return result;
}

// ============================================
// 종족 데이터 (CSV 로드)
// ============================================

function init_race_data() {
    global.races = {};

    var file = file_text_open_read("data/races.csv");
    if (file == -1) {
        show_debug_message("ERROR: data/races.csv not found!");
        return;
    }

    // 헤더 스킵
    var header = file_text_read_string(file);
    file_text_readln(file);

    while (!file_text_eof(file)) {
        var line = file_text_read_string(file);
        file_text_readln(file);

        if (line == "") continue;

        var cols = csv_split_line(line);
        if (array_length(cols) < 21) continue;

        var race_id = cols[0];
        if (race_id == "") continue;

        global.races[$ race_id] = {
            id: race_id,
            name: cols[1],
            hp: real(cols[2]),
            mana: real(cols[3]),
            phys_atk: real(cols[4]),
            mag_atk: real(cols[5]),
            phys_def: real(cols[6]),
            mag_def: real(cols[7]),
            atk_speed: real(cols[8]),
            move_speed: real(cols[9]),
            crit_chance: real(cols[10]),
            crit_damage: real(cols[11]),
            dodge: real(cols[12]),
            accuracy: real(cols[13]),
            lifesteal: real(cols[14]),
            healing_power: real(cols[15]),
            hp_regen: real(cols[16]),
            mana_regen: real(cols[17]),
            cc_resist: real(cols[18]),
            debuff_resist: real(cols[19]),
            tags: parse_tags(cols[20])
        };
    }

    file_text_close(file);
    show_debug_message("Loaded " + string(struct_names_count(global.races)) + " races from CSV");
}

// ============================================
// 직업 데이터 (CSV 로드)
// ============================================

function init_class_data() {
    global.classes = {};

    var file = file_text_open_read("data/classes.csv");
    if (file == -1) {
        show_debug_message("ERROR: data/classes.csv not found!");
        return;
    }

    // 헤더 스킵
    var header = file_text_read_string(file);
    file_text_readln(file);

    while (!file_text_eof(file)) {
        var line = file_text_read_string(file);
        file_text_readln(file);

        if (line == "") continue;

        var cols = csv_split_line(line);
        if (array_length(cols) < 10) continue;

        var class_id = cols[0];
        if (class_id == "") continue;

        global.classes[$ class_id] = {
            id: class_id,
            name: cols[1],
            hp_mod: real(cols[2]),
            phys_atk_mod: real(cols[3]),
            mag_atk_mod: real(cols[4]),
            phys_def_mod: real(cols[5]),
            mag_def_mod: real(cols[6]),
            speed_mod: real(cols[7]),
            atk_range_mod: real(cols[8]),
            tags: parse_tags(cols[9])
        };
    }

    file_text_close(file);
    show_debug_message("Loaded " + string(struct_names_count(global.classes)) + " classes from CSV");
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

// ============================================
// 스킬 데이터 (CSV 로드)
// ============================================

function init_skill_data() {
    global.skills = {};

    var file = file_text_open_read("data/skills.csv");
    if (file == -1) {
        show_debug_message("ERROR: data/skills.csv not found!");
        return;
    }

    // 헤더 스킵
    file_text_read_string(file);
    file_text_readln(file);

    while (!file_text_eof(file)) {
        var line = file_text_read_string(file);
        file_text_readln(file);

        if (line == "") continue;

        var cols = csv_split_line(line);
        if (array_length(cols) < 20) continue;

        var skill_id = cols[0];
        if (skill_id == "") continue;

        // 효과 빌드
        var effects = [];
        var effect_type = cols[5];

        if (effect_type == "damage") {
            var eff = {
                type: "damage",
                base_amount: real(cols[6]),
                scale_stat: cols[7],
                scale_percent: real(cols[8])
            };
            array_push(effects, eff);

            // DoT 추가
            if (real(cols[9]) > 0) {
                array_push(effects, {
                    type: "dot",
                    amount: real(cols[9]),
                    duration: real(cols[10])
                });
            }
        } else if (effect_type == "heal") {
            array_push(effects, {
                type: "heal",
                base_amount: real(cols[11]),
                scale_stat: cols[7],
                scale_percent: real(cols[8])
            });
        }

        // CC 효과 추가
        var cc_type = cols[15];
        if (cc_type != "" && cc_type != "0") {
            array_push(effects, {
                type: cc_type,
                duration: real(cols[16])
            });
        }

        global.skills[$ skill_id] = {
            id: skill_id,
            name: cols[1],
            mana_cost: real(cols[2]),
            cooldown: real(cols[3]),
            damage_type: cols[4],
            effects: effects,
            aoe_radius: real(cols[17]),
            target_type: cols[18],
            tags: parse_tags(cols[19])
        };
    }

    file_text_close(file);
    show_debug_message("Loaded " + string(struct_names_count(global.skills)) + " skills from CSV");
}

function get_skill(skill_id) {
    return global.skills[$ skill_id];
}


// ============================================
// 유닛 데이터 (CSV 로드)
// ============================================

function init_unit_data() {
    global.unit_templates = {};
    global.next_unit_id = 0;

    var file = file_text_open_read("data/units.csv");
    if (file == -1) {
        show_debug_message("ERROR: data/units.csv not found!");
        return;
    }

    // 헤더 스킵
    file_text_read_string(file);
    file_text_readln(file);

    while (!file_text_eof(file)) {
        var line = file_text_read_string(file);
        file_text_readln(file);

        if (line == "") continue;

        var cols = csv_split_line(line);
        if (array_length(cols) < 35) continue;

        var unit_id = cols[0];
        if (unit_id == "") continue;

        // 스킬 파싱 (파이프 구분)
        var skills_arr = parse_tags(cols[33]);

        global.unit_templates[$ unit_id] = {
            type: unit_id,
            name: cols[1],
            race: cols[2],
            class: cols[3],
            base_stats: {
                hp: real(cols[4]),
                max_mana: real(cols[5]),
                physical_attack: real(cols[6]),
                magic_attack: real(cols[7]),
                physical_defense: real(cols[8]),
                magic_defense: real(cols[9]),
                attack_speed: real(cols[10]),
                movement_speed: real(cols[11]),
                attack_range: real(cols[12])
            },
            secondary_stats: {
                crit_chance: real(cols[13]),
                crit_damage: real(cols[14]),
                dodge_chance: real(cols[15]),
                accuracy: real(cols[16]),
                physical_lifesteal: real(cols[17]),
                magic_lifesteal: real(cols[18]),
                healing_power: real(cols[19]),
                physical_penetration: real(cols[20]),
                magic_penetration: real(cols[21]),
                cooldown_reduction: real(cols[22]),
                mana_regen: real(cols[23]),
                hp_regen: real(cols[24])
            },
            resistance: {
                cc_resist: real(cols[25]),
                debuff_resist: real(cols[26])
            },
            growth_per_level: {
                hp: real(cols[27]),
                mana: real(cols[28]),
                physical_attack: real(cols[29]),
                magic_attack: real(cols[30]),
                physical_defense: real(cols[31]),
                magic_defense: real(cols[32])
            },
            skills: skills_arr,
            tags: parse_tags(cols[34])
        };
    }

    file_text_close(file);
    show_debug_message("Loaded " + string(struct_names_count(global.unit_templates)) + " unit templates from CSV");
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

// ============================================
// 건물 데이터 (CSV 로드)
// ============================================

function init_building_data() {
    global.buildings = {};

    var file = file_text_open_read("data/buildings.csv");
    if (file == -1) {
        show_debug_message("ERROR: data/buildings.csv not found!");
        return;
    }

    // 헤더 스킵
    file_text_read_string(file);
    file_text_readln(file);

    while (!file_text_eof(file)) {
        var line = file_text_read_string(file);
        file_text_readln(file);

        if (line == "") continue;

        var cols = csv_split_line(line);
        if (array_length(cols) < 18) continue;

        var building_id = cols[0];
        if (building_id == "") continue;

        global.buildings[$ building_id] = {
            id: building_id,
            name: cols[1],
            hp: real(cols[2]),
            build_cost: {
                gold: real(cols[3]),
                wood: real(cols[4]),
                stone: real(cols[5])
            },
            build_time: real(cols[6]),
            size: {
                x: real(cols[7]),
                y: real(cols[8])
            },
            produces: parse_tags(cols[9]),
            income: {
                gold: real(cols[10]),
                wood: real(cols[11]),
                stone: real(cols[12]),
                interval: real(cols[13])
            },
            max_garrison: real(cols[14]),
            defense_bonus: real(cols[15]),
            requirements: parse_tags(cols[16]),
            tags: parse_tags(cols[17])
        };
    }

    file_text_close(file);
    show_debug_message("Loaded " + string(struct_names_count(global.buildings)) + " buildings from CSV");
}

function get_building(building_id) {
    return global.buildings[$ building_id];
}

/// @function init_all_data()
/// @desc 모든 게임 데이터 초기화
function init_all_data() {
    init_race_data();
    init_class_data();
    init_skill_data();
    init_unit_data();
    init_building_data();
    init_status_system();  // 상태이상 시스템 초기화
}
