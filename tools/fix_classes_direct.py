#!/usr/bin/env python3
"""Directly fix init_class_data in scr_data.gml"""

with open('D:/gml_game/under_dog_lord/scripts/scr_data/scr_data.gml', 'r', encoding='utf-8') as f:
    content = f.read()

old_func = '''function init_class_data() {
    global.classes = {};

    global.classes.warrior = { id: "warrior", name: "전사", hp_mod: 10, phys_atk_mod: 15, mag_atk_mod: -20, phys_def_mod: 5, mag_def_mod: 0, speed_mod: 0, atk_range_mod: 0, tags: ["melee", "physical"] };
    global.classes.tank = { id: "tank", name: "탱커", hp_mod: 30, phys_atk_mod: -10, mag_atk_mod: -20, phys_def_mod: 25, mag_def_mod: 15, speed_mod: -15, atk_range_mod: 0, tags: ["melee", "tank", "frontline"] };
    global.classes.mage = { id: "mage", name: "마법사", hp_mod: -15, phys_atk_mod: -20, mag_atk_mod: 25, phys_def_mod: -10, mag_def_mod: 15, speed_mod: 0, atk_range_mod: 2, tags: ["ranged", "magic", "caster"] };
    global.classes.priest = { id: "priest", name: "사제", hp_mod: 0, phys_atk_mod: -20, mag_atk_mod: 10, phys_def_mod: 0, mag_def_mod: 20, speed_mod: 0, atk_range_mod: 2, tags: ["ranged", "magic", "healer", "holy"] };
    global.classes.rogue = { id: "rogue", name: "도적", hp_mod: -10, phys_atk_mod: 20, mag_atk_mod: -20, phys_def_mod: -10, mag_def_mod: -5, speed_mod: 25, atk_range_mod: 0, tags: ["melee", "physical", "stealth", "fast"] };
    global.classes.archer = { id: "archer", name: "궁수", hp_mod: -10, phys_atk_mod: 25, mag_atk_mod: -20, phys_def_mod: -5, mag_def_mod: -5, speed_mod: 10, atk_range_mod: 4, tags: ["ranged", "physical", "archer"] };
    global.classes.support = { id: "support", name: "서포터", hp_mod: 5, phys_atk_mod: -20, mag_atk_mod: 10, phys_def_mod: 5, mag_def_mod: 15, speed_mod: 5, atk_range_mod: 2, tags: ["ranged", "magic", "support", "buff", "debuff"] };
    global.classes.dummy = { id: "dummy", name: "더미", hp_mod: 0, phys_atk_mod: 0, mag_atk_mod: 0, phys_def_mod: 0, mag_def_mod: 0, speed_mod: 0, atk_range_mod: 0, tags: [] };
}'''

new_func = '''function init_class_data() {
    global.classes = {};

    global.classes.warrior = { id: "warrior", name: "전사", hp_mod: 10, phys_atk_mod: 15, mag_atk_mod: -20, phys_def_mod: 5, mag_def_mod: 0, speed_mod: 0, atk_range_mod: 0, tags: ["melee", "physical"] };
    global.classes.tank = { id: "tank", name: "탱커", hp_mod: 30, phys_atk_mod: -10, mag_atk_mod: -20, phys_def_mod: 25, mag_def_mod: 15, speed_mod: -15, atk_range_mod: 0, tags: ["melee", "tank", "frontline"] };
    global.classes.knight = { id: "knight", name: "기사", hp_mod: 20, phys_atk_mod: 5, mag_atk_mod: -15, phys_def_mod: 15, mag_def_mod: 10, speed_mod: -5, atk_range_mod: 0, tags: ["melee", "tank", "physical"] };
    global.classes.berserker = { id: "berserker", name: "광전사", hp_mod: -5, phys_atk_mod: 35, mag_atk_mod: -20, phys_def_mod: -15, mag_def_mod: -10, speed_mod: 10, atk_range_mod: 0, tags: ["melee", "physical", "berserk"] };
    global.classes.mage = { id: "mage", name: "마법사", hp_mod: -15, phys_atk_mod: -20, mag_atk_mod: 25, phys_def_mod: -10, mag_def_mod: 15, speed_mod: 0, atk_range_mod: 2, tags: ["ranged", "magic", "caster"] };
    global.classes.warlock = { id: "warlock", name: "흑마법사", hp_mod: -10, phys_atk_mod: -20, mag_atk_mod: 30, phys_def_mod: -5, mag_def_mod: 10, speed_mod: -5, atk_range_mod: 2, tags: ["ranged", "magic", "dark", "debuff"] };
    global.classes.elementalist = { id: "elementalist", name: "정령술사", hp_mod: -10, phys_atk_mod: -20, mag_atk_mod: 25, phys_def_mod: -5, mag_def_mod: 20, speed_mod: 0, atk_range_mod: 3, tags: ["ranged", "magic", "elemental"] };
    global.classes.priest = { id: "priest", name: "사제", hp_mod: 0, phys_atk_mod: -20, mag_atk_mod: 10, phys_def_mod: 0, mag_def_mod: 20, speed_mod: 0, atk_range_mod: 2, tags: ["ranged", "magic", "healer", "holy"] };
    global.classes.paladin = { id: "paladin", name: "성기사", hp_mod: 15, phys_atk_mod: 5, mag_atk_mod: 5, phys_def_mod: 15, mag_def_mod: 15, speed_mod: -10, atk_range_mod: 0, tags: ["melee", "tank", "holy", "healer"] };
    global.classes.cleric = { id: "cleric", name: "성직자", hp_mod: 5, phys_atk_mod: -20, mag_atk_mod: 15, phys_def_mod: 5, mag_def_mod: 25, speed_mod: 0, atk_range_mod: 2, tags: ["ranged", "magic", "healer", "holy", "support"] };
    global.classes.rogue = { id: "rogue", name: "도적", hp_mod: -10, phys_atk_mod: 20, mag_atk_mod: -20, phys_def_mod: -10, mag_def_mod: -5, speed_mod: 25, atk_range_mod: 0, tags: ["melee", "physical", "stealth", "fast"] };
    global.classes.assassin = { id: "assassin", name: "암살자", hp_mod: -15, phys_atk_mod: 30, mag_atk_mod: -20, phys_def_mod: -15, mag_def_mod: -10, speed_mod: 30, atk_range_mod: 0, tags: ["melee", "physical", "stealth", "assassin", "crit"] };
    global.classes.ninja = { id: "ninja", name: "닌자", hp_mod: -10, phys_atk_mod: 15, mag_atk_mod: 10, phys_def_mod: -10, mag_def_mod: 0, speed_mod: 35, atk_range_mod: 1, tags: ["melee", "hybrid", "stealth", "fast"] };
    global.classes.ranger = { id: "ranger", name: "레인저", hp_mod: 0, phys_atk_mod: 15, mag_atk_mod: -10, phys_def_mod: 0, mag_def_mod: 0, speed_mod: 15, atk_range_mod: 3, tags: ["ranged", "physical", "versatile"] };
    global.classes.archer = { id: "archer", name: "궁수", hp_mod: -10, phys_atk_mod: 25, mag_atk_mod: -20, phys_def_mod: -5, mag_def_mod: -5, speed_mod: 10, atk_range_mod: 4, tags: ["ranged", "physical", "archer"] };
    global.classes.hunter = { id: "hunter", name: "사냥꾼", hp_mod: 5, phys_atk_mod: 15, mag_atk_mod: -15, phys_def_mod: 5, mag_def_mod: 0, speed_mod: 10, atk_range_mod: 3, tags: ["ranged", "physical", "trap", "tracking"] };
    global.classes.support = { id: "support", name: "서포터", hp_mod: 5, phys_atk_mod: -20, mag_atk_mod: 10, phys_def_mod: 5, mag_def_mod: 15, speed_mod: 5, atk_range_mod: 2, tags: ["ranged", "magic", "support", "buff", "debuff"] };
    global.classes.summoner = { id: "summoner", name: "소환사", hp_mod: -5, phys_atk_mod: -20, mag_atk_mod: 20, phys_def_mod: -5, mag_def_mod: 10, speed_mod: 0, atk_range_mod: 2, tags: ["ranged", "magic", "summon", "minion"] };
    global.classes.dummy = { id: "dummy", name: "더미", hp_mod: 0, phys_atk_mod: 0, mag_atk_mod: 0, phys_def_mod: 0, mag_def_mod: 0, speed_mod: 0, atk_range_mod: 0, tags: [] };
}'''

if old_func in content:
    content = content.replace(old_func, new_func)
    with open('D:/gml_game/under_dog_lord/scripts/scr_data/scr_data.gml', 'w', encoding='utf-8') as f:
        f.write(content)
    print("Fixed init_class_data - added 19 classes")
else:
    print("Old function not found - checking current classes...")
    import re
    matches = re.findall(r'global\.classes\.(\w+)\s*=', content)
    print(f"Current classes: {matches}")
    print(f"Count: {len(matches)}")
