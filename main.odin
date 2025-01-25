package g5engine

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
import "helpers"

WIDTH: i32 = 1280
HEIGHT: i32 = 720
PI: f32 = 3.141592653

x: f32 = 0

positions: [dynamic]glm.vec2


main :: proc() {

    assert(sdl.Init(sdl.INIT_EVERYTHING) >= 0)
    defer sdl.Quit()

    sdl.GL_SetAttribute(sdl.GLattr.CONTEXT_MAJOR_VERSION, 3)
    sdl.GL_SetAttribute(sdl.GLattr.CONTEXT_MINOR_VERSION, 3)
    sdl.GL_SetAttribute(sdl.GLattr.CONTEXT_PROFILE_MASK, gl.CONTEXT_CORE_PROFILE_BIT)
    sdl.GL_SetAttribute(sdl.GLattr.STENCIL_SIZE, 8)

    win: ^sdl.Window = sdl.CreateWindow("g5engine", sdl.WINDOWPOS_CENTERED, sdl.WINDOWPOS_CENTERED, WIDTH, HEIGHT, sdl.WINDOW_OPENGL | sdl.WINDOW_RESIZABLE)
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
    rdprog, rduni := helpers.load_shaders("./shaders/render/vertex.glsl", "./shaders/render/fragment.glsl")

    //make buffers
    vbl_object := helpers.create_vertex_bloc(primitives.plane)
    sphere_object := helpers.create_vertex_bloc(primitives.cube)

    //make textures
    render_texture := helpers.load_texture("textures/copper.png", rduni["texture_image"].location, 1);
    furi_cry := helpers.load_texture("textures/copper.png", rduni["texture_image"].location, 10);

    //make instance buffer
    f: f32 = 100000

    for i in 0..<f {

        g := cast(f32)i

        s: [2]f32 = {
        
            5*glm.sin(2*g*PI/f),
            5*glm.cos(2*g*PI/f)

        }

        append(&positions, s)

    }
    

    instances := helpers.create_instance_array(0, positions[:])
    gl.BindBuffer(gl.ARRAY_BUFFER, instances.array)

    event: sdl.Event
    loopcounter: f32;

    items := 50000

    running: for {

        //sdl (入力する)
        if sdl.PollEvent(&event) {

            if event.type == sdl.EventType.QUIT {
                
                break running

            }

            if event.type == sdl.EventType.KEYDOWN {

                #partial switch event.key.keysym.scancode {

                    case sdl.Scancode.ESCAPE:
                        break running

                    case sdl.Scancode.LEFT:
                        x += 0.01
                    case sdl.Scancode.RIGHT:
                        x -= 0.01

                }

            }

            if event.type == sdl.EventType.WINDOWEVENT {

                #partial switch event.window.event {
                    
                    case sdl.WindowEventID.RESIZED:

                        sdl.GetWindowSize(win, &WIDTH, &HEIGHT);


                }

            }
            
        }



        //opengl (描く)

        //lighting

            camera: glm.vec3 = {10*glm.sin(x), 0, 10*glm.cos(x)}
            lookDirection: glm.vec3 = {0, 0, 0}



        //init
            gl.Viewport(0, 0, WIDTH, HEIGHT)
            gl.ClearColor(0, 0, 0, 1)
            gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

            //these are ur view and projection matrices, really just black box functions rn
            view: glm.mat4 = helpers.dim2_camera({0, 0, 10})
            
            projection: glm.mat4 = glm.mat4Perspective(glm.radians(cast(f32)60.0), cast(f32)WIDTH/cast(f32)HEIGHT, 0.1, 100.0)              
            

        //primary rendering
        helpers.bind_vertex_bloc(sphere_object)
        gl.UseProgram(rdprog)

        gl.UniformMatrix4fv(rduni["view"].location, 1, false, &view[0,0])
        gl.UniformMatrix4fv(rduni["projection"].location, 1, false, &projection[0,0])
        gl.Uniform3f(rduni["camerapos"].location, camera[0], camera[1], camera[2])

        helpers.bind_texture(gl.TEXTURE_2D, rduni, "texture_image", furi_cry)
        gl.Uniform1i(rduni["texture_image"].location, 10)

        model: glm.mat4 = glm.mat4(1.0)
        model *= glm.mat4Rotate({glm.sin(0.01*loopcounter), glm.cos(0.01*loopcounter), glm.sin(0.02*loopcounter)}, 0.01*loopcounter)
    
        helpers.set_model_matrix_uni(rduni, &model, "model", "normalmodel")

        // gl.DrawArrays(gl.TRIANGLES, 0, sphere_object.count) 
        gl.DrawArraysInstanced(gl.TRIANGLES, 0, sphere_object.count, instances.count)




        loopcounter += 1;
        sdl.GL_SwapWindow(win)
    }

    



}



