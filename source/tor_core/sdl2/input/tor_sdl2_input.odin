package tor_core_sdl2_input
import "core:c"
import sdl2 "vendor:sdl2"

// State
INPUT_STATE_UP                                       :: 0b00000000
INPUT_STATE_DOWN                                     :: 0b00000001
INPUT_STATE_PRESSED                                  :: 0b00000010
INPUT_STATE_RELEASED                                 :: 0b00000011

// Input Keys (Keyboard->Arrows)
INPUT_KEY_LEFT                                       :: sdl2.SCANCODE_LEFT
INPUT_KEY_RIGHT                                      :: sdl2.SCANCODE_RIGHT
INPUT_KEY_UP                                         :: sdl2.SCANCODE_UP
INPUT_KEY_DOWN                                       :: sdl2.SCANCODE_DOWN

// Input Keys (Keyboard->Numbers)
INPUT_KEY_0                                          :: sdl2.SCANCODE_0
INPUT_KEY_1                                          :: sdl2.SCANCODE_1
INPUT_KEY_2                                          :: sdl2.SCANCODE_2
INPUT_KEY_3                                          :: sdl2.SCANCODE_3
INPUT_KEY_4                                          :: sdl2.SCANCODE_4
INPUT_KEY_5                                          :: sdl2.SCANCODE_5  
INPUT_KEY_6                                          :: sdl2.SCANCODE_6
INPUT_KEY_7                                          :: sdl2.SCANCODE_7
INPUT_KEY_8                                          :: sdl2.SCANCODE_8
INPUT_KEY_9                                          :: sdl2.SCANCODE_9

// Input Keys (Keyboard->Keypad Numbers)
INPUT_KEY_KEYPAD_0                                   :: sdl2.SCANCODE_KP_0
INPUT_KEY_KEYPAD_00                                  :: sdl2.SCANCODE_KP_00
INPUT_KEY_KEYPAD_000                                 :: sdl2.SCANCODE_KP_000
INPUT_KEY_KEYPAD_1                                   :: sdl2.SCANCODE_KP_1
INPUT_KEY_KEYPAD_2                                   :: sdl2.SCANCODE_KP_2
INPUT_KEY_KEYPAD_3                                   :: sdl2.SCANCODE_KP_3
INPUT_KEY_KEYPAD_4                                   :: sdl2.SCANCODE_KP_4
INPUT_KEY_KEYPAD_5                                   :: sdl2.SCANCODE_KP_5  
INPUT_KEY_KEYPAD_6                                   :: sdl2.SCANCODE_KP_6
INPUT_KEY_KEYPAD_7                                   :: sdl2.SCANCODE_KP_7
INPUT_KEY_KEYPAD_8                                   :: sdl2.SCANCODE_KP_8
INPUT_KEY_KEYPAD_9                                   :: sdl2.SCANCODE_KP_9

// Input Keys (Keyboard->Alphabet)
INPUT_KEY_A                                          :: sdl2.SCANCODE_A
INPUT_KEY_B                                          :: sdl2.SCANCODE_B
INPUT_KEY_C                                          :: sdl2.SCANCODE_C
INPUT_KEY_D                                          :: sdl2.SCANCODE_D
INPUT_KEY_E                                          :: sdl2.SCANCODE_E  
INPUT_KEY_F                                          :: sdl2.SCANCODE_F
INPUT_KEY_G                                          :: sdl2.SCANCODE_G
INPUT_KEY_H                                          :: sdl2.SCANCODE_H
INPUT_KEY_I                                          :: sdl2.SCANCODE_I
INPUT_KEY_J                                          :: sdl2.SCANCODE_J
INPUT_KEY_K                                          :: sdl2.SCANCODE_K
INPUT_KEY_L                                          :: sdl2.SCANCODE_L
INPUT_KEY_M                                          :: sdl2.SCANCODE_M
INPUT_KEY_N                                          :: sdl2.SCANCODE_N
INPUT_KEY_O                                          :: sdl2.SCANCODE_O
INPUT_KEY_P                                          :: sdl2.SCANCODE_P
INPUT_KEY_Q                                          :: sdl2.SCANCODE_Q
INPUT_KEY_R                                          :: sdl2.SCANCODE_R
INPUT_KEY_S                                          :: sdl2.SCANCODE_S
INPUT_KEY_T                                          :: sdl2.SCANCODE_T
INPUT_KEY_U                                          :: sdl2.SCANCODE_U
INPUT_KEY_V                                          :: sdl2.SCANCODE_V
INPUT_KEY_W                                          :: sdl2.SCANCODE_W
INPUT_KEY_X                                          :: sdl2.SCANCODE_X
INPUT_KEY_Y                                          :: sdl2.SCANCODE_Y
INPUT_KEY_Z                                          :: sdl2.SCANCODE_Z

// Keyboard
key_states                                           : [255](i32) // SDL HAS 255 KEYS

/*------------------------------------------------------------------------------
TOR : SDL2->Input (Main)
------------------------------------------------------------------------------*/

get_key_state :: proc (key_code : sdl2.Scancode, state : i32) -> bool
{
    return key_states[key_code] == state
}

update :: proc() 
{
    // Keyboard State
    {
        keyboard_state := sdl2.GetKeyboardState(nil)

        for i := 0; i < 255; i+=1
        {
            // Key up
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