#version 300 es
// Chromatic Aberration Shader for Hyprland - OPTIMIZED
// Fixes: Edge clamping, aspect ratio correction, quadratic falloff

precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// --- CONFIGURATION ---
const float STRENGTH = 0.010;
// Set to your monitor's aspect ratio (16/9, 21/9, etc.) or use 1.0 for uncorrected
const float ASPECT_RATIO = 16.0 / 9.0;
// Use quadratic falloff for more realistic lens distortion
const bool QUADRATIC_FALLOFF = true;

void main() {
    // Aspect-corrected center distance
    vec2 distFromCenter = v_texcoord - 0.5;
    distFromCenter.x *= ASPECT_RATIO;
    
    // Calculate offset magnitude
    float dist = length(distFromCenter);
    float falloff = QUADRATIC_FALLOFF ? dist * dist : dist;
    
    // Normalize direction and apply strength
    vec2 dir = normalize(distFromCenter + 0.0001); // Prevent div by zero
    vec2 offset = dir * falloff * STRENGTH;
    offset.x /= ASPECT_RATIO; // Correct back for sampling
    
    // Sample with clamped coordinates to prevent edge artifacts
    vec2 redCoord = clamp(v_texcoord - offset, 0.0, 1.0);
    vec2 blueCoord = clamp(v_texcoord + offset, 0.0, 1.0);
    
    float r = texture(tex, redCoord).r;
    vec4 centerPixel = texture(tex, v_texcoord);
    float g = centerPixel.g;
    float b = texture(tex, blueCoord).b;

    // Preserve alpha from center sample
    fragColor = vec4(r, g, b, centerPixel.a);
}