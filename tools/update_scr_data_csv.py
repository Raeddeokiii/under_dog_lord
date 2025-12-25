#!/usr/bin/env python3
"""scr_data.gml을 CSV 로드 방식으로 업데이트"""

import re

scr_data_path = 'D:/gml_game/under_dog_lord/scripts/scr_data/scr_data.gml'

new_header = '''/// @file scr_data.gml
/// @desc 스킬 및 유닛 데이터

// ============================================
// CSV 파싱 유틸리티
// ============================================

/// @function csv_split_line(line)
/// @desc CSV 한 줄을 배열로 분리
function csv_split_line(line) {
    var result = [];
    var current = "";
    var len = string_length(line);

    for (var i = 1; i <= len; i++) {
        var ch = string_char_at(line, i);
        if (ch == ",") {
            array_push(result, current);
            current = "";
        } else {
            current += ch;
        }
    }
    array_push(result, current);
    return result;
}

/// @function parse_tags(tag_str)
/// @desc 파이프(|) 구분 태그 문자열을 배열로 변환
function parse_tags(tag_str) {
    if (tag_str == "" || tag_str == undefined) return [];
    var result = [];
    var current = "";
    var len = string_length(tag_str);

    for (var i = 1; i <= len; i++) {
        var ch = string_char_at(tag_str, i);
        if (ch == "|") {
            if (current != "") array_push(result, current);
            current = "";
        } else {
            current += ch;
        }
    }
    if (current != "") array_push(result, current);
    return result;
}

// ============================================
// 종족 데이터 (CSV 로드)
// ============================================

function init_race_data() {
    global.races = {};

    var file = file_text_open_read("data/races.csv");
    if (file == -1) {
        show_debug_message("ERROR: data/races.csv not found!");
        return;
    }

    // 헤더 스킵
    var header = file_text_read_string(file);
    file_text_readln(file);

    while (!file_text_eof(file)) {
        var line = file_text_read_string(file);
        file_text_readln(file);

        if (line == "") continue;

        var cols = csv_split_line(line);
        if (array_length(cols) < 21) continue;

        var race_id = cols[0];
        if (race_id == "") continue;

        global.races[$ race_id] = {
            id: race_id,
            name: cols[1],
            hp: real(cols[2]),
            mana: real(cols[3]),
            phys_atk: real(cols[4]),
            mag_atk: real(cols[5]),
            phys_def: real(cols[6]),
            mag_def: real(cols[7]),
            atk_speed: real(cols[8]),
            move_speed: real(cols[9]),
            crit_chance: real(cols[10]),
            crit_damage: real(cols[11]),
            dodge: real(cols[12]),
            accuracy: real(cols[13]),
            lifesteal: real(cols[14]),
            healing_power: real(cols[15]),
            hp_regen: real(cols[16]),
            mana_regen: real(cols[17]),
            cc_resist: real(cols[18]),
            debuff_resist: real(cols[19]),
            tags: parse_tags(cols[20])
        };
    }

    file_text_close(file);
    show_debug_message("Loaded " + string(struct_names_count(global.races)) + " races from CSV");
}

// ============================================
// 직업 데이터 (CSV 로드)
// ============================================

function init_class_data() {
    global.classes = {};

    var file = file_text_open_read("data/classes.csv");
    if (file == -1) {
        show_debug_message("ERROR: data/classes.csv not found!");
        return;
    }

    // 헤더 스킵
    var header = file_text_read_string(file);
    file_text_readln(file);

    while (!file_text_eof(file)) {
        var line = file_text_read_string(file);
        file_text_readln(file);

        if (line == "") continue;

        var cols = csv_split_line(line);
        if (array_length(cols) < 10) continue;

        var class_id = cols[0];
        if (class_id == "") continue;

        global.classes[$ class_id] = {
            id: class_id,
            name: cols[1],
            hp_mod: real(cols[2]),
            phys_atk_mod: real(cols[3]),
            mag_atk_mod: real(cols[4]),
            phys_def_mod: real(cols[5]),
            mag_def_mod: real(cols[6]),
            speed_mod: real(cols[7]),
            atk_range_mod: real(cols[8]),
            tags: parse_tags(cols[9])
        };
    }

    file_text_close(file);
    show_debug_message("Loaded " + string(struct_names_count(global.classes)) + " classes from CSV");
}

'''

with open(scr_data_path, 'r', encoding='utf-8') as f:
    content = f.read()

# get_race_bonus 함수부터 끝까지 유지
match = re.search(r'(function get_race_bonus\(race_id\).*)', content, re.DOTALL)
if match:
    rest_of_file = match.group(1)
    new_content = new_header + rest_of_file

    with open(scr_data_path, 'w', encoding='utf-8') as f:
        f.write(new_content)

    print("scr_data.gml updated to use CSV loading!")
else:
    print("ERROR: Could not find get_race_bonus function")
