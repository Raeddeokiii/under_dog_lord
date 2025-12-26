/// @file scr_resource.gml
/// @desc M4-1 자원 시스템

// ========================================
// 자원 시스템 초기화
// ========================================

/// @func init_resource_system()
/// @desc 자원 시스템 초기화
function init_resource_system() {
    global.resources = {
        gold: {
            current: 500,
            max: 99999,
            name: "골드",
            color: c_yellow
        },
        food: {
            current: 100,
            max: 9999,
            name: "식량",
            color: c_orange
        },
        materials: {
            current: 50,
            max: 9999,
            name: "자재",
            color: c_gray
        },
        mana_crystal: {
            current: 0,
            max: 999,
            name: "마나 결정",
            color: c_purple
        },
        faith: {
            current: 0,
            max: 999,
            name: "신앙",
            color: c_aqua
        }
    };

    // 수입/지출 추적
    global.resource_income = {
        gold: 0,
        food: 0,
        materials: 0,
        mana_crystal: 0,
        faith: 0
    };

    global.resource_expense = {
        gold: 0,
        food: 0,
        materials: 0,
        mana_crystal: 0,
        faith: 0
    };

    combat_log("자원 시스템 초기화 완료");
}

// ========================================
// 자원 조작 함수
// ========================================

/// @func get_resource(type)
/// @desc 현재 자원량 반환
function get_resource(type) {
    if (!variable_global_exists("resources")) {
        init_resource_system();
    }

    if (!variable_struct_exists(global.resources, type)) {
        combat_log("ERROR: 존재하지 않는 자원 - " + type);
        return 0;
    }

    return global.resources[$ type].current;
}

/// @func add_resource(type, amount, source)
/// @desc 자원 추가
function add_resource(type, amount, source) {
    if (!variable_global_exists("resources")) {
        init_resource_system();
    }

    if (!variable_struct_exists(global.resources, type)) {
        combat_log("ERROR: 존재하지 않는 자원 - " + type);
        return false;
    }

    var res = global.resources[$ type];
    var old_value = res.current;
    res.current = min(res.current + amount, res.max);
    var actual_added = res.current - old_value;

    // 수입 추적
    global.resource_income[$ type] += actual_added;

    if (actual_added > 0) {
        combat_log(res.name + " +" + string(floor(actual_added)) + " (" + source + ")");
    }

    return true;
}

/// @func remove_resource(type, amount, reason)
/// @desc 자원 소모
function remove_resource(type, amount, reason) {
    if (!variable_global_exists("resources")) {
        init_resource_system();
    }

    if (!variable_struct_exists(global.resources, type)) {
        combat_log("ERROR: 존재하지 않는 자원 - " + type);
        return false;
    }

    var res = global.resources[$ type];

    // 자원 부족 체크
    if (res.current < amount) {
        combat_log("자원 부족: " + res.name + " (필요: " + string(amount) + ", 보유: " + string(floor(res.current)) + ")");
        return false;
    }

    var old_value = res.current;
    res.current -= amount;

    // 지출 추적
    global.resource_expense[$ type] += amount;

    combat_log(res.name + " -" + string(floor(amount)) + " (" + reason + ")");

    return true;
}

/// @func has_resources(cost_struct)
/// @desc 여러 자원을 동시에 체크
function has_resources(cost_struct) {
    var types = struct_get_names(cost_struct);

    for (var i = 0; i < array_length(types); i++) {
        var type = types[i];
        var required = cost_struct[$ type];
        if (get_resource(type) < required) {
            return false;
        }
    }

    return true;
}

/// @func spend_resources(cost_struct, reason)
/// @desc 여러 자원을 동시에 소모
function spend_resources(cost_struct, reason) {
    // 먼저 충분한지 체크
    if (!has_resources(cost_struct)) {
        return false;
    }

    // 모두 소모
    var types = struct_get_names(cost_struct);
    for (var i = 0; i < array_length(types); i++) {
        var type = types[i];
        var amount = cost_struct[$ type];
        remove_resource(type, amount, reason);
    }

    return true;
}

/// @func get_missing_resources(cost_struct)
/// @desc 부족한 자원 목록 반환
function get_missing_resources(cost_struct) {
    var missing = {};
    var types = struct_get_names(cost_struct);

    for (var i = 0; i < array_length(types); i++) {
        var type = types[i];
        var required = cost_struct[$ type];
        var current = get_resource(type);

        if (current < required) {
            missing[$ type] = required - current;
        }
    }

    return missing;
}

// ========================================
// 웨이브 보상 시스템
// ========================================

/// @func calculate_wave_rewards(wave_num)
/// @desc 웨이브 클리어 보상 계산
function calculate_wave_rewards(wave_num) {
    var rewards = {
        gold: 0,
        food: 0,
        materials: 0,
        mana_crystal: 0,
        faith: 0
    };

    // 기본 골드
    rewards.gold = 30 + (wave_num * 15);

    // 5웨이브마다 보너스
    if (wave_num % 5 == 0) {
        rewards.gold *= 2;
        rewards.materials = 20 + (wave_num * 2);
    }

    // 10웨이브마다 (보스) 추가 보상
    if (wave_num % 10 == 0) {
        rewards.gold = floor(rewards.gold * 1.5);
        rewards.mana_crystal = floor(wave_num / 10) * 5;
        rewards.faith = floor(wave_num / 10) * 3;
    }

    // 식량은 매 웨이브
    rewards.food = 10 + floor(wave_num / 3) * 5;

    return rewards;
}

/// @func give_wave_rewards(wave_num)
/// @desc 웨이브 보상 지급
function give_wave_rewards(wave_num) {
    var rewards = calculate_wave_rewards(wave_num);
    var source = "웨이브 " + string(wave_num) + " 클리어";

    var types = struct_get_names(rewards);
    for (var i = 0; i < array_length(types); i++) {
        var type = types[i];
        var amount = rewards[$ type];
        if (amount > 0) {
            add_resource(type, amount, source);
        }
    }

    return rewards;
}

// ========================================
// 자원 UI
// ========================================

/// @func draw_resource_ui()
/// @desc 자원 UI 그리기
function draw_resource_ui() {
    if (!variable_global_exists("resources")) return;

    var start_x = 10;
    var start_y = 10;
    var spacing = 120;
    var idx = 0;

    // 배경 패널
    draw_set_alpha(0.7);
    draw_set_color(c_black);
    draw_roundrect(start_x - 5, start_y - 5, start_x + 480, start_y + 30, false);
    draw_set_alpha(1);

    var resource_order = ["gold", "food", "materials", "mana_crystal", "faith"];

    for (var i = 0; i < array_length(resource_order); i++) {
        var type = resource_order[i];
        var res = global.resources[$ type];

        // 보유량 0이고 마나/신앙은 숨김
        if (res.current <= 0 && (type == "mana_crystal" || type == "faith")) {
            continue;
        }

        var px = start_x + (idx * spacing);
        var py = start_y + 12;

        // 아이콘 (원형으로 대체)
        draw_set_color(res.color);
        draw_circle(px + 8, py, 8, false);

        // 수량
        draw_set_halign(fa_left);
        draw_set_valign(fa_middle);
        draw_set_color(c_white);
        draw_text(px + 22, py, res.name + ": " + string(floor(res.current)));

        idx++;
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

// ========================================
// 패시브 자원 생산 (건물에서 호출)
// ========================================

/// @func apply_passive_production(production_struct, delta)
/// @desc 패시브 자원 생산 적용
function apply_passive_production(production_struct, delta) {
    var types = struct_get_names(production_struct);

    for (var i = 0; i < array_length(types); i++) {
        var type = types[i];
        var rate = production_struct[$ type];
        var amount = rate * delta;

        if (amount > 0) {
            add_resource(type, amount, "패시브 생산");
        }
    }
}

// ========================================
// 자원 통계
// ========================================

/// @func get_resource_summary()
/// @desc 자원 수입/지출 요약 반환
function get_resource_summary() {
    return {
        income: global.resource_income,
        expense: global.resource_expense
    };
}

/// @func reset_resource_tracking()
/// @desc 수입/지출 추적 리셋 (웨이브 시작 시)
function reset_resource_tracking() {
    var types = struct_get_names(global.resource_income);

    for (var i = 0; i < array_length(types); i++) {
        var type = types[i];
        global.resource_income[$ type] = 0;
        global.resource_expense[$ type] = 0;
    }
}
