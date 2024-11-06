package tor_sdl2
import sdl2 "vendor:sdl2"
import sdl2_image "vendor:sdl2/image" 
import sdl2_tff "vendor:sdl2/ttf"

// State
TOR_SDL2_RENDERER_STATE_NULL                               :: 0b00000000
TOR_SDL2_RENDERER_STATE_INIT                               :: 0b00000001

// Instance
tor_sdl2_renderer :: struct
{
    state                                                   : u8,    
    window                                                  : ^sdl2.Window,
    renderer                                                : ^sdl2.Renderer,
    clear_color                                             : [4]u8,
    draw_color                                              : [4]u8
}

/*------------------------------------------------------------------------------
TOR : SDL2->Renderer (Color)
------------------------------------------------------------------------------*/

renderer_set_clear_color_rgba :: proc(renderer : ^tor_sdl2_renderer, color : [4]u8)
{
    renderer.clear_color = color
    // sdl2 clear color is set when clears
}

renderer_set_clear_color_hex :: proc(renderer : ^tor_sdl2_renderer, hex : u32)
{
    renderer.clear_color = {  u8((hex >> 16) & 0xFF),  u8((hex >> 8) & 0xFF), u8(hex & 0xFF), 255  }
    // sdl2 clear color is set when clears
}

renderer_set_draw_color_rgba :: proc(renderer : ^tor_sdl2_renderer, color : [4]u8)
{
    renderer.draw_color = color
    sdl2.SetRenderDrawColor(renderer.renderer,renderer.draw_color.r,renderer.draw_color.g,renderer.draw_color.b,renderer.draw_color.a)
}

renderer_set_draw_color_hex :: proc(renderer : ^tor_sdl2_renderer, hex : u32, alpha : u8)
{
    renderer.draw_color = {  u8((hex >> 16) & 0xFF),  u8((hex >> 8) & 0xFF), u8(hex & 0xFF), alpha  }
    sdl2.SetRenderDrawColor(renderer.renderer,renderer.draw_color.r,renderer.draw_color.g,renderer.draw_color.b,renderer.draw_color.a)
}

renderer_set_to_defaults :: proc(renderer : ^tor_sdl2_renderer)
{
    // Renderer
    renderer.clear_color = {100,149,237,255}
    renderer.draw_color = {255,255,255,255}

    // SDL
    sdl2.RenderSetScale(renderer.renderer,1,1)
    sdl2.SetRenderDrawBlendMode(renderer.renderer,sdl2.BlendMode.BLEND)
}

/*------------------------------------------------------------------------------
TOR : SDL2->Renderer (Texture)
------------------------------------------------------------------------------*/

renderer_render_texture_position :: proc(renderer : ^tor_sdl2_renderer, texture : rawptr, position : [2]i32)
{
    
    // Create rect
    rect := sdl2.Rect {x= position.x, y = position.y, w = 100, h = 100}
    sdl2.QueryTexture((^sdl2.Texture)(texture),nil,nil,&rect.w,&rect.h)

    // Render
    sdl2.RenderCopy(renderer.renderer,(^sdl2.Texture)(texture),nil,&rect)
}

renderer_render_texture_rect :: proc(renderer : ^tor_sdl2_renderer, texture : rawptr, rect : [4]i32)
{    
    // Create rect
    rect := sdl2.Rect {x= rect.x, y = rect.y, w= rect.z, h= rect.w}

    // Render
    sdl2.RenderCopy(renderer.renderer,(^sdl2.Texture)(texture),nil,&rect)
}

/*------------------------------------------------------------------------------
TOR : SDL2->Renderer (TTF Font)
------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
TOR : SDL2->Renderer (Main)
------------------------------------------------------------------------------*/

renderer_init :: proc(renderer : ^tor_sdl2_renderer, sdl2_window: ^sdl2.Window)
{
     // Validate
     assert(renderer.state == TOR_SDL2_RENDERER_STATE_NULL, "Renderer (SDL) : Already initalized")
     assert(sdl2_window != nil, "Renderer (SDL) : SDL Window is undefined")
     
     // Bind window
     renderer.window = sdl2_window;

     // Create renderer
     renderer.renderer = sdl2.CreateRenderer(sdl2_window,-1,sdl2.RENDERER_ACCELERATED)
     assert(renderer.renderer != nil, sdl2.GetErrorString())

     // Init sdl2 tff (Font)
     sdl2_tff.Init()

     // Default
     renderer_set_to_defaults(renderer)
}

renderer_deinit :: proc(renderer : ^tor_sdl2_renderer)
{
    // Cleanup Renderer
    sdl2.DestroyRenderer(renderer.renderer);

    // Deinit sdl2 tff (font)
    sdl2_tff.Quit()
}

renderer_render :: proc (renderer : ^tor_sdl2_renderer)
{
   // Render Present
   sdl2.SetRenderDrawColor(renderer.renderer,renderer.draw_color.r,renderer.draw_color.g,renderer.draw_color.b,renderer.draw_color.a)
   sdl2.RenderPresent(renderer.renderer);

   // Clear
   sdl2.SetRenderDrawColor(renderer.renderer,renderer.clear_color.r,renderer.clear_color.b,renderer.clear_color.b,renderer.clear_color.a)
   sdl2.RenderClear(renderer.renderer);
}