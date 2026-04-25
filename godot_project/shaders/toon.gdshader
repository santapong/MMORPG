shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_disabled;

// Frieren-style cel shader.
//   - 3-step diffuse ramp (shadow / midtone / lit)
//   - soft Fresnel rim light in a tint color
//   - flat specular off (anime look)
// Pair each character mesh with a second inverted-hull pass using
// outline.gdshader for the dark line silhouette.

uniform vec4 albedo : source_color = vec4(0.85, 0.82, 0.95, 1.0);
uniform sampler2D albedo_texture : source_color, hint_default_white;
uniform bool use_albedo_texture = false;
uniform vec3 shadow_color : source_color = vec3(0.55, 0.50, 0.65);
uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.45;
uniform float midtone_threshold : hint_range(0.0, 1.0) = 0.85;
uniform float band_softness : hint_range(0.0, 0.2) = 0.04;

uniform vec3 rim_color : source_color = vec3(0.93, 0.83, 0.62);
uniform float rim_strength : hint_range(0.0, 2.0) = 0.55;
uniform float rim_power : hint_range(0.5, 8.0) = 2.5;

void fragment() {
	vec4 base = albedo;
	if (use_albedo_texture) {
		base *= texture(albedo_texture, UV);
	}
	ALBEDO = base.rgb;
	ALPHA = base.a;
	ROUGHNESS = 0.95;
	METALLIC = 0.0;
	SPECULAR = 0.0;
}

void light() {
	float ndotl = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);

	// Three-step ramp with soft band edges.
	float lit = smoothstep(midtone_threshold - band_softness, midtone_threshold + band_softness, ndotl);
	float mid = smoothstep(shadow_threshold - band_softness, shadow_threshold + band_softness, ndotl);
	float band = mix(0.5, 1.0, lit);
	band = mix(0.0, band, mid);

	vec3 lit_color = ALBEDO * LIGHT_COLOR.rgb;
	vec3 shadow_tint = ALBEDO * shadow_color;

	// Rim Fresnel toward the camera, modulated by the same light direction
	// so it only shows on the lit side of the silhouette.
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	vec3 rim = rim_color * fres * rim_strength * smoothstep(0.0, 0.4, ndotl);

	DIFFUSE_LIGHT += mix(shadow_tint, lit_color, band) * ATTENUATION + rim;
}
