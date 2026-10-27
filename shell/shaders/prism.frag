#version 440
// Light through glass: soft beams fanning from a point above the screen, each
// split into the three theme colours, drifting slowly. `time` loops 0..1.
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
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 4; i++) {
        v += a * noise(p);
        p = p * 2.07 + vec2(3.1, 1.7);
        a *= 0.5;
    }
    return v;
}

// one beam: brightness at angle `ang` for a beam centred on `centre`
float beam(float ang, float centre, float width) {
    float d = (ang - centre) / width;
    return exp(-d * d);
}

void main() {
    vec2 uv = qt_TexCoord0;
    float aspect = w / max(h, 1.0);
    vec2 p = vec2((uv.x - 0.5) * aspect, uv.y);
    float t = time * 6.2831853;

    // the light source sits above the top edge and sways a little
    vec2 src = vec2(sin(t) * 0.18 * aspect, -0.35 + cos(t * 2.0) * 0.03);
    vec2 d = p - src;
    float ang = atan(d.x, d.y);
    float dist = length(d);

    vec3 col = bg.rgb;
    // dust in the air, so beams have texture
    float dust = fbm(vec2(ang * 6.0, dist * 3.0 - time * 2.0) + vec2(cos(t), sin(t)) * 0.6);

    for (int i = 0; i < 5; i++) {
        float fi = float(i);
        float centre = -0.75 + fi * 0.37 + sin(t + fi * 1.7) * 0.07;
        float width = 0.05 + 0.035 * (0.5 + 0.5 * sin(t * 2.0 + fi * 2.3));
        // dispersion: the three colours separate the further the light travels
        float spread = 0.012 + dist * 0.035;
        float b1 = beam(ang, centre - spread, width);
        float b2 = beam(ang, centre, width);
        float b3 = beam(ang, centre + spread, width);
        float fall = smoothstep(1.9, 0.1, dist) * (0.55 + 0.45 * dust);
        float k = intensity * fall * (0.35 + 0.15 * sin(fi * 3.1 + t));
        col += (c1.rgb * b1 + c2.rgb * b2 + c3.rgb * b3) * k;
    }

    // a glow where the light enters
    col += mix(c2.rgb, vec3(1.0), 0.35) * exp(-dist * 3.2) * 0.35 * intensity;

    // floating motes catching the light
    vec2 grid = uv * vec2(w, h) / 6.0;
    vec2 cell = floor(grid);
    float mote = step(0.9965, hash(cell)) * (0.5 + 0.5 * sin(t * 4.0 + hash(cell + 7.0) * 40.0));
    col += mix(c1.rgb, vec3(1.0), 0.5) * mote * 0.5 * intensity * smoothstep(1.6, 0.2, dist);

    float vig = smoothstep(1.25, 0.3, length((uv - vec2(0.5, 0.45)) * vec2(1.0, 1.15)));
    col *= mix(0.65, 1.0, vig);

    fragColor = vec4(col * bg.a, bg.a) * qt_Opacity;
}
