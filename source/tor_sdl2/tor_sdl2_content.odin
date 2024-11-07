package tor_sdl2
import sdl2 "vendor:sdl2"
import sdl2_image "vendor:sdl2/image" 
import sdl2_tff "vendor:sdl2/ttf"

tor_sdl2_content_renderer_bound                              : ^sdl2.Renderer

/*------------------------------------------------------------------------------
TOR : SDL2->Content (Font tff)
------------------------------------------------------------------------------*/

content_load_font_tff :: proc(file_path : cstring, font_size : i32) -> rawptr
{
     // Load font
     font := sdl2_tff.OpenFont(file_path,font_size)
     assert(font != nil, sdl2.GetErrorString())
     return rawptr(font)
}

content_destroy_font_tff :: proc(font : rawptr)
{
    sdl2_tff.CloseFont((^sdl2_tff.Font)(font))
}

/*------------------------------------------------------------------------------
TOR : SDL2->Content (Main)
------------------------------------------------------------------------------*/

content_bind_renderer :: proc(renderer : rawptr)
{
    tor_sdl2_content_renderer_bound = (^sdl2.Renderer)(renderer)
}