#!/usr/bin/env python3
content = """{
  "$GMScript":"v1",
  "%Name":"scr_status",
  "isCompatibility":false,
  "isDnD":false,
  "name":"scr_status",
  "parent":{
    "name":"under_dog_lord",
    "path":"under_dog_lord.yyp",
  },
  "resourceType":"GMScript",
  "resourceVersion":"2.0",
}"""

with open('D:/gml_game/under_dog_lord/scripts/scr_status/scr_status.yy', 'w', encoding='utf-8') as f:
    f.write(content)
print('Fixed scr_status.yy')
