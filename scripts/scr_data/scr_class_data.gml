/// @file scr_class_data.gml
/// @desc 직업 데이터 (자동 생성: 2025-12-25 12:35:27)
/// @generated UDL Content Editor

function init_class_data() {
    global.classes = {};

    // 전사
    global.classes.warrior = {
        id: "warrior",
        name: "전사",
        description: "",
        role: "딜러",
        attack_type: "근거리",
        hp_mod: 10,
        phys_atk_mod: 15,
        mag_atk_mod: -20,
        phys_def_mod: 5,
        mag_def_mod: 0,
        speed_mod: 0,
        atk_range_mod: 0,
        tags: ["melee", "physical"]
    };

    // 탱커
    global.classes.tank = {
        id: "tank",
        name: "탱커",
        description: "",
        role: "딜러",
        attack_type: "근거리",
        hp_mod: 30,
        phys_atk_mod: -10,
        mag_atk_mod: -20,
        phys_def_mod: 25,
        mag_def_mod: 15,
        speed_mod: -15,
        atk_range_mod: 0,
        tags: ["melee", "tank", "frontline"]
    };

    // 기사
    global.classes.knight = {
        id: "knight",
        name: "기사",
        description: "균형 잡힌 공방을 갖춘 전사 클래스",
        role: "탱커",
        attack_type: "근거리",
        hp_mod: 20,
        phys_atk_mod: 5,
        mag_atk_mod: -15,
        phys_def_mod: 15,
        mag_def_mod: 10,
        speed_mod: -5,
        atk_range_mod: 0,
        tags: ["melee", "tank", "physical"]
    };

    // 광전사
    global.classes.berserker = {
        id: "berserker",
        name: "광전사",
        description: "방어를 포기하고 극한의 공격력을 추구하는 클래스",
        role: "딜러",
        attack_type: "근거리",
        hp_mod: -5,
        phys_atk_mod: 35,
        mag_atk_mod: -20,
        phys_def_mod: -15,
        mag_def_mod: -10,
        speed_mod: 10,
        atk_range_mod: 0,
        tags: ["melee", "physical", "berserk"]
    };

    // 마법사
    global.classes.mage = {
        id: "mage",
        name: "마법사",
        description: "",
        role: "딜러",
        attack_type: "근거리",
        hp_mod: -15,
        phys_atk_mod: -20,
        mag_atk_mod: 25,
        phys_def_mod: -10,
        mag_def_mod: 15,
        speed_mod: 0,
        atk_range_mod: 2,
        tags: ["ranged", "magic", "caster"]
    };

    // 흑마법사
    global.classes.warlock = {
        id: "warlock",
        name: "흑마법사",
        description: "저주와 암흑 마법을 사용하는 클래스",
        role: "딜러",
        attack_type: "마법",
        hp_mod: -10,
        phys_atk_mod: -20,
        mag_atk_mod: 30,
        phys_def_mod: -5,
        mag_def_mod: 10,
        speed_mod: -5,
        atk_range_mod: 2,
        tags: ["ranged", "magic", "dark", "debuff"]
    };

    // 정령술사
    global.classes.elementalist = {
        id: "elementalist",
        name: "정령술사",
        description: "원소의 힘을 다루는 마법사",
        role: "딜러",
        attack_type: "마법",
        hp_mod: -10,
        phys_atk_mod: -20,
        mag_atk_mod: 25,
        phys_def_mod: -5,
        mag_def_mod: 20,
        speed_mod: 0,
        atk_range_mod: 3,
        tags: ["ranged", "magic", "elemental"]
    };

    // 사제
    global.classes.priest = {
        id: "priest",
        name: "사제",
        description: "",
        role: "딜러",
        attack_type: "근거리",
        hp_mod: 0,
        phys_atk_mod: -20,
        mag_atk_mod: 10,
        phys_def_mod: 0,
        mag_def_mod: 20,
        speed_mod: 0,
        atk_range_mod: 2,
        tags: ["ranged", "magic", "healer", "holy"]
    };

    // 성기사
    global.classes.paladin = {
        id: "paladin",
        name: "성기사",
        description: "신성한 힘으로 싸우며 치유도 가능한 클래스",
        role: "탱커",
        attack_type: "근거리",
        hp_mod: 15,
        phys_atk_mod: 5,
        mag_atk_mod: 5,
        phys_def_mod: 15,
        mag_def_mod: 15,
        speed_mod: -10,
        atk_range_mod: 0,
        tags: ["melee", "tank", "holy", "healer"]
    };

    // 성직자
    global.classes.cleric = {
        id: "cleric",
        name: "성직자",
        description: "신성 마법과 치유에 능한 서포터",
        role: "서포터",
        attack_type: "마법",
        hp_mod: 5,
        phys_atk_mod: -20,
        mag_atk_mod: 15,
        phys_def_mod: 5,
        mag_def_mod: 25,
        speed_mod: 0,
        atk_range_mod: 2,
        tags: ["ranged", "magic", "healer", "holy", "support"]
    };

    // 도적
    global.classes.rogue = {
        id: "rogue",
        name: "도적",
        description: "",
        role: "딜러",
        attack_type: "근거리",
        hp_mod: -10,
        phys_atk_mod: 20,
        mag_atk_mod: -20,
        phys_def_mod: -10,
        mag_def_mod: -5,
        speed_mod: 25,
        atk_range_mod: 0,
        tags: ["melee", "physical", "stealth", "fast"]
    };

    // 암살자
    global.classes.assassin = {
        id: "assassin",
        name: "암살자",
        description: "치명적인 일격을 가하는 암살 전문가",
        role: "딜러",
        attack_type: "근거리",
        hp_mod: -15,
        phys_atk_mod: 30,
        mag_atk_mod: -20,
        phys_def_mod: -15,
        mag_def_mod: -10,
        speed_mod: 30,
        atk_range_mod: 0,
        tags: ["melee", "physical", "stealth", "assassin", "crit"]
    };

    // 닌자
    global.classes.ninja = {
        id: "ninja",
        name: "닌자",
        description: "은신과 인술을 사용하는 민첩한 전사",
        role: "딜러",
        attack_type: "근거리",
        hp_mod: -10,
        phys_atk_mod: 15,
        mag_atk_mod: 10,
        phys_def_mod: -10,
        mag_def_mod: 0,
        speed_mod: 35,
        atk_range_mod: 1,
        tags: ["melee", "hybrid", "stealth", "fast"]
    };

    // 레인저
    global.classes.ranger = {
        id: "ranger",
        name: "레인저",
        description: "다양한 원거리 전투 기술을 갖춘 클래스",
        role: "딜러",
        attack_type: "원거리",
        hp_mod: 0,
        phys_atk_mod: 15,
        mag_atk_mod: -10,
        phys_def_mod: 0,
        mag_def_mod: 0,
        speed_mod: 15,
        atk_range_mod: 3,
        tags: ["ranged", "physical", "versatile"]
    };

    // 궁수
    global.classes.archer = {
        id: "archer",
        name: "궁수",
        description: "",
        role: "딜러",
        attack_type: "근거리",
        hp_mod: -10,
        phys_atk_mod: 25,
        mag_atk_mod: -20,
        phys_def_mod: -5,
        mag_def_mod: -5,
        speed_mod: 10,
        atk_range_mod: 4,
        tags: ["ranged", "physical", "archer"]
    };

    // 사냥꾼
    global.classes.hunter = {
        id: "hunter",
        name: "사냥꾼",
        description: "함정과 추적 능력을 갖춘 원거리 딜러",
        role: "딜러",
        attack_type: "원거리",
        hp_mod: 5,
        phys_atk_mod: 15,
        mag_atk_mod: -15,
        phys_def_mod: 5,
        mag_def_mod: 0,
        speed_mod: 10,
        atk_range_mod: 3,
        tags: ["ranged", "physical", "trap", "tracking"]
    };

    // 서포터
    global.classes.support = {
        id: "support",
        name: "서포터",
        description: "",
        role: "딜러",
        attack_type: "근거리",
        hp_mod: 5,
        phys_atk_mod: -20,
        mag_atk_mod: 10,
        phys_def_mod: 5,
        mag_def_mod: 15,
        speed_mod: 5,
        atk_range_mod: 2,
        tags: ["ranged", "magic", "support", "buff", "debuff"]
    };

    // 소환사
    global.classes.summoner = {
        id: "summoner",
        name: "소환사",
        description: "소환수를 불러내어 전투하는 클래스",
        role: "컨트롤러",
        attack_type: "마법",
        hp_mod: -5,
        phys_atk_mod: -20,
        mag_atk_mod: 20,
        phys_def_mod: -5,
        mag_def_mod: 10,
        speed_mod: 0,
        atk_range_mod: 2,
        tags: ["ranged", "magic", "summon", "minion"]
    };

    // 전사1
    global.classes.1 = {
        id: "1",
        name: "전사1",
        description: "",
        role: "딜러",
        attack_type: "근거리",
        hp_mod: 10,
        phys_atk_mod: 15,
        mag_atk_mod: -20,
        phys_def_mod: 5,
        mag_def_mod: 0,
        speed_mod: 0,
        atk_range_mod: 0,
        tags: ["melee", "physical"]
    };

    // 더미
    global.classes.dummy = {
        id: "dummy",
        name: "더미",
        description: "",
        role: "딜러",
        attack_type: "근거리",
        hp_mod: 0,
        phys_atk_mod: 0,
        mag_atk_mod: 0,
        phys_def_mod: 0,
        mag_def_mod: 0,
        speed_mod: 0,
        atk_range_mod: 0,
        tags: []
    };

}