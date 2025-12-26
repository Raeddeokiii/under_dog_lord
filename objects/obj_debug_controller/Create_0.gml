/// @description 디버그룸 초기화

// 폰트 로드
global.font_korean = font_add("fonts/DungGeunMo.ttf", 14, false, false, 0xAC00, 0xD7A3);
if (global.font_korean != -1) {
    draw_set_font(global.font_korean);
}

// 데이터 초기화 (종족, 직업, 스킬, 유닛)
init_all_data();

// 종족/직업/재능 목록 (CSV에서 동적으로 가져오기)
global.race_list = variable_struct_get_names(global.races);
global.class_list = variable_struct_get_names(global.classes);
global.talent_list = variable_struct_get_names(global.talents);
global.current_race_idx = 0;
global.current_class_idx = 0;
global.current_talent_idx = 0;

// 스킬 목록 (CSV에서 동적으로 가져오기)
global.skill_list = variable_struct_get_names(global.skills);
global.current_skill_idx = 0;

// 드롭다운 상태
global.dropdown = {
    race_open: false,
    class_open: false,
    talent_open: false,
    skill_open: false,
    race_x: 560,
    race_y: 10,
    class_x: 720,
    class_y: 10,
    talent_x: 880,
    talent_y: 10,
    skill_x: 1040,
    skill_y: 10,
    width: 140,
    item_height: 22
};

// 패널 상태 (좌측: 아군, 우측: 적군)
global.panels = {
    // 좌측 - 아군 패널
    ally_stat: { x: 10, y: 10, w: 220, h: 520, collapsed: false, title: "아군 유닛" },
    ally_race: { x: 240, y: 10, w: 200, h: 300, collapsed: false, title: "종족 보너스" },
    ally_class: { x: 240, y: 320, w: 200, h: 160, collapsed: false, title: "직업 보너스" },
    ally_talent: { x: 450, y: 10, w: 200, h: 120, collapsed: false, title: "재능" },
    // 우측 - 적군 패널
    enemy_stat: { x: 1690, y: 10, w: 220, h: 520, collapsed: false, title: "적 유닛" },
    enemy_race: { x: 1460, y: 10, w: 200, h: 300, collapsed: false, title: "종족 보너스" },
    enemy_class: { x: 1460, y: 320, w: 200, h: 160, collapsed: false, title: "직업 보너스" },
    enemy_talent: { x: 1250, y: 10, w: 200, h: 120, collapsed: false, title: "재능" }
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
    ally_unit: undefined,      // 아군 유닛 추가
    target_dummy: undefined,
    enemy_dummy2: undefined,   // 적2 추가
    combat_log: [],
    max_log_lines: 15,
    show_stats: true,
    effects: [],

    // 유닛 선택 시스템
    selected_ally: undefined,   // 선택된 아군 (스킬 시전자)
    selected_enemy: undefined,  // 선택된 적 (타겟)
    all_units: []               // 모든 유닛 배열
};

// === 4유닛 시스템 레이아웃 ===
// 화면 중앙 기준으로 좌/우 진영 분리
var center_x = room_width / 2;
var ally_x = center_x - 200;    // 왼쪽 진영 (아군)
var enemy_x = center_x + 200;   // 오른쪽 진영 (적군)
var row1_y = 400;               // 상단 행
var row2_y = 600;               // 하단 행

// === 아군 진영 (왼쪽) ===
// 플레이어 유닛 (화염 마법사)
global.debug.player_unit = create_unit_from_template("fire_mage", "ally", 1);
global.debug.player_unit.x = ally_x - 60;
global.debug.player_unit.y = row1_y;
global.debug.player_unit.faction = "ally";
global.debug.player_unit.display_name = "플레이어";
global.debug.player_unit.talent = global.talent_list[0];
talent_init_unit(global.debug.player_unit);

// 아군 유닛 (전사)
global.debug.ally_unit = create_unit_from_template("warrior", "ally", 1);
global.debug.ally_unit.x = ally_x + 60;
global.debug.ally_unit.y = row2_y;
global.debug.ally_unit.faction = "ally";
global.debug.ally_unit.display_name = "아군";
global.debug.ally_unit.talent = "";
talent_init_unit(global.debug.ally_unit);

// === 적군 진영 (오른쪽) ===
// 적 유닛 1 (타겟 더미)
global.debug.target_dummy = create_unit_from_template("target_dummy", "enemy", 1);
global.debug.target_dummy.x = enemy_x - 60;
global.debug.target_dummy.y = row1_y;
global.debug.target_dummy.faction = "enemy";
global.debug.target_dummy.display_name = "적1";
global.debug.target_dummy.talent = "";
talent_init_unit(global.debug.target_dummy);

// 적 유닛 2 (얼음 마법사)
global.debug.enemy_dummy2 = create_unit_from_template("ice_mage", "enemy", 1);
global.debug.enemy_dummy2.x = enemy_x + 60;
global.debug.enemy_dummy2.y = row2_y;
global.debug.enemy_dummy2.faction = "enemy";
global.debug.enemy_dummy2.display_name = "적2";
global.debug.enemy_dummy2.talent = "";
talent_init_unit(global.debug.enemy_dummy2);

// 전체 유닛 배열 구성
global.debug.all_units = [
    global.debug.player_unit,
    global.debug.ally_unit,
    global.debug.target_dummy,
    global.debug.enemy_dummy2
];

// 기본 선택 상태 (플레이어 → 적1)
global.debug.selected_ally = global.debug.player_unit;
global.debug.selected_enemy = global.debug.target_dummy;
global.debug.last_selected_side = "ally";  // 마지막 선택된 진영 ("ally" 또는 "enemy")

// 유닛 수 설정 (1명 or 2명)
global.debug.ally_count = 2;   // 1 또는 2
global.debug.enemy_count = 2;  // 1 또는 2

// 더미 자동 회복 토글
global.debug.dummy_auto_regen = true;

// === 적 자동 공격 시스템 ===
global.debug.enemy_auto_attack = false;      // 적 자동 공격 ON/OFF
global.debug.enemy_ignore_cooldown = false;  // 쿨타임 무시 여부
global.debug.enemy_infinite_mana = false;    // 마나 무한 여부
global.debug.enemy_attack_interval = 1.5;    // 쿨무시 시 공격 간격(초)
global.debug.enemy_attack_timer = 0;         // 공격 타이머
global.debug.enemy_target_mode = 0;          // 타겟 모드: 0=모두, 1=플레이어만, 2=아군만

// === 아군 자동 기본공격 시스템 ===
global.debug.ally_auto_attack = false;       // 아군 자동 공격 ON/OFF

// === 부활 시스템 ===
global.debug.respawn_enabled = true;         // 부활 ON/OFF
global.debug.respawn_delay = 5.0;            // 부활 대기 시간(초)
global.debug.respawn_timers = ds_map_create(); // 유닛별 부활 타이머

// === 버튼 UI 시스템 ===
global.debug.buttons = [];
global.debug.btn_skill_use = false;
global.debug.btn_attack_sim = false;

// 버튼 생성 헬퍼 함수
var create_button = function(id, label, x, y, w, h, color, action) {
    return {
        id: id,
        label: label,
        x: x,
        y: y,
        w: w,
        h: h,
        color: color,
        hover: false,
        action: action
    };
};

// 패널 위치 계산
var panel_y = room_height - 200;
var left_panel_x = 50;      // 아군 패널 (왼쪽)
var right_panel_x = room_width - 350;  // 적군 패널 (오른쪽)
var btn_center_x = room_width / 2;
var btn_w = 70;
var btn_h = 28;
var btn_gap = 5;

// === 중앙 패널 (공용) ===
array_push(global.debug.buttons, create_button("basic_attack", "기본공격[G]", btn_center_x - 180, panel_y, 90, 35, c_white, "basic_attack"));
array_push(global.debug.buttons, create_button("skill_use", "스킬[SPACE]", btn_center_x - 80, panel_y, 90, 35, c_lime, "skill_use"));
array_push(global.debug.buttons, create_button("attack_sim", "적 공격[V]", btn_center_x + 20, panel_y, 90, 35, c_orange, "attack_sim"));
array_push(global.debug.buttons, create_button("reset_all", "전체 리셋", btn_center_x - 50, panel_y + 45, 100, 30, c_silver, "reset_all"));

// === 왼쪽 패널 (아군 조작) ===
var lx = left_panel_x;
var ly = panel_y;

// HP 조절 + 자동공격
array_push(global.debug.buttons, create_button("ally_hp_down", "HP -", lx, ly, 50, btn_h, c_red, "ally_hp_down"));
array_push(global.debug.buttons, create_button("ally_hp_up", "HP +", lx + 55, ly, 50, btn_h, c_lime, "ally_hp_up"));
array_push(global.debug.buttons, create_button("ally_cooldown", "쿨초기화", lx + 110, ly, 70, btn_h, c_aqua, "ally_cooldown"));
array_push(global.debug.buttons, create_button("ally_auto_attack", "자동공격", lx + 185, ly, 60, btn_h, c_yellow, "ally_auto_attack"));

// 상태이상
ly += btn_h + btn_gap;
array_push(global.debug.buttons, create_button("cc_stun", "기절", lx, ly, 45, btn_h, c_yellow, "cc_stun"));
array_push(global.debug.buttons, create_button("cc_slow", "둔화", lx + 50, ly, 45, btn_h, c_aqua, "cc_slow"));
array_push(global.debug.buttons, create_button("cc_root", "속박", lx + 100, ly, 45, btn_h, c_green, "cc_root"));
array_push(global.debug.buttons, create_button("cc_silence", "침묵", lx + 150, ly, 45, btn_h, c_purple, "cc_silence"));
array_push(global.debug.buttons, create_button("cc_cleanse", "정화", lx + 200, ly, 45, btn_h, c_white, "cc_cleanse"));

// 레벨
ly += btn_h + btn_gap;
for (var lv = 1; lv <= 9; lv++) {
    array_push(global.debug.buttons, create_button("level_" + string(lv), string(lv), lx + (lv-1) * 28, ly, 25, btn_h, c_gray, "level_" + string(lv)));
}

// 아군 수 토글
array_push(global.debug.buttons, create_button("ally_count", "2명", lx + 260, ly, 40, btn_h, c_blue, "ally_count"));

// === 오른쪽 패널 (적군 조작) ===
var rx = right_panel_x;
var ry = panel_y;

// HP 조절 + 적 수 토글
array_push(global.debug.buttons, create_button("enemy_hp_down", "HP -", rx, ry, 50, btn_h, c_red, "enemy_hp_down"));
array_push(global.debug.buttons, create_button("enemy_hp_up", "HP +", rx + 55, ry, 50, btn_h, c_lime, "enemy_hp_up"));
array_push(global.debug.buttons, create_button("enemy_count", "2명", rx + 115, ry, 40, btn_h, c_red, "enemy_count"));

// 자동 공격 토글
ry += btn_h + btn_gap;
array_push(global.debug.buttons, create_button("auto_attack", "자동공격", rx, ry, 60, btn_h, c_orange, "auto_attack"));
array_push(global.debug.buttons, create_button("ignore_cd", "쿨무시", rx + 65, ry, 50, btn_h, c_yellow, "ignore_cd"));
array_push(global.debug.buttons, create_button("infinite_mana", "마나무한", rx + 120, ry, 55, btn_h, c_aqua, "infinite_mana"));

// 자동 공격 타겟 선택
ry += btn_h + btn_gap;
array_push(global.debug.buttons, create_button("target_mode", "타겟:모두", rx, ry, 75, btn_h, c_fuchsia, "target_mode"));

// 타겟 순환
array_push(global.debug.buttons, create_button("next_target", "타겟 변경", rx + 80, ry, 70, btn_h, c_red, "next_target"));
array_push(global.debug.buttons, create_button("next_caster", "시전자", rx + 155, ry, 50, btn_h, c_blue, "next_caster"));

// 길찾기 시스템 초기화 (60x34 그리드, 32px 셀)
pf_init(60, 34, 32, true);
global.debug.show_pathfinding = false;
global.debug.current_path = undefined;
global.debug.wall_edit_mode = false;  // 벽 편집 모드

// AI 테스트 모드
global.debug.ai_enabled = false;
global.debug.enemies = [];
global.debug.allies = [];

// 모든 유닛에 AI 초기화
global.debug.player_unit.ai_type = "mage";
ai_init_unit(global.debug.player_unit);

global.debug.ally_unit.ai_type = "warrior";
ai_init_unit(global.debug.ally_unit);

global.debug.target_dummy.ai_type = "warrior";
ai_init_unit(global.debug.target_dummy);

global.debug.enemy_dummy2.ai_type = "mage";
ai_init_unit(global.debug.enemy_dummy2);

// 유닛 목록 설정
array_push(global.debug.allies, global.debug.player_unit);
array_push(global.debug.allies, global.debug.ally_unit);
array_push(global.debug.enemies, global.debug.target_dummy);
array_push(global.debug.enemies, global.debug.enemy_dummy2);

debug_log("=== 4유닛 디버그룸 ===");
debug_log("[클릭] 유닛 선택 | [SPACE] 스킬 사용");
debug_log("[V] 적 공격 시뮬레이션 | [R] 전체 리셋");
debug_log("[Tab] 타겟 순환 | [1-9] 레벨");
