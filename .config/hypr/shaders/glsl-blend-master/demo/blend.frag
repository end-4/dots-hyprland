precision mediump float;

uniform sampler2D background;
uniform sampler2D foreground;

uniform int blendMode;
uniform float blendOpacity;

varying vec2 screenPosition;

#define BG_REPEAT 1.0
#pragma glslify: blend = require(../all)

void main() {
  vec4 bgColor = texture2D(background, screenPosition * BG_REPEAT);
  vec4 fgColor = texture2D(foreground, screenPosition);

  vec3 color;
  if( blendOpacity == 1.0 ){
  	color = blend( blendMode, bgColor.rgb, fgColor.rgb );
  }else{
	color = blend( blendMode, bgColor.rgb, fgColor.rgb, blendOpacity );
  }
  
  gl_FragColor = vec4(color, 1.0);
}