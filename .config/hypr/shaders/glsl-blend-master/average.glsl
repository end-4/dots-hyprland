vec3 blendAverage(vec3 base, vec3 blend) {
	return (base+blend)/2.0;
}

vec3 blendAverage(vec3 base, vec3 blend, float opacity) {
	return (blendAverage(base, blend) * opacity + base * (1.0 - opacity));
}

#pragma glslify: export(blendAverage)