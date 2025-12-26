/// @file scr_talent.gml
/// @desc 재능 시스템 - 이벤트 기반 + 최적화

/*
==============================================
재능 트리거 구조: EVENT:SOURCE:FILTER:RANGE
==============================================
EVENT  - 이벤트 타입 (DEATH, HIT, CRIT, KILL 등)
SOURCE - 이벤트 주체 (SELF, ALLY, ENEMY, ANY)
FILTER - 세부 필터 (SUMMON, RACE:UNDEAD, TAG:FIRE 등)
RANGE  - 범위 (-1=전역, 0=자신, 3=반경3칸)

예시:
- ON_CRIT              = 자신이 치명타 시
- DEATH:ENEMY:ANY:3    = 반경 3칸 내 적 사망 시
- KILL:SELF:SUMMON:-1  = 자신이 소환물 처치 시
==============================================
*/

// ============================================
// 상수 정의
// ============================================

#macro TALENT_CELL_SIZE 64  // 공간 해싱 셀 크기

// 이벤트 타입
enum TALENT_EVENT {
    NONE = 0,
    // 유닛 이벤트
    HIT,            // 공격 적중
    CRIT,           // 치명타
    KILL,           // 처치
    DEATH,          // 사망
    SPAWN,          // 스폰
    DODGE,          // 회피
    BLOCK,          // 방어
    HEAL,           // 회복
    SKILL_USE,      // 스킬 사용
    HIT_TAKEN,      // 피격
    // 상태 이벤트
    HP_THRESHOLD,   // HP 임계값 도달
    MP_THRESHOLD,   // MP 임계값 도달
    STATE_CHANGE,   // 상태 변화
    // 전투 이벤트
    BATTLE_START,   // 전투 시작
    BATTLE_END,     // 전투 종료
    WAVE_START,     // 웨이브 시작
    WAVE_END,       // 웨이브 종료
    // 월드 이벤트
    TILE_CHANGE,    // 타일 변화
    STRUCT_DESTROY, // 구조물 파괴
    STRUCT_BUILD,   // 구조물 건설
    // 상시
    ALWAYS,         // 패시브
    // 조건부 상시
    CONDITIONAL     // 조건 충족 중
}

// 이벤트 소스
enum TALENT_SOURCE {
    SELF = 0,
    ALLY,
    ENEMY,
    ANY,
    OWNER   // 소환 주인
}

// ============================================
// 초기화
// ============================================

/// @function init_talent_system()
/// @desc 재능 시스템 초기화
function init_talent_system() {
    // 이벤트 구독 맵 (이벤트별로 관련 재능 ID 저장)
    global.talent_subscribers = {};

    // 이벤트 큐 (배치 처리용)
    global.talent_event_queue = [];

    // 공간 해싱 그리드
    global.talent_spatial_grid = {};

    // 트리거 파싱 캐시
    global.talent_trigger_cache = {};

    // 효과 파싱 캐시
    global.talent_effect_cache = {};

    // 이벤트 이름 → enum 매핑
    global.talent_event_map = {
        "ON_HIT": TALENT_EVENT.HIT,
        "ON_CRIT": TALENT_EVENT.CRIT,
        "ON_KILL": TALENT_EVENT.KILL,
        "ON_DEATH": TALENT_EVENT.DEATH,
        "DEATH": TALENT_EVENT.DEATH,
        "ON_DODGE": TALENT_EVENT.DODGE,
        "ON_BLOCK": TALENT_EVENT.BLOCK,
        "ON_HEAL": TALENT_EVENT.HEAL,
        "ON_SKILL": TALENT_EVENT.SKILL_USE,
        "ON_HIT_TAKEN": TALENT_EVENT.HIT_TAKEN,
        "ON_SPAWN": TALENT_EVENT.SPAWN,
        "KILL": TALENT_EVENT.KILL,
        "HIT": TALENT_EVENT.HIT,
        "SPAWN": TALENT_EVENT.SPAWN,
        "BATTLE_START": TALENT_EVENT.BATTLE_START,
        "BATTLE_END": TALENT_EVENT.BATTLE_END,
        "WAVE_START": TALENT_EVENT.WAVE_START,
        "WAVE_END": TALENT_EVENT.WAVE_END,
        "ALWAYS": TALENT_EVENT.ALWAYS,
        "TILE_CHANGE": TALENT_EVENT.TILE_CHANGE,
        "STRUCT_DESTROY": TALENT_EVENT.STRUCT_DESTROY,
        "TRANSFORM": TALENT_EVENT.TILE_CHANGE,
        "DESTROY": TALENT_EVENT.STRUCT_DESTROY
    };

    // 조건 체크 함수 등록
    global.talent_condition_checkers = {};
    _register_default_conditions();

    // 효과 실행 함수 등록
    global.talent_effect_executors = {};
    _register_default_effects();

    // 재능 데이터 기반으로 구독 맵 생성
    _build_subscription_map();

    show_debug_message("Talent system initialized");
}

/// @function _build_subscription_map()
/// @desc 재능 데이터 기반 구독 맵 생성
function _build_subscription_map() {
    var talent_ids = variable_struct_get_names(global.talents);

    for (var i = 0; i < array_length(talent_ids); i++) {
        var talent_id = talent_ids[i];
        var talent = global.talents[$ talent_id];

        // 트리거 파싱
        var parsed = talent_parse_trigger(talent.trigger);

        // 캐시에 저장
        global.talent_trigger_cache[$ talent_id] = parsed;

        // 효과 캐시 (CSV 컬럼에서 직접 읽으므로 파싱 불필요)
        global.talent_effect_cache[$ talent_id] = {
            type: talent.effect_type,
            stat1: talent.stat1,
            value1: talent.value1,
            stat2: talent.stat2,
            value2: talent.value2,
            duration: talent.duration,
            cc_type: talent.cc_type,
            cc_duration: talent.cc_duration,
            target: talent.target
        };

        // 구독 맵에 추가
        var event_key = string(parsed.event_type);
        if (!variable_struct_exists(global.talent_subscribers, event_key)) {
            global.talent_subscribers[$ event_key] = [];
        }
        array_push(global.talent_subscribers[$ event_key], talent_id);
    }

    show_debug_message("Built subscription map for " + string(array_length(talent_ids)) + " talents");
}

// ============================================
// 트리거 파싱
// ============================================

/// @function talent_parse_trigger(trigger_str)
/// @desc 트리거 문자열 파싱 (EVENT:SOURCE:FILTER:RANGE)
function talent_parse_trigger(trigger_str) {
    var result = {
        event_type: TALENT_EVENT.NONE,
        source: TALENT_SOURCE.SELF,
        filter: "",
        filter_type: "",
        filter_value: "",
        range: 0,
        raw: trigger_str,
        is_conditional: false,
        condition: ""
    };

    // 조건부 트리거 체크 (HP<50% 등)
    if (string_pos("<", trigger_str) > 0 || string_pos(">", trigger_str) > 0 ||
        string_pos("==", trigger_str) > 0 || string_pos("%", trigger_str) > 0) {
        result.event_type = TALENT_EVENT.CONDITIONAL;
        result.is_conditional = true;
        result.condition = trigger_str;
        return result;
    }

    // 콜론으로 분리
    var parts = _split_string(trigger_str, ":");
    var part_count = array_length(parts);

    // 첫 번째: 이벤트 타입
    var event_str = parts[0];
    if (variable_struct_exists(global.talent_event_map, event_str)) {
        result.event_type = global.talent_event_map[$ event_str];
    } else {
        // 알려지지 않은 이벤트는 조건부로 처리
        result.event_type = TALENT_EVENT.CONDITIONAL;
        result.is_conditional = true;
        result.condition = trigger_str;
        return result;
    }

    // 두 번째: 소스 (있으면)
    if (part_count >= 2) {
        var source_str = string_upper(parts[1]);
        switch (source_str) {
            case "SELF": result.source = TALENT_SOURCE.SELF; break;
            case "ALLY": result.source = TALENT_SOURCE.ALLY; break;
            case "ENEMY": result.source = TALENT_SOURCE.ENEMY; break;
            case "ANY": result.source = TALENT_SOURCE.ANY; break;
            case "OWNER": result.source = TALENT_SOURCE.OWNER; break;
            default: result.source = TALENT_SOURCE.ANY; break;
        }
    }

    // 세 번째: 필터 (있으면)
    if (part_count >= 3) {
        result.filter = parts[2];
        // 필터 세부 파싱 (RACE:UNDEAD, TAG:FIRE 등)
        var filter_parts = _split_string(result.filter, "=");
        if (array_length(filter_parts) >= 2) {
            result.filter_type = filter_parts[0];
            result.filter_value = filter_parts[1];
        } else {
            result.filter_type = result.filter;
            result.filter_value = "";
        }
    }

    // 네 번째: 범위 (있으면)
    if (part_count >= 4) {
        result.range = real(parts[3]);
    }

    return result;
}

// ============================================
// 유닛 재능 초기화
// ============================================

/// @function talent_init_unit(unit)
/// @desc 유닛에 재능 시스템 데이터 추가
function talent_init_unit(unit) {
    unit.talent_data = {
        // 쿨다운 관리
        cooldowns: {},

        // 패시브 보너스 캐시
        passive_bonuses: {
            hp: 0, hp_percent: 0,
            atk: 0, atk_percent: 0,
            def: 0, def_percent: 0,
            mag_atk: 0, mag_atk_percent: 0,
            mag_def: 0, mag_def_percent: 0,
            speed: 0, speed_percent: 0,
            crit: 0, crit_dmg: 0,
            dodge: 0, accuracy: 0,
            lifesteal: 0,
            cc_resist: 0, debuff_resist: 0,
            dmg_bonus: 0, dmg_reduction: 0
        },
        passive_dirty: true,

        // 상태 캐싱
        last_hp_percent: 100,
        last_mp_percent: 100,

        // 스택 추적
        stacks: {},

        // 임시 버프
        temp_buffs: [],

        // 히트 카운트 (콤보용)
        hit_count: 0,

        // 킬 카운트
        kill_count: 0
    };

    // 패시브 재능 적용
    if (variable_struct_exists(unit, "talent") && unit.talent != "") {
        talent_apply_passive(unit);
    }
}

/// @function talent_apply_passive(unit)
/// @desc 패시브 재능 효과 계산 및 적용 (컬럼 기반, 조건부 포함)
function talent_apply_passive(unit) {
    if (unit.talent_data == undefined) talent_init_unit(unit);

    // 보너스 초기화
    var bonuses = unit.talent_data.passive_bonuses;
    var keys = variable_struct_get_names(bonuses);
    for (var i = 0; i < array_length(keys); i++) {
        bonuses[$ keys[i]] = 0;
    }

    // 재능이 없으면 종료
    if (!variable_struct_exists(unit, "talent") || unit.talent == "") {
        unit.talent_data.passive_dirty = false;
        return;
    }

    var talent = get_talent(unit.talent);
    if (talent == undefined) {
        unit.talent_data.passive_dirty = false;
        return;
    }

    // 캐시된 트리거 정보 가져오기
    var parsed_trigger = global.talent_trigger_cache[$ unit.talent] ?? talent_parse_trigger(talent.trigger);

    // 효과 적용 여부 결정
    var should_apply = false;

    // ALWAYS 타입: 항상 적용
    if (parsed_trigger.event_type == TALENT_EVENT.ALWAYS) {
        should_apply = true;
    }
    // 조건부 타입: 조건 충족 시 적용
    else if (parsed_trigger.is_conditional) {
        should_apply = talent_check_condition(unit, parsed_trigger.condition);
    }

    // 조건 미충족 시 종료 (보너스는 이미 0으로 초기화됨)
    if (!should_apply) {
        unit.talent_data.passive_dirty = false;
        return;
    }

    // 효과 적용 (컬럼 기반)
    var eff = global.talent_effect_cache[$ unit.talent];
    if (eff == undefined) {
        unit.talent_data.passive_dirty = false;
        return;
    }

    // 유닛의 주 공격력 타입 결정 (직업 tags 기반)
    var is_magic_user = _is_magic_class(unit);

    // 첫 번째 스탯 적용
    if (eff.stat1 != "" && eff.value1 != 0) {
        _apply_passive_stat_smart(bonuses, eff.stat1, eff.value1, is_magic_user);
    }

    // 두 번째 스탯 적용 (combo 타입)
    if (eff.stat2 != "" && eff.value2 != 0) {
        _apply_passive_stat_smart(bonuses, eff.stat2, eff.value2, is_magic_user);
    }

    unit.talent_data.passive_dirty = false;
}

/// @function _is_magic_class(unit)
/// @desc 유닛이 마법 직업인지 확인
function _is_magic_class(unit) {
    if (!variable_struct_exists(unit, "class") || unit.class == "") return false;

    var cls = get_class_bonus(unit.class);
    if (cls == undefined) return false;

    // tags에 "magic"이 있으면 마법 직업
    if (variable_struct_exists(cls, "tags")) {
        for (var i = 0; i < array_length(cls.tags); i++) {
            if (cls.tags[i] == "magic" || cls.tags[i] == "caster") {
                return true;
            }
        }
    }

    return false;
}

/// @function _apply_passive_stat_smart(bonuses, stat, value, is_magic)
/// @desc 패시브 스탯 보너스 적용 (ATK는 직업에 따라 물리/마법 분기)
function _apply_passive_stat_smart(bonuses, stat, value, is_magic) {
    var upper_stat = string_upper(stat);

    // ATK는 직업에 따라 물리 또는 마법으로 분기
    if (upper_stat == "ATK") {
        if (is_magic) {
            bonuses.mag_atk_percent += value;
        } else {
            bonuses.atk_percent += value;
        }
        return;
    }

    // DEF는 양쪽 모두에 적용
    if (upper_stat == "DEF") {
        bonuses.def_percent += value;
        bonuses.mag_def_percent += value * 0.5;  // 마방은 절반
        return;
    }

    // 나머지는 기존 로직
    _apply_passive_stat(bonuses, stat, value);
}

/// @function _apply_passive_stat(bonuses, stat, value)
/// @desc 패시브 스탯 보너스 적용
function _apply_passive_stat(bonuses, stat, value) {
    switch (string_upper(stat)) {
        case "ATK":
        case "PHYS_ATK":
            bonuses.atk_percent += value;
            break;
        case "MAG_ATK":
        case "MAGIC_ATK":
            bonuses.mag_atk_percent += value;
            break;
        case "DEF":
        case "PHYS_DEF":
            bonuses.def_percent += value;
            break;
        case "MAG_DEF":
        case "MAGIC_DEF":
            bonuses.mag_def_percent += value;
            break;
        case "HP":
        case "HP_MAX":
            bonuses.hp_percent += value;
            break;
        case "SPD":
        case "SPEED":
            bonuses.speed_percent += value;
            break;
        case "CRIT":
            bonuses.crit += value;
            break;
        case "CRIT_DMG":
            bonuses.crit_dmg += value;
            break;
        case "DODGE":
            bonuses.dodge += value;
            break;
        case "HIT":
        case "ACCURACY":
            bonuses.accuracy += value;
            break;
        case "LIFESTEAL":
            bonuses.lifesteal += value;
            break;
        case "CC_RESIST":
            bonuses.cc_resist += value;
            break;
        case "DEBUFF_RESIST":
            bonuses.debuff_resist += value;
            break;
        case "DMG":
        case "PHYS_DMG_REDUCE":
        case "MAGIC_DMG_REDUCE":
            bonuses.dmg_reduction += value;
            break;
        case "ALL_STAT":
            bonuses.hp_percent += value;
            bonuses.atk_percent += value;
            bonuses.def_percent += value;
            bonuses.mag_atk_percent += value;
            bonuses.mag_def_percent += value;
            break;
        case "ELEM_DMG":
            bonuses.dmg_bonus += value;
            break;
        case "KNOCKBACK":
        case "HEAL_POWER":
        case "HP_REGEN":
        case "EXP":
        case "GOLD":
        case "ITEM_DROP":
            // 이 스탯들은 별도 처리
            break;
    }
}

// ============================================
// 이벤트 발생
// ============================================

/// @function talent_fire_event(event_type, context)
/// @desc 이벤트 발생 - 배치 처리를 위해 큐에 추가
function talent_fire_event(event_type, context) {
    array_push(global.talent_event_queue, {
        event_type: event_type,
        context: context,
        timestamp: current_time
    });
}

/// @function talent_process_events()
/// @desc 프레임 끝에 배치 처리
function talent_process_events() {
    var queue = global.talent_event_queue;
    var queue_len = array_length(queue);

    if (queue_len == 0) return;

    for (var i = 0; i < queue_len; i++) {
        var evt = queue[i];
        _process_single_event(evt.event_type, evt.context);
    }

    // 큐 초기화
    global.talent_event_queue = [];
}

/// @function _process_single_event(event_type, context)
/// @desc 단일 이벤트 처리
function _process_single_event(event_type, context) {
    // 구독자 가져오기
    var event_key = string(event_type);
    if (!variable_struct_exists(global.talent_subscribers, event_key)) return;

    var subscribers = global.talent_subscribers[$ event_key];

    // 이벤트 영향 받는 유닛들 가져오기
    var affected_units = _get_affected_units(context);

    for (var u = 0; u < array_length(affected_units); u++) {
        var unit = affected_units[u];

        // 유닛에 재능이 없으면 스킵
        if (!variable_struct_exists(unit, "talent") || unit.talent == "") continue;

        // 해당 유닛의 재능이 구독자 목록에 있는지 확인
        var unit_talent = unit.talent;
        var is_subscriber = false;
        for (var s = 0; s < array_length(subscribers); s++) {
            if (subscribers[s] == unit_talent) {
                is_subscriber = true;
                break;
            }
        }

        if (!is_subscriber) continue;

        // 재능 발동 체크
        _try_trigger_talent(unit, unit_talent, event_type, context);
    }
}

/// @function _get_affected_units(context)
/// @desc 이벤트 영향 받는 유닛 목록
function _get_affected_units(context) {
    var units = [];

    // 컨텍스트에서 관련 유닛 추출
    if (variable_struct_exists(context, "source") && context.source != undefined) {
        array_push(units, context.source);
    }
    if (variable_struct_exists(context, "target") && context.target != undefined) {
        if (is_array(context.target)) {
            for (var i = 0; i < array_length(context.target); i++) {
                array_push(units, context.target[i]);
            }
        } else {
            array_push(units, context.target);
        }
    }
    if (variable_struct_exists(context, "cause") && context.cause != undefined) {
        array_push(units, context.cause);
    }

    // 전역 이벤트면 모든 유닛
    if (variable_struct_exists(context, "is_global") && context.is_global) {
        if (variable_struct_exists(global, "debug") && variable_struct_exists(global.debug, "allies")) {
            for (var i = 0; i < array_length(global.debug.allies); i++) {
                array_push(units, global.debug.allies[i]);
            }
        }
    }

    return units;
}

/// @function _try_trigger_talent(unit, talent_id, event_type, context)
/// @desc 재능 발동 시도
function _try_trigger_talent(unit, talent_id, event_type, context) {
    var talent = get_talent(talent_id);
    if (talent == undefined) return;

    // 재능 데이터 초기화 체크
    if (unit.talent_data == undefined) talent_init_unit(unit);

    // 1. 쿨다운 체크 (가장 먼저, 가장 빠름)
    var cd = unit.talent_data.cooldowns[$ talent_id] ?? 0;
    if (cd > 0) return;

    // 2. 트리거 조건 체크
    var parsed = global.talent_trigger_cache[$ talent_id];
    if (parsed == undefined) return;

    // 소스 체크
    if (!_check_source(unit, parsed.source, context)) return;

    // 범위 체크
    if (parsed.range > 0) {
        if (!_check_range(unit, context, parsed.range)) return;
    }

    // 필터 체크
    if (parsed.filter != "" && parsed.filter != "ANY") {
        if (!_check_filter(parsed.filter_type, parsed.filter_value, context)) return;
    }

    // 3. 효과 실행
    talent_execute_effects(unit, talent_id, context);

    // 4. 쿨다운 설정
    if (talent.cooldown > 0) {
        unit.talent_data.cooldowns[$ talent_id] = talent.cooldown;
    }
}

/// @function _check_source(unit, source_type, context)
function _check_source(unit, source_type, context) {
    var event_source = context.source ?? undefined;

    switch (source_type) {
        case TALENT_SOURCE.SELF:
            return (event_source == unit);
        case TALENT_SOURCE.ALLY:
            if (event_source == undefined) return false;
            return (event_source.faction == unit.faction && event_source != unit);
        case TALENT_SOURCE.ENEMY:
            if (event_source == undefined) return false;
            return (event_source.faction != unit.faction);
        case TALENT_SOURCE.ANY:
            return true;
        default:
            return true;
    }
}

/// @function _check_range(unit, context, range)
function _check_range(unit, context, range) {
    var event_x = context.x ?? (context.source != undefined ? context.source.x : unit.x);
    var event_y = context.y ?? (context.source != undefined ? context.source.y : unit.y);

    var dist = point_distance(unit.x, unit.y, event_x, event_y);
    return (dist <= range * TALENT_CELL_SIZE);
}

/// @function _check_filter(filter_type, filter_value, context)
function _check_filter(filter_type, filter_value, context) {
    var source = context.source ?? undefined;
    if (source == undefined) return true;

    switch (string_upper(filter_type)) {
        case "SUMMON":
            return (source.is_summon ?? false);
        case "STRUCTURE":
            return (source.is_structure ?? false);
        case "RACE":
            return (source.race == filter_value);
        case "CLASS":
            return (source.class == filter_value);
        case "TAG":
            if (!variable_struct_exists(source, "tags")) return false;
            for (var i = 0; i < array_length(source.tags); i++) {
                if (source.tags[i] == filter_value) return true;
            }
            return false;
        case "ANY":
            return true;
        default:
            return true;
    }
}

// ============================================
// 효과 실행
// ============================================

/// @function _talent_log(talent, effect_type, source, target, stat, value, duration)
/// @desc 전투 로그에 재능 발동 정보 추가
function _talent_log(talent, effect_type, source, target, stat, value, duration) {
    if (talent == undefined) return;
    if (!variable_struct_exists(global, "debug")) return;

    var log_msg = "[재능] " + talent.name_kr + " 발동! ";
    var source_name = source != undefined ? (source.name ?? "유닛") : "";
    var target_name = target != undefined ? (target.name ?? "적") : "";

    switch (effect_type) {
        case "buff":
            log_msg += source_name + " " + stat;
            if (value > 0) log_msg += " +" + string(value) + "%";
            else log_msg += " " + string(value) + "%";
            if (duration > 0) log_msg += " (" + string(duration) + "초)";
            break;

        case "debuff":
            log_msg += target_name + " " + stat + " " + string(value) + "%";
            if (duration > 0) log_msg += " (" + string(duration) + "초)";
            break;

        case "combo":
            log_msg += source_name + " " + stat + " 변경";
            break;

        case "cc":
            log_msg += target_name + " " + stat + " " + string(value) + "초";
            break;

        case "heal":
            log_msg += source_name + " HP +" + string(value) + " 회복";
            break;

        case "damage":
            log_msg += target_name + "에게 " + string(value) + " 추가 피해!";
            break;

        case "dot":
            log_msg += target_name + " " + stat + " " + string(value) + " (" + string(duration) + "초)";
            break;

        case "special":
            log_msg += stat + " 효과";
            if (value != 0) log_msg += " (" + string(value) + ")";
            break;
    }

    debug_log(log_msg);
}

/// @function talent_execute_effects(unit, talent_id, context)
/// @desc 재능 효과 실행 (컬럼 기반)
function talent_execute_effects(unit, talent_id, context) {
    var eff = global.talent_effect_cache[$ talent_id];
    if (eff == undefined) return;

    var talent = get_talent(talent_id);

    // 타겟 결정
    var target = context.target ?? unit;
    if (eff.target == "self") target = unit;
    else if (eff.target == "enemy" && context.target != undefined) target = context.target;

    // 효과 타입별 실행
    switch (eff.type) {
        case "buff":
            _apply_stat_buff(unit, eff.stat1, eff.value1, eff.duration);
            _talent_log(talent, "buff", unit, undefined, eff.stat1, eff.value1, eff.duration);
            break;

        case "debuff":
            if (target != undefined && target != unit) {
                _apply_stat_buff(target, eff.stat1, eff.value1, eff.duration);
                _talent_log(talent, "debuff", unit, target, eff.stat1, eff.value1, eff.duration);
            }
            break;

        case "combo":
            _apply_stat_buff(unit, eff.stat1, eff.value1, eff.duration);
            if (eff.stat2 != "") {
                _apply_stat_buff(unit, eff.stat2, eff.value2, eff.duration);
            }
            _talent_log(talent, "combo", unit, undefined, eff.stat1 + "/" + eff.stat2, eff.value1, eff.duration);
            break;

        case "cc":
            if (target != undefined && eff.cc_type != "") {
                apply_status_effect(target, {
                    type: eff.cc_type,
                    duration: eff.cc_duration,
                    amount: eff.value1,
                    source_id: unit
                });
                _talent_log(talent, "cc", unit, target, eff.cc_type, eff.cc_duration, 0);
            }
            break;

        case "heal":
            var heal_amount = unit.max_hp * eff.value1 / 100;
            unit.hp = min(unit.max_hp, unit.hp + heal_amount);
            _talent_log(talent, "heal", unit, undefined, "HP", floor(heal_amount), 0);
            break;

        case "damage":
            if (target != undefined && target != unit) {
                var dmg = unit.physical_attack * eff.value1 / 100;
                target.hp = max(0, target.hp - dmg);
                _talent_log(talent, "damage", unit, target, "피해", floor(dmg), 0);
            }
            break;

        case "dot":
            if (target != undefined) {
                apply_status_effect(target, {
                    type: "dot",
                    duration: eff.duration,
                    amount: eff.value1,
                    source_id: unit
                });
                _talent_log(talent, "dot", unit, target, "지속피해", eff.value1, eff.duration);
            }
            break;

        case "special":
            _execute_special_effect(unit, target, eff, context);
            _talent_log(talent, "special", unit, target, eff.stat1, eff.value1, 0);
            break;
    }

    // 발동 로그 (디버그 메시지)
    if (talent != undefined) {
        show_debug_message("[TALENT] " + talent.name_kr + " triggered on " + (unit.name ?? "unit"));
    }
}

/// @function _apply_stat_buff(unit, stat, value, duration)
/// @desc 스탯 버프 적용
function _apply_stat_buff(unit, stat, value, duration) {
    if (stat == "" || value == 0) return;

    // 임시 버프 (지속시간 있음)
    if (duration > 0) {
        array_push(unit.talent_data.temp_buffs, {
            stat: stat,
            value: value,
            duration: duration,
            start_time: current_time
        });
        return;
    }

    // 영구 버프 (패시브)
    var bonuses = unit.talent_data.passive_bonuses;
    switch (string_upper(stat)) {
        case "ATK": bonuses.atk_percent += value; break;
        case "DEF": bonuses.def_percent += value; break;
        case "SPD": bonuses.speed_percent += value; break;
        case "HP": bonuses.hp_percent += value; break;
        case "CRIT": bonuses.crit += value; break;
        case "CRIT_DMG": bonuses.crit_dmg += value; break;
        case "DODGE": bonuses.dodge += value; break;
        case "HIT": bonuses.accuracy += value; break;
        case "CC_RESIST": bonuses.cc_resist += value; break;
        case "LIFESTEAL": bonuses.lifesteal += value; break;
        case "DMG": bonuses.dmg_bonus += value; break;
        case "ALL_STAT":
            bonuses.hp_percent += value;
            bonuses.atk_percent += value;
            bonuses.def_percent += value;
            bonuses.mag_atk_percent += value;
            bonuses.mag_def_percent += value;
            break;
    }
}

/// @function _execute_special_effect(unit, target, eff, context)
/// @desc 특수 효과 실행
function _execute_special_effect(unit, target, eff, context) {
    switch (string_upper(eff.stat1)) {
        case "COOLDOWN_RESET":
            var skill_keys = variable_struct_get_names(unit.skill_cooldowns);
            for (var sk = 0; sk < array_length(skill_keys); sk++) {
                unit.skill_cooldowns[$ skill_keys[sk]] = 0;
            }
            break;

        case "COUNTER_ATTACK":
            if (context.source != undefined && context.source != unit) {
                var counter_dmg = unit.physical_attack * 0.5;
                context.source.hp = max(0, context.source.hp - counter_dmg);
            }
            break;

        case "CC_IMMUNE":
            unit.cc_resist = 100;
            break;

        case "REFLECT_DMG":
            if (context.source != undefined && context.damage != undefined) {
                var reflect = context.damage * eff.value1 / 100;
                context.source.hp = max(0, context.source.hp - reflect);
            }
            break;

        case "SURVIVE":
            // 치명적 피해 시 HP 1로 생존 (별도 처리 필요)
            break;

        case "REVIVE":
        case "REVIVE_SELF":
            // 부활 효과 (별도 처리 필요)
            break;
    }
}

// ============================================
// 조건 체크
// ============================================

/// @function _register_default_conditions()
function _register_default_conditions() {
    // HP 조건
    global.talent_condition_checkers[$ "HP<"] = function(unit, value) {
        return (unit.hp / unit.max_hp * 100) < value;
    };
    global.talent_condition_checkers[$ "HP>"] = function(unit, value) {
        return (unit.hp / unit.max_hp * 100) > value;
    };

    // MP 조건
    global.talent_condition_checkers[$ "MP<"] = function(unit, value) {
        return (unit.mana / unit.max_mana * 100) < value;
    };
    global.talent_condition_checkers[$ "MP>"] = function(unit, value) {
        return (unit.mana / unit.max_mana * 100) > value;
    };
    global.talent_condition_checkers[$ "MP_FULL"] = function(unit, value) {
        return unit.mana >= unit.max_mana;
    };
}

/// @function talent_check_condition(unit, condition_str)
/// @desc 조건 문자열 체크
function talent_check_condition(unit, condition_str) {
    // HP<50%, MP>30% 등 파싱

    // HP 조건
    if (string_pos("HP<", condition_str) > 0) {
        var val = real(string_replace(string_replace(condition_str, "HP<", ""), "%", ""));
        return (unit.hp / unit.max_hp * 100) < val;
    }
    if (string_pos("HP>", condition_str) > 0) {
        var val = real(string_replace(string_replace(condition_str, "HP>", ""), "%", ""));
        return (unit.hp / unit.max_hp * 100) > val;
    }

    // MP 조건
    if (string_pos("MP_FULL", condition_str) >= 0) {
        return unit.mana >= unit.max_mana;
    }

    // 적 HP 조건
    if (string_pos("ENEMY_HP<", condition_str) > 0) {
        // 컨텍스트 필요
        return true;
    }

    return true;
}

/// @function talent_check_conditional_talents(unit)
/// @desc 조건부 재능 체크 (상태 기반)
function talent_check_conditional_talents(unit) {
    if (!variable_struct_exists(unit, "talent") || unit.talent == "") return;
    if (unit.talent_data == undefined) talent_init_unit(unit);

    var talent = get_talent(unit.talent);
    if (talent == undefined) return;

    var parsed = global.talent_trigger_cache[$ unit.talent];
    if (parsed == undefined || !parsed.is_conditional) return;

    // 조건 체크
    var condition_met = talent_check_condition(unit, parsed.condition);

    // HP 임계값 체크
    var current_hp_pct = floor(unit.hp / unit.max_hp * 100);
    var last_hp_pct = unit.talent_data.last_hp_percent;

    // 임계값 넘었는지 확인
    var thresholds = [10, 20, 30, 50];
    for (var i = 0; i < array_length(thresholds); i++) {
        var th = thresholds[i];
        if ((last_hp_pct > th && current_hp_pct <= th) ||
            (last_hp_pct <= th && current_hp_pct > th)) {
            // 임계값 통과 - 재능 발동 체크
            if (condition_met) {
                talent_execute_effects(unit, unit.talent, { source: unit, target: unit });
            }
            break;
        }
    }

    unit.talent_data.last_hp_percent = current_hp_pct;
}

// ============================================
// 효과 등록
// ============================================

/// @function _register_default_effects()
function _register_default_effects() {
    // 기본 효과 실행 함수들은 _execute_single_effect에서 처리
}

/// @function talent_register_effect(effect_type, executor_func)
/// @desc 커스텀 효과 실행 함수 등록
function talent_register_effect(effect_type, executor_func) {
    global.talent_effect_executors[$ effect_type] = executor_func;
}

// ============================================
// 쿨다운 관리
// ============================================

/// @function talent_update_cooldowns(unit, delta)
/// @desc 재능 쿨다운 감소
function talent_update_cooldowns(unit, delta) {
    if (unit.talent_data == undefined) return;

    var cd_keys = variable_struct_get_names(unit.talent_data.cooldowns);
    for (var i = 0; i < array_length(cd_keys); i++) {
        var key = cd_keys[i];
        var cd = unit.talent_data.cooldowns[$ key];
        if (cd > 0) {
            unit.talent_data.cooldowns[$ key] = max(0, cd - delta);
        }
    }

    // 임시 버프 만료 체크
    var buffs = unit.talent_data.temp_buffs;
    for (var i = array_length(buffs) - 1; i >= 0; i--) {
        var buff = buffs[i];
        var elapsed = (current_time - buff.start_time) / 1000;
        if (elapsed >= buff.duration) {
            array_delete(buffs, i, 1);
        }
    }
}

// ============================================
// 공간 해싱
// ============================================

/// @function talent_update_spatial_grid(units)
/// @desc 공간 해싱 그리드 업데이트
function talent_update_spatial_grid(units) {
    // 그리드 초기화
    global.talent_spatial_grid = {};

    for (var i = 0; i < array_length(units); i++) {
        var unit = units[i];
        var cell_x = floor(unit.x / TALENT_CELL_SIZE);
        var cell_y = floor(unit.y / TALENT_CELL_SIZE);
        var key = string(cell_x) + "_" + string(cell_y);

        if (!variable_struct_exists(global.talent_spatial_grid, key)) {
            global.talent_spatial_grid[$ key] = [];
        }
        array_push(global.talent_spatial_grid[$ key], unit);
    }
}

/// @function talent_get_units_in_range(x, y, range, units)
/// @desc 범위 내 유닛 가져오기 (공간 해싱 최적화)
function talent_get_units_in_range(xx, yy, range_cells, units) {
    var result = [];
    var pixel_range = range_cells * TALENT_CELL_SIZE;

    var center_cx = floor(xx / TALENT_CELL_SIZE);
    var center_cy = floor(yy / TALENT_CELL_SIZE);

    // 주변 셀 검사
    for (var cx = center_cx - range_cells; cx <= center_cx + range_cells; cx++) {
        for (var cy = center_cy - range_cells; cy <= center_cy + range_cells; cy++) {
            var key = string(cx) + "_" + string(cy);
            if (variable_struct_exists(global.talent_spatial_grid, key)) {
                var cell_units = global.talent_spatial_grid[$ key];
                for (var i = 0; i < array_length(cell_units); i++) {
                    var unit = cell_units[i];
                    if (point_distance(xx, yy, unit.x, unit.y) <= pixel_range) {
                        array_push(result, unit);
                    }
                }
            }
        }
    }

    return result;
}

// ============================================
// 유틸리티
// ============================================

/// @function _split_string(str, delimiter)
/// @desc 문자열 분리
function _split_string(str, delimiter) {
    var result = [];
    var current = "";
    var delim_len = string_length(delimiter);
    var str_len = string_length(str);

    for (var i = 1; i <= str_len; i++) {
        var match = true;
        for (var d = 0; d < delim_len; d++) {
            if (i + d > str_len || string_char_at(str, i + d) != string_char_at(delimiter, d + 1)) {
                match = false;
                break;
            }
        }

        if (match) {
            array_push(result, current);
            current = "";
            i += delim_len - 1;
        } else {
            current += string_char_at(str, i);
        }
    }
    array_push(result, current);

    return result;
}

// ============================================
// 이벤트 헬퍼 함수 (외부 호출용)
// ============================================

/// @function talent_on_hit(attacker, target, damage)
/// @desc 공격 적중 시 호출
function talent_on_hit(attacker, target, damage) {
    talent_fire_event(TALENT_EVENT.HIT, {
        source: attacker,
        target: target,
        damage: damage,
        x: target.x,
        y: target.y
    });

    // 피격 이벤트도
    talent_fire_event(TALENT_EVENT.HIT_TAKEN, {
        source: target,
        target: attacker,
        damage: damage,
        x: target.x,
        y: target.y
    });
}

/// @function talent_on_crit(attacker, target, damage)
/// @desc 치명타 시 호출
function talent_on_crit(attacker, target, damage) {
    talent_fire_event(TALENT_EVENT.CRIT, {
        source: attacker,
        target: target,
        damage: damage,
        x: target.x,
        y: target.y
    });
}

/// @function talent_on_kill(killer, victim)
/// @desc 처치 시 호출
function talent_on_kill(killer, victim) {
    talent_fire_event(TALENT_EVENT.KILL, {
        source: killer,
        target: victim,
        x: victim.x,
        y: victim.y
    });

    talent_fire_event(TALENT_EVENT.DEATH, {
        source: victim,
        cause: killer,
        x: victim.x,
        y: victim.y
    });
}

/// @function talent_on_dodge(unit, attacker)
/// @desc 회피 시 호출
function talent_on_dodge(unit, attacker) {
    talent_fire_event(TALENT_EVENT.DODGE, {
        source: unit,
        target: attacker,
        x: unit.x,
        y: unit.y
    });
}

/// @function talent_on_skill(unit, skill_id, targets)
/// @desc 스킬 사용 시 호출
function talent_on_skill(unit, skill_id, targets) {
    talent_fire_event(TALENT_EVENT.SKILL_USE, {
        source: unit,
        target: targets,
        skill_id: skill_id,
        x: unit.x,
        y: unit.y
    });
}

/// @function talent_on_heal(healer, target, amount)
/// @desc 회복 시 호출
function talent_on_heal(healer, target, amount) {
    talent_fire_event(TALENT_EVENT.HEAL, {
        source: healer,
        target: target,
        amount: amount,
        x: target.x,
        y: target.y
    });
}

/// @function talent_on_battle_start(units)
/// @desc 전투 시작 시 호출
function talent_on_battle_start(units) {
    talent_fire_event(TALENT_EVENT.BATTLE_START, {
        source: undefined,
        target: units,
        is_global: true
    });
}

/// @function talent_on_wave_start(wave_num)
/// @desc 웨이브 시작 시 호출
function talent_on_wave_start(wave_num) {
    talent_fire_event(TALENT_EVENT.WAVE_START, {
        source: undefined,
        wave: wave_num,
        is_global: true
    });
}
