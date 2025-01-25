package helpers

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"

import gl "vendor:OpenGL"
import sdl "vendor:sdl2"
import glm "core:math/linalg/glsl"
import glfw "vendor:glfw"
import img "vendor:stb/image"
import gltf "vendor:cgltf"

import "../loaders"
import "../primitives"

VertexBloc :: struct {
    vbo: u32,
    vao: u32,
    count: i32
}

InstanceArray :: struct {

    array: u32, 
    count: i32

}

Texture :: struct {
    id: u32,
    slot: i32
}

MVPMatrices :: struct {
    model: glm.mat4,
    view: glm.mat4,
    projection: glm.mat4
}

IndexTri :: [3]u32


draw_skybox :: proc(sprog: u32, uniforms: map[string]gl.Uniform_Info, texture_unit: i32, vbloc: VertexBloc, transform: ^MVPMatrices) {

    //disable depth mask
    gl.DepthMask(false)

    bind_vertex_bloc(vbloc)
    gl.UseProgram(sprog)
    skyboxview: glm.mat4 = glm.mat4(glm.mat3(transform^.view))


    gl.UniformMatrix4fv(uniforms["projection"].location, 1, false, &transform.projection[0,0])
    gl.UniformMatrix4fv(uniforms["view"].location, 1, false, &skyboxview[0,0])

    gl.Uniform1i(uniforms["skybox"].location, texture_unit)

    gl.DrawArrays(gl.TRIANGLES, 0, cast(i32)vbloc.count)

    //unbind our buffers for no undefined behavior
    gl.BindVertexArray(0)
    gl.BindBuffer(gl.ARRAY_BUFFER, 0)

    //reenable depth mask
    gl.DepthMask(true)

}

load_shaders :: proc(vsc: string, fsc: string) -> (u32, map[string]gl.Uniform_Info) {

    program, program_loaded := gl.load_shaders_file(vsc, fsc)
    assert(program_loaded)
    // defer gl.DeleteProgram(program)
    uniforms := gl.get_uniforms_from_program(program)

    fmt.println("Shaders built properly!")

    gl.UseProgram(program)
    
    return program, uniforms

}

fill_vertex_buffer :: proc(vbo: u32, vertices: []primitives.Vertex) {

    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BufferData(gl.ARRAY_BUFFER, len(vertices)*size_of(primitives.Vertex), raw_data(vertices), gl.STATIC_DRAW)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(primitives.Vertex), offset_of(primitives.Vertex, position))
    gl.VertexAttribPointer(1, 3, gl.FLOAT, false, size_of(primitives.Vertex), offset_of(primitives.Vertex, normal))
    gl.VertexAttribPointer(2, 2, gl.FLOAT, false, size_of(primitives.Vertex), offset_of(primitives.Vertex, texture))

    gl.EnableVertexAttribArray(0);
    gl.EnableVertexAttribArray(1);
    gl.EnableVertexAttribArray(2);


}

//use this only for temporary things
fill_vertex_buffer_obj :: proc(vbo: u32, mfile: string) -> i32 {

    vertices := loaders.readOBJFile(mfile)
    defer delete(vertices)

    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BufferData(gl.ARRAY_BUFFER, len(vertices)*size_of(primitives.Vertex), raw_data(vertices), gl.STATIC_DRAW)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(primitives.Vertex), offset_of(primitives.Vertex, position))
    gl.VertexAttribPointer(1, 3, gl.FLOAT, false, size_of(primitives.Vertex), offset_of(primitives.Vertex, normal))
    gl.VertexAttribPointer(2, 2, gl.FLOAT, false, size_of(primitives.Vertex), offset_of(primitives.Vertex, texture))

    gl.EnableVertexAttribArray(0);
    gl.EnableVertexAttribArray(1);
    gl.EnableVertexAttribArray(2);

    return cast(i32)len(vertices)

}

fill_index_buffer :: proc(ibo: u32, indices: [][3]u32) {

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ibo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(indices)*size_of(IndexTri), raw_data(indices), gl.STATIC_DRAW)

}

load_cube_map :: proc(uniforms: map[string]gl.Uniform_Info, uniname: string, unit: u32, paths: [6]cstring) -> u32 {

    tex: u32;
    width, height, channels: i32
    texd: rawptr
    depth: u32

    gl.ActiveTexture(gl.TEXTURE0+unit)
    gl.GenTextures(1, &tex)
    gl.BindTexture(gl.TEXTURE_CUBE_MAP, tex)    
    img.set_flip_vertically_on_load(0)

    //we're gonna need to load like 6 images now
    for i in 0..=5 {
        texd = img.load(paths[i], &width, &height, &channels, 0)
        if (texd != nil) {
            depth = (channels == 4 ? gl.RGBA : gl.RGB)
            gl.TexImage2D(gl.TEXTURE_CUBE_MAP_POSITIVE_X + cast(u32)i, 0, cast(i32)depth, width, height, 0, depth, gl.UNSIGNED_BYTE, texd)
            img.image_free(texd)
        }
        else {
            fmt.println("image failed to load")
            assert(false)
        }
    }
    gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_S, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_T, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_R, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.Uniform1i(uniforms[uniname].location, cast(i32)unit)
    return tex

}

load_texture :: proc(path: cstring, textureUniform: i32, textureSlot: u32) -> Texture {


    texture: Texture


    texture.slot = cast(i32)textureSlot

    //define variables here statically
    width, height, channels: i32
    texture_data: rawptr
    colormode: u32

    gl.ActiveTexture(gl.TEXTURE0 + textureSlot)

    gl.GenTextures(1, &texture.id)
    gl.BindTexture(gl.TEXTURE_2D, texture.id)


    texture_data = img.load(path, &width, &height, &channels, 0)
    defer img.image_free(texture_data)

    //auto pick the color mode
    colormode = channels == 4 ? gl.RGBA : gl.RGB

    gl.TexImage2D(gl.TEXTURE_2D, 0, cast(i32)colormode, width, height, 0, colormode, gl.UNSIGNED_BYTE, texture_data)
    gl.GenerateMipmap(gl.TEXTURE_2D)


    gl.Uniform1i(textureUniform, cast(i32)textureSlot)
    
    return texture

}

bind_texture :: proc(target: u32, uniforms: map[string]gl.Uniform_Info, uniform: string, texture: Texture) {

    uni := uniforms[uniform].location

    gl.ActiveTexture(0)
    gl.BindTexture(gl.TEXTURE_2D, 0)

    gl.ActiveTexture(gl.TEXTURE0 + cast(u32)texture.slot)
    gl.BindTexture(target, texture.id)
    gl.Uniform1i(uni, texture.slot)

}

create_vertex_bloc :: proc(vertices: []primitives.Vertex) -> VertexBloc {

    vb: VertexBloc;

    vb.count = cast(i32)len(vertices)
    gl.GenVertexArrays(1, &vb.vao)
    gl.GenBuffers(1, &vb.vbo)

    gl.BindVertexArray(vb.vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, vb.vbo)

    gl.BufferData(gl.ARRAY_BUFFER, len(vertices)*size_of(primitives.Vertex), raw_data(vertices), gl.STATIC_DRAW)

    //vertex positions
    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(primitives.Vertex), offset_of(primitives.Vertex, position))
    gl.EnableVertexAttribArray(0)

    //normals
    gl.VertexAttribPointer(1, 3, gl.FLOAT, false, size_of(primitives.Vertex), offset_of(primitives.Vertex, normal))
    gl.EnableVertexAttribArray(1)

    //texture positions
    gl.VertexAttribPointer(2, 2, gl.FLOAT, false, size_of(primitives.Vertex), offset_of(primitives.Vertex, texture))
    gl.EnableVertexAttribArray(2)

    return vb

}

create_instance_array :: proc(attrib: u32, instances: []glm.vec2) -> InstanceArray {

    array: InstanceArray
    gl.GenBuffers(1, &array.array)
    gl.BindBuffer(gl.ARRAY_BUFFER, array.array)
    gl.BufferData(gl.ARRAY_BUFFER, len(instances)*size_of(instances[0]), raw_data(instances), gl.STATIC_DRAW)

    gl.VertexAttribPointer(4+attrib, 2, gl.FLOAT, false, 2*size_of(f32), 0)
    gl.EnableVertexAttribArray(4+attrib)
    gl.VertexAttribDivisor(4+attrib, 1)

    array.count = cast(i32)len(instances)

    gl.BindBuffer(gl.ARRAY_BUFFER, 0)

    return array

}

bind_instance_array :: proc(array: InstanceArray) {
        gl.BindBuffer(gl.ARRAY_BUFFER, array.array)
}





bind_vertex_bloc :: proc(vb: VertexBloc) {
    gl.BindVertexArray(vb.vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, vb.vbo)
}

sdl_surface_to_texture :: proc(surface: ^sdl.Surface, uniforms: map[string]gl.Uniform_Info, tuni: string, textureSlot: u32) {

    texture: u32
    colormode: u32

    gl.ActiveTexture(gl.TEXTURE0 + textureSlot)

    gl.GenTextures(1, &texture)
    gl.BindTexture(gl.TEXTURE_2D, texture)



    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, surface.w, surface.h, 0, gl.RGBA, gl.UNSIGNED_BYTE, surface.pixels)
    gl.GenerateMipmap(gl.TEXTURE_2D)

    gl.Uniform1i(uniforms[tuni].location, cast(i32)textureSlot)
    

}

set_model_matrix_uni :: proc(uniforms: map[string]gl.Uniform_Info, model: ^glm.mat4, modelUni: string, normalUni: string) {

    normal: glm.mat3 = glm.mat3(glm.transpose(glm.inverse(model^)))

    gl.UniformMatrix4fv(uniforms[modelUni].location, 1, false, &model[0,0])
    gl.UniformMatrix3fv(uniforms[normalUni].location, 1, false, &normal[0,0])

}

gl_check_error :: proc() {


    for glerror := gl.GetError(); glerror != 0; {
        fmt.println(glerror);
        assert(false)
    }

}

gl_check_error_cnt :: proc(loopcounter: i32) {

    for glerror := gl.GetError(); glerror != 0; {
        fmt.println(glerror)
        fmt.println(loopcounter)
        assert(false)
    }

}

dim2_camera :: proc(transform: glm.vec3) -> glm.mat4 {

    m: glm.mat4 = glm.mat4(1)
    m *= glm.mat4Translate(-transform)

    return m

}