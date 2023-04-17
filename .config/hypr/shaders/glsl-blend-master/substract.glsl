float blendSubstract(float base, float blend) {
	return max(base+blend-1.0,0.0);
}

vec3 blendSubstract(vec3 base, vec3 blend) {
	return max(base+blend-vec3(1.0),vec3(0.0));
}

vec3 blendSubstract(vec3 base, vec3 blend, float opacity) {
	return (blendSubstract(base, blend) * opacity + blend * (1.0 - opacity));
}

#pragma glslify: export(blendSubstract)