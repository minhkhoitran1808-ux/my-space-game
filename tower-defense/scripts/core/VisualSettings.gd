class_name VisualSettings
extends RefCounted
## Cài đặt hiển thị / hỗ trợ người chơi (accessibility), lưu ở biến static để các hiệu ứng
## chạy mỗi frame đọc thẳng mà không phải tra file cài đặt.
##
## SaveManager gọi apply() khi khởi động và mỗi khi người chơi đổi cài đặt; hệ thống nào
## cần phản ứng ngay (vd thanh máu đang hiện) thì nghe thêm SaveManager.settings_changed.

enum HitFlash {
	ON, ## Nháy trắng đầy đủ.
	REDUCED, ## Nháy nhạt (tối đa 35%).
	OFF, ## Không nháy.
}

enum HealthBarMode {
	DAMAGED_ONLY, ## Chỉ hiện khi địch đã mất máu (mặc định).
	ALWAYS, ## Luôn hiện.
	OFF, ## Không hiện (trừ Boss).
}

## Tên hiển thị trong menu Cài đặt (đúng thứ tự enum).
const HIT_FLASH_NAMES := ["Đầy đủ", "Nhẹ", "Tắt"]
const HEALTH_BAR_NAMES := ["Khi bị thương", "Luôn hiện", "Tắt"]

## Tắt các chuyển động trang trí: giật, rung, vòng xoay / nhịp, sóng lan, vệt máu rút dần.
static var reduced_motion := false
static var hit_flash: HitFlash = HitFlash.ON
static var health_bar_mode: HealthBarMode = HealthBarMode.DAMAGED_ONLY
## Bảng màu thân thiện với người mù màu đỏ - lục.
static var colorblind := false


## Cập nhật một cài đặt (bỏ qua các key không thuộc nhóm hiển thị).
static func apply(key: String, value: Variant) -> void:
	match key:
		"reduced_motion":
			reduced_motion = bool(value)
		"hit_flash":
			hit_flash = clampi(int(value), 0, HitFlash.size() - 1) as HitFlash
		"health_bar_mode":
			health_bar_mode = clampi(int(value), 0, HealthBarMode.size() - 1) as HealthBarMode
		"colorblind":
			colorblind = bool(value)


## Cường độ tối đa của nháy trắng theo cài đặt (0..1).
static func hit_flash_strength() -> float:
	match hit_flash:
		HitFlash.REDUCED:
			return 0.35
		HitFlash.OFF:
			return 0.0
		_:
			return 1.0
