/// @description 게임 초기화

// 폰트 로드
global.font_korean = font_add("fonts/DungGeunMo.ttf", 14, false, false, 0xAC00, 0xD7A3);
if (global.font_korean != -1) {
    draw_set_font(global.font_korean);
}

// 디버그 모드 플래그
global.debug_mode = false;

// 시스템 초기화
init_resource_system();
init_building_system();
init_skill_templates();
init_unit_costs();

// 전투 시작
start_battle();

combat_log("=== 게임 시작 ===");
combat_log("[ESC] 디버그룸으로 전환");
