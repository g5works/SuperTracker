#version 330 core

in vec4 fragcolor;
in vec2 tcoord;
out vec4 color;

uniform sampler2D tex;

void main() {

    vec4 tc = texture(tex, tcoord);
    // if (tc.a < 0.8) {
    //     discard;
    // }
    color = fragcolor;
    // color = vec4(1, 1, 1, 1);

}
