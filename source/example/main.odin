package main

import "core:fmt"
import "../tor_sdl2"

app                                                            : tor_sdl2.tor_sdl2_app
renderer                                                       : tor_sdl2.tor_sdl2_renderer
texture_destination                                            : tor_sdl2.tor_sdl2_rect
texture                                                        : rawptr
font                                                           : rawptr

/*------------------------------------------------------------------------------
Game
------------------------------------------------------------------------------*/

main :: proc()
{
    // Create app
    tor_sdl2.app_bind(&app)
    tor_sdl2.app_init()
    tor_sdl2.app_bind_events(start,end,update,render_start,render_end,resized)
    tor_sdl2.app_run()
}

start :: proc()
{    
    // Create renderer
    tor_sdl2.renderer_bind(&renderer)
    tor_sdl2.renderer_init(app.window)
    tor_sdl2.renderer_set_clear_color_rgba({0,0,0,0})

    // Load content
    tor_sdl2.content_bind_renderer(renderer.renderer)
    texture = tor_sdl2.content_load_texture("content/logo.png")
    texture_query_size := tor_sdl2.content_query_texture_size(texture)
    texture_destination = { 0, 0, texture_query_size.x, texture_query_size.y}
    font = tor_sdl2.content_load_font_tff("content/OpenSans_Regular.ttf",16)

    // Bind texture/font to renderer
    tor_sdl2.renderer_bind_texture(texture)
    tor_sdl2.renderer_bind_text_tff_font(font)

}

end :: proc()
{
    // Destroy renderer
    tor_sdl2.renderer_deinit(&renderer)

    // Destroy content
    tor_sdl2.content_destroy_texture(texture)
}

update :: proc()
{
    tor_sdl2.app_set_window_title(app.time_fps_as_string)
}

render_start :: proc()
{
    tor_sdl2.renderer_draw_texture(nil,&texture_destination)
    tor_sdl2.renderer_draw_text_tff("I like to eat tacos")
}

render_end :: proc()
{
    tor_sdl2.renderer_render(&renderer)
}

resized :: proc()
{
}