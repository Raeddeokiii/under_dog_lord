#!/usr/bin/env python3
"""Fix remaining is_cc/is_debuff checks"""

file_path = 'D:/gml_game/under_dog_lord/scripts/scr_status/scr_status.gml'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix cleanse_cc check
content = content.replace(
    'if (type_info != undefined && type_info.is_cc) {',
    'if (type_info != undefined && variable_struct_exists(type_info, "is_cc") && type_info.is_cc) {'
)

# Fix cleanse_debuffs check
content = content.replace(
    'if (type_info != undefined && type_info.is_debuff) {',
    'if (type_info != undefined && variable_struct_exists(type_info, "is_debuff") && type_info.is_debuff) {'
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Fixed remaining checks')
