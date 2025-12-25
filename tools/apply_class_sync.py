#!/usr/bin/env python3
"""Apply synced classes to game code"""
import json
import re

# Load classes from content editor
with open('D:/gml_game/under_dog_lord/tools/data/classes.json', 'r', encoding='utf-8') as f:
    classes = json.load(f)

# Generate GML code for init_class_data
gml_lines = []
gml_lines.append("function init_class_data() {")
gml_lines.append("    global.classes = {};")
gml_lines.append("")

for class_id, cls in classes.items():
    if class_id == "1":
        continue
    tags_str = str(cls.get("tags", [])).replace("'", '"')
    line = f'    global.classes.{class_id} = {{ id: "{class_id}", name: "{cls["name"]}", '
    line += f'hp_mod: {cls["hp_mod"]}, phys_atk_mod: {cls["phys_atk_mod"]}, mag_atk_mod: {cls["mag_atk_mod"]}, '
    line += f'phys_def_mod: {cls["phys_def_mod"]}, mag_def_mod: {cls["mag_def_mod"]}, speed_mod: {cls["speed_mod"]}, '
    line += f'atk_range_mod: {cls["atk_range_mod"]}, tags: {tags_str} }};'
    gml_lines.append(line)

gml_lines.append("}")
new_init_class_data = "\n".join(gml_lines)

# Update scr_data.gml
with open('D:/gml_game/under_dog_lord/scripts/scr_data/scr_data.gml', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace init_class_data function
pattern = r'function init_class_data\(\) \{[^}]+\n\}'
content = re.sub(pattern, new_init_class_data, content)

with open('D:/gml_game/under_dog_lord/scripts/scr_data/scr_data.gml', 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated scr_data.gml")

# Update Create_0.gml - class_list
class_list = [c for c in classes.keys() if c not in ["1", "dummy"]]
class_list.append("dummy")
class_list_str = str(class_list).replace("'", '"')

with open('D:/gml_game/under_dog_lord/objects/obj_debug_controller/Create_0.gml', 'r', encoding='utf-8') as f:
    create_content = f.read()

# Replace class_list line
create_content = re.sub(
    r'global\.class_list = \[.*?\];',
    f'global.class_list = {class_list_str};',
    create_content
)

with open('D:/gml_game/under_dog_lord/objects/obj_debug_controller/Create_0.gml', 'w', encoding='utf-8') as f:
    f.write(create_content)
print("Updated Create_0.gml")

print(f"Synced {len(class_list)} classes")
