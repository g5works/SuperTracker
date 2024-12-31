#version 330 core

layout(location = 0) in vec4 position;
layout(location = 1) in vec4 normals;
layout(location = 2) in vec2 texture;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;


uniform vec4 offsets;

out vec4 fragcolor;
out vec2 tcoord;


void main() {


    gl_Position = projection * view * model * position;

    fragcolor = normals;
    tcoord = texture;

}


