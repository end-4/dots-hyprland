#version 300 es
// Retro Terminal Shader for Hyprland - Amber/Green phosphor monitor effect

precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// --- CONFIGURATION ---
// Choose your phosphor color:
// 1 = Amber (classic IBM/DOS terminals)
// 2 = Green (classic VT terminals)
// 3 = White (early monochrome displays)
const int PHOSPHOR_TYPE = 1;

const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);
const float BRIGHTNESS = 1.2;
const float CONTRAST = 1.3;
const float SCANLINE_INTENSITY = 0.08;  // CRT scanline effect
const float PHOSPHOR_GLOW = 0.12;       // Screen glow
const float VIGNETTE_STRENGTH = 0.3;    // Edge darkening
const float CURVATURE = 0.05;           // Subtle screen curve

// Phosphor color definitions
const vec3 AMBER_DARK = vec3(0.15, 0.08, 0.0);
const vec3 AMBER_BRIGHT = vec3(1.0, 0.7, 0.1);

const vec3 GREEN_DARK = vec3(0.0, 0.15, 0.05);
const vec3 GREEN_BRIGHT = vec3(0.2, 1.0, 0.3);

const vec3 WHITE_DARK = vec3(0.1, 0.1, 0.1);
const vec3 WHITE_BRIGHT = vec3(1.0, 1.0, 0.95);

void main() {
    vec2 uv = v_texcoord;
    
    // Subtle screen curvature
    vec2 centered = uv * 2.0 - 1.0;
    centered *= 1.0 + CURVATURE * dot(centered, centered);
    uv = centered * 0.5 + 0.5;
    
    vec4 color = texture(tex, uv);
    
    // Convert to grayscale
    float gray = dot(color.rgb, LUMA);
    
    // Apply contrast and brightness
    gray = (gray - 0.5) * CONTRAST + 0.5;
    gray *= BRIGHTNESS;
    
    // Select phosphor color
    vec3 darkColor, brightColor;
    if (PHOSPHOR_TYPE == 1) {
        darkColor = AMBER_DARK;
        brightColor = AMBER_BRIGHT;
    } else if (PHOSPHOR_TYPE == 2) {
        darkColor = GREEN_DARK;
        brightColor = GREEN_BRIGHT;
    } else {
        darkColor = WHITE_DARK;
        brightColor = WHITE_BRIGHT;
    }
    
    // Map to phosphor color
    vec3 phosphorColor = mix(darkColor, brightColor, gray);
    
    // Add phosphor glow to bright areas
    if (gray > 0.7) {
        phosphorColor += brightColor * PHOSPHOR_GLOW * (gray - 0.7);
    }
    
    // CRT scanlines
    float scanline = sin(v_texcoord.y * 1080.0 * 0.5) * SCANLINE_INTENSITY;
    phosphorColor -= scanline;
    
    // Vignette effect (darken edges)
    vec2 vignetteUV = v_texcoord * (1.0 - v_texcoord);
    float vignette = vignetteUV.x * vignetteUV.y * 15.0;
    vignette = pow(vignette, VIGNETTE_STRENGTH);
    phosphorColor *= vignette;
    
    phosphorColor = clamp(phosphorColor, 0.0, 1.0);
    
    fragColor = vec4(phosphorColor, color.a);
}