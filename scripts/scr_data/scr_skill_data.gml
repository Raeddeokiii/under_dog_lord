/// @file scr_skill_data.gml
/// @desc 스킬 데이터 (자동 생성: 2025-12-25 12:35:27)
/// @generated UDL Content Editor

function init_skill_data_generated() {
    // 기존 데이터에 추가
    if (!variable_global_exists("skills")) {
        global.skills = {};
    }

    // 파이어볼
    global.skills.fireball = {
        id: "fireball",
        name: "파이어볼",
        description: "",
        mana_cost: 30,
        cooldown: 3.0,
        cast_time: 0.0,

        targeting: {
            base: "enemy",
            select_method: "nearest",
            count: 1,
            range: 5
        },

        effects: [
            {
                type: "damage",
                amount: 50,
                damage_type: "physical"
,
                scale_stat: "magic_attack"
,
                scale_percent: 150
            },
            {
                type: "dot",
                amount: 10,
                duration: 3.0,
                tick_rate: 1.0,
                damage_type: "physical"
            }
        ],
        ai_hints: {
            priority: 50,
            use_when: "always",
            min_targets: 1
        }
    };

}