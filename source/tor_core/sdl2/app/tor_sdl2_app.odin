package tor_core_sdl2_app
import "core:strings"
import "core:strconv"
import sdl2 "vendor:sdl2"
import sdl2_tff "vendor:sdl2/ttf"

// State
STATE_NULL                                                 :: 0b00000000
STATE_INIT                                                 :: 0b00000001
STATE_RUNNING                                              :: 0b00000010

// Event
event :: proc()
timed_event :: proc(delta_time : f64)

// Bound
bound                                                       : app

// Instance
app :: struct
{
    state                                                   : u8,    
    window                                                  : ^sdl2.Window,  
    on_start                                                : event,
    on_end                                                  : event,
    on_update_fixed                                         : timed_event,
    on_update                                               : timed_event,
    on_render                                               : event,
    on_resize                                               : event,
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

bind_events :: proc( on_start : event, on_end : event, on_update_fixed : timed_event, on_update : timed_event, on_render : event, on_resize : event)
{
    // Bind events
    bound.on_start = on_start;
    bound.on_end = on_end;
    bound.on_update_fixed = on_update_fixed;
    bound.on_update = on_update;
    bound.on_render = on_render;
    bound.on_resize = on_resize;
}

/*------------------------------------------------------------------------------
TOR : SDL2->App (Main)
------------------------------------------------------------------------------*/

init :: proc()
{
    // Validate
    assert(bound.state == STATE_NULL, "App (SDL) : Already initalized")

    // Init state | SDL
    bound.state = STATE_INIT
	assert(sdl2.Init(sdl2.INIT_EVERYTHING) == 0, sdl2.GetErrorString())

    // Default fps target
    bound.time_fps_target = 120
    bound.time_delta_time_fixed = 15

    // Init sdl2 tff
    sdl2_tff.Init()
}

run :: proc()
{
    // Set state
    bound.state = STATE_RUNNING

    // Time
    time_current := (f64)(sdl2.GetPerformanceCounter())
	time_previous := time_current
    time_frame_time_target := (f64)(0)

     // Fixed update variables
     time_accumulator_fixed := 0.0  // Accumulates delta time for fixed update

    // Event (on start)
    if (bound.on_start != nil) { bound.on_start() }

    // Run | App loop
    is_runing := true
    for is_runing
    {
        // Time (start)
        {
            // Get target frame time
            time_frame_time_target = 1000.0 / (f64)(bound.time_fps_target)

            // Get previous and current time
            time_previous = time_current;
            time_current = (f64)(sdl2.GetPerformanceCounter())
        }

        // Update
        {
            // Get delta time
            bound.time_delta_time = f64((time_current - time_previous) / (f64)(sdl2.GetPerformanceFrequency()))

            // Update
            if (bound.on_update != nil) { bound.on_update(bound.time_delta_time) }
        }

        // Fixed Update
        {
            // Accumulate delta time for fixed update
            time_accumulator_fixed += bound.time_delta_time_fixed

            bound.time_delta_time_fixed = 1000.0 / bound.time_fps_target_fixed
            
            // Perform fixed updates as long as we have enough accumulated time
            for (time_accumulator_fixed >= bound.time_delta_time_fixed)
            {
                if (bound.on_update_fixed != nil) { bound.on_update_fixed(bound.time_delta_time_fixed) }

                // Decrease time_accumulator_fixed by the fixed time step
                time_accumulator_fixed -= bound.time_delta_time_fixed
            }
        }

        // Render
        {
            if (bound.on_render != nil) { bound.on_render() }
        }

        // SDL Event Loop
        {
            event : sdl2.Event
            for (sdl2.PollEvent(&event))
            {
                if (event.type == sdl2.EventType.QUIT) { is_runing = false }
                else if (event.type == sdl2.EventType.WINDOWEVENT && bound.on_resize != nil) { bound.on_resize();}
            }
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
    bound.state = STATE_NULL

    // Event (On end)
    if (bound.on_end != nil) { bound.on_end() }

    // Stop SDL
    sdl2.DestroyWindow(bound.window)
    sdl2.Quit();
   
    // Deinit sdl2 tff
    sdl2_tff.Quit()
}