#vertex
#version 330 core

layout (location = 0) in vec2 aPos;

uniform vec2 uWindow;
uniform vec2 uPos;
uniform vec2 uSize;
uniform vec4 uColor;

void main()
{
    gl_Position = vec4((uPos.x + aPos.x * uSize.x) / uWindow.x - 0.5, (-uPos.y + aPos.y * uSize.y) / uWindow.y + 0.5, 0.0, 1.0);
}

#fragment
#version 330 core
out vec4 FragColor;

uniform vec4 uColor;

void main()
{
    FragColor = uColor;
    // vec4(1.0f, 0.5f, 0.2f, 1.0f);
} 