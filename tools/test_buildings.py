#!/usr/bin/env python3
"""건물 CSV 로드 테스트"""
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
print(f'건물: {len(mw.buildings)}개')

print()
print('=== 건물 목록 ===')
for building_id, building in mw.buildings.items():
    print(f'  - {building_id}: {building["name"]} (HP:{building["hp"]}, 생산:{building["produces"]})')
