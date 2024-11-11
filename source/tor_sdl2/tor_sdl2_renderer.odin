package tor_sdl2
import sdl2 "vendor:sdl2"
import sdl2_image "vendor:sdl2/image" 
import sdl2_tff "vendor:sdl2/ttf"
import "core:math/rand"
import "core:mem"

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

// Renderer cache
tor_sdl2_renderer_renderer_cache                           : map[u8] ^tor_sdl2_renderer

// Instance
tor_sdl2_renderer                                          :: struct
{
    state                                                  : u8,    
    renderer                                               : ^sdl2.Renderer,
    clear_color                                            : [4]u8,
    draw_color                                             : [4]u8,
    draw_color_sdl                                         :  sdl2.Color,
    bound_texture                                          : ^sdl2.Texture,
    bound_font                                             : ^sdl2_tff.Font,
    viewport_rects                                         : [TOR_SDL2_RENDERER_VIEWPORT_COUNT] tor_sdl2_rect,
    texture_cache                                          : map[u8] ^sdl2.Texture,
    ttf_font_cache                                         : map[u8] ^sdl2_tff.Font,
    ttf_text_static_texture_cache                          : map[tor_sdl2_renderer_text_tff_static_key] tor_sdl2_renderer_text_tff_static_value
}

// Draw
tor_sdl2_renderer_draw_destination_rect                    : sdl2.Rect
tor_sdl2_renderer_draw_source_rect                         : sdl2.Rect


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

renderer_bind_texture :: proc(texture_id : u8)
{
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(tor_sdl2_renderer_bound.texture_cache[texture_id] != nil, "texture with id does not exist")

    // Bind texture
    tor_sdl2_renderer_bound.bound_texture = tor_sdl2_renderer_bound.texture_cache[texture_id]
}

renderer_create_texture :: proc(file_path : cstring, bind : bool) -> u8
{
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")
 
    // Load texture
    texture_id := u8(0)
    for i := 1; i < 255; i+=1
    {
        if (tor_sdl2_renderer_bound.texture_cache[u8(i)] == nil)
        {
            texture_id = u8(i)
            
            // Load texture
            texture := sdl2_image.LoadTexture(tor_sdl2_renderer_bound.renderer, file_path)
            assert(texture != nil, sdl2.GetErrorString())

            // Add to cache
            tor_sdl2_renderer_bound.texture_cache[texture_id] = texture

            // Bind
            if (bind)
            {
                tor_sdl2_renderer_bound.bound_texture = texture
            }
            
            // Return
            return texture_id
        }
    }
    
    // Return
    return 0
}

renderer_destroy_texture :: proc(texture_id : u8)
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

renderer_query_texture_size :: proc(texture_id : u8) -> [2]i32
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
TOR : SDL2->Renderer (Texture : Draw SDL)
------------------------------------------------------------------------------*/

renderer_draw_texture_sdl2 :: proc(destination_rect : ^tor_sdl2_rect)
{
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(tor_sdl2_renderer_bound.bound_texture != nil, "Renderer (SDL) : Texture not bound")
 
    // Render
    sdl2.RenderCopy(tor_sdl2_renderer_bound.renderer,tor_sdl2_renderer_bound.bound_texture,nil,destination_rect)
}

renderer_draw_texture_sdl2_ex :: proc(destination_rect : ^tor_sdl2_rect, angle: f64, point : ^tor_sdl2_point, render_flip : tor_sdl2_render_flip)
{   
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(tor_sdl2_renderer_bound.bound_texture != nil, "Renderer (SDL) : Texture not bound")
 
    // Render
    sdl2.RenderCopyEx(tor_sdl2_renderer_bound.renderer,tor_sdl2_renderer_bound.bound_texture,nil,destination_rect,angle,point,render_flip)
}

renderer_draw_texture_atlas_sdl2 :: proc(source_rect : ^tor_sdl2_rect, destination_rect : ^tor_sdl2_rect)
{   
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(tor_sdl2_renderer_bound.bound_texture != nil, "Renderer (SDL) : Texture not bound")
 
    // Render
    sdl2.RenderCopy(tor_sdl2_renderer_bound.renderer,tor_sdl2_renderer_bound.bound_texture,source_rect,destination_rect)
}

renderer_draw_texture_atlas_sdl2_ex :: proc(source_rect : ^tor_sdl2_rect, destination_rect : ^tor_sdl2_rect, angle: f64, point : ^tor_sdl2_point, render_flip : tor_sdl2_render_flip)
{   
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(tor_sdl2_renderer_bound.bound_texture != nil, "Renderer (SDL) : Texture not bound")
 
    // Render
    sdl2.RenderCopyEx(tor_sdl2_renderer_bound.renderer,tor_sdl2_renderer_bound.bound_texture,source_rect,destination_rect,angle,point,render_flip)
}

/*------------------------------------------------------------------------------
TOR : SDL2->Renderer (Texture : Draw)
------------------------------------------------------------------------------*/

renderer_draw_texture :: proc(destination_rect : [4]i32)
{   
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(tor_sdl2_renderer_bound.bound_texture != nil, "Renderer (SDL) : Texture not bound")
 
    // Render
    tor_sdl2_renderer_draw_destination_rect = sdl2.Rect {destination_rect.x,destination_rect.y,destination_rect.z,destination_rect.w}
    sdl2.RenderCopy(tor_sdl2_renderer_bound.renderer,tor_sdl2_renderer_bound.bound_texture,nil,&tor_sdl2_renderer_draw_destination_rect)
}

renderer_draw_texture_atlas :: proc(source_rect : [4]i32, destination_rect : [4]i32)
{   
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(tor_sdl2_renderer_bound.bound_texture != nil, "Renderer (SDL) : Texture not bound")
 
    // Render
    tor_sdl2_renderer_draw_destination_rect = sdl2.Rect {destination_rect.x,destination_rect.y,destination_rect.z,destination_rect.w}
    tor_sdl2_renderer_draw_source_rect = sdl2.Rect {source_rect.x,source_rect.y,source_rect.z,source_rect.w}
    sdl2.RenderCopy(tor_sdl2_renderer_bound.renderer,tor_sdl2_renderer_bound.bound_texture,&tor_sdl2_renderer_draw_source_rect,&tor_sdl2_renderer_draw_destination_rect)
}

renderer_draw_texture_atlas_f64 :: proc(source_rect : [4]f64, destination_rect : [4]f64)
{   
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(tor_sdl2_renderer_bound.bound_texture != nil, "Renderer (SDL) : Texture not bound")
 
    // Render
    tor_sdl2_renderer_draw_destination_rect = sdl2.Rect {(i32)(destination_rect.x),(i32)(destination_rect.y),(i32)(destination_rect.z),(i32)(destination_rect.w)}
    tor_sdl2_renderer_draw_source_rect = sdl2.Rect {(i32)(source_rect.x),(i32)(source_rect.y),(i32)(source_rect.z),(i32)(source_rect.w)}
    sdl2.RenderCopy(tor_sdl2_renderer_bound.renderer,tor_sdl2_renderer_bound.bound_texture,&tor_sdl2_renderer_draw_source_rect,&tor_sdl2_renderer_draw_destination_rect)
}

/*------------------------------------------------------------------------------
TOR : SDL2->Content (Font tff)
------------------------------------------------------------------------------*/

renderer_bind_text_tff_font :: proc(font_id : u8)
{
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(tor_sdl2_renderer_bound.ttf_font_cache[font_id] != nil, "font with id does not exist")

    // Font
    tor_sdl2_renderer_bound.bound_font = tor_sdl2_renderer_bound.ttf_font_cache[font_id]
}

renderer_create_tff_font :: proc(file_path : cstring, font_size : i32, bind : bool) -> u8
{
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")
    
    // Load font
    font_id := u8(0)
    for i := 1; i < 255; i+=1
    {
        if (tor_sdl2_renderer_bound.ttf_font_cache[u8(i)] == nil)
        {
            font_id = u8(rand.float32_range(1,255))
            
             // Load font
            font := sdl2_tff.OpenFont(file_path,font_size)
            assert(font != nil, sdl2.GetErrorString())

            // Add to cache
            tor_sdl2_renderer_bound.ttf_font_cache[font_id] = font

            // Bind
            if (bind)
            {
                tor_sdl2_renderer_bound.bound_font = font
            }
            
            // Return
            return font_id
        }
    }
        
    // Return
    return 0
}

renderer_destroy_tff_font :: proc(font_id : u8)
{
    // Font
    font := tor_sdl2_renderer_bound.ttf_font_cache[font_id]

    // Remove from cache
    tor_sdl2_renderer_bound.ttf_font_cache[font_id] = nil

    // Destroy font
    sdl2_tff.CloseFont((^sdl2_tff.Font)(font))
}

/*------------------------------------------------------------------------------
TOR : SDL2->Renderer (text tff : Draw)
------------------------------------------------------------------------------*/

renderer_draw_text_tff_static :: proc(text : cstring, position : [2]i32)
{
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(sdl2_tff.WasInit() != 0, "Renderer (SDL) : Tff not initalized")
    assert(tor_sdl2_renderer_bound.bound_font != nil, "Renderer (SDL) : Font not bound")

    // Key 
    key := tor_sdl2_renderer_text_tff_static_key { text, tor_sdl2_renderer_bound.bound_font }

    // Texture
    cache := tor_sdl2_renderer_bound.ttf_text_static_texture_cache[key]
    if (cache.texture == nil)
    {
        // Surface
        surface := sdl2_tff.RenderText_Solid(tor_sdl2_renderer_bound.bound_font,text, tor_sdl2_renderer_bound.draw_color_sdl)
        texture := sdl2.CreateTextureFromSurface(tor_sdl2_renderer_bound.renderer,surface)

        // cache
        tor_sdl2_renderer_bound.ttf_text_static_texture_cache[key] = { texture, {surface.w,surface.h} }

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

renderer_bind :: proc(renderer_id : u8)
{
    // Bind renderer
    tor_sdl2_renderer_bound = tor_sdl2_renderer_renderer_cache[renderer_id]
}

renderer_free :: proc(renderer_id : u8)
{
    // delete 
}

renderer_get_rawptr :: proc(renderer_id : u8) -> rawptr
{
    return tor_sdl2_renderer_renderer_cache[renderer_id]
}

renderer_create :: proc(sdl2_window : rawptr, bind : bool) -> u8
{
    // Validate
    assert(sdl2_window != nil, "Renderer (SDL) : SDL Window is undefined")
     
    // Enable batching
    sdl2.SetHint(sdl2.HINT_RENDER_BATCHING,"1")

    // Create renderer
    renderer_id := u8(0)
    for i := 1; i < 255; i+=1
    {
        if (tor_sdl2_renderer_renderer_cache[u8(i)] == nil)
        {
            // ID
            renderer_id = u8(i)
            
            // Create renderer
            tor_sdl2_renderer_renderer_cache[renderer_id] = new (tor_sdl2_renderer)
            tor_sdl2_renderer_renderer_cache[renderer_id].renderer = sdl2.CreateRenderer((^sdl2.Window)(sdl2_window),-1,sdl2.RENDERER_ACCELERATED)
                        
            // Bind
            if (bind)
            {
                tor_sdl2_renderer_bound = tor_sdl2_renderer_renderer_cache[renderer_id]
            }

            // Return
            return renderer_id
        }
    }

    return 0
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