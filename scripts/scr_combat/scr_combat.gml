/// @file scr_combat.gml
/// @desc M1-2 기본 전투 시스템 - 데미지 계산, 적용, 사망 처리

#macro SOUL_EXPIRE_WAVES 3          // 영혼 소멸까지 웨이브 수
#macro SOUL_REVIVE_HP_PERCENT 0.5   // 부활 시 HP 비율

// ========================================
// 전역 변수 초기화
// ========================================

/// @func init_combat_system()
/// @desc 전투 시스템 전역 변수 초기화
function init_combat_system() {
    global.ally_units = [];
    global.enemy_units = [];
    global.souls_in_battle = [];
    global.sanctuary = {
        souls: [],
        max_souls: 20
    };
}

// ========================================
// 데미지 계산
// ========================================

/// @func calculate_basic_damage(attacker, target)
/// @desc M1용 기본 데미지 계산 (물리/마법 중 높은 것 사용)
/// @param {struct} attacker - 공격자 유닛
/// @param {struct} target - 대상 유닛
/// @return {struct} { damage, damage_type, is_crit }
function calculate_basic_damage(attacker, target) {
    // 1. 공격력 결정 (물리 vs 마법 중 높은 것)
    var atk_phys = attacker.physical_attack ?? 50;
    var atk_mag = attacker.magic_attack ?? 30;

    var damage_type = "physical";
    var base_attack = atk_phys;

    if (atk_mag > atk_phys) {
        damage_type = "magic";
        base_attack = atk_mag;
    }

    // 2. 방어력 적용
    var defense = 0;
    if (damage_type == "physical") {
        defense = target.physical_defense ?? 0;
    } else {
        defense = target.magic_defense ?? 0;
    }

    // 3. 데미지 공식: damage = attack * (100 / (100 + defense))
    // defense가 100이면 50% 감소, 200이면 33% 감소
    var damage_multiplier = 100 / (100 + max(defense, 0));
    var final_damage = base_attack * damage_multiplier;

    // 4. 최소 데미지 보장 (1 이상)
    final_damage = max(floor(final_damage), 1);

    // 5. M1에서는 치명타 없음 (M3에서 추가)
    var result = {
        damage: final_damage,
        damage_type: damage_type,
        is_crit: false
    };

    return result;
}

// ========================================
// 데미지 적용
// ========================================

/// @func apply_damage(target, damage_info, attacker)
/// @desc 대상에게 데미지 적용 + 사망 체크
/// @param {struct} target - 피격 대상
/// @param {struct} damage_info - calculate_basic_damage 결과
/// @param {struct} attacker - 공격자 (옵션)
/// @return {real} 실제 적용된 데미지
function apply_damage(target, damage_info, attacker = undefined) {
    if (target == undefined) return 0;
    if (target.hp <= 0) return 0;

    var damage = damage_info.damage;

    // 1. HP 감소
    var old_hp = target.hp;
    target.hp = max(0, target.hp - damage);
    var actual_damage = old_hp - target.hp;

    // 2. 데미지 숫자 표시
    create_damage_number(target.x, target.y - 20, actual_damage, damage_info.is_crit);

    // 3. 전투 로그
    var attacker_name = (attacker != undefined) ? (attacker.display_name ?? attacker.unit_id ?? "unknown") : "unknown";
    var target_name = target.display_name ?? target.unit_id ?? "unknown";
    combat_log(attacker_name + " -> " + target_name + ": " + string(actual_damage) + " 데미지");

    // 4. 사망 체크
    if (target.hp <= 0) {
        kill_unit(target);
    }

    return actual_damage;
}

/// @func combat_log(message)
/// @desc 전투 로그 출력
function combat_log(message) {
    if (variable_global_exists("debug") && variable_struct_exists(global.debug, "combat_log")) {
        array_push(global.debug.combat_log, "[전투] " + message);
        while (array_length(global.debug.combat_log) > 50) {
            array_delete(global.debug.combat_log, 0, 1);
        }
    }
    show_debug_message("[COMBAT] " + message);
}

// ========================================
// 사망 처리
// ========================================

/// @func kill_unit(unit)
/// @desc 유닛 사망 처리 + 아군인 경우 영혼 생성
/// @param {struct} unit - 사망할 유닛
function kill_unit(unit) {
    if (unit == undefined) return;
    if (unit.hp > 0) return;  // 아직 살아있음

    unit.is_alive = false;
    unit.hp = 0;

    var unit_name = unit.display_name ?? unit.unit_id ?? "unknown";
    var team = unit.team ?? "unknown";

    // 1. 전역 리스트에서 제거
    if (team == "ally") {
        var idx = array_get_index(global.ally_units, unit);
        if (idx >= 0) array_delete(global.ally_units, idx, 1);

        // ★ 아군 사망 시 영혼 생성 (소환수 제외)
        var is_summon = unit.is_summon ?? false;
        if (!is_summon) {
            create_soul_from_unit(unit);
        }
    } else if (team == "enemy") {
        var idx = array_get_index(global.enemy_units, unit);
        if (idx >= 0) array_delete(global.enemy_units, idx, 1);
    }

    // 2. 사망 로그
    combat_log("사망: " + unit_name + " (" + team + ")");

    // 3. 사망 이펙트 (M8에서 구현)
    // create_death_effect(unit.x, unit.y, team);
}

// ========================================
// 기본 공격 실행
// ========================================

/// @func execute_basic_attack(attacker, target)
/// @desc 기본 공격 수행 (사거리 체크 포함)
/// @param {struct} attacker - 공격자
/// @param {struct} target - 대상
/// @return {bool} 공격 성공 여부
function execute_basic_attack(attacker, target) {
    if (attacker == undefined || target == undefined) return false;
    if (attacker.hp <= 0 || target.hp <= 0) return false;

    // 1. 공격 쿨타임 체크
    var atk_cd = attacker.attack_cooldown ?? 0;
    if (atk_cd > 0) return false;

    // 2. 사거리 체크
    var atk_range = attacker.attack_range ?? 100;
    var dist = point_distance(attacker.x, attacker.y, target.x, target.y);

    if (dist > atk_range) {
        return false;  // 사거리 밖
    }

    // 3. 데미지 계산
    var damage_info = calculate_basic_damage(attacker, target);

    // 4. 공격 이펙트 (근접 vs 원거리)
    var is_melee = (atk_range <= 120);
    create_attack_effect(attacker, target, is_melee, damage_info.is_crit);

    // 5. 데미지 적용
    apply_damage(target, damage_info, attacker);

    // 6. 공격 쿨타임 설정
    var atk_speed = attacker.attack_speed ?? 1.0;
    attacker.attack_cooldown = 1.0 / max(atk_speed, 0.1);

    return true;
}

/// @func create_attack_effect(attacker, target, is_melee, is_crit)
/// @desc 공격 이펙트 생성
function create_attack_effect(attacker, target, is_melee, is_crit) {
    if (!variable_global_exists("debug")) return;
    if (!variable_struct_exists(global.debug, "effects")) return;

    var dir = point_direction(attacker.x, attacker.y, target.x, target.y);

    if (is_melee) {
        // 근접: 슬래시 이펙트
        array_push(global.debug.effects, {
            type: "slash",
            x: target.x,
            y: target.y,
            direction: dir,
            timer: 0,
            max_timer: 12,
            size: 60,
            is_crit: is_crit,
            color: is_crit ? c_yellow : c_white
        });
    } else {
        // 원거리: 투사체 이펙트
        array_push(global.debug.effects, {
            type: "projectile",
            x: attacker.x,
            y: attacker.y,
            target_x: target.x,
            target_y: target.y,
            speed: 15,
            trail_timer: 0,
            color: c_aqua
        });
    }
}

// ========================================
// 데미지 숫자 표시
// ========================================

/// @func create_damage_number(x, y, damage, is_crit)
/// @desc 데미지 숫자 이펙트 생성
function create_damage_number(_x, _y, damage, is_crit = false) {
    if (!variable_global_exists("debug")) return;
    if (!variable_struct_exists(global.debug, "damage_numbers")) {
        global.debug.damage_numbers = [];
    }

    var color = c_white;
    var text = string(floor(damage));

    if (is_crit) {
        color = c_yellow;
        text = string(floor(damage)) + "!";
    } else if (damage <= 0) {
        color = c_gray;
        text = "MISS";
    }

    array_push(global.debug.damage_numbers, {
        x: _x,
        y: _y,
        text: text,
        color: color,
        alpha: 1.0,
        lifetime: 45  // 0.75초
    });
}

/// @func update_damage_numbers()
/// @desc 데미지 숫자 업데이트 (Step에서 호출)
function update_damage_numbers() {
    if (!variable_global_exists("debug")) return;
    if (!variable_struct_exists(global.debug, "damage_numbers")) return;

    for (var i = array_length(global.debug.damage_numbers) - 1; i >= 0; i--) {
        var num = global.debug.damage_numbers[i];
        num.y -= 1;  // 위로 떠오름
        num.lifetime--;

        if (num.lifetime < 15) {
            num.alpha = num.lifetime / 15;
        }

        if (num.lifetime <= 0) {
            array_delete(global.debug.damage_numbers, i, 1);
        }
    }
}

/// @func draw_damage_numbers()
/// @desc 데미지 숫자 그리기 (Draw에서 호출)
function draw_damage_numbers() {
    if (!variable_global_exists("debug")) return;
    if (!variable_struct_exists(global.debug, "damage_numbers")) return;

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    for (var i = 0; i < array_length(global.debug.damage_numbers); i++) {
        var num = global.debug.damage_numbers[i];
        draw_set_color(num.color);
        draw_set_alpha(num.alpha);
        draw_text(num.x, num.y, num.text);
    }

    draw_set_alpha(1);
    draw_set_color(c_white);
}

// ========================================
// 쿨타임 업데이트
// ========================================

/// @func update_attack_cooldowns(delta)
/// @desc 모든 유닛의 공격 쿨타임 감소
/// @param {real} delta - 프레임 시간 (초)
function update_attack_cooldowns(delta) {
    // 아군
    for (var i = 0; i < array_length(global.ally_units); i++) {
        var unit = global.ally_units[i];
        if (unit.attack_cooldown > 0) {
            unit.attack_cooldown = max(0, unit.attack_cooldown - delta);
        }
    }

    // 적군
    for (var i = 0; i < array_length(global.enemy_units); i++) {
        var unit = global.enemy_units[i];
        if (unit.attack_cooldown > 0) {
            unit.attack_cooldown = max(0, unit.attack_cooldown - delta);
        }
    }
}


// ========================================
// M1-5: 성문 시스템
// ========================================

/// @func init_gate()
/// @desc 성문 초기화
function init_gate() {
    global.gate = {
        x: 640,
        y: 600,
        
        hp: 1000,
        max_hp: 1000,
        defense: 50,
        
        is_gate: true,
        is_alive: true,
        
        // M6에서 확장
        level: 1,
        repair_cost: { gold: 100 }
    };
    
    return global.gate;
}

/// @func get_gate_hp_percent()
/// @desc 성문 HP 퍼센트 반환
function get_gate_hp_percent() {
    if (!variable_global_exists("gate")) return 0;
    if (global.gate.max_hp <= 0) return 0;
    return (global.gate.hp / global.gate.max_hp) * 100;
}

/// @func is_gate_destroyed()
/// @desc 성문 파괴 여부
function is_gate_destroyed() {
    if (!variable_global_exists("gate")) return true;
    return global.gate.hp <= 0;
}

/// @func repair_gate(amount)
/// @desc 성문 수리
function repair_gate(amount) {
    if (!variable_global_exists("gate")) return;
    
    global.gate.hp = min(global.gate.hp + amount, global.gate.max_hp);
    combat_log("성문 수리: +" + string(amount) + " HP");
}

/// @func draw_gate()
/// @desc 성문 그리기 (디버그용)
function draw_gate() {
    if (!variable_global_exists("gate")) return;
    
    var gate = global.gate;
    
    // 성문 본체
    var gate_color = (gate.hp > gate.max_hp * 0.3) ? c_gray : c_maroon;
    draw_set_color(gate_color);
    draw_rectangle(gate.x - 60, gate.y - 40, gate.x + 60, gate.y + 40, false);
    
    // 테두리
    draw_set_color(c_white);
    draw_rectangle(gate.x - 60, gate.y - 40, gate.x + 60, gate.y + 40, true);
    
    // HP 바
    var hp_ratio = gate.hp / gate.max_hp;
    var bar_width = 100;
    var bar_x = gate.x - bar_width / 2;
    var bar_y = gate.y - 55;
    
    // 배경
    draw_set_color(c_dkgray);
    draw_rectangle(bar_x, bar_y, bar_x + bar_width, bar_y + 8, false);
    
    // HP
    var hp_color = (hp_ratio > 0.5) ? c_green : ((hp_ratio > 0.25) ? c_yellow : c_red);
    draw_set_color(hp_color);
    draw_rectangle(bar_x, bar_y, bar_x + bar_width * hp_ratio, bar_y + 8, false);
    
    // 텍스트
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    draw_set_color(c_white);
    draw_text(gate.x, bar_y - 2, "성문 " + string(floor(gate.hp)) + "/" + string(gate.max_hp));
    
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

// ========================================
// M3-2: 타겟팅 우선순위 시스템
// ========================================

/// @func find_target_by_priority(unit, priority_type)
/// @desc 우선순위에 따라 타겟 찾기
function find_target_by_priority(unit, priority_type) {
    var enemy_team = (unit.team == "ally") ? "enemy" : "ally";
    var candidates = get_alive_units_by_team(enemy_team);

    if (array_length(candidates) == 0) return undefined;

    switch (priority_type) {
        case "nearest":
            return find_nearest_unit(unit, candidates);

        case "lowest_hp":
            return find_lowest_hp_unit(candidates);

        case "lowest_hp_percent":
            return find_lowest_hp_percent_unit(candidates);

        case "highest_threat":
            return find_highest_threat_unit(unit, candidates);

        case "healer_first":
            return find_unit_by_role(candidates, "healer") ?? find_nearest_unit(unit, candidates);

        case "backline":
            return find_backline_unit(candidates) ?? find_nearest_unit(unit, candidates);

        case "random":
            return candidates[irandom(array_length(candidates) - 1)];

        default:
            return find_nearest_unit(unit, candidates);
    }
}

/// @func get_alive_units_by_team(team)
function get_alive_units_by_team(team) {
    var result = [];
    var units;

    if (team == "ally") {
        units = variable_global_exists("ally_units") ? global.ally_units : [];
    } else {
        units = variable_global_exists("enemy_units") ? global.enemy_units : [];
    }

    for (var i = 0; i < array_length(units); i++) {
        if (units[i].hp > 0) {
            array_push(result, units[i]);
        }
    }

    return result;
}

/// @func find_nearest_unit(from_unit, candidates)
function find_nearest_unit(from_unit, candidates) {
    var nearest = undefined;
    var nearest_dist = infinity;

    for (var i = 0; i < array_length(candidates); i++) {
        var candidate = candidates[i];
        if (candidate.hp <= 0) continue;

        var dist = point_distance(from_unit.x, from_unit.y, candidate.x, candidate.y);
        if (dist < nearest_dist) {
            nearest_dist = dist;
            nearest = candidate;
        }
    }

    return nearest;
}

/// @func find_lowest_hp_unit(candidates)
function find_lowest_hp_unit(candidates) {
    var lowest = undefined;
    var lowest_hp = infinity;

    for (var i = 0; i < array_length(candidates); i++) {
        var u = candidates[i];
        if (u.hp <= 0) continue;

        if (u.hp < lowest_hp) {
            lowest_hp = u.hp;
            lowest = u;
        }
    }

    return lowest;
}

/// @func find_lowest_hp_percent_unit(candidates)
function find_lowest_hp_percent_unit(candidates) {
    var lowest = undefined;
    var lowest_percent = infinity;

    for (var i = 0; i < array_length(candidates); i++) {
        var u = candidates[i];
        if (u.hp <= 0) continue;

        var percent = u.hp / u.max_hp;
        if (percent < lowest_percent) {
            lowest_percent = percent;
            lowest = u;
        }
    }

    return lowest;
}

/// @func find_highest_threat_unit(from_unit, candidates)
/// @desc 위협도 = 공격력 / 거리
function find_highest_threat_unit(from_unit, candidates) {
    var highest = undefined;
    var highest_threat = -infinity;

    for (var i = 0; i < array_length(candidates); i++) {
        var u = candidates[i];
        if (u.hp <= 0) continue;

        var dist = max(point_distance(from_unit.x, from_unit.y, u.x, u.y), 1);
        var attack_power = max(u.physical_attack ?? 0, u.magic_attack ?? 0);
        var threat = attack_power / dist;

        if (threat > highest_threat) {
            highest_threat = threat;
            highest = u;
        }
    }

    return highest;
}

/// @func find_unit_by_role(candidates, role)
function find_unit_by_role(candidates, role) {
    for (var i = 0; i < array_length(candidates); i++) {
        var u = candidates[i];
        if (u.hp <= 0) continue;

        var unit_role = u.role ?? u.ai_type ?? "";
        if (unit_role == role) {
            return u;
        }
    }
    return undefined;
}

/// @func find_backline_unit(candidates)
/// @desc 가장 뒤에 있는 유닛 (y좌표 기준)
function find_backline_unit(candidates) {
    var backline = undefined;
    var backline_y = infinity;  // 가장 작은 y = 가장 뒤

    for (var i = 0; i < array_length(candidates); i++) {
        var u = candidates[i];
        if (u.hp <= 0) continue;

        if (u.y < backline_y) {
            backline_y = u.y;
            backline = u;
        }
    }

    return backline;
}

/// @func find_allies_in_range(unit, range)
/// @desc 범위 내 아군 찾기
function find_allies_in_range(unit, range) {
    var result = [];
    var allies = variable_global_exists("ally_units") ? global.ally_units : [];

    if (unit.team == "enemy") {
        allies = variable_global_exists("enemy_units") ? global.enemy_units : [];
    }

    for (var i = 0; i < array_length(allies); i++) {
        var ally = allies[i];
        if (ally.hp <= 0 || ally == unit) continue;

        var dist = point_distance(unit.x, unit.y, ally.x, ally.y);
        if (dist <= range) {
            array_push(result, ally);
        }
    }

    return result;
}

/// @func find_ally_lowest_hp_percent(unit, range)
/// @desc 범위 내 가장 체력 비율이 낮은 아군
function find_ally_lowest_hp_percent(unit, range) {
    var allies = find_allies_in_range(unit, range);
    if (array_length(allies) == 0) return undefined;

    var lowest = undefined;
    var lowest_percent = infinity;

    for (var i = 0; i < array_length(allies); i++) {
        var ally = allies[i];
        var percent = ally.hp / ally.max_hp;
        if (percent < lowest_percent) {
            lowest_percent = percent;
            lowest = ally;
        }
    }

    return lowest;
}

/// @func is_valid_target(target)
function is_valid_target(target) {
    if (target == undefined) return false;
    if (target.hp <= 0) return false;
    return true;
}
