package tor_sdl2
import "core:strings"
import "core:strconv"
import sdl2 "vendor:sdl2"
import sdl2_tff "vendor:sdl2/ttf"

// State
TOR_SDL2_APP_STATE_NULL                                     :: 0b00000000
TOR_SDL2_APP_STATE_INIT                                     :: 0b00000001
TOR_SDL2_APP_STATE_RUNNING                                  :: 0b00000010

// Event
tor_sdl2_app_event :: proc()
tor_sdl2_app_timed_event :: proc(delta_time : f64)

// Bound
tor_sdl2_app_bound                                          : tor_sdl2_app

// Instance
tor_sdl2_app :: struct
{
    state                                                   : u8,    
    window                                                  : ^sdl2.Window,  
    on_start                                                : tor_sdl2_app_event,
    on_end                                                  : tor_sdl2_app_event,
    on_update_fixed                                         : tor_sdl2_app_timed_event,
    on_update                                               : tor_sdl2_app_timed_event,
    on_render                                               : tor_sdl2_app_event,
    on_resize                                               : tor_sdl2_app_event,
    time_delta_time_fixed                                   : f64,
    time_delta_time                                         : f64,
    time_fps_target_fixed                                   : f64,
    time_fps_target                                         : f64,
    time_fps                                                : f64,
    time_fps_as_string                                      : string
}

/*------------------------------------------------------------------------------
TOR : SDL2->App (Events)
------------------------------------------------------------------------------*/

app_bind_events :: proc( on_start : tor_sdl2_app_event, on_end : tor_sdl2_app_event, on_update_fixed : tor_sdl2_app_timed_event, on_update : tor_sdl2_app_timed_event, on_render : tor_sdl2_app_event, on_resize : tor_sdl2_app_event)
{
    // Bind events
    tor_sdl2_app_bound.on_start = on_start;
    tor_sdl2_app_bound.on_end = on_end;
    tor_sdl2_app_bound.on_update_fixed = on_update_fixed;
    tor_sdl2_app_bound.on_update = on_update;
    tor_sdl2_app_bound.on_render = on_render;
    tor_sdl2_app_bound.on_resize = on_resize;
}

/*------------------------------------------------------------------------------
TOR : SDL2->App (Main)
------------------------------------------------------------------------------*/

app_init :: proc()
{
    // Validate
    assert(tor_sdl2_app_bound.state == TOR_SDL2_APP_STATE_NULL, "App (SDL) : Already initalized")

    // Init state | SDL
    tor_sdl2_app_bound.state = TOR_SDL2_APP_STATE_INIT
	assert(sdl2.Init(sdl2.INIT_EVERYTHING) == 0, sdl2.GetErrorString())

    // Default fps target
    tor_sdl2_app_bound.time_fps_target = 60
    tor_sdl2_app_bound.time_delta_time_fixed = 60

    // Init sdl2 tff
    sdl2_tff.Init()
}

app_run :: proc()
{
    // Set state
    tor_sdl2_app_bound.state = TOR_SDL2_APP_STATE_RUNNING

    // Time
    time_current := (f64)(sdl2.GetPerformanceCounter())
	time_previous := time_current
    time_frame_time_target := (f64)(0)

     // Fixed update variables
     time_accumulator_fixed := 0.0  // Accumulates delta time for fixed update

    // Event (on start)
    if (tor_sdl2_app_bound.on_start != nil) { tor_sdl2_app_bound.on_start() }

    // Run | App loop
    is_runing := true
    for is_runing
    {
        // Time (start)
        {
            // Get target frame time
            time_frame_time_target = 1000.0 / (f64)(tor_sdl2_app_bound.time_fps_target)

            // Get previous and current time
            time_previous = time_current;
            time_current = (f64)(sdl2.GetPerformanceCounter())

            // Get delta time
            tor_sdl2_app_bound.time_delta_time = f64((time_current - time_previous) / (f64)(sdl2.GetPerformanceFrequency()))
            tor_sdl2_app_bound.time_delta_time_fixed = 1.0 / tor_sdl2_app_bound.time_fps_target_fixed
            
            // Accumulate delta time for fixed update
            time_accumulator_fixed += tor_sdl2_app_bound.time_delta_time
        }

        // SDL Event Loop
        {
            event : sdl2.Event
            for (sdl2.PollEvent(&event))
            {
                if (event.type == sdl2.EventType.QUIT) { is_runing = false }
                if (event.type == sdl2.EventType.WINDOWEVENT && tor_sdl2_app_bound.on_resize != nil) { tor_sdl2_app_bound.on_resize();}
            }
        }

        // Fixed Update
        {
            // Perform fixed updates as long as we have enough accumulated time
            for (time_accumulator_fixed >= tor_sdl2_app_bound.time_delta_time_fixed)
            {
                if (tor_sdl2_app_bound.on_update_fixed != nil) { tor_sdl2_app_bound.on_update_fixed(tor_sdl2_app_bound.time_delta_time_fixed) }

                // Decrease time_accumulator_fixed by the fixed time step
                time_accumulator_fixed -= tor_sdl2_app_bound.time_delta_time_fixed
            }
        }

        // Update
        {
            if (tor_sdl2_app_bound.on_update != nil) { tor_sdl2_app_bound.on_update(tor_sdl2_app_bound.time_delta_time) }
        }

        // Render
        {
            if (tor_sdl2_app_bound.on_render != nil) { tor_sdl2_app_bound.on_render() }
        }

        // Time (end)
        {
            // Calculate time taken for this frame
            frame_time := f64((sdl2.GetPerformanceCounter() - (u64)(time_previous)) * 1000) / (f64)(sdl2.GetPerformanceFrequency())

            // If the frame took too long (greater than target), skip delay
            if (frame_time < time_frame_time_target)
            {
                // Delay the rest of the frame to limit the FPS
                delay_time := time_frame_time_target - frame_time
                sdl2.Delay(u32(delay_time))  // SDL_Delay expects milliseconds
            }
        }
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