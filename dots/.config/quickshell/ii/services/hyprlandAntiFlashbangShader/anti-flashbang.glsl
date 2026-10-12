#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

float overlayOpacityForBrightness(float x) {
    // Note: range 0 to 1
    
    // Will a fancy curve help?... I'll have to experiment more at night
    // float y = pow(x, 2.0) * 0.75;
    // float y = (1.0 - exp(-x))*1.15;
    // float y = (1.0 - exp(-pow((x-0.15), 0.6)))*1.18;

    float y = x*0.75;
    return min(max(y, 0.001), 1.0);
}

void main() {
    // 1. Get the current pixel color
    vec4 pixColor = texture(tex, v_texcoord);

    // 2. Calculate average screen brightness
    vec3 totalRGB = vec3(0.0);
    float samples = 0.0;
    
    // We use a nested loop to create a 10x10 grid (100 samples)
    // This is dense enough to catch small icons/text but light enough to run fast.
    for(float x = 0.05; x < 1.0; x += 0.1) {
        for(float y = 0.05; y < 1.0; y += 0.1) {
            totalRGB += texture(tex, vec2(x, y)).rgb;
            samples++;
        }
    }
    
    vec3 avgColor = totalRGB / samples;
    float globalBrightness = dot(avgColor, vec3(0.2126, 0.7152, 0.0722));

    // 3. Get the specific opacity for this brightness level
    float opacity = overlayOpacityForBrightness(globalBrightness);

    // 4. Apply the "black overlay" effect
    vec3 outColor = mix(pixColor.rgb, vec3(0.0), opacity);

    fragColor = vec4(outColor, pixColor.a);
}
