/// @description 디버그룸 초기화

// 폰트 로드
global.font_korean = font_add("fonts/DungGeunMo.ttf", 14, false, false, 0xAC00, 0xD7A3);
if (global.font_korean != -1) {
    draw_set_font(global.font_korean);
}

// 데이터 초기화 (종족, 직업, 스킬, 유닛)
init_all_data();

// 종족/직업 목록 (CSV에서 동적으로 가져오기)
global.race_list = variable_struct_get_names(global.races);
global.class_list = variable_struct_get_names(global.classes);
global.current_race_idx = 0;
global.current_class_idx = 0;

// 드롭다운 상태
global.dropdown = {
    race_open: false,
    class_open: false,
    race_x: 560,
    race_y: 10,
    class_x: 720,
    class_y: 10,
    width: 140,
    item_height: 22
};

// 패널 상태
global.panels = {
    player_stat: { x: 10, y: 10, w: 220, h: 520, collapsed: false, title: "플레이어 유닛" },
    race_bonus: { x: 240, y: 10, w: 200, h: 300, collapsed: false, title: "종족 보너스" },
    class_bonus: { x: 240, y: 340, w: 200, h: 160, collapsed: false, title: "직업 보너스" },
    target_stat: { x: 1690, y: 10, w: 210, h: 200, collapsed: false, title: "타겟 더미" }
};

// 드래그 상태
global.drag = {
    active: false,
    target: undefined,
    target_type: "",  // "unit" or "panel"
    offset_x: 0,
    offset_y: 0
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
global.debug.player_unit.x = 700;
global.debug.player_unit.y = 550;

// 타겟 더미 생성
global.debug.target_dummy = create_unit_from_template("target_dummy", "enemy", 1);
global.debug.target_dummy.x = 1200;
global.debug.target_dummy.y = 550;

debug_log("=== 유닛 디버그룸 ===");
debug_log("SPACE: 파이어볼 | R: 더미 리셋");
debug_log("1~9: 레벨 변경");
debug_log("드래그: 유닛/패널 이동");
debug_log("패널 제목 클릭: 접기/펴기");
