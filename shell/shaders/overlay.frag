#version 440
// Vignette + film grain over the whole screen.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float w;
    float h;
    float vignette;
    float grain;
};

float hash(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 c = (uv - 0.5) * vec2(w / max(h, 1.0), 1.0);
    float v = smoothstep(0.35, 1.05, length(c) * 1.1) * vignette;
    // grain: new pattern every frame step, centred on zero
    float n = hash(floor(uv * vec2(w, h)) + floor(time * 2400.0) * 1.37) - 0.5;
    // premultiplied: darken toward black for the vignette, add +/- grain
    float a = clamp(v + abs(n) * grain * 0.5, 0.0, 1.0);
    vec3 col = vec3(n > 0.0 ? grain * 0.5 : 0.0) * abs(n) * 2.0;
    fragColor = vec4(col, a) * qt_Opacity;
}
