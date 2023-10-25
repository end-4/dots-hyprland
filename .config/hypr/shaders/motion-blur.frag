// vim: set ft=glsl:

precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;
uniform float blurFactor;
uniform vec2 resolution;

const int numSamples = 120000;

uniform sampler2D accumulator;

void main() {
    float blurFactor = 120000.0;

    vec4 currentColor = texture2D(tex, v_texcoord);
    vec4 prevColor = texture2D(accumulator, v_texcoord);

    vec2 velocity = (v_texcoord - gl_FragCoord.xy / resolution) * 2.0;

    vec4 colorDiff = currentColor - prevColor;

    float motionBlur = length(velocity) * blurFactor;

    vec4 finalColor = prevColor + colorDiff * 2.0;

    gl_FragColor = finalColor;
}