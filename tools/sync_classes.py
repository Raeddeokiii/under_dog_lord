#!/usr/bin/env python3
"""Sync classes from content editor to game code"""
import json

# Load classes from content editor
with open('D:/gml_game/under_dog_lord/tools/data/classes.json', 'r', encoding='utf-8') as f:
    classes = json.load(f)

# Generate GML code for init_class_data
gml_lines = []
gml_lines.append("function init_class_data() {")
gml_lines.append("    global.classes = {};")
gml_lines.append("")

for class_id, cls in classes.items():
    # Skip test entries like "1"
    if class_id == "1":
        continue

    tags_str = json.dumps(cls.get("tags", []))

    line = f'    global.classes.{class_id} = {{ id: "{class_id}", name: "{cls["name"]}", '
    line += f'hp_mod: {cls["hp_mod"]}, phys_atk_mod: {cls["phys_atk_mod"]}, mag_atk_mod: {cls["mag_atk_mod"]}, '
    line += f'phys_def_mod: {cls["phys_def_mod"]}, mag_def_mod: {cls["mag_def_mod"]}, speed_mod: {cls["speed_mod"]}, '
    line += f'atk_range_mod: {cls["atk_range_mod"]}, tags: {tags_str} }};'
    gml_lines.append(line)

gml_lines.append("}")

# Generate class list for dropdown (excluding dummy and test entries)
class_list = [c for c in classes.keys() if c not in ["1", "dummy"]]
class_list.append("dummy")  # Add dummy at the end

print("=== init_class_data() ===")
print("\n".join(gml_lines))
print()
print("=== class_list for Create_0.gml ===")
print(f'global.class_list = {json.dumps(class_list)};')
print()
print(f"Total classes: {len(class_list)}")
