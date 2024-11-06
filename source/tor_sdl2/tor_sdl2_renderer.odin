package tor_sdl2
import sdl2 "vendor:sdl2"
import sdl2_image "vendor:sdl2/image" 
import sdl2_tff "vendor:sdl2/ttf"

// State
TOR_SDL2_RENDERER_STATE_NULL                               :: 0b00000000
TOR_SDL2_RENDERER_STATE_INIT                               :: 0b00000001

// Type aliases
tor_sdl2_point                                             :: sdl2.Point
tor_sdl2_rect                                              :: sdl2.Rect
tor_sdl2_render_flip                                       :: sdl2.RendererFlip

// Bound
tor_sdl2_renderer_bound                                    : ^tor_sdl2_renderer

// Instance
tor_sdl2_renderer :: struct
{
    state                                                   : u8,    
    window                                                  : ^sdl2.Window,
    renderer                                                : ^sdl2.Renderer,
    clear_color                                             : [4]u8,
    draw_color                                              : [4]u8,
    bound_texture                                           : ^sdl2.Texture,
    bound_font                                              : ^sdl2_tff.Font
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

    // Set render color
    tor_sdl2_renderer_bound.draw_color = color
    sdl2.SetRenderDrawColor(tor_sdl2_renderer_bound.renderer,tor_sdl2_renderer_bound.draw_color.r,tor_sdl2_renderer_bound.draw_color.g,tor_sdl2_renderer_bound.draw_color.b,tor_sdl2_renderer_bound.draw_color.a)
}

renderer_set_draw_color_hex :: proc(hex : u32, alpha : u8)
{
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")

    // Set render color
    tor_sdl2_renderer_bound.draw_color = {  u8((hex >> 16) & 0xFF),  u8((hex >> 8) & 0xFF), u8(hex & 0xFF), alpha  }
    sdl2.SetRenderDrawColor(tor_sdl2_renderer_bound.renderer,tor_sdl2_renderer_bound.draw_color.r,tor_sdl2_renderer_bound.draw_color.g,tor_sdl2_renderer_bound.draw_color.b,tor_sdl2_renderer_bound.draw_color.a)
}

renderer_set_to_defaults :: proc()
{
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")

    // Renderer
    tor_sdl2_renderer_bound.clear_color = {100,149,237,255}
    tor_sdl2_renderer_bound.draw_color = {255,255,255,255}

    // SDL
    sdl2.RenderSetScale(tor_sdl2_renderer_bound.renderer,1,1)
    sdl2.SetRenderDrawBlendMode(tor_sdl2_renderer_bound.renderer,sdl2.BlendMode.BLEND)
}

/*------------------------------------------------------------------------------
TOR : SDL2->Renderer (Texture)
------------------------------------------------------------------------------*/

renderer_bind_texture :: proc(texture : rawptr)
{
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")

    // Bind texture
    tor_sdl2_renderer_bound.bound_texture = (^sdl2.Texture)(texture)
}

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
TOR : SDL2->Renderer (Dtext tff)
------------------------------------------------------------------------------*/

renderer_bind_text_tff_font :: proc(font : rawptr)
{
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")
    
    // Bind font
    tor_sdl2_renderer_bound.bound_font = (^sdl2_tff.Font)(font)
}

renderer_draw_text_tff :: proc(text : cstring)
{
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")
    assert(sdl2_tff.WasInit() != 0, "Renderer (SDL) : Tff not initalized")
    assert(tor_sdl2_renderer_bound.bound_font != nil, "Renderer (SDL) : Font not bound")

    // Color
    color := sdl2.Color{tor_sdl2_renderer_bound.draw_color.r, tor_sdl2_renderer_bound.draw_color.g, tor_sdl2_renderer_bound.draw_color.b, tor_sdl2_renderer_bound.draw_color.a}

    string_surface := sdl2_tff.RenderText_Solid(tor_sdl2_renderer_bound.bound_font,text, color);
    string_texture := sdl2.CreateTextureFromSurface(tor_sdl2_renderer_bound.renderer,string_surface);

    // Render String
    dest_rect := sdl2.Rect{0,0, string_surface.w, string_surface.h};
    sdl2.RenderCopy(tor_sdl2_renderer_bound.renderer, string_texture,nil,&dest_rect)
  
    // Free Surface And Texture
    sdl2.FreeSurface(string_surface)
    sdl2.DestroyTexture(string_texture)
}

/*------------------------------------------------------------------------------
TOR : SDL2->Renderer (Main)
------------------------------------------------------------------------------*/

renderer_bind :: proc(renderer : ^tor_sdl2_renderer)
{
    // Bind renderer
    tor_sdl2_renderer_bound = renderer;
}

renderer_init :: proc(sdl2_window: rawptr)
{
     // Validate
     assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")
     assert(tor_sdl2_renderer_bound.state == TOR_SDL2_RENDERER_STATE_NULL, "Renderer (SDL) : Already initalized")
     assert(sdl2_window != nil, "Renderer (SDL) : SDL Window is undefined")
     
     // Bind window
     tor_sdl2_renderer_bound.window = (^sdl2.Window)(sdl2_window);

     // Create renderer
     tor_sdl2_renderer_bound.renderer = sdl2.CreateRenderer(tor_sdl2_renderer_bound.window,-1,sdl2.RENDERER_ACCELERATED)
     assert(tor_sdl2_renderer_bound.renderer != nil, sdl2.GetErrorString())

     // Default
     renderer_set_to_defaults()
}

renderer_deinit :: proc(renderer : ^tor_sdl2_renderer)
{
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")

    // Cleanup Renderer
    sdl2.DestroyRenderer(tor_sdl2_renderer_bound.renderer);
}

renderer_render :: proc (renderer : ^tor_sdl2_renderer)
{
    // Validate
    assert(tor_sdl2_renderer_bound != nil, "Renderer (SDL) : Renderer not bound")

    // Render Present
    sdl2.SetRenderDrawColor(tor_sdl2_renderer_bound.renderer,tor_sdl2_renderer_bound.draw_color.r,tor_sdl2_renderer_bound.draw_color.g,tor_sdl2_renderer_bound.draw_color.b,tor_sdl2_renderer_bound.draw_color.a)
    sdl2.RenderPresent(tor_sdl2_renderer_bound.renderer);

    // Clear
    sdl2.SetRenderDrawColor(tor_sdl2_renderer_bound.renderer,tor_sdl2_renderer_bound.clear_color.r,tor_sdl2_renderer_bound.clear_color.b,tor_sdl2_renderer_bound.clear_color.b,tor_sdl2_renderer_bound.clear_color.a)
    sdl2.RenderClear(tor_sdl2_renderer_bound.renderer);
}