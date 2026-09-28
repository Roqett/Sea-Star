#include <metal_stdlib>
using namespace metal;

// Living-water shaders: the slow caustic that makes the header face read as
// breathing water rather than a sticker, and the fine grain that gives the
// rockpool's void the visual snow of a dark-adapted eye.

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

// A slow, drifting caustic for the header face. Two value-noise fields, sampled
// at different scales and drifting in different directions, are summed into a
// highlight. The highlight is applied *only* where the artwork already has ink
// (its alpha), so the silhouette never moves — only the light across it does.
[[ stitchable ]] half4 caustics(float2 position, half4 color, float time, float size) {
    // Wrap the clock before it reaches the hash. The caller passes absolute
    // reference-date time (~7.8e8) and float32 cannot represent fractional parts
    // past 2^23, so an unwrapped coordinate makes hash21() collapse to a constant
    // and the drift freezes.
    float t = fmod(time, 3600.0);

    // Normalise against the drawn size so the shimmer's scale doesn't change with
    // how large the header icon happens to be.
    float2 uv = position / max(size, 1.0) * 3.0;

    float n0 = valueNoise(uv + float2(t * 0.11, t * -0.07));
    float n1 = valueNoise(uv * 2.3 + float2(t * -0.09, t * 0.13));

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

// A single soft speck drawn in one grid cell: empty unless the cell's hash
// clears the threshold, and gently twinkling on its own stable phase, so a field
// of them shimmers rather than translates like a scraped texture.
static float speckle(float2 p, float threshold, float time) {
    float2 cell = floor(p);
    float2 f = fract(p) - 0.5;
    float r = hash21(cell);
    if (r < threshold) return 0.0;

    float glow = 1.0 - smoothstep(0.0, 0.5, length(f));
    float twinkle = 0.55 + 0.45 * sin(time * 1.3 + r * 42.0);
    return glow * twinkle * (0.3 + 0.7 * r);
}

// The rockpool's grain: the faint visual snow of a dark-adapted eye, laid into
// the water behind the starfield. Sparse by design — most cells stay empty and
// the few that glint do so cool and dim — so it never lifts the pool's black or
// competes with a node. Two grids drift in different directions so the field
// never sits still and never betrays a repeating lattice.
[[ stitchable ]] half4 grain(float2 position, half4 color, float time, float size) {
    // Same precision guard as the caustic above: the clock must be wrapped before
    // it feeds the hash, or every cell hashes to a constant and no speck lands.
    float t = fmod(time, 3600.0);

    // ~150 cells across the pool's shorter side, so specks stay a constant size
    // however large or small the pool is drawn.
    float2 uv = position / max(size, 1.0) * 150.0;

    float2 drift0 = float2(t * 0.35, t * 0.22);
    float2 drift1 = float2(t * -0.27, t * 0.18);

    float snow = speckle(uv + drift0, 0.965, t) * 0.65;
    snow += speckle(uv * 1.9 + drift1, 0.982, t) * 0.35;

    half3 tint = half3(0.52h, 0.60h, 0.68h);

    return half4(color.rgb + tint * half(snow) * 0.30h, color.a);
}
