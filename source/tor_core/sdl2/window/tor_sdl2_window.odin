package tor_core_sdl2_window
import sdl2 "vendor:sdl2"

// Window cache
cache                                           : map[u8] ^sdl2.Window
bound                                           : ^sdl2.Window

/*------------------------------------------------------------------------------
TOR : SDL2->Window (Window)
------------------------------------------------------------------------------*/

get_size :: proc() -> ([2]i32)
{
    // Validate
    assert(bound != nil, "Window (SDL) : Window not bound")
    
    // Get size
    x, y : i32
    sdl2.GetWindowSize(bound ,&x,&y)
    return { x ,y }
}

set_title :: proc(title:string)
{
    // Validate
    assert(bound != nil, "Window (SDL) : Window not bound")
    
    // Set title
    sdl2.SetWindowTitle(bound ,"FIX")
}

set_resizable :: proc(bEnabled : bool)
{
    // Validate
    assert(bound != nil, "Window (SDL) : Window not bound")

    // Set resizable
    sdl2.SetWindowResizable(bound ,cast(sdl2.bool)bEnabled)
}

set_maxamize :: proc()
{
    // Validate
    assert(bound != nil, "Window (SDL) : Window not bound")

    // Maximize
    sdl2.MaximizeWindow(bound )
}

set_minamized :: proc ()
{
    // Validate
    assert(bound != nil, "Window (SDL) : Window not bound")

    // Minimize
    sdl2.MinimizeWindow(bound )
}

set_restore :: proc()
{
    // Validate
    assert(bound != nil, "Window (SDL) : Window not bound")

    // Restore
    sdl2.RestoreWindow(bound )
}


/*------------------------------------------------------------------------------
TOR : SDL2->Window (Main)
------------------------------------------------------------------------------*/

bind :: proc(id : u8)
{
    bound = cache[id]
}

get_rawptr :: proc(id : u8) -> rawptr
{
    return cache[id]
}

create :: proc(title : cstring, size : [2]i32, bind : bool) -> u8
{
    // Create window
    id := u8(0)
    for i := 1; i < 255; i+=1
    {
        if (cache[u8(i)] == nil)
        {
            // ID
            id = u8(i)
            
            // Create renderer
            cache[id] = sdl2.CreateWindow(title, sdl2.WINDOWPOS_CENTERED,sdl2.WINDOWPOS_CENTERED,size.x,size.y,sdl2.WINDOW_SHOWN)
            assert(cache[id] != nil, sdl2.GetErrorString())
           
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