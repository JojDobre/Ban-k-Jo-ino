shader_type canvas_item;
// Láva: textúra pomaly tečie do strany, hladina sa vlní a jas pulzuje.

uniform float flow_speed = 0.06;
uniform float glow = 0.25;
// Výška vlnenia hladiny (0 = bez vlnenia, pre spodné riadky lávy).
uniform float wave = 3.0;

void vertex() {
	// Vlnenie iba horného okraja.
	VERTEX.y += sin(TIME * 2.2 + VERTEX.x * 0.05) * wave * (1.0 - UV.y);
}

void fragment() {
	vec2 uv = UV;
	uv.x += TIME * flow_speed;
	vec4 color = texture(TEXTURE, uv);
	float pulse = 0.5 + 0.5 * sin(TIME * 2.0 + UV.x * 20.0);
	color.rgb += vec3(0.35, 0.15, 0.0) * glow * pulse;
	COLOR = color;
}
