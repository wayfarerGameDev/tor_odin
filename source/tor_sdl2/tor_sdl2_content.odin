package tor_sdl2
import sdl2 "vendor:sdl2"
import sdl2_image "vendor:sdl2/image" 
import sdl2_tff "vendor:sdl2/ttf"

tor_sdl2_content_renderer_bound                              : ^sdl2.Renderer


/*------------------------------------------------------------------------------
TOR : SDL2->Content (Texture)
------------------------------------------------------------------------------*/

content_load_texture :: proc(file_path : cstring) -> rawptr
{
    // Validate
    assert(tor_sdl2_content_renderer_bound != nil, "Content (SDL) : Renderer not bound")

    // Load texture
    texture := sdl2_image.LoadTexture(tor_sdl2_content_renderer_bound, file_path)
    assert(texture != nil, sdl2.GetErrorString())
    return rawptr(texture)
}

content_destroy_texture :: proc(texture : rawptr)
{
    // Destroy texture
    sdl2.DestroyTexture((^sdl2.Texture)(texture))
}

content_query_texture_size :: proc(texture : rawptr) -> [2]i32
{
    rect := sdl2.Rect {}
    sdl2.QueryTexture((^sdl2.Texture)(texture),nil,nil,&rect.w,&rect.h)
    return { rect.w, rect.h }
}

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