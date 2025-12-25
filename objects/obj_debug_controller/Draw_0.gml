/// @description 디버그룸 렌더링

if (global.font_korean != -1) {
    draw_set_font(global.font_korean);
}

var player = global.debug.player_unit;
var dummy = global.debug.target_dummy;
var panels = global.panels;

// 배경
draw_set_color(c_dkgray);
draw_rectangle(0, 0, room_width, room_height, false);

// === 유닛 그리기 ===
draw_unit_box(player, c_blue, "플레이어");
draw_unit_box(dummy, c_red, "타겟");

// === 상태이상 아이콘 그리기 ===
draw_status_icons(player, player.x, player.y - 70);
draw_status_icons(dummy, dummy.x, dummy.y - 70);

// === 이펙트 그리기 ===
for (var i = 0; i < array_length(global.debug.effects); i++) {
    var fx = global.debug.effects[i];

    if (fx.type == "fireball") {
        draw_set_alpha(0.3);
        draw_set_color(c_red);
        draw_circle(fx.x, fx.y, 20, false);
        draw_set_alpha(1);
        draw_set_color(c_orange);
        draw_circle(fx.x, fx.y, 12, false);
        draw_set_color(c_yellow);
        draw_circle(fx.x, fx.y, 6, false);
    }
    else if (fx.type == "explosion") {
        var progress = fx.timer / fx.max_timer;
        draw_set_alpha(1 - progress);
        draw_set_color(c_red);
        draw_circle(fx.x, fx.y, fx.radius, true);
        draw_circle(fx.x, fx.y, fx.radius * 0.7, true);
        draw_set_alpha((1 - progress) * 0.5);
        draw_set_color(c_orange);
        draw_circle(fx.x, fx.y, fx.radius * 0.5, false);
        draw_set_color(c_yellow);
        draw_circle(fx.x, fx.y, fx.radius * 0.2, false);
    }
    else if (fx.type == "particle") {
        draw_set_alpha(fx.timer / 15);
        draw_set_color(fx.color);
        draw_circle(fx.x, fx.y, fx.size, false);
    }
    else if (fx.type == "dot_tick") {
        draw_set_alpha(fx.timer / 30);
        draw_set_color(c_orange);
        draw_set_halign(fa_center);
        draw_text(fx.x, fx.y, fx.text);
        draw_set_halign(fa_left);
    }
    else if (fx.type == "status_text") {
        draw_set_alpha(fx.timer / fx.max_timer);
        draw_set_color(fx.color);
        draw_set_halign(fa_center);
        draw_text(fx.x, fx.y, fx.text);
        draw_set_halign(fa_left);
    }
}
draw_set_alpha(1);

// === 패널 그리기 ===
var p = panels.player_stat;
draw_panel_stat_with_bonus(p.x, p.y, p.w, p.collapsed, player, p.title);

p = panels.race_bonus;
draw_panel_race_bonus(p.x, p.y, p.w, p.collapsed, p.title);

p = panels.class_bonus;
draw_panel_class_bonus(p.x, p.y, p.w, p.collapsed, p.title);

p = panels.target_stat;
draw_panel_stat(p.x, p.y, p.w, p.collapsed, dummy, p.title);

// === 종족/직업 드롭다운 UI ===
draw_dropdown_only();

// === 전투 로그 ===
draw_combat_log(10, room_height - 250);

// === 조작법 ===
draw_set_color(c_yellow);
draw_set_halign(fa_center);
draw_text(room_width/2, room_height - 290, "[SPACE] 파이어볼  [R] 더미 리셋  [1-9] 레벨");
draw_text(room_width/2, room_height - 270, "[T] 기절  [Y] 둔화  [U] 속박  [I] 침묵  [C] 정화");
draw_set_halign(fa_left);

// === 쿨다운 표시 ===
var cd = player.skill_cooldowns[$ "fireball"] ?? 0;
draw_set_halign(fa_center);
if (cd > 0) {
    draw_set_color(c_red);
    draw_text(room_width/2, room_height - 310, "쿨다운: " + string_format(cd, 1, 1) + "초");
} else if (!can_use_skill(player)) {
    draw_set_color(c_orange);
    draw_text(room_width/2, room_height - 310, "스킬 사용 불가 (기절/침묵)");
} else {
    draw_set_color(c_lime);
    draw_text(room_width/2, room_height - 310, "스킬 준비됨!");
}
draw_set_halign(fa_left);
