package primitives

Vertex :: struct {

    position: glm.vec3,
    normal: glm.vec3,
    texture: glm.vec2

}

import glm "core:math/linalg/glsl"

plane: []Vertex = {
    {{  0, -1,  1 }, { 0, 0 ,1 }, {0, 1}},
    {{  0,  1,  1 }, { 0, 0 ,1 }, {1, 1}},
    {{  0, -1, -1 }, { 0, 0 ,1 }, {0, 0}},

    {{  0,  1,  1 }, { 0, 0, 1 }, {1, 1}},
    {{  0, -1, -1 }, { 0, 0, 1 }, {0, 0}},
    {{  0,  1, -1 }, { 0, 0, 1 }, {1, 0}}
}