#version 330 core

layout(location = 0) in vec4 position;
layout(location = 1) in vec4 normals;
layout(location = 2) in vec2 texture;

uniform mat4 view;
uniform mat4 projection;
uniform mat4 model;
uniform vec2 scale;

out vec2 tcoord;

void main() {

    mat4 vm = view*model;
    vm[0] = vec4(scale.x, 0, 0, vm[0][3]);
    vm[1] = vec4(0, scale.y, 0, vm[1][3]);
    vm[2] = vec4(0, 0, 1, vm[2][3]);

    tcoord = texture;

    gl_Position = projection*vm*position;

}