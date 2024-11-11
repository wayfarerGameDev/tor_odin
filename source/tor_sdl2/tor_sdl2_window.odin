package tor_sdl2
import sdl2 "vendor:sdl2"

// Window cache
tor_sdl2_window_window_cache                           : map[u8] ^sdl2.Window
tor_sdl2_window_window_bound                           : ^sdl2.Window

/*------------------------------------------------------------------------------
TOR : SDL2->Window (Window)
------------------------------------------------------------------------------*/

window_get_size :: proc() -> ([2]i32)
{
    // Validate
    assert(tor_sdl2_window_window_bound != nil, "Window (SDL) : Window not bound")
    
    // Get size
    x, y : i32
    sdl2.GetWindowSize(tor_sdl2_window_window_bound ,&x,&y)
    return { x ,y }
}

widdow_set_title :: proc(title:string)
{
    // Validate
    assert(tor_sdl2_window_window_bound != nil, "Window (SDL) : Window not bound")
    
    // Set title
    sdl2.SetWindowTitle(tor_sdl2_window_window_bound ,"FIX")
}

window_set_resizable :: proc(bEnabled : bool)
{
    // Validate
    assert(tor_sdl2_window_window_bound != nil, "Window (SDL) : Window not bound")

    // Set resizable
    sdl2.SetWindowResizable(tor_sdl2_window_window_bound ,cast(sdl2.bool)bEnabled)
}

window_set_maxamize :: proc()
{
    // Validate
    assert(tor_sdl2_window_window_bound != nil, "Window (SDL) : Window not bound")

    // Maximize
    sdl2.MaximizeWindow(tor_sdl2_window_window_bound )
}

window_set_minamized :: proc ()
{
    // Validate
    assert(tor_sdl2_window_window_bound != nil, "Window (SDL) : Window not bound")

    // Minimize
    sdl2.MinimizeWindow(tor_sdl2_window_window_bound )
}

window_set_restore :: proc()
{
    // Validate
    assert(tor_sdl2_window_window_bound != nil, "Window (SDL) : Window not bound")

    // Restore
    sdl2.RestoreWindow(tor_sdl2_window_window_bound )
}


/*------------------------------------------------------------------------------
TOR : SDL2->Window (Main)
------------------------------------------------------------------------------*/

window_bind :: proc(window_id : u8)
{
    tor_sdl2_window_window_bound = tor_sdl2_window_window_cache[window_id]
}

window_get_rawptr :: proc(window_id : u8) -> rawptr
{
    return tor_sdl2_window_window_cache[window_id]
}

window_create :: proc(title : cstring, size : [2]i32, bind : bool) -> u8
{
    // Create window
    window_id := u8(0)
    for i := 1; i < 255; i+=1
    {
        if (tor_sdl2_window_window_cache[u8(i)] == nil)
        {
            // ID
            window_id = u8(i)
            
            // Create renderer
            tor_sdl2_window_window_cache[window_id] = sdl2.CreateWindow(title, sdl2.WINDOWPOS_CENTERED,sdl2.WINDOWPOS_CENTERED,size.x,size.y,sdl2.WINDOW_SHOWN)
            assert(tor_sdl2_window_window_cache[window_id] != nil, sdl2.GetErrorString())
           
            // Bind
            if (bind)
            {
                tor_sdl2_window_window_bound = tor_sdl2_window_window_cache[window_id]
            }
            
            // Return
            return window_id
        }
    }

    return 0
}