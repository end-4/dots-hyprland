#version 300 es
// AMOLED Black + Monochrome Shader for Hyprland

precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// --- CONFIGURATION ---
const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);

// Black threshold: pixels below this become pure black
const float BLACK_THRESHOLD = 0.02;

const float CONTRAST = 1.2;

const float BRIGHTNESS = 0.0;

const float MIN_LUMINANCE = 0.08;

const float DESATURATION = 1.0;

void main() {
    vec4 color = texture(tex, v_texcoord);
    
    float gray = dot(color.rgb, LUMA);
    
    vec3 desaturated = mix(color.rgb, vec3(gray), DESATURATION);
    
    if (gray < BLACK_THRESHOLD) {
        desaturated = vec3(0.0);
    } else {
        desaturated = (desaturated - BLACK_THRESHOLD) / (1.0 - BLACK_THRESHOLD);
    }
    
    desaturated = max(desaturated, vec3(MIN_LUMINANCE));
    
    desaturated = (desaturated - 0.5) * CONTRAST + 0.5;
    
    desaturated += BRIGHTNESS;
    
    desaturated = clamp(desaturated, 0.0, 1.0);
    
    fragColor = vec4(desaturated, color.a);
}