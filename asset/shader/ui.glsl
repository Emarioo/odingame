#vertex
#version 330 core

layout (location = 0) in vec2 aPos;

uniform vec2 uWindow;
uniform vec2 uPos;
uniform vec2 uSize;
uniform vec4 uColor;

out vec2 fTexcoord;

void main()
{
    fTexcoord = aPos;
    gl_Position = vec4(2*(uPos.x + aPos.x * uSize.x) / uWindow.x - 1.0, -2*(uPos.y + (1-aPos.y) * uSize.y) / uWindow.y+1, 0.0, 1.0);
}

#fragment
#version 330 core
out vec4 FragColor;

in vec2 fTexcoord;

uniform vec4 uColor;
uniform sampler2D uSampler;

void main()
{
    vec4 result = uColor;
    // vec4 result = vec4(1);
    result *= texture(uSampler, fTexcoord);
    // result *= vec4(fTexcoord,0,1);
    FragColor = result;
} 