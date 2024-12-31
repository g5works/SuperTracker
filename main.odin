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

WIDTH: i32 = 640
HEIGHT: i32 = 480


IndexTri :: [3]u32




main :: proc() {



    
    vertices: [dynamic]loaders.Vertex = loaders.readOBJFile("models/cube.obj")
    defer delete(vertices)


    for i in vertices {
        fmt.println(i.position)
    }


    // vertices: []loaders.Vertex = {

    //     { {  0.5,  0.5,  0.5  }, {  1.0,  0.3,  0.0  }, {  1.0,  1.0  } }, // front top right 0
    //     { { -0.5,  0.5,  0.5  }, {  1.0,  1.0,  0.0  }, {  0.0,  1.0  } }, // front top left 1

    //     { {  0.5, -0.5,  0.5  }, {  1.0,  1.0,  0.0  }, {  1.0,  0.0  } }, // front bottom right 2
    //     { { -0.5, -0.5,  0.5  }, {  1.0,  0.3,  0.0  }, {  0.0,  0.0  } }, // front bottom left 3


    //     { {  0.5,  0.5, -0.5  }, {  1.0,  0.3,  0.0  }, {  1.0,  1.0  } }, // back top right 4
    //     { { -0.5,  0.5, -0.5  }, {  1.0,  1.0,  0.0  }, {  0.0,  1.0  } }, // back top left 5

    //     { {  0.5, -0.5, -0.5  }, {  1.0,  1.0,  0.0  }, {  1.0,  0.0  } }, // back bottom right 6
    //     { { -0.5, -0.5, -0.5  }, {  1.0,  0.3,  0.0  }, {  0.0,  0.0  } }, // back bottom left 7


    // }

    // vertices: []loaders.Vertex = {

    //     {{ 0.5,  0.5,  0.5}, {1.0, 1.0, 1.0} ,{0.0, 0.0}},
    //     {{-0.5, -0.5,  0.5}, {1.0, 1.0, 1.0} ,{1.0, 1.0}},
    //     {{ 0.5, -0.5,  0.5}, {1.0, 1.0, 1.0} ,{0.0, 1.0}},
    //     {{-0.5, -0.5,  0.5}, {1.0, 1.0, 1.0} ,{1.0, 1.0}},
    //     {{ 0.5,  0.5,  0.5}, {1.0, 1.0, 1.0} ,{0.0, 0.0}},
    //     {{-0.5,  0.5,  0.5}, {1.0, 1.0, 1.0} ,{1.0, 0.0}},


    // }

    // indices: []IndexTri = {
 
    //     {0, 1, 3},
    //     {0, 2, 3},
    //     {0, 2, 6},

    // }

     
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
    gl.DepthFunc(gl.LEQUAL)
  

    
    //vsync
    sdl.GL_SetSwapInterval(1);

    //load up shaders
    program, uniforms := loadShaders(#load("./shaders/vertex.glsl"), #load("./shaders/fragment.glsl"))

    //make buffers
    vao,vbo,ibo: u32
    gl.GenVertexArrays(1, &vao)
    defer gl.DeleteVertexArrays(1, &vao)
    gl.BindVertexArray(vao)

    gl.GenBuffers(1, &vbo)
    defer gl.DeleteBuffers(1, &vbo)
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)

    // gl.GenBuffers(1, &ibo)
    // defer gl.DeleteBuffers(gl.ELEMENT_ARRAY_BUFFER, &ibo)

    //vertex, index
    fillVBuffer(vbo, vertices)
    // fillIBuffer(ibo, indices)

    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)

    loadTexture("sphere.png", uniforms["tex"].location, 1);

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
        


        gl.Viewport(0, 0, WIDTH, HEIGHT)
        gl.ClearColor(0, 0, 0, 1)
        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)


        position: glm.vec3 = {0, 0, 0}

        model: glm.mat4 = glm.mat4(1.0)
        view: glm.mat4 = glm.mat4Translate({0, 0, -1})
        projection: glm.mat4 = glm.mat4Perspective(glm.radians(cast(f32)60.0), cast(f32)WIDTH/cast(f32)HEIGHT, 0.1, 100.0)              


        model *= glm.mat4Translate({0, 0, -3})
        model *= glm.mat4Rotate(1, x)

        
        
        //so simple, so elegant, just looking like a wow
        gl.UniformMatrix4fv(uniforms["camera"].location, 1, false, &projection[0,0])
        gl.UniformMatrix4fv(uniforms["view"].location, 1, false, &view[0,0])
        gl.UniformMatrix4fv(uniforms["model"].location, 1, false, &model[0,0])

        gl.DrawArrays(gl.TRIANGLES, 0, cast(i32)(len(vertices)/3))
        // gl.DrawElements(gl.TRIANGLES, i32(len(indices)*3), gl.UNSIGNED_INT, nil)
        

        glCheckError()
        
        sdl.GL_SwapWindow(win)
        x += 0.01

    }

    



}



loadShaders :: proc(vsc: []u8, fsc: []u8) -> (u32, map[string]gl.Uniform_Info) {

    program, program_loaded := gl.load_shaders_source(string(vsc), string(fsc))
    assert(program_loaded)
    defer gl.DeleteProgram(program)
    uniforms := gl.get_uniforms_from_program(program)

    fmt.println("Shaders built properly!")

    gl.UseProgram(program)
    
    return program, uniforms

}

fillVBuffer :: proc(vbo: u32, vertices: [dynamic]loaders.Vertex) {

    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)

    gl.BufferData(gl.ARRAY_BUFFER, len(vertices)*size_of(loaders.Vertex), raw_data(vertices), gl.STATIC_DRAW)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(loaders.Vertex), offset_of(loaders.Vertex, position))
    gl.VertexAttribPointer(1, 3, gl.FLOAT, false, size_of(loaders.Vertex), offset_of(loaders.Vertex, normal))
    gl.VertexAttribPointer(2, 2, gl.FLOAT, false, size_of(loaders.Vertex), offset_of(loaders.Vertex, texture))

    gl.EnableVertexAttribArray(0);
    gl.EnableVertexAttribArray(1);
    gl.EnableVertexAttribArray(2);


}

fillIBuffer :: proc(ibo: u32, indices: [][3]u32) {

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ibo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(indices)*size_of(IndexTri), raw_data(indices), gl.STATIC_DRAW)

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

glCheckError :: proc() {


    for glerror := gl.GetError(); glerror != 0; {
        fmt.println(glerror);
        assert(false)
    }

}

