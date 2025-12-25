/// @file scr_race_data.gml
/// @desc 종족 데이터 (자동 생성: 2025-12-25 12:35:27)
/// @generated UDL Content Editor

function init_race_data() {
    global.races = {};

    // 인간
    global.races.human = {
        id: "human",
        name: "인간",
        description: "균형 잡힌 능력치를 가진 종족",
        hp_bonus: 0,
        atk_bonus: 0,
        def_bonus: 0,
        speed_bonus: 0,
        tags: []
    };

    // 엘프
    global.races.elf = {
        id: "elf",
        name: "엘프",
        description: "민첩하고 마법에 뛰어난 종족",
        hp_bonus: -10,
        atk_bonus: 0,
        def_bonus: -5,
        speed_bonus: 15,
        tags: ["elf"]
    };

    // 드워프
    global.races.dwarf = {
        id: "dwarf",
        name: "드워프",
        description: "강인하고 방어에 뛰어난 종족",
        hp_bonus: 15,
        atk_bonus: 5,
        def_bonus: 10,
        speed_bonus: -10,
        tags: ["dwarf"]
    };

    // 오크
    global.races.orc = {
        id: "orc",
        name: "오크",
        description: "강력한 공격력을 가진 호전적인 종족",
        hp_bonus: 10,
        atk_bonus: 15,
        def_bonus: 0,
        speed_bonus: -5,
        tags: ["orc", "greenskin"]
    };

    // 언데드
    global.races.undead = {
        id: "undead",
        name: "언데드",
        description: "죽음에서 되살아난 존재",
        hp_bonus: 0,
        atk_bonus: 0,
        def_bonus: 5,
        speed_bonus: -5,
        tags: ["undead", "dark"]
    };

    // 악마
    global.races.demon = {
        id: "demon",
        name: "악마",
        description: "지옥에서 온 사악한 존재",
        hp_bonus: 5,
        atk_bonus: 10,
        def_bonus: 0,
        speed_bonus: 5,
        tags: ["demon", "dark", "evil"]
    };

    // 슬라임
    global.races.slime = {
        id: "slime",
        name: "슬라임",
        description: "물리 공격에 강한 젤리 생명체",
        hp_bonus: 20,
        atk_bonus: -20,
        def_bonus: 15,
        speed_bonus: -15,
        tags: ["slime", "amorphous"]
    };

    // 야수
    global.races.beast = {
        id: "beast",
        name: "야수",
        description: "야생의 본능을 가진 생물",
        hp_bonus: 5,
        atk_bonus: 10,
        def_bonus: 0,
        speed_bonus: 10,
        tags: ["beast", "animal"]
    };

    // 용족
    global.races.dragon = {
        id: "dragon",
        name: "용족",
        description: "강력한 용의 혈통",
        hp_bonus: 20,
        atk_bonus: 15,
        def_bonus: 10,
        speed_bonus: 0,
        tags: ["dragon", "flying"]
    };

    // 구조물
    global.races.construct = {
        id: "construct",
        name: "구조물",
        description: "인공적으로 만들어진 존재",
        hp_bonus: 30,
        atk_bonus: 0,
        def_bonus: 20,
        speed_bonus: -20,
        tags: ["construct", "mechanical"]
    };

}