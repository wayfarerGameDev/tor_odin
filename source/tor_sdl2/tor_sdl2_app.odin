package tor_sdl2
import "core:strings"
import "core:strconv"
import sdl2 "vendor:sdl2"
import sdl2_tff "vendor:sdl2/ttf"

// State
TOR_SDL2_APP_STATE_NULL                                     :: 0b00000000
TOR_SDL2_APP_STATE_INIT                                     :: 0b00000001
TOR_SDL2_APP_STATE_RUNNING                                  :: 0b00000010

// Window
TOR_SDL2_APP_WINDOW_WIDTH_DEFAULT                           : i32 : 1280
TOR_SDL2_APP_WINDOW_HEIGHT_DEFAULT                          : i32 : 720
TOR_SDL2_APP_WINDOW_TITLE_DEFAULT                           : cstring : "Tor (SDL)"

// Event
tor_sdl2_app_event :: proc()

// Bound
tor_sdl2_app_bound                                          : ^tor_sdl2_app

// Instance
tor_sdl2_app :: struct
{
    state                                                   : u8,    
    window                                                  : ^sdl2.Window,  
    on_start                                                : tor_sdl2_app_event,
    on_end                                                  : tor_sdl2_app_event,
    on_update                                               : tor_sdl2_app_event,
    on_render_start                                         : tor_sdl2_app_event,
    on_render_end                                           : tor_sdl2_app_event,
    on_resize                                               : tor_sdl2_app_event,
    time_performance_frequency                              : f64,
    time_delta_time_target                                  : f64,
    time_fps_target                                         : f64,
    time_fps                                                : f64,
    time_fps_as_string                                      : string
}

/*------------------------------------------------------------------------------
TOR : SDL2->App (Window)
------------------------------------------------------------------------------*/

app_get_window_size :: proc() -> (i32,i32)
{
    // Validate
    assert(tor_sdl2_app_bound != nil, "App (SDL) : App not bound")
    
    // Get size
    x : ^i32
    y : ^i32
    sdl2.GetWindowSize(tor_sdl2_app_bound.window,x,y)
    return x^ ,y^
}

app_set_window_title :: proc(title:string)
{
    // Validate
    assert(tor_sdl2_app_bound != nil, "App (SDL) : App not bound")
    
    // Set title
    sdl2.SetWindowTitle(tor_sdl2_app_bound.window,"FIX")
}

app_set_window_resizable :: proc(bEnabled : bool)
{
    // Validate
    assert(tor_sdl2_app_bound != nil, "App (SDL) : App not bound")

    // Set resizable
    sdl2.SetWindowResizable(tor_sdl2_app_bound.window,cast(sdl2.bool)bEnabled)
}

app_set_window_maxamize :: proc()
{
    // Validate
    assert(tor_sdl2_app_bound != nil, "App (SDL) : App not bound")

    // Maximize
    sdl2.MaximizeWindow(tor_sdl2_app_bound.window)
}

app_set_window_minamized :: proc ()
{
    // Validate
    assert(tor_sdl2_app_bound != nil, "App (SDL) : App not bound")

    // Minimize
    sdl2.MinimizeWindow(tor_sdl2_app_bound.window)
}

app_set_window_restore :: proc()
{
    // Validate
    assert(tor_sdl2_app_bound != nil, "App (SDL) : App not bound")

    // Restore
    sdl2.RestoreWindow(tor_sdl2_app_bound.window)
}

/*------------------------------------------------------------------------------
TOR : SDL2->App (Events)
------------------------------------------------------------------------------*/

app_bind_events :: proc( on_start : tor_sdl2_app_event, on_end : tor_sdl2_app_event, on_update : tor_sdl2_app_event, on_render_start : tor_sdl2_app_event, on_render_end : tor_sdl2_app_event, on_resize : tor_sdl2_app_event)
{
    // Validate
    assert(tor_sdl2_app_bound != nil, "App (SDL) : App not bound")

    // Bind events
    tor_sdl2_app_bound.on_start = on_start;
    tor_sdl2_app_bound.on_end = on_end;
    tor_sdl2_app_bound.on_update = on_update;
    tor_sdl2_app_bound.on_render_start = on_render_start;
    tor_sdl2_app_bound.on_render_end = on_render_end;
    tor_sdl2_app_bound.on_resize = on_resize;
}

/*------------------------------------------------------------------------------
TOR : SDL2->App (Time)
------------------------------------------------------------------------------*/

app_set_time_fps_target :: proc( fps : f64)
{
    // Validate
    assert(tor_sdl2_app_bound != nil, "App (SDL) : App not bound")

    // Set fps target
    tor_sdl2_app_bound.time_fps_target = fps
    tor_sdl2_app_bound.time_delta_time_target = f64(1000) / fps
}

app_get_time :: proc() -> f64
{
    // Validate
    assert(tor_sdl2_app_bound != nil, "App (SDL) : App not bound")

    // Return time
	return f64(sdl2.GetPerformanceCounter()) * 1000 / tor_sdl2_app_bound.time_performance_frequency
}


/*------------------------------------------------------------------------------
TOR : SDL2->App (Main)
------------------------------------------------------------------------------*/

app_bind :: proc(app: ^tor_sdl2_app)
{
    // Validate
    assert(app.state != TOR_SDL2_APP_STATE_RUNNING, "App (SDL) : Can't bind when running")

    // Bind
    tor_sdl2_app_bound = app
}

app_init :: proc()
{
    // Validate
    assert(tor_sdl2_app_bound != nil, "App (SDL) : App not bound")
    assert(tor_sdl2_app_bound.state == TOR_SDL2_APP_STATE_NULL, "App (SDL) : Already initalized")

    // Get performance frequency
    tor_sdl2_app_bound.time_performance_frequency = f64(sdl2.GetPerformanceFrequency())

    // Init state | SDL
    tor_sdl2_app_bound.state = TOR_SDL2_APP_STATE_INIT
	assert(sdl2.Init(sdl2.INIT_EVERYTHING) == 0, sdl2.GetErrorString())

    // Create SDL window
    tor_sdl2_app_bound.window = sdl2.CreateWindow(TOR_SDL2_APP_WINDOW_TITLE_DEFAULT, sdl2.WINDOWPOS_CENTERED,sdl2.WINDOWPOS_CENTERED,TOR_SDL2_APP_WINDOW_WIDTH_DEFAULT,TOR_SDL2_APP_WINDOW_HEIGHT_DEFAULT,sdl2.WINDOW_SHOWN)
    assert(tor_sdl2_app_bound.window != nil, sdl2.GetErrorString())

    // Init sdl2 tff
    sdl2_tff.Init()

    // Set default fps
    app_set_time_fps_target(60)
}

app_run :: proc()
{
    // Set state
    tor_sdl2_app_bound.state = TOR_SDL2_APP_STATE_RUNNING

    // Time
    time_start : f64
	time_end : f64

    // Event (on start)
    if (tor_sdl2_app_bound.on_start != nil) { tor_sdl2_app_bound.on_start() }

    // Run | App loop
    is_runing := true
    for is_runing
    {
        // Time (start)
        time_start = app_get_time()

        // SDL Event Loop
        {
            event : sdl2.Event
            for (sdl2.PollEvent(&event))
            {
                if (event.type == sdl2.EventType.QUIT) { is_runing = false }
                if (event.type == sdl2.EventType.WINDOWEVENT && tor_sdl2_app_bound.on_resize != nil) { tor_sdl2_app_bound.on_resize();}
            }
        }

        // Event (On update)
        if (tor_sdl2_app_bound.on_update != nil) { tor_sdl2_app_bound.on_update() }

        // Render (start)
        if (tor_sdl2_app_bound.on_render_start != nil) { tor_sdl2_app_bound.on_render_start() }

        // Time (end) | Hit target framerate
        time_end = app_get_time()
		for time_end - time_start < tor_sdl2_app_bound.time_delta_time_target{ time_end = app_get_time() }
    
        // Time (fps)
        tor_sdl2_app_bound.time_fps = 1000 / (time_end - time_start)
        {
            buf: [8]byte
            tor_sdl2_app_bound.time_fps_as_string = strconv.append_float(buf[:], tor_sdl2_app_bound.time_fps, 'f', 2, 64)
        }

        // Render (end)
        if (tor_sdl2_app_bound.on_render_end != nil) { tor_sdl2_app_bound.on_render_end() }
    }

    //Shutdown state
    tor_sdl2_app_bound.state = TOR_SDL2_APP_STATE_NULL

    // Event (On end)
    if (tor_sdl2_app_bound.on_end != nil) { tor_sdl2_app_bound.on_end() }

    // Stop SDL
    sdl2.DestroyWindow(tor_sdl2_app_bound.window)
    sdl2.Quit();
   
    // Deinit sdl2 tff
    sdl2_tff.Quit()
}