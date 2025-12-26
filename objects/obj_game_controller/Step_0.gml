/// @description 게임 메인 루프

var delta = 1/60;

// 전투 업데이트
update_battle(delta);

// 경제 업데이트 (건물, 자원 등)
update_economy(delta);

// ESC: 디버그룸으로 전환
if (keyboard_check_pressed(vk_escape)) {
    // 디버그 컨트롤러로 전환
    instance_destroy();
    instance_create_layer(0, 0, "Instances", obj_debug_controller);
    combat_log("=== 디버그 모드 ===");
}

// R: 전투 재시작
if (keyboard_check_pressed(ord("R"))) {
    // 시스템 재초기화
    init_resource_system();
    init_building_system();
    start_battle();
    combat_log("=== 전투 재시작 ===");
}
