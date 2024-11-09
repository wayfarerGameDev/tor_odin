package main

import "core:fmt"
import "core:math/rand"
import "../tor_sdl2"

ENTITY_COUNT                                                   :: 50000

app                                                            : tor_sdl2.tor_sdl2_app
renderer                                                       : tor_sdl2.tor_sdl2_renderer
entity_destinations                                            : [ENTITY_COUNT * 4]f64
texture                                                        : u8
font                                                           : u8

/*------------------------------------------------------------------------------
Game
------------------------------------------------------------------------------*/

main :: proc()
{
    // Create app
    tor_sdl2.app_bind(&app)
    tor_sdl2.app_init()
    tor_sdl2.app_set_window_resizable(true)
    tor_sdl2.app_bind_events(start,end,update_fixed,update,render,resized)
    tor_sdl2.app_run()
}

start :: proc()
{    
    // Create renderer
    tor_sdl2.renderer_bind(&renderer)
    tor_sdl2.renderer_init(app.window)
    tor_sdl2.renderer_set_clear_color_rgba({0,0,0,0})

    // Load texture
    texture = tor_sdl2.renderer_load_texture("content/chicken.png")
    texture_query_size := tor_sdl2.renderer_query_texture_size(texture)

    // Entities
    for i:= 0; i < ENTITY_COUNT - 1; i+=1
    {
        rand_x := (i32)(rand.float32_range(50,1204))
        rand_y := (i32)(rand.float32_range(50,1204))
        entity_destinations[i * 4] = (f64)(rand_x)
        entity_destinations[i * 4 + 1] = (f64)(rand_y)
        entity_destinations[i * 4 + 2] = (f64)(texture_query_size.x)
        entity_destinations[i * 4 + 3] = (f64)(texture_query_size.y)
    }

    font = tor_sdl2.renderer_load_tff_font("content/OpenSans_Regular.ttf",16)
}

end :: proc()
{
    // Destroy renderer
    tor_sdl2.renderer_deinit()

    // Destroy content
    tor_sdl2.renderer_destroy_texture(texture)
}

update_fixed :: proc(delta_time_fixed : f64)
{ 
    fmt.printfln("hit")

    // Entities
    for i:= 0; i < ENTITY_COUNT - 1; i+=1
    {
        entity_destinations[i * 4] = 0
    }
}

update :: proc(delta_time : f64)
{
    fmt.printfln(app.time_fps_as_string)
}

render :: proc()
{
    // World space
    tor_sdl2.renderer_set_viewport_current(0)
    tor_sdl2.renderer_set_viewport_position(0,{0,0})
   
    // Entities
    tor_sdl2.renderer_bind_texture(texture)
    for i:= 0; i < ENTITY_COUNT - 1; i+=1
    {
        // tor_sdl2.renderer_draw_texture_atlas_sdl2(nil,&texture_destinations[i])
        tor_sdl2.renderer_draw_texture_atlas_f64( {0,0,20,20}, {entity_destinations[i * 4],entity_destinations[i * 4 + 1],entity_destinations[i * 4 + 2],entity_destinations[i * 4 + 3]})
    }

    // Screenspace
    tor_sdl2.renderer_set_viewport_current(1)
    
    // UI
    tor_sdl2.renderer_bind_text_tff_font(font)
    tor_sdl2.renderer_draw_text_tff_static("I like to eat tacos", {0, 0})
    
    // Final
    tor_sdl2.renderer_render_present()
    tor_sdl2.renderer_render_clear()
}

resized :: proc()
{
    // apply wnidow resize to render viewports
    size := tor_sdl2.app_get_window_size()
    tor_sdl2.renderer_set_viewport_size(0,size)
    tor_sdl2.renderer_set_viewport_size(1,size)
}