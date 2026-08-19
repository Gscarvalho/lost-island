shader_type spatial;

render_mode blend_mix, depth_draw_opaque, cull_disabled, specular_disabled;


/* BASE SURFACE */

uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform bool use_albedo_texture = false;

uniform sampler2D albedo_texture :
	source_color,
	filter_linear_mipmap,
	repeat_enable;


/* TOON LIGHTING */

uniform bool use_color_gradient = true;

uniform sampler2D color_gradient :
	source_color,
	hint_default_white,
	filter_linear,
	repeat_disable;

uniform vec4 shadow_color : source_color = vec4(
	0.45,
	0.45,
	0.5,
	1.0
);

uniform float shadow_threshold : hint_range(-1.0, 1.0) = 0.2;

uniform float shadow_softness : hint_range(0.0, 0.2) = 0.02;


/* FRESNEL */

uniform bool use_fresnel = true;

uniform sampler2D fresnel_gradient :
	source_color,
	hint_default_black,
	filter_linear,
	repeat_disable;

uniform float fresnel_power : hint_range(0.1, 10.0) = 4.0;

uniform float fresnel_strength : hint_range(0.0, 2.0) = 0.25;


/* FUNCTIONS */

float fresnel(
	float power,
	vec3 normal,
	vec3 view
) {
	float facing = clamp(
		dot(
			normalize(normal),
			normalize(view)
		),
		0.0,
		1.0
	);

	return pow(
		1.0 - facing,
		power
	);
}


/* SURFACE COLOR */

void fragment() {
	vec4 final_color = base_color;

	if (use_albedo_texture) {
		final_color *= texture(
			albedo_texture,
			UV
		);
	}

	if (use_fresnel) {
		float fresnel_amount = fresnel(
			fresnel_power,
			NORMAL,
			VIEW
		);

		vec3 fresnel_color = texture(
			fresnel_gradient,
			vec2(
				fresnel_amount,
				0.0
			)
		).rgb;

		final_color.rgb += (
			fresnel_color
			* fresnel_amount
			* fresnel_strength
		);
	}

	ALBEDO = final_color.rgb;
}


/* TOON LIGHTING */

void light() {
	float light_amount = clamp(
		dot(
			NORMAL,
			LIGHT
		),
		-1.0,
		1.0
	);

	vec3 lighting;

	if (use_color_gradient) {
		float gradient_position = clamp(
			(
				light_amount + 1.0
			)
			* 0.5
			* ATTENUATION,
			0.0,
			1.0
		);

		lighting = texture(
			color_gradient,
			vec2(
				gradient_position,
				0.0
			)
		).rgb;
	}
	else {
		float toon_amount = smoothstep(
			shadow_threshold - shadow_softness,
			shadow_threshold + shadow_softness,
			light_amount
		);

		lighting = mix(
			shadow_color.rgb,
			vec3(1.0),
			toon_amount
		);
	}

	DIFFUSE_LIGHT += (
		lighting
		* LIGHT_COLOR
		* ATTENUATION
	);
}