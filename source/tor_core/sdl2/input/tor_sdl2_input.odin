package tor_core_sdl2_input
import "core:c"
import sdl2 "vendor:sdl2"

// State
INPUT_STATE_UP                                       :: 0b00000000
INPUT_STATE_DOWN                                     :: 0b00000001
INPUT_STATE_PRESSED                                  :: 0b00000010
INPUT_STATE_RELEASED                                 :: 0b00000011
                                                  
// Keyboard
Keycode                                              :: sdl2.Scancode
@(private)
key_states                                           : [255](i32) // SDL HAS 255 KEYS

// Mouse
MouseButton                                          :: enum
{
	Left,
	Right,
	Middle
}   
@private
mouse_position                                       : [4](i32)
@private
mouse_button_states                                  : [3](i32)

/*------------------------------------------------------------------------------
TOR : SDL2->Input (Main)
------------------------------------------------------------------------------*/

get_key_state :: proc (key_code : Keycode, state : i32) -> bool
{
    return key_states[key_code] == state
}

get_mouse_button_state :: proc(mouse_button : MouseButton, state : i32) -> bool
{
    return mouse_button_states[mouse_button] == state
}

update :: proc() 
{
    // Mouse state
    {
        // Positin
        mouse_state := sdl2.GetMouseState(&mouse_position.x,&mouse_position.y)
        sdl2.GetGlobalMouseState(&mouse_position.z,&mouse_position.w)

        // Left mouse button Up | Down
        if (mouse_state & sdl2.BUTTON_LMASK) != 0
        {
            mouse_button_states[0]  = mouse_button_states[0] == INPUT_STATE_UP ? INPUT_STATE_PRESSED : INPUT_STATE_DOWN
        }
        else
        {
            mouse_button_states[0] = mouse_button_states[0] == INPUT_STATE_DOWN  ? INPUT_STATE_RELEASED : INPUT_STATE_UP
        }

        // Right mouse button Up | Down
        if (mouse_state & sdl2.BUTTON_RMASK) != 0
        {
            mouse_button_states[1]  = mouse_button_states[1] == INPUT_STATE_UP ? INPUT_STATE_PRESSED : INPUT_STATE_DOWN
        }
        else
        {
            mouse_button_states[1] = mouse_button_states[1] == INPUT_STATE_DOWN  ? INPUT_STATE_RELEASED : INPUT_STATE_UP
        }

        // Middle mouse button Up | Down
        if (mouse_state & sdl2.BUTTON_MMASK) != 0
        {
            mouse_button_states[2]  = mouse_button_states[2] == INPUT_STATE_UP ? INPUT_STATE_PRESSED : INPUT_STATE_DOWN
        }
        else
        {
            mouse_button_states[2] = mouse_button_states[2] == INPUT_STATE_DOWN  ? INPUT_STATE_RELEASED : INPUT_STATE_UP
        }
    }

    // Keyboard State
    {
        keyboard_state := sdl2.GetKeyboardState(nil)

        for i := 0; i < 255; i+=1
        {
            // Key up | Dpwn
            if keyboard_state[i] == 0
            {
                key_states[i] = key_states[i] == INPUT_STATE_DOWN  ? INPUT_STATE_RELEASED : INPUT_STATE_UP
            } 
            else 
            {
                key_states[i] = key_states[i] == INPUT_STATE_UP ? INPUT_STATE_PRESSED : INPUT_STATE_DOWN
            }
        }
    }
}