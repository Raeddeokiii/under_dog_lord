/// @file scr_debug.gml
/// @desc 디버그 유틸리티 함수들

/// @func get_modified_skill_range(caster, skill)
/// @desc 종족/직업 보정이 적용된 스킬 사거리 반환 (원거리 스킬만)
function get_modified_skill_range(caster, skill) {
    if (skill == undefined) return 0;

    var base_range = skill.range ?? 0;

    // 근접 스킬(200 미만)은 보정 없이 그대로 반환
    if (base_range < 200) {
        return base_range;
    }

    // 원거리 스킬(200 이상)은 종족/직업 보정 적용
    var race = get_race_bonus(caster.race ?? "human");
    var cls = get_class_bonus(caster.class ?? "warrior");

    var race_mod = (race.atk_range_mod ?? 0) * 10;
    var class_mod = (cls.atk_range_mod ?? 0) * 20;

    return base_range + race_mod + class_mod;
}

/// @func debug_basic_attack(attacker, target)
/// @desc 기본 공격 수행 (근접: 슬래시, 원거리: 투사체)
function debug_basic_attack(attacker, target) {
    if (attacker == undefined || target == undefined) return;
    if (attacker.hp <= 0 || target.hp <= 0) return;

    // 공격 쿨타임 체크
    var atk_cd = attacker.attack_cooldown ?? 0;
    if (atk_cd > 0) {
        debug_log("[공격 쿨타임] " + string_format(atk_cd, 1, 2) + "초 남음");
        return;
    }

    var atk_range = attacker.attack_range ?? 100;
    var dist = point_distance(attacker.x, attacker.y, target.x, target.y);

    // 사거리 체크
    if (dist > atk_range) {
        debug_log("기본 공격 사거리 밖! (" + string(floor(dist)) + "/" + string(atk_range) + ")");
        return;
    }

    // 공격 타입 결정 (120 이하 = 근접)
    var is_melee = (atk_range <= 120);

    // 데미지 계산
    var atk = is_melee ? (attacker.physical_attack ?? 50) : (attacker.magic_attack ?? 50);
    var def = is_melee ? (target.physical_defense ?? 0) : (target.magic_defense ?? 0);
    var damage = atk * (100 / (100 + def));

    // 치명타 체크
    var is_crit = false;
    var crit_chance = attacker.crit_chance ?? 10;
    if (random(100) < crit_chance) {
        is_crit = true;
        var crit_dmg = attacker.crit_damage ?? 150;
        damage = damage * (crit_dmg / 100);
    }

    // 방향 계산
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

    // 데미지 적용 (보호자 체크 포함)
    var actual_target = target;
    var protector = should_redirect_damage(target, attacker);

    if (protector != undefined) {
        // 리다이렉트 이펙트
        array_push(global.debug.effects, {
            type: "damage_redirect",
            start_x: target.x,
            start_y: target.y,
            end_x: protector.x,
            end_y: protector.y,
            progress: 0,
            color: c_red
        });
        actual_target = protector;

        var guardian_bonus = get_guardian_defense_bonus(protector);
        def = (is_melee ? protector.physical_defense : protector.magic_defense) + guardian_bonus;
        damage = atk * (100 / (100 + def));
        if (is_crit) damage = damage * ((attacker.crit_damage ?? 150) / 100);
    }

    // 결투 체크
    if (!can_receive_damage_from(actual_target, attacker)) {
        debug_log("[기본 공격] " + attacker.display_name + " → " + target.display_name + " (결투로 무효!)");
        return;
    }

    var final_dmg = apply_damage_with_immortal(actual_target, damage);

    // 로그
    var atk_type = is_melee ? "근접" : "원거리";
    var crit_text = is_crit ? " [치명타!]" : "";
    var redirect_text = (protector != undefined) ? " → " + protector.display_name + "(대신)" : "";

    debug_log("[" + atk_type + " 공격] " + attacker.display_name + " → " + target.display_name + redirect_text);
    debug_log("  피해: " + string(floor(final_dmg)) + crit_text);

    // 공격 쿨타임 설정 (1 / 공격속도)
    var atk_speed = attacker.attack_speed ?? 1.0;
    attacker.attack_cooldown = 1.0 / atk_speed;
}

/// @func debug_log(message)
function debug_log(message) {
    array_push(global.debug.combat_log, message);
    while (array_length(global.debug.combat_log) > global.debug.max_log_lines) {
        array_delete(global.debug.combat_log, 0, 1);
    }
}

/// @func debug_use_skill(caster, skill_id, target)
function debug_use_skill(caster, skill_id, target) {
    var skill = get_skill(skill_id);
    if (skill == undefined) {
        debug_log("스킬을 찾을 수 없음: " + skill_id);
        return;
    }

    var cd = caster.skill_cooldowns[$ skill_id] ?? 0;
    if (cd > 0) {
        debug_log(skill.name + " 쿨다운 중: " + string_format(cd, 1, 1) + "초");
        return;
    }

    if (caster.mana < skill.mana_cost) {
        debug_log("마나 부족! (" + string(floor(caster.mana)) + "/" + string(skill.mana_cost) + ")");
        return;
    }

    caster.mana -= skill.mana_cost;
    caster.skill_cooldowns[$ skill_id] = skill.cooldown * (1 - caster.cooldown_reduction / 100);

    // 재능 이벤트: 스킬 사용
    talent_on_skill(caster, skill_id, target);

    debug_log("");
    debug_log("=== " + skill.name + " 시전! ===");
    debug_log("마나 소모: " + string(skill.mana_cost) + " (남은 마나: " + string(floor(caster.mana)) + ")");

    // 스킬 타입별 이펙트 결정
    var primary_effect_type = "damage";
    if (array_length(skill.effects) > 0) {
        primary_effect_type = skill.effects[0].type;
    }

    // 이펙트 색상 결정
    var effect_color = c_white;
    var damage_type = skill.damage_type ?? "";
    switch (damage_type) {
        case "fire": effect_color = c_orange; break;
        case "ice": effect_color = c_aqua; break;
        case "physical": effect_color = c_silver; break;
        case "holy": effect_color = c_yellow; break;
    }

    // 스킬 타입에 따른 이펙트 생성
    if (primary_effect_type == "heal") {
        // 힐 스킬: 시전자에게 즉시 힐 이펙트
        array_push(global.debug.effects, {
            type: "heal_effect",
            x: caster.x,
            y: caster.y,
            timer: 30,
            max_timer: 30,
            color: effect_color
        });
    } else if (primary_effect_type == "buff" || primary_effect_type == "guardian" ||
               primary_effect_type == "duel" || primary_effect_type == "immortal") {
        // 버프/특수 스킬: 시전자에게 버프 이펙트
        array_push(global.debug.effects, {
            type: "buff_effect",
            x: caster.x,
            y: caster.y,
            timer: 40,
            max_timer: 40,
            color: effect_color
        });
    } else if (skill.target_type == "self" || skill.target_type == "ally") {
        // self/ally 타겟 스킬: 투사체 없이 즉시 이펙트
        array_push(global.debug.effects, {
            type: "buff_effect",
            x: target.x,
            y: target.y,
            timer: 40,
            max_timer: 40,
            color: effect_color
        });
    } else {
        // 대미지/CC 스킬: 투사체 이펙트
        array_push(global.debug.effects, {
            type: "projectile",
            x: caster.x,
            y: caster.y,
            target_x: target.x,
            target_y: target.y,
            speed: 12,
            trail_timer: 0,
            color: effect_color,
            skill_id: skill_id
        });
    }

    for (var i = 0; i < array_length(skill.effects); i++) {
        var eff = skill.effects[i];

        if (eff.type == "damage") {
            // 결투 상태 체크: 결투 중인 상대가 아니면 피해 무효
            if (!can_receive_damage_from(target, caster)) {
                debug_log("피해 무효! (결투 중 - 외부 공격 차단)");
                continue;
            }

            // 보호자 리다이렉트 체크
            var actual_target = target;
            var redirected = false;
            var protector = should_redirect_damage(target, caster);
            if (protector != undefined) {
                actual_target = protector;
                redirected = true;

                // 리다이렉트 애니메이션 생성
                array_push(global.debug.effects, {
                    type: "damage_redirect",
                    start_x: target.x,
                    start_y: target.y,
                    end_x: protector.x,
                    end_y: protector.y,
                    progress: 0,
                    color: c_red
                });

                debug_log(">> 피해 리다이렉트! (보호자가 대신 받음)");
            }

            var stat_val = 0;
            if (eff.scale_stat == "magic_attack") {
                stat_val = caster.magic_attack;
                // 재능 보너스 적용
                if (variable_struct_exists(caster, "talent_data") && caster.talent_data != undefined) {
                    var bonuses = caster.talent_data.passive_bonuses;
                    stat_val += bonuses.mag_atk;
                    stat_val = stat_val * (1 + bonuses.mag_atk_percent / 100);
                }
            }
            else if (eff.scale_stat == "physical_attack") {
                stat_val = caster.physical_attack;
                // 재능 보너스 적용
                if (variable_struct_exists(caster, "talent_data") && caster.talent_data != undefined) {
                    var bonuses = caster.talent_data.passive_bonuses;
                    stat_val += bonuses.atk;
                    stat_val = stat_val * (1 + bonuses.atk_percent / 100);
                }
            }

            var raw_damage = eff.base_amount + stat_val * (eff.scale_percent / 100);
            var is_crit = random(100) < caster.crit_chance;

            if (is_crit) {
                raw_damage *= (caster.crit_damage / 100);
            }

            // 물리/마법 방어력 선택 (scale_stat 기준)
            var is_physical = (eff.scale_stat == "physical_attack");
            var defense = is_physical ? actual_target.physical_defense : actual_target.magic_defense;
            var pen = is_physical ? caster.physical_penetration : caster.magic_penetration;

            // 방어력 보너스 적용 (버프 + 결투 + 보호자)
            var buff_def_bonus = get_buff_defense_bonus(actual_target);
            var duel_def_bonus = get_duel_defense_bonus(actual_target);
            var guardian_def_bonus = get_guardian_defense_bonus(actual_target);
            var total_def_bonus = buff_def_bonus + duel_def_bonus + guardian_def_bonus;

            if (total_def_bonus > 0) {
                defense = floor(defense * (1 + total_def_bonus / 100));
            }

            var effective_def = max(0, defense - pen);
            var reduction = effective_def / (effective_def + 100);
            var final_damage = floor(raw_damage * (1 - reduction));

            // 불멸 상태 체크하여 피해 적용
            var actual_damage = apply_damage_with_immortal(actual_target, final_damage);
            var immortal_blocked = (actual_damage < final_damage);

            // 재능 이벤트 발생 (실제 피해가 있을 때만)
            if (actual_damage > 0) {
                talent_on_hit(caster, actual_target, actual_damage);
                if (is_crit) {
                    talent_on_crit(caster, actual_target, actual_damage);
                }
            }

            // 처치 확인
            if (actual_target.hp <= 0) {
                talent_on_kill(caster, actual_target);
            }

            var crit_text = is_crit ? " [치명타!]" : "";
            var duel_text = duel_def_bonus > 0 ? " [결투+" + string(duel_def_bonus) + "%]" : "";
            var guardian_text = guardian_def_bonus > 0 ? " [보호+" + string(guardian_def_bonus) + "%]" : "";
            var redirect_text = redirected ? " [대신받음]" : "";
            var immortal_text = immortal_blocked ? " [불멸!]" : "";
            debug_log("피해량: " + string(actual_damage) + crit_text + duel_text + guardian_text + redirect_text + immortal_text);
            debug_log("  (기본: " + string(eff.base_amount) + " + 마공 " + string(stat_val) + " x " + string(eff.scale_percent) + "%)");
            debug_log("  (방어: " + string(defense) + " - 관통 " + string(pen) + " = " + string_format(reduction * 100, 1, 1) + "% 감소)");
            if (redirected) {
                debug_log("보호자 HP: " + string(floor(actual_target.hp)) + "/" + string(actual_target.max_hp));
            } else {
                debug_log("타겟 HP: " + string(floor(actual_target.hp)) + "/" + string(actual_target.max_hp));
            }
        }
        else if (eff.type == "heal") {
            var stat_val = 0;
            if (eff.scale_stat == "magic_attack") {
                stat_val = variable_struct_exists(caster, "magic_attack") ? caster.magic_attack : 0;
            }

            var heal_amount = floor(eff.base_amount + stat_val * (eff.scale_percent / 100));
            var heal_power = variable_struct_exists(caster, "heal_power") ? caster.heal_power : 0;
            heal_amount = floor(heal_amount * (1 + heal_power / 100));

            var old_hp = caster.hp;
            caster.hp = min(caster.max_hp, caster.hp + heal_amount);
            var actual_heal = floor(caster.hp - old_hp);

            // 재능 이벤트
            talent_on_heal(caster, caster, actual_heal);

            debug_log("회복량: " + string(actual_heal) + " (계산: " + string(heal_amount) + ")");
            debug_log("시전자 HP: " + string(floor(caster.hp)) + "/" + string(caster.max_hp));
        }
        else if (eff.type == "dot") {
            debug_log("지속 피해: " + string(eff.amount) + " x " + string(eff.duration) + "초");
        }
        else if (eff.type == "stun" || eff.type == "slow" || eff.type == "root" || eff.type == "silence") {
            apply_status_effect(target, { type: eff.type, duration: eff.duration });
            debug_log("상태이상: " + eff.type + " (" + string(eff.duration) + "초)");
        }
        else if (eff.type == "buff") {
            // 버프 효과 (방패벽 등)
            var stat = eff.stat;
            var value = eff.value;
            var duration = eff.duration;
            var is_percent = variable_struct_exists(eff, "percent") ? eff.percent : true;  // 기본값 true (%)

            var percent_str = is_percent ? "%" : "";
            var buff_effect = {
                type: "buff_" + stat,
                stat: stat,
                value: value,
                percent: is_percent,
                duration: duration
            };

            // 타겟 타입에 따라 대상 결정
            if (skill.target_type == "self") {
                // 본인에게만
                apply_status_effect(caster, buff_effect);
                debug_log("버프: " + caster.display_name + " " + stat + " +" + string(value) + percent_str);
                debug_show_status_text(caster, stat + " +" + string(value) + percent_str, c_lime);
            } else if (skill.target_type == "ally") {
                // 본인 + 모든 아군에게 적용
                for (var ai = 0; ai < array_length(global.debug.allies); ai++) {
                    var ally_unit = global.debug.allies[ai];
                    if (ally_unit != undefined && ally_unit.hp > 0) {
                        apply_status_effect(ally_unit, buff_effect);
                        debug_log("버프: " + ally_unit.display_name + " " + stat + " +" + string(value) + percent_str);
                        debug_show_status_text(ally_unit, stat + " +" + string(value) + percent_str, c_lime);
                    }
                }
            } else {
                // 타겟에게만
                apply_status_effect(target, buff_effect);
                debug_log("버프: " + target.display_name + " " + stat + " +" + string(value) + percent_str);
                debug_show_status_text(target, stat + " +" + string(value) + percent_str, c_lime);
            }

            debug_log("  (" + string(duration) + "초 지속)");
        }
        else if (eff.type == "guardian") {
            // 대신 맞아주기 - 가장 약한 아군 자동 선택
            var defense_bonus = eff.defense_bonus;
            var duration = eff.duration;

            // 가장 약한 아군 찾기 (시전자 제외, 살아있는 유닛만)
            var weakest_ally = undefined;
            var lowest_score = infinity;

            for (var gi = 0; gi < array_length(global.debug.allies); gi++) {
                var check_ally = global.debug.allies[gi];
                if (check_ally == undefined) continue;
                if (check_ally == caster) continue;  // 시전자 제외
                if (check_ally.hp <= 0) continue;    // 죽은 유닛 제외

                // 약함 점수 계산 (낮을수록 약함)
                // 최대HP + 물리방어 + 마법방어 합산
                var toughness = check_ally.max_hp + (check_ally.physical_defense * 5) + (check_ally.magic_defense * 5);

                if (toughness < lowest_score) {
                    lowest_score = toughness;
                    weakest_ally = check_ally;
                }
            }

            // 보호할 아군이 없으면 스킵
            if (weakest_ally == undefined) {
                debug_log("보호할 아군이 없습니다!");
                continue;
            }

            // 시전자에게 보호자 버프 적용
            apply_status_effect(caster, {
                type: "guardian",
                defense_bonus: defense_bonus,
                protected_unit: weakest_ally,
                duration: duration
            });

            // 가장 약한 아군에게 보호받음 표시
            apply_status_effect(weakest_ally, {
                type: "protected",
                protector: caster,
                duration: duration
            });

            debug_log("보호자: " + caster.display_name + " → " + weakest_ally.display_name);
            debug_log("  " + string(duration) + "초간 피해 대신 받음 (방어력 +" + string(defense_bonus) + "%)");
            debug_log("  [" + weakest_ally.display_name + "] HP:" + string(weakest_ally.max_hp) +
                      " 물방:" + string(weakest_ally.physical_defense) +
                      " 마방:" + string(weakest_ally.magic_defense));
            debug_show_status_text(caster, "보호자", c_aqua);
            debug_show_status_text(weakest_ally, "보호받음", c_lime);
        }
        else if (eff.type == "duel") {
            // 명예로운 결투 - 1:1 강제 (시전자만 방어력 보너스)
            var defense_bonus = eff.defense_bonus;
            var duration = eff.duration;

            // 시전자: 결투 상태 + 방어력 보너스
            apply_status_effect(caster, {
                type: "duel",
                opponent: target,
                defense_bonus: defense_bonus,
                duration: duration
            });
            // 타겟: 결투 상태만 (방어력 보너스 없음)
            apply_status_effect(target, {
                type: "duel",
                opponent: caster,
                defense_bonus: 0,
                duration: duration
            });

            debug_log("결투: " + string(duration) + "초간 1:1 강제");
            debug_log("  시전자 방어력 +" + string(defense_bonus) + "%");
            debug_show_status_text(caster, "결투!", c_orange);
            debug_show_status_text(target, "결투 당함!", c_red);
        }
        else if (eff.type == "immortal") {
            // 불굴의 의지 - HP 1 이하 불가
            var duration = eff.duration;

            apply_status_effect(caster, {
                type: "immortal",
                duration: duration
            });

            debug_log("불멸: " + string(duration) + "초간 HP 1 이하로 떨어지지 않음");
            debug_show_status_text(caster, "불굴!", c_yellow);
        }
    }
}

/// @func debug_set_level(unit, level)
function debug_set_level(unit, level) {
    if (unit == undefined) return;
    debug_recreate_unit(unit, level);
}

/// @func draw_unit_box(unit, color, label)
function draw_unit_box(unit, color, label) {
    var size = 40;
    draw_set_color(color);
    draw_rectangle(unit.x - size, unit.y - size, unit.x + size, unit.y + size, false);
    draw_set_color(c_white);
    draw_rectangle(unit.x - size, unit.y - size, unit.x + size, unit.y + size, true);

    draw_set_halign(fa_center);
    draw_text(unit.x, unit.y - size - 25, label);

    var bar_w = size * 2;
    var bar_h = 10;
    var bar_y = unit.y + size + 5;

    // HP 바
    var hp_pct = unit.hp / unit.max_hp;
    draw_set_color(c_maroon);
    draw_rectangle(unit.x - size, bar_y, unit.x + size, bar_y + bar_h, false);
    draw_set_color(c_red);
    draw_rectangle(unit.x - size, bar_y, unit.x - size + bar_w * hp_pct, bar_y + bar_h, false);
    draw_set_color(c_white);
    draw_rectangle(unit.x - size, bar_y, unit.x + size, bar_y + bar_h, true);

    // 마나 바
    var mana_y = bar_y + bar_h + 2;
    if (unit.max_mana > 0) {
        var mana_pct = unit.mana / unit.max_mana;
        draw_set_color(c_navy);
        draw_rectangle(unit.x - size, mana_y, unit.x + size, mana_y + bar_h, false);
        draw_set_color(c_aqua);
        draw_rectangle(unit.x - size, mana_y, unit.x - size + bar_w * mana_pct, mana_y + bar_h, false);
        draw_set_color(c_white);
        draw_rectangle(unit.x - size, mana_y, unit.x + size, mana_y + bar_h, true);
    }

    // HP/MP 텍스트
    draw_set_color(c_white);
    draw_text(unit.x, mana_y + bar_h + 5, string(floor(unit.hp)) + "/" + string(unit.max_hp));
    if (unit.max_mana > 0) {
        draw_set_color(c_aqua);
        draw_text(unit.x, mana_y + bar_h + 20, string(floor(unit.mana)) + "/" + string(unit.max_mana));
    }
    draw_set_halign(fa_left);
}

/// @func draw_stat_panel(x, y, unit, title)
function draw_stat_panel(xx, yy, unit, title) {
    var w = 210;
    var h = 200;

    draw_set_color(c_black);
    draw_set_alpha(0.8);
    draw_rectangle(xx, yy, xx + w, yy + h, false);
    draw_set_alpha(1);

    draw_set_color(c_gray);
    draw_rectangle(xx, yy, xx + w, yy + h, true);

    draw_set_color(c_yellow);
    draw_text(xx + 10, yy + 5, title);

    var ty = yy + 30;
    var lh = 18;

    draw_set_color(c_white);
    draw_text(xx + 10, ty, "레벨: " + string(unit.level)); ty += lh;
    draw_text(xx + 10, ty, "HP: " + string(floor(unit.hp)) + "/" + string(unit.max_hp)); ty += lh;
    draw_text(xx + 10, ty, "마나: " + string(floor(unit.mana)) + "/" + string(unit.max_mana)); ty += lh;
    draw_text(xx + 10, ty, "물리 공격력: " + string(unit.physical_attack)); ty += lh;
    draw_text(xx + 10, ty, "마법 공격력: " + string(unit.magic_attack)); ty += lh;

    // 물리 방어력 (결투/보호자/버프 보너스 표시)
    var pdef_bonus = get_duel_defense_bonus(unit) + get_guardian_defense_bonus(unit) + get_buff_defense_bonus(unit);
    if (pdef_bonus > 0) {
        var pdef_final = floor(unit.physical_defense * (1 + pdef_bonus / 100));
        draw_set_color(c_lime);
        draw_text(xx + 10, ty, "물리 방어력: " + string(pdef_final) + " (+" + string(pdef_bonus) + "%)");
    } else {
        draw_text(xx + 10, ty, "물리 방어력: " + string(unit.physical_defense));
    }
    ty += lh;

    // 마법 방어력 (결투/보호자/버프 보너스 표시)
    var mdef_bonus = get_duel_defense_bonus(unit) + get_guardian_defense_bonus(unit) + get_buff_defense_bonus(unit);
    if (mdef_bonus > 0) {
        var mdef_final = floor(unit.magic_defense * (1 + mdef_bonus / 100));
        draw_set_color(c_lime);
        draw_text(xx + 10, ty, "마법 방어력: " + string(mdef_final) + " (+" + string(mdef_bonus) + "%)");
    } else {
        draw_text(xx + 10, ty, "마법 방어력: " + string(unit.magic_defense));
    }
    draw_set_color(c_white);
    ty += lh;

    draw_text(xx + 10, ty, "HP 재생: " + string(unit.hp_regen) + "/s"); ty += lh;
}

/// @func draw_combat_log(x, y)
function draw_combat_log(xx, yy) {
    var w = room_width - 20;
    var h = 220;

    draw_set_color(c_black);
    draw_set_alpha(0.7);
    draw_rectangle(xx, yy, xx + w, yy + h, false);
    draw_set_alpha(1);

    draw_set_color(c_gray);
    draw_rectangle(xx, yy, xx + w, yy + h, true);

    draw_set_color(c_yellow);
    draw_text(xx + 10, yy + 5, "=== 전투 로그 ===");

    draw_set_color(c_white);
    for (var i = 0; i < array_length(global.debug.combat_log); i++) {
        draw_text(xx + 10, yy + 25 + i * 13, global.debug.combat_log[i]);
    }
}

/// @func debug_recreate_player()
function debug_recreate_player() {
    debug_recreate_player_with_level(global.debug.player_unit.level);
}

/// @func debug_recreate_player_with_level(level)
function debug_recreate_player_with_level(level) {
    // 선택된 유닛이 없으면 플레이어 유닛 사용
    var target_unit = global.debug.selected_ally ?? global.debug.player_unit;
    debug_recreate_unit(target_unit, level);
}

/// @func debug_recreate_unit(unit, level)
/// @desc 선택된 유닛을 새로운 종족/직업으로 재생성
function debug_recreate_unit(unit, level) {
    if (unit == undefined) return;

    var race_id = global.race_list[global.current_race_idx];
    var class_id = global.class_list[global.current_class_idx];
    var old_x = unit.x;
    var old_y = unit.y;
    var old_faction = unit.faction ?? "ally";
    var old_name = unit.display_name ?? "유닛";
    var old_talent = unit.talent ?? "";
    var old_ai_type = unit.ai_type ?? "warrior";
    // 직업 기반 기본 사거리 (근접: 80, 원거리: 400)
    var class_data = get_class_bonus(global.class_list[global.current_class_idx]);
    var class_tags = class_data.tags ?? "";
    var is_ranged = (string_pos("ranged", class_tags) > 0);
    var base_attack_range = is_ranged ? 350 : 80;

    var custom_template = {
        type: "custom_unit",
        name: get_race_bonus(race_id).name + " " + get_class_bonus(class_id).name,
        race: race_id,
        class: class_id,
        base_stats: {
            hp: 300, max_mana: 100,
            physical_attack: 50, magic_attack: 50,
            physical_defense: 30, magic_defense: 30,
            attack_speed: 1.0, movement_speed: 100, attack_range: base_attack_range
        },
        secondary_stats: {
            crit_chance: 10, crit_damage: 150,
            dodge_chance: 10, accuracy: 100,
            physical_lifesteal: 0, magic_lifesteal: 0,
            healing_power: 100, physical_penetration: 0,
            magic_penetration: 0, cooldown_reduction: 0,
            mana_regen: 5, hp_regen: 2
        },
        resistance: { cc_resist: 0, debuff_resist: 0 },
        growth_per_level: { hp: 30, mana: 5, physical_attack: 5, magic_attack: 5, physical_defense: 2, magic_defense: 2 },
        skills: ["fireball"]
    };

    global.unit_templates.custom_unit = custom_template;

    var new_unit = create_unit_from_template("custom_unit", old_faction, level);
    new_unit.x = old_x;
    new_unit.y = old_y;
    new_unit.faction = old_faction;
    new_unit.display_name = old_name;
    new_unit.talent = old_talent;
    new_unit.ai_type = old_ai_type;
    // attack_range는 직업 태그 기반으로 자동 계산됨

    // 재능 초기화
    talent_init_unit(new_unit);

    // AI 초기화
    ai_init_unit(new_unit);

    // 전역 참조 업데이트 (display_name 기반)
    if (old_name == "플레이어") {
        global.debug.player_unit = new_unit;
        global.debug.allies[0] = new_unit;
        global.debug.all_units[0] = new_unit;
    } else if (old_name == "아군") {
        global.debug.ally_unit = new_unit;
        global.debug.allies[1] = new_unit;
        global.debug.all_units[1] = new_unit;
    } else if (old_name == "적1") {
        global.debug.target_dummy = new_unit;
        global.debug.enemies[0] = new_unit;
        global.debug.all_units[2] = new_unit;
    } else if (old_name == "적2") {
        global.debug.enemy_dummy2 = new_unit;
        global.debug.enemies[1] = new_unit;
        global.debug.all_units[3] = new_unit;
    }

    // 선택 상태 업데이트 (진영에 따라)
    if (old_faction == "ally") {
        global.debug.selected_ally = new_unit;
    } else {
        global.debug.selected_enemy = new_unit;
    }

    var race = get_race_bonus(race_id);
    var cls = get_class_bonus(class_id);
    var talent = get_talent(new_unit.talent);
    var talent_name = talent != undefined ? talent.name_kr : "없음";

    debug_log("");
    debug_log("=== " + old_name + " 변경 ===");
    debug_log("종족: " + race.name + " | 직업: " + cls.name + " | 레벨: " + string(level));
    debug_log("재능: " + talent_name);
    debug_log("HP: " + string(new_unit.max_hp) + " | 마공: " + string(new_unit.magic_attack));

    return new_unit;
}

/// @func format_bonus(val)
/// @desc 보너스 값을 문자열로 포맷 (+/-% 형태)
function format_bonus(val) {
    if (val > 0) return "+" + string(val) + "%";
    else if (val < 0) return string(val) + "%";
    else return "0%";
}

/// @func draw_stat_panel_with_bonus(x, y, unit, title)
/// @desc 보너스 정보가 포함된 스탯 패널
function draw_stat_panel_with_bonus(xx, yy, unit, title) {
    var w = 220;
    var h = 520;

    draw_set_color(c_black);
    draw_set_alpha(0.8);
    draw_rectangle(xx, yy, xx + w, yy + h, false);
    draw_set_alpha(1);

    draw_set_color(c_gray);
    draw_rectangle(xx, yy, xx + w, yy + h, true);

    draw_set_color(c_yellow);
    draw_text(xx + 10, yy + 5, title);

    var ty = yy + 28;
    var lh = 16;

    var race = get_race_bonus(unit.race);
    var cls = get_class_bonus(unit.class);

    // 종족/직업 정보
    draw_set_color(c_orange);
    draw_text(xx + 10, ty, "종족: " + race.name); ty += lh;
    draw_set_color(c_white);
    draw_text(xx + 10, ty, "직업: " + cls.name + " (Lv." + string(unit.level) + ")"); ty += lh;
    ty += 5;

    // 1차 스탯
    draw_set_color(c_lime);
    draw_text(xx + 10, ty, "[ 1차 스탯 ]"); ty += lh;
    draw_set_color(c_white);
    draw_text(xx + 10, ty, "HP: " + string(floor(unit.hp)) + "/" + string(unit.max_hp)); ty += lh;
    draw_text(xx + 10, ty, "마나: " + string(floor(unit.mana)) + "/" + string(unit.max_mana)); ty += lh;
    draw_text(xx + 10, ty, "물리 공격력: " + string(unit.physical_attack)); ty += lh;
    draw_text(xx + 10, ty, "마법 공격력: " + string(unit.magic_attack)); ty += lh;
    draw_text(xx + 10, ty, "물리 방어력: " + string(unit.physical_defense)); ty += lh;
    draw_text(xx + 10, ty, "마법 방어력: " + string(unit.magic_defense)); ty += lh;
    draw_text(xx + 10, ty, "공격 속도: " + string_format(unit.attack_speed, 1, 2)); ty += lh;
    draw_text(xx + 10, ty, "이동 속도: " + string(unit.movement_speed)); ty += lh;
    draw_text(xx + 10, ty, "사거리: " + string(unit.attack_range ?? 50)); ty += lh;
    ty += 5;

    // 2차 스탯
    draw_set_color(c_aqua);
    draw_text(xx + 10, ty, "[ 2차 스탯 ]"); ty += lh;
    draw_set_color(c_white);
    draw_text(xx + 10, ty, "치명타 확률: " + string(unit.crit_chance) + "%"); ty += lh;
    draw_text(xx + 10, ty, "치명타 피해: " + string(unit.crit_damage) + "%"); ty += lh;
    draw_text(xx + 10, ty, "회피율: " + string(unit.dodge_chance) + "%"); ty += lh;
    draw_text(xx + 10, ty, "명중률: " + string(unit.accuracy) + "%"); ty += lh;
    draw_text(xx + 10, ty, "물리 흡혈: " + string(unit.physical_lifesteal) + "%"); ty += lh;
    draw_text(xx + 10, ty, "마법 흡혈: " + string(unit.magic_lifesteal) + "%"); ty += lh;
    draw_text(xx + 10, ty, "치유력: " + string(unit.healing_power)); ty += lh;
    draw_text(xx + 10, ty, "물리 관통: " + string(unit.physical_penetration)); ty += lh;
    draw_text(xx + 10, ty, "마법 관통: " + string(unit.magic_penetration)); ty += lh;
    draw_text(xx + 10, ty, "쿨다운 감소: " + string(unit.cooldown_reduction) + "%"); ty += lh;
    draw_text(xx + 10, ty, "HP 재생: " + string_format(unit.hp_regen, 1, 1) + "/s"); ty += lh;
    draw_text(xx + 10, ty, "마나 재생: " + string_format(unit.mana_regen, 1, 1) + "/s"); ty += lh;
    ty += 5;

    // 저항
    draw_set_color(c_fuchsia);
    draw_text(xx + 10, ty, "[ 저항 ]"); ty += lh;
    draw_set_color(c_white);
    draw_text(xx + 10, ty, "행동불능 저항: " + string(unit.cc_resist) + "%"); ty += lh;
    draw_text(xx + 10, ty, "약화 저항: " + string(unit.debuff_resist) + "%"); ty += lh;
}

/// @func draw_race_bonus_panel(x, y)
/// @desc 종족 보너스 상세 패널
function draw_race_bonus_panel(xx, yy) {
    var race_id = global.race_list[global.current_race_idx];
    var race = get_race_bonus(race_id);

    var w = 200;
    var h = 280;

    draw_set_color(c_black);
    draw_set_alpha(0.85);
    draw_rectangle(xx, yy, xx + w, yy + h, false);
    draw_set_alpha(1);

    draw_set_color(c_gray);
    draw_rectangle(xx, yy, xx + w, yy + h, true);

    draw_set_color(c_orange);
    draw_text(xx + 10, yy + 5, "[ " + race.name + " 종족 보너스 ]");

    var ty = yy + 28;
    var lh = 15;

    draw_set_color(c_white);
    draw_text(xx + 10, ty, "HP: " + format_bonus(race.hp)); ty += lh;
    draw_text(xx + 10, ty, "마나: " + format_bonus(race.mana)); ty += lh;
    draw_text(xx + 10, ty, "물리공격: " + format_bonus(race.phys_atk)); ty += lh;
    draw_text(xx + 10, ty, "마법공격: " + format_bonus(race.mag_atk)); ty += lh;
    draw_text(xx + 10, ty, "물리방어: " + format_bonus(race.phys_def)); ty += lh;
    draw_text(xx + 10, ty, "마법방어: " + format_bonus(race.mag_def)); ty += lh;
    draw_text(xx + 10, ty, "공격속도: " + format_bonus(race.atk_speed)); ty += lh;
    draw_text(xx + 10, ty, "이동속도: " + format_bonus(race.move_speed)); ty += lh;
    ty += 3;
    draw_text(xx + 10, ty, "치명타: " + format_bonus(race.crit_chance)); ty += lh;
    draw_text(xx + 10, ty, "치명타피해: " + format_bonus(race.crit_damage)); ty += lh;
    draw_text(xx + 10, ty, "회피: " + format_bonus(race.dodge)); ty += lh;
    draw_text(xx + 10, ty, "명중: " + format_bonus(race.accuracy)); ty += lh;
    draw_text(xx + 10, ty, "흡혈: " + format_bonus(race.lifesteal)); ty += lh;
    draw_text(xx + 10, ty, "치유력: " + format_bonus(race.healing_power)); ty += lh;
    draw_text(xx + 10, ty, "HP재생: " + format_bonus(race.hp_regen)); ty += lh;
    draw_text(xx + 10, ty, "행동불능 저항: " + format_bonus(race.cc_resist)); ty += lh;
    draw_text(xx + 10, ty, "약화 저항: " + format_bonus(race.debuff_resist)); ty += lh;
    var range_mod = race.atk_range_mod ?? 0;
    var range_str = (range_mod > 0) ? "+" + string(range_mod * 10) : string(range_mod * 10);
    draw_text(xx + 10, ty, "사거리: " + range_str); ty += lh;
}

/// @func draw_dropdown_ui()
function draw_dropdown_ui() {
    var dd = global.dropdown;

    draw_dropdown("종족", dd.race_x, dd.race_y, dd.width, dd.item_height,
                  global.race_list, global.current_race_idx, dd.race_open, true);

    draw_dropdown("직업", dd.class_x, dd.class_y, dd.width, dd.item_height,
                  global.class_list, global.current_class_idx, dd.class_open, false);
}

/// @func draw_dropdown_only()
/// @desc 드롭다운만 그리기 (패널 분리용)
function draw_dropdown_only() {
    var dd = global.dropdown;

    draw_dropdown("종족", dd.race_x, dd.race_y, dd.width, dd.item_height,
                  global.race_list, global.current_race_idx, dd.race_open, true);

    draw_dropdown("직업", dd.class_x, dd.class_y, dd.width, dd.item_height,
                  global.class_list, global.current_class_idx, dd.class_open, false);

    draw_dropdown_talent("재능", dd.talent_x, dd.talent_y, dd.width, dd.item_height,
                  global.talent_list, global.current_talent_idx, dd.talent_open);

    draw_dropdown_skill("스킬", dd.skill_x, dd.skill_y, dd.width, dd.item_height,
                  global.skill_list, global.current_skill_idx, dd.skill_open);
}

/// @func draw_dropdown_talent(label, x, y, w, h, items, selected_idx, is_open)
/// @desc 재능 드롭다운 (최대 10개만 표시)
function draw_dropdown_talent(label, xx, yy, w, h, items, selected_idx, is_open) {
    var mx = mouse_x;
    var my = mouse_y;

    draw_set_color(c_yellow);
    draw_text(xx, yy - 18, label);

    var selected_id = items[selected_idx];
    var talent = get_talent(selected_id);
    var selected_name = talent != undefined ? talent.name_kr : "???";

    var hover_btn = point_in_rectangle(mx, my, xx, yy, xx + w, yy + h);
    draw_set_color(hover_btn ? c_gray : c_dkgray);
    draw_rectangle(xx, yy, xx + w, yy + h, false);
    draw_set_color(c_white);
    draw_rectangle(xx, yy, xx + w, yy + h, true);

    // 희귀도별 색상
    var rarity_color = c_white;
    if (talent != undefined) {
        switch (talent.rarity) {
            case "Common": rarity_color = c_white; break;
            case "Rare": rarity_color = c_aqua; break;
            case "Epic": rarity_color = c_purple; break;
            case "Legendary": rarity_color = c_orange; break;
        }
    }
    draw_set_color(rarity_color);
    draw_text(xx + 8, yy + 4, selected_name);

    draw_set_color(c_yellow);
    var arrow = is_open ? "^" : "v";
    draw_text(xx + w - 16, yy + 4, arrow);

    if (is_open) {
        var show_count = min(10, array_length(items));
        var list_y = yy + h;
        var list_h = show_count * h;

        draw_set_color(c_black);
        draw_set_alpha(0.95);
        draw_rectangle(xx, list_y, xx + w, list_y + list_h, false);
        draw_set_alpha(1);
        draw_set_color(c_white);
        draw_rectangle(xx, list_y, xx + w, list_y + list_h, true);

        for (var i = 0; i < show_count; i++) {
            var item_y = list_y + i * h;
            var item_id = items[i];
            var item_talent = get_talent(item_id);
            var item_name = item_talent != undefined ? item_talent.name_kr : "???";

            var hover = point_in_rectangle(mx, my, xx, item_y, xx + w, item_y + h);
            var selected = (i == selected_idx);

            if (selected) {
                draw_set_color(c_navy);
                draw_rectangle(xx + 1, item_y + 1, xx + w - 1, item_y + h - 1, false);
            } else if (hover) {
                draw_set_color(c_gray);
                draw_rectangle(xx + 1, item_y + 1, xx + w - 1, item_y + h - 1, false);
            }

            // 희귀도별 색상
            var item_rarity_color = c_white;
            if (item_talent != undefined) {
                switch (item_talent.rarity) {
                    case "Common": item_rarity_color = c_white; break;
                    case "Rare": item_rarity_color = c_aqua; break;
                    case "Epic": item_rarity_color = c_purple; break;
                    case "Legendary": item_rarity_color = c_orange; break;
                }
            }
            draw_set_color(item_rarity_color);
            draw_text(xx + 8, item_y + 4, item_name);
        }
    }
}

/// @func draw_dropdown_skill(label, x, y, w, h, items, selected_idx, is_open)
/// @desc 스킬 드롭다운
function draw_dropdown_skill(label, xx, yy, w, h, items, selected_idx, is_open) {
    var mx = mouse_x;
    var my = mouse_y;

    draw_set_color(c_lime);
    draw_text(xx, yy - 18, label);

    var selected_id = items[selected_idx];
    var skill = get_skill(selected_id);
    var selected_name = skill != undefined ? skill.name : selected_id;

    var hover_btn = point_in_rectangle(mx, my, xx, yy, xx + w, yy + h);
    draw_set_color(hover_btn ? c_gray : c_dkgray);
    draw_rectangle(xx, yy, xx + w, yy + h, false);
    draw_set_color(c_white);
    draw_rectangle(xx, yy, xx + w, yy + h, true);

    // 스킬 타입별 색상
    var skill_color = c_white;
    if (skill != undefined) {
        var skill_type = skill.damage_type ?? "";
        switch (skill_type) {
            case "fire": skill_color = c_orange; break;
            case "ice": skill_color = c_aqua; break;
            case "physical": skill_color = c_silver; break;
            case "holy": skill_color = c_yellow; break;
            default: skill_color = c_white; break;
        }
    }
    draw_set_color(skill_color);
    draw_text(xx + 8, yy + 4, selected_name);

    draw_set_color(c_lime);
    var arrow = is_open ? "^" : "v";
    draw_text(xx + w - 16, yy + 4, arrow);

    if (is_open) {
        var show_count = min(10, array_length(items));
        var list_y = yy + h;
        var list_h = show_count * h;

        draw_set_color(c_black);
        draw_set_alpha(0.95);
        draw_rectangle(xx, list_y, xx + w, list_y + list_h, false);
        draw_set_alpha(1);
        draw_set_color(c_white);
        draw_rectangle(xx, list_y, xx + w, list_y + list_h, true);

        for (var i = 0; i < show_count; i++) {
            var item_y = list_y + i * h;
            var item_id = items[i];
            var item_skill = get_skill(item_id);
            var item_name = item_skill != undefined ? item_skill.name : item_id;

            var hover = point_in_rectangle(mx, my, xx, item_y, xx + w, item_y + h);
            var selected = (i == selected_idx);

            if (selected) {
                draw_set_color(c_navy);
                draw_rectangle(xx + 1, item_y + 1, xx + w - 1, item_y + h - 1, false);
            } else if (hover) {
                draw_set_color(c_gray);
                draw_rectangle(xx + 1, item_y + 1, xx + w - 1, item_y + h - 1, false);
            }

            // 스킬 타입별 색상
            var item_skill_color = c_white;
            if (item_skill != undefined) {
                var item_type = item_skill.damage_type ?? "";
                switch (item_type) {
                    case "fire": item_skill_color = c_orange; break;
                    case "ice": item_skill_color = c_aqua; break;
                    case "physical": item_skill_color = c_silver; break;
                    case "holy": item_skill_color = c_yellow; break;
                    default: item_skill_color = c_white; break;
                }
            }
            draw_set_color(item_skill_color);
            draw_text(xx + 8, item_y + 4, item_name);
        }
    }
}

/// @func draw_panel_header(x, y, w, title, collapsed)
/// @desc 패널 헤더 (드래그/접기 버튼 포함)
function draw_panel_header(xx, yy, w, title, collapsed) {
    var h = 24;

    // 헤더 배경
    draw_set_color(c_navy);
    draw_rectangle(xx, yy, xx + w, yy + h, false);
    draw_set_color(c_white);
    draw_rectangle(xx, yy, xx + w, yy + h, true);

    // 제목
    draw_set_color(c_yellow);
    draw_text(xx + 8, yy + 5, title);

    // 접기/펴기 버튼
    draw_set_color(c_white);
    var btn_x = xx + w - 20;
    draw_text(btn_x, yy + 5, collapsed ? "+" : "-");

    return h;
}

/// @func draw_panel_stat_with_bonus(x, y, w, collapsed, unit, title)
/// @desc 보너스 포함 스탯 패널 (접기 가능, 재능 보너스 반영)
function draw_panel_stat_with_bonus(xx, yy, w, collapsed, unit, title) {
    var header_h = draw_panel_header(xx, yy, w, title, collapsed);

    if (collapsed) return;

    var h = 520;
    var content_y = yy + header_h;

    draw_set_color(c_black);
    draw_set_alpha(0.8);
    draw_rectangle(xx, content_y, xx + w, content_y + h, false);
    draw_set_alpha(1);
    draw_set_color(c_gray);
    draw_rectangle(xx, content_y, xx + w, content_y + h, true);

    var ty = content_y + 8;
    var lh = 16;

    var race = get_race_bonus(unit.race);
    var cls = get_class_bonus(unit.class);

    // 재능 패시브 보너스 가져오기
    var bonuses = undefined;
    if (unit.talent_data != undefined) {
        bonuses = unit.talent_data.passive_bonuses;
    }

    // 종족/직업 정보
    draw_set_color(c_orange);
    draw_text(xx + 10, ty, "종족: " + race.name); ty += lh;
    draw_set_color(c_white);
    draw_text(xx + 10, ty, "직업: " + cls.name + " (Lv." + string(unit.level) + ")"); ty += lh;
    ty += 5;

    // 1차 스탯 (재능 보너스 반영)
    draw_set_color(c_lime);
    draw_text(xx + 10, ty, "[ 1차 스탯 ]"); ty += lh;

    // 물리 공격력 (재능 보너스 표시)
    var phys_atk = unit.physical_attack;
    var phys_atk_bonus = bonuses != undefined ? bonuses.atk_percent : 0;
    var phys_atk_final = floor(phys_atk * (1 + phys_atk_bonus / 100));
    if (phys_atk_bonus != 0) {
        draw_set_color(phys_atk_bonus > 0 ? c_lime : c_red);
        draw_text(xx + 10, ty, "물리 공격력: " + string(phys_atk_final) + " (" + (phys_atk_bonus > 0 ? "+" : "") + string(phys_atk_bonus) + "%)");
    } else {
        draw_set_color(c_white);
        draw_text(xx + 10, ty, "물리 공격력: " + string(phys_atk));
    }
    ty += lh;

    // 마법 공격력 (재능 보너스 표시)
    var mag_atk = unit.magic_attack;
    var mag_atk_bonus = bonuses != undefined ? bonuses.mag_atk_percent : 0;
    var mag_atk_final = floor(mag_atk * (1 + mag_atk_bonus / 100));
    if (mag_atk_bonus != 0) {
        draw_set_color(mag_atk_bonus > 0 ? c_lime : c_red);
        draw_text(xx + 10, ty, "마법 공격력: " + string(mag_atk_final) + " (" + (mag_atk_bonus > 0 ? "+" : "") + string(mag_atk_bonus) + "%)");
    } else {
        draw_set_color(c_white);
        draw_text(xx + 10, ty, "마법 공격력: " + string(mag_atk));
    }
    ty += lh;

    // 물리 방어력 (재능 + 결투/보호자/버프 보너스 포함)
    var phys_def = unit.physical_defense;
    var phys_def_talent = bonuses != undefined ? bonuses.def_percent : 0;
    var phys_def_duel = get_duel_defense_bonus(unit);
    var phys_def_guardian = get_guardian_defense_bonus(unit);
    var phys_def_buff = get_buff_defense_bonus(unit);
    var phys_def_total_bonus = phys_def_talent + phys_def_duel + phys_def_guardian + phys_def_buff;
    var phys_def_final = floor(phys_def * (1 + phys_def_total_bonus / 100));
    if (phys_def_total_bonus != 0) {
        draw_set_color(phys_def_total_bonus > 0 ? c_lime : c_red);
        var bonus_text = "";
        if (phys_def_buff > 0) bonus_text += " [버프+" + string(phys_def_buff) + "%]";
        if (phys_def_duel > 0) bonus_text += " [결투+" + string(phys_def_duel) + "%]";
        if (phys_def_guardian > 0) bonus_text += " [보호+" + string(phys_def_guardian) + "%]";
        draw_text(xx + 10, ty, "물리 방어력: " + string(phys_def_final) + bonus_text);
    } else {
        draw_set_color(c_white);
        draw_text(xx + 10, ty, "물리 방어력: " + string(phys_def));
    }
    ty += lh;

    // 마법 방어력 (재능 + 결투/보호자/버프 보너스 포함)
    var mag_def = unit.magic_defense;
    var mag_def_talent = bonuses != undefined ? bonuses.mag_def_percent : 0;
    var mag_def_duel = get_duel_defense_bonus(unit);
    var mag_def_guardian = get_guardian_defense_bonus(unit);
    var mag_def_buff = get_buff_defense_bonus(unit);
    var mag_def_total_bonus = mag_def_talent + mag_def_duel + mag_def_guardian + mag_def_buff;
    var mag_def_final = floor(mag_def * (1 + mag_def_total_bonus / 100));
    if (mag_def_total_bonus != 0) {
        draw_set_color(mag_def_total_bonus > 0 ? c_lime : c_red);
        var bonus_text = "";
        if (mag_def_buff > 0) bonus_text += " [버프+" + string(mag_def_buff) + "%]";
        if (mag_def_duel > 0) bonus_text += " [결투+" + string(mag_def_duel) + "%]";
        if (mag_def_guardian > 0) bonus_text += " [보호+" + string(mag_def_guardian) + "%]";
        draw_text(xx + 10, ty, "마법 방어력: " + string(mag_def_final) + bonus_text);
    } else {
        draw_set_color(c_white);
        draw_text(xx + 10, ty, "마법 방어력: " + string(mag_def));
    }
    ty += lh;

    draw_set_color(c_white);
    draw_text(xx + 10, ty, "HP: " + string(floor(unit.hp)) + "/" + string(unit.max_hp)); ty += lh;
    draw_text(xx + 10, ty, "마나: " + string(floor(unit.mana)) + "/" + string(unit.max_mana)); ty += lh;
    draw_text(xx + 10, ty, "공격 속도: " + string_format(unit.attack_speed, 1, 2)); ty += lh;

    // 공격 쿨타임 표시
    var atk_cd = unit.attack_cooldown ?? 0;
    if (atk_cd > 0) {
        draw_set_color(c_orange);
        draw_text(xx + 10, ty, "공격 쿨타임: " + string_format(atk_cd, 1, 2) + "초");
    } else {
        draw_set_color(c_lime);
        draw_text(xx + 10, ty, "공격 쿨타임: 대기");
    }
    ty += lh;
    draw_set_color(c_white);

    draw_text(xx + 10, ty, "이동 속도: " + string(unit.movement_speed)); ty += lh;
    draw_text(xx + 10, ty, "사거리: " + string(unit.attack_range ?? 50)); ty += lh;
    ty += 5;

    // 2차 스탯
    draw_set_color(c_aqua);
    draw_text(xx + 10, ty, "[ 2차 스탯 ]"); ty += lh;

    // 치명타
    var crit = unit.crit_chance;
    var crit_bonus = bonuses != undefined ? bonuses.crit : 0;
    if (crit_bonus != 0) {
        draw_set_color(c_lime);
        draw_text(xx + 10, ty, "치명타 확률: " + string(crit + crit_bonus) + "% (+" + string(crit_bonus) + "%)");
    } else {
        draw_set_color(c_white);
        draw_text(xx + 10, ty, "치명타 확률: " + string(crit) + "%");
    }
    ty += lh;

    // 회피
    var dodge = unit.dodge_chance;
    var dodge_bonus = bonuses != undefined ? bonuses.dodge : 0;
    if (dodge_bonus != 0) {
        draw_set_color(c_lime);
        draw_text(xx + 10, ty, "회피율: " + string(dodge + dodge_bonus) + "% (+" + string(dodge_bonus) + "%)");
    } else {
        draw_set_color(c_white);
        draw_text(xx + 10, ty, "회피율: " + string(dodge) + "%");
    }
    ty += lh;

    draw_set_color(c_white);
    draw_text(xx + 10, ty, "치명타 피해: " + string(unit.crit_damage) + "%"); ty += lh;
    draw_text(xx + 10, ty, "명중률: " + string(unit.accuracy) + "%"); ty += lh;
    draw_text(xx + 10, ty, "물리 흡혈: " + string(unit.physical_lifesteal) + "%"); ty += lh;
    draw_text(xx + 10, ty, "마법 흡혈: " + string(unit.magic_lifesteal) + "%"); ty += lh;
    draw_text(xx + 10, ty, "치유력: " + string(unit.healing_power)); ty += lh;
    draw_text(xx + 10, ty, "물리 관통: " + string(unit.physical_penetration)); ty += lh;
    draw_text(xx + 10, ty, "마법 관통: " + string(unit.magic_penetration)); ty += lh;
    draw_text(xx + 10, ty, "쿨다운 감소: " + string(unit.cooldown_reduction) + "%"); ty += lh;
    draw_text(xx + 10, ty, "HP 재생: " + string_format(unit.hp_regen, 1, 1) + "/s"); ty += lh;
    draw_text(xx + 10, ty, "마나 재생: " + string_format(unit.mana_regen, 1, 1) + "/s"); ty += lh;
    ty += 5;

    // 저항
    draw_set_color(c_fuchsia);
    draw_text(xx + 10, ty, "[ 저항 ]"); ty += lh;
    draw_set_color(c_white);
    draw_text(xx + 10, ty, "행동불능 저항: " + string(unit.cc_resist) + "%"); ty += lh;
    draw_text(xx + 10, ty, "약화 저항: " + string(unit.debuff_resist) + "%"); ty += lh;
}

/// @func draw_panel_race_bonus(x, y, w, collapsed, title, unit)
/// @desc 종족 보너스 패널 (접기 가능) - 선택된 유닛 기준
function draw_panel_race_bonus(xx, yy, w, collapsed, title, unit) {
    var race_id = (unit != undefined && variable_struct_exists(unit, "race")) ? unit.race : global.race_list[global.current_race_idx];
    var race = get_race_bonus(race_id);

    var full_title = title + " [" + race.name + "]";
    var header_h = draw_panel_header(xx, yy, w, full_title, collapsed);

    if (collapsed) return;

    var h = 280;
    var content_y = yy + header_h;

    draw_set_color(c_black);
    draw_set_alpha(0.85);
    draw_rectangle(xx, content_y, xx + w, content_y + h, false);
    draw_set_alpha(1);
    draw_set_color(c_gray);
    draw_rectangle(xx, content_y, xx + w, content_y + h, true);

    var ty = content_y + 8;
    var lh = 15;

    draw_set_color(c_white);
    draw_text(xx + 10, ty, "HP: " + format_bonus(race.hp)); ty += lh;
    draw_text(xx + 10, ty, "마나: " + format_bonus(race.mana)); ty += lh;
    draw_text(xx + 10, ty, "물리공격: " + format_bonus(race.phys_atk)); ty += lh;
    draw_text(xx + 10, ty, "마법공격: " + format_bonus(race.mag_atk)); ty += lh;
    draw_text(xx + 10, ty, "물리방어: " + format_bonus(race.phys_def)); ty += lh;
    draw_text(xx + 10, ty, "마법방어: " + format_bonus(race.mag_def)); ty += lh;
    draw_text(xx + 10, ty, "공격속도: " + format_bonus(race.atk_speed)); ty += lh;
    draw_text(xx + 10, ty, "이동속도: " + format_bonus(race.move_speed)); ty += lh;
    ty += 3;
    draw_text(xx + 10, ty, "치명타: " + format_bonus(race.crit_chance)); ty += lh;
    draw_text(xx + 10, ty, "치명타피해: " + format_bonus(race.crit_damage)); ty += lh;
    draw_text(xx + 10, ty, "회피: " + format_bonus(race.dodge)); ty += lh;
    draw_text(xx + 10, ty, "명중: " + format_bonus(race.accuracy)); ty += lh;
    draw_text(xx + 10, ty, "흡혈: " + format_bonus(race.lifesteal)); ty += lh;
    draw_text(xx + 10, ty, "치유력: " + format_bonus(race.healing_power)); ty += lh;
    draw_text(xx + 10, ty, "HP재생: " + format_bonus(race.hp_regen)); ty += lh;
    draw_text(xx + 10, ty, "행동불능 저항: " + format_bonus(race.cc_resist)); ty += lh;
    draw_text(xx + 10, ty, "약화 저항: " + format_bonus(race.debuff_resist)); ty += lh;
    var range_mod = race.atk_range_mod ?? 0;
    var range_str = (range_mod > 0) ? "+" + string(range_mod * 10) : string(range_mod * 10);
    draw_text(xx + 10, ty, "사거리: " + range_str); ty += lh;
}

/// @func draw_panel_class_bonus(x, y, w, collapsed, title, unit)
/// @desc 직업 보너스 패널 (접기 가능) - 선택된 유닛 기준
function draw_panel_class_bonus(xx, yy, w, collapsed, title, unit) {
    var class_id = (unit != undefined && variable_struct_exists(unit, "class")) ? unit.class : global.class_list[global.current_class_idx];
    var cls = get_class_bonus(class_id);

    var full_title = title + " [" + cls.name + "]";
    var header_h = draw_panel_header(xx, yy, w, full_title, collapsed);

    if (collapsed) return;

    var h = 140;
    var content_y = yy + header_h;

    draw_set_color(c_black);
    draw_set_alpha(0.85);
    draw_rectangle(xx, content_y, xx + w, content_y + h, false);
    draw_set_alpha(1);
    draw_set_color(c_gray);
    draw_rectangle(xx, content_y, xx + w, content_y + h, true);

    var ty = content_y + 8;
    var lh = 15;

    draw_set_color(c_white);
    draw_text(xx + 10, ty, "HP: " + format_bonus(cls.hp_mod)); ty += lh;
    draw_text(xx + 10, ty, "물리공격: " + format_bonus(cls.phys_atk_mod)); ty += lh;
    draw_text(xx + 10, ty, "마법공격: " + format_bonus(cls.mag_atk_mod)); ty += lh;
    draw_text(xx + 10, ty, "물리방어: " + format_bonus(cls.phys_def_mod)); ty += lh;
    draw_text(xx + 10, ty, "마법방어: " + format_bonus(cls.mag_def_mod)); ty += lh;
    draw_text(xx + 10, ty, "이동속도: " + format_bonus(cls.speed_mod)); ty += lh;
    draw_text(xx + 10, ty, "공격 사거리: " + format_bonus(cls.atk_range_mod)); ty += lh;
}

/// @func draw_panel_talent(x, y, w, collapsed, unit, title)
/// @desc 재능 정보 패널 (접기 가능)
function draw_panel_talent(xx, yy, w, collapsed, unit, title) {
    var talent_id = unit.talent ?? "";
    var talent = get_talent(talent_id);

    var talent_name = talent != undefined ? talent.name_kr : "없음";
    var full_title = title + " [" + talent_name + "]";
    var header_h = draw_panel_header(xx, yy, w, full_title, collapsed);

    if (collapsed) return;

    var h = 120;  // 높이 증가 (쿨타임 바 추가)
    var content_y = yy + header_h;

    draw_set_color(c_black);
    draw_set_alpha(0.85);
    draw_rectangle(xx, content_y, xx + w, content_y + h, false);
    draw_set_alpha(1);
    draw_set_color(c_gray);
    draw_rectangle(xx, content_y, xx + w, content_y + h, true);

    var ty = content_y + 8;
    var lh = 15;

    if (talent == undefined) {
        draw_set_color(c_gray);
        draw_text(xx + 10, ty, "재능 없음");
        return;
    }

    // 희귀도별 색상
    var rarity_color = c_white;
    switch (talent.rarity) {
        case "Common": rarity_color = c_white; break;
        case "Rare": rarity_color = c_aqua; break;
        case "Epic": rarity_color = c_purple; break;
        case "Legendary": rarity_color = c_orange; break;
    }

    draw_set_color(rarity_color);
    draw_text(xx + 10, ty, "[" + talent.rarity + "]"); ty += lh;

    draw_set_color(c_lime);
    draw_text(xx + 10, ty, "발동: " + talent.trigger); ty += lh;

    // 효과 표시 (컬럼 기반)
    draw_set_color(c_yellow);
    var effect_str = talent.effect_type;
    if (talent.stat1 != "") {
        effect_str += " " + talent.stat1;
        if (talent.value1 != 0) effect_str += (talent.value1 > 0 ? "+" : "") + string(talent.value1) + "%";
    }
    if (talent.stat2 != "") {
        effect_str += " / " + talent.stat2;
        if (talent.value2 != 0) effect_str += (talent.value2 > 0 ? "+" : "") + string(talent.value2) + "%";
    }
    if (talent.cc_type != "") {
        effect_str += " " + talent.cc_type + " " + string(talent.cc_duration) + "s";
    }
    if (talent.duration > 0) {
        effect_str += " (" + string(talent.duration) + "s)";
    }
    draw_text(xx + 10, ty, "효과: " + effect_str); ty += lh;

    draw_set_color(c_white);
    draw_text(xx + 10, ty, talent.description); ty += lh;

    // 쿨타임 표시 (현재 / 최대)
    if (talent.cooldown > 0) {
        ty += 3;
        var current_cd = 0;
        if (unit.talent_data != undefined && variable_struct_exists(unit.talent_data, "cooldowns")) {
            current_cd = unit.talent_data.cooldowns[$ talent_id] ?? 0;
        }

        var bar_w = w - 20;
        var bar_h = 12;
        var bar_x = xx + 10;
        var bar_y = ty;

        // 쿨타임 바 배경
        draw_set_color(c_dkgray);
        draw_rectangle(bar_x, bar_y, bar_x + bar_w, bar_y + bar_h, false);

        // 쿨타임 바 (남은 시간 비율)
        if (current_cd > 0) {
            var cd_pct = current_cd / talent.cooldown;
            draw_set_color(c_maroon);
            draw_rectangle(bar_x, bar_y, bar_x + bar_w * cd_pct, bar_y + bar_h, false);
        } else {
            // 사용 가능
            draw_set_color(c_green);
            draw_rectangle(bar_x, bar_y, bar_x + bar_w, bar_y + bar_h, false);
        }

        // 테두리
        draw_set_color(c_gray);
        draw_rectangle(bar_x, bar_y, bar_x + bar_w, bar_y + bar_h, true);

        // 쿨타임 텍스트
        draw_set_halign(fa_center);
        if (current_cd > 0) {
            draw_set_color(c_red);
            draw_text(bar_x + bar_w/2, bar_y - 1, string_format(current_cd, 1, 1) + "s / " + string(talent.cooldown) + "s");
        } else {
            draw_set_color(c_lime);
            draw_text(bar_x + bar_w/2, bar_y - 1, "준비됨");
        }
        draw_set_halign(fa_left);
    }
}

/// @func draw_panel_stat(x, y, w, collapsed, unit, title)
/// @desc 기본 스탯 패널 (접기 가능)
function draw_panel_stat(xx, yy, w, collapsed, unit, title) {
    var header_h = draw_panel_header(xx, yy, w, title, collapsed);

    if (collapsed) return;

    var h = 180;
    var content_y = yy + header_h;

    draw_set_color(c_black);
    draw_set_alpha(0.8);
    draw_rectangle(xx, content_y, xx + w, content_y + h, false);
    draw_set_alpha(1);
    draw_set_color(c_gray);
    draw_rectangle(xx, content_y, xx + w, content_y + h, true);

    var ty = content_y + 8;
    var lh = 18;

    draw_set_color(c_white);
    draw_text(xx + 10, ty, "레벨: " + string(unit.level)); ty += lh;
    draw_text(xx + 10, ty, "HP: " + string(floor(unit.hp)) + "/" + string(unit.max_hp)); ty += lh;
    draw_text(xx + 10, ty, "마나: " + string(floor(unit.mana)) + "/" + string(unit.max_mana)); ty += lh;
    draw_text(xx + 10, ty, "물리 공격력: " + string(unit.physical_attack)); ty += lh;
    draw_text(xx + 10, ty, "마법 공격력: " + string(unit.magic_attack)); ty += lh;

    // 물리 방어력 (결투/보호자/버프 보너스 표시)
    var pdef_bonus2 = get_duel_defense_bonus(unit) + get_guardian_defense_bonus(unit) + get_buff_defense_bonus(unit);
    if (pdef_bonus2 > 0) {
        var pdef_final2 = floor(unit.physical_defense * (1 + pdef_bonus2 / 100));
        draw_set_color(c_lime);
        draw_text(xx + 10, ty, "물리 방어력: " + string(pdef_final2) + " (+" + string(pdef_bonus2) + "%)");
    } else {
        draw_text(xx + 10, ty, "물리 방어력: " + string(unit.physical_defense));
    }
    ty += lh;

    // 마법 방어력 (결투/보호자/버프 보너스 표시)
    var mdef_bonus2 = get_duel_defense_bonus(unit) + get_guardian_defense_bonus(unit) + get_buff_defense_bonus(unit);
    if (mdef_bonus2 > 0) {
        var mdef_final2 = floor(unit.magic_defense * (1 + mdef_bonus2 / 100));
        draw_set_color(c_lime);
        draw_text(xx + 10, ty, "마법 방어력: " + string(mdef_final2) + " (+" + string(mdef_bonus2) + "%)");
    } else {
        draw_text(xx + 10, ty, "마법 방어력: " + string(unit.magic_defense));
    }
    draw_set_color(c_white);
    ty += lh;

    draw_text(xx + 10, ty, "HP 재생: " + string(unit.hp_regen) + "/s"); ty += lh;
}

/// @func draw_dropdown(label, x, y, w, h, items, selected_idx, is_open, is_race)
function draw_dropdown(label, xx, yy, w, h, items, selected_idx, is_open, is_race) {
    var mx = mouse_x;
    var my = mouse_y;

    draw_set_color(c_yellow);
    draw_text(xx, yy - 18, label);

    var selected_id = items[selected_idx];
    var selected_name = "";
    if (is_race) {
        selected_name = get_race_bonus(selected_id).name;
    } else {
        selected_name = get_class_bonus(selected_id).name;
    }

    var hover_btn = point_in_rectangle(mx, my, xx, yy, xx + w, yy + h);
    draw_set_color(hover_btn ? c_gray : c_dkgray);
    draw_rectangle(xx, yy, xx + w, yy + h, false);
    draw_set_color(c_white);
    draw_rectangle(xx, yy, xx + w, yy + h, true);

    draw_set_color(c_white);
    draw_text(xx + 8, yy + 4, selected_name);

    draw_set_color(c_yellow);
    var arrow = is_open ? "^" : "v";
    draw_text(xx + w - 16, yy + 4, arrow);

    if (is_open) {
        var list_y = yy + h;
        var list_h = array_length(items) * h;

        draw_set_color(c_black);
        draw_set_alpha(0.95);
        draw_rectangle(xx, list_y, xx + w, list_y + list_h, false);
        draw_set_alpha(1);
        draw_set_color(c_white);
        draw_rectangle(xx, list_y, xx + w, list_y + list_h, true);

        for (var i = 0; i < array_length(items); i++) {
            var item_y = list_y + i * h;
            var item_id = items[i];
            var item_name = "";
            if (is_race) {
                item_name = get_race_bonus(item_id).name;
            } else {
                item_name = get_class_bonus(item_id).name;
            }

            var hover = point_in_rectangle(mx, my, xx, item_y, xx + w, item_y + h);
            var selected = (i == selected_idx);

            if (hover || selected) {
                draw_set_color(selected ? c_navy : c_gray);
                draw_set_alpha(0.8);
                draw_rectangle(xx + 1, item_y + 1, xx + w - 1, item_y + h - 1, false);
                draw_set_alpha(1);
            }

            draw_set_color(hover ? c_yellow : c_white);
            draw_text(xx + 8, item_y + 4, item_name);
        }
    }
}

/// @func draw_status_icons(unit, x, y)
/// @desc 유닛의 상태이상 아이콘 표시
function draw_status_icons(unit, xx, yy) {
    var effects = get_status_effect_list(unit);
    if (array_length(effects) == 0) return;

    var icon_size = 18;
    var spacing = 4;
    var total_width = array_length(effects) * (icon_size + spacing) - spacing;
    var start_x = xx - total_width / 2;

    for (var i = 0; i < array_length(effects); i++) {
        var eff = effects[i];
        var icon_x = start_x + i * (icon_size + spacing);
        var icon_color = get_status_icon_color(eff.type);
        var icon_char = "?";

        switch (eff.type) {
            case "stun": icon_char = "S"; break;
            case "root": icon_char = "R"; break;
            case "silence": icon_char = "X"; break;
            case "slow": icon_char = "~"; break;
            case "dot": icon_char = "!"; break;
            case "hot": icon_char = "+"; break;
            case "weaken": icon_char = "W"; break;
            case "vulnerable": icon_char = "V"; break;
            case "haste": icon_char = "H"; break;
            case "might": icon_char = "M"; break;
            case "shield": icon_char = "O"; break;
            case "guardian": icon_char = "G"; break;
            case "protected": icon_char = "P"; break;
            case "duel": icon_char = "D"; break;
            case "immortal": icon_char = "I"; break;
            default:
                // buff_defense 등 버프 타입 처리
                if (string_pos("buff_", eff.type) == 1) {
                    icon_char = "B";
                }
                break;
        }

        draw_set_color(c_black);
        draw_set_alpha(0.7);
        draw_rectangle(icon_x, yy, icon_x + icon_size, yy + icon_size, false);
        draw_set_alpha(1);

        draw_set_color(icon_color);
        draw_rectangle(icon_x, yy, icon_x + icon_size, yy + icon_size, true);

        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text(icon_x + icon_size/2, yy + icon_size/2, icon_char);

        if (eff.max_duration > 0) {
            var pct = eff.duration / eff.max_duration;
            draw_set_color(icon_color);
            draw_rectangle(icon_x, yy + icon_size + 1, icon_x + icon_size * pct, yy + icon_size + 3, false);
        }
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

/// @func debug_show_status_text(unit, text, color)
function debug_show_status_text(unit, text, color) {
    array_push(global.debug.effects, {
        type: "status_text",
        x: unit.x,
        y: unit.y - 80,
        text: text,
        color: color,
        timer: 45,
        max_timer: 45
    });
}
