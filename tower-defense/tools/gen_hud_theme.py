"""Sinh resources/ui/hud_theme.tres từ bảng token màu (chạy: python3 tools/gen_hud_theme.py).

Theme có thể chỉnh trực tiếp trong Godot; script này chỉ để sinh lại toàn bộ nhất quán
(5 trạng thái nút × các biến thể dùng chung một công thức) khi đổi bảng màu.
"""

TOKENS = {
    "base": "#0B101D", "surface": "#182238", "gold": "#FFC72C", "danger": "#E63946",
    "wave": "#4EA8DE", "success": "#38B000", "disabled": "#5C677D", "focus": "#00F5D4",
    "text": "#E8ECF4", "muted": "#8D99AE", "retry": "#F77F00",
}


def hexc(h, a=1.0):
    h = TOKENS.get(h, h).lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    return f"Color({r:.3f}, {g:.3f}, {b:.3f}, {a})"


subs = []


def sb(sid, **p):
    subs.append("\n".join([f'[sub_resource type="StyleBoxFlat" id="{sid}"]'] + [f"{k} = {v}" for k, v in p.items()]))
    return f'SubResource("{sid}")'


def corner(r):
    return {f"corner_radius_{c}": r for c in ("top_left", "top_right", "bottom_right", "bottom_left")}


def border(top=0, bottom=0, side=0):
    return {"border_width_left": side, "border_width_right": side, "border_width_top": top, "border_width_bottom": bottom}


def button_set(prefix, normal, hover, pressed, edge, pressed_border=None):
    """Nút nổi khối: gờ đáy 4px; pressed lún xuống 3px (chữ dịch xuống, gờ phẳng lại)."""
    base = dict(content_margin_left=16.0, content_margin_right=16.0, **corner(8))
    up = dict(content_margin_top=6.0, content_margin_bottom=9.0, **border(top=0, bottom=4))
    pb = pressed_border or edge
    return {
        "normal": sb(f"{prefix}_normal", bg_color=normal, border_color=edge, **up, **base),
        "hover": sb(f"{prefix}_hover", bg_color=hover, border_color=edge, **up, **base),
        "pressed": sb(f"{prefix}_pressed", bg_color=pressed, border_color=pb, content_margin_top=9.0,
                      content_margin_bottom=6.0, **border(top=2, bottom=2, side=2 if pressed_border else 0), **base),
        "disabled": sb(f"{prefix}_disabled", bg_color=hexc("disabled", 0.5), border_color=hexc("base", 0.4),
                       **up, **base),
    }


EDGE = hexc("#070B14")
variants = {
    # tên biến thể: (style, màu chữ thường, font đậm?)
    "Button": (button_set("btn", hexc("#22304D"), hexc("#2D3F63"), hexc("#18233A"), EDGE, hexc("wave")), hexc("text"), False),
    "PrimaryButton": (button_set("primary", hexc("success"), hexc("#4CC915"), hexc("#2E9400"), hexc("#1C5C00")), "Color(1, 1, 1, 1)", True),
    "RetryButton": (button_set("retry", hexc("retry"), hexc("#FF9426"), hexc("#D96F00"), hexc("#7A3E00")), "Color(1, 1, 1, 1)", True),
    "GoldButton": (button_set("gold", hexc("gold"), hexc("#FFD45C"), hexc("#E6B020"), hexc("#7A5A00")), hexc("base"), True),
}
focus = sb("focus", draw_center="false", border_color=hexc("focus"), expand_margin_left=2.0, expand_margin_right=2.0,
           expand_margin_top=2.0, expand_margin_bottom=2.0, **border(2, 2, 2), **corner(10))

props = ['default_font = ExtResource("1_semibold")', "default_font_size = 16"]
for name, (styles, font_color, bold) in variants.items():
    if name != "Button":
        props.append(f'{name}/base_type = &"Button"')
    props += [
        f"{name}/colors/font_color = {font_color}",
        f"{name}/colors/font_hover_color = {font_color if name == 'GoldButton' else 'Color(1, 1, 1, 1)'}",
        f"{name}/colors/font_pressed_color = {font_color if name != 'Button' else hexc('#BFE3FA')}",
        f"{name}/colors/font_hover_pressed_color = {font_color if name != 'Button' else hexc('#D6EEFC')}",
        f"{name}/colors/font_focus_color = {font_color}",
        f"{name}/colors/font_disabled_color = Color(1, 1, 1, 0.45)",
    ]
    if bold:
        props.append(f'{name}/fonts/font = ExtResource("2_extrabold")')
    for state in ("normal", "hover", "pressed", "disabled"):
        props.append(f"{name}/styles/{state} = {styles[state]}")
    props.append(f"{name}/styles/hover_pressed = {styles['pressed']}")
props.append(f"Button/styles/focus = {focus}")

# Nút ở thanh dưới (chọn tháp / kỹ năng): cùng phong cách nút mặc định nhưng gọn hơn
# (lề 10px, chữ 14px) để 6 nút + dòng gợi ý vừa một hàng 1280px.
dock = button_set("dock", hexc("#22304D"), hexc("#2D3F63"), hexc("#18233A"), EDGE, hexc("wave"))
for sid in ("normal", "hover", "pressed", "disabled"):
    i = next(k for k, sub in enumerate(subs) if f'id="dock_{sid}"' in sub)
    subs[i] = subs[i].replace("content_margin_left = 16.0", "content_margin_left = 10.0") \
            .replace("content_margin_right = 16.0", "content_margin_right = 12.0")
props += ['DockButton/base_type = &"Button"', "DockButton/font_sizes/font_size = 14"]
for state in ("normal", "hover", "pressed", "disabled"):
    props.append(f"DockButton/styles/{state} = {dock[state]}")
props.append(f"DockButton/styles/hover_pressed = {dock['pressed']}")

panel = sb("panel", bg_color=hexc("surface", 0.97), border_color=hexc("#FFFFFF", 0.08), content_margin_left=6.0,
           content_margin_right=6.0, content_margin_top=6.0, content_margin_bottom=6.0,
           shadow_color=hexc("#000000", 0.35), shadow_size=8, **border(1, 1, 1), **corner(12))
bar = sb("hud_bar", bg_color=hexc("base", 0.94), border_color=hexc("#FFFFFF", 0.06), **border(top=1, bottom=1))
chip = sb("stat_chip", bg_color=hexc("surface"), border_color=hexc("#FFFFFF", 0.07), content_margin_left=10.0,
          content_margin_right=14.0, content_margin_top=3.0, content_margin_bottom=3.0, **border(1, 1, 1), **corner(10))
modal = sb("modal", bg_color=hexc("surface"), border_color=hexc("#FFFFFF", 0.12), shadow_color=hexc("#000000", 0.55),
           shadow_size=24, **border(2, 2, 2), **corner(16))
tooltip = sb("tooltip", bg_color=hexc("base", 0.97), border_color=hexc("wave", 0.5), content_margin_left=10.0,
             content_margin_right=10.0, content_margin_top=6.0, content_margin_bottom=6.0, **border(1, 1, 1), **corner(6))
bar_bg = sb("lives_bar_bg", bg_color=hexc("#070B14"), **corner(3))
bar_fill = sb("lives_bar_fill", bg_color=hexc("danger"), **corner(3))

props += [
    f"PanelContainer/styles/panel = {panel}",
    'HudBar/base_type = &"PanelContainer"', f"HudBar/styles/panel = {bar}",
    'StatChip/base_type = &"PanelContainer"', f"StatChip/styles/panel = {chip}",
    'ModalPanel/base_type = &"PanelContainer"', f"ModalPanel/styles/panel = {modal}",
    f"TooltipPanel/styles/panel = {tooltip}", f"TooltipLabel/colors/font_color = {hexc('text')}",
    f"Label/colors/font_color = {hexc('text')}",
    'StatValue/base_type = &"Label"', 'StatValue/fonts/font = ExtResource("2_extrabold")', "StatValue/font_sizes/font_size = 22",
    'StatCaption/base_type = &"Label"', f"StatCaption/colors/font_color = {hexc('muted')}", "StatCaption/font_sizes/font_size = 11",
    'MutedLabel/base_type = &"Label"', f"MutedLabel/colors/font_color = {hexc('muted')}", "MutedLabel/font_sizes/font_size = 13",
    'HudTitle/base_type = &"Label"', 'HudTitle/fonts/font = ExtResource("2_extrabold")', "HudTitle/font_sizes/font_size = 44",
    'LivesBar/base_type = &"ProgressBar"', f"LivesBar/styles/background = {bar_bg}", f"LivesBar/styles/fill = {bar_fill}",
]

head = (f'[gd_resource type="Theme" load_steps={len(subs) + 3} format=3]\n\n'
        '[ext_resource type="FontFile" path="res://assets/fonts/BeVietnamPro-SemiBold.ttf" id="1_semibold"]\n'
        '[ext_resource type="FontFile" path="res://assets/fonts/BeVietnamPro-ExtraBold.ttf" id="2_extrabold"]\n\n')
with open("resources/ui/hud_theme.tres", "w", encoding="utf-8") as f:
    f.write(head + "\n\n".join(subs) + "\n\n[resource]\n" + "\n".join(props) + "\n")
print(f"{len(subs)} StyleBox, {len(props)} thuộc tính theme")
