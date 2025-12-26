/// @file scr_soul.gml
/// @desc 영혼 & 성소 시스템 - 사망 시 영혼 생성, 부활 관리

// ========================================
// 영혼 생성
// ========================================

/// @func create_soul_from_unit(unit)
/// @desc 사망한 유닛으로부터 영혼 생성
/// @param {struct} unit - 사망한 유닛
/// @return {struct} 생성된 영혼
function create_soul_from_unit(unit) {
    var soul = {
        // 식별
        id: "soul_" + string(irandom(99999)),
        source_unit_id: unit.unit_id ?? "unknown",

        // 원본 유닛 정보 (부활 시 복원용)
        unit_template_id: unit.template_id ?? unit.unit_id ?? "unknown",
        unit_level: unit.level ?? 1,
        unit_experience: unit.experience ?? 0,
        unit_display_name: unit.display_name ?? "알 수 없음",
        garrison_building_id: unit.garrison_building_id ?? undefined,

        // 영혼 상태
        state: "floating",  // floating, collected, reviving, expired

        // 위치
        x: unit.x ?? 0,
        y: unit.y ?? 0,
        start_y: unit.y ?? 0,

        // 시각 효과
        alpha: 1.0,
        scale: 1.0,
        float_offset: 0,
        tint: c_white,

        // 소멸 타이머
        waves_remaining: SOUL_EXPIRE_WAVES,

        // 부활 비용
        revival_cost: calculate_revival_cost(unit),

        // 시간
        created_at: current_time
    };

    // 전장 영혼 목록에 추가
    if (!variable_global_exists("souls_in_battle")) {
        global.souls_in_battle = [];
    }
    array_push(global.souls_in_battle, soul);

    // 로그
    combat_log("영혼 생성: " + soul.unit_display_name);

    return soul;
}

/// @func calculate_revival_cost(unit)
/// @desc 유닛의 부활 비용 계산
/// @param {struct} unit - 유닛
/// @return {struct} { gold, soul_stone }
function calculate_revival_cost(unit) {
    var level = unit.level ?? 1;
    var tier = unit.tier ?? "common";

    var base_cost = {
        gold: 50,
        soul_stone: 0
    };

    // 레벨 보정 (레벨당 +20 골드)
    base_cost.gold += level * 20;

    // 등급 보정
    switch (tier) {
        case "common":
            break;
        case "uncommon":
            base_cost.gold = floor(base_cost.gold * 1.5);
            break;
        case "rare":
            base_cost.gold = floor(base_cost.gold * 2);
            base_cost.soul_stone = 1;
            break;
        case "epic":
            base_cost.gold = floor(base_cost.gold * 3);
            base_cost.soul_stone = 3;
            break;
        case "legendary":
            base_cost.gold = floor(base_cost.gold * 5);
            base_cost.soul_stone = 5;
            break;
    }

    // 영웅 유닛
    var is_hero = unit.is_hero ?? false;
    if (is_hero) {
        base_cost.gold = floor(base_cost.gold * 3);
        base_cost.soul_stone = floor(base_cost.soul_stone * 2);
    }

    return base_cost;
}

// ========================================
// 영혼 업데이트 (시각 효과)
// ========================================

/// @func update_souls_visual(delta)
/// @desc 전장 영혼들의 시각 효과 업데이트
/// @param {real} delta - 프레임 시간
function update_souls_visual(delta) {
    if (!variable_global_exists("souls_in_battle")) return;

    for (var i = 0; i < array_length(global.souls_in_battle); i++) {
        var soul = global.souls_in_battle[i];

        if (soul.state != "floating") continue;

        // 둥둥 떠다니는 효과
        soul.float_offset += delta * 2;
        soul.y = soul.start_y - 20 + sin(soul.float_offset) * 10;

        // 반투명 깜빡임
        soul.alpha = 0.6 + sin(soul.float_offset * 1.5) * 0.3;
    }
}

/// @func draw_souls()
/// @desc 전장 영혼 그리기
function draw_souls() {
    if (!variable_global_exists("souls_in_battle")) return;

    for (var i = 0; i < array_length(global.souls_in_battle); i++) {
        var soul = global.souls_in_battle[i];

        if (soul.state != "floating") continue;

        // 영혼 그리기 (간단한 원형)
        draw_set_alpha(soul.alpha);
        draw_set_color(c_aqua);
        draw_circle(soul.x, soul.y, 15 * soul.scale, false);

        // 테두리
        draw_set_color(c_white);
        draw_circle(soul.x, soul.y, 15 * soul.scale, true);

        // 이름 표시
        draw_set_halign(fa_center);
        draw_set_valign(fa_bottom);
        draw_set_color(c_white);
        draw_text(soul.x, soul.y - 25, soul.unit_display_name);

        draw_set_alpha(1);
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

// ========================================
// 웨이브 종료 시 영혼 수집
// ========================================

/// @func collect_souls_to_sanctuary()
/// @desc 웨이브 종료 시 전장의 모든 영혼을 성소로 수집
/// @return {real} 수집된 영혼 수
function collect_souls_to_sanctuary() {
    if (!variable_global_exists("souls_in_battle")) return 0;
    if (!variable_global_exists("sanctuary")) {
        global.sanctuary = { souls: [], max_souls: 20 };
    }

    var collected_count = 0;

    for (var i = 0; i < array_length(global.souls_in_battle); i++) {
        var soul = global.souls_in_battle[i];

        if (soul.state != "floating") continue;

        // 성소 수용량 확인
        if (array_length(global.sanctuary.souls) >= global.sanctuary.max_souls) {
            combat_log("성소가 가득 찼습니다! " + soul.unit_display_name + " 영혼 소멸");
            soul.state = "expired";
            continue;
        }

        // 영혼 상태 변경
        soul.state = "collected";
        soul.collected_at = current_time;

        // 성소에 추가
        array_push(global.sanctuary.souls, soul);
        collected_count++;
    }

    // 전장 영혼 목록 초기화
    global.souls_in_battle = [];

    if (collected_count > 0) {
        combat_log(string(collected_count) + "개의 영혼이 성소에 수집되었습니다.");
    }

    return collected_count;
}

// ========================================
// 부활 시스템
// ========================================

/// @func can_afford_revival(soul)
/// @desc 부활 비용 지불 가능 여부
/// @param {struct} soul - 영혼
/// @return {bool}
function can_afford_revival(soul) {
    if (!variable_global_exists("resources")) return false;

    var cost = soul.revival_cost;
    var gold = global.resources.gold ?? 0;
    var soul_stone = global.resources.soul_stone ?? 0;

    return (gold >= cost.gold && soul_stone >= cost.soul_stone);
}

/// @func revive_soul(soul)
/// @desc 영혼 부활
/// @param {struct} soul - 부활할 영혼
/// @return {struct|undefined} 부활된 유닛 또는 undefined
function revive_soul(soul) {
    if (!can_afford_revival(soul)) {
        combat_log("부활 비용이 부족합니다.");
        return undefined;
    }

    // 비용 차감
    global.resources.gold -= soul.revival_cost.gold;
    global.resources.soul_stone -= soul.revival_cost.soul_stone;

    // 영혼 상태 변경
    soul.state = "reviving";

    // 유닛 복원 (M4에서 완전 구현)
    var revived_unit = {
        unit_id: soul.source_unit_id,
        template_id: soul.unit_template_id,
        display_name: soul.unit_display_name,
        level: soul.unit_level,
        experience: soul.unit_experience,
        hp: 100,  // 임시 - 실제로는 max_hp * 0.5
        is_alive: true,
        team: "ally",
        x: 400,
        y: 400
    };

    // 성소에서 영혼 제거
    remove_soul_from_sanctuary(soul);

    combat_log(soul.unit_display_name + " 부활!");

    return revived_unit;
}

/// @func remove_soul_from_sanctuary(soul)
/// @desc 성소에서 영혼 제거
function remove_soul_from_sanctuary(soul) {
    if (!variable_global_exists("sanctuary")) return;

    for (var i = array_length(global.sanctuary.souls) - 1; i >= 0; i--) {
        if (global.sanctuary.souls[i].id == soul.id) {
            array_delete(global.sanctuary.souls, i, 1);
            break;
        }
    }
}

// ========================================
// 영혼 소멸 타이머
// ========================================

/// @func update_soul_timers()
/// @desc 웨이브 시작 시 영혼 소멸 타이머 업데이트
function update_soul_timers() {
    if (!variable_global_exists("sanctuary")) return;

    for (var i = array_length(global.sanctuary.souls) - 1; i >= 0; i--) {
        var soul = global.sanctuary.souls[i];

        // 타이머 감소
        soul.waves_remaining--;

        // 소멸 확인
        if (soul.waves_remaining <= 0) {
            expire_soul(soul);
            array_delete(global.sanctuary.souls, i, 1);
        } else if (soul.waves_remaining == 1) {
            // 경고
            combat_log(soul.unit_display_name + "의 영혼이 곧 소멸합니다!");
        }
    }
}

/// @func expire_soul(soul)
/// @desc 영혼 영구 소멸 처리
function expire_soul(soul) {
    soul.state = "expired";
    combat_log(soul.unit_display_name + "의 영혼이 소멸했습니다...");
}

// ========================================
// 성소 UI (간단 버전)
// ========================================

/// @func draw_sanctuary_ui(x, y)
/// @desc 성소 UI 그리기 (디버그용)
function draw_sanctuary_ui(_x, _y) {
    if (!variable_global_exists("sanctuary")) return;

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);

    draw_text(_x, _y, "=== 성소 ===");
    draw_text(_x, _y + 20, "영혼: " + string(array_length(global.sanctuary.souls)) + " / " + string(global.sanctuary.max_souls));

    var y_offset = 50;
    for (var i = 0; i < array_length(global.sanctuary.souls); i++) {
        var soul = global.sanctuary.souls[i];

        var soul_color = (soul.waves_remaining <= 1) ? c_red : c_aqua;
        draw_set_color(soul_color);

        var info = soul.unit_display_name + " Lv." + string(soul.unit_level);
        info += " (소멸: " + string(soul.waves_remaining) + "웨이브)";
        info += " [" + string(soul.revival_cost.gold) + "G]";

        draw_text(_x, _y + y_offset, info);
        y_offset += 20;
    }

    draw_set_color(c_white);
}
