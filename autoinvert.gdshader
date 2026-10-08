shader_type canvas_item;


uniform float fireball_scale_y = 1.0;
uniform float glow_scale_y = 1.0;
uniform float glow_strength = 1.0;
uniform float glow_intensity = 0.0;
uniform sampler2D noise : repeat_enable, filter_nearest_mipmap_anisotropic;
uniform sampler2D noise2 : repeat_enable, filter_nearest_mipmap_anisotropic;
uniform sampler2D colo_curve;
uniform int pixel_size : hint_range(1, 100) = 1;

// Parameters for position and size
uniform vec2 glow_position = vec2(0.5, 0.5);
uniform vec2 glow_size = vec2(0.2, 0.2);

// Parameters for pulsating effect
uniform bool pulsate = false;
uniform float pulsation_speed = 1.0;
uniform float glow_intensity_start = 0.75;
uniform float glow_intensity_stop = 1.0;

// Helper function to generate noise patterns (remains unchanged)
vec4 f1(vec2 uv, float time){
    vec4 nv2 = texture(noise, uv + vec2(time, 0.0));
    vec4 n2v2 = texture(noise2, uv + vec2(time*.8, 0.0));
    nv2.r = max(0., nv2.r + uv.x - 1.0);
    n2v2.r = max(0., n2v2.r + uv.x - 1.0);
    return nv2 * n2v2;
}

void fragment()
{
    // 1. Get the original color from the sprite's texture
    vec4 base_color = texture(TEXTURE, UV);

    // 2. Calculate the inverted color (alpha is preserved)
    vec4 inverted_color = vec4(1.0 - base_color.rgb, base_color.a);

    // This variable will hold the result of applying effects to the inverted_color
    vec4 effect_result = inverted_color;

    // --- UV Setup for Fireball Core ---
    vec2 mUV = (UV - glow_position) / glow_size; // UVs relative to glow center and scale
    vec2 uv_fireball = (mUV - 0.5) * 2.0 * vec2(1.0, fireball_scale_y); // Scaled UVs for noise sampling
    float time = TIME;
    vec2 cuv = mUV - vec2(0.5); // Centered UVs within the glow area
    float d2c = length(cuv);    // Distance from the center of the glow area

    // --- Core Fireball Noise Application (applied to effect_result) ---
    effect_result *= (f1(uv_fireball, time) + f1(uv_fireball + vec2(0.1, 0.0), time + 11.514) + f1(uv_fireball + vec2(0.05, 0.0), time + 14.14));

    // --- Red Channel Manipulation (on effect_result) ---
    effect_result.r -= 1.0;
    effect_result.r = -pow(effect_result.r, 2.0) + 1.0;

    // --- Color Remapping with Curve (on effect_result) ---
    // The alpha of effect_result is preserved from inverted_color.a
    effect_result.rgb = texture(colo_curve, vec2(effect_result.r, 0.0)).rgb;

    // --- Edge Softening/Shaping based on Distance and Noise (on effect_result) ---
    float randmoo_shape = texture(noise2, mUV + vec2(time, -time)).r;
    randmoo_shape = mix(randmoo_shape, 0.0, mUV.x); // Fade noise effect to the right
    effect_result.r *= smoothstep(0.5, 0.48 - (0.2 - min(mUV.x, 1.0) * 0.2), d2c + randmoo_shape * 0.4);

    // --- Further Red Channel Attenuation (on effect_result) ---
    // Make very dark red channel values completely black in RGB
    effect_result.rgb = mix(effect_result.rgb, vec3(0.0), smoothstep(0.00001, 0.0, effect_result.r));

    // --- Glow Calculation ---
    vec2 glowUV = (UV - glow_position) / glow_size; // UVs for glow, same as mUV
    float d2c_l = length(glowUV * vec2(1.0, glow_scale_y) - vec2(0.58, 0.5 * glow_scale_y)); // Distance for glow, slightly offset

    // Oscillating glow_intensity if pulsate is true
    float current_glow_intensity = pulsate ? mix(glow_intensity_start, glow_intensity_stop, 0.5 + 0.5 * sin(time * pulsation_speed * 3.14159 * 2.0)) : glow_intensity;

    float glow_amount = -log(d2c_l + current_glow_intensity) * glow_strength;
    float randmoo_glow = texture(noise2, vec2(time, -time)).r; // Different noise instance for glow

    // Apply Glow (to effect_result)
    // Glow color is also sampled from colo_curve, perturbed by noise
    vec4 glow_color_from_curve = texture(colo_curve, vec2(1.0 - d2c_l - 0.1 * randmoo_glow, 0.0));
    effect_result.rgb += glow_color_from_curve.rgb * glow_amount; // Additive to RGB channels

    // --- Pixelation Effect ---
    // This samples the *original* texture (TEXTURE) to calculate an average,
    // then subtracts it from the current effect_result.
    vec2 pixel_pos = UV / TEXTURE_PIXEL_SIZE;
    vec2 square_size = vec2(float(pixel_size), float(pixel_size));
    vec2 block_top_left = floor(pixel_pos / square_size) * square_size;
    vec4 avg_original_block_color = vec4(0.0);

    for (int x = 0; x < pixel_size; x++){
        for (int y = 0; y < pixel_size; y++){
            avg_original_block_color += texture(TEXTURE, (block_top_left + vec2(float(x), float(y))) * TEXTURE_PIXEL_SIZE);
        }
    }
    avg_original_block_color /= float(pixel_size * pixel_size);

    effect_result -= avg_original_block_color; // Subtract average original color from the effect

    // --- Final Combination ---
    // The calculated effect (which was based on the inverted color) is added to the base color.
    COLOR = base_color * effect_result;
    // The alpha channel will be base_color.a + effect_result.a.
    // Since effect_result.a started as base_color.a and was then modified by `effect_result -= avg_original_block_color;`
    // (so effect_result.a = base_color.a - avg_original_block_color.a),
    // the final COLOR.a = base_color.a + (base_color.a - avg_original_block_color.a)
    //                 = 2.0 * base_color.a - avg_original_block_color.a.
    // This will then be used by the `blend_add` mode.
}

