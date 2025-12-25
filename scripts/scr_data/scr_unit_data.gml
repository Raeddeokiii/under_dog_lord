/// @file scr_unit_data.gml
/// @desc 유닛 데이터 (자동 생성: 2025-12-25 12:35:27)
/// @generated UDL Content Editor

function init_unit_data_generated() {
    // 기존 데이터에 추가
    if (!variable_global_exists("unit_templates")) {
        global.unit_templates = {};
    }

    // 화염 마법사
    global.unit_templates.fire_mage = {
        type: "fire_mage",
        name: "화염 마법사",
        race: "human",
        class: "mage",
        rarity: "c",
        ai_type: "ai_melee_dps",
        deploy_position: "FC",

        base_stats: {
            hp: 300,
            max_mana: 100,
            physical_attack: 10,
            magic_attack: 80,
            physical_defense: 10,
            magic_defense: 30,
            attack_speed: 0.8,
            movement_speed: 80,
            attack_range: 5
        },

        secondary_stats: {
            crit_chance: 15,
            crit_damage: 150,
            dodge_chance: 5,
            accuracy: 100,
            physical_lifesteal: 0,
            magic_lifesteal: 0,
            healing_power: 0,
            physical_penetration: 0,
            magic_penetration: 10,
            cooldown_reduction: 0,
            mana_regen: 5,
            hp_regen: 0
        },

        resistance: {
            cc_resist: 0,
            debuff_resist: 0
        },

        growth_per_level: {
            hp: 30,
            mana: 10,
            magic_attack: 8,
            magic_defense: 3
        },

        sprites: {
        },

        skills: [{ skill_id: "fireball", unlock_level: 1 }],
        tags: []
    };

    // 타겟 더미
    global.unit_templates.target_dummy = {
        type: "target_dummy",
        name: "타겟 더미",
        race: "construct",
        class: "warrior",
        rarity: "c",
        ai_type: "ai_melee_dps",
        deploy_position: "FC",

        base_stats: {
            hp: 10000,
            max_mana: 0,
            physical_attack: 0,
            magic_attack: 0,
            physical_defense: 50,
            magic_defense: 50,
            attack_speed: 0.0,
            movement_speed: 0,
            attack_range: 0
        },

        secondary_stats: {
            crit_chance: 0,
            crit_damage: 0,
            dodge_chance: 0,
            accuracy: 0,
            physical_lifesteal: 0,
            magic_lifesteal: 0,
            healing_power: 0,
            physical_penetration: 0,
            magic_penetration: 0,
            cooldown_reduction: 0,
            mana_regen: 0,
            hp_regen: 100
        },

        resistance: {
            cc_resist: 100,
            debuff_resist: 100
        },

        growth_per_level: {
        },

        sprites: {
        },

        skills: [],
        tags: []
    };

}