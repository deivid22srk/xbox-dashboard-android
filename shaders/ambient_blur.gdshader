// Fundo ambiente: arte do hero escurecida, ampliada e com blur multi-tap
// (replica o "ambient art" do dashboard Xbox, que sangra a arte atras da UI).
shader_type canvas_item;

uniform sampler2D art : source_color, filter_linear;
uniform float dark = 0.30;
uniform float zoom = 1.16;
uniform vec2 uv_offset = vec2(0.0);
uniform float desat = 0.25;

void fragment() {
	vec2 uv = clamp(UV * zoom + uv_offset - vec2(zoom - 1.0) * 0.5, vec2(0.004), vec2(0.996));
	vec3 c = vec3(0.0);
	c += texture(art, uv).rgb * 0.1963;
	c += texture(art, uv + vec2( 0.0110, 0.0000)).rgb * 0.1749;
	c += texture(art, uv + vec2(-0.0110, 0.0000)).rgb * 0.1749;
	c += texture(art, uv + vec2( 0.0000, 0.0110)).rgb * 0.1749;
	c += texture(art, uv + vec2( 0.0000,-0.0110)).rgb * 0.1749;
	c += texture(art, uv + vec2( 0.0078, 0.0078)).rgb * 0.0525;
	c += texture(art, uv + vec2(-0.0078, 0.0078)).rgb * 0.0525;
	c += texture(art, uv + vec2( 0.0078,-0.0078)).rgb * 0.0525;
	c += texture(art, uv + vec2(-0.0078,-0.0078)).rgb * 0.0525;
	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(c, vec3(lum), desat);
	COLOR = vec4(c * dark, 1.0);
}
