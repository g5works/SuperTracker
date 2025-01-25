#version 330 core

layout(location = 0) in vec4 position;
layout(location = 1) in vec4 normals;
layout(location = 2) in vec2 texture;
layout(location = 4) in vec2 offset;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform mat3 normalmodel;



out vec2 tcoord;



void main() {

    mat4 offset_model = model;
    offset_model[3] = vec4(offset.x, offset.y, 0, 1);

    mat4 transform = projection * view * offset_model;


    tcoord = texture;

    


    gl_Position = transform * position;


}


