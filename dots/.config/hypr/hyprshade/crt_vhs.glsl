#version 300 es

precision highp float;

in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;

// Hyprland 0.56.2 Screen Shader API。
uniform sampler2D tex;
uniform float time;
uniform vec2 fullSize;

// ============================================================================
// 参数调节区
// ----------------------------------------------------------------------------
// 所有“像素”参数都会除以 fullSize，因此不写死 1366p、1080p、2K 或 4K。
// 某项不需要时，把对应的“强度”改为 0.0 即可关闭。
//
// 这个版本模仿参考代码的风格：平时有模拟电视波纹和 RGB 偏移，每隔一段时间
// 发生一次短促的信号故障；故障时抖动、横向波浪、RGB 分离、块状噪声会增强。
// 默认值仍比参考网页克制一些，避免终端和编辑器文字完全无法阅读。
// ============================================================================

// ---------- 周期性故障包络 ----------
const float GLITCH_INTERVAL       = 95.0;   // 故障周期（秒）；越小故障越频繁。
const float GLITCH_DURATION       = 0.65;  // 每个周期末尾的增强时长（秒）。
const float GLITCH_POWER          = 0.72;  // 周期性故障总强度；0.0 关闭强故障。
const float BASE_GLITCH           = 0.10;  // 平时持续存在的轻微信号不稳程度。

// ---------- 整屏抖动 ----------
const float SHAKE_BASE_PIXELS     = 0.30;  // 平时整屏随机抖动，单位：物理像素。
const float SHAKE_GLITCH_PIXELS   = 4.50;  // 强故障时额外抖动，单位：物理像素。
const float SHAKE_RATE            = 24.0;  // 每秒重新生成抖动位置的次数。

// ---------- 水平信号波浪 / 撕裂 ----------
const float WAVE_BASE_PIXELS      = 0.55;  // 平时横向波纹位移，单位：像素。
const float WAVE_GLITCH_PIXELS    = 7.00;  // 强故障时横向波纹额外位移。
const float WAVE_DENSITY_1        = 0.018; // 第一层波纹密度；越大横纹越密。
const float WAVE_DENSITY_2        = 0.047; // 第二层细波纹密度。
const float WAVE_SPEED            = 22.0;  // 横向信号波纹的动画速度。

// ---------- 从上向下滚动的同步撕裂带 ----------
const float ROLLING_TEAR_STRENGTH = 0.75;  // 滚动撕裂强度；0.0 关闭。
const float ROLLING_TEAR_WIDTH    = 0.060; // 撕裂带高度，占屏幕高度比例。
const float ROLLING_TEAR_SPEED    = 0.20;  // 每秒滚动屏幕比例；0.20 = 5 秒一圈。
const float ROLLING_TEAR_PIXELS   = 11.0;  // 撕裂带最大水平错位，单位：像素。

// ---------- RGB 分离 ----------
const float RGB_SHIFT_BASE_PIXELS = 0.90;  // 平时 R/B 两侧偏移，单位：像素。
const float RGB_SHIFT_GLITCH      = 7.00;  // 强故障时额外 RGB 分离，单位：像素。
const float RGB_SHIFT_TEAR        = 2.50;  // 滚动撕裂带内额外 RGB 分离。

// ---------- 块状噪声 ----------
const float BLOCK_NOISE_STRENGTH  = 0.26;  // 块噪声亮度；0.0 关闭。
const float BLOCK_NOISE_AMOUNT    = 0.10;  // 平时块噪声出现概率。
const float BLOCK_GLITCH_AMOUNT   = 0.28;  // 强故障时增加的出现概率。
const float BLOCK_SHIFT_PIXELS    = 70.0;  // 噪声块引用画面的水平错位像素数。
const float BLOCK_RATE            = 20.0;  // 块噪声每秒变化次数。

// ---------- 白噪点和横向暗纹 ----------
const float WHITE_NOISE_STRENGTH  = 0.035; // 全屏白噪点强度。
const float GLITCH_NOISE_BOOST    = 0.090; // 强故障时额外噪点。
const float HORIZONTAL_LINE       = 0.055; // 高频水平暗纹强度。

// ---------- 原 CRT 基础效果 ----------
const float CURVATURE             = 0.060; // CRT 桶形曲率。
const float SCANLINE_STRENGTH     = 0.070; // 细扫描线强度。
const float RGB_MASK_STRENGTH     = 0.025; // RGB 荧光粉子像素强度。
const float VIGNETTE_STRENGTH     = 0.180; // 四角暗角强度。
const float FLICKER_STRENGTH      = 0.006; // 很轻的整体亮度闪烁。
const float SCREEN_SCALE_X        = 1.064; // 横向画面缩放；1.0 原始大小，小于 1.0 缩小。
const float SCREEN_SCALE_Y        = 1.010; // 纵向画面缩放；可与横向独立调节。
const float EDGE_SOFTNESS         = 1.50;  // 管面边缘软化宽度，单位：像素。

// ----------------------------------------------------------------------------
// 廉价随机函数。避免使用参考代码中的完整 3D simplex noise，以控制 compositor
// 的长期 GPU 开销；通过多层正弦和分块 hash 获得相似的模拟信号风格。
// ----------------------------------------------------------------------------
float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float smoothPulse(float center, float width, float y) {
    float d = abs(y - center);
    d = min(d, 1.0 - d);
    return 1.0 - smoothstep(width * 0.20, width, d);
}

void main() {
    vec2 resolution = max(fullSize, vec2(1.0));
    vec2 pixel = 1.0 / resolution;

    // 每个周期末尾逐渐进入强故障，随后快速归零，接近参考代码的 strength 包络。
    float cycleTime = mod(time, GLITCH_INTERVAL);
    float glitchStart = GLITCH_INTERVAL - min(GLITCH_DURATION, GLITCH_INTERVAL);
    float glitchEnvelope = smoothstep(glitchStart, GLITCH_INTERVAL, cycleTime);
    glitchEnvelope *= glitchEnvelope;
    float glitch = clamp(BASE_GLITCH + glitchEnvelope * GLITCH_POWER, 0.0, 1.0);

    // 离散随机整屏抖动，比连续 sin 更像同步信号丢失。
    float shakeFrame = floor(time * SHAKE_RATE);
    vec2 shakeRandom = vec2(
        hash21(vec2(shakeFrame, 13.1)),
        hash21(vec2(shakeFrame, 71.7))
    ) * 2.0 - 1.0;
    vec2 shake = shakeRandom * (SHAKE_BASE_PIXELS + glitch * SHAKE_GLITCH_PIXELS) * pixel;

    float yPixel = v_texcoord.y * resolution.y;

    // 多层横向波浪：每一行获得不同 X 位移，模拟坏信号和水平同步漂移。
    float wave1 = sin(yPixel * WAVE_DENSITY_1 + time * WAVE_SPEED);
    float wave2 = sin(yPixel * WAVE_DENSITY_2 - time * WAVE_SPEED * 0.47);
    float wave3 = sin(yPixel * 0.006 + floor(time * 8.0) * 2.17);
    float rgbWavePixels = (wave1 * 0.58 + wave2 * 0.27 + wave3 * 0.15)
                        * (WAVE_BASE_PIXELS + glitch * WAVE_GLITCH_PIXELS);

    // 两条极细、偶发的水平同步跳线，对应参考代码中的 step(sin(...)) 尖峰。
    float spikeA = step(0.9975, sin(yPixel * 0.011 + time * 1.6));
    float spikeB = step(0.9985, sin(yPixel * 0.007 - time * 2.1));
    rgbWavePixels += spikeA * (3.0 + glitch * 8.0);
    rgbWavePixels -= spikeB * (4.0 + glitch * 10.0);

    // 从上向下滚动的旧电视垂直同步撕裂带。
    float tearCenter = fract(time * ROLLING_TEAR_SPEED);
    float rollingTear = smoothPulse(tearCenter, ROLLING_TEAR_WIDTH, v_texcoord.y);
    float tearGrain = hash21(vec2(floor(yPixel * 0.12), floor(time * 30.0))) * 2.0 - 1.0;
    float tearShape = 0.60 * sin(yPixel * 0.19 + time * 31.0)
                    + 0.25 * sin(yPixel * 0.053 - time * 13.0)
                    + 0.15 * tearGrain;
    float tearShiftPixels = rollingTear * tearShape
                          * ROLLING_TEAR_STRENGTH * ROLLING_TEAR_PIXELS;

    // CRT 桶形曲面；纵横比修正让不同屏幕方向下曲率相近。
    vec2 p = v_texcoord * 2.0 - 1.0;
    float aspect = resolution.x / resolution.y;
    vec2 radial = p * vec2(min(aspect, 1.0), min(1.0 / aspect, 1.0));
    float r2 = dot(radial, radial);
    p *= 1.0 + CURVATURE * r2;
    vec2 uv = p * 0.5 + 0.5;
    // 横向和纵向独立缩放；大于 1.0 放大，小于 1.0 缩小并露出边缘。
    uv = (uv - 0.5) / max(vec2(SCREEN_SCALE_X, SCREEN_SCALE_Y), vec2(0.001)) + 0.5;
    uv += shake;
    uv.x += (rgbWavePixels + tearShiftPixels) * pixel.x;

    // 主画面固定三次采样：R/G/B 各一次。故障越强，色彩分离越明显。
    float rgbDiffPixels = RGB_SHIFT_BASE_PIXELS
                        + glitch * RGB_SHIFT_GLITCH
                        + rollingTear * ROLLING_TEAR_STRENGTH * RGB_SHIFT_TEAR;
    rgbDiffPixels += sin(time * 47.0 + v_texcoord.y * 40.0) * (0.20 + glitch * 1.20);
    vec2 rgbOffset = vec2(rgbDiffPixels * pixel.x, 0.0);

    vec3 color;
    color.r = texture(tex, uv + rgbOffset).r;
    color.g = texture(tex, uv).g;
    color.b = texture(tex, uv - rgbOffset).b;

    // 块状信号噪声：按低分辨率网格随机选区；仅命中时混入一份错位画面。
    // 这里额外 1 次 texture lookup，总采样数为 4，比参考实现的 9 次更适合桌面常驻。
    float blockFrame = floor(time * BLOCK_RATE);
    vec2 blockCell = floor(vec2(v_texcoord.x * 14.0, v_texcoord.y * 32.0));
    float blockRand = hash21(blockCell + vec2(blockFrame * 1.37, blockFrame * 2.11));
    float blockThreshold = BLOCK_NOISE_AMOUNT + glitch * BLOCK_GLITCH_AMOUNT;
    float blockMask = 1.0 - step(blockThreshold, blockRand);

    // 再用较粗网格裁切，使噪声形成参考代码那种断续矩形，而不是覆盖整行。
    vec2 coarseCell = floor(vec2(v_texcoord.x * 5.0, v_texcoord.y * 9.0));
    float coarseMask = step(0.52, hash21(coarseCell + vec2(blockFrame * 0.73)));
    blockMask *= coarseMask * BLOCK_NOISE_STRENGTH;

    float blockDirection = hash21(vec2(blockFrame, 8.3)) * 2.0 - 1.0;
    vec2 blockUV = uv + vec2(blockDirection * BLOCK_SHIFT_PIXELS * pixel.x, 0.0);
    vec3 blockColor = texture(tex, blockUV).rgb;
    color = mix(color, blockColor + vec3(0.025, 0.010, 0.035), blockMask);

    // 每帧变化的细白噪点；滚动撕裂区和强故障期间略微增强。
    float whiteNoise = hash21(gl_FragCoord.xy + vec2(floor(time * 60.0) * 17.0,
                                                      floor(time * 60.0) * 29.0)) * 2.0 - 1.0;
    float noiseAmount = WHITE_NOISE_STRENGTH
                      + glitch * GLITCH_NOISE_BOOST
                      + rollingTear * ROLLING_TEAR_STRENGTH * 0.035;
    color += whiteNoise * noiseAmount;

    // 高频暗纹和传统 CRT 扫描线。
    float waveNoise = 0.5 + 0.5 * sin(yPixel * 1.55 + time * 2.0);
    color -= waveNoise * HORIZONTAL_LINE * (0.55 + glitch * 0.75);

    float scan = 0.5 + 0.5 * sin(6.2831853 * (gl_FragCoord.y * 0.50 + time * 0.35));
    color *= 1.0 - SCANLINE_STRENGTH * scan;

    // RGB 荧光粉三色子像素结构。
    float phase = mod(floor(gl_FragCoord.x), 3.0);
    vec3 mask = phase < 1.0 ? vec3(1.0, 0.72, 0.72)
              : phase < 2.0 ? vec3(0.72, 1.0, 0.72)
                            : vec3(0.72, 0.72, 1.0);
    color *= mix(vec3(1.0), mask, RGB_MASK_STRENGTH);

    // 撕裂带内附加一点亮度跳动，模拟水平同步脉冲不稳定。
    color *= 1.0 + rollingTear * tearShape * ROLLING_TEAR_STRENGTH * 0.035;

    // 整体亮度轻微闪烁。
    color *= 1.0 + FLICKER_STRENGTH
                   * (0.72 * sin(time * 7.3) + 0.28 * sin(time * 13.7));

    // CRT 四角暗角。
    vec2 edge = abs(v_texcoord * 2.0 - 1.0);
    float vignette = smoothstep(0.20, 1.25, dot(edge, edge));
    color *= 1.0 - VIGNETTE_STRENGTH * vignette;

    // 管面之外变黑，边缘宽度按物理像素计算。
    vec2 inside = smoothstep(vec2(0.0), EDGE_SOFTNESS * pixel, uv)
                * smoothstep(vec2(0.0), EDGE_SOFTNESS * pixel, 1.0 - uv);
    color *= inside.x * inside.y;

    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}