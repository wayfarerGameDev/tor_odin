package main

import "core:fmt"
import "core:math/rand"
import "../tor_core/sdl2/app"
import "../tor_core/sdl2/window"
import "../tor_core/sdl2/input"
import "../tor_core/sdl2/renderer"

ENTITY_COUNT                                                   :: 50000
ENTITY_DATA_CHUNCK                                             :: 4

_window                                                         : u8
_renderer                                                       : u8
_texture                                                        : u8
_font                                                           : u8
_entity_data                                                    : [ENTITY_COUNT * ENTITY_DATA_CHUNCK]f64

/*------------------------------------------------------------------------------
Game
------------------------------------------------------------------------------*/

main :: proc()
{
    // Create app
    app.init()
    app.bind_events(start,end,update_fixed,update,render,resized)
    app.run()
}

start :: proc()
{   
    // Create window
    _window = window.create("Tor (SDL)",{1280, 720},true)
    window.set_resizable(true) 

    // Create renderer
    _renderer = renderer.create(window.get_rawptr(_window),true)
    renderer.set_clear_color_rgba({0,0,0,0})

    // Load texture
    _texture = renderer.create_texture("content/chicken.png",true)

    // Load font
    _font = renderer.create_tff_font("content/OpenSans_Regular.ttf",16,true)

    // Entities
    for i:= 0; i < ENTITY_COUNT * ENTITY_DATA_CHUNCK; i+= ENTITY_DATA_CHUNCK
    {
        _entity_data[i] = (f64)(rand.float32_range(50,1204))
        _entity_data[i + 1] = (f64)(rand.float32_range(50,720))
        _entity_data[i + 2] = 32
        _entity_data[i + 3] = 32
    }
}

end :: proc()
{
    // Destroy renderer
    renderer.deinit()

    // Destroy content
    renderer.destroy_texture(_texture)
}

update_fixed :: proc(delta_time_fixed : f64)
{ 
}

update :: proc(delta_time : f64)
{
    input.update();

    if (input.get_key_state(input.INPUT_KEY_W,1))
    {
        // Entities
        for i:= 0; i < ENTITY_COUNT * ENTITY_DATA_CHUNCK; i+= ENTITY_DATA_CHUNCK
        {
            _entity_data[i] += 1 * delta_time
        }
    }
}

render :: proc()
{
    // World space
    renderer.set_viewport_current(0)
    renderer.set_viewport_position(0,{0,0})
   
    // Entities
    for i:= 0; i < ENTITY_COUNT * ENTITY_DATA_CHUNCK; i+= ENTITY_DATA_CHUNCK
    {
        renderer.draw_texture_atlas_f64( {0,0,20,20}, {_entity_data[i],_entity_data[i + 1],_entity_data[i + 2],_entity_data[i + 3]})
    }

    // Screenspace
    renderer.set_viewport_current(1)
    
    // UI
    renderer.bind_text_tff_font(_font)
    renderer.draw_text_tff_static("I like to eat tacos", {0, 0})
    
    // Final
    renderer.render_present()
    renderer.render_clear()
}

resized :: proc()
{
    // Apply wnidow resize to render viewports
    size := window.get_size()
    renderer.set_viewport_size(0,size)
    renderer.set_viewport_size(1,size)
}