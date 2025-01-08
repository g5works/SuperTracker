#version 330 core

out vec4 color;

in vec3 TexCoords;

uniform samplerCube skybox;

void main()
{    
    color = texture(skybox, TexCoords);
    // color = vec4(1,0,1,1);
}