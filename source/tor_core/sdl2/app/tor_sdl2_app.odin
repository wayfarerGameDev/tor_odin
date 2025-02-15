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
on_start,on_end,on_run,on_run_fixed,on_resize              : Event

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

bind_Events :: proc(on_start_in : Event, on_end_in : Event, on_run_in : Event, on_run_fixed_in, on_resize_in : Event)
{
    // Bind Events
    on_start = on_start_in
    on_end = on_end_in
    on_run = on_run_in
    on_run_fixed = on_run_fixed_in
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

    // Time for fixed update interval (e.g., 30 frames = fixed time step)
    fixed_update_interval := 0.0
    fixed_accumulated_time := 0.0  // Time accumulator for fixed updates
    fixed_updates_max := 5
    fixed_updates := 0

    // Run | App loop
    is_running := true
    for is_running
    {
        // Time
        {
            // Start | End
            time_end_ticks = time_start_ticks
            time_start_ticks = sdl2.GetTicks()
            time_start_perf := sdl2.GetPerformanceCounter()

            // Delta
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
        }

        // SDL Event Loop
        {
            Event : sdl2.Event
            for (sdl2.PollEvent(&Event))
            {
                if (Event.type == sdl2.EventType.QUIT) { is_running = false }
                else if (Event.type == sdl2.EventType.WINDOWEVENT && on_resize != nil) { on_resize(); }
            }
        }

        // Run
        if (on_run != nil) { on_run() }

        // Run Fixed
        {
            // Run fixed updates multiple times if FPS drops
            fixed_updates = 0
            fixed_update_interval = 1.0 / 30.0  // 30 FPS fixed update
            fixed_accumulated_time += time.delta_time

            for fixed_accumulated_time >= fixed_update_interval && fixed_updates < fixed_updates_max
            {
                // Call on_run_fixed every fixed time step (30 frames interval)
                if (on_run_fixed != nil) { on_run_fixed() }
            
                fixed_accumulated_time -= fixed_update_interval
                fixed_updates += 1
            }
        }
    }

    // Shutdown state
    state = STATE_NULL

    // Event (On end)
    if (on_end != nil) { on_end() }

    // Stop SDL
    sdl2.Quit()

    // Deinit sdl2_tff
    sdl2_tff.Quit()
}
