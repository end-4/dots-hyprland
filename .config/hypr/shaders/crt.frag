#version 100
precision highp float;
varying highp vec2 v_texcoord;
varying highp vec3 v_pos;
uniform highp sampler2D tex;
uniform lowp float time;

#define BORDER_COLOR vec4(vec3(0.0, 0.0, 0.0), 1.0) // black border
#define BORDER_RADIUS 1.0 // larger vignette radius
#define BORDER_SIZE 0.01 // small border size
#define CHROMATIC_ABERRATION_STRENGTH 0.00
#define DENOISE_INTENSITY 0.0001 //
#define DISTORTION_AMOUNT 0.00 // moderate distortion amount
#define HDR_BLOOM 0.75 // bloom intensity
#define HDR_BRIGHTNESS 0.011 // brightness
#define HDR_CONTRAST 0.011 // contrast
#define HDR_SATURATION 1.0// saturation
#define LENS_DISTORTION_AMOUNT 0.0
#define NOISE_THRESHOLD 0.0001
#define PHOSPHOR_BLUR_AMOUNT 0.77 // Amount of blur for phosphor glow
#define PHOSPHOR_GLOW_AMOUNT 0.77 // Amount of phosphor glow
#define SAMPLING_RADIUS 0.0001
#define SCANLINE_FREQUENCY 540.0
#define SCANLINE_THICKNESS 0.0507
#define SCANLINE_TIME time * 471.24
#define SHARPNESS 0.25
#define SUPERSAMPLING_SAMPLES 16.0
#define VIGNETTE_RADIUS 0.0 // larger vignette radius
#define PI 3.14159265359
#define TWOPI 6.28318530718

vec2 applyBarrelDistortion(vec2 coord, float amt) {
    vec2 p = coord.xy / vec2(1.0);
    vec2 v = p * 2.0 - vec2(1.0);
    float r = dot(v, v);
    float k = 1.0 + pow(r, 2.0) * pow(amt, 2.0);
    vec2 result = v * k;
    return vec2(0.5, 0.5) + 0.5 * result.xy;
}

vec4 applyColorCorrection(vec4 color) {
    color.rgb *= vec3(1.0, 0.79, 0.89);
    return vec4(color.rgb, 1.0);
}

vec4 applyBorder(vec2 tc, vec4 color, float borderSize, vec4 borderColor) {
    float dist_x = min(tc.x, 1.0 - tc.x);
    float dist_y = min(tc.y, 1.0 - tc.y);
    float dist = min(dist_x, dist_y) * -1.0;
    float border = smoothstep(borderSize, 0.0, dist);
    border += smoothstep(borderSize, 0.0, dist);
    return mix(color, borderColor, border);
}

vec4 applyFakeHDR(vec4 color, float brightness, float contrast, float saturation, float bloom) {
    color.rgb = (color.rgb - vec3(0.5)) * exp2(brightness) + vec3(0.5);
    vec3 crtfactor = vec3(1.05, 0.92, 1.0);
    color.rgb = pow(color.rgb, crtfactor);
    // // NTSC
    // vec3 lumCoeff = vec3(0.2125, 0.7154, 0.0721);

    // // BT.709
    // vec3 lumCoeff = vec3(0.299, 0.587, 0.114);

    // BT.2020
    vec3 lumCoeff = vec3(0.2627, 0.6780, 0.0593);

    // // Warm NTSC
    // vec3 lumCoeff = vec3(0.2125, 0.7010, 0.0865);

    float luminance = dot(color.rgb, lumCoeff);
    luminance = pow(luminance, 2.2);
    color.rgb = mix(vec3(luminance), color.rgb, saturation);
    color.rgb = mix(color.rgb, vec3(1.0), pow(max(0.0, luminance - 1.0 + bloom), 4.0));
    return color;
}

vec4 applyVignette(vec4 color) {
    vec2 center = vec2(0.5, 0.5); // center of screen
    float radius = VIGNETTE_RADIUS; // radius of vignette effect
    float softness = 1.0; // softness of vignette effect
    float intensity = 0.7; // intensity of vignette effect
    vec2 offset = v_texcoord - center; // offset from center of screen
    float distance = length(offset); // distance from center of screen
    float alpha = smoothstep(radius, radius - radius * softness, distance) * intensity; // calculate alpha value for vignette effect
    return mix(vec4(0.0, 0.0, 0.0, alpha), color, alpha); // mix black with color using calculated alpha value
}

vec4 applyPhosphorGlow(vec2 tc, vec4 color, sampler2D tex) {
    // Calculate average color value of the texture
    vec4 texelColor = color;
    float averageColor = (texelColor.r + texelColor.g + texelColor.b) / 3.0;

    // Determine brightness-dependent color factor
    float factor = mix(
        mix(0.09,
            mix(0.005, 0.0075, (averageColor - 0.1) / 0.1),
            step(0.01, averageColor)), 0.0005,
        step(0.02, averageColor));
    // Apply phosphor glow effect
    vec4 sum = vec4(0.0);
    vec4 pixels[9];
    pixels[0] = texture2D(tex, tc - vec2(0.001, 0.001));
    pixels[1] = texture2D(tex, tc - vec2(0.001, 0.0));
    pixels[2] = texture2D(tex, tc - vec2(0.001, -0.001));
    pixels[3] = texture2D(tex, tc - vec2(0.0, 0.001));
    pixels[4] = texture2D(tex, tc);
    pixels[5] = texture2D(tex, tc + vec2(0.001, 0.001));
    pixels[6] = texture2D(tex, tc + vec2(0.001, 0.0));
    pixels[7] = texture2D(tex, tc + vec2(0.001, -0.001));
    pixels[8] = texture2D(tex, tc + vec2(0.0, 0.001));

// Perform operations on input pixels in parallel
    sum = pixels[0]
        + pixels[1]
        + pixels[2]
        + pixels[3]
        + pixels[4]
        + pixels[5]
        + pixels[6]
        + pixels[7]
        + pixels[8];
    sum /= 9.0;
    sum += texture2D(tex, tc - vec2(0.01, 0.01)) * 0.001;
    sum += texture2D(tex, tc - vec2(0.0, 0.01)) * 0.001;
    sum += texture2D(tex, tc - vec2(-0.01, 0.01)) * 0.001;
    sum += texture2D(tex, tc - vec2(0.01, 0.0)) * 0.001;
    sum += color * PHOSPHOR_BLUR_AMOUNT;
    sum += texture2D(tex, tc - vec2(-0.01, 0.0)) * 0.001;
    sum += texture2D(tex, tc - vec2(0.01, -0.01)) * 0.001;
    sum += texture2D(tex, tc - vec2(0.0, -0.01)) * 0.001;
    sum += texture2D(tex, tc - vec2(-0.01, -0.01)) * 0.001;
    sum *= PHOSPHOR_GLOW_AMOUNT;

    // Initialize sum_sum_factor to zero
    vec4 sum_sum_factor = vec4(0.0);
    // Compute sum_j for i = -1
    vec4 sum_j = vec4(0.0);
    sum_j += texture2D(tex, tc + vec2(-1, -1) * 0.01);
    sum_j += texture2D(tex, tc + vec2(0, -1) * 0.01);
    sum_j += texture2D(tex, tc + vec2(1, -1) * 0.01);
    sum_j += texture2D(tex, tc + vec2(-1, 0) * 0.01);
    sum_j += texture2D(tex, tc + vec2(0, 0) * 0.01);
    sum_j += texture2D(tex, tc + vec2(1, 0) * 0.01);
    sum_j += texture2D(tex, tc + vec2(-1, 1) * 0.01);
    sum_j += texture2D(tex, tc + vec2(0, 1) * 0.01);
    sum_j += texture2D(tex, tc + vec2(1, 1) * 0.01);
    sum_sum_factor += sum_j * vec4(0.011);

    // Compute sum_j for i = 0
    sum_j = vec4(0.0);
    sum_j += texture2D(tex, tc + vec2(-1, 0) * 0.01);
    sum_j += texture2D(tex, tc + vec2(0, 0) * 0.01);
    sum_j += texture2D(tex, tc + vec2(1, 0) * 0.01);
    sum_j += texture2D(tex, tc + vec2(-1, 1) * 0.01);
    sum_j += texture2D(tex, tc + vec2(0, 1) * 0.01);
    sum_j += texture2D(tex, tc + vec2(1, 1) * 0.01);
    sum_sum_factor += sum_j * vec4(0.011);

    // Compute sum_j for i = 1
    sum_j = vec4(0.0);
    sum_j += texture2D(tex, tc + vec2(-1, 0) * 0.01);
    sum_j += texture2D(tex, tc + vec2(0, 1) * 0.01);
    sum_j += texture2D(tex, tc + vec2(1, 0) * 0.01);
    sum_j += texture2D(tex, tc + vec2(-1, 1) * 0.01);
    sum_j += texture2D(tex, tc + vec2(0, 1) * 0.01);
    sum_j += texture2D(tex, tc + vec2(1, 1) * 0.01);
    sum_sum_factor += sum_j * vec4(0.011);
    color += mix(sum_sum_factor * sum_sum_factor * vec4(factor), sum, 0.5);
    return color;
}

vec4 applyAdaptiveSharpen(vec2 tc, vec4 color, sampler2D tex) {
    vec4 color_tl = texture2D(tex, tc + vec2(-1.0, -1.0) * 0.5 / 2160.0);
    vec4 color_tr = texture2D(tex, tc + vec2(1.0, -1.0) * 0.5 / 2160.0);
    vec4 color_bl = texture2D(tex, tc + vec2(-1.0, 1.0) * 0.5 / 2160.0);
    vec4 color_br = texture2D(tex, tc + vec2(1.0, 1.0) * 0.5 / 2160.0);
    float sharpness = SHARPNESS;
    vec3 color_no_alpha = color.rgb;
    vec3 color_tl_no_alpha = color_tl.rgb;
    vec3 color_tr_no_alpha = color_tr.rgb;
    vec3 color_bl_no_alpha = color_bl.rgb;
    vec3 color_br_no_alpha = color_br.rgb;
    float delta = (dot(color_no_alpha, vec3(0.333333)) + dot(color_tl_no_alpha, vec3(0.333333)) + dot(color_tr_no_alpha, vec3(0.333333)) + dot(color_bl_no_alpha, vec3(0.333333)) + dot(color_br_no_alpha, vec3(0.333333))) * 0.2 - dot(color_no_alpha, vec3(0.333333));
    vec3 sharp_color_no_alpha = color_no_alpha + min(vec3(0.0), vec3(delta * sharpness));
    vec4 sharp_color = vec4(sharp_color_no_alpha, color.a);
    return sharp_color;
}

vec4 applyScanlines(vec2 tc, vec4 color) {
    float scanline = (cos(tc.y * SCANLINE_FREQUENCY + SCANLINE_TIME) *
                      sin(tc.y * SCANLINE_FREQUENCY + SCANLINE_TIME)) * SCANLINE_THICKNESS;
    float alpha = clamp(1.0 - abs(scanline), 0.0, 1.0);
    return vec4(color.rgb * alpha, color.a);
}

vec4 applyChromaticAberration(vec2 uv, vec4 color) {
    vec2 center = vec2(0.5, 0.5); // center of the screen
    vec2 offset = (uv - center) * CHROMATIC_ABERRATION_STRENGTH; // calculate the offset from the center

    // apply lens distortion
    float rSquared = dot(offset, offset);
    float distortion = 1.0 + LENS_DISTORTION_AMOUNT * rSquared;
    vec2 distortedOffset = offset * distortion;

    // apply chromatic aberration
    vec2 redOffset = vec2(distortedOffset.x * 1.00, distortedOffset.y * 1.00);
    vec2 blueOffset = vec2(distortedOffset.x * 1.00, distortedOffset.y * 1.00);

    vec4 redColor = texture2D(tex, uv + redOffset);
    vec4 blueColor = texture2D(tex, uv + blueOffset);

    vec4 result = vec4(redColor.r, color.g, blueColor.b, color.a);

    return result;
}

vec4 reduceGlare(vec4 color) {
    // Calculate the intensity of the color by taking the average of the RGB components
    float intensity = (color.r + color.g + color.b) / 3.0;
    // Set the maximum intensity that can be considered for glare
    float maxIntensity = 0.98;
    // Use smoothstep to create a smooth transition from no glare to full glare
    // based on the intensity of the color and the maximum intensity
    float glareIntensity = smoothstep(maxIntensity - 0.02, maxIntensity, intensity);
    // Set the amount of glare to apply to the color
    float glareAmount = 0.02;
    // Mix the original color with the reduced color that has glare applied to it
    vec3 reducedColor = mix(color.rgb, vec3(glareIntensity), glareAmount);
    // Return the reduced color with the original alpha value
    return vec4(reducedColor, color.a);
}

// Apply a fake HDR effect to the input color.
// Parameters:
// - inputColor: the color to apply the effect to.
// - brightness: the brightness of the image. Should be a value between 0 and 1.
// - contrast: the contrast of the image. Should be a value between 0 and 1.
// - saturation: the saturation of the image. Should be a value between 0 and 2.
// - bloom: the intensity of the bloom effect. Should be a value between 0 and 1.
vec4 applyFakeHDREffect(vec4 inputColor, float brightness, float contrast, float saturation, float bloom) {
    const float minBrightness = 0.0;
    const float maxBrightness = 1.0;
    const float minContrast = 0.0;
    const float maxContrast = 1.0;
    const float minSaturation = 0.0;
    const float maxSaturation = 2.0;
    const float minBloom = 0.0;
    const float maxBloom = 1.0;

    // Check input parameters for validity
    if (brightness < minBrightness || brightness > maxBrightness) {
        return vec4(0.0, 0.0, 0.0, 1.0); // Return black with alpha of 1.0 to indicate error
    }
    if (contrast < minContrast || contrast > maxContrast) {
        return vec4(0.0, 0.0, 0.0, 1.0);
    }
    if (saturation < minSaturation || saturation > maxSaturation) {
        return vec4(0.0, 0.0, 0.0, 1.0);
    }
    if (bloom < minBloom || bloom > maxBloom) {
        return vec4(0.0, 0.0, 0.0, 1.0);
    }

    // Apply brightness and contrast
    vec3 color = inputColor.rgb;
    color = (color - vec3(0.5)) * exp2(brightness * 10.0) + vec3(0.5);
    color = mix(vec3(0.5), color, pow(contrast * 4.0 + 1.0, 2.0));

    // // NTSC
    // vec3 lumCoeff = vec3(0.2125, 0.7154, 0.0721);

    // // BT.709
    // vec3 lumCoeff = vec3(0.299, 0.587, 0.114);

    // // BT.2020
    // vec3 lumCoeff = vec3(0.2627, 0.6780, 0.0593);

    // Warm NTSC
    vec3 lumCoeff = vec3(0.2125, 0.7010, 0.0865);

    // Apply saturation
    float luminance = dot(color, lumCoeff);
    vec3 grey = vec3(luminance);
    color = mix(grey, color, saturation);

    // Apply bloom effect
    float threshold = 1.0 - bloom;
    vec3 bloomColor = max(color - threshold, vec3(0.0));
    bloomColor = pow(bloomColor, vec3(2.0));
    bloomColor = mix(vec3(0.0), bloomColor, pow(min(luminance, threshold), 4.0));
    color += bloomColor;

    return vec4(color, inputColor.a);
}

vec4 bilateralFilter(sampler2D tex, vec2 uv, vec4 color, float sampleRadius, float noiseThreshold, float intensity) {
    vec4 filteredColor = vec4(0.0);
    float totalWeight = 0.0;

    // Top-left pixel
    vec4 sample = texture2D(tex, uv + vec2(-1.0, -1.0));
    float dist = length(vec2(-1.0, -1.0));
    float colorDist = length(sample - color);
    float weight = exp(-0.5 * (dist * dist + colorDist * colorDist * intensity) / (sampleRadius * sampleRadius));
    filteredColor += sample * weight;
    totalWeight += weight;

    // Top pixel
    sample = texture2D(tex, uv + vec2(0.0, -1.0));
    dist = length(vec2(0.0, -1.0));
    colorDist = length(sample - color);
    weight = exp(-0.5 * (dist * dist + colorDist * colorDist * intensity) / (sampleRadius * sampleRadius));
    filteredColor += sample * weight;
    totalWeight += weight;

    // Top-right pixel
    sample = texture2D(tex, uv + vec2(1.0, -1.0));
    dist = length(vec2(1.0, -1.0));
    colorDist = length(sample - color);
    weight = exp(-0.5 * (dist * dist + colorDist * colorDist * intensity) / (sampleRadius * sampleRadius));
    filteredColor += sample * weight;
    totalWeight += weight;

    // Left pixel
    sample = texture2D(tex, uv + vec2(-1.0, 0.0));
    dist = length(vec2(-1.0, 0.0));
    colorDist = length(sample - color);
    weight = exp(-0.5 * (dist * dist + colorDist * colorDist * intensity) / (sampleRadius * sampleRadius));
    filteredColor += sample * weight;
    totalWeight += weight;

    // Center pixel
    sample = texture2D(tex, uv);
    dist = 0.0;
    colorDist = length(sample - color);
    weight = exp(-0.5 * (dist * dist + colorDist * colorDist * intensity) / (sampleRadius * sampleRadius));
    filteredColor += sample * weight;
    totalWeight += weight;

    // Right pixel
    sample = texture2D(tex, uv + vec2(1.0, 0.0));
    dist = length(vec2(1.0, 0.0));
    colorDist = length(sample - color);
    weight = exp(-0.5 * (dist * dist + colorDist * colorDist * intensity) / (sampleRadius * sampleRadius));
    filteredColor += sample * weight;
    totalWeight += weight;

    // Bottom-left pixel
    sample = texture2D(tex, uv + vec2(-1.0, 1.0));
    dist = length(vec2(-1.0, 1.0));
    colorDist = length(sample - color);
    weight = exp(-0.5 * (dist * dist + colorDist * colorDist * intensity) / (sampleRadius * sampleRadius));
    filteredColor += sample * weight;
    totalWeight += weight;

// Bottom pixel
    sample = texture2D(tex, uv + vec2(0.0, sampleRadius));
    dist = length(vec2(0.0, sampleRadius));
    colorDist = length(sample - color);
    weight = exp(-0.5 * (dist * dist + colorDist * colorDist * intensity) / (sampleRadius * sampleRadius));
    filteredColor += sample * weight;
    totalWeight += weight;

    filteredColor /= totalWeight;
    return mix(color, filteredColor, step(noiseThreshold, length(filteredColor - color)));
}

vec4 supersample(sampler2D tex, vec2 uv, float sampleRadius, float noiseThreshold, float intensity) {
    float radiusSq = sampleRadius * sampleRadius;
    vec2 poissonDisk;
    vec4 color = vec4(0.0);

    float r1_0 = sqrt(0.0 / 16.0);
    float r2_0 = fract(1.0 / 3.0);
    float theta_0 = TWOPI * r2_0;
    poissonDisk = vec2(r1_0 * cos(theta_0), r1_0 * sin(theta_0));
    color += texture2D(tex, uv + poissonDisk * sampleRadius);

    float r1_1 = sqrt(1.0 / 16.0);
    float r2_1 = fract(2.0 / 3.0);
    float theta_1 = TWOPI * r2_1;
    poissonDisk = vec2(r1_1 * cos(theta_1), r1_1 * sin(theta_1));
    color += texture2D(tex, uv + poissonDisk * sampleRadius);

    float r1_2 = sqrt(2.0 / 16.0);
    float r2_2 = fract(3.0 / 3.0);
    float theta_2 = TWOPI * r2_2;
    poissonDisk = vec2(r1_2 * cos(theta_2), r1_2 * sin(theta_2));
    color += texture2D(tex, uv + poissonDisk * sampleRadius);

    float r1_3 = sqrt(3.0 / 16.0);
    float r2_3 = fract(4.0 / 3.0);
    float theta_3 = TWOPI * r2_3;
    poissonDisk = vec2(r1_3 * cos(theta_3), r1_3 * sin(theta_3));
    color += texture2D(tex, uv + poissonDisk * sampleRadius);

    float r1_4 = sqrt(4.0 / 16.0);
    float r2_4 = fract(5.0 / 3.0);
    float theta_4 = TWOPI * r2_4;
    poissonDisk = vec2(r1_4 * cos(theta_4), r1_4 * sin(theta_4));
    color += texture2D(tex, uv + poissonDisk * sampleRadius);

    float r1_5 = sqrt(5.0 / 16.0);
    float r2_5 = fract(6.0 / 3.0);
    float theta_5 = TWOPI * r2_5;
    poissonDisk = vec2(r1_5 * cos(theta_5), r1_5 * sin(theta_5));
    color += texture2D(tex, uv + poissonDisk * sampleRadius);

    float r1_6 = sqrt(6.0 / 16.0);
    float r2_6 = fract(7.0 / 3.0);
    float theta_6 = TWOPI * r2_6;
    poissonDisk = vec2(r1_6 * cos(theta_6), r1_6 * sin(theta_6));
    color += texture2D(tex, uv + poissonDisk * sampleRadius);

    float r1_7 = sqrt(7.0 / 16.0);
    float r2_7 = fract(8.0 / 3.0);
    float theta_7 = TWOPI * r2_7;
    poissonDisk = vec2(r1_7 * cos(theta_7), r1_7 * sin(theta_7));
    color += texture2D(tex, uv + poissonDisk * sampleRadius);

    float r1_8 = sqrt(8.0 / 16.0);
    float r2_8 = fract(9.0 / 3.0);
    float theta_8 = TWOPI * r2_8;
    poissonDisk = vec2(r1_8 * cos(theta_8), r1_8 * sin(theta_8));
    color += texture2D(tex, uv + poissonDisk * sampleRadius);

    float r1_9 = sqrt(9.0 / 16.0);
    float r2_9 = fract(10.0 / 3.0);
    float theta_9 = TWOPI * r2_9;
    poissonDisk = vec2(r1_9 * cos(theta_9), r1_9 * sin(theta_9));
    color += texture2D(tex, uv + poissonDisk * sampleRadius);

    float r1_10 = sqrt(10.0 / 16.0);
    float r2_10 = fract(11.0 / 3.0);
    float theta_10 = TWOPI * r2_10;
    poissonDisk = vec2(r1_10 * cos(theta_10), r1_10 * sin(theta_10));
    color += texture2D(tex, uv + poissonDisk * sampleRadius);

    float r1_11 = sqrt(11.0 / 16.0);
    float r2_11 = fract(12.0 / 3.0);
    float theta_11 = TWOPI * r2_11;
    poissonDisk = vec2(r1_11 * cos(theta_11), r1_11 * sin(theta_11));
    color += texture2D(tex, uv + poissonDisk * sampleRadius);

    float r1_12 = sqrt(12.0 / 16.0);
    float r2_12 = fract(13.0 / 3.0);
    float theta_12 = TWOPI * r2_12;
    poissonDisk = vec2(r1_12 * cos(theta_12), r1_12 * sin(theta_12));
    color += texture2D(tex, uv + poissonDisk * sampleRadius);

    float r1_13 = sqrt(13.0 / 16.0);
    float r2_13 = fract(14.0 / 3.0);
    float theta_13 = TWOPI * r2_13;
    poissonDisk = vec2(r1_13 * cos(theta_13), r1_13 * sin(theta_13));
    color += texture2D(tex, uv + poissonDisk * sampleRadius);

    float r1_14 = sqrt(14.0 / 16.0);
    float r2_14 = fract(15.0 / 3.0);
    float theta_14 = TWOPI * r2_14;
    poissonDisk = vec2(r1_14 * cos(theta_14), r1_14 * sin(theta_14));
    color += texture2D(tex, uv + poissonDisk * sampleRadius);

    float r1_15 = sqrt(15.0 / 16.0);
    float r2_15 = fract(16.0 / 3.0);
    float theta_15 = TWOPI * r2_15;
    poissonDisk = vec2(r1_15 * cos(theta_15), r1_15 * sin(theta_15));
    color += texture2D(tex, uv + poissonDisk * sampleRadius);

    return bilateralFilter(tex, uv, color, sampleRadius, noiseThreshold, intensity);
}
void main() {
    vec2 tc_no_dist = v_texcoord;

    vec2 tc = applyBarrelDistortion(tc_no_dist, DISTORTION_AMOUNT);

    // [-1, 1]
    vec2 tc_no_dist_symmetric = tc_no_dist * 2.0 - 1.0;

    // [0,1]
    vec2 tc_no_dist_normalized = (tc_no_dist_symmetric + 1.0) / 2.0;

    // vec4 color = texture2D(tex, tc);
    vec4 color = supersample(tex, tc, SAMPLING_RADIUS, NOISE_THRESHOLD, DENOISE_INTENSITY);

    color = applyAdaptiveSharpen(tc, color, tex);

    color = applyPhosphorGlow(tc, color, tex);

    color = reduceGlare(color);

    color = mix(applyFakeHDREffect(color, HDR_BRIGHTNESS, HDR_CONTRAST, HDR_SATURATION, HDR_BLOOM), color, 0.5);

    color = applyColorCorrection(color);

    color /= SUPERSAMPLING_SAMPLES;

    color = mix(applyChromaticAberration(tc, color), color, 0.25);

    color = mix(color, applyVignette(color), 0.37);

    color = applyBorder(tc_no_dist_normalized, color, 1.0 - BORDER_SIZE * BORDER_RADIUS, BORDER_COLOR);

    color = mix(applyBorder(tc, color, BORDER_SIZE, BORDER_COLOR), color, 0.05);

    color = applyScanlines(tc, color);

    gl_FragColor = color;
    gl_FragColor.a = 1.0;
}

