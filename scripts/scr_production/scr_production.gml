/// @file scr_production.gml
/// @desc M4-3 유닛 생산 시스템

// ========================================
// 유닛 생산 비용 데이터
// ========================================

/// @func init_unit_costs()
/// @desc 유닛 생산 비용 초기화
function init_unit_costs() {
    global.unit_costs = {
        // 전사 계열
        warrior: {
            cost: { gold: 50, food: 20 },
            time: 5,
            required_building: "barracks",
            required_level: 1
        },
        knight: {
            cost: { gold: 120, food: 40 },
            time: 10,
            required_building: "barracks",
            required_level: 3
        },

        // 궁수 계열
        archer: {
            cost: { gold: 60, food: 15 },
            time: 6,
            required_building: "archery_range",
            required_level: 1
        },

        // 마법사 계열
        fire_mage: {
            cost: { gold: 100, food: 25, mana_crystal: 5 },
            time: 12,
            required_building: "mage_tower",
            required_level: 1
        },

        // 사제 계열
        priest: {
            cost: { gold: 80, food: 20, faith: 10 },
            time: 8,
            required_building: "temple",
            required_level: 1
        },

        // 암살자 계열
        assassin: {
            cost: { gold: 90, food: 25 },
            time: 7,
            required_building: "assassin_guild",
            required_level: 1
        }
    };

    combat_log("유닛 생산 비용 로드됨");
}

// ========================================
// 생산 가능 여부 체크
// ========================================

/// @func can_produce_unit(building, unit_id)
/// @desc 유닛 생산 가능 여부 체크
function can_produce_unit(building, unit_id) {
    if (!variable_global_exists("unit_costs")) {
        init_unit_costs();
    }

    // 건물 상태 체크
    if (building.state != "active") {
        return { can: false, reason: "건물이 활성 상태가 아닙니다" };
    }

    // 유닛 비용 데이터 체크
    var unit_data = global.unit_costs[$ unit_id];
    if (unit_data == undefined) {
        return { can: false, reason: "알 수 없는 유닛입니다" };
    }

    // 건물 타입 체크
    if (unit_data.required_building != building.id) {
        return { can: false, reason: "이 건물에서 생산할 수 없습니다" };
    }

    // 건물 레벨 체크
    if (building.level < unit_data.required_level) {
        return { can: false, reason: "건물 레벨이 부족합니다 (필요: Lv" + string(unit_data.required_level) + ")" };
    }

    // 자원 체크
    if (!has_resources(unit_data.cost)) {
        var missing = get_missing_resources(unit_data.cost);
        var missing_text = "";
        var types = struct_get_names(missing);
        for (var i = 0; i < array_length(types); i++) {
            if (missing_text != "") missing_text += ", ";
            missing_text += types[i] + " " + string(floor(missing[$ types[i]]));
        }
        return { can: false, reason: "자원 부족: " + missing_text };
    }

    // 생산 대기열 체크 (최대 5개)
    if (array_length(building.production_queue) >= 5) {
        return { can: false, reason: "생산 대기열이 가득 찼습니다" };
    }

    return { can: true, reason: "" };
}

// ========================================
// 생산 시작
// ========================================

/// @func start_production(building, unit_id)
/// @desc 유닛 생산 시작
function start_production(building, unit_id) {
    var check = can_produce_unit(building, unit_id);
    if (!check.can) {
        combat_log("생산 불가: " + check.reason);
        return false;
    }

    var unit_data = global.unit_costs[$ unit_id];

    // 비용 지불
    var unit_name = get_ally_base_stats(unit_id).name;
    spend_resources(unit_data.cost, unit_name + " 생산");

    // 생산 대기열에 추가
    var production = {
        unit_id: unit_id,
        name: unit_name,
        time: unit_data.time,
        progress: 0
    };

    array_push(building.production_queue, production);

    combat_log(building.name + ": " + unit_name + " 생산 대기열 추가");

    return true;
}

/// @func update_building_production(building, delta)
/// @desc 건물 생산 업데이트
function update_building_production(building, delta) {
    if (array_length(building.production_queue) == 0) return;

    // 첫 번째 항목 생산 중
    var current = building.production_queue[0];

    // 생산 속도 보너스 적용
    var speed_mult = 1.0;
    if (variable_struct_exists(building.template, "level_bonuses")) {
        for (var i = 1; i < building.level; i++) {
            var bonus = building.template.level_bonuses[i];
            if (bonus != undefined && variable_struct_exists(bonus, "production_speed")) {
                speed_mult += bonus.production_speed;
            }
        }
    }

    current.progress += (delta / current.time) * speed_mult;

    if (current.progress >= 1) {
        // 생산 완료
        complete_production(building, current);
        array_delete(building.production_queue, 0, 1);
    }
}

/// @func complete_production(building, production)
/// @desc 유닛 생산 완료
function complete_production(building, production) {
    // 유닛 생성
    var unit = create_ally_unit(production.unit_id, building.x, building.y + 60, 1);

    if (unit != undefined) {
        // 자동 배치
        auto_deploy_unit(unit);

        combat_log(building.name + ": " + production.name + " 생산 완료!");
    }
}

/// @func cancel_production(building, index)
/// @desc 생산 취소 (환불 없음)
function cancel_production(building, index) {
    if (index < 0 || index >= array_length(building.production_queue)) {
        return false;
    }

    var cancelled = building.production_queue[index];
    array_delete(building.production_queue, index, 1);

    combat_log(building.name + ": " + cancelled.name + " 생산 취소");

    return true;
}

// ========================================
// 생산 UI
// ========================================

/// @func draw_production_queue(building, x, y)
/// @desc 생산 대기열 UI 그리기
function draw_production_queue(building, _x, _y) {
    if (array_length(building.production_queue) == 0) return;

    var slot_size = 40;
    var spacing = 5;

    for (var i = 0; i < array_length(building.production_queue); i++) {
        var production = building.production_queue[i];
        var px = _x + i * (slot_size + spacing);

        // 슬롯 배경
        draw_set_color(c_dkgray);
        draw_rectangle(px, _y, px + slot_size, _y + slot_size, false);

        // 진행률 (첫 번째 항목만)
        if (i == 0) {
            draw_set_color(c_lime);
            var progress_height = slot_size * production.progress;
            draw_rectangle(px, _y + slot_size - progress_height, px + slot_size, _y + slot_size, false);
        }

        // 테두리
        draw_set_color(c_white);
        draw_rectangle(px, _y, px + slot_size, _y + slot_size, true);

        // 유닛 ID (간략화)
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_color(c_white);
        draw_text(px + slot_size/2, _y + slot_size/2, string_char_at(production.unit_id, 1));
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

// ========================================
// 생산 가능 유닛 목록
// ========================================

/// @func get_producible_units(building)
/// @desc 건물에서 생산 가능한 유닛 목록 반환
function get_producible_units(building) {
    if (!variable_global_exists("unit_costs")) {
        init_unit_costs();
    }

    var result = [];
    var template = building.template;

    if (!variable_struct_exists(template, "produces")) {
        return result;
    }

    for (var i = 0; i < array_length(template.produces); i++) {
        var unit_id = template.produces[i];

        // 레벨 체크
        var unlock_level = 1;
        if (variable_struct_exists(template, "unlock_at_level")) {
            unlock_level = template.unlock_at_level[$ unit_id] ?? 1;
        }

        if (building.level >= unlock_level) {
            var unit_data = global.unit_costs[$ unit_id];
            if (unit_data != undefined) {
                array_push(result, {
                    id: unit_id,
                    name: get_ally_base_stats(unit_id).name,
                    cost: unit_data.cost,
                    time: unit_data.time,
                    can_afford: has_resources(unit_data.cost)
                });
            }
        }
    }

    return result;
}

// ========================================
// 식량 소모 시스템
// ========================================

/// @func calculate_food_consumption()
/// @desc 현재 유닛들의 식량 소모량 계산
function calculate_food_consumption() {
    var consumption = 0;

    // 아군 유닛
    if (variable_global_exists("ally_units")) {
        consumption += array_length(global.ally_units) * 1;  // 유닛당 1 식량/초
    }

    // 주둔 유닛
    if (variable_global_exists("buildings")) {
        for (var i = 0; i < array_length(global.buildings); i++) {
            var building = global.buildings[i];
            consumption += array_length(building.garrison_units) * 0.5;  // 주둔 유닛은 50% 소모
        }
    }

    return consumption;
}

/// @func update_food_consumption(delta)
/// @desc 식량 소모 업데이트 (웨이브 중)
function update_food_consumption(delta) {
    var consumption = calculate_food_consumption() * delta;

    if (consumption > 0) {
        remove_resource("food", consumption, "유닛 유지비");
    }

    // 식량 0이면 유닛 사기 저하 (M6에서 구현)
    if (get_resource("food") <= 0) {
        // TODO: 사기 시스템
    }
}

// ========================================
// 통합 업데이트
// ========================================

/// @func update_economy(delta)
/// @desc 경제 시스템 통합 업데이트
function update_economy(delta) {
    // 건물 업데이트
    update_buildings(delta);

    // 식량 소모 (전투 중에만)
    if (variable_global_exists("wave") && global.wave.state == "in_progress") {
        update_food_consumption(delta);
    }
}
