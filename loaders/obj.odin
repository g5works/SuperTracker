package loaders

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"
import glm "core:math/linalg/glsl"
import "../primitives/"

readOBJFile :: proc(path: string) -> [dynamic]primitives.Vertex {



    positions: [dynamic]glm.vec3
    normals: [dynamic]glm.vec3
    texture: [dynamic]glm.vec2

    vertices: [dynamic]primitives.Vertex

    data, readfail := os.read_entire_file_from_filename(path)
    assert(readfail)

    sd: string = string(data)

    for line in strings.split_lines_iterator(&sd) {

        identifier := strings.cut(line, 0, 2)

        if identifier == "v " {

            vline := strings.split_after(line, " ")
 
            arr: [3]f32 = {cast(f32)strconv.atof(vline[1]), cast(f32)strconv.atof(vline[2]), cast(f32)strconv.atof(vline[3])}

            append(&positions, arr)
            
        }       
        else if identifier == "vn" {
            
            nline := strings.split_after(line, " ")
 
            arr: [3]f32 = {cast(f32)strconv.atof(nline[1]), cast(f32)strconv.atof(nline[2]), cast(f32)strconv.atof(nline[3])}

            append(&normals, arr)

        }
        else if identifier == "vt" {
            
            vtline := strings.split_after(line, " ")
 
            arr: [2]f32 = {cast(f32)strconv.atof(vtline[1]), cast(f32)strconv.atof(vtline[2])}

            append(&texture, arr)

        }
        
        // positions/textures/normal
        if identifier == "f " {

            indices := strings.split(strings.cut(line, 2, 0), " ")

            

            if len(indices) == 4 {

                f1: [3][3]u32 = {convertIndexArray(indices[0]), convertIndexArray(indices[1]), convertIndexArray(indices[2])}
                f2: [3][3]u32 = {convertIndexArray(indices[0]), convertIndexArray(indices[2]), convertIndexArray(indices[3])}

     

                for i in f1 {

                    vtex: primitives.Vertex 
                    vtex.position = positions[i[0]]
                    vtex.texture = texture[i[1]]
                    vtex.normal = normals[i[2]]

                    append(&vertices, vtex)
                }

                for i in f2 {

                    vtex: primitives.Vertex 
                    vtex.position = positions[i[0]]
                    vtex.texture = texture[i[1]]
                    vtex.normal = normals[i[2]]

                    append(&vertices, vtex)
                }

            }
            else if len(indices) == 3 {


                f1: [3][3]u32 = {convertIndexArray(indices[0]), convertIndexArray(indices[1]), convertIndexArray(indices[2])}

                for i in f1 {

                    vtex: primitives.Vertex 
                    vtex.position = positions[i[0]]
                    vtex.texture = texture[i[1]]
                    vtex.normal = normals[i[2]]

                    append(&vertices, vtex)
                }


            }


        }

    }

    delete(positions)
    delete(texture)
    delete(data)

    return vertices

}



convertIndexArray :: proc(astr: string) -> [3]u32 {

    // 1/2/3
    arr := strings.split(astr, "/")
    indices: [3]u32 = {cast(u32)strconv.atoi(arr[0])-1, cast(u32)strconv.atoi(arr[1])-1, cast(u32)strconv.atoi(arr[2])-1}
    return indices

}