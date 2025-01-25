#version 330 core

//outputs
out vec4 color;

in vec2 tcoord;

uniform sampler2D texture_image;


void main() {

    
    



    // color = (ambient+diffuse+spec)*vec4(lightcolor, 1)*dc;
    color = texture(texture_image, tcoord);
    // color = vec4(1,1,1,1);

}
