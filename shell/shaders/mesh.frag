#version 440
// Mesh gradient: four soft colour fields drifting around each other, like
// light under frosted glass. `time` loops 0..1.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float w;
    float h;
    float intensity;
    vec4 c1;
    vec4 c2;
    vec4 c3;
    vec4 bg;
};

float hash(vec2 p) {
    p = fract(p * vec2(443.897, 441.423));
    p += dot(p, p.yx + 19.19);
    return fract((p.x + p.y) * p.x);
}

void main() {
    vec2 uv = qt_TexCoord0;
    float aspect = w / max(h, 1.0);
    vec2 p = vec2(uv.x * aspect, uv.y);
    float t = time * 6.2831853;

    // a gentle swirl so the fields bend instead of sliding
    vec2 q = p + 0.08 * vec2(sin(p.y * 3.0 + t), cos(p.x * 3.0 - t));

    vec2 a = vec2((0.25 + 0.12 * cos(t)) * aspect, 0.30 + 0.12 * sin(t * 2.0));
    vec2 b = vec2((0.78 + 0.10 * sin(t)) * aspect, 0.25 + 0.14 * cos(t));
    vec2 c = vec2((0.55 + 0.16 * sin(t * 2.0 + 1.0)) * aspect, 0.80 + 0.08 * cos(t + 2.0));
    vec2 d = vec2((0.12 + 0.08 * sin(t + 3.0)) * aspect, 0.85 + 0.10 * sin(t));

    float wa = 1.0 / pow(length(q - a) + 0.12, 2.4);
    float wb = 1.0 / pow(length(q - b) + 0.12, 2.4);
    float wc = 1.0 / pow(length(q - c) + 0.12, 2.4);
    float wd = 1.0 / pow(length(q - d) + 0.12, 2.4) * 0.8;
    float sum = wa + wb + wc + wd;

    // the theme colours are pastel accents: deepen them so text stays readable
    vec3 deep = bg.rgb;
    vec3 k1 = mix(deep, c1.rgb, 0.62);
    vec3 k2 = mix(deep, c2.rgb, 0.5);
    vec3 k3 = mix(deep, c3.rgb, 0.58);
    vec3 col = (k1 * wa + k2 * wb + k3 * wc + deep * wd * 1.6) / (sum + wd * 0.6);
    col = mix(deep, col, intensity);

    // fine dither so the gradients never band
    col += (hash(uv * vec2(w, h)) - 0.5) / 255.0 * 2.0;

    fragColor = vec4(col * bg.a, bg.a) * qt_Opacity;
}
