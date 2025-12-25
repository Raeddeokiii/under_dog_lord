#!/usr/bin/env python3
"""Update debug controller with dropdown race/class selection"""

# Update Create_0.gml
create_content = '''/// @description 디버그룸 초기화

// 폰트 로드
global.font_korean = font_add("fonts/DungGeunMo.ttf", 14, false, false, 0xAC00, 0xD7A3);
if (global.font_korean != -1) {
    draw_set_font(global.font_korean);
}

// 데이터 초기화 (종족, 직업, 스킬, 유닛)
init_all_data();

// 종족/직업 목록
global.race_list = ["human", "elf", "dwarf", "orc", "undead", "demon", "slime", "beast", "dragon", "construct"];
global.class_list = ["warrior", "tank", "mage", "priest", "rogue", "archer", "support"];
global.current_race_idx = 0;  // human
global.current_class_idx = 2; // mage

// 드롭다운 상태
global.dropdown = {
    race_open: false,
    class_open: false,
    race_x: 240,
    race_y: 10,
    class_x: 400,
    class_y: 10,
    width: 140,
    item_height: 22
};

// 디버그 상태
global.debug = {
    player_unit: undefined,
    target_dummy: undefined,
    combat_log: [],
    max_log_lines: 15,
    show_stats: true,
    effects: []
};

// 화염 마법사 생성 (플레이어 유닛)
global.debug.player_unit = create_unit_from_template("fire_mage", "ally", 1);
global.debug.player_unit.x = 300;
global.debug.player_unit.y = 400;

// 타겟 더미 생성
global.debug.target_dummy = create_unit_from_template("target_dummy", "enemy", 1);
global.debug.target_dummy.x = 700;
global.debug.target_dummy.y = 400;

debug_log("=== 유닛 디버그룸 ===");
debug_log("화염 마법사 (Lv.1) 생성됨");
debug_log("타겟 더미 생성됨");
debug_log("");
debug_log("[조작법]");
debug_log("SPACE: 파이어볼 시전");
debug_log("R: 더미 HP 리셋");
debug_log("1~9: 레벨 변경");
debug_log("마우스: 종족/직업 드롭다운");
'''

print("Script ready")
