/// @file scr_skill.gml
/// @desc M3-1 스킬/이펙트 시스템

// ========================================
// 스킬 템플릿 초기화
// ========================================

/// @func init_skill_templates()
/// @desc 스킬 템플릿 데이터 초기화
function init_skill_templates() {
    global.skill_templates = {};

    // ========================================
    // 공격 스킬
    // ========================================

    // 파이어볼 (마법사)
    global.skill_templates[$ "fireball"] = {
        id: "fireball",
        name: "파이어볼",
        description: "화염 구체를 발사하여 마법 피해를 입힙니다.",

        mana_cost: 20,
        cooldown: 3,

        target_type: "enemy",
        range: 400,

        effects: [
            {
                type: "damage",
                damage_type: "magic",
                element: "fire",
                base_damage: 100,
                scaling: { stat: "magic_attack", ratio: 1.5 }
            }
        ]
    };

    // 화염 폭발 (마법사 - AOE)
    global.skill_templates[$ "flame_burst"] = {
        id: "flame_burst",
        name: "화염 폭발",
        description: "대상 주변에 화염을 폭발시킵니다.",

        mana_cost: 40,
        cooldown: 8,

        target_type: "enemy",
        range: 350,
        aoe_radius: 120,

        effects: [
            {
                type: "damage",
                damage_type: "magic",
                element: "fire",
                base_damage: 80,
                scaling: { stat: "magic_attack", ratio: 1.2 }
            },
            {
                type: "dot",
                damage_type: "magic",
                element: "fire",
                tick_damage: 20,
                duration: 3,
                tick_interval: 1
            }
        ]
    };

    // 파워 스트라이크 (전사)
    global.skill_templates[$ "power_strike"] = {
        id: "power_strike",
        name: "강타",
        description: "강력한 일격으로 물리 피해를 입힙니다.",

        mana_cost: 15,
        cooldown: 4,

        target_type: "enemy",
        range: 80,

        effects: [
            {
                type: "damage",
                damage_type: "physical",
                base_damage: 50,
                scaling: { stat: "physical_attack", ratio: 2.0 }
            }
        ]
    };

    // 암살 (암살자)
    global.skill_templates[$ "assassinate"] = {
        id: "assassinate",
        name: "암살",
        description: "치명적인 공격. HP가 낮은 적에게 추가 피해.",

        mana_cost: 25,
        cooldown: 6,

        target_type: "enemy",
        target_priority: "lowest_hp_percent",
        range: 60,

        effects: [
            {
                type: "damage",
                damage_type: "physical",
                base_damage: 80,
                scaling: { stat: "physical_attack", ratio: 2.5 },
                execute_threshold: 0.3,  // HP 30% 이하 시 2배 피해
                execute_multiplier: 2.0
            }
        ]
    };

    // 멀티샷 (궁수)
    global.skill_templates[$ "multishot"] = {
        id: "multishot",
        name: "멀티샷",
        description: "3명의 적에게 화살을 발사합니다.",

        mana_cost: 20,
        cooldown: 5,

        target_type: "enemy",
        target_count: 3,
        range: 300,

        effects: [
            {
                type: "damage",
                damage_type: "physical",
                base_damage: 40,
                scaling: { stat: "physical_attack", ratio: 0.8 }
            }
        ]
    };

    // ========================================
    // 힐 스킬
    // ========================================

    // 치유 (사제)
    global.skill_templates[$ "heal"] = {
        id: "heal",
        name: "치유",
        description: "아군 하나의 HP를 회복합니다.",

        mana_cost: 30,
        cooldown: 5,

        target_type: "ally",
        target_priority: "lowest_hp_percent",
        range: 350,

        effects: [
            {
                type: "heal",
                base_heal: 80,
                scaling: { stat: "magic_attack", ratio: 1.5 }
            }
        ]
    };

    // 재생 (사제 - HOT)
    global.skill_templates[$ "regeneration"] = {
        id: "regeneration",
        name: "재생",
        description: "지속적으로 HP를 회복합니다.",

        mana_cost: 25,
        cooldown: 8,

        target_type: "ally",
        target_priority: "lowest_hp_percent",
        range: 300,

        effects: [
            {
                type: "hot",
                tick_heal: 25,
                duration: 6,
                tick_interval: 1,
                scaling: { stat: "magic_attack", ratio: 0.3 }
            }
        ]
    };

    // 집단 치유 (사제 - AOE)
    global.skill_templates[$ "mass_heal"] = {
        id: "mass_heal",
        name: "집단 치유",
        description: "주변 아군 전체를 치유합니다.",

        mana_cost: 60,
        cooldown: 15,

        target_type: "ally",
        target_self: true,
        aoe_radius: 200,

        effects: [
            {
                type: "heal",
                base_heal: 50,
                scaling: { stat: "magic_attack", ratio: 1.0 }
            }
        ]
    };

    // ========================================
    // 버프/디버프 스킬
    // ========================================

    // 도발 (탱커)
    global.skill_templates[$ "taunt"] = {
        id: "taunt",
        name: "도발",
        description: "주변 적들이 자신을 공격하도록 유도합니다.",

        mana_cost: 20,
        cooldown: 10,

        target_type: "self",
        aoe_radius: 200,
        aoe_target: "enemy",

        effects: [
            {
                type: "taunt",
                duration: 3
            },
            {
                type: "buff",
                stat: "physical_defense",
                amount: 30,
                is_percent: true,
                duration: 5
            }
        ]
    };

    // 전투의 함성 (지원)
    global.skill_templates[$ "war_cry"] = {
        id: "war_cry",
        name: "전투의 함성",
        description: "주변 아군의 공격력을 증가시킵니다.",

        mana_cost: 35,
        cooldown: 20,

        target_type: "ally",
        target_self: true,
        aoe_radius: 250,

        effects: [
            {
                type: "buff",
                stat: "physical_attack",
                amount: 25,
                is_percent: true,
                duration: 10
            }
        ]
    };

    // 슬로우 (마법사)
    global.skill_templates[$ "slow"] = {
        id: "slow",
        name: "감속",
        description: "대상의 이동/공격 속도를 감소시킵니다.",

        mana_cost: 15,
        cooldown: 6,

        target_type: "enemy",
        range: 350,

        effects: [
            {
                type: "debuff",
                stat: "movement_speed",
                amount: -40,
                is_percent: true,
                duration: 4
            },
            {
                type: "debuff",
                stat: "attack_speed",
                amount: -30,
                is_percent: true,
                duration: 4
            }
        ]
    };

    // 스턴 (탱커)
    global.skill_templates[$ "shield_bash"] = {
        id: "shield_bash",
        name: "방패 강타",
        description: "적을 기절시킵니다.",

        mana_cost: 25,
        cooldown: 12,

        target_type: "enemy",
        range: 60,

        effects: [
            {
                type: "damage",
                damage_type: "physical",
                base_damage: 30,
                scaling: { stat: "physical_attack", ratio: 0.5 }
            },
            {
                type: "cc",
                cc_type: "stun",
                duration: 2
            }
        ]
    };

    combat_log("스킬 템플릿 " + string(struct_names_count(global.skill_templates)) + "개 로드됨");
}

// ========================================
// 스킬 사용
// ========================================

/// @func use_skill(caster, skill_id, target)
/// @desc 스킬 사용
function use_skill(caster, skill_id, target) {
    // 템플릿 확인
    if (!variable_global_exists("skill_templates")) {
        init_skill_templates();
    }

    var skill = global.skill_templates[$ skill_id];
    if (skill == undefined) {
        combat_log("알 수 없는 스킬: " + skill_id);
        return false;
    }

    // 쿨다운 체크
    if (!check_skill_cooldown(caster, skill_id)) {
        return false;
    }

    // 마나 체크
    var mana = caster[$ "mana"] ?? 100;
    if (mana < skill.mana_cost) {
        return false;
    }

    // 사거리 체크 (self 타입 제외)
    if (skill.target_type != "self" && target != undefined) {
        var dist = point_distance(caster.x, caster.y, target.x, target.y);
        if (dist > skill.range) {
            return false;
        }
    }

    // 마나 소모
    caster.mana = mana - skill.mana_cost;

    // 쿨다운 시작
    start_skill_cooldown(caster, skill_id, skill.cooldown);

    // 타겟 목록 결정
    var targets = get_skill_targets(caster, skill, target);

    // 효과 적용
    for (var i = 0; i < array_length(targets); i++) {
        apply_skill_effects(caster, skill, targets[i]);
    }

    combat_log((caster.display_name ?? "유닛") + " → " + skill.name + " 사용");

    return true;
}

/// @func get_skill_targets(caster, skill, primary_target)
/// @desc 스킬 타겟 목록 반환
function get_skill_targets(caster, skill, primary_target) {
    var targets = [];

    // self 타입
    if (skill.target_type == "self") {
        array_push(targets, caster);

        // AOE가 있으면 추가 타겟
        if (variable_struct_exists(skill, "aoe_radius")) {
            var aoe_team = skill[$ "aoe_target"] ?? "ally";
            var nearby = get_units_in_radius(caster.x, caster.y, skill.aoe_radius, aoe_team);
            for (var i = 0; i < array_length(nearby); i++) {
                if (nearby[i] != caster) {
                    array_push(targets, nearby[i]);
                }
            }
        }
        return targets;
    }

    // AOE 스킬
    if (variable_struct_exists(skill, "aoe_radius")) {
        var center_x, center_y;
        if (primary_target != undefined) {
            center_x = primary_target.x;
            center_y = primary_target.y;
        } else {
            center_x = caster.x;
            center_y = caster.y;
        }

        var team = skill.target_type;
        if (team == "ally" && skill[$ "target_self"]) {
            array_push(targets, caster);
        }

        var nearby = get_units_in_radius(center_x, center_y, skill.aoe_radius, team);
        for (var i = 0; i < array_length(nearby); i++) {
            if (nearby[i] != caster || skill[$ "target_self"]) {
                array_push(targets, nearby[i]);
            }
        }
        return targets;
    }

    // 다중 타겟
    if (variable_struct_exists(skill, "target_count")) {
        var team = skill.target_type;
        var all_targets = get_all_units_by_team(team == "enemy" ? get_enemy_team(caster.team) : caster.team);

        // 거리순 정렬
        array_sort(all_targets, function(a, b) {
            return point_distance(caster.x, caster.y, a.x, a.y) - point_distance(caster.x, caster.y, b.x, b.y);
        });

        var count = min(skill.target_count, array_length(all_targets));
        for (var i = 0; i < count; i++) {
            array_push(targets, all_targets[i]);
        }
        return targets;
    }

    // 단일 타겟
    if (primary_target != undefined) {
        array_push(targets, primary_target);
    }

    return targets;
}

/// @func apply_skill_effects(caster, skill, target)
/// @desc 스킬 효과 적용
function apply_skill_effects(caster, skill, target) {
    for (var i = 0; i < array_length(skill.effects); i++) {
        var effect = skill.effects[i];
        apply_effect(caster, target, effect);
    }
}

// ========================================
// 이펙트 처리
// ========================================

/// @func apply_effect(caster, target, effect)
/// @desc 개별 이펙트 적용
function apply_effect(caster, target, effect) {
    switch (effect.type) {
        case "damage":
            apply_damage_effect(caster, target, effect);
            break;

        case "heal":
            apply_heal_effect(caster, target, effect);
            break;

        case "dot":
            apply_dot_effect(caster, target, effect);
            break;

        case "hot":
            apply_hot_effect(caster, target, effect);
            break;

        case "buff":
            apply_buff_effect(caster, target, effect);
            break;

        case "debuff":
            apply_debuff_effect(caster, target, effect);
            break;

        case "cc":
            apply_cc_effect(caster, target, effect);
            break;

        case "taunt":
            apply_taunt_effect(caster, target, effect);
            break;
    }
}

/// @func apply_damage_effect(caster, target, effect)
function apply_damage_effect(caster, target, effect) {
    // 기본 피해
    var damage = effect.base_damage ?? 0;

    // 스케일링
    if (variable_struct_exists(effect, "scaling")) {
        var stat_name = effect.scaling.stat;
        var stat_value = caster[$ stat_name] ?? 0;
        damage += stat_value * effect.scaling.ratio;
    }

    // 처형 보너스
    if (variable_struct_exists(effect, "execute_threshold")) {
        var hp_percent = target.hp / target.max_hp;
        if (hp_percent <= effect.execute_threshold) {
            damage *= effect.execute_multiplier ?? 2;
        }
    }

    // 피해 적용
    var damage_info = {
        amount: damage,
        type: effect.damage_type ?? "physical",
        element: effect[$ "element"] ?? "none",
        is_skill: true
    };

    apply_damage(target, damage_info, caster);
}

/// @func apply_heal_effect(caster, target, effect)
function apply_heal_effect(caster, target, effect) {
    var heal = effect.base_heal ?? 0;

    // 스케일링
    if (variable_struct_exists(effect, "scaling")) {
        var stat_name = effect.scaling.stat;
        var stat_value = caster[$ stat_name] ?? 0;
        heal += stat_value * effect.scaling.ratio;
    }

    // 회복 적용
    var old_hp = target.hp;
    target.hp = min(target.hp + heal, target.max_hp);
    var actual_heal = target.hp - old_hp;

    if (actual_heal > 0) {
        // 힐 숫자 표시
        show_damage_number(target.x, target.y, actual_heal, c_lime);
        combat_log((target.display_name ?? "유닛") + " HP +" + string(floor(actual_heal)));
    }
}

/// @func apply_dot_effect(caster, target, effect)
function apply_dot_effect(caster, target, effect) {
    // DOT 버프로 추가
    var dot = {
        type: "dot",
        source: caster,
        damage_type: effect.damage_type ?? "magic",
        element: effect[$ "element"] ?? "none",
        tick_damage: effect.tick_damage,
        duration: effect.duration,
        remaining: effect.duration,
        tick_interval: effect.tick_interval ?? 1,
        tick_timer: 0
    };

    add_status_effect(target, dot);
}

/// @func apply_hot_effect(caster, target, effect)
function apply_hot_effect(caster, target, effect) {
    var tick_heal = effect.tick_heal ?? 0;

    // 스케일링
    if (variable_struct_exists(effect, "scaling")) {
        var stat_name = effect.scaling.stat;
        var stat_value = caster[$ stat_name] ?? 0;
        tick_heal += stat_value * effect.scaling.ratio;
    }

    var hot = {
        type: "hot",
        source: caster,
        tick_heal: tick_heal,
        duration: effect.duration,
        remaining: effect.duration,
        tick_interval: effect.tick_interval ?? 1,
        tick_timer: 0
    };

    add_status_effect(target, hot);
}

/// @func apply_buff_effect(caster, target, effect)
function apply_buff_effect(caster, target, effect) {
    var buff = {
        type: "buff",
        stat: effect.stat,
        amount: effect.amount,
        is_percent: effect[$ "is_percent"] ?? false,
        duration: effect.duration,
        remaining: effect.duration
    };

    add_status_effect(target, buff);
    recalculate_unit_stats(target);

    combat_log((target.display_name ?? "유닛") + " " + effect.stat + " +" + string(effect.amount) + (effect[$ "is_percent"] ? "%" : ""));
}

/// @func apply_debuff_effect(caster, target, effect)
function apply_debuff_effect(caster, target, effect) {
    var debuff = {
        type: "debuff",
        stat: effect.stat,
        amount: effect.amount,
        is_percent: effect[$ "is_percent"] ?? false,
        duration: effect.duration,
        remaining: effect.duration
    };

    add_status_effect(target, debuff);
    recalculate_unit_stats(target);

    combat_log((target.display_name ?? "유닛") + " " + effect.stat + " " + string(effect.amount) + (effect[$ "is_percent"] ? "%" : ""));
}

/// @func apply_cc_effect(caster, target, effect)
function apply_cc_effect(caster, target, effect) {
    var cc = {
        type: "cc",
        cc_type: effect.cc_type,
        duration: effect.duration,
        remaining: effect.duration
    };

    add_status_effect(target, cc);

    // CC 상태 적용
    target.is_stunned = (effect.cc_type == "stun");
    target.is_rooted = (effect.cc_type == "root");
    target.is_silenced = (effect.cc_type == "silence");

    combat_log((target.display_name ?? "유닛") + " " + effect.cc_type + " " + string(effect.duration) + "초");
}

/// @func apply_taunt_effect(caster, target, effect)
function apply_taunt_effect(caster, target, effect) {
    // target은 적 유닛 (AOE로 선택됨)
    target.ai_target = caster;
    target.taunt_source = caster;
    target.taunt_remaining = effect.duration;

    combat_log((target.display_name ?? "적") + " → " + (caster.display_name ?? "탱커") + " 도발됨");
}

// ========================================
// 상태 효과 관리
// ========================================

/// @func add_status_effect(unit, effect)
function add_status_effect(unit, effect) {
    if (!variable_struct_exists(unit, "status_effects")) {
        unit.status_effects = [];
    }

    // 같은 타입의 효과가 있으면 갱신 (가장 강한 것 유지 또는 리프레시)
    for (var i = 0; i < array_length(unit.status_effects); i++) {
        var existing = unit.status_effects[i];
        if (existing.type == effect.type && existing[$ "stat"] == effect[$ "stat"]) {
            // 지속시간 리프레시
            existing.remaining = max(existing.remaining, effect.remaining);
            return;
        }
    }

    array_push(unit.status_effects, effect);
}

/// @func update_status_effects(unit, delta)
function update_status_effects(unit, delta) {
    if (!variable_struct_exists(unit, "status_effects")) return;

    for (var i = array_length(unit.status_effects) - 1; i >= 0; i--) {
        var effect = unit.status_effects[i];

        // DOT/HOT 틱 처리
        if (effect.type == "dot" || effect.type == "hot") {
            effect.tick_timer += delta;

            if (effect.tick_timer >= effect.tick_interval) {
                effect.tick_timer -= effect.tick_interval;

                if (effect.type == "dot") {
                    // DOT 틱 피해
                    var damage_info = {
                        amount: effect.tick_damage,
                        type: effect.damage_type,
                        element: effect.element,
                        is_dot: true
                    };
                    apply_damage(unit, damage_info, effect.source);
                } else {
                    // HOT 틱 힐
                    var old_hp = unit.hp;
                    unit.hp = min(unit.hp + effect.tick_heal, unit.max_hp);
                    var healed = unit.hp - old_hp;
                    if (healed > 0) {
                        show_damage_number(unit.x, unit.y, healed, c_lime);
                    }
                }
            }
        }

        // 지속시간 감소
        effect.remaining -= delta;

        // 만료 체크
        if (effect.remaining <= 0) {
            // 효과 종료
            if (effect.type == "cc") {
                unit.is_stunned = false;
                unit.is_rooted = false;
                unit.is_silenced = false;
            }

            array_delete(unit.status_effects, i, 1);

            // 스탯 재계산 (버프/디버프)
            if (effect.type == "buff" || effect.type == "debuff") {
                recalculate_unit_stats(unit);
            }
        }
    }

    // 도발 타이머
    if (variable_struct_exists(unit, "taunt_remaining")) {
        unit.taunt_remaining -= delta;
        if (unit.taunt_remaining <= 0) {
            unit.taunt_source = undefined;
        }
    }
}

/// @func recalculate_unit_stats(unit)
/// @desc 버프/디버프 적용하여 스탯 재계산
function recalculate_unit_stats(unit) {
    // 기본 스탯 저장 (없으면 현재 값 저장)
    if (!variable_struct_exists(unit, "base_stats")) {
        unit.base_stats = {
            physical_attack: unit.physical_attack,
            physical_defense: unit.physical_defense,
            magic_attack: unit[$ "magic_attack"] ?? 0,
            magic_defense: unit[$ "magic_defense"] ?? 0,
            attack_speed: unit.attack_speed,
            movement_speed: unit.movement_speed
        };
    }

    // 기본 스탯으로 리셋
    unit.physical_attack = unit.base_stats.physical_attack;
    unit.physical_defense = unit.base_stats.physical_defense;
    unit.magic_attack = unit.base_stats.magic_attack;
    unit.magic_defense = unit.base_stats.magic_defense;
    unit.attack_speed = unit.base_stats.attack_speed;
    unit.movement_speed = unit.base_stats.movement_speed;

    // 버프/디버프 적용
    if (!variable_struct_exists(unit, "status_effects")) return;

    // 먼저 고정값 적용
    for (var i = 0; i < array_length(unit.status_effects); i++) {
        var effect = unit.status_effects[i];
        if ((effect.type == "buff" || effect.type == "debuff") && !effect.is_percent) {
            apply_stat_modifier(unit, effect.stat, effect.amount);
        }
    }

    // 그다음 퍼센트 적용
    for (var i = 0; i < array_length(unit.status_effects); i++) {
        var effect = unit.status_effects[i];
        if ((effect.type == "buff" || effect.type == "debuff") && effect.is_percent) {
            var base = unit[$ effect.stat] ?? 0;
            apply_stat_modifier(unit, effect.stat, base * effect.amount / 100);
        }
    }
}

/// @func apply_stat_modifier(unit, stat, amount)
function apply_stat_modifier(unit, stat, amount) {
    switch (stat) {
        case "physical_attack":
            unit.physical_attack += amount;
            break;
        case "physical_defense":
            unit.physical_defense += amount;
            break;
        case "magic_attack":
            unit.magic_attack += amount;
            break;
        case "magic_defense":
            unit.magic_defense += amount;
            break;
        case "attack_speed":
            unit.attack_speed += amount;
            break;
        case "movement_speed":
            unit.movement_speed += amount;
            break;
    }
}

// ========================================
// 쿨다운 시스템
// ========================================

/// @func check_skill_cooldown(unit, skill_id)
function check_skill_cooldown(unit, skill_id) {
    if (!variable_struct_exists(unit, "skill_cooldowns")) {
        unit.skill_cooldowns = {};
    }

    var remaining = unit.skill_cooldowns[$ skill_id] ?? 0;
    return remaining <= 0;
}

/// @func start_skill_cooldown(unit, skill_id, duration)
function start_skill_cooldown(unit, skill_id, duration) {
    if (!variable_struct_exists(unit, "skill_cooldowns")) {
        unit.skill_cooldowns = {};
    }

    unit.skill_cooldowns[$ skill_id] = duration;
}

/// @func update_skill_cooldowns(unit, delta)
function update_skill_cooldowns(unit, delta) {
    if (!variable_struct_exists(unit, "skill_cooldowns")) return;

    var skills = struct_get_names(unit.skill_cooldowns);
    for (var i = 0; i < array_length(skills); i++) {
        var skill_id = skills[i];
        if (unit.skill_cooldowns[$ skill_id] > 0) {
            unit.skill_cooldowns[$ skill_id] -= delta;
        }
    }
}

// ========================================
// 마나 시스템
// ========================================

/// @func init_unit_mana(unit)
function init_unit_mana(unit) {
    if (!variable_struct_exists(unit, "mana")) {
        unit.mana = 100;
        unit.max_mana = 100;
        unit.mana_regen = 5;  // 초당 마나 재생
    }
}

/// @func update_unit_mana(unit, delta)
function update_unit_mana(unit, delta) {
    if (!variable_struct_exists(unit, "mana")) return;

    unit.mana = min(unit.mana + unit.mana_regen * delta, unit.max_mana);
}

// ========================================
// 유틸리티
// ========================================

/// @func get_units_in_radius(x, y, radius, team)
function get_units_in_radius(_x, _y, radius, team) {
    var result = [];
    var units;

    if (team == "ally") {
        units = variable_global_exists("ally_units") ? global.ally_units : [];
    } else if (team == "enemy") {
        units = variable_global_exists("enemy_units") ? global.enemy_units : [];
    } else {
        // 모든 유닛
        units = [];
        if (variable_global_exists("ally_units")) {
            units = array_concat(units, global.ally_units);
        }
        if (variable_global_exists("enemy_units")) {
            units = array_concat(units, global.enemy_units);
        }
    }

    for (var i = 0; i < array_length(units); i++) {
        var u = units[i];
        if (u.hp > 0 && point_distance(_x, _y, u.x, u.y) <= radius) {
            array_push(result, u);
        }
    }

    return result;
}

/// @func get_all_units_by_team(team)
function get_all_units_by_team(team) {
    if (team == "ally") {
        return variable_global_exists("ally_units") ? global.ally_units : [];
    } else if (team == "enemy") {
        return variable_global_exists("enemy_units") ? global.enemy_units : [];
    }
    return [];
}

/// @func get_enemy_team(team)
function get_enemy_team(team) {
    return (team == "ally") ? "enemy" : "ally";
}

/// @func show_damage_number(x, y, value, color)
function show_damage_number(_x, _y, value, color) {
    if (!variable_global_exists("debug")) return;
    if (!variable_struct_exists(global.debug, "damage_numbers")) return;

    array_push(global.debug.damage_numbers, {
        x: _x + random_range(-10, 10),
        y: _y - 20,
        value: floor(value),
        color: color,
        alpha: 1,
        vy: -40
    });
}
