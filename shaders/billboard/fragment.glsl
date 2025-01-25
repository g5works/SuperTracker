#version 330 core

uniform sampler2D helpertex;
uniform vec3 helpercolor;

in vec2 tcoord;


out vec4 color;

void main() {

    vec4 t = texture(helpertex, tcoord);
    if (t.a < 0.5) {
        discard;
    }

    
    color = t * vec4(helpercolor, 1);

}