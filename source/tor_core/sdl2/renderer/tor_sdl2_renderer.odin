package tor_core_sdl2_renderer
import sdl2 "vendor:sdl2"
import sdl2_image "vendor:sdl2/image" 
import sdl2_tff "vendor:sdl2/ttf"
import "core:math/rand"
import "core:mem"

// State
STATE_NULL                                                :: 0b00000000
STATE_INIT                                                :: 0b00000001

// Type aliases
point                                                     :: sdl2.Point
rect                                                      :: sdl2.Rect
render_flip                                               :: sdl2.RendererFlip

// Bound
bound                                                     : ^renderer

// Viewport                                                
VIEWPORT_COUNT                                            :: 8

// Text
text_tff_static_key                                        :: struct 
{
    text                                                   : cstring,
    font                                                   : ^sdl2_tff.Font,
}

text_tff_static_value                                      :: struct 
{
    texture                                                :^sdl2.Texture,
    size                                                   : [2]i32
}

// Renderer cache
cache                                                      : map[u8] ^renderer

// Instance
renderer                                                   :: struct
{
    state                                                  : u8,    
    renderer                                               : ^sdl2.Renderer,
    clear_color                                            : [4]u8,
    draw_color                                             : [4]u8,
    draw_color_sdl                                         :  sdl2.Color,
    bound_texture                                          : ^sdl2.Texture,
    bound_font                                             : ^sdl2_tff.Font,
    viewport_rects                                         : [VIEWPORT_COUNT] rect,
    texture_cache                                          : map[u8] ^sdl2.Texture,
    ttf_font_cache                                         : map[u8] ^sdl2_tff.Font,
    ttf_text_static_texture_cache                          : map[text_tff_static_key] text_tff_static_value
}

// Draw
draw_destination_rect                                      : sdl2.Rect
draw_source_rect                                           : sdl2.Rect


/*------------------------------------------------------------------------------
TOR : SDL2->Renderer (Color)
------------------------------------------------------------------------------*/

set_clear_color_rgba :: proc(color : [4]u8)
{
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")

    // Set clear color (sdl2 clear color is set when clears)
    bound.clear_color = color
}

set_clear_color_hex :: proc(hex : u32)
{
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")

    // Set clear color (sdl2 clear color is set when clears)
    bound.clear_color = {  u8((hex >> 16) & 0xFF),  u8((hex >> 8) & 0xFF), u8(hex & 0xFF), 255  }
}

set_draw_color_rgba :: proc(color : [4]u8)
{
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")

    // Set draw color
    bound.draw_color = color
    bound.draw_color_sdl = sdl2.Color{color.r, color.g, color.b, color.a}
    sdl2.SetRenderDrawColor(bound.renderer,color.r,color.g,color.b,color.a)
}

set_draw_color_hex :: proc(hex : u32, alpha : u8)
{
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")

    // Color
    color := [4]u8 {u8((hex >> 16) & 0xFF), u8((hex >> 8) & 0xFF), u8(hex & 0xFF), 255}

    // Set draw color
    bound.draw_color = color
    bound.draw_color_sdl = sdl2.Color{color.r, color.g, color.b, color.a}
    sdl2.SetRenderDrawColor(bound.renderer,color.r,color.g,color.b,color.a)
}

/*------------------------------------------------------------------------------
TOR : SDL2->Renderer (viewport)
------------------------------------------------------------------------------*/

set_viewport_current :: proc(viewport : u8)
{
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")

    // Bind viewport
    viewport_clamped := clamp(viewport,0,VIEWPORT_COUNT - 1)
    sdl2.RenderSetViewport(bound.renderer,&bound.viewport_rects[viewport_clamped])
}

set_viewport_rect :: proc(viewport : u8, rect : rect)
{
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")

    // Set viewport rect
    viewport_clamped := clamp(viewport,0,VIEWPORT_COUNT - 1)
    bound.viewport_rects[viewport_clamped] = rect
}

set_viewport_position :: proc(viewport : u8, position : [2]i32)
{
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")

    // Set viewport position
    viewport_clamped := clamp(viewport,0,VIEWPORT_COUNT - 1)
    bound.viewport_rects[viewport_clamped].x = position.x
    bound.viewport_rects[viewport_clamped].y = position.y
}

set_viewport_size :: proc(viewport : u8, size : [2]i32)
{
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")

    // Set viewport size
    viewport_clamped := clamp(viewport,0,VIEWPORT_COUNT - 1)
    bound.viewport_rects[viewport_clamped].w = size.x
    bound.viewport_rects[viewport_clamped].h = size.y
}

/*------------------------------------------------------------------------------
TOR : SDL2->Renderer (Pixel)
------------------------------------------------------------------------------*/



/*------------------------------------------------------------------------------
TOR : SDL2->Renderer (text tff : Load)
------------------------------------------------------------------------------*/

bind_texture :: proc(texture_id : u8)
{
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(bound.texture_cache[texture_id] != nil, "texture with id does not exist")

    // Bind texture
    bound.bound_texture = bound.texture_cache[texture_id]
}

create_texture :: proc(file_path : cstring, bind : bool) -> u8
{
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")
 
    // Load texture
    texture_id := u8(0)
    for i := 1; i < 255; i+=1
    {
        if (bound.texture_cache[u8(i)] == nil)
        {
            texture_id = u8(i)
            
            // Load texture
            texture := sdl2_image.LoadTexture(bound.renderer, file_path)
            assert(texture != nil, sdl2.GetErrorString())

            // Add to cache
            bound.texture_cache[texture_id] = texture

            // Bind
            if (bind)
            {
                bound.bound_texture = texture
            }
            
            // Return
            return texture_id
        }
    }
    
    // Return
    return 0
}

destroy_texture :: proc(texture_id : u8)
{
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")

    // Texture
    texture := bound.texture_cache[texture_id]
    
    // Remove from cache
    bound.texture_cache[texture_id] = nil
    
    // Destroy texture
    sdl2.DestroyTexture(texture)
}

query_texture_size :: proc(texture_id : u8) -> [2]i32
{
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")

    // Texture
    texture := bound.texture_cache[texture_id]

    // Return size
    rect := sdl2.Rect {}
    sdl2.QueryTexture(texture,nil,nil,&rect.w,&rect.h)
    return { rect.w, rect.h }
}

/*------------------------------------------------------------------------------
TOR : SDL2->Renderer (Texture : Draw SDL)
------------------------------------------------------------------------------*/

draw_texture_sdl2 :: proc(destination_rect : ^rect)
{
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(bound.bound_texture != nil, "Renderer (SDL) : Texture not bound")
 
    // Render
    sdl2.RenderCopy(bound.renderer,bound.bound_texture,nil,destination_rect)
}

draw_texture_sdl2_ex :: proc(destination_rect : ^rect, angle: f64, point : ^point, render_flip : render_flip)
{   
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(bound.bound_texture != nil, "Renderer (SDL) : Texture not bound")
 
    // Render
    sdl2.RenderCopyEx(bound.renderer,bound.bound_texture,nil,destination_rect,angle,point,render_flip)
}

draw_texture_atlas_sdl2 :: proc(source_rect : ^rect, destination_rect : ^rect)
{   
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(bound.bound_texture != nil, "Renderer (SDL) : Texture not bound")
 
    // Render
    sdl2.RenderCopy(bound.renderer,bound.bound_texture,source_rect,destination_rect)
}

draw_texture_atlas_sdl2_ex :: proc(source_rect : ^rect, destination_rect : ^rect, angle: f64, point : ^point, render_flip : render_flip)
{   
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(bound.bound_texture != nil, "Renderer (SDL) : Texture not bound")
 
    // Render
    sdl2.RenderCopyEx(bound.renderer,bound.bound_texture,source_rect,destination_rect,angle,point,render_flip)
}

/*------------------------------------------------------------------------------
TOR : SDL2->Renderer (Texture : Draw)
------------------------------------------------------------------------------*/

draw_texture_i32 :: proc(destination_rect : [4]i32)
{   
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(bound.bound_texture != nil, "Renderer (SDL) : Texture not bound")
 
    // Render
    draw_destination_rect = sdl2.Rect {destination_rect.x,destination_rect.y,destination_rect.z,destination_rect.w}
    sdl2.RenderCopy(bound.renderer,bound.bound_texture,nil,&draw_destination_rect)
}

draw_texture_f32 :: proc(destination_rect : [4]f32)
{   
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(bound.bound_texture != nil, "Renderer (SDL) : Texture not bound")
 
    // Render
    draw_destination_rect = sdl2.Rect {(i32)(destination_rect.x),(i32)(destination_rect.y),(i32)(destination_rect.z),(i32)(destination_rect.w)}
    sdl2.RenderCopy(bound.renderer,bound.bound_texture,nil,&draw_destination_rect)
}

draw_texture_f64 :: proc(destination_rect : [4]f64)
{   
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(bound.bound_texture != nil, "Renderer (SDL) : Texture not bound")
 
    // Render
    draw_destination_rect = sdl2.Rect {(i32)(destination_rect.x),(i32)(destination_rect.y),(i32)(destination_rect.z),(i32)(destination_rect.w)}
    sdl2.RenderCopy(bound.renderer,bound.bound_texture,nil,&draw_destination_rect)
}

draw_texture_atlas_i32 :: proc(source_rect : [4]i32, destination_rect : [4]i32)
{   
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(bound.bound_texture != nil, "Renderer (SDL) : Texture not bound")
 
    // Render
    draw_destination_rect = sdl2.Rect {destination_rect.x,destination_rect.y,destination_rect.z,destination_rect.w}
    draw_source_rect = sdl2.Rect {source_rect.x,source_rect.y,source_rect.z,source_rect.w}
    sdl2.RenderCopy(bound.renderer,bound.bound_texture,&draw_source_rect,&draw_destination_rect)
}

draw_texture_atlas_f32 :: proc(source_rect : [4]f32, destination_rect : [4]f32)
{   
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(bound.bound_texture != nil, "Renderer (SDL) : Texture not bound")
 
    // Render
    draw_destination_rect = sdl2.Rect {(i32)(destination_rect.x),(i32)(destination_rect.y),(i32)(destination_rect.z),(i32)(destination_rect.w)}
    draw_source_rect = sdl2.Rect {(i32)(source_rect.x),(i32)(source_rect.y),(i32)(source_rect.z),(i32)(source_rect.w)}
    sdl2.RenderCopy(bound.renderer,bound.bound_texture,&draw_source_rect,&draw_destination_rect)
}

draw_texture_atlas_f64 :: proc(source_rect : [4]f64, destination_rect : [4]f64)
{   
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(bound.bound_texture != nil, "Renderer (SDL) : Texture not bound")
 
    // Render
    draw_destination_rect = sdl2.Rect {(i32)(destination_rect.x),(i32)(destination_rect.y),(i32)(destination_rect.z),(i32)(destination_rect.w)}
    draw_source_rect = sdl2.Rect {(i32)(source_rect.x),(i32)(source_rect.y),(i32)(source_rect.z),(i32)(source_rect.w)}
    sdl2.RenderCopy(bound.renderer,bound.bound_texture,&draw_source_rect,&draw_destination_rect)
}

/*------------------------------------------------------------------------------
TOR : SDL2->Renderer (Font tff)
------------------------------------------------------------------------------*/

bind_text_tff_font :: proc(font_id : u8)
{
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(bound.ttf_font_cache[font_id] != nil, "font with id does not exist")

    // Font
    bound.bound_font = bound.ttf_font_cache[font_id]
}

create_tff_font :: proc(file_path : cstring, font_size : i32, bind : bool) -> u8
{
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")
    
    // Load font
    font_id := u8(0)
    for i := 1; i < 255; i+=1
    {
        if (bound.ttf_font_cache[u8(i)] == nil)
        {
            font_id = u8(rand.float32_range(1,255))
            
             // Load font
            font := sdl2_tff.OpenFont(file_path,font_size)
            assert(font != nil, sdl2.GetErrorString())

            // Add to cache
            bound.ttf_font_cache[font_id] = font

            // Bind
            if (bind)
            {
                bound.bound_font = font
            }
            
            // Return
            return font_id
        }
    }
        
    // Return
    return 0
}

destroy_tff_font :: proc(font_id : u8)
{
    // Font
    font := bound.ttf_font_cache[font_id]

    // Remove from cache
    bound.ttf_font_cache[font_id] = nil

    // Destroy font
    sdl2_tff.CloseFont((^sdl2_tff.Font)(font))
}

/*------------------------------------------------------------------------------
TOR : SDL2->Renderer (text tff : Draw)
------------------------------------------------------------------------------*/

draw_text_tff_static :: proc(text : cstring, position : [2]i32)
{
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(sdl2_tff.WasInit() != 0, "Renderer (SDL) : Tff not initalized")
    assert(bound.bound_font != nil, "Renderer (SDL) : Font not bound")

    // Key 
    key := text_tff_static_key { text, bound.bound_font }

    // Texture
    cache := bound.ttf_text_static_texture_cache[key]
    if (cache.texture == nil)
    {
        // Surface
        surface := sdl2_tff.RenderText_Solid(bound.bound_font,text, bound.draw_color_sdl)
        texture := sdl2.CreateTextureFromSurface(bound.renderer,surface)

        // cache
        bound.ttf_text_static_texture_cache[key] = { texture, {surface.w,surface.h} }

        // Free Surface And Texture
        sdl2.FreeSurface(surface)
    }
  
    // Render
    dest_rect := sdl2.Rect{ position.x, position.y, cache.size.x, cache.size.y }
    sdl2.RenderCopy(bound.renderer, cache.texture,nil,&dest_rect)
}

draw_text_tff_dynamic :: proc(text : cstring, position : [2]i32)
{
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(sdl2_tff.WasInit() != 0, "Renderer (SDL) : Tff not initalized")
    assert(bound.bound_font != nil, "Renderer (SDL) : Font not bound")

    // Texture
    surface := sdl2_tff.RenderText_Solid(bound.bound_font,text, bound.draw_color_sdl)
    texture := sdl2.CreateTextureFromSurface(bound.renderer,surface)

    // Render
    dest_rect := sdl2.Rect{ position.x, position.y, surface.w, surface.h}
    sdl2.RenderCopy(bound.renderer, texture,nil,&dest_rect)
  
    // Free Surface And Texture
    sdl2.FreeSurface(surface)
    sdl2.DestroyTexture(texture)
}

/*------------------------------------------------------------------------------
TOR : SDL2->Renderer (Main)
------------------------------------------------------------------------------*/

set_to_defaults :: proc()
{
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")

    // Renderer
    set_clear_color_rgba({100,149,237,255})
    set_draw_color_rgba({255,255,255,255})

    // SDL
    sdl2.RenderSetScale(bound.renderer,1,1)
    sdl2.SetRenderDrawBlendMode(bound.renderer,sdl2.BlendMode.BLEND)
}

bind :: proc(id : u8)
{
    // Bind renderer
    bound = cache[id]
}

free :: proc(id : u8)
{
    // delete 
}

get_rawptr :: proc(id : u8) -> rawptr
{
    return cache[id]
}

create :: proc(sdl2_window : rawptr, bind : bool) -> u8
{
    // Validate
    assert(sdl2_window != nil, "Renderer (SDL) : SDL Window is undefined")
     
    // Enable batching
    sdl2.SetHint(sdl2.HINT_RENDER_BATCHING,"1")

    // Create renderer
    id := u8(0)
    for i := 1; i < 255; i+=1
    {
        if (cache[u8(i)] == nil)
        {
            // ID
            id = u8(i)
            
            // Create renderer
            cache[id] = new (renderer)
            cache[id].renderer = sdl2.CreateRenderer((^sdl2.Window)(sdl2_window),-1,sdl2.RENDERER_ACCELERATED)
                        
            // Bind
            if (bind)
            {
                bound = cache[id]
            }

            // Return
            return id
        }
    }

    return 0
}

deinit :: proc()
{
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")

    // Cleanup Renderer
    sdl2.DestroyRenderer(bound.renderer)
}

render_present :: proc ()
{
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")
    
    // Render Present
    sdl2.SetRenderDrawColor(bound.renderer,bound.draw_color.r,bound.draw_color.g,bound.draw_color.b,bound.draw_color.a)
    sdl2.RenderPresent(bound.renderer)
}

render_clear :: proc ()
{
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")
    
    // Clear
    sdl2.SetRenderDrawColor(bound.renderer,bound.clear_color.r,bound.clear_color.b,bound.clear_color.b,bound.clear_color.a)
    sdl2.RenderClear(bound.renderer)
}