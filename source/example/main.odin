package main

import "core:fmt"
import "../tor_sdl2"

app                                                            : tor_sdl2.tor_sdl2_app
renderer                                                       : tor_sdl2.tor_sdl2_renderer
texture_destination_a                                          : tor_sdl2.tor_sdl2_rect
texture_destination_b                                          : tor_sdl2.tor_sdl2_rect
texture                                                        : u32
font                                                           : rawptr

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
    texture_destination_a = { 0, 0, texture_query_size.x, texture_query_size.y}
    texture_destination_b = { 100, 0, texture_query_size.x, texture_query_size.y}


    font = tor_sdl2.content_load_font_tff("content/OpenSans_Regular.ttf",16)
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
    tor_sdl2.renderer_set_viewport_position(0,{100,500})
   
    // Entities
    tor_sdl2.renderer_bind_texture(texture)
    tor_sdl2.renderer_draw_texture(nil,&texture_destination_a)
    tor_sdl2.renderer_draw_texture(nil,&texture_destination_b)

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