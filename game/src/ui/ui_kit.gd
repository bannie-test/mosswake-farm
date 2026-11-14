class_name UiKit
extends RefCounted
## Shared look of every screen: parchment panels with a wood border, colours from the master
## palette only (Appendix A). Final 9-slice art replaces the flat boxes in M5.

const PARCHMENT := Color("f0dcae")
const PARCHMENT_DARK := Color("d9a066")
const WOOD := Color("5a3a2a")
const WOOD_DARK := Color("3a2620")
const WOOD_LIGHT := Color("a67348")
const INK := Color("2a1f2b")
const AMBER := Color("ffe9a3")
const GREEN := Color("2f5d3a")
const RED := Color("8f3b32")
const FONT_SIZE := 8
const FONT_BIG := 16


static func box(bg: Color, border: Color, width := 2, pad := 4) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_content_margin_all(pad)
	sb.anti_aliasing = false
	return sb


static func theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = FONT_SIZE
	t.set_color("font_color", "Label", INK)
	t.set_stylebox("panel", "PanelContainer", box(PARCHMENT, WOOD))
	t.set_stylebox("normal", "Button", box(PARCHMENT_DARK, WOOD, 1, 3))
	t.set_stylebox("hover", "Button", box(AMBER, WOOD, 1, 3))
	t.set_stylebox("pressed", "Button", box(WOOD_LIGHT, WOOD_DARK, 1, 3))
	t.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), WOOD_DARK, 1, 3))
	t.set_stylebox("disabled", "Button", box(PARCHMENT, PARCHMENT_DARK, 1, 3))
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(state, "Button", INK)
	t.set_color("font_disabled_color", "Button", WOOD_LIGHT)
	t.set_constant("separation", "VBoxContainer", 3)
	t.set_constant("separation", "HBoxContainer", 4)
	return t


static func label(text: String, color: Color = INK, size: int = FONT_SIZE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", size)
	return l


static func icon(texture: Texture2D, scale := 1) -> TextureRect:
	var r := TextureRect.new()
	r.texture = texture
	r.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED if scale == 1 else TextureRect.STRETCH_SCALE
	r.custom_minimum_size = texture.get_size() * scale
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return r


## A titled window centred on the 640x360 screen. Returns [panel, body VBox].
static func window(title: String, size: Vector2) -> Array:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = size
	panel.position = ((Vector2(640, 360) - size) / 2.0).round()
	var v := VBoxContainer.new()
	panel.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	head.add_child(label(title, WOOD_DARK))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	head.add_child(label("Esc: close", WOOD_LIGHT))
	var rule := ColorRect.new()
	rule.color = WOOD
	rule.custom_minimum_size = Vector2(0, 1)
	v.add_child(rule)
	return [panel, v]


static func clear(node: Node) -> void:
	for child: Node in node.get_children():
		node.remove_child(child)
		child.queue_free()


## Give keyboard focus to a control once the frame has settled, if it is still on screen.
static func focus(control: Control) -> void:
	(func() -> void:
		if is_instance_valid(control) and control.is_inside_tree() and control.is_visible_in_tree():
			control.grab_focus()).call_deferred()
