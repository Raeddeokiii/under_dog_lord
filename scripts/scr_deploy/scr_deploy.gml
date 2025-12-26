/// @file scr_deploy.gml
/// @desc M2-2 배치 시스템 - 9슬롯 배치

// ========================================
// 9슬롯 구조
// ========================================
//
//              [북쪽 - 적 스폰]
//                    ↓
//    ┌─────────────────────────────────┐
//    │    WL          WC          WR   │  ← 성벽 (Wall)
//    ├─────────────────────────────────┤
//    │    BL          BC          BR   │  ← 후열 (Back)
//    ├─────────────────────────────────┤
//    │    FL          FC          FR   │  ← 전열 (Front)
//    └─────────────────────────────────┘
//                    ↑
//              [성문 위치]
//

/// @func init_deploy_system()
/// @desc 배치 시스템 초기화
function init_deploy_system() {
    // 슬롯 좌표 정의
    global.deploy_slots = {
        // 전열 (Front) - 성문에 가장 가까움
        "FL": { x: room_width * 0.25, y: room_height * 0.65, row: "front", col: "left" },
        "FC": { x: room_width * 0.50, y: room_height * 0.65, row: "front", col: "center" },
        "FR": { x: room_width * 0.75, y: room_height * 0.65, row: "front", col: "right" },

        // 후열 (Back)
        "BL": { x: room_width * 0.25, y: room_height * 0.50, row: "back", col: "left" },
        "BC": { x: room_width * 0.50, y: room_height * 0.50, row: "back", col: "center" },
        "BR": { x: room_width * 0.75, y: room_height * 0.50, row: "back", col: "right" },

        // 성벽 (Wall) - 가장 뒤
        "WL": { x: room_width * 0.25, y: room_height * 0.35, row: "wall", col: "left" },
        "WC": { x: room_width * 0.50, y: room_height * 0.35, row: "wall", col: "center" },
        "WR": { x: room_width * 0.75, y: room_height * 0.35, row: "wall", col: "right" }
    };

    // 슬롯별 배치된 유닛
    global.slot_units = {
        "FL": undefined, "FC": undefined, "FR": undefined,
        "BL": undefined, "BC": undefined, "BR": undefined,
        "WL": undefined, "WC": undefined, "WR": undefined
    };

    // 슬롯 순서 (우선순위)
    global.slot_order = ["FL", "FC", "FR", "BL", "BC", "BR", "WL", "WC", "WR"];

    // 역할별 권장 슬롯
    global.role_preferred_slots = {
        "tank": ["FL", "FC", "FR"],
        "warrior": ["FL", "FC", "FR", "BL", "BC", "BR"],
        "assassin": ["FL", "FR"],
        "ranger": ["BL", "BC", "BR", "WL", "WC", "WR"],
        "mage": ["BL", "BC", "BR", "WL", "WC", "WR"],
        "healer": ["WL", "WC", "WR", "BL", "BC", "BR"],
        "support": ["BC", "WC", "BL", "BR"]
    };
}

// ========================================
// 유닛 배치
// ========================================

/// @func deploy_unit_to_slot(unit, slot_id)
/// @desc 유닛을 특정 슬롯에 배치
function deploy_unit_to_slot(unit, slot_id) {
    if (!variable_global_exists("deploy_slots")) {
        init_deploy_system();
    }

    // 슬롯 유효성 체크
    if (!variable_struct_exists(global.deploy_slots, slot_id)) {
        combat_log("잘못된 슬롯: " + slot_id);
        return false;
    }

    // 슬롯 이미 사용 중이면 실패
    if (global.slot_units[$ slot_id] != undefined) {
        combat_log("슬롯 " + slot_id + " 이미 사용 중");
        return false;
    }

    // 유닛이 다른 슬롯에 있으면 제거
    remove_unit_from_slot(unit);

    // 슬롯 정보
    var slot = global.deploy_slots[$ slot_id];

    // 유닛 배치
    unit.x = slot.x;
    unit.y = slot.y;
    unit.deploy_slot = slot_id;

    // 슬롯에 유닛 등록
    global.slot_units[$ slot_id] = unit;

    combat_log((unit.display_name ?? "유닛") + " → " + slot_id + " 배치");

    return true;
}

/// @func remove_unit_from_slot(unit)
/// @desc 유닛을 현재 슬롯에서 제거
function remove_unit_from_slot(unit) {
    if (!variable_struct_exists(unit, "deploy_slot")) return;

    var old_slot = unit.deploy_slot;
    if (old_slot != undefined && variable_struct_exists(global.slot_units, old_slot)) {
        if (global.slot_units[$ old_slot] == unit) {
            global.slot_units[$ old_slot] = undefined;
        }
    }

    unit.deploy_slot = undefined;
}

/// @func get_empty_slot()
/// @desc 비어있는 첫 번째 슬롯 반환
function get_empty_slot() {
    for (var i = 0; i < array_length(global.slot_order); i++) {
        var slot_id = global.slot_order[i];
        if (global.slot_units[$ slot_id] == undefined) {
            return slot_id;
        }
    }
    return undefined;
}

/// @func get_best_slot_for_role(role)
/// @desc 역할에 맞는 빈 슬롯 반환
function get_best_slot_for_role(role) {
    var preferred = global.role_preferred_slots[$ role];
    if (preferred == undefined) {
        preferred = global.slot_order;
    }

    // 권장 슬롯 중 빈 곳 찾기
    for (var i = 0; i < array_length(preferred); i++) {
        var slot_id = preferred[i];
        if (global.slot_units[$ slot_id] == undefined) {
            return slot_id;
        }
    }

    // 없으면 아무 빈 슬롯
    return get_empty_slot();
}

/// @func auto_deploy_unit(unit)
/// @desc 역할에 맞게 자동 배치
function auto_deploy_unit(unit) {
    var role = unit.ai_type ?? unit.role ?? "warrior";
    var slot = get_best_slot_for_role(role);

    if (slot != undefined) {
        return deploy_unit_to_slot(unit, slot);
    }

    combat_log("배치 가능한 슬롯 없음");
    return false;
}

// ========================================
// 아군 유닛 생성
// ========================================

/// @func create_ally_unit(unit_id, x, y, level)
/// @desc 아군 유닛 struct 생성
function create_ally_unit(unit_id, _x, _y, level) {
    var base = get_ally_base_stats(unit_id);

    var ally = {
        // 식별
        unit_id: unit_id,
        display_name: base.name,
        team: "ally",

        // 위치
        x: _x,
        y: _y,
        facing: 1,
        deploy_slot: undefined,

        // 스탯
        level: level,
        hp: base.hp * (1 + (level - 1) * 0.1),
        max_hp: base.hp * (1 + (level - 1) * 0.1),
        physical_attack: base.atk * (1 + (level - 1) * 0.1),
        physical_defense: base.def * (1 + (level - 1) * 0.05),
        magic_attack: base.matk ?? 0,
        magic_defense: base.mdef ?? 0,
        attack_range: base.range ?? 80,
        attack_speed: base.aspd ?? 1.0,
        movement_speed: base.mspd ?? 60,

        // 상태
        is_alive: true,
        is_boss: false,
        is_summon: false,

        // 역할
        ai_type: base.role ?? "warrior",
        role: base.role ?? "warrior",

        // AI
        ai_state: "idle",
        ai_target: undefined,
        attack_timer: 0,
        attack_cooldown: 0
    };

    // 전역 아군 목록에 추가
    if (!variable_global_exists("ally_units")) {
        global.ally_units = [];
    }
    array_push(global.ally_units, ally);

    return ally;
}

/// @func get_ally_base_stats(unit_id)
function get_ally_base_stats(unit_id) {
    switch (unit_id) {
        case "warrior":
            return { name: "전사", hp: 150, atk: 25, def: 15, range: 60, aspd: 1.0, mspd: 70, role: "warrior" };
        case "knight":
            return { name: "기사", hp: 250, atk: 20, def: 30, range: 50, aspd: 0.8, mspd: 50, role: "tank" };
        case "archer":
            return { name: "궁수", hp: 80, atk: 30, def: 5, range: 250, aspd: 1.2, mspd: 80, role: "ranger" };
        case "fire_mage":
            return { name: "화염 마법사", hp: 70, atk: 5, def: 5, matk: 45, mdef: 15, range: 200, aspd: 0.7, mspd: 60, role: "mage" };
        case "priest":
            return { name: "사제", hp: 90, atk: 10, def: 8, matk: 20, mdef: 20, range: 150, aspd: 0.8, mspd: 60, role: "healer" };
        case "assassin":
            return { name: "암살자", hp: 100, atk: 40, def: 8, range: 50, aspd: 1.5, mspd: 100, role: "assassin" };
        default:
            return { name: "병사", hp: 100, atk: 20, def: 10, range: 60, aspd: 1.0, mspd: 70, role: "warrior" };
    }
}

/// @func spawn_starting_allies()
/// @desc 시작 아군 배치 (테스트용)
function spawn_starting_allies() {
    // 전열: 탱커
    var knight = create_ally_unit("knight", 0, 0, 1);
    deploy_unit_to_slot(knight, "FC");

    // 전열 양쪽: 전사
    var warrior1 = create_ally_unit("warrior", 0, 0, 1);
    deploy_unit_to_slot(warrior1, "FL");

    var warrior2 = create_ally_unit("warrior", 0, 0, 1);
    deploy_unit_to_slot(warrior2, "FR");

    // 후열: 궁수
    var archer = create_ally_unit("archer", 0, 0, 1);
    deploy_unit_to_slot(archer, "BC");

    // 성벽: 마법사
    var mage = create_ally_unit("fire_mage", 0, 0, 1);
    deploy_unit_to_slot(mage, "WC");

    combat_log("시작 아군 5명 배치 완료");
}

// ========================================
// 슬롯 UI 그리기
// ========================================

/// @func draw_deploy_slots()
/// @desc 배치 슬롯 시각화
function draw_deploy_slots() {
    if (!variable_global_exists("deploy_slots")) return;

    var slot_names = struct_get_names(global.deploy_slots);

    for (var i = 0; i < array_length(slot_names); i++) {
        var slot_id = slot_names[i];
        var slot = global.deploy_slots[$ slot_id];
        var unit = global.slot_units[$ slot_id];

        // 슬롯 영역
        var size = 40;
        var x1 = slot.x - size;
        var y1 = slot.y - size;
        var x2 = slot.x + size;
        var y2 = slot.y + size;

        // 색상 (비어있으면 회색, 있으면 초록)
        if (unit != undefined && unit.hp > 0) {
            draw_set_color(c_green);
            draw_set_alpha(0.3);
            draw_rectangle(x1, y1, x2, y2, false);
            draw_set_alpha(1);
            draw_set_color(c_lime);
        } else {
            draw_set_color(c_dkgray);
            draw_set_alpha(0.2);
            draw_rectangle(x1, y1, x2, y2, false);
            draw_set_alpha(1);
            draw_set_color(c_gray);
        }

        // 테두리
        draw_rectangle(x1, y1, x2, y2, true);

        // 슬롯 이름
        draw_set_halign(fa_center);
        draw_set_valign(fa_bottom);
        draw_set_color(c_white);
        draw_text(slot.x, y1 - 2, slot_id);
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

// ========================================
// 유닛 그리기
// ========================================

/// @func draw_all_units()
/// @desc 모든 유닛 그리기 (간단 버전)
function draw_all_units() {
    // 아군
    if (variable_global_exists("ally_units")) {
        for (var i = 0; i < array_length(global.ally_units); i++) {
            var unit = global.ally_units[i];
            if (unit.hp > 0) {
                draw_unit(unit, c_blue);
            }
        }
    }

    // 적군
    if (variable_global_exists("enemy_units")) {
        for (var i = 0; i < array_length(global.enemy_units); i++) {
            var unit = global.enemy_units[i];
            if (unit.hp > 0) {
                draw_unit(unit, c_red);
            }
        }
    }
}

/// @func draw_unit(unit, color)
function draw_unit(unit, color) {
    var size = unit.is_boss ? 25 : 15;

    // 본체
    draw_set_color(color);
    draw_circle(unit.x, unit.y, size, false);

    // 테두리
    draw_set_color(c_white);
    draw_circle(unit.x, unit.y, size, true);

    // HP 바
    var bar_width = size * 2;
    var bar_height = 4;
    var bar_x = unit.x - bar_width / 2;
    var bar_y = unit.y - size - 8;

    var hp_ratio = unit.hp / unit.max_hp;

    draw_set_color(c_dkgray);
    draw_rectangle(bar_x, bar_y, bar_x + bar_width, bar_y + bar_height, false);

    var hp_color = (hp_ratio > 0.5) ? c_lime : ((hp_ratio > 0.25) ? c_yellow : c_red);
    draw_set_color(hp_color);
    draw_rectangle(bar_x, bar_y, bar_x + bar_width * hp_ratio, bar_y + bar_height, false);

    // 이름
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    draw_set_color(c_white);
    draw_text(unit.x, bar_y - 2, unit.display_name ?? "?");

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
