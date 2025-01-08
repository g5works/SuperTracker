package strack

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

import "loaders"
import "primitives"

WIDTH: i32 = 1280
HEIGHT: i32 = 720

VertexBloc :: struct {
    vbo: u32,
    vao: u32,
    count: i32
}

IndexTri :: [3]u32



main :: proc() {

    assert(sdl.Init(sdl.INIT_EVERYTHING) >= 0)
    defer sdl.Quit()

    sdl.GL_SetAttribute(sdl.GLattr.CONTEXT_MAJOR_VERSION, 3)
    sdl.GL_SetAttribute(sdl.GLattr.CONTEXT_MINOR_VERSION, 3)
    sdl.GL_SetAttribute(sdl.GLattr.CONTEXT_PROFILE_MASK, gl.CONTEXT_CORE_PROFILE_BIT)
    sdl.GL_SetAttribute(sdl.GLattr.STENCIL_SIZE, 8)

    win: ^sdl.Window = sdl.CreateWindow("SuperTracker", sdl.WINDOWPOS_CENTERED, sdl.WINDOWPOS_CENTERED, WIDTH, HEIGHT, {.OPENGL})
    assert(win != nil)
    defer sdl.DestroyWindow(win)

    glContext: sdl.GLContext = sdl.GL_CreateContext(win)
    sdl.GL_MakeCurrent(win, glContext)

    //load opengl functions
    gl.load_up_to(3, 3, sdl.gl_set_proc_address)
    gl.Enable(gl.DEPTH_TEST)

    //textureparams
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)


    //vsync
    sdl.GL_SetSwapInterval(1);

    //load up shaders
    rdprog, rduni := loadShaders(#load("./shaders/render/vertex.glsl"), #load("./shaders/render/debugfragment.glsl"))
    bbprog, bbuni := loadShaders(#load("./shaders/billboard/vertex.glsl"), #load("./shaders/billboard/fragment.glsl"))
    sbprog, sbuni := loadShaders(#load("./shaders/skybox/vertex.glsl"), #load("./shaders/skybox/fragment.glsl"))

    //make buffers
    vbl_object := createVertexBloc(primitives.cube)
    bbl_object := createVertexBloc(primitives.plane)
    sky_object := createVertexBloc(primitives.cube)

    gl.UseProgram(rdprog)
    loadTexture("textures/cobblestone/wedged-cobblestone_albedo.png", rduni["tex"].location, 1)
    loadTexture("textures/cobblestone/wedged-cobblestone_normal-ogl.png", rduni["normaltex"].location, 2)

    gl.UseProgram(bbprog)
    loadTexture("textures/pointlight.png", bbuni["helpertex"].location, 3)

    gl.UseProgram(sbprog)
    skytex := loadCubeMap({
        "textures/nebula/px.png", 
        "textures/nebula/nx.png", 
        "textures/nebula/py.png",
        "textures/nebula/ny.png", 
        "textures/nebula/pz.png", 
        "textures/nebula/nz.png"
    })


    event: sdl.Event

    x: f32 = 0

    running: for {

        if sdl.PollEvent(&event) {

            if event.type == sdl.EventType.QUIT {
                
                break running

            }

            if event.type == sdl.EventType.KEYDOWN {

                #partial switch event.key.keysym.scancode {

                    case sdl.Scancode.ESCAPE:
                        break running

                }

            }
            
        }


        
        lights: [][2]glm.vec3 = {
            {{5*glm.sin(x), 0, 5*glm.cos(x)}, {1, 1, 1}}
        }

        camera: glm.vec3 = {10,10,10}
        lookDirection: glm.vec3 = {0, 0, 0}

        
        //action!


        gl.Viewport(0, 0, WIDTH, HEIGHT)
        // gl.ClearColor(0, 0, 0, 1)
        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
        // gl.Clear(gl.DEPTH_BUFFER_BIT)

        //these are ur view and projection matrices, really just black box functions rn
        view: glm.mat4 = glm.mat4LookAt(camera, lookDirection, {0, 1, 0})
        skyview: glm.mat4 = glm.mat4(glm.mat3(view))
        projection: glm.mat4 = glm.mat4Perspective(glm.radians(cast(f32)60.0), cast(f32)WIDTH/cast(f32)HEIGHT, 0.1, 100.0)              

        gl.DepthMask(false)
        bindVertexBloc(sky_object)
        gl.UseProgram(sbprog)
        
        gl.UniformMatrix4fv(sbuni["view"].location, 1, false, &view[0,0])
        gl.UniformMatrix4fv(sbuni["projection"].location, 1, false, &projection[0,0])

        gl.BindTexture(gl.TEXTURE_CUBE_MAP, skytex)
        gl.DrawArrays(gl.TRIANGLES, 0, sky_object.count)
        gl.DepthMask(true)

        //draw rendering objects
        bindVertexBloc(vbl_object)
        gl.UseProgram(rdprog)

        gl.UniformMatrix4fv(rduni["view"].location, 1, false, &view[0,0])
        gl.UniformMatrix4fv(rduni["projection"].location, 1, false, &projection[0,0])
        gl.Uniform3f(rduni["camerapos"].location, camera[0], camera[1], camera[2])

        model: glm.mat4 = glm.mat4(1.0)
        model *= glm.mat4Rotate({glm.sin(x), glm.cos(x), glm.sin(2*x)}, x)
        setModelMatrixUniform(rduni, &model, "model", "normalmodel")

        gl.DrawArrays(gl.TRIANGLES, 0, vbl_object.count)        



        //draw light helpers
        bindVertexBloc(bbl_object)
        gl.UseProgram(bbprog)
        gl.UniformMatrix4fv(bbuni["view"].location, 1, false, &view[0,0])
        gl.UniformMatrix4fv(bbuni["projection"].location, 1, false, &projection[0,0])
        for i in lights {
            
            // draw helpers 
            gl.UseProgram(bbprog) //switch into billboard shader
            lightmodel: glm.mat4 = glm.mat4(1)
            lightmodel *= glm.mat4Scale(1)
            lightmodel *= glm.mat4Translate({i[0][0], i[0][1], i[0][2]})
      
            gl.Uniform2f(bbuni["scale"].location, 0.5, 0.5)
            gl.UniformMatrix4fv(bbuni["model"].location, 1, false, &lightmodel[0,0])
            gl.DrawArrays(gl.TRIANGLES, 0, bbl_object.count)

            //set light position for render shaders
            gl.UseProgram(rdprog) //switch into render shader
            gl.Uniform3f(rduni["lightpos"].location, i[0][0], i[0][1], i[0][2])
            gl.Uniform3f(rduni["lightcolor"].location, i[1][0], i[1][1], i[1][2])

        }

        glCheckError()


        sdl.GL_SwapWindow(win)
        x += 0.01
    }

    



}



loadShaders :: proc(vsc: []u8, fsc: []u8) -> (u32, map[string]gl.Uniform_Info) {

    program, program_loaded := gl.load_shaders_source(string(vsc), string(fsc))
    assert(program_loaded)
    // defer gl.DeleteProgram(program)
    uniforms := gl.get_uniforms_from_program(program)

    fmt.println("Shaders built properly!")

    gl.UseProgram(program)
    
    return program, uniforms

}

fillVBuffer :: proc(vbo: u32, vertices: []primitives.Vertex) {

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
fillVBufferWithModel :: proc(vbo: u32, mfile: string) -> i32 {

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

fillIBuffer :: proc(ibo: u32, indices: [][3]u32) {

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ibo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(indices)*size_of(IndexTri), raw_data(indices), gl.STATIC_DRAW)

}

loadCubeMap :: proc(paths: [6]cstring) -> u32 {

    tex: u32;
    width, height, channels: i32
    texd: rawptr
    depth: u32


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

    return tex

}

loadTexture :: proc(path: cstring, textureUniform: i32, textureSlot: u32) -> u32 {

    //define variables here statically
    texture: u32
    width, height, channels: i32
    texture_data: rawptr
    colormode: u32

    gl.ActiveTexture(gl.TEXTURE0 + textureSlot)

    gl.GenTextures(1, &texture)
    gl.BindTexture(gl.TEXTURE_2D, texture)


    img.set_flip_vertically_on_load(1)
    texture_data = img.load(path, &width, &height, &channels, 0)
    defer img.image_free(texture_data)

    //auto pick the color mode
    colormode = channels == 4 ? gl.RGBA : gl.RGB

    gl.TexImage2D(gl.TEXTURE_2D, 0, cast(i32)colormode, width, height, 0, colormode, gl.UNSIGNED_BYTE, texture_data)
    gl.GenerateMipmap(gl.TEXTURE_2D)


    gl.Uniform1i(textureUniform, cast(i32)textureSlot)
    
    return texture

}

createVertexBloc :: proc(vertices: []primitives.Vertex) -> VertexBloc {

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


bindVertexBloc :: proc(vb: VertexBloc) {
    gl.BindVertexArray(vb.vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, vb.vbo)
}

surfaceToTexture :: proc(surface: ^sdl.Surface, textureUniform: i32, textureSlot: u32) {

    texture: u32
    colormode: u32

    gl.ActiveTexture(gl.TEXTURE0 + textureSlot)

    gl.GenTextures(1, &texture)
    gl.BindTexture(gl.TEXTURE_2D, texture)



    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, surface.w, surface.h, 0, gl.RGBA, gl.UNSIGNED_BYTE, surface.pixels)
    gl.GenerateMipmap(gl.TEXTURE_2D)

}

setModelMatrixUniform :: proc(uniforms: map[string]gl.Uniform_Info, model: ^glm.mat4, modelUni: string, normalUni: string) {

    normal: glm.mat3 = glm.mat3(glm.transpose(glm.inverse(model^)))

    gl.UniformMatrix4fv(uniforms[modelUni].location, 1, false, &model[0,0])
    gl.UniformMatrix3fv(uniforms[normalUni].location, 1, false, &normal[0,0])

}

glCheckError :: proc() {


    for glerror := gl.GetError(); glerror != 0; {
        fmt.println(glerror);
        assert(false)
    }

}

glCheckErrorLoop :: proc(loopcounter: i32) {

    for glerror := gl.GetError(); glerror != 0; {
        fmt.println(glerror)
        fmt.println(loopcounter)
        assert(false)
    }

}
