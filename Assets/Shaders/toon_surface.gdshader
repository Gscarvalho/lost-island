shader_type spatial;

render_mode blend_mix, depth_draw_opaque, cull_disabled, specular_disabled;


uniform vec4 base_color : source_color = vec4(1.0);

uniform bool use_albedo_texture = false;
uniform sampler2D albedo_texture : source_color;

uniform vec4 shadow_color : source_color = vec4(
	0.45,
	0.45,
	0.5,
	1.0
);

uniform float shadow_threshold : hint_range(
	-1.0,
	1.0
) = 0.2;

uniform float shadow_softness : hint_range(
	0.0,
	0.2
) = 0.0;


void fragment() {
	vec4 final_color = base_color;

	if (use_albedo_texture) {
		final_color *= texture(
			albedo_texture,
			UV
		);
	}

	ALBEDO = final_color.rgb;
}


void light() {
	float light_amount = dot(
		NORMAL,
		LIGHT
	);

	float toon_light = smoothstep(
		shadow_threshold - shadow_softness,
		shadow_threshold + shadow_softness,
		light_amount
	);

	vec3 lighting = mix(
		shadow_color.rgb,
		vec3(1.0),
		toon_light
	);

	DIFFUSE_LIGHT += (
		lighting
		* LIGHT_COLOR
		* ATTENUATION
	);
}