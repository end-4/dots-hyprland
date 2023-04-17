precision mediump float;

uniform sampler2D base;
uniform sampler2D blend;
uniform float opacity;
uniform int mode;

varying vec2 vUv;

#pragma glslify: blendMethod = require(../all)

void main(){

	vec4 baseColor = texture2D(base,vUv);
	vec4 blendColor = texture2D(blend,vUv);

	vec3 color;
	if( opacity == 1.0 ){
		color = blendMethod( mode, baseColor.rgb, blendColor.rgb );
	}else{
		color = blendMethod( mode, baseColor.rgb, blendColor.rgb, opacity );
	}

	gl_FragColor = vec4( color, 1.0 );

}