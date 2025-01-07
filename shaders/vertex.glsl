#version 330 core

layout(location = 0) in vec4 position;
layout(location = 1) in vec4 normals;
layout(location = 2) in vec2 texture;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform mat3 normalmodel;

out vec2 tcoord;
out vec3 tnormal; 
out vec3 fragpos;


void main() {

    mat4 transform = projection * view * model;

    tnormal = normalmodel * normals.xyz;
    fragpos = vec3(model * position);

    gl_Position = transform * position;


    tcoord = texture;

}


