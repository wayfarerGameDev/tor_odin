package tor_core_sdl2_app
import "core:strings"
import "core:strconv"
import "core:fmt"
import sdl2 "vendor:sdl2"
import sdl2_tff "vendor:sdl2/ttf"

// State
@(private)
STATE_NULL                                                 :: 0b00000000
@(private)
STATE_INIT                                                 :: 0b00000001
@(private)
STATE_RUNNING                                              :: 0b00000010
@(private)
state                                                      : u8 

// Events
@(private)
Event                                                      :: proc()
@(private)
on_start,on_end,on_update,on_render,on_resize              : Event

// Time
time                                                       : Time
Time                                                       :: struct
{
    delta_time                                             : f64,
    fps                                                    : f64,
    fps_as_string                                          : string,
    fps_as_cstring                                         : cstring,
}

/*------------------------------------------------------------------------------
TOR : SDL2->App (Events)
------------------------------------------------------------------------------*/

bind_Events :: proc(on_start_in : Event, on_end_in : Event, on_update_in : Event, on_render_in : Event, on_resize_in : Event)
{
    // Bind Events
    on_start = on_start_in;
    on_end = on_end_in;
    on_update = on_update_in;
    on_render = on_render_in;
    on_resize = on_resize_in;
}

/*------------------------------------------------------------------------------
TOR : SDL2->App (Main)
------------------------------------------------------------------------------*/

init :: proc()
{
    // Validate
    assert(state == STATE_NULL, "App (SDL) : Already initalized")

    // Init state | SDL
    state = STATE_INIT
	assert(sdl2.Init(sdl2.INIT_EVERYTHING) == 0, sdl2.GetErrorString())

    // Init sdl2 tff
    sdl2_tff.Init()
}

init_opengl :: proc(version_major : i32, version_minor : i32, opengl_context : i32 )
{
    // Validate
    assert(state == STATE_NULL, "App (SDL) : Already initalized")

    // Init state | SDL
    state = STATE_INIT
	assert(sdl2.Init(sdl2.INIT_EVERYTHING) == 0, sdl2.GetErrorString())

    // Init sdl2 tff
    sdl2_tff.Init()
} 

run :: proc()
{
    // Set state
    state = STATE_RUNNING

    // Event (on start)
    if (on_start != nil) { on_start() }

    time_frame_count := 0
    time_start_ticks := sdl2.GetTicks()
    time_end_ticks := sdl2.GetTicks()
    time_fps_updater_ticks := u32(0)
    
    time.fps_as_string = "NA"
    time.fps_as_cstring = strings.clone_to_cstring(time.fps_as_string)

    // Run | App loop
    is_runing := true
    for is_runing
    {
        // Time (Start)
        {
            time_end_ticks = time_start_ticks
            time_start_ticks = sdl2.GetTicks()
            time_start_perf := sdl2.GetPerformanceCounter()
        }

        // SDL Event Loop
        {
            Event : sdl2.Event
            for (sdl2.PollEvent(&Event))
            {
                if (Event.type == sdl2.EventType.QUIT) { is_runing = false }
                else if (Event.type == sdl2.EventType.WINDOWEVENT && on_resize != nil) { on_resize(); }
            }
        }

        // Update | Render
        {
            time.delta_time = f64(time_start_ticks - time_end_ticks) / 1000.0
           
            // Increment frame count
            time_frame_count += 1
            
            // Check if a second has passed to update FPS
             if (time_start_ticks - time_fps_updater_ticks >= 1000)
            {
                // Update FPS every second
                time.fps = f64(time_frame_count)
                time_frame_count = 0
                time_fps_updater_ticks = time_start_ticks

                // Convert to string
                buf: [8]byte
	            time.fps_as_string = strconv.append_float(buf[:], time.fps, 'f', 2, 64)
                time.fps_as_cstring = strings.clone_to_cstring(time.fps_as_string)
            }

            // Update last frame time to current time
            time_end_ticks = sdl2.GetTicks()
        }

        if (on_update != nil) { on_update() }
        if (on_render != nil) { on_render() }
    }

    //Shutdown state
    state = STATE_NULL

    // Event (On end)
    if (on_end != nil) { on_end() }

    // Stop SDL
    sdl2.Quit();
   
    // Deinit sdl2 tff
    sdl2_tff.Quit()
}