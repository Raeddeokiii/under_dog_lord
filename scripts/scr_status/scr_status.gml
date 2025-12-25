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

CC 저항 적용:
- cc_resist: 기절, 속박, 침묵 지속시간 감소
- debuff_resist: 둔화율, 디버프 효과량 감소
*/

/// @func init_status_system()
/// @desc 상태이상 시스템 초기화
function init_status_system() {
    // 상태이상 타입 정의
    global.status_types = {
        // CC (군중제어) - cc_resist 적용
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
        // 디버프 - debuff_resist 적용
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
    if (type_info == undefined) return false;

    var duration = effect_data.duration;
    var amount = variable_struct_exists(effect_data, "amount") ? effect_data.amount : 0;

    // CC 저항 적용 (기절, 속박, 침묵)
    if (variable_struct_exists(type_info, "is_cc") && type_info.is_cc) {
        var cc_reduction = unit.cc_resist / 100;
        duration = duration * (1 - cc_reduction);

        // 지속시간이 0.1초 미만이면 면역
        if (duration < 0.1) {
            // 면역 효과 표시 가능
            return false;
        }
    }

    // 디버프 저항 적용 (둔화, 약화, 취약, DOT)
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
/// @desc CC 완전 면역 여부 (cc_resist 100%)
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
        default: return c_gray;
    }
}
