#include <metal_stdlib>
using namespace metal;

// A slow, drifting caustic that makes the header face read as living water
// rather than a sticker. Two value-noise fields, sampled at different scales and
// drifting in different directions, are summed into a highlight. The highlight is
// applied *only* where the artwork already has ink (its alpha), so the silhouette
// never moves — only the light travelling across it does.

static float hash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

static float valueNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);

    float a = hash21(i);
    float b = hash21(i + float2(1.0, 0.0));
    float c = hash21(i + float2(0.0, 1.0));
    float d = hash21(i + float2(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

[[ stitchable ]] half4 caustics(float2 position, half4 color, float time, float size) {
    // Normalise against the drawn size so the shimmer's scale doesn't change with
    // how large the header icon happens to be.
    float2 uv = position / max(size, 1.0) * 3.0;

    float n0 = valueNoise(uv + float2(time * 0.11, time * -0.07));
    float n1 = valueNoise(uv * 2.3 + float2(time * -0.09, time * 0.13));

    float caustic = 0.5 + 0.5 * (n0 * 0.65 + n1 * 0.35);
    caustic = pow(caustic, 2.2);

    half ink = color.a;
    half c = half(caustic);

    // A scaling shimmer plus an additive lift, both gated by ink coverage. Scaling
    // and additive terms behave the same whether the incoming colour arrives
    // premultiplied or straight, so this stays correct either way.
    half3 rgb = color.rgb * (1.0h + c * 0.28h) + half3(0.08h) * c * ink;

    return half4(rgb, ink);
}
