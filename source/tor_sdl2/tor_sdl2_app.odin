package tor_sdl2
import "core:strings"
import "core:strconv"
import "vendor:sdl2"

// State
TOR_SDL2_APP_STATE_NULL                                     :: 0b00000000
TOR_SDL2_APP_STATE_INIT                                     :: 0b00000001
TOR_SDL2_APP_STATE_RUNNING                                  :: 0b00000010
TOR_SDL2_APP_STATE_SHUTDOWN                                 :: 0b00000011

// Window
TOR_SDL2_APP_WINDOW_WIDTH_DEFAULT                           : i32 : 1280
TOR_SDL2_APP_WINDOW_HEIGHT_DEFAULT                          : i32 : 720
TOR_SDL2_APP_WINDOW_TITLE_DEFAULT                           : cstring : "Tor (SDL)"

// Event
tor_sdl2_app_event :: proc()

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

app_get_window_size :: proc(app: ^tor_sdl2_app) -> (i32,i32)
{
    x : ^i32
    y : ^i32
    sdl2.GetWindowSize(app.window,x,y)
    return x^ ,y^
}

app_set_window_title :: proc(app: ^tor_sdl2_app, title:string)
{
    sdl2.SetWindowTitle(app.window,"FIX")
}

app_set_window_resizable :: proc(app: ^tor_sdl2_app,bEnabled : bool)
{
    sdl2.SetWindowResizable(app.window,cast(sdl2.bool)bEnabled)
}

app_set_window_maxamize :: proc(app: ^tor_sdl2_app)
{
    sdl2.MaximizeWindow(app.window)
}

app_set_window_minamized :: proc (app: ^tor_sdl2_app)
{
    sdl2.MinimizeWindow(app.window)
}

app_set_window_restore :: proc(app: ^tor_sdl2_app)
{
    sdl2.RestoreWindow(app.window)
}

/*------------------------------------------------------------------------------
TOR : SDL2->App (Events)
------------------------------------------------------------------------------*/

app_bind_events :: proc(app: ^tor_sdl2_app, on_start : tor_sdl2_app_event, on_end : tor_sdl2_app_event, on_update : tor_sdl2_app_event, on_render_start : tor_sdl2_app_event, on_render_end : tor_sdl2_app_event, on_resize : tor_sdl2_app_event)
{
    // Bind events
    app.on_start = on_start;
    app.on_end = on_end;
    app.on_update = on_update;
    app.on_render_start = on_render_start;
    app.on_render_end = on_render_end;
    app.on_resize = on_resize;
}

/*------------------------------------------------------------------------------
TOR : SDL2->App (Time)
------------------------------------------------------------------------------*/

app_set_time_fps_target :: proc(app: ^tor_sdl2_app, fps : f64)
{
    app.time_fps_target = fps
    app.time_delta_time_target = f64(1000) / fps
}

app_get_time :: proc(app: ^tor_sdl2_app) -> f64
{
	return f64(sdl2.GetPerformanceCounter()) * 1000 / app.time_performance_frequency
}


/*------------------------------------------------------------------------------
TOR : SDL2->App (Main)
------------------------------------------------------------------------------*/

app_init :: proc(app: ^tor_sdl2_app)
{
    // Validate (state)
    assert(app.state == TOR_SDL2_APP_STATE_NULL, "App (SDL) : Already initalized")

    // Get performance frequency
    app.time_performance_frequency = f64(sdl2.GetPerformanceFrequency())

    // Init state | SDL
    app.state = TOR_SDL2_APP_STATE_INIT
	assert(sdl2.Init(sdl2.INIT_EVERYTHING) == 0, sdl2.GetErrorString())

    // Create SDL window
    app.window = sdl2.CreateWindow(TOR_SDL2_APP_WINDOW_TITLE_DEFAULT, sdl2.WINDOWPOS_CENTERED,sdl2.WINDOWPOS_CENTERED,TOR_SDL2_APP_WINDOW_WIDTH_DEFAULT,TOR_SDL2_APP_WINDOW_HEIGHT_DEFAULT,sdl2.WINDOW_SHOWN)
    assert(app.window != nil, sdl2.GetErrorString())

    // Set default fps
    app_set_time_fps_target(app,60)
}

app_run :: proc(app: ^tor_sdl2_app)
{
    // Time
    time_start : f64
	time_end : f64

    // Event (on start)
    if (app.on_start != nil) { app.on_start() }

    // Run | App loop
    app.state = TOR_SDL2_APP_STATE_RUNNING
    is_runing := true
    for is_runing
    {
        // Time (start)
        time_start = app_get_time(app)

        // SDL Event Loop
        {
            event : sdl2.Event
            for (sdl2.PollEvent(&event))
            {
                if (event.type == sdl2.EventType.QUIT) { is_runing = false }
                if (event.type == sdl2.EventType.WINDOWEVENT && app.on_resize != nil) { app.on_resize();}
            }
        }

        // Event (On update)
        if (app.on_update != nil) { app.on_update() }

        // Render (start)
        if (app.on_render_start != nil) { app.on_render_start() }

        // Time (end) | Hit target framerate
        time_end = app_get_time(app)
		for time_end - time_start < app.time_delta_time_target{ time_end = app_get_time(app) }
    
        // Time (fps)
        app.time_fps = 1000 / (time_end - time_start)
        {
            buf: [8]byte
            app.time_fps_as_string = strconv.append_float(buf[:], app.time_fps, 'f', 2, 64)
        }

        // Render (end)
        if (app.on_render_end != nil) { app.on_render_end() }
    }

    //Shutdown state
    app.state = TOR_SDL2_APP_STATE_SHUTDOWN

    // Event (On end)
    if (app.on_end != nil) { app.on_end() }

    // Stop SDL
    sdl2.DestroyWindow(app.window)
    sdl2.Quit();
}