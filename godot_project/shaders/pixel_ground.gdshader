shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float grid = mod(floor(world_position.x * 0.75) + floor(world_position.z * 0.75), 2.0);
	vec3 village_a = vec3(0.20, 0.34, 0.25);
	vec3 village_b = vec3(0.25, 0.40, 0.28);
	vec3 field_a = vec3(0.24, 0.46, 0.26);
	vec3 field_b = vec3(0.31, 0.55, 0.30);
	float in_slime_field = step(-13.5, world_position.x) * (1.0 - step(0.5, world_position.z));
	vec3 village = mix(village_a, village_b, grid);
	vec3 field = mix(field_a, field_b, grid);
	vec3 base = mix(village, field, in_slime_field);
	float path = 1.0 - step(1.35, abs(world_position.z + 10.0));
	base = mix(base, mix(vec3(0.46, 0.34, 0.22), vec3(0.55, 0.40, 0.24), grid), path * 0.85);
	ALBEDO = base;
	ROUGHNESS = 1.0;
}
