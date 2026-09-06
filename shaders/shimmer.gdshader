// Skeleton loading com brilho deslizante (shimmer).
shader_type canvas_item;

uniform vec4 base : source_color = vec4(0.125, 0.125, 0.13, 1.0);
uniform vec4 shine : source_color = vec4(0.21, 0.21, 0.22, 1.0);
uniform float speed = 0.9;

void fragment() {
	float band = fract(UV.x * 0.65 + UV.y * 0.35 + TIME * speed);
	float g = smoothstep(0.0, 0.5, band) * smoothstep(1.0, 0.5, band);
	COLOR = mix(base, shine, g * 0.55);
}
