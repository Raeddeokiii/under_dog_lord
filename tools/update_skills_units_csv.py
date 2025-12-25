#!/usr/bin/env python3
"""스킬/유닛 CSV 로드 함수를 scr_data.gml에 추가"""

scr_data_path = 'D:/gml_game/under_dog_lord/scripts/scr_data/scr_data.gml'

new_skill_func = '''
// ============================================
// 스킬 데이터 (CSV 로드)
// ============================================

function init_skill_data() {
    global.skills = {};

    var file = file_text_open_read("data/skills.csv");
    if (file == -1) {
        show_debug_message("ERROR: data/skills.csv not found!");
        return;
    }

    // 헤더 스킵
    file_text_read_string(file);
    file_text_readln(file);

    while (!file_text_eof(file)) {
        var line = file_text_read_string(file);
        file_text_readln(file);

        if (line == "") continue;

        var cols = csv_split_line(line);
        if (array_length(cols) < 20) continue;

        var skill_id = cols[0];
        if (skill_id == "") continue;

        // 효과 빌드
        var effects = [];
        var effect_type = cols[5];

        if (effect_type == "damage") {
            var eff = {
                type: "damage",
                base_amount: real(cols[6]),
                scale_stat: cols[7],
                scale_percent: real(cols[8])
            };
            array_push(effects, eff);

            // DoT 추가
            if (real(cols[9]) > 0) {
                array_push(effects, {
                    type: "dot",
                    amount: real(cols[9]),
                    duration: real(cols[10])
                });
            }
        } else if (effect_type == "heal") {
            array_push(effects, {
                type: "heal",
                base_amount: real(cols[11]),
                scale_stat: cols[7],
                scale_percent: real(cols[8])
            });
        }

        // CC 효과 추가
        var cc_type = cols[15];
        if (cc_type != "" && cc_type != "0") {
            array_push(effects, {
                type: cc_type,
                duration: real(cols[16])
            });
        }

        global.skills[$ skill_id] = {
            id: skill_id,
            name: cols[1],
            mana_cost: real(cols[2]),
            cooldown: real(cols[3]),
            damage_type: cols[4],
            effects: effects,
            aoe_radius: real(cols[17]),
            target_type: cols[18],
            tags: parse_tags(cols[19])
        };
    }

    file_text_close(file);
    show_debug_message("Loaded " + string(struct_names_count(global.skills)) + " skills from CSV");
}

function get_skill(skill_id) {
    return global.skills[$ skill_id];
}
'''

new_unit_func = '''
// ============================================
// 유닛 데이터 (CSV 로드)
// ============================================

function init_unit_data() {
    global.unit_templates = {};
    global.next_unit_id = 0;

    var file = file_text_open_read("data/units.csv");
    if (file == -1) {
        show_debug_message("ERROR: data/units.csv not found!");
        return;
    }

    // 헤더 스킵
    file_text_read_string(file);
    file_text_readln(file);

    while (!file_text_eof(file)) {
        var line = file_text_read_string(file);
        file_text_readln(file);

        if (line == "") continue;

        var cols = csv_split_line(line);
        if (array_length(cols) < 35) continue;

        var unit_id = cols[0];
        if (unit_id == "") continue;

        // 스킬 파싱 (파이프 구분)
        var skills_arr = parse_tags(cols[33]);

        global.unit_templates[$ unit_id] = {
            type: unit_id,
            name: cols[1],
            race: cols[2],
            class: cols[3],
            base_stats: {
                hp: real(cols[4]),
                max_mana: real(cols[5]),
                physical_attack: real(cols[6]),
                magic_attack: real(cols[7]),
                physical_defense: real(cols[8]),
                magic_defense: real(cols[9]),
                attack_speed: real(cols[10]),
                movement_speed: real(cols[11]),
                attack_range: real(cols[12])
            },
            secondary_stats: {
                crit_chance: real(cols[13]),
                crit_damage: real(cols[14]),
                dodge_chance: real(cols[15]),
                accuracy: real(cols[16]),
                physical_lifesteal: real(cols[17]),
                magic_lifesteal: real(cols[18]),
                healing_power: real(cols[19]),
                physical_penetration: real(cols[20]),
                magic_penetration: real(cols[21]),
                cooldown_reduction: real(cols[22]),
                mana_regen: real(cols[23]),
                hp_regen: real(cols[24])
            },
            resistance: {
                cc_resist: real(cols[25]),
                debuff_resist: real(cols[26])
            },
            growth_per_level: {
                hp: real(cols[27]),
                mana: real(cols[28]),
                physical_attack: real(cols[29]),
                magic_attack: real(cols[30]),
                physical_defense: real(cols[31]),
                magic_defense: real(cols[32])
            },
            skills: skills_arr,
            tags: parse_tags(cols[34])
        };
    }

    file_text_close(file);
    show_debug_message("Loaded " + string(struct_names_count(global.unit_templates)) + " unit templates from CSV");
}
'''

with open(scr_data_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 기존 스킬/유닛 함수 찾아서 교체
import re

# init_skill_data 함수 교체
skill_pattern = r'// ={10,}\n// 스킬 데이터\n// ={10,}\n\nfunction init_skill_data\(\) \{[^}]*\{[^}]*\}[^}]*\{[^}]*\}[^}]*\}[^}]*\}\n\nfunction get_skill\(skill_id\) \{[^}]*\}'
skill_match = re.search(skill_pattern, content, re.DOTALL)

if skill_match:
    content = content[:skill_match.start()] + new_skill_func + content[skill_match.end():]
else:
    print("Could not find skill function pattern, trying simpler approach...")
    # 더 간단한 패턴 시도
    content = re.sub(
        r'function init_skill_data\(\) \{.*?\n\}\n\nfunction get_skill\(skill_id\) \{.*?\n\}',
        new_skill_func.strip(),
        content,
        flags=re.DOTALL
    )

# init_unit_data 함수 교체
unit_pattern = r'// ={10,}\n// 유닛 데이터\n// ={10,}\n\nfunction init_unit_data\(\) \{.*?\n\}'
unit_match = re.search(unit_pattern, content, re.DOTALL)

if unit_match:
    # create_unit_from_template 전까지만 교체
    content = content[:unit_match.start()] + new_unit_func + '\n' + content[unit_match.end():]
else:
    print("Could not find unit function pattern, trying simpler approach...")
    # init_unit_data 함수만 교체
    content = re.sub(
        r'function init_unit_data\(\) \{.*?skills: \[\]\n    \};\n\}',
        new_unit_func.strip(),
        content,
        flags=re.DOTALL
    )

with open(scr_data_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated scr_data.gml with CSV loading for skills and units!")
