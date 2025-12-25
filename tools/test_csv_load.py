#!/usr/bin/env python3
"""CSV 로드 테스트"""
import sys
sys.path.insert(0, 'D:/gml_game/under_dog_lord/tools')

from PyQt6.QtWidgets import QApplication
from src.main_window import MainWindow

app = QApplication(sys.argv)
mw = MainWindow()

print('=== 로드된 데이터 ===')
print(f'종족: {len(mw.races)}개')
print(f'직업: {len(mw.classes)}개')
print(f'스킬: {len(mw.skills)}개')
print(f'유닛: {len(mw.units)}개')

print()
print('=== 스킬 목록 ===')
for skill_id, skill in mw.skills.items():
    print(f'  - {skill_id}: {skill.name}')

print()
print('=== 유닛 목록 ===')
for unit_id, unit in mw.units.items():
    print(f'  - {unit_id}: {unit.name}')
