// Acrylic/Fluent: desfoca o que esta atras do painel (screen texture) e aplica tinta.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float blur_lod = 4.5;
uniform vec4 tint : source_color = vec4(0.07, 0.07, 0.08, 0.78);

void fragment() {
	vec3 c = textureLod(screen_tex, SCREEN_UV, blur_lod).rgb;
	vec3 mixed = mix(c, tint.rgb, 0.65);
	COLOR = vec4(mixed, tint.a);
}
