/// @description A* 길찾기 시스템
/// 원본: https://github.com/MatthewStone218/pathfinder
/// 수정: 8방향 이동 지원, 게임 연동 함수 추가

// === 매크로 ===
#macro PF_SHIFT 16              // X좌표 비트 시프트
#macro PF_MASK 65535            // Y좌표 비트 마스크
#macro PF_INF 987654321         // 무한대 (도달 불가)

// === 전역 설정 ===
global.pathfinder = undefined;  // 메인 길찾기 인스턴스
global.pf_grid_cols = 0;        // 그리드 열 수
global.pf_grid_rows = 0;        // 그리드 행 수
global.pf_cell_size = 32;       // 셀 크기 (픽셀)

/// @function AStar(cols, rows, costArr, use_diagonal)
/// @description A* 길찾기 클래스
/// @param {Real} cols 그리드 열 수
/// @param {Real} rows 그리드 행 수
/// @param {Array} costArr 각 셀의 이동 비용 (0 = 이동 불가)
/// @param {Bool} use_diagonal 대각선 이동 허용 여부
function AStar(cols, rows, costArr, use_diagonal = true) constructor {
    // 입력 검증
    if (cols <= 0 || cols > 200) show_error("열 수가 유효하지 않음: " + string(cols), false);
    if (rows <= 0 || rows > 200) show_error("행 수가 유효하지 않음: " + string(rows), false);
    if (!is_array(costArr)) show_error("비용 배열이 배열이 아님", false);
    if (cols * rows != array_length(costArr)) show_error("비용 배열 크기 불일치", false);

    // 변수 초기화
    COLS = cols;
    ROWS = rows;
    USE_DIAGONAL = use_diagonal;

    // 이동 방향 (8방향 지원)
    // 반대 방향이 +4 위치에 오도록 배열 (0<->4, 1<->5, 2<->6, 3<->7)
    if (use_diagonal) {
        // 8방향: 우, 우하, 하, 좌하, 좌, 좌상, 상, 우상
        DIRX = [1, 1, 0, -1, -1, -1, 0, 1];
        DIRY = [0, 1, 1, 1, 0, -1, -1, -1];
        DIRCOST = [1.0, 1.414, 1.0, 1.414, 1.0, 1.414, 1.0, 1.414];
        DIR_COUNT = 8;
    } else {
        // 4방향: 우, 하, 좌, 상 (반대 방향이 +2 위치)
        DIRX = [1, 0, -1, 0];
        DIRY = [0, 1, 0, -1];
        DIRCOST = [1.0, 1.0, 1.0, 1.0];
        DIR_COUNT = 4;
    }

    // 데이터 구조
    OPENQUEUE = ds_priority_create();   // 후보 타일 우선순위 큐
    COSTARR = costArr;                  // 이동 비용 배열
    DISTARR = array_create(rows * cols, PF_INF);   // 거리 배열
    VISITED = array_create(rows * cols, false);     // 방문 여부
    DIRFIELD = array_create(rows * cols, 0);        // 경로 역추적용

    /// @function updateCost(costArr)
    /// @description 비용 배열 업데이트
    static updateCost = function(costArr) {
        if (!is_array(costArr)) show_error("비용 배열이 배열이 아님", false);
        if (ROWS * COLS != array_length(costArr)) show_error("배열 크기 불일치", false);
        COSTARR = costArr;
    }

    /// @function reset()
    /// @description 탐색 상태 초기화
    static reset = function() {
        ds_priority_clear(OPENQUEUE);
        for (var i = 0; i < ROWS * COLS; i++) {
            DISTARR[i] = PF_INF;
            VISITED[i] = false;
            DIRFIELD[i] = 0;
        }
    }

    /// @function destroy()
    /// @description 메모리 해제
    static destroy = function() {
        ds_priority_destroy(OPENQUEUE);
    }

    /// @function heuristic(x1, y1, x2, y2)
    /// @description 휴리스틱 함수 (8방향: 옥타일, 4방향: 맨해튼)
    static heuristic = function(x1, y1, x2, y2) {
        var dx = abs(x2 - x1);
        var dy = abs(y2 - y1);
        if (USE_DIAGONAL) {
            // 옥타일 거리 (대각선 이동 고려)
            return max(dx, dy) + (1.414 - 1) * min(dx, dy);
        } else {
            // 맨해튼 거리
            return dx + dy;
        }
    }

    /// @function pathfind(startx, starty, goalx, goaly)
    /// @description A* 경로 탐색
    /// @returns {Bool} 경로 발견 여부
    static pathfind = function(startx, starty, goalx, goaly) {
        var startp = startx << PF_SHIFT | starty;
        var endp = goalx << PF_SHIFT | goaly;

        // 시작점 = 목표점
        if (startp == endp) return true;

        // 목표점이 이동 불가능한 경우
        if (COSTARR[goaly * COLS + goalx] == 0) return false;

        reset();

        // 시작점 추가
        DISTARR[starty * COLS + startx] = 0;
        ds_priority_add(OPENQUEUE, startp, 0);

        // 메인 루프
        while (!ds_priority_empty(OPENQUEUE)) {
            var curp = ds_priority_delete_min(OPENQUEUE);

            // 목표 도달
            if (curp == endp) {
                return true;
            }

            var curx = curp >> PF_SHIFT;
            var cury = curp & PF_MASK;
            var curIdx = cury * COLS + curx;

            // 이미 방문한 노드
            if (VISITED[curIdx]) continue;
            VISITED[curIdx] = true;

            // 인접 노드 탐색
            for (var n = 0; n < DIR_COUNT; n++) {
                var nextx = curx + DIRX[n];
                var nexty = cury + DIRY[n];

                // 범위 체크
                if (nextx < 0 || nextx >= COLS || nexty < 0 || nexty >= ROWS) continue;

                var nextIdx = nexty * COLS + nextx;

                // 이미 방문했거나 이동 불가
                if (VISITED[nextIdx] || COSTARR[nextIdx] == 0) continue;

                // 대각선 이동 시 모서리 체크 (벽 모서리 통과 방지)
                // 대각선은 홀수 인덱스 (1, 3, 5, 7)
                if (n % 2 == 1) {
                    var check1 = (cury + DIRY[n]) * COLS + curx;
                    var check2 = cury * COLS + (curx + DIRX[n]);
                    if (COSTARR[check1] == 0 || COSTARR[check2] == 0) continue;
                }

                // 비용 계산
                var moveCost = COSTARR[nextIdx] * DIRCOST[n];
                var newDist = DISTARR[curIdx] + moveCost;

                if (newDist < DISTARR[nextIdx]) {
                    DISTARR[nextIdx] = newDist;
                    DIRFIELD[nextIdx] = (n + (DIR_COUNT / 2)) % DIR_COUNT; // 역방향 저장

                    var h = heuristic(nextx, nexty, goalx, goaly);
                    var priority = newDist + h * 1.1; // 약간의 가중치로 탐색 속도 향상
                    ds_priority_add(OPENQUEUE, nextx << PF_SHIFT | nexty, priority);
                }
            }
        }

        return false; // 경로 없음
    }

    /// @function getPath(goalx, goaly)
    /// @description 탐색된 경로를 배열로 반환
    /// @returns {Array} [{x, y}, ...] 형태의 경로 배열
    static getPath = function(goalx, goaly) {
        var path = [];
        var cx = goalx;
        var cy = goaly;

        // 목표점이 범위 밖이면 빈 배열 반환
        if (cx < 0 || cx >= COLS || cy < 0 || cy >= ROWS) {
            return path;
        }

        // 목표점에 도달하지 못했으면 빈 배열 반환
        var goalIdx = cy * COLS + cx;
        if (DISTARR[goalIdx] == PF_INF) {
            return path;
        }

        // 목표점에서 시작점까지 역추적
        var maxIter = COLS * ROWS;
        var iter = 0;

        while (DISTARR[cy * COLS + cx] != 0 && iter < maxIter) {
            iter++;
            array_insert(path, 0, { x: cx, y: cy });

            var idx = cy * COLS + cx;
            var dir = DIRFIELD[idx];

            var nextX = cx + DIRX[dir];
            var nextY = cy + DIRY[dir];

            // 범위 체크
            if (nextX < 0 || nextX >= COLS || nextY < 0 || nextY >= ROWS) {
                break;
            }

            cx = nextX;
            cy = nextY;
        }

        return path;
    }

    /// @function getPathPixel(goalx, goaly, cellSize)
    /// @description 픽셀 좌표로 변환된 경로 반환
    static getPathPixel = function(goalx, goaly, cellSize) {
        var gridPath = getPath(goalx, goaly);
        var pixelPath = [];

        for (var i = 0; i < array_length(gridPath); i++) {
            array_push(pixelPath, {
                x: gridPath[i].x * cellSize + cellSize / 2,
                y: gridPath[i].y * cellSize + cellSize / 2
            });
        }

        return pixelPath;
    }
}

// ============================================
// 게임 연동 헬퍼 함수
// ============================================

/// @function pf_init(cols, rows, cellSize, use_diagonal)
/// @description 길찾기 시스템 초기화
function pf_init(cols, rows, cellSize, use_diagonal = true) {
    global.pf_grid_cols = cols;
    global.pf_grid_rows = rows;
    global.pf_cell_size = cellSize;

    // 기본 비용 배열 생성 (모든 셀 이동 가능)
    var costArr = array_create(cols * rows, 1);

    // 기존 인스턴스 정리
    if (global.pathfinder != undefined) {
        global.pathfinder.destroy();
    }

    global.pathfinder = new AStar(cols, rows, costArr, use_diagonal);

    return global.pathfinder;
}

/// @function pf_set_blocked(gridX, gridY, blocked)
/// @description 특정 셀의 이동 가능 여부 설정
function pf_set_blocked(gridX, gridY, blocked) {
    if (global.pathfinder == undefined) return;

    var idx = gridY * global.pf_grid_cols + gridX;
    global.pathfinder.COSTARR[idx] = blocked ? 0 : 1;
}

/// @function pf_set_cost(gridX, gridY, cost)
/// @description 특정 셀의 이동 비용 설정 (0 = 이동 불가, 높을수록 느림)
function pf_set_cost(gridX, gridY, cost) {
    if (global.pathfinder == undefined) return;

    var idx = gridY * global.pf_grid_cols + gridX;
    global.pathfinder.COSTARR[idx] = cost;
}

/// @function pf_pixel_to_grid(px, py)
/// @description 픽셀 좌표를 그리드 좌표로 변환
function pf_pixel_to_grid(px, py) {
    return {
        x: floor(px / global.pf_cell_size),
        y: floor(py / global.pf_cell_size)
    };
}

/// @function pf_grid_to_pixel(gx, gy)
/// @description 그리드 좌표를 픽셀 좌표(셀 중앙)로 변환
function pf_grid_to_pixel(gx, gy) {
    return {
        x: gx * global.pf_cell_size + global.pf_cell_size / 2,
        y: gy * global.pf_cell_size + global.pf_cell_size / 2
    };
}

/// @function pf_find_path(startX, startY, goalX, goalY, use_pixel)
/// @description 경로 탐색 (픽셀 또는 그리드 좌표)
/// @param {Real} startX 시작 X
/// @param {Real} startY 시작 Y
/// @param {Real} goalX 목표 X
/// @param {Real} goalY 목표 Y
/// @param {Bool} use_pixel true면 픽셀 좌표, false면 그리드 좌표
/// @returns {Array|undefined} 경로 배열 또는 undefined
function pf_find_path(startX, startY, goalX, goalY, use_pixel = true) {
    if (global.pathfinder == undefined) return undefined;

    var sx, sy, gx, gy;

    if (use_pixel) {
        var startGrid = pf_pixel_to_grid(startX, startY);
        var goalGrid = pf_pixel_to_grid(goalX, goalY);
        sx = startGrid.x;
        sy = startGrid.y;
        gx = goalGrid.x;
        gy = goalGrid.y;
    } else {
        sx = floor(startX);
        sy = floor(startY);
        gx = floor(goalX);
        gy = floor(goalY);
    }

    // 범위 체크
    sx = clamp(sx, 0, global.pf_grid_cols - 1);
    sy = clamp(sy, 0, global.pf_grid_rows - 1);
    gx = clamp(gx, 0, global.pf_grid_cols - 1);
    gy = clamp(gy, 0, global.pf_grid_rows - 1);

    // 시작점과 목표점이 같으면 빈 경로
    if (sx == gx && sy == gy) {
        return [];
    }

    // 경로 탐색
    if (global.pathfinder.pathfind(sx, sy, gx, gy)) {
        var path;
        if (use_pixel) {
            path = global.pathfinder.getPathPixel(gx, gy, global.pf_cell_size);
            // 시작점은 실제 유닛 위치 사용 (그리드 셀 중앙이 아닌)
            array_insert(path, 0, { x: startX, y: startY });
        } else {
            path = global.pathfinder.getPath(gx, gy);
            // 시작점 추가 (그리드 좌표)
            array_insert(path, 0, { x: sx, y: sy });
        }

        // 빈 경로면 undefined 반환
        if (array_length(path) == 0) {
            return undefined;
        }
        return path;
    }

    return undefined;
}

/// @function pf_find_path_unit(unit, targetX, targetY)
/// @description 유닛용 경로 탐색
/// @returns {Array|undefined} 픽셀 좌표 경로
function pf_find_path_unit(unit, targetX, targetY) {
    return pf_find_path(unit.x, unit.y, targetX, targetY, true);
}

/// @function pf_draw_debug(alpha)
/// @description 디버그용 그리드 시각화
function pf_draw_debug(alpha = 0.3) {
    if (global.pathfinder == undefined) return;

    var cellSize = global.pf_cell_size;

    draw_set_alpha(alpha);

    for (var gy = 0; gy < global.pf_grid_rows; gy++) {
        for (var gx = 0; gx < global.pf_grid_cols; gx++) {
            var idx = gy * global.pf_grid_cols + gx;
            var cost = global.pathfinder.COSTARR[idx];

            var px = gx * cellSize;
            var py = gy * cellSize;

            if (cost == 0) {
                // 이동 불가
                draw_set_color(c_red);
                draw_rectangle(px, py, px + cellSize - 1, py + cellSize - 1, false);
            } else if (cost > 1) {
                // 높은 비용
                draw_set_color(c_yellow);
                draw_rectangle(px, py, px + cellSize - 1, py + cellSize - 1, false);
            }

            // 그리드 선
            draw_set_color(c_gray);
            draw_rectangle(px, py, px + cellSize - 1, py + cellSize - 1, true);
        }
    }

    draw_set_alpha(1.0);
    draw_set_color(c_white);
}

/// @function pf_draw_path(path, color)
/// @description 경로 시각화 (셀 단위)
function pf_draw_path(path, color = c_lime) {
    if (path == undefined || array_length(path) < 1) return;

    var cellSize = global.pf_cell_size;
    var halfCell = cellSize / 2;

    // 경로 셀 채우기 (밝은 녹색, 불투명)
    var _i = 0;
    repeat (array_length(path)) {
        var pp = path[_i];
        var gx = floor(pp.x / cellSize);
        var gy = floor(pp.y / cellSize);
        var px = gx * cellSize;
        var py = gy * cellSize;

        // 셀 배경 (연두색)
        draw_set_color(c_lime);
        draw_set_alpha(0.7);
        draw_rectangle(px + 1, py + 1, px + cellSize - 2, py + cellSize - 2, false);

        // 셀 테두리 (진한 녹색)
        draw_set_color(c_green);
        draw_set_alpha(1.0);
        draw_rectangle(px + 1, py + 1, px + cellSize - 2, py + cellSize - 2, true);

        _i++;
    }

    draw_set_alpha(1.0);

    // 시작점 (파란 원)
    if (array_length(path) >= 1) {
        var startP = path[0];
        var sx = floor(startP.x / cellSize) * cellSize + halfCell;
        var sy = floor(startP.y / cellSize) * cellSize + halfCell;
        draw_set_color(c_aqua);
        draw_circle(sx, sy, 8, false);
    }

    // 끝점 (노란 원)
    if (array_length(path) >= 2) {
        var endP = path[array_length(path) - 1];
        var ex = floor(endP.x / cellSize) * cellSize + halfCell;
        var ey = floor(endP.y / cellSize) * cellSize + halfCell;
        draw_set_color(c_yellow);
        draw_circle(ex, ey, 8, false);
    }

    draw_set_color(c_white);
}

/// @function pf_cleanup()
/// @description 길찾기 시스템 정리
function pf_cleanup() {
    if (global.pathfinder != undefined) {
        global.pathfinder.destroy();
        global.pathfinder = undefined;
    }
}

/// @function pf_save_walls(filename)
/// @description 벽 데이터를 JSON 파일로 저장
function pf_save_walls(filename) {
    if (global.pathfinder == undefined) return;

    var walls = [];
    var cols = global.pf_grid_cols;
    var rows = global.pf_grid_rows;

    for (var gy = 0; gy < rows; gy++) {
        for (var gx = 0; gx < cols; gx++) {
            var idx = gy * cols + gx;
            if (global.pathfinder.COSTARR[idx] == 0) {
                array_push(walls, { x: gx, y: gy });
            }
        }
    }

    var data = {
        cols: cols,
        rows: rows,
        cell_size: global.pf_cell_size,
        walls: walls
    };

    var json_str = json_stringify(data);
    var file = file_text_open_write(filename);
    file_text_write_string(file, json_str);
    file_text_close(file);
}

/// @function pf_load_walls(filename)
/// @description JSON 파일에서 벽 데이터 불러오기
/// @returns {Bool} 성공 여부
function pf_load_walls(filename) {
    if (global.pathfinder == undefined) return false;
    if (!file_exists(filename)) return false;

    var file = file_text_open_read(filename);
    var json_str = file_text_read_string(file);
    file_text_close(file);

    var data = json_parse(json_str);

    // 모든 벽 초기화
    pf_clear_walls();

    // 저장된 벽 복원
    var walls = data.walls;
    for (var i = 0; i < array_length(walls); i++) {
        var wall = walls[i];
        pf_set_blocked(wall.x, wall.y, true);
    }

    return true;
}

/// @function pf_clear_walls()
/// @description 모든 벽 제거
function pf_clear_walls() {
    if (global.pathfinder == undefined) return;

    var total = global.pf_grid_cols * global.pf_grid_rows;
    for (var i = 0; i < total; i++) {
        global.pathfinder.COSTARR[i] = 1;
    }
}
