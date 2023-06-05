// -*- mode:c -*-
precision lowp float;
varying vec2 v_texcoord;
uniform sampler2D tex;

float distanceSquared(vec3 pixColor, vec3 solarizedColor) {
	vec3 distanceVector = pixColor - solarizedColor;
	return dot(distanceVector, distanceVector);
}

void main() {
	vec3 solarized[16];
	solarized[0]  = vec3(0.,0.169,0.212);
	solarized[1]  = vec3(0.027,0.212,0.259);
	solarized[2]  = vec3(0.345,0.431,0.459);
	solarized[3]  = vec3(0.396,0.482,0.514);
	solarized[4]  = vec3(0.514,0.58,0.588);
	solarized[5]  = vec3(0.576,0.631,0.631);
	solarized[6]  = vec3(0.933,0.91,0.835);
	solarized[7]  = vec3(0.992,0.965,0.89);
	solarized[8]  = vec3(0.71,0.537,0.);
	solarized[9]  = vec3(0.796,0.294,0.086);
	solarized[10] = vec3(0.863,0.196,0.184);
	solarized[11] = vec3(0.827,0.212,0.51);
	solarized[12] = vec3(0.424,0.443,0.769);
	solarized[13] = vec3(0.149,0.545,0.824);
	solarized[14] = vec3(0.165,0.631,0.596);
	solarized[15] = vec3(0.522,0.6,0.);

	vec3 pixColor = vec3(texture2D(tex, v_texcoord));
	int closest = 0;
	float closestDistanceSquared = distanceSquared(pixColor, solarized[0]);
	for (int i = 1; i < 15; i++) {
		float newDistanceSquared = distanceSquared(pixColor, solarized[i]);
		if (newDistanceSquared < closestDistanceSquared) {
			closest = i;
			closestDistanceSquared = newDistanceSquared;
		}
	}
	gl_FragColor = vec4(solarized[closest], 1.);
}
