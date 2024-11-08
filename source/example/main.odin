package main

import "core:fmt"
import "core:math/rand"
import "../tor_sdl2"

ENTITY_COUNT                                                   :: 50000

app                                                            : tor_sdl2.tor_sdl2_app
renderer                                                       : tor_sdl2.tor_sdl2_renderer
texture_destinations                                           : [ENTITY_COUNT]tor_sdl2.tor_sdl2_rect
entity_destinations                                            : [ENTITY_COUNT * 4]i32
texture                                                        : u16
font                                                           : u16

/*------------------------------------------------------------------------------
Game
------------------------------------------------------------------------------*/

main :: proc()
{
    // Create app
    tor_sdl2.app_bind(&app)
    tor_sdl2.app_init()
    tor_sdl2.app_set_window_resizable(true)
    tor_sdl2.app_bind_events(start,end,update,render,resized)
    tor_sdl2.app_set_time_fps_target(99999);
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
        texture_destinations[i] = { (i32)(rand.float32_range(50,1204)), (i32)(rand.float32_range(50,660)), texture_query_size.x, texture_query_size.y}
        entity_destinations[i * 4] = rand_x
        entity_destinations[i * 4 + 1] = rand_y
        entity_destinations[i * 4 + 2] = texture_query_size.x
        entity_destinations[i * 4 + 3] = texture_query_size.y
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

update :: proc()
{
    tor_sdl2.app_set_window_title(app.time_fps_as_string)

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
        tor_sdl2.renderer_draw_texture_atlas( {0,0,20,20}, {entity_destinations[i * 4],entity_destinations[i * 4 + 1],entity_destinations[i * 4 + 2],entity_destinations[i * 4 + 3]})
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