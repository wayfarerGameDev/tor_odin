package tor_core_sdl2_renderer2d
import sdl2 "vendor:sdl2"
import sdl2_image "vendor:sdl2/image" 
import sdl2_tff "vendor:sdl2/ttf"
import "core:math/rand"
import "core:c"

// Types
SourceRect                                                :: sdl2.Rect
DestinationRect                                           :: sdl2.FRect

// Blendmode
BLENDMODE_NONE                                            :: 0x00000000
BLENDMODE_ALPHA                                           :: 0x00000001
BLENDMODE_ADD                                             :: 0x00000002
BLENDMODE_MODULATE                                        :: 0x00000004
BLENDMODE_MULTIPLY                                        :: 0x00000008
BLENDMODE_INVALID                                         :: 0x7FFFFFFF

// State
@(private)
STATE_NULL                                                :: 0b00000000
@(private)
STATE_INIT                                                :: 0b00000001

// Viewport
@(private)
VIEWPORT_COUNT                                            :: 8

// Text
@(private)
text_tff_static_key                                       :: struct 
{
    text                                                  : cstring,
    font                                                  : ^sdl2_tff.Font,
}

@(private)
text_tff_static_value                                     :: struct 
{
    texture                                               :^sdl2.Texture,
    size                                                  : [2]i32
}

// Bound | Cache
@(private)
bound                                                     : ^renderer2d
@(private)
cache                                                     : map[u8] ^renderer2d

// Instance
@(private)
renderer2d                                                :: struct
{
    state                                                 : u8,    
    renderer                                              : ^sdl2.Renderer,
    clear_color                                           : [4]u8,
    draw_color                                            : [4]u8,
    draw_color_sdl                                        :  sdl2.Color,
    viewport_rects                                        : [VIEWPORT_COUNT] sdl2.Rect,
    sprite_bound                                          : ^sdl2.Texture,
    sprite_cache                                          : map[u8] ^sdl2.Texture,
    ttf_font_bound                                        : ^sdl2_tff.Font,
    ttf_font_cache                                        : map[u8] ^sdl2_tff.Font,
    ttf_text_static_sprite_cache                          : map[text_tff_static_key] text_tff_static_value
}

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

set_viewport :: proc(viewport : u8)
{
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")

    // Bind viewport
    viewport_clamped := clamp(viewport,0,VIEWPORT_COUNT - 1)
    sdl2.RenderSetViewport(bound.renderer,&bound.viewport_rects[viewport_clamped])
}

set_viewport_position_size :: proc(viewport : u8, position : [2]i32, size : [2]i32)
{
     // Validate
     assert(bound != nil, "Renderer (SDL) : Renderer not bound")

     // Set viewport position | size
     viewport_clamped := clamp(viewport,0,VIEWPORT_COUNT - 1)
     bound.viewport_rects[viewport_clamped].x = position.x
     bound.viewport_rects[viewport_clamped].y = position.y
     bound.viewport_rects[viewport_clamped].w = size.x
     bound.viewport_rects[viewport_clamped].h = size.y
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
TOR : SDL2->Renderer (Sprite : Load)
------------------------------------------------------------------------------*/

bind_sprite :: proc(sprite_id : u8)
{
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(bound.sprite_cache[sprite_id] != nil, "texture with id does not exist")

    // Bind sprite
    bound.sprite_bound = bound.sprite_cache[sprite_id]

    // Apply blendmode
    blend_mode := sdl2.BlendMode.NONE
    sdl2.GetRenderDrawBlendMode(bound.renderer,&blend_mode)
    sdl2.SetTextureBlendMode(bound.sprite_bound,blend_mode)
}

create_sprite :: proc(file_path : cstring, bind : bool) -> u8
{
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")
 
    // Load texture
    sprite_id := u8(0)
    for i := 1; i < 255; i+=1
    {
        if (bound.sprite_cache[u8(i)] == nil)
        {
            sprite_id = u8(i)
            
            // Load texture
            texture := sdl2_image.LoadTexture(bound.renderer, file_path)
            assert(texture != nil, sdl2.GetErrorString())

            // Add to cache
            bound.sprite_cache[sprite_id] = texture

            // Bind
            if (bind)
            {
                bound.sprite_bound = texture
            }
            
            // Return
            return sprite_id
        }
    }
    
    // Return
    return 0
}

destroy_sprite :: proc(sprite_id : u8)
{
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")

    // Texture
    texture := bound.sprite_cache[sprite_id]
    
    // Remove from cache
    bound.sprite_cache[sprite_id] = nil
    
    // Destroy texture
    sdl2.DestroyTexture(texture)
}

query_sprite_size :: proc(sprite_id : u8) -> [2]i32
{
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")

    // Texture
    texture := bound.sprite_cache[sprite_id]

    // Return size
    rect := sdl2.Rect {}
    sdl2.QueryTexture(texture,nil,nil,&rect.w,&rect.h)
    return { rect.w, rect.h }
}

/*------------------------------------------------------------------------------
TOR : SDL2->Renderer (Sprite : Draw)
------------------------------------------------------------------------------*/

draw_sprite_rect :: proc(destination : ^DestinationRect)
{   
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(bound.sprite_bound != nil, "Renderer (SDL) : Texture not bound")
 
    // Draw
    sdl2.RenderCopyF(bound.renderer,bound.sprite_bound,nil,destination)
}

draw_sprite_vector :: proc(destination : [4]f32)
{   
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(bound.sprite_bound != nil, "Renderer (SDL) : Texture not bound")
 
    // Draw
    sdl2.RenderCopyF(bound.renderer,bound.sprite_bound,nil,&{destination.x,destination.y,destination.z,destination.w})
}

draw_sprite_atlas_rect :: proc(source : ^SourceRect, destination : ^DestinationRect)
{  
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(bound.sprite_bound != nil, "Renderer (SDL) : Texture not bound")

    sdl2.RenderCopyF(bound.renderer,bound.sprite_bound,source,destination)
}


draw_sprite_atlas_vector :: proc(source : ^[4]f32, destination : ^[4]f32)
{   
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(bound.sprite_bound != nil, "Renderer (SDL) : Texture not bound")
 
    // Draw
    sdl2.RenderCopyF(bound.renderer,bound.sprite_bound,&{i32(source.x),i32(source.y),i32(source.z),i32(source.w)},&{f32(destination.x),f32(destination.y),f32(destination.z),f32(destination.w)})
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
    bound.ttf_font_bound = bound.ttf_font_cache[font_id]
}

create_text_tff_font :: proc(file_path : cstring, font_size : i32, bind : bool) -> u8
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
                bound.ttf_font_bound = font
            }
            
            // Return
            return font_id
        }
    }
        
    // Return
    return 0
}

destroy_text_tff_font :: proc(font_id : u8)
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
    assert(bound.ttf_font_bound != nil, "Renderer (SDL) : Font not bound")

    // Key 
    key := text_tff_static_key { text, bound.ttf_font_bound }

    // Texture
    cache := bound.ttf_text_static_sprite_cache[key]
    if (cache.texture == nil)
    {
        // Surface
        surface := sdl2_tff.RenderText_Solid(bound.ttf_font_bound,text, bound.draw_color_sdl)
        texture := sdl2.CreateTextureFromSurface(bound.renderer,surface)

        // cache
        bound.ttf_text_static_sprite_cache[key] = { texture, {surface.w,surface.h} }

        // Free Surface And Texture
        sdl2.FreeSurface(surface)
    }
  
    // Draw
    dest_rect := sdl2.Rect{ position.x, position.y, cache.size.x, cache.size.y }
    sdl2.RenderCopy(bound.renderer, cache.texture,nil,&dest_rect)
}

draw_text_tff_dynamic :: proc(text : cstring, position : [2]i32)
{
    // Validate
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(sdl2_tff.WasInit() != 0, "Renderer (SDL) : Tff not initalized")
    assert(bound.ttf_font_bound != nil, "Renderer (SDL) : Font not bound")

    // Texture
    surface := sdl2_tff.RenderText_Solid(bound.ttf_font_bound,text, bound.draw_color_sdl)
    texture := sdl2.CreateTextureFromSurface(bound.renderer,surface)

    // Draw
    dest_rect := sdl2.Rect{ position.x, position.y, surface.w, surface.h}
    sdl2.RenderCopy(bound.renderer, texture,nil,&dest_rect)
  
    // Free Surface And Texture
    sdl2.FreeSurface(surface)
    sdl2.DestroyTexture(texture)
}

/*------------------------------------------------------------------------------
TOR : SDL2->Modes
------------------------------------------------------------------------------*/

set_blend_mode :: proc(blend_mode : c.int)
{
    assert(bound != nil, "Renderer (SDL) : Renderer not bound")
    sdl2.SetRenderDrawBlendMode(bound.renderer,sdl2.BlendMode(blend_mode))

    if (bound.sprite_bound != nil)
    {
        sdl2.SetTextureBlendMode(bound.sprite_bound,sdl2.BlendMode(blend_mode))
    }
}

/*------------------------------------------------------------------------------
TOR : SDL2->Renderer (Main)
------------------------------------------------------------------------------*/

bind :: proc(id : u8)
{
    // Bind renderer
    bound = cache[id]
}

free :: proc(id : u8)
{
    // delete 
}

get_bound_rawptr :: proc(id : u8) -> rawptr
{
    return bound
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
    //sdl2.SetHint(sdl2.HINT_RENDER_VSYNC,"2")

    // Create renderer
    id := u8(0)
    for i := 1; i < 255; i+=1
    {
        if (cache[u8(i)] == nil)
        {
            // ID
            id = u8(i)
            
            // Create renderer
            cache[id] = new (renderer2d)
            cache[id].renderer = sdl2.CreateRenderer((^sdl2.Window)(sdl2_window),-1,sdl2.RENDERER_ACCELERATED)
                        
            // Bind
            if (bind)
            {
                bound = cache[id]
            }

            
            // Defaults
            set_clear_color_rgba({100,149,237,255})
            set_draw_color_rgba({255,255,255,255})
            sdl2.RenderSetScale(cache[id].renderer,1,1)
            sdl2.SetRenderDrawBlendMode(cache[id].renderer,sdl2.BlendMode.BLEND)

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
    
    // Draw Present
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