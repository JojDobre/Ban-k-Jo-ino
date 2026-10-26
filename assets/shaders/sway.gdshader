shader_type canvas_item;
// Vietor: vrch kresby (tráva, kry, hríby) sa jemne kolíše, spodok ostáva na zemi.
// Fáza závisí od polohy v svete, takže rastliny sa nehýbu rovnako.

uniform float strength = 4.0;
uniform float speed = 1.6;

void vertex() {
	float world_x = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).x;
	float top = 1.0 - UV.y;
	VERTEX.x += sin(TIME * speed + world_x * 0.013) * strength * top * top;
}
