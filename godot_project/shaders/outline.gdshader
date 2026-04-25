shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque;

// Inverted-hull outline pass.
// Apply this material to a *second* MeshInstance3D that copies the
// character mesh (or use surface index 1 with the same mesh duplicated).
// Front-face culling shows only the outward-pushed back faces; flat
// black ALBEDO and unshaded mode give a clean cel-anime contour.

uniform vec4 outline_color : source_color = vec4(0.05, 0.04, 0.10, 1.0);
uniform float outline_thickness : hint_range(0.0, 0.1) = 0.02;

void vertex() {
	VERTEX += NORMAL * outline_thickness;
}

void fragment() {
	ALBEDO = outline_color.rgb;
	ALPHA = outline_color.a;
}
