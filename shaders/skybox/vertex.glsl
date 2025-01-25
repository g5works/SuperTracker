#version 400 core

layout(location = 0) in vec4 position;
layout(location = 1) in vec4 normals;
layout(location = 2) in vec2 texture;

out vec3 TexCoords;

uniform mat4 projection;
uniform mat4 view;

void main()
{
    vec4 vp = projection * view * position;
    gl_Position = vp;
    TexCoords = position.xyz;

}  


