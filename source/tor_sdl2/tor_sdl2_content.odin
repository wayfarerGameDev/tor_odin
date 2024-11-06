package tor_sdl2
import sdl2 "vendor:sdl2"
import sdl2_image "vendor:sdl2/image" 
import sdl2_tff "vendor:sdl2/ttf"

content_init :: proc()
{
    sdl2_tff.Init()
    sdl2_image.Init(sdl2_image.INIT_PNG)
}

/*------------------------------------------------------------------------------
TOR : SDL2->Content (Texture)
------------------------------------------------------------------------------*/

content_load_texture :: proc(renderer : ^sdl2.Renderer, file_path : cstring) -> rawptr
{
    // Load texture
    texture := sdl2_image.LoadTexture(renderer, file_path)
    assert(texture != nil, sdl2.GetErrorString())
    return rawptr(texture)
}

content_destroy_texture :: proc(texture : rawptr)
{
    // Destroy texture
    sdl2.DestroyTexture((^sdl2.Texture)(texture))
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