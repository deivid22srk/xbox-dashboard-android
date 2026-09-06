// Cantos arredondados para TextureRect (mascara rounded-box em pixels do no).
shader_type canvas_item;

uniform float radius_px = 10.0;
uniform vec2 node_size = vec2(100.0, 100.0);

float rounded_box(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + vec2(r);
	return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 p = (UV - 0.5) * node_size;
	float d = rounded_box(p, node_size * 0.5, radius_px);
	float mask = 1.0 - smoothstep(-1.0, 1.0, d);
	COLOR = vec4(tex.rgb, tex.a * mask);
}
