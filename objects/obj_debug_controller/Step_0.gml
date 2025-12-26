/// @description 디버그룸 업데이트

var player = global.debug.player_unit;
var ally = global.debug.ally_unit;
var dummy = global.debug.target_dummy;
var dummy2 = global.debug.enemy_dummy2;
var delta = 1/60;

// 선택된 유닛 참조 (편의용)
var selected_ally = global.debug.selected_ally;
var selected_enemy = global.debug.selected_enemy;

// === 모든 유닛 업데이트 ===
for (var u = 0; u < array_length(global.debug.all_units); u++) {
    var unit = global.debug.all_units[u];

    // 재능 시스템
    talent_update_cooldowns(unit, delta);
    talent_apply_passive(unit);

    // 상태이상
    update_status_effects(unit, delta);

    // 공격 쿨타임 감소
    if ((unit.attack_cooldown ?? 0) > 0) {
        unit.attack_cooldown = max(0, unit.attack_cooldown - delta);
    }

    // 스킬 쿨다운 감소
    var skill_keys = variable_struct_get_names(unit.skill_cooldowns);
    for (var si = 0; si < array_length(skill_keys); si++) {
        var sk = skill_keys[si];
        var scd = unit.skill_cooldowns[$ sk];
        if (scd > 0) {
            unit.skill_cooldowns[$ sk] = max(0, scd - delta);
        }
    }

    // 마나 재생
    unit.mana = min(unit.max_mana, unit.mana + (unit.mana_regen ?? 0) * delta);
}

// === 적 마나 무한 ===
if (global.debug.enemy_infinite_mana) {
    for (var em = 0; em < array_length(global.debug.enemies); em++) {
        global.debug.enemies[em].mana = global.debug.enemies[em].max_mana;
    }
}

// === 이펙트 업데이트 ===
for (var i = array_length(global.debug.effects) - 1; i >= 0; i--) {
    var fx = global.debug.effects[i];

    if (fx.type == "fireball" || fx.type == "projectile") {
        var dx = fx.target_x - fx.x;
        var dy = fx.target_y - fx.y;
        var dist = sqrt(dx*dx + dy*dy);

        if (dist < fx.speed) {
            fx.type = "explosion";
            fx.x = fx.target_x;
            fx.y = fx.target_y;
            fx.timer = 0;
            fx.max_timer = 20;
            fx.radius = 10;
            // 색상 유지
            if (!variable_struct_exists(fx, "color")) {
                fx.color = c_orange;
            }
        } else {
            fx.x += (dx / dist) * fx.speed;
            fx.y += (dy / dist) * fx.speed;

            if (fx.trail_timer <= 0) {
                var trail_color = variable_struct_exists(fx, "color") ? fx.color : c_orange;
                array_push(global.debug.effects, {
                    type: "particle",
                    x: fx.x + random_range(-5, 5),
                    y: fx.y + random_range(-5, 5),
                    timer: 15,
                    size: random_range(3, 8),
                    color: trail_color
                });
                fx.trail_timer = 2;
            } else {
                fx.trail_timer--;
            }
        }
    }
    else if (fx.type == "explosion") {
        fx.timer++;
        fx.radius = 10 + fx.timer * 3;
        if (fx.timer >= fx.max_timer) {
            array_delete(global.debug.effects, i, 1);
        }
    }
    else if (fx.type == "particle") {
        fx.timer--;
        fx.size *= 0.9;
        if (fx.timer <= 0) {
            array_delete(global.debug.effects, i, 1);
        }
    }
    else if (fx.type == "heal_effect") {
        fx.timer--;
        fx.y -= 0.5;
        if (fx.timer <= 0) {
            array_delete(global.debug.effects, i, 1);
        }
    }
    else if (fx.type == "dot_tick") {
        fx.timer--;
        fx.y -= 1;
        if (fx.timer <= 0) {
            array_delete(global.debug.effects, i, 1);
        }
    }
    else if (fx.type == "status_text") {
        fx.timer--;
        fx.y -= 0.5;
        if (fx.timer <= 0) {
            array_delete(global.debug.effects, i, 1);
        }
    }
    else if (fx.type == "buff_effect") {
        fx.timer--;
        if (fx.timer <= 0) {
            array_delete(global.debug.effects, i, 1);
        }
    }
    else if (fx.type == "damage_redirect") {
        // 피해 리다이렉트 애니메이션 (빠르게 이동)
        fx.progress += 0.15;
        if (fx.progress >= 1) {
            // 도착 시 임팩트 이펙트 생성
            array_push(global.debug.effects, {
                type: "redirect_impact",
                x: fx.end_x,
                y: fx.end_y,
                timer: 15,
                max_timer: 15,
                color: c_red
            });
            array_delete(global.debug.effects, i, 1);
        }
    }
    else if (fx.type == "redirect_impact") {
        fx.timer--;
        if (fx.timer <= 0) {
            array_delete(global.debug.effects, i, 1);
        }
    }
    else if (fx.type == "slash") {
        // 슬래시 이펙트 타이머
        fx.timer++;
        if (fx.timer >= fx.max_timer) {
            array_delete(global.debug.effects, i, 1);
        }
    }
}

// 더미 HP 재생 (토글 가능)
if (global.debug.dummy_auto_regen) {
    dummy.hp = min(dummy.max_hp, dummy.hp + dummy.hp_regen * delta);
}

// === 마우스 입력 처리 ===
var mx = mouse_x;
var my = mouse_y;
var dd = global.dropdown;
var drag = global.drag;
var panels = global.panels;
var unit_size = 40;
var header_h = 24;

// 마우스 클릭
if (mouse_check_button_pressed(mb_left)) {
    var clicked_something = false;

    // 드롭다운 처리 (우선순위 높음)
    // 마지막으로 선택된 진영의 유닛에게 적용
    var selected_unit = undefined;
    if (global.debug.last_selected_side == "ally") {
        selected_unit = global.debug.selected_ally;
    } else {
        selected_unit = global.debug.selected_enemy;
    }

    if (dd.race_open || dd.class_open || dd.talent_open || dd.skill_open) {
        // 드롭다운 리스트 클릭 처리
        if (dd.race_open) {
            var list_y = dd.race_y + dd.item_height;
            for (var i = 0; i < array_length(global.race_list); i++) {
                var item_y1 = list_y + i * dd.item_height;
                var item_y2 = item_y1 + dd.item_height;
                if (point_in_rectangle(mx, my, dd.race_x, item_y1, dd.race_x + dd.width, item_y2)) {
                    global.current_race_idx = i;
                    dd.race_open = false;
                    // 선택된 유닛의 종족 변경
                    if (selected_unit != undefined) {
                        debug_recreate_unit(selected_unit, selected_unit.level);
                    }
                    clicked_something = true;
                    break;
                }
            }
            if (!clicked_something) dd.race_open = false;
        }
        if (dd.class_open) {
            var list_y = dd.class_y + dd.item_height;
            for (var i = 0; i < array_length(global.class_list); i++) {
                var item_y1 = list_y + i * dd.item_height;
                var item_y2 = item_y1 + dd.item_height;
                if (point_in_rectangle(mx, my, dd.class_x, item_y1, dd.class_x + dd.width, item_y2)) {
                    global.current_class_idx = i;
                    dd.class_open = false;
                    // 선택된 유닛의 직업 변경
                    if (selected_unit != undefined) {
                        debug_recreate_unit(selected_unit, selected_unit.level);
                    }
                    clicked_something = true;
                    break;
                }
            }
            if (!clicked_something) dd.class_open = false;
        }
        if (dd.talent_open) {
            var list_y = dd.talent_y + dd.item_height;
            // 재능 목록이 많으므로 최대 10개만 표시
            var show_count = min(10, array_length(global.talent_list));
            for (var i = 0; i < show_count; i++) {
                var item_y1 = list_y + i * dd.item_height;
                var item_y2 = item_y1 + dd.item_height;
                if (point_in_rectangle(mx, my, dd.talent_x, item_y1, dd.talent_x + dd.width, item_y2)) {
                    global.current_talent_idx = i;
                    dd.talent_open = false;
                    // 선택된 유닛의 재능 변경
                    if (selected_unit != undefined) {
                        selected_unit.talent = global.talent_list[i];
                        // 재능 변경 시 재능 시스템 재초기화
                        if (variable_struct_exists(selected_unit, "talent_data") && selected_unit.talent_data != undefined) {
                            selected_unit.talent_data.passive_dirty = true;
                        }
                        talent_init_unit(selected_unit);
                        talent_apply_passive(selected_unit);  // 패시브 재계산
                        var talent_info = get_talent(selected_unit.talent);
                        debug_log(selected_unit.display_name + " 재능 변경: " + (talent_info != undefined ? talent_info.name_kr : "없음"));
                    }
                    clicked_something = true;
                    break;
                }
            }
            if (!clicked_something) dd.talent_open = false;
        }
        if (dd.skill_open) {
            var list_y = dd.skill_y + dd.item_height;
            var show_count = min(10, array_length(global.skill_list));
            for (var i = 0; i < show_count; i++) {
                var item_y1 = list_y + i * dd.item_height;
                var item_y2 = item_y1 + dd.item_height;
                if (point_in_rectangle(mx, my, dd.skill_x, item_y1, dd.skill_x + dd.width, item_y2)) {
                    global.current_skill_idx = i;
                    dd.skill_open = false;
                    var selected_skill = get_skill(global.skill_list[i]);
                    debug_log("스킬 선택: " + (selected_skill != undefined ? selected_skill.name : global.skill_list[i]));
                    clicked_something = true;
                    break;
                }
            }
            if (!clicked_something) dd.skill_open = false;
        }
        clicked_something = true;
    }

    // 드롭다운 버튼 클릭
    if (!clicked_something) {
        if (point_in_rectangle(mx, my, dd.race_x, dd.race_y, dd.race_x + dd.width, dd.race_y + dd.item_height)) {
            dd.race_open = !dd.race_open;
            dd.class_open = false;
            dd.talent_open = false;
            dd.skill_open = false;
            clicked_something = true;
        }
        else if (point_in_rectangle(mx, my, dd.class_x, dd.class_y, dd.class_x + dd.width, dd.class_y + dd.item_height)) {
            dd.class_open = !dd.class_open;
            dd.race_open = false;
            dd.talent_open = false;
            dd.skill_open = false;
            clicked_something = true;
        }
        else if (point_in_rectangle(mx, my, dd.talent_x, dd.talent_y, dd.talent_x + dd.width, dd.talent_y + dd.item_height)) {
            dd.talent_open = !dd.talent_open;
            dd.race_open = false;
            dd.class_open = false;
            dd.skill_open = false;
            clicked_something = true;
        }
        else if (point_in_rectangle(mx, my, dd.skill_x, dd.skill_y, dd.skill_x + dd.width, dd.skill_y + dd.item_height)) {
            dd.skill_open = !dd.skill_open;
            dd.race_open = false;
            dd.class_open = false;
            dd.talent_open = false;
            clicked_something = true;
        }
    }

    // 패널 헤더 클릭 (토글 또는 드래그 시작)
    if (!clicked_something) {
        var panel_names = variable_struct_get_names(panels);
        for (var i = 0; i < array_length(panel_names); i++) {
            var pname = panel_names[i];
            var p = panels[$ pname];
            if (point_in_rectangle(mx, my, p.x, p.y, p.x + p.w, p.y + header_h)) {
                // 더블클릭 체크를 위한 간단한 토글 (일단 단일 클릭으로 처리)
                // 오른쪽 끝 20px는 접기 버튼
                if (mx > p.x + p.w - 25) {
                    p.collapsed = !p.collapsed;
                } else {
                    // 드래그 시작
                    drag.active = true;
                    drag.target = p;
                    drag.target_type = "panel";
                    drag.offset_x = p.x - mx;
                    drag.offset_y = p.y - my;
                }
                clicked_something = true;
                break;
            }
        }
    }

    // 유닛 클릭 (선택 + 드래그) - 활성화된 유닛만
    if (!clicked_something) {
        // 활성화된 유닛 목록 생성
        var clickable_units = [global.debug.player_unit, global.debug.target_dummy];
        if (global.debug.ally_count >= 2) array_push(clickable_units, global.debug.ally_unit);
        if (global.debug.enemy_count >= 2) array_push(clickable_units, global.debug.enemy_dummy2);

        for (var ui = 0; ui < array_length(clickable_units); ui++) {
            var click_unit = clickable_units[ui];
            if (point_in_rectangle(mx, my, click_unit.x - unit_size, click_unit.y - unit_size,
                                   click_unit.x + unit_size, click_unit.y + unit_size)) {
                // 유닛 선택 (팩션에 따라 다르게)
                if (click_unit.faction == "ally") {
                    global.debug.selected_ally = click_unit;
                    global.debug.last_selected_side = "ally";
                    debug_log("시전자 선택: " + click_unit.display_name + " (종족/직업/재능 설정 가능)");
                } else {
                    global.debug.selected_enemy = click_unit;
                    global.debug.last_selected_side = "enemy";
                    debug_log("적 선택: " + click_unit.display_name + " (종족/직업/재능 설정 가능)");
                }

                // 드래그 시작
                drag.active = true;
                drag.target = click_unit;
                drag.target_type = "unit";
                drag.offset_x = click_unit.x - mx;
                drag.offset_y = click_unit.y - my;
                clicked_something = true;
                break;
            }
        }
    }
}

// 드래그 중
if (drag.active && mouse_check_button(mb_left)) {
    drag.target.x = mx + drag.offset_x;
    drag.target.y = my + drag.offset_y;
}

// 드래그 종료
if (mouse_check_button_released(mb_left)) {
    drag.active = false;
    drag.target = undefined;
    drag.target_type = "";
}

// === 버튼 호버 및 클릭 처리 ===
var btn_clicked = "";

for (var bi = 0; bi < array_length(global.debug.buttons); bi++) {
    var btn = global.debug.buttons[bi];
    btn.hover = point_in_rectangle(mx, my, btn.x, btn.y, btn.x + btn.w, btn.y + btn.h);

    if (btn.hover && mouse_check_button_pressed(mb_left)) {
        btn_clicked = btn.action;
    }
}

// === 버튼 액션 처리 ===
if (btn_clicked != "") {
    var caster = global.debug.selected_ally;
    var target = global.debug.selected_enemy;

    switch (btn_clicked) {
        // 중앙 패널
        case "basic_attack":
            if (caster != undefined && target != undefined) {
                debug_basic_attack(caster, target);
            } else {
                debug_log("시전자와 타겟을 선택하세요!");
            }
            break;
        case "skill_use":
            global.debug.btn_skill_use = true;
            break;
        case "attack_sim":
            global.debug.btn_attack_sim = true;
            break;
        case "reset_all":
            for (var ri = 0; ri < array_length(global.debug.all_units); ri++) {
                var reset_unit = global.debug.all_units[ri];
                reset_unit.hp = reset_unit.max_hp;
                reset_unit.mana = reset_unit.max_mana;
                remove_status_effect(reset_unit);
            }
            debug_log("=== 전체 유닛 리셋 완료 ===");
            break;

        // 아군 패널
        case "ally_hp_down":
            if (caster != undefined) {
                var amount = caster.max_hp * 0.1;
                caster.hp = max(1, caster.hp - amount);
                debug_log(caster.display_name + " HP -10%");
            }
            break;
        case "ally_hp_up":
            if (caster != undefined) {
                var amount = caster.max_hp * 0.1;
                caster.hp = min(caster.max_hp, caster.hp + amount);
                debug_log(caster.display_name + " HP +10%");
            }
            break;
        case "ally_cooldown":
            if (caster != undefined) {
                var cd_keys = variable_struct_get_names(caster.skill_cooldowns);
                for (var ci = 0; ci < array_length(cd_keys); ci++) {
                    caster.skill_cooldowns[$ cd_keys[ci]] = 0;
                }
                caster.mana = caster.max_mana;
                debug_log(caster.display_name + " 쿨타임 초기화!");
            }
            break;
        case "ally_auto_attack":
            global.debug.ally_auto_attack = !global.debug.ally_auto_attack;
            debug_log("아군 자동 공격: " + (global.debug.ally_auto_attack ? "ON" : "OFF"));
            break;

        // CC
        case "cc_stun":
            if (caster != undefined) {
                apply_status_effect(caster, { type: "stun", duration: 2.0, source_id: -1 });
                debug_show_status_text(caster, "기절!", c_yellow);
            }
            break;
        case "cc_slow":
            if (caster != undefined) {
                apply_status_effect(caster, { type: "slow", duration: 3.0, amount: 50, source_id: -1 });
                debug_show_status_text(caster, "둔화!", c_aqua);
            }
            break;
        case "cc_root":
            if (caster != undefined) {
                apply_status_effect(caster, { type: "root", duration: 1.5, source_id: -1 });
                debug_show_status_text(caster, "속박!", c_green);
            }
            break;
        case "cc_silence":
            if (caster != undefined) {
                apply_status_effect(caster, { type: "silence", duration: 2.0, source_id: -1 });
                debug_show_status_text(caster, "침묵!", c_purple);
            }
            break;
        case "cc_cleanse":
            if (caster != undefined) {
                cleanse_cc(caster);
                debug_show_status_text(caster, "정화!", c_white);
            }
            break;

        // 레벨
        case "level_1": case "level_2": case "level_3": case "level_4": case "level_5":
        case "level_6": case "level_7": case "level_8": case "level_9":
            if (caster != undefined) {
                var lv = real(string_char_at(btn_clicked, 7));
                debug_set_level(caster, lv);
                debug_log(caster.display_name + " 레벨 " + string(lv));
            }
            break;

        // 적군 패널
        case "enemy_hp_down":
            if (target != undefined) {
                var amount = target.max_hp * 0.1;
                target.hp = max(1, target.hp - amount);
                debug_log(target.display_name + " HP -10%");
            }
            break;
        case "enemy_hp_up":
            if (target != undefined) {
                var amount = target.max_hp * 0.1;
                target.hp = min(target.max_hp, target.hp + amount);
                debug_log(target.display_name + " HP +10%");
            }
            break;
        case "auto_attack":
            global.debug.enemy_auto_attack = !global.debug.enemy_auto_attack;
            debug_log("적 자동 공격: " + (global.debug.enemy_auto_attack ? "ON" : "OFF"));
            break;
        case "ignore_cd":
            global.debug.enemy_ignore_cooldown = !global.debug.enemy_ignore_cooldown;
            debug_log("쿨타임 무시: " + (global.debug.enemy_ignore_cooldown ? "ON" : "OFF"));
            break;
        case "infinite_mana":
            global.debug.enemy_infinite_mana = !global.debug.enemy_infinite_mana;
            debug_log("마나 무한: " + (global.debug.enemy_infinite_mana ? "ON" : "OFF"));
            break;
        case "target_mode":
            // 타겟 모드 순환: 0=모두 → 1=플레이어만 → 2=아군만 → 0
            global.debug.enemy_target_mode = (global.debug.enemy_target_mode + 1) mod 3;
            var mode_names = ["모두", "플레이어만", "아군만"];
            debug_log("자동공격 타겟: " + mode_names[global.debug.enemy_target_mode]);
            break;
        case "next_target":
            var enemies = global.debug.enemies;
            var current_idx = -1;
            for (var ti = 0; ti < array_length(enemies); ti++) {
                if (enemies[ti] == target) { current_idx = ti; break; }
            }
            var next_idx = (current_idx + 1) mod array_length(enemies);
            global.debug.selected_enemy = enemies[next_idx];
            debug_log("타겟 변경: " + global.debug.selected_enemy.display_name);
            break;
        case "next_caster":
            var allies = global.debug.allies;
            current_idx = -1;
            for (var ai = 0; ai < array_length(allies); ai++) {
                if (allies[ai] == caster) { current_idx = ai; break; }
            }
            next_idx = (current_idx + 1) mod array_length(allies);
            global.debug.selected_ally = allies[next_idx];
            debug_log("시전자 변경: " + global.debug.selected_ally.display_name);
            break;

        case "ally_count":
            global.debug.ally_count = (global.debug.ally_count == 1) ? 2 : 1;
            // 아군 배열 재구성
            global.debug.allies = [global.debug.player_unit];
            if (global.debug.ally_count == 2) {
                array_push(global.debug.allies, global.debug.ally_unit);
            }
            // 선택된 아군이 비활성화된 경우 첫 번째로 변경
            if (global.debug.selected_ally == global.debug.ally_unit && global.debug.ally_count == 1) {
                global.debug.selected_ally = global.debug.player_unit;
            }
            debug_log("아군 수: " + string(global.debug.ally_count) + "명");
            break;

        case "enemy_count":
            global.debug.enemy_count = (global.debug.enemy_count == 1) ? 2 : 1;
            // 적군 배열 재구성
            global.debug.enemies = [global.debug.target_dummy];
            if (global.debug.enemy_count == 2) {
                array_push(global.debug.enemies, global.debug.enemy_dummy2);
            }
            // 선택된 적이 비활성화된 경우 첫 번째로 변경
            if (global.debug.selected_enemy == global.debug.enemy_dummy2 && global.debug.enemy_count == 1) {
                global.debug.selected_enemy = global.debug.target_dummy;
            }
            debug_log("적군 수: " + string(global.debug.enemy_count) + "명");
            break;
    }
}

// === 키보드 입력 처리 ===

// SPACE: 선택된 스킬 사용 (선택된 아군 → 선택된 적)
var do_skill_use = keyboard_check_pressed(vk_space) || (global.debug.btn_skill_use ?? false);
global.debug.btn_skill_use = false;
if (do_skill_use) {
    var caster = global.debug.selected_ally;
    var target = global.debug.selected_enemy;

    if (caster == undefined) {
        debug_log("시전자를 선택하세요! (아군 유닛 클릭)");
    } else if (!can_use_skill(caster)) {
        debug_log(caster.display_name + " 스킬 사용 불가! (기절/침묵 상태)");
    } else {
        var selected_skill_id = global.skill_list[global.current_skill_idx];
        var skill_data = get_skill(selected_skill_id);

        // 타겟 타입에 따라 다르게 처리
        var target_type = "enemy";
        if (skill_data != undefined && variable_struct_exists(skill_data, "target_type")) {
            target_type = skill_data.target_type;
        }

        if (target_type == "self") {
            // 자기 자신에게 사용하는 스킬
            debug_use_skill(caster, selected_skill_id, caster);
        } else if (target_type == "ally") {
            // 아군 대상 스킬 - 선택된 아군에게 적용 (또는 다른 아군 선택 가능)
            // 여기서는 시전자 자신 또는 다른 아군에게 사용
            // 간단히: guardian 스킬은 선택된 적과 같은 위치의 아군에게
            debug_use_skill(caster, selected_skill_id, target ?? caster);
        } else {
            // 적 대상 스킬 - 사거리 체크 후 선택된 적에게 사용
            if (target == undefined) {
                debug_log("타겟을 선택하세요! (적 유닛 클릭)");
            } else {
                // 보정된 스킬 사거리 계산 (원거리 스킬만 종족/직업 보정)
                var skill_range = get_modified_skill_range(caster, skill_data);
                if (skill_range <= 0) skill_range = 9999;

                var dist = point_distance(caster.x, caster.y, target.x, target.y);
                if (dist <= skill_range) {
                    debug_use_skill(caster, selected_skill_id, target);
                } else {
                    var base_range = skill_data.range ?? 0;
                    var range_info = (base_range != skill_range) ?
                        string(floor(dist)) + " / " + string(skill_range) + " (기본:" + string(base_range) + ")" :
                        string(floor(dist)) + " / " + string(skill_range);
                    debug_log("사거리 밖! (" + range_info + ")");
                }
            }
        }
    }
}

// R: 전체 유닛 리셋
if (keyboard_check_pressed(ord("R"))) {
    for (var ri = 0; ri < array_length(global.debug.all_units); ri++) {
        var reset_unit = global.debug.all_units[ri];
        reset_unit.hp = reset_unit.max_hp;
        reset_unit.mana = reset_unit.max_mana;
        remove_status_effect(reset_unit);
    }
    debug_log("=== 전체 유닛 리셋 완료 ===");
}

// G: 기본 공격 (선택된 아군 → 선택된 적)
if (keyboard_check_pressed(ord("G"))) {
    var attacker = global.debug.selected_ally;
    var target = global.debug.selected_enemy;

    if (attacker == undefined) {
        debug_log("시전자를 선택하세요!");
    } else if (target == undefined) {
        debug_log("타겟을 선택하세요!");
    } else {
        debug_basic_attack(attacker, target);
    }
}

// F: 선택된 아군 스킬 쿨타임 초기화
if (keyboard_check_pressed(ord("F"))) {
    if (global.debug.selected_ally != undefined) {
        var cd_unit = global.debug.selected_ally;
        var cd_keys = variable_struct_get_names(cd_unit.skill_cooldowns);
        for (var ci = 0; ci < array_length(cd_keys); ci++) {
            cd_unit.skill_cooldowns[$ cd_keys[ci]] = 0;
        }
        cd_unit.mana = cd_unit.max_mana;  // 마나도 회복
        debug_log(cd_unit.display_name + " 쿨타임 초기화 + 마나 회복!");
    }
}

// 1~9: 선택된 아군 레벨 변경
for (var i = 1; i <= 9; i++) {
    if (keyboard_check_pressed(ord(string(i)))) {
        if (global.debug.selected_ally != undefined) {
            debug_set_level(global.debug.selected_ally, i);
            debug_log(global.debug.selected_ally.display_name + " 레벨 " + string(i));
        }
    }
}

// Tab: 타겟 순환 (적 유닛 사이클)
if (keyboard_check_pressed(vk_tab)) {
    var enemies = global.debug.enemies;
    var current_idx = -1;

    // 현재 선택된 적의 인덱스 찾기
    for (var ti = 0; ti < array_length(enemies); ti++) {
        if (enemies[ti] == global.debug.selected_enemy) {
            current_idx = ti;
            break;
        }
    }

    // 다음 적으로 순환
    var next_idx = (current_idx + 1) mod array_length(enemies);
    global.debug.selected_enemy = enemies[next_idx];
    debug_log("타겟 변경: " + global.debug.selected_enemy.display_name);
}

// Shift+Tab: 시전자 순환 (아군 유닛 사이클)
if (keyboard_check(vk_shift) && keyboard_check_pressed(vk_tab)) {
    var allies = global.debug.allies;
    current_idx = -1;

    for (var ai = 0; ai < array_length(allies); ai++) {
        if (allies[ai] == global.debug.selected_ally) {
            current_idx = ai;
            break;
        }
    }

    next_idx = (current_idx + 1) mod array_length(allies);
    global.debug.selected_ally = allies[next_idx];
    debug_log("시전자 변경: " + global.debug.selected_ally.display_name);
}

// V: 적 공격 시뮬레이션 (선택된 적 → 선택된 아군 기본공격)
var do_attack_sim = keyboard_check_pressed(ord("V")) || (global.debug.btn_attack_sim ?? false);
global.debug.btn_attack_sim = false;
if (do_attack_sim) {
    var attacker = global.debug.selected_enemy;
    var victim = global.debug.selected_ally;

    if (attacker == undefined || victim == undefined) {
        debug_log("공격자/피해자를 선택하세요!");
    } else {
        // 적의 기본 공격 시뮬레이션
        var atk = attacker.physical_attack ?? 100;
        var def = victim.physical_defense ?? 0;
        var damage = atk * (100 / (100 + def));

        debug_log("[공격 시뮬] " + attacker.display_name + " → " + victim.display_name);

        // 보호자 리다이렉트 체크
        var protector = should_redirect_damage(victim, attacker);
        if (protector != undefined) {
            // 리다이렉트 애니메이션
            array_push(global.debug.effects, {
                type: "damage_redirect",
                start_x: victim.x,
                start_y: victim.y,
                end_x: protector.x,
                end_y: protector.y,
                progress: 0,
                color: c_red
            });

            var guardian_bonus = get_guardian_defense_bonus(protector);
            var prot_def = protector.physical_defense + guardian_bonus;
            damage = atk * (100 / (100 + prot_def));
            var actual_dmg = apply_damage_with_immortal(protector, damage);
            if (actual_dmg > 0) {
                debug_log("  → " + protector.display_name + "이(가) 대신 맞음! (-" + string(floor(actual_dmg)) + ")");
            } else {
                debug_log("  → " + protector.display_name + " 불멸! (피해 무효)");
            }
        } else {
            // 결투 상태 체크
            if (!can_receive_damage_from(victim, attacker)) {
                debug_log("  → 피해 무효! (결투 중 - 외부 공격 차단)");
            } else {
                var actual_dmg = apply_damage_with_immortal(victim, damage);
                if (actual_dmg > 0) {
                    debug_log("  → " + victim.display_name + " 피해! (-" + string(floor(actual_dmg)) + ")");
                } else {
                    debug_log("  → " + victim.display_name + " 불멸! (피해 무효)");
                }

                // 피해 이펙트
                array_push(global.debug.effects, {
                    type: "explosion",
                    x: victim.x,
                    y: victim.y,
                    timer: 0,
                    max_timer: 15,
                    radius: 10,
                    color: c_red
                });
            }
        }
    }
}

// === 상태이상 테스트 키 (선택된 아군에게 적용) ===
var cc_target = global.debug.selected_ally;

// T: 기절 2초
if (keyboard_check_pressed(ord("T")) && cc_target != undefined) {
    var result = apply_status_effect(cc_target, {
        type: "stun",
        duration: 2.0,
        source_id: -1
    });
    if (result) {
        debug_log(cc_target.display_name + " 기절! (2초)");
        debug_show_status_text(cc_target, "기절!", c_yellow);
    } else {
        debug_log(cc_target.display_name + " 기절 면역!");
        debug_show_status_text(cc_target, "면역!", c_gray);
    }
}

// Y: 둔화 50% 3초
if (keyboard_check_pressed(ord("Y")) && cc_target != undefined) {
    var result = apply_status_effect(cc_target, {
        type: "slow",
        duration: 3.0,
        amount: 50,
        source_id: -1
    });
    if (result) {
        var slow_amt = get_slow_amount(cc_target);
        debug_log(cc_target.display_name + " 둔화! (" + string(floor(slow_amt)) + "%)");
        debug_show_status_text(cc_target, "둔화!", c_aqua);
    } else {
        debug_log(cc_target.display_name + " 둔화 면역!");
    }
}

// U: 속박 1.5초
if (keyboard_check_pressed(ord("U")) && cc_target != undefined) {
    var result = apply_status_effect(cc_target, {
        type: "root",
        duration: 1.5,
        source_id: -1
    });
    if (result) {
        debug_log(cc_target.display_name + " 속박!");
        debug_show_status_text(cc_target, "속박!", c_green);
    } else {
        debug_log(cc_target.display_name + " 속박 면역!");
    }
}

// I: 침묵 2초
if (keyboard_check_pressed(ord("I")) && cc_target != undefined) {
    var result = apply_status_effect(cc_target, {
        type: "silence",
        duration: 2.0,
        source_id: -1
    });
    if (result) {
        debug_log(cc_target.display_name + " 침묵!");
        debug_show_status_text(cc_target, "침묵!", c_purple);
    } else {
        debug_log(cc_target.display_name + " 침묵 면역!");
    }
}

// C: 선택된 아군 CC 정화
if (keyboard_check_pressed(ord("C")) && cc_target != undefined) {
    cleanse_cc(cc_target);
    debug_log(cc_target.display_name + " CC 정화!");
    debug_show_status_text(cc_target, "정화!", c_white);
}

// P: 길찾기 시각화 토글
if (keyboard_check_pressed(ord("P"))) {
    global.debug.show_pathfinding = !global.debug.show_pathfinding;
    if (global.debug.show_pathfinding) {
        debug_log("길찾기 시각화 ON (W: 벽 편집)");
    } else {
        debug_log("길찾기 시각화 OFF");
    }
}

// W: 벽 편집 모드 토글 (길찾기 시각화 중일 때만)
if (keyboard_check_pressed(ord("W")) && global.debug.show_pathfinding) {
    global.debug.wall_edit_mode = !global.debug.wall_edit_mode;
    if (global.debug.wall_edit_mode) {
        debug_log("벽 편집 모드 ON (클릭: 배치/제거)");
        debug_log("F5: 저장 | F6: 불러오기 | F7: 초기화");
    } else {
        debug_log("벽 편집 모드 OFF");
    }
}

// F5: 벽 데이터 저장
if (keyboard_check_pressed(vk_f5) && global.debug.show_pathfinding) {
    pf_save_walls("walls.json");
    debug_log("벽 데이터 저장됨 (walls.json)");
}

// F6: 벽 데이터 불러오기
if (keyboard_check_pressed(vk_f6) && global.debug.show_pathfinding) {
    if (pf_load_walls("walls.json")) {
        debug_log("벽 데이터 불러옴 (walls.json)");
    } else {
        debug_log("저장된 벽 데이터 없음");
    }
}

// F7: 벽 초기화
if (keyboard_check_pressed(vk_f7) && global.debug.show_pathfinding) {
    pf_clear_walls();
    debug_log("모든 벽 초기화됨");
}

// 벽 편집 모드에서 마우스 클릭으로 벽 배치/제거
if (global.debug.wall_edit_mode && global.debug.show_pathfinding) {
    if (mouse_check_button_pressed(mb_left)) {
        var grid = pf_pixel_to_grid(mx, my);
        var gx = grid.x;
        var gy = grid.y;

        // 범위 체크 및 드래그 중이 아닐 때만
        if (gx >= 0 && gx < global.pf_grid_cols && gy >= 0 && gy < global.pf_grid_rows && !drag.active) {
            var idx = gy * global.pf_grid_cols + gx;
            var current_cost = global.pathfinder.COSTARR[idx];

            // 토글: 벽이면 제거, 아니면 벽 설치
            if (current_cost == 0) {
                pf_set_blocked(gx, gy, false);
            } else {
                pf_set_blocked(gx, gy, true);
            }
        }
    }
}

// 길찾기 경로 계산 (시각화 ON일 때 매 프레임)
if (global.debug.show_pathfinding) {
    global.debug.current_path = pf_find_path_unit(player, dummy.x, dummy.y);
}

// A: AI 토글
if (keyboard_check_pressed(ord("A"))) {
    global.debug.ai_enabled = !global.debug.ai_enabled;
    if (global.debug.ai_enabled) {
        debug_log("AI 활성화 - 플레이어가 타겟을 공격합니다");
    } else {
        debug_log("AI 비활성화");
    }
}

// H: 더미 자동 회복 토글
if (keyboard_check_pressed(ord("H"))) {
    global.debug.dummy_auto_regen = !global.debug.dummy_auto_regen;
    if (global.debug.dummy_auto_regen) {
        debug_log("더미 자동 회복 ON");
    } else {
        debug_log("더미 자동 회복 OFF");
    }
}

// Q/E: 선택된 아군 HP 조절 (-10% / +10%)
if (keyboard_check_pressed(ord("Q")) && global.debug.selected_ally != undefined) {
    var hp_unit = global.debug.selected_ally;
    var amount = hp_unit.max_hp * 0.1;
    hp_unit.hp = max(1, hp_unit.hp - amount);
    debug_log(hp_unit.display_name + " HP -10% (" + string(floor(hp_unit.hp)) + "/" + string(hp_unit.max_hp) + ")");
}
if (keyboard_check_pressed(ord("E")) && global.debug.selected_ally != undefined) {
    var hp_unit = global.debug.selected_ally;
    var amount = hp_unit.max_hp * 0.1;
    hp_unit.hp = min(hp_unit.max_hp, hp_unit.hp + amount);
    debug_log(hp_unit.display_name + " HP +10% (" + string(floor(hp_unit.hp)) + "/" + string(hp_unit.max_hp) + ")");
}

// Z/X: 선택된 적 HP 조절 (-10% / +10%)
if (keyboard_check_pressed(ord("Z")) && global.debug.selected_enemy != undefined) {
    var hp_unit = global.debug.selected_enemy;
    var amount = hp_unit.max_hp * 0.1;
    hp_unit.hp = max(1, hp_unit.hp - amount);
    debug_log(hp_unit.display_name + " HP -10% (" + string(floor(hp_unit.hp)) + "/" + string(hp_unit.max_hp) + ")");
}
if (keyboard_check_pressed(ord("X")) && global.debug.selected_enemy != undefined) {
    var hp_unit = global.debug.selected_enemy;
    var amount = hp_unit.max_hp * 0.1;
    hp_unit.hp = min(hp_unit.max_hp, hp_unit.hp + amount);
    debug_log(hp_unit.display_name + " HP +10% (" + string(floor(hp_unit.hp)) + "/" + string(hp_unit.max_hp) + ")");
}

// === 적 자동 공격 시스템 ===
// B: 적 자동 공격 토글
if (keyboard_check_pressed(ord("B"))) {
    global.debug.enemy_auto_attack = !global.debug.enemy_auto_attack;
    if (global.debug.enemy_auto_attack) {
        debug_log("적 자동 공격 ON (N: 쿨타임 무시 토글)");
    } else {
        debug_log("적 자동 공격 OFF");
    }
}

// N: 쿨타임 무시 토글
if (keyboard_check_pressed(ord("N"))) {
    global.debug.enemy_ignore_cooldown = !global.debug.enemy_ignore_cooldown;
    if (global.debug.enemy_ignore_cooldown) {
        debug_log("쿨타임 무시 ON (" + string(global.debug.enemy_attack_interval) + "초 간격)");
    } else {
        debug_log("쿨타임 무시 OFF (정상 쿨타임)");
    }
}

// 적 자동 공격 로직
if (global.debug.enemy_auto_attack) {
    global.debug.enemy_attack_timer += delta;

    // 각 적 유닛이 스킬 사용
    for (var ei = 0; ei < array_length(global.debug.enemies); ei++) {
        var enemy_unit = global.debug.enemies[ei];

        // 죽은 유닛 스킵
        if (enemy_unit.hp <= 0) continue;

        // 스킬 사용 가능 체크
        if (!can_use_skill(enemy_unit)) continue;

        // 타겟 선택 (타겟 모드에 따라)
        var alive_allies = [];
        for (var tai = 0; tai < array_length(global.debug.allies); tai++) {
            var check_unit = global.debug.allies[tai];
            if (check_unit == undefined || check_unit.hp <= 0) continue;

            // 타겟 모드에 따라 필터링
            var target_mode = global.debug.enemy_target_mode;
            if (target_mode == 0) {
                // 모두
                array_push(alive_allies, check_unit);
            } else if (target_mode == 1 && check_unit.display_name == "플레이어") {
                // 플레이어만
                array_push(alive_allies, check_unit);
            } else if (target_mode == 2 && check_unit.display_name == "아군") {
                // 아군만
                array_push(alive_allies, check_unit);
            }
        }
        if (array_length(alive_allies) == 0) continue;

        var target_ally = alive_allies[irandom(array_length(alive_allies) - 1)];

        // 유닛의 스킬 가져오기
        var enemy_skills = enemy_unit.skills ?? [];
        if (array_length(enemy_skills) == 0) {
            // 스킬이 없으면 기본 공격
            if (global.debug.enemy_ignore_cooldown) {
                if (global.debug.enemy_attack_timer >= global.debug.enemy_attack_interval) {
                    // V키와 동일한 기본 공격
                    var atk = enemy_unit.physical_attack ?? 100;
                    var def = target_ally.physical_defense ?? 0;
                    var damage = atk * (100 / (100 + def));

                    var protector = should_redirect_damage(target_ally, enemy_unit);
                    if (protector != undefined) {
                        array_push(global.debug.effects, {
                            type: "damage_redirect",
                            start_x: target_ally.x, start_y: target_ally.y,
                            end_x: protector.x, end_y: protector.y,
                            progress: 0, color: c_red
                        });
                        var guardian_bonus = get_guardian_defense_bonus(protector);
                        var prot_def = protector.physical_defense + guardian_bonus;
                        damage = atk * (100 / (100 + prot_def));
                        apply_damage_with_immortal(protector, damage);
                    } else if (can_receive_damage_from(target_ally, enemy_unit)) {
                        apply_damage_with_immortal(target_ally, damage);
                        array_push(global.debug.effects, {
                            type: "explosion", x: target_ally.x, y: target_ally.y,
                            timer: 0, max_timer: 15, radius: 10, color: c_red
                        });
                    }
                }
            }
        } else {
            // 스킬 사용
            var skill_id = enemy_skills[0];  // 첫 번째 스킬 사용
            var skill_cd = enemy_unit.skill_cooldowns[$ skill_id] ?? 0;

            if (global.debug.enemy_ignore_cooldown) {
                // 쿨타임 무시 - 일정 간격으로 사용
                if (global.debug.enemy_attack_timer >= global.debug.enemy_attack_interval) {
                    debug_use_skill(enemy_unit, skill_id, target_ally);
                    enemy_unit.skill_cooldowns[$ skill_id] = 0;  // 쿨타임 즉시 리셋
                }
            } else {
                // 정상 쿨타임
                if (skill_cd <= 0) {
                    debug_use_skill(enemy_unit, skill_id, target_ally);
                }
            }
        }
    }

    // 타이머 리셋
    if (global.debug.enemy_attack_timer >= global.debug.enemy_attack_interval) {
        global.debug.enemy_attack_timer = 0;
    }
}

// === 아군 자동 기본공격 시스템 ===
if (global.debug.ally_auto_attack) {
    for (var ai = 0; ai < array_length(global.debug.allies); ai++) {
        var ally_unit = global.debug.allies[ai];

        // 죽은 유닛 스킵
        if (ally_unit == undefined || ally_unit.hp <= 0) continue;

        // 공격 쿨타임 체크
        if ((ally_unit.attack_cooldown ?? 0) > 0) continue;

        // 행동불능 상태 체크 (기절, 속박 등)
        if (!can_use_skill(ally_unit)) continue;

        // 살아있는 적 중 사거리 내 가장 가까운 적 찾기
        var atk_range = ally_unit.attack_range ?? 100;
        var closest_enemy = undefined;
        var closest_dist = atk_range + 1;

        for (var ei = 0; ei < array_length(global.debug.enemies); ei++) {
            var enemy_unit = global.debug.enemies[ei];
            if (enemy_unit == undefined || enemy_unit.hp <= 0) continue;

            var dist = point_distance(ally_unit.x, ally_unit.y, enemy_unit.x, enemy_unit.y);
            if (dist <= atk_range && dist < closest_dist) {
                closest_dist = dist;
                closest_enemy = enemy_unit;
            }
        }

        // 사거리 내 적이 있으면 기본 공격
        if (closest_enemy != undefined) {
            debug_basic_attack(ally_unit, closest_enemy);
        }
    }
}

// === 부활 시스템 ===
for (var ri = 0; ri < array_length(global.debug.all_units); ri++) {
    var resp_unit = global.debug.all_units[ri];
    var unit_key = string(ri);

    if (resp_unit.hp <= 0) {
        // 죽은 유닛 - 부활 타이머 체크
        if (!ds_map_exists(global.debug.respawn_timers, unit_key)) {
            // 타이머 시작
            ds_map_add(global.debug.respawn_timers, unit_key, global.debug.respawn_delay);
            debug_log(resp_unit.display_name + " 사망! (" + string(global.debug.respawn_delay) + "초 후 부활)");
        } else {
            // 타이머 감소
            var timer = ds_map_find_value(global.debug.respawn_timers, unit_key);
            timer -= delta;
            ds_map_replace(global.debug.respawn_timers, unit_key, timer);

            if (timer <= 0) {
                // 부활!
                resp_unit.hp = resp_unit.max_hp;
                resp_unit.mana = resp_unit.max_mana;
                remove_status_effect(resp_unit);
                ds_map_delete(global.debug.respawn_timers, unit_key);
                debug_log(resp_unit.display_name + " 부활!");

                // 부활 이펙트
                array_push(global.debug.effects, {
                    type: "buff_effect",
                    x: resp_unit.x, y: resp_unit.y,
                    timer: 30, max_timer: 30,
                    color: c_lime
                });
            }
        }
    } else {
        // 살아있는 유닛 - 타이머 제거
        if (ds_map_exists(global.debug.respawn_timers, unit_key)) {
            ds_map_delete(global.debug.respawn_timers, unit_key);
        }
    }
}

// AI 업데이트
if (global.debug.ai_enabled) {
    ai_update(player, global.debug.enemies, global.debug.allies, delta);
}

// === 재능 이벤트 배치 처리 (프레임 끝) ===
talent_process_events();
