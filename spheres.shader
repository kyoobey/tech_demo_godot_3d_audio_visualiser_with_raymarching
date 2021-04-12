











/* shader config */

shader_type spatial;
render_mode cull_front;
render_mode unshaded;




uniform int MAX_STEPS : hint_range(1, 1023) = 255;
uniform float MAX_SHADING_DISTANCE : hint_range(1, 10000) = 100.0;
const float MIN_HIT_DISTANCE = 0.001;







/* math */
const float PI = 3.141592653589793238;



/* scene code */


uniform float angle_factor;
uniform float radius = 1.0;
uniform float smoothness = 0.5;


uniform float hist_1;
uniform float hist_2;
uniform float hist_3;
uniform float hist_4;
uniform float hist_5;
uniform float hist_6;


float operation_smooth_union(float d1, float d2, float k) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}

vec4 operation_smooth_union_color(vec4 d1, vec4 d2, float k) {
	float interpolation = clamp(0.5 + 0.5 * (d2.a - d1.a) / k, 0.0, 1.0);
    return mix(d1, d2, interpolation);
}

float sdf_sphere(vec3 p, float r) {
	return length(p) - r;
}

float SDF(vec3 p) {
	float hist[] = {
		hist_1, hist_2, hist_3, hist_4, hist_5, hist_6
	};

	vec3 c = vec3(0.,0.,1.)*radius;
	float m = sdf_sphere(p - c, hist[0]);

	for (int i=1; i<6; i++) {
		float angle = float(i)*(PI*angle_factor);
		c = vec3(sin(angle),0.,cos(angle))*radius;
		m = operation_smooth_union(m, sdf_sphere(p - c, hist[i]), smoothness);
	}

	return m;
}

vec4 SDF_color(vec3 p) {
	float hist[] = {
		hist_1, hist_2, hist_3, hist_4, hist_5, hist_6
	};

	vec3 colors[] = {
		vec3(1.,0.,0.),
		vec3(0.,1.,0.),
		vec3(0.,0.,1.),
		vec3(1.,1.,0.),
		vec3(0.,1.,1.),
		vec3(1.,0.,1.)
	};

	vec3 c = vec3(0.,0.,1.)*radius;
	vec4 m = vec4(colors[0], sdf_sphere(p - c, hist[0]));

	for (int i=1; i<6; i++) {
		float angle = float(i)*(PI*angle_factor);
		c = vec3(sin(angle),0.,cos(angle))*radius;
		m = operation_smooth_union_color(m, vec4(colors[i], sdf_sphere(p - c, hist[i])), smoothness);
		// m = operation_smooth_union_color(m, sdf_sphere(p - c, hist[i]), smoothness);
	}

	return m;
}


void shade(
	in vec3 p,
	in int steps, in float depth, in float minimum_distance, in bool hit,
	out vec3 albedo, out float alpha,
) {
	alpha = 0.3;
	albedo = vec3(0.);

	if (depth < MAX_SHADING_DISTANCE) {
		albedo = SDF_color(p).rgb;
		alpha = 1.0;
	}
}


















/* ray marching code */

varying highp vec3 camera_position;
varying highp vec3 camera_direction;

void vertex() {
	// pass data to fragment shader
	camera_position = (inverse(WORLD_MATRIX) * CAMERA_MATRIX * vec4(0.0,0.0,0.0, 1.0)).xyz;
	camera_direction = normalize(VERTEX - camera_position);
}

void march(
	in vec3 point, in vec3 direction,
	in int max_steps, in float max_shading_distance, in float min_hit_distance,
	out int steps, out float depth, out float minimum_distance, out bool hit,
) {
	minimum_distance = max_shading_distance;

	for (steps=0; depth < max_shading_distance && steps < max_steps; steps++) {
		vec3 current_position = point + direction * depth;
		float current_distance = SDF(current_position); // to be

		if (abs(current_distance) < min_hit_distance) {
			hit = true;
			break;
		}

		minimum_distance = min(minimum_distance, current_distance);
		depth += current_distance;
	}
}

void fragment() {
	int steps;
	float depth, minimum_distance;
	bool hit;

	march(
		camera_position, camera_direction,
		MAX_STEPS, MAX_SHADING_DISTANCE, MIN_HIT_DISTANCE,
		steps, depth, minimum_distance, hit
	);

	shade(
		camera_position + camera_direction * depth,
		steps, depth, minimum_distance, hit,
		ALBEDO, ALPHA
	);
}













// eof