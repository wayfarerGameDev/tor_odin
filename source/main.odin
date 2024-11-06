package main

import "core:fmt"
import "tor_sdl2"

app                                                            : tor_sdl2.tor_sdl2_app
renderer                                                       : tor_sdl2.tor_sdl2_renderer
image                                                          : rawptr

/*------------------------------------------------------------------------------
Game
------------------------------------------------------------------------------*/

main :: proc()
{
    // Create app
    tor_sdl2.app_init(&app)
    tor_sdl2.app_bind_events(&app,start,end,update,render_start,render_end,resized)    
    tor_sdl2.app_run(&app)
}

start :: proc()
{
    // Create renderer
    tor_sdl2.renderer_init(&renderer,app.window)
    tor_sdl2.renderer_set_clear_color_rgba(&renderer,{0,0,0,0})

    // Load content
    tor_sdl2.content_init()
    image = tor_sdl2.content_load_texture(renderer.renderer,"content/logo.png")

}

end :: proc()
{
    // Destroy renderer
    tor_sdl2.renderer_deinit(&renderer)

    // Destroy content
    tor_sdl2.content_destroy_texture(image)
}

update :: proc()
{
    tor_sdl2.app_set_window_title(&app,app.time_fps_as_string)
}

render_start :: proc()
{
    tor_sdl2.renderer_render_texture_position(&renderer,image, {100,100})
}

render_end :: proc()
{
    tor_sdl2.renderer_render(&renderer)
}

resized :: proc()
{
}