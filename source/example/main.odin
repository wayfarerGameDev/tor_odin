package main

import "core:fmt"
import "core:math/rand"
import "../tor_core/sdl2/app"
import "../tor_core/sdl2/window"
import "../tor_core/sdl2/input"
import "../tor_core/sdl2/renderer2d"

ENTITY_COUNT                                                   :: 100000
ENTITY_DATA_CHUNCK                                             :: 4

_window                                                        : u8
_renderer                                                      : u8
_sprite                                                        : u8
_font                                                          : u8
_entity_data                                                   : [ENTITY_COUNT * ENTITY_DATA_CHUNCK]f64

/*------------------------------------------------------------------------------
Game
------------------------------------------------------------------------------*/

main :: proc()
{
    // Create app
    app.init()
    app.bind_Events(start,end,update,render,resized)
    app.run()
}

start :: proc()
{   
    // Create window
    _window = window.create("Tor (SDL)",{1280, 720},true)
    window.set_resizable(true) 

    // Create renderer
    _renderer = renderer2d.create(window.get_rawptr(_window),true)
    renderer2d.set_clear_color_rgba({0,0,0,0})

    // Load sprite
    _sprite = renderer2d.create_sprite("content/chicken.png",true)

    // Load font
    _font = renderer2d.create_text_tff_font("content/OpenSans_Regular.ttf",16,true)

    // Entities
    for i:= 0; i < ENTITY_COUNT; i+= 1
    {
        _entity_data[i * ENTITY_DATA_CHUNCK] = (f64)(rand.float32_range(50,1204))
        _entity_data[i * ENTITY_DATA_CHUNCK + 1] = (f64)(rand.float32_range(50,720))
        _entity_data[i * ENTITY_DATA_CHUNCK + 2] = 32
        _entity_data[i * ENTITY_DATA_CHUNCK + 3] = 32
    }
}

end :: proc()
{
}

update :: proc()
{
    delta_time := app.time.delta_time
    
    input.update();
    window.set_title(app.time.fps_as_cstring)
    //if (input.get_key_state(input.Keycode.W,1))
    {
        // Entities
        for i:= 0; i < ENTITY_COUNT; i+=1
        {
            _entity_data[i * ENTITY_DATA_CHUNCK] += 1 * delta_time
            _entity_data[i * ENTITY_DATA_CHUNCK + 1] += 1 * delta_time
        }
    }
}

render :: proc()
{
    // World space
    renderer2d.set_viewport(0)
    renderer2d.set_viewport_position(0,{0,0})

    // Entities
    for i:= 0; i < ENTITY_COUNT ; i+=1
    {
       // renderer2d.draw_sprite_atlas_f64( {0,0,20,20}, {_entity_data[i * ENTITY_DATA_CHUNCK],_entity_data[i * ENTITY_DATA_CHUNCK + 1],_entity_data[i * ENTITY_DATA_CHUNCK + 2], _entity_data[i * ENTITY_DATA_CHUNCK + 3]})
    }

    // Screenspace
    renderer2d.set_viewport(1)

    // UI
    renderer2d.bind_text_tff_font(_font)
    renderer2d.draw_text_tff_static(app.time.fps_as_cstring, {0, 0})
      
    // Final
    renderer2d.render_present()
    renderer2d.render_clear()
}

resized :: proc()
{
    // Apply wnidow resize to render viewports
    size := window.get_size()
    renderer2d.set_viewport_size(0,size)
    renderer2d.set_viewport_position_size(1,{0,0},size)
}