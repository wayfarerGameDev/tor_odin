package tor_sdl2
import sdl2 "vendor:sdl2"
import sdl2_image "vendor:sdl2/image" 
import sdl2_tff "vendor:sdl2/ttf"
import "core:math/rand"

// State
TOR_SDL2_RENDERER_STATE_NULL                               :: 0b00000000
TOR_SDL2_RENDERER_STATE_INIT                               :: 0b00000001

// Type aliases
tor_sdl2_point                                             :: sdl2.Point
tor_sdl2_rect                                              :: sdl2.Rect
tor_sdl2_render_flip                                       :: sdl2.RendererFlip

// Bound
tor_sdl2_renderer_bound                                    : ^tor_sdl2_renderer

// Viewport                                                
TOR_SDL2_RENDERER_VIEWPORT_COUNT                           :: 8

// Text
tor_sdl2_renderer_text_tff_static_key                      :: struct 
{
    text                                                   : cstring,
    font                                                   : ^sdl2_tff.Font,
}

tor_sdl2_renderer_text_tff_static_value                    :: struct 
{
    texture                                                :^sdl2.Texture,
    size                                                   : [2]i32
}

/* Share texture caches between all renderers */
tor_sdl2_renderer_text_ttf_static_texture_cache            : map[tor_sdl2_renderer_text_tff_static_key] tor_sdl2_renderer_text_tff_static_value

// Instance
tor_sdl2_renderer                                          :: struct
{
    state                                                  : u8,    
    window                                                 : ^sdl2.Window,
    renderer                                               : ^sdl2.Renderer,
    clear_color                                            : [4]u8,
    draw_color                                             : [4]u8,
    draw_color_sdl                                         :  sdl2.Color,
    bound_texture                                          : ^sdl2.Texture,
    bound_font                                             : ^sdl2_tff.Font,
    viewport_rects                                         : [TOR_SDL2_RENDERER_VIEWPORT_COUNT] tor_sdl2_rect,
    texture_cache                                          : map[u32] ^sdl2.Texture
}

/*------------------------------------------------------------------------------
TOR : SDL2->Renderer (Color)
------------------------------------------------------------------------------*/

renderer_set_clear_color_rgba :: proc(color : [4]u8)
{
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")

    // Set clear color (sdl2 clear color is set when clears)
    tor_sdl2_renderer_bound.clear_color = color
}

renderer_set_clear_color_hex :: proc(hex : u32)
{
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")

    // Set clear color (sdl2 clear color is set when clears)
    tor_sdl2_renderer_bound.clear_color = {  u8((hex >> 16) & 0xFF),  u8((hex >> 8) & 0xFF), u8(hex & 0xFF), 255  }
}

renderer_set_draw_color_rgba :: proc(color : [4]u8)
{
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")

    // Set draw color
    tor_sdl2_renderer_bound.draw_color = color
    tor_sdl2_renderer_bound.draw_color_sdl = sdl2.Color{color.r, color.g, color.b, color.a}
    sdl2.SetRenderDrawColor(tor_sdl2_renderer_bound.renderer,color.r,color.g,color.b,color.a)
}

renderer_set_draw_color_hex :: proc(hex : u32, alpha : u8)
{
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")

    // Color
    color := [4]u8 {u8((hex >> 16) & 0xFF), u8((hex >> 8) & 0xFF), u8(hex & 0xFF), 255}

    // Set draw color
    tor_sdl2_renderer_bound.draw_color = color
    tor_sdl2_renderer_bound.draw_color_sdl = sdl2.Color{color.r, color.g, color.b, color.a}
    sdl2.SetRenderDrawColor(tor_sdl2_renderer_bound.renderer,color.r,color.g,color.b,color.a)
}

/*------------------------------------------------------------------------------
TOR : SDL2->Renderer (viewport)
------------------------------------------------------------------------------*/

renderer_set_viewport_current :: proc(viewport : u8)
{
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")

    // Bind viewport
    viewport_clamped := clamp(viewport,0,TOR_SDL2_RENDERER_VIEWPORT_COUNT - 1)
    sdl2.RenderSetViewport(tor_sdl2_renderer_bound.renderer,&tor_sdl2_renderer_bound.viewport_rects[viewport_clamped])
}

renderer_set_viewport_rect :: proc(viewport : u8, rect : tor_sdl2_rect)
{
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")

    // Set viewport rect
    viewport_clamped := clamp(viewport,0,TOR_SDL2_RENDERER_VIEWPORT_COUNT - 1)
    tor_sdl2_renderer_bound.viewport_rects[viewport_clamped] = rect
}

renderer_set_viewport_position :: proc(viewport : u8, position : [2]i32)
{
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")

    // Set viewport position
    viewport_clamped := clamp(viewport,0,TOR_SDL2_RENDERER_VIEWPORT_COUNT - 1)
    tor_sdl2_renderer_bound.viewport_rects[viewport_clamped].x = position.x
    tor_sdl2_renderer_bound.viewport_rects[viewport_clamped].y = position.y
}

renderer_set_viewport_size :: proc(viewport : u8, size : [2]i32)
{
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")

    // Set viewport size
    viewport_clamped := clamp(viewport,0,TOR_SDL2_RENDERER_VIEWPORT_COUNT - 1)
    tor_sdl2_renderer_bound.viewport_rects[viewport_clamped].w = size.x
    tor_sdl2_renderer_bound.viewport_rects[viewport_clamped].h = size.y
}

/*------------------------------------------------------------------------------
TOR : SDL2->Renderer (Pixel)
------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
TOR : SDL2->Renderer (text tff : Load)
------------------------------------------------------------------------------*/

renderer_bind_texture :: proc(texture_id : u32)
{
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(tor_sdl2_renderer_bound.texture_cache[texture_id] == nil, "does NOT EXIST")

    // Bind texture
    tor_sdl2_renderer_bound.bound_texture = tor_sdl2_renderer_bound.texture_cache[texture_id]
}

renderer_load_texture :: proc(file_path : cstring) -> u32
{
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")

    // Load texture
    texture := sdl2_image.LoadTexture(tor_sdl2_renderer_bound.renderer, file_path)
    assert(texture != nil, sdl2.GetErrorString())

    // Add to cache
    texture_id := (u32)(rand.float32_range(0,99999999))
    tor_sdl2_renderer_bound.texture_cache[texture_id] = texture
    
    // Return
    return texture_id
}

renderer_destroy_texture :: proc(texture_id : u32)
{
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")

    // Texture
    texture := tor_sdl2_renderer_bound.texture_cache[texture_id]
    
    // Remove from cache
    tor_sdl2_renderer_bound.texture_cache[texture_id] = nil
    
    // Destroy texture
    sdl2.DestroyTexture(texture)
}

renderer_query_texture_size :: proc(texture_id : u32) -> [2]i32
{
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")

    // Texture
    texture := tor_sdl2_renderer_bound.texture_cache[texture_id]

    // Return size
    rect := sdl2.Rect {}
    sdl2.QueryTexture(texture,nil,nil,&rect.w,&rect.h)
    return { rect.w, rect.h }
}

/*------------------------------------------------------------------------------
TOR : SDL2->Renderer (Texture)
------------------------------------------------------------------------------*/

renderer_draw_texture :: proc(source_rect : ^tor_sdl2_rect, destination_rect : ^tor_sdl2_rect)
{   
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(tor_sdl2_renderer_bound.bound_texture != nil, "Renderer (SDL) : Texture not bound")
 
    // Render
    sdl2.RenderCopy(tor_sdl2_renderer_bound.renderer,tor_sdl2_renderer_bound.bound_texture,source_rect,destination_rect)
}

renderer_draw_texture_ex :: proc(source_rect : ^tor_sdl2_rect, destination_rect : ^tor_sdl2_rect, angle: f64, point : ^tor_sdl2_point, render_flip : tor_sdl2_render_flip)
{   
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(tor_sdl2_renderer_bound.bound_texture != nil, "Renderer (SDL) : Texture not bound")
 
    // Render
    sdl2.RenderCopyEx(tor_sdl2_renderer_bound.renderer,tor_sdl2_renderer_bound.bound_texture,source_rect,destination_rect,angle,point,render_flip)
}

/*------------------------------------------------------------------------------
TOR : SDL2->Renderer (text tff : Draw)
------------------------------------------------------------------------------*/

renderer_bind_text_tff_font :: proc(font : rawptr)
{
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")
    
    // Bind font
    tor_sdl2_renderer_bound.bound_font = (^sdl2_tff.Font)(font)
}

renderer_draw_text_tff_static :: proc(text : cstring, position : [2]i32)
{
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(sdl2_tff.WasInit() != 0, "Renderer (SDL) : Tff not initalized")
    assert(tor_sdl2_renderer_bound.bound_font != nil, "Renderer (SDL) : Font not bound")

    // Key 
    key := tor_sdl2_renderer_text_tff_static_key { text, tor_sdl2_renderer_bound.bound_font }

    // Texture
    cache := tor_sdl2_renderer_text_ttf_static_texture_cache[key]
    if (cache.texture == nil)
    {
        // Surface
        surface := sdl2_tff.RenderText_Solid(tor_sdl2_renderer_bound.bound_font,text, tor_sdl2_renderer_bound.draw_color_sdl)
        texture := sdl2.CreateTextureFromSurface(tor_sdl2_renderer_bound.renderer,surface)

        // cache
        tor_sdl2_renderer_text_ttf_static_texture_cache[key] = { texture, {surface.w,surface.h} }

        // Free Surface And Texture
        sdl2.FreeSurface(surface)
    }
  
    // Render
    dest_rect := sdl2.Rect{ position.x, position.y, cache.size.x, cache.size.y }
    sdl2.RenderCopy(tor_sdl2_renderer_bound.renderer, cache.texture,nil,&dest_rect)
}

renderer_draw_text_tff_dynamic :: proc(text : cstring, position : [2]i32)
{
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(sdl2_tff.WasInit() != 0, "Renderer (SDL) : Tff not initalized")
    assert(tor_sdl2_renderer_bound.bound_font != nil, "Renderer (SDL) : Font not bound")

    // Texture
    surface := sdl2_tff.RenderText_Solid(tor_sdl2_renderer_bound.bound_font,text, tor_sdl2_renderer_bound.draw_color_sdl)
    texture := sdl2.CreateTextureFromSurface(tor_sdl2_renderer_bound.renderer,surface)

    // Render
    dest_rect := sdl2.Rect{ position.x, position.y, surface.w, surface.h}
    sdl2.RenderCopy(tor_sdl2_renderer_bound.renderer, texture,nil,&dest_rect)
  
    // Free Surface And Texture
    sdl2.FreeSurface(surface)
    sdl2.DestroyTexture(texture)
}

/*------------------------------------------------------------------------------
TOR : SDL2->Renderer (Main)
------------------------------------------------------------------------------*/

renderer_set_to_defaults :: proc()
{
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")

    // Renderer
    renderer_set_clear_color_rgba({100,149,237,255})
    renderer_set_draw_color_rgba({255,255,255,255})

    // SDL
    sdl2.RenderSetScale(tor_sdl2_renderer_bound.renderer,1,1)
    sdl2.SetRenderDrawBlendMode(tor_sdl2_renderer_bound.renderer,sdl2.BlendMode.BLEND)
}

renderer_bind :: proc(renderer : ^tor_sdl2_renderer)
{
    // Bind renderer
    tor_sdl2_renderer_bound = renderer
}

renderer_init :: proc(sdl2_window : rawptr)
{
     // Validate
     assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")
     assert(tor_sdl2_renderer_bound.state == TOR_SDL2_RENDERER_STATE_NULL, "Renderer (SDL) : Already initalized")
     assert(sdl2_window != nil, "Renderer (SDL) : SDL Window is undefined")
     
     // Bind window
     tor_sdl2_renderer_bound.window = (^sdl2.Window)(sdl2_window)

     // Create renderer
     tor_sdl2_renderer_bound.renderer = sdl2.CreateRenderer(tor_sdl2_renderer_bound.window,-1,sdl2.RENDERER_ACCELERATED)
     assert(tor_sdl2_renderer_bound.renderer != nil, sdl2.GetErrorString())

     // Enable batching
     sdl2.SetHint(sdl2.HINT_RENDER_BATCHING,"1")

     // Default
     renderer_set_to_defaults()
}

renderer_deinit :: proc()
{
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")

    // Cleanup Renderer
    sdl2.DestroyRenderer(tor_sdl2_renderer_bound.renderer)
}

renderer_render_present :: proc ()
{
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")
    
    // Render Present
    sdl2.SetRenderDrawColor(tor_sdl2_renderer_bound.renderer,tor_sdl2_renderer_bound.draw_color.r,tor_sdl2_renderer_bound.draw_color.g,tor_sdl2_renderer_bound.draw_color.b,tor_sdl2_renderer_bound.draw_color.a)
    sdl2.RenderPresent(tor_sdl2_renderer_bound.renderer)
}

renderer_render_clear :: proc ()
{
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")
    
    // Clear
    sdl2.SetRenderDrawColor(tor_sdl2_renderer_bound.renderer,tor_sdl2_renderer_bound.clear_color.r,tor_sdl2_renderer_bound.clear_color.b,tor_sdl2_renderer_bound.clear_color.b,tor_sdl2_renderer_bound.clear_color.a)
    sdl2.RenderClear(tor_sdl2_renderer_bound.renderer)
}