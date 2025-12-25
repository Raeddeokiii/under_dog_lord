#!/usr/bin/env python3
"""Fix is_debuff check in scr_status.gml"""

file_path = 'D:/gml_game/under_dog_lord/scripts/scr_status/scr_status.gml'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix is_cc check
content = content.replace(
    'if (type_info.is_cc) {',
    'if (variable_struct_exists(type_info, "is_cc") && type_info.is_cc) {'
)

# Fix is_debuff check
content = content.replace(
    'if (type_info.is_debuff) {',
    'if (variable_struct_exists(type_info, "is_debuff") && type_info.is_debuff) {'
)

# Fix is_buff check if exists
content = content.replace(
    'if (type_info.is_buff) {',
    'if (variable_struct_exists(type_info, "is_buff") && type_info.is_buff) {'
)

# Fix else if versions too
content = content.replace(
    'else if (type_info.is_debuff) {',
    'else if (variable_struct_exists(type_info, "is_debuff") && type_info.is_debuff) {'
)

content = content.replace(
    'else if (type_info.is_buff) {',
    'else if (variable_struct_exists(type_info, "is_buff") && type_info.is_buff) {'
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Fixed variable checks in scr_status.gml')
