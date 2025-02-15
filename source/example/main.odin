package main

import "core:fmt"
import "core:math/rand"
import "../tor_core/sdl2/app"
import "../tor_core/sdl2/window"
import "../tor_core/sdl2/input"
import "../tor_core/sdl2/renderer2d"

_window                                                        : u8
_renderer                                                      : u8
_sprite                                                        : u8
_font                                                          : u8

ENTITY_COUNT                                                   :: 100000
_entity_source_rects                                           : [ENTITY_COUNT]renderer2d.SourceRect
_entity_destination_rects                                      : [ENTITY_COUNT]renderer2d.DestinationRect

_render_interval_target                                        := 2
_render_interval_time                                          := 0

/*------------------------------------------------------------------------------
Game
------------------------------------------------------------------------------*/

main :: proc()
{
    // Create app
    app.init()
    app.bind_Events(start,end,run,run_fixed,resized)
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
        _entity_source_rects[i].w = 20
        _entity_source_rects[i].h = 20
        _entity_destination_rects[i].x = rand.float32_range(50,1204)
        _entity_destination_rects[i].y = rand.float32_range(50,720)
        _entity_destination_rects[i].w = rand.float32_range(32,32)
        _entity_destination_rects[i].h = rand.float32_range(32,32)
    }
}

end :: proc()
{
}

run_fixed :: proc()
{
    
}

run :: proc()
{
    // Control how often we render
    //_render_interval_time += 1
    //if (_render_interval_time < _render_interval_target) { return }
    //_render_interval_time = 0

    // Debug fps
    window.set_title(app.time.fps_as_cstring)

    delta_time := f32(app.time.delta_time)
    speed := 3 * delta_time // Calculate once to save alot of fps

    // Update entities
    source_rect := renderer2d.SourceRect {0,0,32,32}
    for i:= 0; i < ENTITY_COUNT ; i+=1
    {
        // Move
        _entity_destination_rects[i].x += speed
        _entity_destination_rects[i].y += speed

        // Draw
        renderer2d.draw_sprite_atlas_rect(&source_rect,&_entity_destination_rects[i])
    }
      
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