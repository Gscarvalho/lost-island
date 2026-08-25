shader_type spatial;

render_mode blend_mix, depth_draw_opaque, cull_disabled, specular_disabled;

/* PLAYER INTERACTION */

global uniform vec3 player_grass_position;

uniform float player_grass_radius : hint_range(0.1, 5.0, 0.1) = 1.2;

uniform float player_grass_strength : hint_range(0.0, 2.0, 0.05) = 0.12;

/* WIND */

uniform vec3 wind_direction = vec3(1.0, 0.0, 0.0);

uniform float wind_strength :
	hint_range(0.0, 1.0, 0.01) = 0.1;

uniform float wind_speed :
	hint_range(0.0, 10.0, 0.1) = 2.0;

uniform float wind_wave_scale :
	hint_range(0.1, 10.0, 0.1) = 1.5;


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


void vertex() {
	/*
		Calculate this vertex's original world position.
		We use this for both wind and player interaction.
	*/
	vec3 world_position = (
		MODEL_MATRIX
		* vec4(VERTEX, 1.0)
	).xyz;

	/*
		Bottom of blade stays stiff.
		Top bends much more.
	*/
	float height_amount = max(
		VERTEX.y,
		0.0
	);

	height_amount *= height_amount;

	/*
		We'll combine every movement effect in world space
		before applying it to the vertex.
	*/
	vec3 world_offset = vec3(0.0);


	/* WIND */

	vec3 direction = wind_direction;
	direction.y = 0.0;

	if (length(direction) > 0.0001) {
		direction = normalize(direction);

		float wave_position = dot(
			world_position.xz,
			direction.xz
		);

		float wave = sin(
			wave_position * wind_wave_scale
			+ TIME * wind_speed
		);

		float bend = (
			0.65
			+ wave * 0.35
		);

		bend *= (
			wind_strength
			* height_amount
		);

		world_offset += (
			direction
			* bend
		);
	}


/* PLAYER INTERACTION */

/*
	Use the position of the grass instance itself,
	not each individual vertex.

	This makes the entire blade/clump lean together.
*/
vec3 grass_position = MODEL_MATRIX[3].xyz;

vec2 from_player = (
	grass_position.xz
	- player_grass_position.xz
);

float player_distance = length(
	from_player
);

if (
	player_distance < player_grass_radius
	&& player_distance > 0.001
) {
	vec2 push_direction = (
		from_player
		/ player_distance
	);

	/*
		Full influence close to the player,
		then smoothly fade out.
	*/
	float influence = (
		1.0
		- smoothstep(
			player_grass_radius * 0.2,
			player_grass_radius,
			player_distance
		)
	);

	vec3 player_offset = vec3(
		push_direction.x,
		0.0,
		push_direction.y
	);

	player_offset *= (
		player_grass_strength
		* influence
		* height_amount
	);

	world_offset += player_offset;
}

/*
	Convert our combined world-space movement
	back into the local space of this grass instance.
*/
vec3 local_offset = (
	inverse(
		mat3(MODEL_MATRIX)
	)
	* world_offset
);

VERTEX += local_offset;
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