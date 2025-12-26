/// @file scr_building.gml
/// @desc M4-2 건물 시스템

// ========================================
// 건물 템플릿 초기화
// ========================================

/// @func init_building_templates()
/// @desc 건물 템플릿 데이터 초기화
function init_building_templates() {
    global.building_templates = {};

    // ========================================
    // 직업 건물 (유닛 생산)
    // ========================================

    global.building_templates[$ "barracks"] = {
        id: "barracks",
        name: "병영",
        description: "전사 계열 유닛을 생산합니다.",
        category: "job",

        build_cost: { gold: 200, materials: 100 },
        build_time: 10,

        max_level: 5,
        upgrade_costs: [
            { gold: 200, materials: 100 },
            { gold: 400, materials: 200 },
            { gold: 800, materials: 400 },
            { gold: 1600, materials: 800 }
        ],

        produces: ["warrior", "knight"],
        unlock_at_level: { warrior: 1, knight: 3 },

        garrison_slots: 2,
        garrison_buff: { physical_attack: 10, physical_defense: 5 }
    };

    global.building_templates[$ "archery_range"] = {
        id: "archery_range",
        name: "궁술장",
        description: "궁수 계열 유닛을 생산합니다.",
        category: "job",

        build_cost: { gold: 180, materials: 80 },
        build_time: 8,

        max_level: 5,
        upgrade_costs: [
            { gold: 180, materials: 80 },
            { gold: 360, materials: 160 },
            { gold: 720, materials: 320 },
            { gold: 1440, materials: 640 }
        ],

        produces: ["archer"],
        unlock_at_level: { archer: 1 },

        garrison_slots: 2,
        garrison_buff: { physical_attack: 15, attack_range: 30 }
    };

    global.building_templates[$ "mage_tower"] = {
        id: "mage_tower",
        name: "마법사 탑",
        description: "마법사 계열 유닛을 생산합니다.",
        category: "job",

        build_cost: { gold: 300, materials: 150, mana_crystal: 10 },
        build_time: 15,

        max_level: 5,
        upgrade_costs: [
            { gold: 300, materials: 150, mana_crystal: 15 },
            { gold: 600, materials: 300, mana_crystal: 30 },
            { gold: 1200, materials: 600, mana_crystal: 60 },
            { gold: 2400, materials: 1200, mana_crystal: 120 }
        ],

        produces: ["fire_mage"],
        unlock_at_level: { fire_mage: 1 },

        garrison_slots: 1,
        garrison_buff: { magic_attack: 20 }
    };

    global.building_templates[$ "temple"] = {
        id: "temple",
        name: "신전",
        description: "사제 계열 유닛을 생산하고 신앙을 축적합니다.",
        category: "job",

        build_cost: { gold: 400, materials: 200, faith: 20 },
        build_time: 20,

        max_level: 5,
        upgrade_costs: [
            { gold: 400, materials: 200, faith: 30 },
            { gold: 800, materials: 400, faith: 50 },
            { gold: 1600, materials: 800, faith: 80 },
            { gold: 3200, materials: 1600, faith: 120 }
        ],

        produces: ["priest"],
        unlock_at_level: { priest: 1 },

        garrison_slots: 2,
        garrison_buff: { magic_attack: 10, max_hp: 50 },

        passive_production: { faith: 0.5 }
    };

    global.building_templates[$ "assassin_guild"] = {
        id: "assassin_guild",
        name: "암살자 길드",
        description: "암살자를 생산합니다.",
        category: "job",

        build_cost: { gold: 350, materials: 120 },
        build_time: 12,

        max_level: 5,
        upgrade_costs: [
            { gold: 350, materials: 120 },
            { gold: 700, materials: 240 },
            { gold: 1400, materials: 480 },
            { gold: 2800, materials: 960 }
        ],

        produces: ["assassin"],
        unlock_at_level: { assassin: 1 },

        garrison_slots: 1,
        garrison_buff: { physical_attack: 25, movement_speed: 20 }
    };

    // ========================================
    // 방어 건물
    // ========================================

    global.building_templates[$ "watchtower"] = {
        id: "watchtower",
        name: "감시탑",
        description: "주변 적을 자동으로 공격합니다.",
        category: "defense",

        build_cost: { gold: 150, materials: 80 },
        build_time: 8,

        max_level: 3,
        upgrade_costs: [
            { gold: 200, materials: 100 },
            { gold: 400, materials: 200 }
        ],

        auto_attack: {
            damage: 30,
            range: 300,
            attack_speed: 1.0,
            damage_type: "physical"
        },

        garrison_slots: 1,
        garrison_attack_bonus: 0.5
    };

    global.building_templates[$ "wall"] = {
        id: "wall",
        name: "성벽",
        description: "적의 진행을 막는 장애물입니다.",
        category: "defense",

        build_cost: { gold: 50, materials: 100 },
        build_time: 5,

        max_level: 3,
        upgrade_costs: [
            { gold: 75, materials: 150 },
            { gold: 100, materials: 200 }
        ],

        hp: 500,
        hp_per_level: 250,
        blocks_movement: true
    };

    // ========================================
    // 지원 건물 (자원 생산)
    // ========================================

    global.building_templates[$ "farm"] = {
        id: "farm",
        name: "농장",
        description: "식량을 생산합니다.",
        category: "support",

        build_cost: { gold: 100, materials: 50 },
        build_time: 8,

        max_level: 5,
        upgrade_costs: [
            { gold: 150, materials: 75 },
            { gold: 225, materials: 110 },
            { gold: 340, materials: 170 },
            { gold: 500, materials: 250 }
        ],

        passive_production: { food: 2 },
        production_per_level: { food: 1 }
    };

    global.building_templates[$ "mine"] = {
        id: "mine",
        name: "광산",
        description: "자재를 생산합니다.",
        category: "support",

        build_cost: { gold: 150, materials: 30 },
        build_time: 10,

        max_level: 5,
        upgrade_costs: [
            { gold: 200, materials: 50 },
            { gold: 300, materials: 75 },
            { gold: 450, materials: 110 },
            { gold: 675, materials: 165 }
        ],

        passive_production: { materials: 1 },
        production_per_level: { materials: 0.5 }
    };

    global.building_templates[$ "mana_well"] = {
        id: "mana_well",
        name: "마나 우물",
        description: "마나 결정을 생산합니다.",
        category: "support",

        build_cost: { gold: 500, materials: 200, mana_crystal: 30 },
        build_time: 20,

        max_level: 3,
        upgrade_costs: [
            { gold: 750, materials: 300, mana_crystal: 50 },
            { gold: 1125, materials: 450, mana_crystal: 75 }
        ],

        passive_production: { mana_crystal: 0.2 },
        production_per_level: { mana_crystal: 0.1 }
    };

    combat_log("건물 템플릿 " + string(struct_names_count(global.building_templates)) + "개 로드됨");
}

// ========================================
// 건물 시스템 초기화
// ========================================

/// @func init_building_system()
/// @desc 건물 시스템 초기화
function init_building_system() {
    if (!variable_global_exists("building_templates")) {
        init_building_templates();
    }

    global.buildings = [];  // 건설된 건물 목록
    global.building_slots = 10;  // 최대 건물 슬롯

    combat_log("건물 시스템 초기화 완료");
}

// ========================================
// 건물 생성/건설
// ========================================

/// @func create_building(building_id, x, y)
/// @desc 건물 생성 (struct 기반)
function create_building(building_id, _x, _y) {
    if (!variable_global_exists("building_templates")) {
        init_building_templates();
    }

    var template = global.building_templates[$ building_id];
    if (template == undefined) {
        combat_log("ERROR: 건물 템플릿 없음 - " + building_id);
        return undefined;
    }

    // 비용 체크
    if (!has_resources(template.build_cost)) {
        combat_log("건설 불가: 자원 부족 - " + template.name);
        return undefined;
    }

    // 슬롯 체크
    if (array_length(global.buildings) >= global.building_slots) {
        combat_log("건설 불가: 슬롯 부족");
        return undefined;
    }

    // 비용 지불
    spend_resources(template.build_cost, template.name + " 건설");

    // 건물 struct 생성
    var building = {
        id: building_id,
        template: template,
        name: template.name,
        level: 1,

        x: _x,
        y: _y,

        // 상태
        state: "constructing",  // constructing, active, upgrading
        construction_progress: 0,
        construction_time: template.build_time,

        // 주둔
        garrison_units: [],

        // 생산
        production_queue: [],
        current_production: undefined,
        production_progress: 0,

        // HP (방어 건물)
        hp: template[$ "hp"] ?? 0,
        max_hp: template[$ "hp"] ?? 0,

        // 자동 공격 (감시탑)
        attack_timer: 0,
        attack_target: undefined
    };

    // 건물 목록에 추가
    if (!variable_global_exists("buildings")) {
        global.buildings = [];
    }
    array_push(global.buildings, building);

    combat_log(template.name + " 건설 시작 (" + string(template.build_time) + "초)");

    return building;
}

/// @func update_buildings(delta)
/// @desc 모든 건물 업데이트
function update_buildings(delta) {
    if (!variable_global_exists("buildings")) return;

    for (var i = 0; i < array_length(global.buildings); i++) {
        var building = global.buildings[i];

        switch (building.state) {
            case "constructing":
                update_building_construction(building, delta);
                break;
            case "active":
                update_building_active(building, delta);
                break;
            case "upgrading":
                update_building_upgrade(building, delta);
                break;
        }
    }
}

/// @func update_building_construction(building, delta)
function update_building_construction(building, delta) {
    building.construction_progress += delta / building.construction_time;

    if (building.construction_progress >= 1) {
        building.state = "active";
        building.construction_progress = 1;
        combat_log(building.name + " 건설 완료!");
    }
}

/// @func update_building_active(building, delta)
function update_building_active(building, delta) {
    var template = building.template;

    // 패시브 생산
    if (variable_struct_exists(template, "passive_production")) {
        var production = template.passive_production;

        // 레벨 보너스 적용
        if (variable_struct_exists(template, "production_per_level")) {
            var bonus = template.production_per_level;
            var types = struct_get_names(bonus);
            for (var j = 0; j < array_length(types); j++) {
                var type = types[j];
                var extra = bonus[$ type] * (building.level - 1);
                if (variable_struct_exists(production, type)) {
                    production[$ type] += extra;
                }
            }
        }

        apply_passive_production(production, delta);
    }

    // 자동 공격 (감시탑)
    if (variable_struct_exists(template, "auto_attack")) {
        update_building_auto_attack(building, delta);
    }

    // 유닛 생산
    update_building_production(building, delta);
}

/// @func update_building_upgrade(building, delta)
function update_building_upgrade(building, delta) {
    building.construction_progress += delta / building.construction_time;

    if (building.construction_progress >= 1) {
        building.level++;
        building.state = "active";
        building.construction_progress = 1;

        // HP 증가 (방어 건물)
        if (variable_struct_exists(building.template, "hp_per_level")) {
            building.max_hp += building.template.hp_per_level;
            building.hp = building.max_hp;
        }

        combat_log(building.name + " 레벨 " + string(building.level) + " 업그레이드 완료!");
    }
}

// ========================================
// 건물 업그레이드
// ========================================

/// @func upgrade_building(building)
/// @desc 건물 업그레이드
function upgrade_building(building) {
    if (building.state != "active") {
        combat_log("업그레이드 불가: 건물이 활성 상태가 아님");
        return false;
    }

    var template = building.template;

    if (building.level >= template.max_level) {
        combat_log("업그레이드 불가: 최대 레벨");
        return false;
    }

    // 업그레이드 비용
    var cost_index = building.level - 1;
    if (cost_index >= array_length(template.upgrade_costs)) {
        return false;
    }

    var cost = template.upgrade_costs[cost_index];

    if (!has_resources(cost)) {
        combat_log("업그레이드 불가: 자원 부족");
        return false;
    }

    // 비용 지불
    spend_resources(cost, building.name + " 업그레이드");

    // 업그레이드 시작
    building.state = "upgrading";
    building.construction_time = template.build_time * (building.level + 1) * 0.5;
    building.construction_progress = 0;

    combat_log(building.name + " 레벨 " + string(building.level + 1) + " 업그레이드 시작");

    return true;
}

// ========================================
// 자동 공격 (감시탑)
// ========================================

/// @func update_building_auto_attack(building, delta)
function update_building_auto_attack(building, delta) {
    var attack_data = building.template.auto_attack;

    building.attack_timer -= delta;

    if (building.attack_timer <= 0) {
        // 타겟 찾기
        var target = find_enemy_in_range(building.x, building.y, attack_data.range);

        if (target != undefined) {
            // 공격
            var damage = attack_data.damage;

            // 주둔 보너스
            if (array_length(building.garrison_units) > 0 && variable_struct_exists(building.template, "garrison_attack_bonus")) {
                var garrison = building.garrison_units[0];
                damage += garrison.physical_attack * building.template.garrison_attack_bonus;
            }

            var damage_info = {
                damage: damage,
                damage_type: attack_data.damage_type,
                is_crit: false
            };

            apply_damage(target, damage_info, undefined);

            building.attack_timer = 1.0 / attack_data.attack_speed;
        }
    }
}

/// @func find_enemy_in_range(x, y, range)
function find_enemy_in_range(_x, _y, range) {
    if (!variable_global_exists("enemy_units")) return undefined;

    var nearest = undefined;
    var nearest_dist = range;

    for (var i = 0; i < array_length(global.enemy_units); i++) {
        var enemy = global.enemy_units[i];
        if (enemy.hp <= 0) continue;

        var dist = point_distance(_x, _y, enemy.x, enemy.y);
        if (dist < nearest_dist) {
            nearest_dist = dist;
            nearest = enemy;
        }
    }

    return nearest;
}

// ========================================
// 주둔 시스템
// ========================================

/// @func garrison_unit(building, unit)
/// @desc 유닛을 건물에 주둔
function garrison_unit(building, unit) {
    var max_slots = building.template.garrison_slots ?? 0;

    if (array_length(building.garrison_units) >= max_slots) {
        combat_log("주둔 불가: 슬롯 부족");
        return false;
    }

    // 전투 목록에서 제거
    var idx = array_get_index(global.ally_units, unit);
    if (idx >= 0) {
        array_delete(global.ally_units, idx, 1);
    }

    // 배치 슬롯에서 제거
    remove_unit_from_slot(unit);

    // 주둔 추가
    array_push(building.garrison_units, unit);

    // 버프 적용
    if (variable_struct_exists(building.template, "garrison_buff")) {
        apply_garrison_buff(unit, building.template.garrison_buff);
    }

    combat_log((unit.display_name ?? "유닛") + " → " + building.name + " 주둔");

    return true;
}

/// @func ungarrison_unit(building, unit)
/// @desc 유닛 주둔 해제
function ungarrison_unit(building, unit) {
    var idx = array_get_index(building.garrison_units, unit);
    if (idx < 0) return false;

    array_delete(building.garrison_units, idx, 1);

    // 버프 제거
    if (variable_struct_exists(building.template, "garrison_buff")) {
        remove_garrison_buff(unit, building.template.garrison_buff);
    }

    // 전투 목록에 복귀
    array_push(global.ally_units, unit);

    // 자동 배치
    auto_deploy_unit(unit);

    combat_log((unit.display_name ?? "유닛") + " 주둔 해제");

    return true;
}

/// @func apply_garrison_buff(unit, buff)
function apply_garrison_buff(unit, buff) {
    var types = struct_get_names(buff);
    for (var i = 0; i < array_length(types); i++) {
        var stat = types[i];
        var amount = buff[$ stat];

        if (variable_struct_exists(unit, stat)) {
            unit[$ stat] += amount;
        }
    }
}

/// @func remove_garrison_buff(unit, buff)
function remove_garrison_buff(unit, buff) {
    var types = struct_get_names(buff);
    for (var i = 0; i < array_length(types); i++) {
        var stat = types[i];
        var amount = buff[$ stat];

        if (variable_struct_exists(unit, stat)) {
            unit[$ stat] -= amount;
        }
    }
}

// ========================================
// 건물 UI
// ========================================

/// @func draw_buildings()
/// @desc 모든 건물 그리기
function draw_buildings() {
    if (!variable_global_exists("buildings")) return;

    for (var i = 0; i < array_length(global.buildings); i++) {
        var building = global.buildings[i];
        draw_building(building);
    }
}

/// @func draw_building(building)
function draw_building(building) {
    var size = 50;
    var x1 = building.x - size/2;
    var y1 = building.y - size/2;
    var x2 = building.x + size/2;
    var y2 = building.y + size/2;

    // 카테고리별 색상
    var color = c_gray;
    switch (building.template.category) {
        case "job": color = c_blue; break;
        case "defense": color = c_red; break;
        case "support": color = c_green; break;
    }

    // 상태별 알파
    var alpha = 1;
    if (building.state == "constructing" || building.state == "upgrading") {
        alpha = 0.5 + building.construction_progress * 0.5;
    }

    // 건물 본체
    draw_set_alpha(alpha);
    draw_set_color(color);
    draw_rectangle(x1, y1, x2, y2, false);
    draw_set_alpha(1);

    // 테두리
    draw_set_color(c_white);
    draw_rectangle(x1, y1, x2, y2, true);

    // 레벨 표시
    draw_set_halign(fa_right);
    draw_set_valign(fa_top);
    draw_set_color(c_yellow);
    draw_text(x2 - 2, y1 + 2, "Lv" + string(building.level));

    // 이름
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    draw_set_color(c_white);
    draw_text(building.x, y1 - 2, building.name);

    // 건설/업그레이드 진행률
    if (building.state == "constructing" || building.state == "upgrading") {
        var bar_y = y2 + 5;
        var bar_w = size;
        var bar_h = 4;

        draw_set_color(c_dkgray);
        draw_rectangle(x1, bar_y, x2, bar_y + bar_h, false);

        draw_set_color(c_lime);
        draw_rectangle(x1, bar_y, x1 + bar_w * building.construction_progress, bar_y + bar_h, false);
    }

    // 주둔 유닛 수
    var garrison_count = array_length(building.garrison_units);
    var max_garrison = building.template.garrison_slots ?? 0;
    if (max_garrison > 0) {
        draw_set_halign(fa_left);
        draw_set_valign(fa_bottom);
        draw_set_color(c_aqua);
        draw_text(x1 + 2, y2 - 2, string(garrison_count) + "/" + string(max_garrison));
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
