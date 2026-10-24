// Mặt đất 3D: màu trung tính, độ bão hoà thấp (để đơn vị màu tươi nổi lên),
// ô cờ rất nhạt theo lưới 2 m để người chơi đoán được ô đặt tháp.
shader_type spatial;

uniform vec4 color_a : source_color = vec4(0.42, 0.48, 0.43, 1.0); // #6B7B6E
uniform vec4 color_b : source_color = vec4(0.39, 0.45, 0.40, 1.0);
uniform float cell = 2.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 c = floor(world_pos.xz / cell);
	float checker = mod(c.x + c.y, 2.0);
	ALBEDO = mix(color_a.rgb, color_b.rgb, checker);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
