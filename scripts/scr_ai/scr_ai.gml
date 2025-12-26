/// @description AI 시스템
/// 우선순위 기반 AI + 역할별 가중치

// ============================================
// AI 행동 타입
// ============================================
enum AI_ACTION {
    NONE,
    SKILL_DAMAGE,      // 공격 스킬
    SKILL_HEAL,        // 치유 스킬
    SKILL_BUFF,        // 버프 스킬
    SKILL_CC,          // CC 스킬
    SKILL_DEFENSE,     // 방어 스킬
    BASIC_ATTACK,      // 기본 공격
    MOVE_TO_TARGET,    // 타겟에게 이동
    MOVE_TO_ALLY,      // 아군에게 이동
    RETREAT,           // 후퇴
    IDLE               // 대기
}

// AI 상태
enum AI_STATE {
    IDLE,
    MOVING,
    ATTACKING,
    CASTING,
    RETREATING
}

// ============================================
// 역할별 가중치 테이블
// ============================================
/// @function init_ai_weights()
/// @description AI 가중치 테이블 초기화
function init_ai_weights() {
    global.ai_weights = {};

    // Tank: 방어 우선, 어그로 유지
    global.ai_weights.tank = {
        SKILL_DAMAGE: 2,
        SKILL_HEAL: 0,
        SKILL_BUFF: 1,
        SKILL_CC: 3,
        SKILL_DEFENSE: 8,
        BASIC_ATTACK: 3,
        MOVE_TO_TARGET: 4,
        MOVE_TO_ALLY: 1,
        RETREAT: 1
    };

    // Warrior: 근접 딜러
    global.ai_weights.warrior = {
        SKILL_DAMAGE: 5,
        SKILL_HEAL: 0,
        SKILL_BUFF: 2,
        SKILL_CC: 1,
        SKILL_DEFENSE: 2,
        BASIC_ATTACK: 4,
        MOVE_TO_TARGET: 4,
        MOVE_TO_ALLY: 2,
        RETREAT: 2
    };

    // Assassin: 고가치 타겟 암살
    global.ai_weights.assassin = {
        SKILL_DAMAGE: 5,
        SKILL_HEAL: 0,
        SKILL_BUFF: 2,
        SKILL_CC: 2,
        SKILL_DEFENSE: 1,
        BASIC_ATTACK: 4,
        MOVE_TO_TARGET: 6,
        MOVE_TO_ALLY: 1,
        RETREAT: 3
    };

    // Ranger: 원거리 물리 딜러
    global.ai_weights.ranger = {
        SKILL_DAMAGE: 5,
        SKILL_HEAL: 0,
        SKILL_BUFF: 2,
        SKILL_CC: 2,
        SKILL_DEFENSE: 1,
        BASIC_ATTACK: 4,
        MOVE_TO_TARGET: 2,
        MOVE_TO_ALLY: 2,
        RETREAT: 4
    };

    // Mage: 원거리 마법 딜러
    global.ai_weights.mage = {
        SKILL_DAMAGE: 5,
        SKILL_HEAL: 0,
        SKILL_BUFF: 2,
        SKILL_CC: 4,
        SKILL_DEFENSE: 1,
        BASIC_ATTACK: 3,
        MOVE_TO_TARGET: 2,
        MOVE_TO_ALLY: 2,
        RETREAT: 4
    };

    // Healer: 치유 우선
    global.ai_weights.healer = {
        SKILL_DAMAGE: 1,
        SKILL_HEAL: 10,
        SKILL_BUFF: 3,
        SKILL_CC: 1,
        SKILL_DEFENSE: 2,
        BASIC_ATTACK: 1,
        MOVE_TO_TARGET: 1,
        MOVE_TO_ALLY: 5,
        RETREAT: 6
    };

    // Support: 버프/디버프 전문
    global.ai_weights.support = {
        SKILL_DAMAGE: 2,
        SKILL_HEAL: 3,
        SKILL_BUFF: 8,
        SKILL_CC: 6,
        SKILL_DEFENSE: 3,
        BASIC_ATTACK: 2,
        MOVE_TO_TARGET: 2,
        MOVE_TO_ALLY: 5,
        RETREAT: 4
    };

    // Summoner: 소환수 운용
    global.ai_weights.summoner = {
        SKILL_DAMAGE: 3,
        SKILL_HEAL: 0,
        SKILL_BUFF: 4,
        SKILL_CC: 3,
        SKILL_DEFENSE: 2,
        BASIC_ATTACK: 2,
        MOVE_TO_TARGET: 2,
        MOVE_TO_ALLY: 3,
        RETREAT: 5
    };
}

// ============================================
// AI 초기화
// ============================================
/// @function ai_init_unit(unit)
/// @description 유닛에 AI 데이터 추가
function ai_init_unit(unit) {
    unit.ai = {
        state: AI_STATE.IDLE,
        target: undefined,
        target_type: "enemy",  // "enemy" or "ally"
        current_action: AI_ACTION.NONE,
        path: undefined,
        path_idx: 0,
        think_timer: 0,
        think_interval: 0.2,  // 0.2초마다 의사결정
        attack_timer: 0
    };

    // 역할별 가중치 할당
    var ai_type = unit.ai_type ?? "warrior";
    if (variable_struct_exists(global.ai_weights, ai_type)) {
        unit.ai.weights = global.ai_weights[$ ai_type];
    } else {
        unit.ai.weights = global.ai_weights.warrior;
    }

    return unit;
}

// ============================================
// 타겟 선정
// ============================================
/// @function ai_select_target(unit, enemies, allies)
/// @description 역할에 따른 타겟 선정
function ai_select_target(unit, enemies, allies) {
    // 결투 상태면 결투 상대만 타겟팅 (완전 격리)
    if (is_in_duel(unit)) {
        var duel_opponent = get_duel_opponent(unit);
        if (duel_opponent != undefined && duel_opponent.hp > 0) {
            unit.ai.target = duel_opponent;
            unit.ai.target_type = "enemy";
            return duel_opponent;
        }
    }

    // 결투 중인 적은 타겟 목록에서 제외
    var available_enemies = [];
    for (var i = 0; i < array_length(enemies); i++) {
        var enemy = enemies[i];
        if (can_attack_target(unit, enemy)) {
            array_push(available_enemies, enemy);
        }
    }

    var ai_type = unit.ai_type ?? "warrior";

    switch (ai_type) {
        case "tank":
            // 가장 가까운 적 (어그로 유지)
            unit.ai.target = find_nearest_unit(unit, available_enemies);
            unit.ai.target_type = "enemy";
            break;

        case "warrior":
        case "ranger":
        case "mage":
            // 가장 약한 적 (처치 우선)
            unit.ai.target = find_lowest_hp_unit(unit, available_enemies);
            unit.ai.target_type = "enemy";
            break;

        case "assassin":
            // 고가치 타겟 (원거리, 힐러 우선)
            unit.ai.target = find_high_value_target(unit, available_enemies);
            unit.ai.target_type = "enemy";
            break;

        case "healer":
            // 가장 다친 아군
            var injured = find_injured_ally(unit, allies, 0.9);
            if (injured != undefined) {
                unit.ai.target = injured;
                unit.ai.target_type = "ally";
            } else {
                // 다친 아군 없으면 가장 가까운 적
                unit.ai.target = find_nearest_unit(unit, available_enemies);
                unit.ai.target_type = "enemy";
            }
            break;

        case "support":
            // 상황별 판단
            var enemy_count = array_length(available_enemies);
            if (enemy_count > 3) {
                // 적 많으면 CC 타겟
                unit.ai.target = find_enemy_cluster(unit, available_enemies);
                unit.ai.target_type = "enemy";
            } else {
                // 버프할 아군
                unit.ai.target = find_ally_for_buff(unit, allies);
                unit.ai.target_type = "ally";
            }
            break;

        case "summoner":
            // 가장 가까운 적
            unit.ai.target = find_nearest_unit(unit, available_enemies);
            unit.ai.target_type = "enemy";
            break;

        default:
            unit.ai.target = find_nearest_unit(unit, available_enemies);
            unit.ai.target_type = "enemy";
            break;
    }

    return unit.ai.target;
}

// ============================================
// 타겟 탐색 헬퍼 함수
// ============================================
/// @function find_nearest_unit(unit, targets)
function find_nearest_unit(unit, targets) {
    var nearest = undefined;
    var min_dist = infinity;

    var i = 0;
    repeat (array_length(targets)) {
        var t = targets[i];
        if (t.hp > 0) {
            var dist = point_distance(unit.x, unit.y, t.x, t.y);
            if (dist < min_dist) {
                min_dist = dist;
                nearest = t;
            }
        }
        i++;
    }

    return nearest;
}

/// @function find_lowest_hp_unit(unit, targets)
function find_lowest_hp_unit(unit, targets) {
    var lowest = undefined;
    var min_hp_ratio = infinity;

    var i = 0;
    repeat (array_length(targets)) {
        var t = targets[i];
        if (t.hp > 0) {
            var ratio = t.hp / t.max_hp;
            if (ratio < min_hp_ratio) {
                min_hp_ratio = ratio;
                lowest = t;
            }
        }
        i++;
    }

    return lowest;
}

/// @function find_high_value_target(unit, enemies)
/// @description 고가치 타겟 (힐러 > 원거리 > 일반)
function find_high_value_target(unit, enemies) {
    var best = undefined;
    var best_score = -1;

    var i = 0;
    repeat (array_length(enemies)) {
        var e = enemies[i];
        if (e.hp > 0) {
            var _score = 0;

            // 역할별 가치
            var enemy_type = e.ai_type ?? "warrior";
            switch (enemy_type) {
                case "healer": _score += 100; break;
                case "mage": _score += 80; break;
                case "ranger": _score += 70; break;
                case "support": _score += 60; break;
                default: _score += 30; break;
            }

            // 낮은 HP 보너스
            _score += (1 - e.hp / e.max_hp) * 50;

            // 거리 페널티
            var dist = point_distance(unit.x, unit.y, e.x, e.y);
            _score -= dist * 0.05;

            if (_score > best_score) {
                best_score = _score;
                best = e;
            }
        }
        i++;
    }

    return best;
}

/// @function find_injured_ally(unit, allies, threshold)
/// @description HP 비율이 threshold 미만인 아군 찾기
function find_injured_ally(unit, allies, threshold) {
    var most_injured = undefined;
    var min_ratio = threshold;

    var i = 0;
    repeat (array_length(allies)) {
        var a = allies[i];
        if (a.hp > 0 && a != unit) {
            var ratio = a.hp / a.max_hp;
            if (ratio < min_ratio) {
                min_ratio = ratio;
                most_injured = a;
            }
        }
        i++;
    }

    return most_injured;
}

/// @function find_enemy_cluster(unit, enemies)
/// @description 적이 밀집한 위치의 적 찾기
function find_enemy_cluster(unit, enemies) {
    var best = undefined;
    var best_nearby = 0;

    var i = 0;
    repeat (array_length(enemies)) {
        var e = enemies[i];
        if (e.hp > 0) {
            var nearby = 0;
            var j = 0;
            repeat (array_length(enemies)) {
                var _other = enemies[j];
                if (_other != e && _other.hp > 0) {
                    if (point_distance(e.x, e.y, _other.x, _other.y) < 150) {
                        nearby++;
                    }
                }
                j++;
            }

            if (nearby > best_nearby) {
                best_nearby = nearby;
                best = e;
            }
        }
        i++;
    }

    return best ?? find_nearest_unit(unit, enemies);
}

/// @function find_ally_for_buff(unit, allies)
/// @description 버프할 아군 (딜러 우선)
function find_ally_for_buff(unit, allies) {
    var best = undefined;
    var best_score = -1;

    var i = 0;
    repeat (array_length(allies)) {
        var a = allies[i];
        if (a.hp > 0 && a != unit) {
            var _score = 0;

            var ally_type = a.ai_type ?? "warrior";
            switch (ally_type) {
                case "warrior":
                case "assassin":
                case "ranger":
                case "mage":
                    _score += 80;  // 딜러 우선
                    break;
                case "tank":
                    _score += 50;
                    break;
                default:
                    _score += 30;
                    break;
            }

            // HP 높은 유닛 우선 (죽을 것 같은 유닛에 버프 낭비 X)
            _score += (a.hp / a.max_hp) * 20;

            if (_score > best_score) {
                best_score = _score;
                best = a;
            }
        }
        i++;
    }

    return best;
}

// ============================================
// AI 의사결정
// ============================================
/// @function ai_decide(unit, enemies, allies)
/// @description 가중치 기반 행동 결정
function ai_decide(unit, enemies, allies) {
    var actions = [];
    var weights = unit.ai.weights;
    var target = unit.ai.target;

    // 생존 체크 - HP 30% 미만이면 후퇴 가중치 증가
    var hp_ratio = unit.hp / unit.max_hp;
    var survival_mult = (hp_ratio < 0.3) ? 3 : 1;

    // 1. 스킬 체크
    if (variable_struct_exists(unit, "skills") && is_array(unit.skills)) {
        var i = 0;
        repeat (array_length(unit.skills)) {
            var skill_id = unit.skills[i];
            if (ai_can_use_skill(unit, skill_id, target)) {
                var skill_data = get_skill_data(skill_id);
                if (skill_data != undefined) {
                    var action_type = ai_get_skill_action_type(skill_data);
                    var weight_key = ai_action_to_weight_key(action_type);
                    var base_weight = weights[$ weight_key] ?? 1;

                    var _score = base_weight * ai_calculate_skill_value(unit, skill_data, target);
                    array_push(actions, {
                        type: action_type,
                        action: "skill",
                        skill_id: skill_id,
                        priority: _score
                    });
                }
            }
            i++;
        }
    }

    // 2. 기본 공격 체크
    if (target != undefined && unit.ai.target_type == "enemy") {
        var dist = point_distance(unit.x, unit.y, target.x, target.y);
        var attack_range = unit.attack_range ?? 50;

        if (dist <= attack_range && unit.ai.attack_timer <= 0) {
            var _score = weights.BASIC_ATTACK * (1 + (1 - target.hp / target.max_hp));
            array_push(actions, {
                type: AI_ACTION.BASIC_ATTACK,
                action: "basic_attack",
                priority: _score
            });
        }
    }

    // 3. 이동 체크 (타겟에게)
    if (target != undefined) {
        var dist = point_distance(unit.x, unit.y, target.x, target.y);
        var desired_range = ai_get_desired_range(unit);

        if (dist > desired_range) {
            var weight_key = (unit.ai.target_type == "ally") ? "MOVE_TO_ALLY" : "MOVE_TO_TARGET";
            var _score = weights[$ weight_key] * (dist / 500);  // 거리 비례
            array_push(actions, {
                type: (unit.ai.target_type == "ally") ? AI_ACTION.MOVE_TO_ALLY : AI_ACTION.MOVE_TO_TARGET,
                action: "move",
                priority: _score
            });
        }
    }

    // 4. 후퇴 체크
    if (hp_ratio < 0.3 && unit.ai_type != "tank") {
        var _score = weights.RETREAT * survival_mult * (1 - hp_ratio);
        array_push(actions, {
            type: AI_ACTION.RETREAT,
            action: "retreat",
            priority: _score
        });
    }

    // 5. 대기
    if (array_length(actions) == 0) {
        array_push(actions, {
            type: AI_ACTION.IDLE,
            action: "idle",
            priority: 0
        });
    }

    // 가장 높은 점수 행동 선택
    var best = actions[0];
    var i = 1;
    repeat (array_length(actions) - 1) {
        if (actions[i].priority > best.priority) {
            best = actions[i];
        }
        i++;
    }

    unit.ai.current_action = best.type;
    return best;
}

// ============================================
// AI 헬퍼 함수
// ============================================
/// @function ai_can_use_skill(unit, skill_id, target)
function ai_can_use_skill(unit, skill_id, target) {
    // 쿨다운 체크
    var cd = unit.skill_cooldowns[$ skill_id] ?? 0;
    if (cd > 0) return false;

    // 마나 체크
    var skill_data = get_skill_data(skill_id);
    if (skill_data == undefined) return false;

    var mana_cost = skill_data.mana_cost ?? 0;
    if (unit.mana < mana_cost) return false;

    // 사거리 체크 (타겟 필요한 스킬)
    if (target != undefined && variable_struct_exists(skill_data, "range")) {
        var dist = point_distance(unit.x, unit.y, target.x, target.y);
        if (dist > skill_data.range) return false;
    }

    // 상태이상 체크 (침묵)
    if (has_status_effect(unit, "silence")) return false;

    return true;
}

/// @function ai_get_primary_skill_type(skill_data)
/// @description effects 배열에서 주요 스킬 타입 추출
function ai_get_primary_skill_type(skill_data) {
    if (!variable_struct_exists(skill_data, "effects")) return "damage";
    if (array_length(skill_data.effects) == 0) return "damage";

    // 첫 번째 효과의 타입 반환 (주요 효과)
    var first_effect = skill_data.effects[0];
    if (variable_struct_exists(first_effect, "type")) {
        return first_effect.type;
    }
    return "damage";
}

/// @function ai_get_skill_action_type(skill_data)
function ai_get_skill_action_type(skill_data) {
    var skill_type = ai_get_primary_skill_type(skill_data);

    switch (skill_type) {
        case "damage":
        case "dot":
            return AI_ACTION.SKILL_DAMAGE;
        case "heal":
        case "hot":
            return AI_ACTION.SKILL_HEAL;
        case "buff":
            return AI_ACTION.SKILL_BUFF;
        case "cc":
        case "debuff":
        case "stun":
        case "slow":
        case "root":
        case "silence":
            return AI_ACTION.SKILL_CC;
        case "defense":
        case "shield":
            return AI_ACTION.SKILL_DEFENSE;
        default:
            return AI_ACTION.SKILL_DAMAGE;
    }
}

/// @function ai_action_to_weight_key(action_type)
function ai_action_to_weight_key(action_type) {
    switch (action_type) {
        case AI_ACTION.SKILL_DAMAGE: return "SKILL_DAMAGE";
        case AI_ACTION.SKILL_HEAL: return "SKILL_HEAL";
        case AI_ACTION.SKILL_BUFF: return "SKILL_BUFF";
        case AI_ACTION.SKILL_CC: return "SKILL_CC";
        case AI_ACTION.SKILL_DEFENSE: return "SKILL_DEFENSE";
        case AI_ACTION.BASIC_ATTACK: return "BASIC_ATTACK";
        case AI_ACTION.MOVE_TO_TARGET: return "MOVE_TO_TARGET";
        case AI_ACTION.MOVE_TO_ALLY: return "MOVE_TO_ALLY";
        case AI_ACTION.RETREAT: return "RETREAT";
        default: return "BASIC_ATTACK";
    }
}

/// @function ai_calculate_skill_value(unit, skill_data, target)
function ai_calculate_skill_value(unit, skill_data, target) {
    var value = 1.0;
    var skill_type = ai_get_primary_skill_type(skill_data);

    // 대미지 스킬: 타겟 HP 낮을수록 가치 증가
    if (skill_type == "damage" && target != undefined) {
        value += (1 - target.hp / target.max_hp) * 0.5;
    }

    // 힐 스킬: 타겟 HP 낮을수록 가치 증가
    if (skill_type == "heal" && target != undefined) {
        value += (1 - target.hp / target.max_hp) * 2;
    }

    // AOE 스킬: 추가 가치
    var aoe_radius = skill_data.aoe_radius ?? 0;
    if (aoe_radius > 0) {
        value += 0.5;
    }

    return value;
}

/// @function ai_get_desired_range(unit)
/// @description 역할별 원하는 거리 (유닛/스킬 사거리 기반)
function ai_get_desired_range(unit) {
    var ai_type = unit.ai_type ?? "warrior";
    var base_range = unit.attack_range ?? 50;

    // 스킬 중 가장 긴 사거리 찾기
    var max_skill_range = base_range;
    if (variable_struct_exists(unit, "skills") && array_length(unit.skills) > 0) {
        for (var i = 0; i < array_length(unit.skills); i++) {
            var skill_data = get_skill_data(unit.skills[i]);
            if (skill_data != undefined && variable_struct_exists(skill_data, "range")) {
                max_skill_range = max(max_skill_range, skill_data.range);
            }
        }
    }

    switch (ai_type) {
        case "tank":
        case "warrior":
        case "assassin":
            return base_range;  // 근접: 기본 공격 사거리

        case "ranger":
        case "mage":
            // 원거리: 최대 스킬 사거리의 80% (약간 가까이)
            return max_skill_range * 0.8;

        case "healer":
        case "support":
            // 지원: 최대 스킬 사거리의 70%
            return max_skill_range * 0.7;

        default:
            return base_range;
    }
}

// ============================================
// AI 실행
// ============================================
/// @function ai_execute(unit, decision, delta)
/// @description AI 결정 실행
function ai_execute(unit, decision, delta) {
    switch (decision.action) {
        case "skill":
            ai_execute_skill(unit, decision.skill_id);
            break;

        case "basic_attack":
            ai_execute_basic_attack(unit);
            break;

        case "move":
            ai_execute_move(unit, delta);
            break;

        case "retreat":
            ai_execute_retreat(unit, delta);
            break;

        case "idle":
        default:
            unit.ai.state = AI_STATE.IDLE;
            break;
    }
}

/// @function ai_execute_skill(unit, skill_id)
function ai_execute_skill(unit, skill_id) {
    unit.ai.state = AI_STATE.CASTING;

    // 기존 use_skill 함수 호출 (scr_debug에 있음)
    if (script_exists(asset_get_index("use_skill"))) {
        use_skill(unit, skill_id, unit.ai.target);
    }
}

/// @function ai_execute_basic_attack(unit)
function ai_execute_basic_attack(unit) {
    var target = unit.ai.target;
    if (target == undefined || target.hp <= 0) return;

    unit.ai.state = AI_STATE.ATTACKING;

    // 공격 속도에 따른 쿨다운
    var attack_speed = unit.attack_speed ?? 1.0;
    unit.ai.attack_timer = 1.0 / attack_speed;

    // 대미지 계산 (물리 공격)
    var damage = unit.physical_attack ?? 10;
    var defense = target.physical_defense ?? 0;
    var final_damage = damage * (100 / (100 + defense));

    target.hp = max(0, target.hp - final_damage);
}

/// @function ai_execute_move(unit, delta)
function ai_execute_move(unit, delta) {
    var target = unit.ai.target;
    if (target == undefined) return;

    unit.ai.state = AI_STATE.MOVING;

    // 길찾기 사용
    if (global.pathfinder != undefined) {
        var need_new_path = false;

        // 경로가 없으면 새로 계산
        if (unit.ai.path == undefined || array_length(unit.ai.path) == 0) {
            need_new_path = true;
        }
        // 경로 끝에 도달했으면 새로 계산
        else if (unit.ai.path_idx >= array_length(unit.ai.path)) {
            need_new_path = true;
        }
        // 타겟이 많이 이동했으면 경로 재계산 (50픽셀 이상)
        else {
            var last_wp = unit.ai.path[array_length(unit.ai.path) - 1];
            var target_moved = point_distance(last_wp.x, last_wp.y, target.x, target.y);
            if (target_moved > 50) {
                need_new_path = true;
            }
        }

        // 경로 계산
        if (need_new_path) {
            unit.ai.path = pf_find_path(unit.x, unit.y, target.x, target.y, true);
            unit.ai.path_idx = 0;
        }

        // 경로 따라 이동
        if (unit.ai.path != undefined && unit.ai.path_idx < array_length(unit.ai.path)) {
            var waypoint = unit.ai.path[unit.ai.path_idx];
            var dist = point_distance(unit.x, unit.y, waypoint.x, waypoint.y);

            if (dist < 10) {
                // 웨이포인트 도달 - 다음으로 진행
                unit.ai.path_idx++;
            } else {
                // 웨이포인트로 이동
                var dir = point_direction(unit.x, unit.y, waypoint.x, waypoint.y);
                var move_speed = unit.movement_speed ?? 100;
                unit.x += lengthdir_x(move_speed * delta, dir);
                unit.y += lengthdir_y(move_speed * delta, dir);
            }
        } else {
            // 경로가 없으면 직선 이동
            var dir = point_direction(unit.x, unit.y, target.x, target.y);
            var move_speed = unit.movement_speed ?? 100;
            unit.x += lengthdir_x(move_speed * delta, dir);
            unit.y += lengthdir_y(move_speed * delta, dir);
        }
    } else {
        // 길찾기 없으면 직선 이동
        var dir = point_direction(unit.x, unit.y, target.x, target.y);
        var move_speed = unit.movement_speed ?? 100;
        unit.x += lengthdir_x(move_speed * delta, dir);
        unit.y += lengthdir_y(move_speed * delta, dir);
    }
}

/// @function ai_execute_retreat(unit, delta)
function ai_execute_retreat(unit, delta) {
    unit.ai.state = AI_STATE.RETREATING;

    // 타겟 반대 방향으로 이동
    var target = unit.ai.target;
    if (target != undefined) {
        var dir = point_direction(target.x, target.y, unit.x, unit.y);
        var move_speed = unit.movement_speed ?? 100;
        unit.x += lengthdir_x(move_speed * delta, dir);
        unit.y += lengthdir_y(move_speed * delta, dir);
    }
}

// ============================================
// AI 업데이트 (메인 루프)
// ============================================
/// @function ai_update(unit, enemies, allies, delta)
/// @description 유닛 AI 업데이트
function ai_update(unit, enemies, allies, delta) {
    if (unit.hp <= 0) return;
    if (unit.ai == undefined) ai_init_unit(unit);

    // 공격 타이머 감소
    if (unit.ai.attack_timer > 0) {
        unit.ai.attack_timer -= delta;
    }

    // 의사결정 타이머
    unit.ai.think_timer -= delta;
    if (unit.ai.think_timer <= 0) {
        unit.ai.think_timer = unit.ai.think_interval;

        // 타겟 선정
        ai_select_target(unit, enemies, allies);

        // 행동 결정
        var decision = ai_decide(unit, enemies, allies);

        // 행동 실행
        ai_execute(unit, decision, delta);
    } else {
        // 의사결정 사이에는 현재 행동 계속
        if (unit.ai.state == AI_STATE.MOVING) {
            ai_execute_move(unit, delta);
        }
    }
}

// ============================================
// 스킬 데이터 헬퍼
// ============================================
/// @function get_skill_data(skill_id)
function get_skill_data(skill_id) {
    if (variable_struct_exists(global, "skills") && variable_struct_exists(global.skills, skill_id)) {
        return global.skills[$ skill_id];
    }
    return undefined;
}

// has_status_effect는 scr_status.gml에 정의됨


// ============================================
// M1-3: Rush AI (단순 버전)
// ============================================
// 적 유닛이 아군/성문 방향으로 돌진하는 기본 AI

/// @function ai_rush_update(unit, delta)
/// @desc Rush AI 메인 업데이트 (struct 기반)
function ai_rush_update(unit, delta) {
    if (unit.hp <= 0) return;
    
    // AI 상태 초기화
    if (!variable_struct_exists(unit, "ai_state")) {
        unit.ai_state = "idle";
        unit.ai_target = undefined;
        unit.attack_timer = 0;
    }
    
    // 공격 쿨다운 감소
    if (unit.attack_timer > 0) {
        unit.attack_timer -= delta;
    }
    
    switch (unit.ai_state) {
        case "idle":
            ai_rush_idle(unit);
            break;
        case "move":
            ai_rush_move(unit, delta);
            break;
        case "attack":
            ai_rush_attack(unit, delta);
            break;
    }
}

/// @function ai_rush_idle(unit)
/// @desc Rush AI - 대기 상태: 타겟 찾기
function ai_rush_idle(unit) {
    unit.ai_target = ai_find_rush_target(unit);
    
    if (unit.ai_target != undefined) {
        unit.ai_state = "move";
    }
}

/// @function ai_rush_move(unit, delta)
/// @desc Rush AI - 이동 상태: 타겟에게 돌진
function ai_rush_move(unit, delta) {
    if (!ai_is_valid_target(unit.ai_target)) {
        unit.ai_target = undefined;
        unit.ai_state = "idle";
        return;
    }
    
    var target_x = unit.ai_target.x;
    var target_y = unit.ai_target.y;
    var dist = point_distance(unit.x, unit.y, target_x, target_y);
    var attack_range = unit.attack_range ?? 80;
    
    if (dist <= attack_range) {
        unit.ai_state = "attack";
        return;
    }
    
    var dir = point_direction(unit.x, unit.y, target_x, target_y);
    var move_speed = unit.movement_speed ?? 80;
    var move_dist = move_speed * delta;
    
    unit.x += lengthdir_x(move_dist, dir);
    unit.y += lengthdir_y(move_dist, dir);
    unit.facing = (target_x > unit.x) ? 1 : -1;
}

/// @function ai_rush_attack(unit, delta)
/// @desc Rush AI - 공격 상태
function ai_rush_attack(unit, delta) {
    if (!ai_is_valid_target(unit.ai_target)) {
        unit.ai_target = undefined;
        unit.ai_state = "idle";
        return;
    }
    
    var dist = point_distance(unit.x, unit.y, unit.ai_target.x, unit.ai_target.y);
    var attack_range = unit.attack_range ?? 80;
    
    if (dist > attack_range + 20) {
        unit.ai_state = "move";
        return;
    }
    
    if (unit.attack_timer <= 0) {
        if (variable_struct_exists(unit.ai_target, "is_gate") && unit.ai_target.is_gate) {
            ai_attack_gate(unit);
        } else {
            ai_attack_unit(unit, unit.ai_target);
        }
        
        var attack_speed = unit.attack_speed ?? 1.0;
        unit.attack_timer = 1.0 / max(attack_speed, 0.1);
    }
}

/// @function ai_find_rush_target(unit)
/// @desc 가장 가까운 아군 또는 성문 찾기
function ai_find_rush_target(unit) {
    var nearest = undefined;
    var nearest_dist = 999999;
    
    if (variable_global_exists("ally_units")) {
        for (var i = 0; i < array_length(global.ally_units); i++) {
            var ally = global.ally_units[i];
            if (ally.hp <= 0) continue;
            
            var dist = point_distance(unit.x, unit.y, ally.x, ally.y);
            if (dist < nearest_dist) {
                nearest_dist = dist;
                nearest = ally;
            }
        }
    }
    
    if (variable_global_exists("gate") && global.gate != undefined) {
        if (global.gate.hp > 0) {
            var gate_dist = point_distance(unit.x, unit.y, global.gate.x, global.gate.y);
            if (nearest == undefined || gate_dist < nearest_dist * 0.7) {
                nearest = global.gate;
            }
        }
    }
    
    return nearest;
}

/// @function ai_is_valid_target(target)
function ai_is_valid_target(target) {
    if (target == undefined) return false;
    if (target.hp <= 0) return false;
    return true;
}

/// @function ai_attack_unit(attacker, target)
function ai_attack_unit(attacker, target) {
    var damage_info = calculate_basic_damage(attacker, target);
    apply_damage(target, damage_info, attacker);
}

/// @function ai_attack_gate(attacker)
function ai_attack_gate(attacker) {
    if (!variable_global_exists("gate")) return;
    if (global.gate.hp <= 0) return;
    
    var atk = attacker.physical_attack ?? 50;
    var def = global.gate.defense ?? 50;
    var damage = atk * (100 / (100 + def));
    
    global.gate.hp = max(0, global.gate.hp - damage);
    combat_log((attacker.display_name ?? "적") + " -> 성문: " + string(floor(damage)));
    
    if (global.gate.hp <= 0) {
        combat_log("★ 성문이 파괴되었습니다!");
    }
}

// ============================================
// M1-4: 아군 기본 AI
// ============================================

/// @function ai_ally_basic_update(unit, delta)
function ai_ally_basic_update(unit, delta) {
    if (unit.hp <= 0) return;
    
    if (!variable_struct_exists(unit, "ai_state")) {
        unit.ai_state = "idle";
        unit.ai_target = undefined;
        unit.attack_timer = 0;
    }
    
    if (unit.attack_timer > 0) {
        unit.attack_timer -= delta;
    }
    
    switch (unit.ai_state) {
        case "idle":
            ai_ally_find_target(unit);
            break;
        case "attack":
            ai_ally_attack(unit, delta);
            break;
    }
}

/// @function ai_ally_find_target(unit)
function ai_ally_find_target(unit) {
    var nearest = undefined;
    var nearest_dist = 999999;
    
    if (variable_global_exists("enemy_units")) {
        for (var i = 0; i < array_length(global.enemy_units); i++) {
            var enemy = global.enemy_units[i];
            if (enemy.hp <= 0) continue;
            
            var dist = point_distance(unit.x, unit.y, enemy.x, enemy.y);
            if (dist < nearest_dist) {
                nearest_dist = dist;
                nearest = enemy;
            }
        }
    }
    
    if (nearest != undefined) {
        var attack_range = unit.attack_range ?? 80;
        if (nearest_dist <= attack_range) {
            unit.ai_target = nearest;
            unit.ai_state = "attack";
        }
    }
}

/// @function ai_ally_attack(unit, delta)
function ai_ally_attack(unit, delta) {
    if (!ai_is_valid_target(unit.ai_target)) {
        unit.ai_target = undefined;
        unit.ai_state = "idle";
        return;
    }

    var dist = point_distance(unit.x, unit.y, unit.ai_target.x, unit.ai_target.y);
    var attack_range = unit.attack_range ?? 80;

    if (dist > attack_range) {
        unit.ai_target = undefined;
        unit.ai_state = "idle";
        return;
    }

    if (unit.attack_timer <= 0) {
        ai_attack_unit(unit, unit.ai_target);

        var attack_speed = unit.attack_speed ?? 1.0;
        unit.attack_timer = 1.0 / max(attack_speed, 0.1);
    }
}

// ============================================
// M3-3: Ranged AI (원거리 적)
// ============================================
// 적정 거리를 유지하며 원거리 공격하는 AI

/// @function ai_ranged_update(unit, delta)
/// @desc Ranged AI 메인 업데이트
function ai_ranged_update(unit, delta) {
    if (unit.hp <= 0) return;

    // AI 상태 초기화
    if (!variable_struct_exists(unit, "ai_state")) {
        unit.ai_state = "idle";
        unit.ai_target = undefined;
        unit.attack_timer = 0;
        unit.kite_distance = (unit.attack_range ?? 200) * 0.7;
    }

    if (unit.attack_timer > 0) {
        unit.attack_timer -= delta;
    }

    switch (unit.ai_state) {
        case "idle":
            ai_ranged_idle(unit);
            break;
        case "position":
            ai_ranged_position(unit, delta);
            break;
        case "attack":
            ai_ranged_attack(unit, delta);
            break;
        case "kite":
            ai_ranged_kite(unit, delta);
            break;
    }
}

/// @function ai_ranged_idle(unit)
function ai_ranged_idle(unit) {
    unit.ai_target = find_target_by_priority(unit, "nearest");

    if (unit.ai_target != undefined) {
        unit.ai_state = "position";
    }
}

/// @function ai_ranged_position(unit, delta)
/// @desc 적정 거리로 위치 조정
function ai_ranged_position(unit, delta) {
    if (!is_valid_target(unit.ai_target)) {
        unit.ai_state = "idle";
        return;
    }

    var dist = point_distance(unit.x, unit.y, unit.ai_target.x, unit.ai_target.y);
    var attack_range = unit.attack_range ?? 200;
    var kite_distance = unit.kite_distance ?? 140;

    // 너무 가까우면 후퇴
    if (dist < kite_distance) {
        unit.ai_state = "kite";
        return;
    }

    // 사거리 내면 공격
    if (dist <= attack_range) {
        unit.ai_state = "attack";
        return;
    }

    // 사거리 밖이면 접근
    var dir = point_direction(unit.x, unit.y, unit.ai_target.x, unit.ai_target.y);
    var move_speed = unit.movement_speed ?? 70;
    unit.x += lengthdir_x(move_speed * delta, dir);
    unit.y += lengthdir_y(move_speed * delta, dir);
    unit.facing = (unit.ai_target.x > unit.x) ? 1 : -1;
}

/// @function ai_ranged_attack(unit, delta)
function ai_ranged_attack(unit, delta) {
    if (!is_valid_target(unit.ai_target)) {
        unit.ai_state = "idle";
        return;
    }

    var dist = point_distance(unit.x, unit.y, unit.ai_target.x, unit.ai_target.y);
    var attack_range = unit.attack_range ?? 200;
    var kite_distance = unit.kite_distance ?? 140;

    // 너무 가까워지면 후퇴
    if (dist < kite_distance) {
        unit.ai_state = "kite";
        return;
    }

    // 사거리 밖이면 재위치
    if (dist > attack_range) {
        unit.ai_state = "position";
        return;
    }

    // 공격
    if (unit.attack_timer <= 0) {
        ai_attack_unit(unit, unit.ai_target);

        var attack_speed = unit.attack_speed ?? 0.8;
        unit.attack_timer = 1.0 / max(attack_speed, 0.1);
    }

    unit.facing = (unit.ai_target.x > unit.x) ? 1 : -1;
}

/// @function ai_ranged_kite(unit, delta)
/// @desc 후퇴 (카이팅)
function ai_ranged_kite(unit, delta) {
    if (!is_valid_target(unit.ai_target)) {
        unit.ai_state = "idle";
        return;
    }

    var dist = point_distance(unit.x, unit.y, unit.ai_target.x, unit.ai_target.y);
    var kite_distance = unit.kite_distance ?? 140;

    // 충분히 멀어지면 공격 재개
    if (dist >= kite_distance * 1.2) {
        unit.ai_state = "attack";
        return;
    }

    // 타겟 반대 방향으로 후퇴
    var dir = point_direction(unit.ai_target.x, unit.ai_target.y, unit.x, unit.y);
    var move_speed = unit.movement_speed ?? 70;
    unit.x += lengthdir_x(move_speed * delta, dir);
    unit.y += lengthdir_y(move_speed * delta, dir);

    // 후퇴 중에도 공격 가능
    var attack_range = unit.attack_range ?? 200;
    if (dist <= attack_range && unit.attack_timer <= 0) {
        ai_attack_unit(unit, unit.ai_target);

        var attack_speed = unit.attack_speed ?? 0.8;
        unit.attack_timer = 1.0 / max(attack_speed, 0.1);
    }

    unit.facing = (unit.ai_target.x > unit.x) ? 1 : -1;
}

// ============================================
// M3-3: Boss AI
// ============================================
// 보스 유닛용 AI - 패턴 기반 행동

/// @function ai_boss_update(unit, delta)
/// @desc Boss AI 메인 업데이트
function ai_boss_update(unit, delta) {
    if (unit.hp <= 0) return;

    // AI 상태 초기화
    if (!variable_struct_exists(unit, "ai_state")) {
        unit.ai_state = "idle";
        unit.ai_target = undefined;
        unit.attack_timer = 0;
        unit.pattern_timer = 0;
        unit.current_pattern = 0;
        unit.enraged = false;
    }

    if (unit.attack_timer > 0) {
        unit.attack_timer -= delta;
    }

    if (unit.pattern_timer > 0) {
        unit.pattern_timer -= delta;
    }

    // 분노 체크 (HP 30% 이하)
    if (!unit.enraged && unit.hp / unit.max_hp <= 0.3) {
        unit.enraged = true;
        unit.physical_attack *= 1.5;
        unit.attack_speed *= 1.3;
        combat_log("★ " + (unit.display_name ?? "보스") + " 분노!");
    }

    switch (unit.ai_state) {
        case "idle":
            ai_boss_idle(unit);
            break;
        case "move":
            ai_boss_move(unit, delta);
            break;
        case "attack":
            ai_boss_attack(unit, delta);
            break;
        case "skill":
            ai_boss_skill(unit, delta);
            break;
    }
}

/// @function ai_boss_idle(unit)
function ai_boss_idle(unit) {
    unit.ai_target = find_target_by_priority(unit, "highest_threat");

    if (unit.ai_target != undefined) {
        unit.ai_state = "move";
    }
}

/// @function ai_boss_move(unit, delta)
function ai_boss_move(unit, delta) {
    if (!is_valid_target(unit.ai_target)) {
        unit.ai_state = "idle";
        return;
    }

    var dist = point_distance(unit.x, unit.y, unit.ai_target.x, unit.ai_target.y);
    var attack_range = unit.attack_range ?? 80;

    if (dist <= attack_range) {
        unit.ai_state = "attack";
        return;
    }

    // 타겟에게 이동
    var dir = point_direction(unit.x, unit.y, unit.ai_target.x, unit.ai_target.y);
    var move_speed = unit.movement_speed ?? 50;
    unit.x += lengthdir_x(move_speed * delta, dir);
    unit.y += lengthdir_y(move_speed * delta, dir);
    unit.facing = (unit.ai_target.x > unit.x) ? 1 : -1;
}

/// @function ai_boss_attack(unit, delta)
function ai_boss_attack(unit, delta) {
    if (!is_valid_target(unit.ai_target)) {
        unit.ai_state = "idle";
        return;
    }

    var dist = point_distance(unit.x, unit.y, unit.ai_target.x, unit.ai_target.y);
    var attack_range = unit.attack_range ?? 80;

    if (dist > attack_range) {
        unit.ai_state = "move";
        return;
    }

    // 패턴 스킬 사용 (쿨다운 완료 시)
    if (unit.pattern_timer <= 0) {
        unit.ai_state = "skill";
        return;
    }

    // 기본 공격
    if (unit.attack_timer <= 0) {
        ai_attack_unit(unit, unit.ai_target);

        var attack_speed = unit.attack_speed ?? 0.7;
        unit.attack_timer = 1.0 / max(attack_speed, 0.1);
    }

    unit.facing = (unit.ai_target.x > unit.x) ? 1 : -1;
}

/// @function ai_boss_skill(unit, delta)
/// @desc 보스 패턴 스킬 사용
function ai_boss_skill(unit, delta) {
    var pattern = unit.current_pattern;

    switch (pattern) {
        case 0:
            // 패턴 1: 강타 (고 데미지)
            ai_boss_heavy_strike(unit);
            break;

        case 1:
            // 패턴 2: 휩쓸기 (AOE)
            ai_boss_sweep(unit);
            break;

        case 2:
            // 패턴 3: 전쟁의 함성 (자기 버프)
            ai_boss_war_cry(unit);
            break;
    }

    // 다음 패턴
    unit.current_pattern = (unit.current_pattern + 1) % 3;

    // 패턴 쿨다운 (분노 시 더 빠름)
    unit.pattern_timer = unit.enraged ? 4 : 6;

    unit.ai_state = "attack";
}

/// @function ai_boss_heavy_strike(unit)
/// @desc 보스 강타 - 현재 타겟에게 2배 데미지
function ai_boss_heavy_strike(unit) {
    if (!is_valid_target(unit.ai_target)) return;

    var base_damage = (unit.physical_attack ?? 50) * 2;
    var defense = unit.ai_target.physical_defense ?? 0;
    var damage = base_damage * (100 / (100 + defense));

    var damage_info = {
        damage: damage,
        damage_type: "physical",
        is_crit: false
    };

    apply_damage(unit.ai_target, damage_info, unit);
    combat_log("★ " + (unit.display_name ?? "보스") + " 강타!");
}

/// @function ai_boss_sweep(unit)
/// @desc 보스 휩쓸기 - 주변 모든 적에게 데미지
function ai_boss_sweep(unit) {
    var targets = get_units_in_radius(unit.x, unit.y, 150, "ally");
    var base_damage = unit.physical_attack ?? 50;

    for (var i = 0; i < array_length(targets); i++) {
        var target = targets[i];
        var defense = target.physical_defense ?? 0;
        var damage = base_damage * (100 / (100 + defense));

        var damage_info = {
            damage: damage,
            damage_type: "physical",
            is_crit: false
        };

        apply_damage(target, damage_info, unit);
    }

    if (array_length(targets) > 0) {
        combat_log("★ " + (unit.display_name ?? "보스") + " 휩쓸기! (" + string(array_length(targets)) + "명 적중)");
    }
}

/// @function ai_boss_war_cry(unit)
/// @desc 보스 전쟁의 함성 - 자기 버프
function ai_boss_war_cry(unit) {
    // 10초간 공격력 50% 증가
    var buff = {
        type: "buff",
        stat: "physical_attack",
        amount: 50,
        is_percent: true,
        duration: 10,
        remaining: 10
    };

    add_status_effect(unit, buff);
    recalculate_unit_stats(unit);

    combat_log("★ " + (unit.display_name ?? "보스") + " 전쟁의 함성!");
}

// ============================================
// M3-4: Tank AI (아군)
// ============================================

/// @function ai_tank_update(unit, delta)
/// @desc Tank AI 메인 업데이트
function ai_tank_update(unit, delta) {
    if (unit.hp <= 0) return;

    // AI 상태 초기화
    if (!variable_struct_exists(unit, "ai_state")) {
        unit.ai_state = "idle";
        unit.ai_target = undefined;
        unit.attack_timer = 0;
        unit.taunt_cooldown = 0;
    }

    if (unit.attack_timer > 0) {
        unit.attack_timer -= delta;
    }

    if (unit.taunt_cooldown > 0) {
        unit.taunt_cooldown -= delta;
    }

    switch (unit.ai_state) {
        case "idle":
            ai_tank_idle(unit);
            break;
        case "engage":
            ai_tank_engage(unit, delta);
            break;
        case "protect":
            ai_tank_protect(unit, delta);
            break;
    }
}

/// @function ai_tank_idle(unit)
function ai_tank_idle(unit) {
    // 가장 가까운 적 찾기
    unit.ai_target = find_target_by_priority(unit, "nearest");

    if (unit.ai_target != undefined) {
        unit.ai_state = "engage";
    }
}

/// @function ai_tank_engage(unit, delta)
function ai_tank_engage(unit, delta) {
    if (!is_valid_target(unit.ai_target)) {
        unit.ai_state = "idle";
        return;
    }

    var dist = point_distance(unit.x, unit.y, unit.ai_target.x, unit.ai_target.y);
    var attack_range = unit.attack_range ?? 60;

    // 도발 사용 (쿨다운 완료 시)
    if (dist <= 200 && unit.taunt_cooldown <= 0) {
        ai_tank_taunt(unit);
        unit.taunt_cooldown = 10;
    }

    // 공격
    if (dist <= attack_range && unit.attack_timer <= 0) {
        ai_attack_unit(unit, unit.ai_target);

        var attack_speed = unit.attack_speed ?? 0.8;
        unit.attack_timer = 1.0 / max(attack_speed, 0.1);
    }

    unit.facing = (unit.ai_target.x > unit.x) ? 1 : -1;
}

/// @function ai_tank_protect(unit, delta)
/// @desc 아군 보호 (취약한 아군 근처로 이동)
function ai_tank_protect(unit, delta) {
    // 보호할 대상이 없으면 전투 복귀
    var ally = find_ally_lowest_hp_percent(unit, 300);
    if (ally == undefined) {
        unit.ai_state = "idle";
        return;
    }

    // 아군 근처로 이동
    var dist = point_distance(unit.x, unit.y, ally.x, ally.y);
    if (dist > 80) {
        var dir = point_direction(unit.x, unit.y, ally.x, ally.y);
        var move_speed = unit.movement_speed ?? 50;
        unit.x += lengthdir_x(move_speed * delta, dir);
        unit.y += lengthdir_y(move_speed * delta, dir);
    }

    // 근처 적 도발
    if (unit.taunt_cooldown <= 0) {
        ai_tank_taunt(unit);
        unit.taunt_cooldown = 10;
    }
}

/// @function ai_tank_taunt(unit)
/// @desc 주변 적 도발
function ai_tank_taunt(unit) {
    var enemies = get_units_in_radius(unit.x, unit.y, 200, "enemy");

    for (var i = 0; i < array_length(enemies); i++) {
        var enemy = enemies[i];
        enemy.ai_target = unit;
        enemy.taunt_source = unit;
        enemy.taunt_remaining = 3;
    }

    if (array_length(enemies) > 0) {
        combat_log((unit.display_name ?? "탱커") + " 도발! (" + string(array_length(enemies)) + "명)");
    }
}

// ============================================
// M3-4: Healer AI (아군)
// ============================================

/// @function ai_healer_update(unit, delta)
/// @desc Healer AI 메인 업데이트
function ai_healer_update(unit, delta) {
    if (unit.hp <= 0) return;

    // AI 상태 초기화
    if (!variable_struct_exists(unit, "ai_state")) {
        unit.ai_state = "idle";
        unit.ai_target = undefined;
        unit.attack_timer = 0;
        unit.heal_cooldown = 0;
    }

    if (unit.attack_timer > 0) {
        unit.attack_timer -= delta;
    }

    if (unit.heal_cooldown > 0) {
        unit.heal_cooldown -= delta;
    }

    // 마나 재생
    update_unit_mana(unit, delta);

    switch (unit.ai_state) {
        case "idle":
            ai_healer_idle(unit);
            break;
        case "heal":
            ai_healer_heal(unit, delta);
            break;
        case "attack":
            ai_healer_attack(unit, delta);
            break;
    }
}

/// @function ai_healer_idle(unit)
function ai_healer_idle(unit) {
    // 치유 필요한 아군 찾기 (HP 80% 미만)
    var injured = find_ally_lowest_hp_percent(unit, unit.attack_range ?? 300);

    if (injured != undefined && injured.hp / injured.max_hp < 0.8) {
        unit.ai_target = injured;
        unit.ai_state = "heal";
        return;
    }

    // 치유할 대상 없으면 공격
    var enemy = find_target_by_priority(unit, "nearest");
    if (enemy != undefined) {
        unit.ai_target = enemy;
        unit.ai_state = "attack";
    }
}

/// @function ai_healer_heal(unit, delta)
function ai_healer_heal(unit, delta) {
    // 타겟 유효성 체크
    if (!is_valid_target(unit.ai_target)) {
        unit.ai_state = "idle";
        return;
    }

    // HP 회복 완료되면 다른 대상 찾기
    if (unit.ai_target.hp / unit.ai_target.max_hp >= 0.9) {
        unit.ai_state = "idle";
        return;
    }

    var dist = point_distance(unit.x, unit.y, unit.ai_target.x, unit.ai_target.y);
    var heal_range = unit.attack_range ?? 300;

    // 사거리 밖이면 이동
    if (dist > heal_range) {
        var dir = point_direction(unit.x, unit.y, unit.ai_target.x, unit.ai_target.y);
        var move_speed = unit.movement_speed ?? 60;
        unit.x += lengthdir_x(move_speed * delta, dir);
        unit.y += lengthdir_y(move_speed * delta, dir);
        return;
    }

    // 힐 스킬 사용
    if (unit.heal_cooldown <= 0 && (unit.mana ?? 100) >= 30) {
        ai_healer_cast_heal(unit, unit.ai_target);
        unit.heal_cooldown = 3;
    }
}

/// @function ai_healer_cast_heal(unit, target)
function ai_healer_cast_heal(unit, target) {
    // 힐 스킬 사용 시도
    if (variable_global_exists("skill_templates")) {
        var success = use_skill(unit, "heal", target);
        if (success) return;
    }

    // 스킬 없으면 기본 힐
    var heal_amount = (unit.magic_attack ?? 30) * 1.5;
    var old_hp = target.hp;
    target.hp = min(target.hp + heal_amount, target.max_hp);
    var actual_heal = target.hp - old_hp;

    if (actual_heal > 0) {
        show_damage_number(target.x, target.y, actual_heal, c_lime);
        combat_log((unit.display_name ?? "힐러") + " → " + (target.display_name ?? "아군") + " 치유 +" + string(floor(actual_heal)));
    }

    // 마나 소모
    unit.mana = max(0, (unit.mana ?? 100) - 30);
}

/// @function ai_healer_attack(unit, delta)
function ai_healer_attack(unit, delta) {
    // 치유 필요한 아군 체크
    var injured = find_ally_lowest_hp_percent(unit, unit.attack_range ?? 300);
    if (injured != undefined && injured.hp / injured.max_hp < 0.7) {
        unit.ai_target = injured;
        unit.ai_state = "heal";
        return;
    }

    if (!is_valid_target(unit.ai_target)) {
        unit.ai_state = "idle";
        return;
    }

    var dist = point_distance(unit.x, unit.y, unit.ai_target.x, unit.ai_target.y);
    var attack_range = unit.attack_range ?? 200;

    if (dist <= attack_range && unit.attack_timer <= 0) {
        ai_attack_unit(unit, unit.ai_target);

        var attack_speed = unit.attack_speed ?? 0.8;
        unit.attack_timer = 1.0 / max(attack_speed, 0.1);
    }
}

// ============================================
// M3-4: DPS AI (아군 - 범용 딜러)
// ============================================

/// @function ai_dps_update(unit, delta)
/// @desc DPS AI 메인 업데이트 (Melee/Ranged 공용)
function ai_dps_update(unit, delta) {
    if (unit.hp <= 0) return;

    // AI 상태 초기화
    if (!variable_struct_exists(unit, "ai_state")) {
        unit.ai_state = "idle";
        unit.ai_target = undefined;
        unit.attack_timer = 0;
        unit.skill_cooldown = 0;
    }

    if (unit.attack_timer > 0) {
        unit.attack_timer -= delta;
    }

    if (unit.skill_cooldown > 0) {
        unit.skill_cooldown -= delta;
    }

    // 마나 재생
    update_unit_mana(unit, delta);

    switch (unit.ai_state) {
        case "idle":
            ai_dps_idle(unit);
            break;
        case "engage":
            ai_dps_engage(unit, delta);
            break;
        case "attack":
            ai_dps_attack(unit, delta);
            break;
    }
}

/// @function ai_dps_idle(unit)
function ai_dps_idle(unit) {
    var priority = "lowest_hp_percent";
    var role = unit.role ?? unit.ai_type ?? "warrior";

    // 암살자는 고가치 타겟 우선
    if (role == "assassin") {
        priority = "backline";
    }

    unit.ai_target = find_target_by_priority(unit, priority);

    if (unit.ai_target != undefined) {
        unit.ai_state = "engage";
    }
}

/// @function ai_dps_engage(unit, delta)
function ai_dps_engage(unit, delta) {
    if (!is_valid_target(unit.ai_target)) {
        unit.ai_state = "idle";
        return;
    }

    var dist = point_distance(unit.x, unit.y, unit.ai_target.x, unit.ai_target.y);
    var attack_range = unit.attack_range ?? 80;

    if (dist <= attack_range) {
        unit.ai_state = "attack";
        return;
    }

    // 타겟에게 이동
    var dir = point_direction(unit.x, unit.y, unit.ai_target.x, unit.ai_target.y);
    var move_speed = unit.movement_speed ?? 80;
    unit.x += lengthdir_x(move_speed * delta, dir);
    unit.y += lengthdir_y(move_speed * delta, dir);
    unit.facing = (unit.ai_target.x > unit.x) ? 1 : -1;
}

/// @function ai_dps_attack(unit, delta)
function ai_dps_attack(unit, delta) {
    if (!is_valid_target(unit.ai_target)) {
        unit.ai_state = "idle";
        return;
    }

    var dist = point_distance(unit.x, unit.y, unit.ai_target.x, unit.ai_target.y);
    var attack_range = unit.attack_range ?? 80;

    if (dist > attack_range + 30) {
        unit.ai_state = "engage";
        return;
    }

    // 스킬 사용 (쿨다운 완료 시)
    if (unit.skill_cooldown <= 0 && (unit.mana ?? 100) >= 20) {
        var used = ai_dps_use_skill(unit);
        if (used) {
            unit.skill_cooldown = 4;
        }
    }

    // 기본 공격
    if (unit.attack_timer <= 0) {
        ai_attack_unit(unit, unit.ai_target);

        var attack_speed = unit.attack_speed ?? 1.0;
        unit.attack_timer = 1.0 / max(attack_speed, 0.1);
    }

    unit.facing = (unit.ai_target.x > unit.x) ? 1 : -1;
}

/// @function ai_dps_use_skill(unit)
/// @desc DPS 스킬 사용 시도
function ai_dps_use_skill(unit) {
    if (!variable_global_exists("skill_templates")) return false;

    var role = unit.role ?? unit.ai_type ?? "warrior";
    var skill_id = "";

    switch (role) {
        case "warrior":
            skill_id = "power_strike";
            break;
        case "assassin":
            skill_id = "assassinate";
            break;
        case "ranger":
            skill_id = "multishot";
            break;
        case "mage":
            skill_id = "fireball";
            break;
        default:
            return false;
    }

    return use_skill(unit, skill_id, unit.ai_target);
}
