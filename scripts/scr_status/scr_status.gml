/// @file scr_status.gml
/// @desc 상태이상(CC) 시스템

/*
상태이상 종류:
- stun (기절): 행동 불가 (이동, 공격, 스킬 모두 불가)
- root (속박): 이동 불가 (공격, 스킬은 가능)
- slow (둔화): 이동속도/공격속도 감소
- silence (침묵): 스킬 사용 불가 (이동, 기본공격은 가능)
- dot (지속피해): 매 초 피해
- hot (지속회복): 매 초 회복
- buff (버프): 스탯 증가
- debuff (디버프): 스탯 감소

저항 적용:
- cc_resist (행동불능 저항): 기절, 속박, 침묵 지속시간 감소
- debuff_resist (약화 저항): 둔화율, 디버프 효과량 감소
*/

/// @func init_status_system()
/// @desc 상태이상 시스템 초기화
function init_status_system() {
    // 상태이상 타입 정의
    global.status_types = {
        // 행동불능 (Hard CC) - cc_resist 적용
        stun: {
            id: "stun",
            name: "기절",
            is_cc: true,
            blocks_movement: true,
            blocks_attack: true,
            blocks_skill: true,
            stackable: false  // 중첩 불가, 더 긴 시간으로 갱신
        },
        root: {
            id: "root",
            name: "속박",
            is_cc: true,
            blocks_movement: true,
            blocks_attack: false,
            blocks_skill: false,
            stackable: false
        },
        silence: {
            id: "silence",
            name: "침묵",
            is_cc: true,
            blocks_movement: false,
            blocks_attack: false,
            blocks_skill: true,
            stackable: false
        },
        // 약화 (Soft Debuff) - debuff_resist 적용
        slow: {
            id: "slow",
            name: "둔화",
            is_cc: false,
            is_debuff: true,
            affects: ["movement_speed", "attack_speed"],
            stackable: false  // 가장 강한 효과만 적용
        },
        weaken: {
            id: "weaken",
            name: "약화",
            is_cc: false,
            is_debuff: true,
            affects: ["physical_attack", "magic_attack"],
            stackable: false
        },
        vulnerable: {
            id: "vulnerable",
            name: "취약",
            is_cc: false,
            is_debuff: true,
            affects: ["physical_defense", "magic_defense"],
            stackable: false
        },
        // 지속 효과
        dot: {
            id: "dot",
            name: "지속피해",
            is_cc: false,
            is_debuff: true,
            stackable: true,  // 중첩 가능 (다른 소스끼리)
            tick_rate: 1.0    // 1초마다 틱
        },
        hot: {
            id: "hot",
            name: "지속회복",
            is_cc: false,
            is_buff: true,
            stackable: true,
            tick_rate: 1.0
        },
        // 버프
        haste: {
            id: "haste",
            name: "가속",
            is_cc: false,
            is_buff: true,
            affects: ["movement_speed", "attack_speed"],
            stackable: false
        },
        might: {
            id: "might",
            name: "강화",
            is_cc: false,
            is_buff: true,
            affects: ["physical_attack", "magic_attack"],
            stackable: false
        },
        shield: {
            id: "shield",
            name: "보호막",
            is_cc: false,
            is_buff: true,
            stackable: true  // 보호막은 중첩 가능
        },
        // 기사 스킬용 특수 효과
        guardian: {
            id: "guardian",
            name: "보호자",
            is_cc: false,
            is_buff: true,
            stackable: false
        },
        protected: {
            id: "protected",
            name: "보호받음",
            is_cc: false,
            is_buff: true,
            stackable: false
        },
        duel: {
            id: "duel",
            name: "결투",
            is_cc: false,
            is_buff: true,
            stackable: false
        },
        immortal: {
            id: "immortal",
            name: "불멸",
            is_cc: false,
            is_buff: true,
            stackable: false
        },
        buff_defense: {
            id: "buff_defense",
            name: "방어력 증가",
            is_cc: false,
            is_buff: true,
            stackable: false
        }
    };
}

/// @func apply_status_effect(unit, effect_data)
/// @desc 유닛에 상태이상 적용
/// @param unit 대상 유닛
/// @param effect_data { type, duration, amount, source_id, damage_type }
/// @return 적용 성공 여부
function apply_status_effect(unit, effect_data) {
    if (!variable_struct_exists(unit, "status_effects")) {
        unit.status_effects = [];
    }

    var type_id = effect_data.type;
    var type_info = global.status_types[$ type_id];

    // 동적 버프 타입 처리 (buff_defense 등)
    if (type_info == undefined) {
        // buff_ 접두사 또는 특수 효과 타입인 경우 기본 버프로 처리
        if (string_pos("buff_", type_id) == 1 ||
            type_id == "guardian" || type_id == "protected" ||
            type_id == "duel" || type_id == "immortal") {
            type_info = {
                id: type_id,
                name: type_id,
                is_cc: false,
                is_buff: true,
                stackable: false
            };
        } else {
            return false;
        }
    }

    var duration = effect_data.duration;
    var amount = variable_struct_exists(effect_data, "amount") ? effect_data.amount : 0;

    // 행동불능 저항 적용 (기절, 속박, 침묵)
    if (variable_struct_exists(type_info, "is_cc") && type_info.is_cc) {
        var cc_reduction = unit.cc_resist / 100;
        duration = duration * (1 - cc_reduction);

        // 지속시간이 0.1초 미만이면 면역
        if (duration < 0.1) {
            // 면역 효과 표시 가능
            return false;
        }
    }

    // 약화 저항 적용 (둔화, 약화, 취약, DOT)
    if (variable_struct_exists(type_info, "is_debuff") && type_info.is_debuff) {
        var debuff_reduction = unit.debuff_resist / 100;

        // 효과량 감소 (둔화율, 피해량 등)
        amount = amount * (1 - debuff_reduction);

        // DOT이 아닌 경우 지속시간도 감소
        if (type_id != "dot") {
            duration = duration * (1 - debuff_reduction * 0.5);  // 50%만 적용
        }

        // 효과가 너무 약하면 무시
        if (amount < 1 && type_id != "dot") {
            return false;
        }
    }

    // 새 효과 생성
    var new_effect = {
        type: type_id,
        duration: duration,
        max_duration: duration,
        amount: amount,
        source_id: variable_struct_exists(effect_data, "source_id") ? effect_data.source_id : -1,
        damage_type: variable_struct_exists(effect_data, "damage_type") ? effect_data.damage_type : "none",
        tick_timer: 0
    };

    // 추가 속성 복사 (guardian, duel 등 특수 효과용)
    if (variable_struct_exists(effect_data, "stat")) new_effect.stat = effect_data.stat;
    if (variable_struct_exists(effect_data, "value")) new_effect.value = effect_data.value;
    if (variable_struct_exists(effect_data, "percent")) new_effect.percent = effect_data.percent;
    if (variable_struct_exists(effect_data, "defense_bonus")) new_effect.defense_bonus = effect_data.defense_bonus;
    if (variable_struct_exists(effect_data, "protected_unit")) new_effect.protected_unit = effect_data.protected_unit;
    if (variable_struct_exists(effect_data, "protector")) new_effect.protector = effect_data.protector;
    if (variable_struct_exists(effect_data, "opponent")) new_effect.opponent = effect_data.opponent;

    // 중첩 처리
    if (!type_info.stackable) {
        // 기존 같은 타입 효과 찾기
        for (var i = 0; i < array_length(unit.status_effects); i++) {
            var existing = unit.status_effects[i];
            if (existing.type == type_id) {
                // CC: 더 긴 지속시간으로 갱신
                if (variable_struct_exists(type_info, "is_cc") && type_info.is_cc) {
                    if (new_effect.duration > existing.duration) {
                        existing.duration = new_effect.duration;
                        existing.max_duration = new_effect.max_duration;
                    }
                }
                // 둔화/버프: 더 강한 효과로 갱신
                else {
                    if (new_effect.amount > existing.amount) {
                        existing.amount = new_effect.amount;
                        existing.duration = new_effect.duration;
                        existing.max_duration = new_effect.max_duration;
                    } else if (new_effect.duration > existing.duration) {
                        existing.duration = new_effect.duration;
                        existing.max_duration = new_effect.max_duration;
                    }
                }
                return true;
            }
        }
    } else {
        // 중첩 가능: 같은 소스의 효과만 갱신
        for (var i = 0; i < array_length(unit.status_effects); i++) {
            var existing = unit.status_effects[i];
            if (existing.type == type_id && existing.source_id == new_effect.source_id) {
                existing.duration = new_effect.duration;
                existing.max_duration = new_effect.max_duration;
                existing.amount = new_effect.amount;
                return true;
            }
        }
    }

    // 새 효과 추가
    array_push(unit.status_effects, new_effect);
    return true;
}

/// @func remove_status_effect(unit, type_id, source_id)
/// @desc 상태이상 제거
/// @param unit 대상 유닛
/// @param type_id 효과 타입 (undefined면 모든 타입)
/// @param source_id 소스 ID (undefined면 모든 소스)
function remove_status_effect(unit, type_id = undefined, source_id = undefined) {
    if (!variable_struct_exists(unit, "status_effects")) return;

    for (var i = array_length(unit.status_effects) - 1; i >= 0; i--) {
        var effect = unit.status_effects[i];
        var should_remove = true;

        if (type_id != undefined && effect.type != type_id) {
            should_remove = false;
        }
        if (source_id != undefined && effect.source_id != source_id) {
            should_remove = false;
        }

        if (should_remove) {
            array_delete(unit.status_effects, i, 1);
        }
    }
}

/// @func cleanse_cc(unit)
/// @desc 모든 CC 효과 제거
function cleanse_cc(unit) {
    if (!variable_struct_exists(unit, "status_effects")) return;

    for (var i = array_length(unit.status_effects) - 1; i >= 0; i--) {
        var effect = unit.status_effects[i];
        var type_info = global.status_types[$ effect.type];
        if (type_info != undefined && variable_struct_exists(type_info, "is_cc") && type_info.is_cc) {
            array_delete(unit.status_effects, i, 1);
        }
    }
}

/// @func cleanse_debuffs(unit)
/// @desc 모든 디버프 효과 제거
function cleanse_debuffs(unit) {
    if (!variable_struct_exists(unit, "status_effects")) return;

    for (var i = array_length(unit.status_effects) - 1; i >= 0; i--) {
        var effect = unit.status_effects[i];
        var type_info = global.status_types[$ effect.type];
        if (type_info != undefined && variable_struct_exists(type_info, "is_debuff") && type_info.is_debuff) {
            array_delete(unit.status_effects, i, 1);
        }
    }
}

/// @func update_status_effects(unit, delta_time)
/// @desc 상태이상 업데이트 (매 프레임 호출)
/// @param unit 대상 유닛
/// @param delta_time 프레임 시간 (초)
function update_status_effects(unit, delta_time) {
    if (!variable_struct_exists(unit, "status_effects")) return;

    for (var i = array_length(unit.status_effects) - 1; i >= 0; i--) {
        var effect = unit.status_effects[i];
        var type_info = global.status_types[$ effect.type];

        // 지속시간 감소
        effect.duration -= delta_time;

        // DOT/HOT 틱 처리
        if (type_info != undefined) {
            if (variable_struct_exists(type_info, "tick_rate")) {
                effect.tick_timer += delta_time;
                if (effect.tick_timer >= type_info.tick_rate) {
                    effect.tick_timer -= type_info.tick_rate;

                    // DOT 피해
                    if (effect.type == "dot") {
                        var damage = effect.amount;
                        unit.hp = max(0, unit.hp - damage);
                    }
                    // HOT 회복
                    else if (effect.type == "hot") {
                        var heal = effect.amount;
                        unit.hp = min(unit.max_hp, unit.hp + heal);
                    }
                }
            }
        }

        // 만료된 효과 제거
        if (effect.duration <= 0) {
            array_delete(unit.status_effects, i, 1);
        }
    }
}

/// @func has_status_effect(unit, type_id)
/// @desc 특정 상태이상 보유 여부
function has_status_effect(unit, type_id) {
    if (!variable_struct_exists(unit, "status_effects")) return false;

    for (var i = 0; i < array_length(unit.status_effects); i++) {
        if (unit.status_effects[i].type == type_id) {
            return true;
        }
    }
    return false;
}

/// @func get_status_effect(unit, type_id)
/// @desc 특정 상태이상 가져오기
function get_status_effect(unit, type_id) {
    if (!variable_struct_exists(unit, "status_effects")) return undefined;

    for (var i = 0; i < array_length(unit.status_effects); i++) {
        if (unit.status_effects[i].type == type_id) {
            return unit.status_effects[i];
        }
    }
    return undefined;
}

/// @func is_stunned(unit)
function is_stunned(unit) {
    return has_status_effect(unit, "stun");
}

/// @func is_rooted(unit)
function is_rooted(unit) {
    return has_status_effect(unit, "root");
}

/// @func is_silenced(unit)
function is_silenced(unit) {
    return has_status_effect(unit, "silence");
}

/// @func is_cc_immune(unit)
/// @desc 행동불능 완전 면역 여부 (cc_resist 100%)
function is_cc_immune(unit) {
    return unit.cc_resist >= 100;
}

/// @func can_move(unit)
/// @desc 이동 가능 여부
function can_move(unit) {
    if (!unit.is_alive) return false;
    if (has_status_effect(unit, "stun")) return false;
    if (has_status_effect(unit, "root")) return false;
    return true;
}

/// @func can_attack(unit)
/// @desc 기본 공격 가능 여부
function can_attack(unit) {
    if (!unit.is_alive) return false;
    if (has_status_effect(unit, "stun")) return false;
    return true;
}

/// @func can_use_skill(unit)
/// @desc 스킬 사용 가능 여부
function can_use_skill(unit) {
    if (!unit.is_alive) return false;
    if (has_status_effect(unit, "stun")) return false;
    if (has_status_effect(unit, "silence")) return false;
    return true;
}

/// @func get_effective_stat(unit, stat_name)
/// @desc 상태이상 적용된 실제 스탯 값 계산
function get_effective_stat(unit, stat_name) {
    var base_value = variable_struct_get(unit, stat_name);
    if (base_value == undefined) return 0;

    if (!variable_struct_exists(unit, "status_effects")) return base_value;

    var multiplier = 1.0;

    for (var i = 0; i < array_length(unit.status_effects); i++) {
        var effect = unit.status_effects[i];
        var type_info = global.status_types[$ effect.type];

        if (type_info == undefined) continue;
        if (!variable_struct_exists(type_info, "affects")) continue;

        // 이 효과가 해당 스탯에 영향을 주는지 확인
        var affects_stat = false;
        for (var j = 0; j < array_length(type_info.affects); j++) {
            if (type_info.affects[j] == stat_name) {
                affects_stat = true;
                break;
            }
        }

        if (affects_stat) {
            if (variable_struct_exists(type_info, "is_debuff") && type_info.is_debuff) {
                // 디버프: 감소
                multiplier *= (1 - effect.amount / 100);
            } else if (variable_struct_exists(type_info, "is_buff") && type_info.is_buff) {
                // 버프: 증가
                multiplier *= (1 + effect.amount / 100);
            }
        }
    }

    return floor(base_value * multiplier);
}

/// @func get_slow_amount(unit)
/// @desc 현재 적용된 둔화량 (%)
function get_slow_amount(unit) {
    var effect = get_status_effect(unit, "slow");
    if (effect != undefined) {
        return effect.amount;
    }
    return 0;
}

/// @func get_status_effect_list(unit)
/// @desc 유닛의 모든 상태이상 목록
function get_status_effect_list(unit) {
    if (!variable_struct_exists(unit, "status_effects")) {
        return [];
    }
    return unit.status_effects;
}

// ============================================
// 결투(Duel) 시스템 함수
// ============================================

/// @func is_in_duel(unit)
/// @desc 유닛이 결투 중인지 확인
function is_in_duel(unit) {
    return has_status_effect(unit, "duel");
}

/// @func get_duel_opponent(unit)
/// @desc 결투 상대 유닛 반환 (없으면 undefined)
function get_duel_opponent(unit) {
    var effect = get_status_effect(unit, "duel");
    if (effect != undefined && variable_struct_exists(effect, "opponent")) {
        return effect.opponent;
    }
    return undefined;
}

/// @func can_attack_target(attacker, target)
/// @desc 공격자가 대상을 공격할 수 있는지 확인 (결투 상태 고려)
function can_attack_target(attacker, target) {
    // 공격자가 결투 중이면 결투 상대만 공격 가능
    if (is_in_duel(attacker)) {
        var opponent = get_duel_opponent(attacker);
        if (opponent != undefined && opponent != target) {
            return false;  // 결투 상대가 아니면 공격 불가
        }
    }

    // 대상이 결투 중이면 결투 상대만 공격 가능
    if (is_in_duel(target)) {
        var target_opponent = get_duel_opponent(target);
        if (target_opponent != undefined && target_opponent != attacker) {
            return false;  // 결투에 개입 불가
        }
    }

    return true;
}

/// @func can_receive_damage_from(defender, attacker)
/// @desc 방어자가 공격자로부터 피해를 받을 수 있는지 확인
function can_receive_damage_from(defender, attacker) {
    // 방어자가 결투 중이면 결투 상대만 피해 가능
    if (is_in_duel(defender)) {
        var opponent = get_duel_opponent(defender);
        if (opponent != undefined && opponent != attacker) {
            return false;  // 결투 상대가 아니면 피해 무효
        }
    }

    return true;
}

/// @func get_duel_defense_bonus(unit)
/// @desc 결투로 인한 방어력 보너스 (%) 반환
function get_duel_defense_bonus(unit) {
    var effect = get_status_effect(unit, "duel");
    if (effect != undefined && variable_struct_exists(effect, "defense_bonus")) {
        return effect.defense_bonus;
    }
    return 0;
}

/// @func get_buff_defense_bonus(unit)
/// @desc 버프로 인한 방어력 보너스 (%) 반환
function get_buff_defense_bonus(unit) {
    var effect = get_status_effect(unit, "buff_defense");
    if (effect != undefined && variable_struct_exists(effect, "value")) {
        return effect.value;
    }
    return 0;
}

// ============================================
// 보호자(Guardian) 시스템 함수
// ============================================

/// @func is_protected(unit)
/// @desc 유닛이 보호받는 상태인지 확인
function is_protected(unit) {
    return has_status_effect(unit, "protected");
}

/// @func is_guardian(unit)
/// @desc 유닛이 보호자 상태인지 확인
function is_guardian(unit) {
    return has_status_effect(unit, "guardian");
}

/// @func get_protector(unit)
/// @desc 보호자 유닛 반환 (없으면 undefined)
function get_protector(unit) {
    var effect = get_status_effect(unit, "protected");
    if (effect != undefined && variable_struct_exists(effect, "protector")) {
        return effect.protector;
    }
    return undefined;
}

/// @func get_protected_unit(guardian)
/// @desc 보호받는 유닛 반환 (없으면 undefined)
function get_protected_unit(guardian) {
    var effect = get_status_effect(guardian, "guardian");
    if (effect != undefined && variable_struct_exists(effect, "protected_unit")) {
        return effect.protected_unit;
    }
    return undefined;
}

/// @func get_guardian_defense_bonus(unit)
/// @desc 보호자로 인한 방어력 보너스 (%) 반환
function get_guardian_defense_bonus(unit) {
    var effect = get_status_effect(unit, "guardian");
    if (effect != undefined && variable_struct_exists(effect, "defense_bonus")) {
        return effect.defense_bonus;
    }
    return 0;
}

/// @func is_immortal(unit)
/// @desc 불멸 상태인지 확인
function is_immortal(unit) {
    return has_status_effect(unit, "immortal");
}

/// @func apply_damage_with_immortal(unit, damage)
/// @desc 불멸 상태를 고려하여 피해 적용 (HP가 1 이하로 떨어지지 않음)
/// @return 실제 적용된 피해량
function apply_damage_with_immortal(unit, damage) {
    if (is_immortal(unit)) {
        // 불멸 상태: HP가 1 이하로 떨어지지 않음
        var max_damage = unit.hp - 1;
        if (max_damage <= 0) {
            return 0;  // 이미 HP가 1 이하면 피해 없음
        }
        var actual_damage = min(damage, max_damage);
        unit.hp = max(1, unit.hp - actual_damage);
        return actual_damage;
    } else {
        // 일반 상태: 정상 피해 적용
        unit.hp = max(0, unit.hp - damage);
        return damage;
    }
}

/// @func should_redirect_damage(target, attacker)
/// @desc 피해를 보호자에게 리다이렉트해야 하는지 확인
/// @return 보호자 유닛 또는 undefined
function should_redirect_damage(target, attacker) {
    // 대상이 보호받는 상태인지 확인
    if (!is_protected(target)) return undefined;

    var protector = get_protector(target);
    if (protector == undefined) return undefined;

    // 보호자가 살아있는지 확인
    if (protector.hp <= 0) return undefined;

    // 보호자가 아직 guardian 상태인지 확인
    if (!is_guardian(protector)) return undefined;

    return protector;
}

/// @func get_status_icon_color(type_id)
/// @desc 상태이상 타입별 아이콘 색상
function get_status_icon_color(type_id) {
    switch (type_id) {
        case "stun": return c_yellow;
        case "root": return c_green;
        case "slow": return c_aqua;
        case "silence": return c_purple;
        case "dot": return c_red;
        case "hot": return c_lime;
        case "weaken": return c_orange;
        case "vulnerable": return c_maroon;
        case "haste": return c_aqua;
        case "might": return c_red;
        case "shield": return c_white;
        // 기사 스킬용
        case "guardian": return c_aqua;
        case "protected": return c_lime;
        case "duel": return c_orange;
        case "immortal": return c_yellow;
        case "buff_defense": return c_silver;
        default:
            // buff_ 접두사 처리
            if (string_pos("buff_", type_id) == 1) {
                return c_lime;
            }
            return c_gray;
    }
}
