#version 450

layout (location = 0) out vec3 fColor;

vec2 points[3] = vec2[](
    vec2(0.0, -0.5),
    vec2(0.5, 0.5),
    vec2(-0.5, 0.5)
);

vec3 colors[3] = vec3[](
    vec3(1.0, 0.1, 0.1),
    vec3(0.1, 1.0, 0.1),
    vec3(0.1, 0.1, 1.0)
);

void main() {
    fColor = colors[gl_VertexIndex];
    gl_Position = vec4(points[gl_VertexIndex], 0, 1.0);
}
