extends Node
## Events (Autoload): bus tín hiệu cho meta-progression.
##
## Trận đấu chỉ PHÁT sự kiện ở đây (qua MatchTracker); các hệ thống ngoài trận (thống kê,
## thành tựu, nhiệm vụ...) chỉ LẮNG NGHE. Hai bên không biết nhau, nên thêm hệ thống meta
## mới không phải sửa code trận đấu. File này chỉ khai báo signal.

# --- Trong trận -------------------------------------------------------------------
signal enemy_killed(enemy_id: StringName)
signal boss_killed(enemy_id: StringName, seconds_alive: float)
signal enemy_seen(enemy_id: StringName)
## Lần đầu tiên (theo hồ sơ) gặp một loại địch.
signal enemy_discovered(enemy_id: StringName)
signal wave_survived(wave_number: int)
signal tower_built(tower_id: StringName)
signal tower_upgraded(tower_id: StringName)
signal tower_sold(tower_id: StringName)
signal ability_used(ability_id: StringName)
## Kết thúc ván. result: xem MatchTracker.build_result().
signal match_ended(result: Dictionary)

# --- Meta -------------------------------------------------------------------------
signal stat_changed(key: StringName, value: int)
signal currency_changed(currency: StringName, value: int)
signal level_up(new_level: int)
signal achievement_unlocked(id: StringName)
signal item_granted(item_id: StringName, amount: int)
## Có / hết thứ để nhận (thành tựu, nhiệm vụ, quà đăng nhập) -> chấm đỏ trên menu.
signal claimables_changed
