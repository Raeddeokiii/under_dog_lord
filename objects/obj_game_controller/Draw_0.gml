/// @description 게임 렌더링

if (global.font_korean != -1) {
    draw_set_font(global.font_korean);
}

// 배경
draw_set_color(c_dkgray);
draw_rectangle(0, 0, room_width, room_height, false);

// 전투 UI 렌더링
draw_battle_ui();

// 자원 UI 렌더링
draw_resource_ui();

// 건물 UI 렌더링 (간략화)
draw_buildings();

// 조작 안내
draw_set_halign(fa_center);
draw_set_color(c_white);
draw_text(room_width / 2, room_height - 50, "[ESC] 디버그룸 | [R] 재시작");
draw_set_halign(fa_left);
