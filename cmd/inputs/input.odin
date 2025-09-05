package inputs

import "core:io"
import "core:os"
import "core:fmt"
import "core:thread"
import rl "vendor:raylib"


@(private)
COSMAC_KEYBOARD :: [16]u8{
    0x1, 0x2, 0x3, 0xC,
    0x4, 0x5, 0x6, 0xD,
    0x7, 0x8, 0x9, 0xE,
    0xA, 0x0, 0xB, 0xF,
}

@(private)
QWERTY_KEYBOARD :: [16]string{
    "1", "2", "3", "4",
    "Q", "W", "E", "R",
    "A", "S", "D", "F",
    "Z", "X", "C", "V",
}

Input ::struct{
    _is_game_paused          : bool,

    _keyboard                : [16]bool,    // location with index 16 is for not valid key
    _keyboard_watcher_thread : ^thread.Thread,

    // Methods
    inputs_deinit   : proc(^Input),
    key_pressed     : proc(self: ^Input, key : string),
    key_released    : proc(self: ^Input, key : string),
    wait_keypress   : proc(^Input)-> u8,
    is_key_pressed  : proc(^Input, u8)-> (bool)
}

init :: proc() -> ^Input{ 
    input := new(Input)

    input._is_game_paused   = false

    input.wait_keypress     = wait_keypress
    input.is_key_pressed    = is_key_pressed

    input.inputs_deinit     = deinit

    input._keyboard_watcher_thread = thread.create_and_start_with_poly_data(
        input,
        keyboard_watcher,
    )

    return input
}

deinit :: proc (self: ^Input){

    self._is_game_paused  = false

    thread.destroy(self._keyboard_watcher_thread)
    free(self)
}

wait_keypress :: proc(self :^Input)-> u8{
    // fmt.printf("\033[1;1H`wait_keypress`")

    temp_cosmac := COSMAC_KEYBOARD

    for key, index in self._keyboard {
        if key do return temp_cosmac[index]
    }

    return 0xff
}

is_key_pressed :: proc(self :^Input, cosmac_key_value : u8)-> (found : bool){
    // fmt.printf("\033[%d;1H '%4s' ('%4d') is pressed: '%v'.", cosmac_key_value+2, map_cosmac_to_qwerty(cosmac_key_value), cosmac_key_value, wait_keypress(self) == cosmac_key_value)
    return self._keyboard[map_cosmac_to_keyboard(cosmac_key_value)]
}

@(private)
map_cosmac_to_keyboard :: proc(cosmac_key : u8) -> u8 {    
    for cosm, i in COSMAC_KEYBOARD {
        if cosm == cosmac_key{
            return u8(i)
        }
    }

    return 0xff
}

@(private)
map_cosmac_to_qwerty :: proc(cosmac_key : u8) -> string {
    temp_qwerty := QWERTY_KEYBOARD
    
    for cosm, i in COSMAC_KEYBOARD {
        if cosm == cosmac_key{
            return temp_qwerty[i]
        }
    }
    return "invalid"
}

// --- helpers --- 
@(private)
keyboard_watcher :: proc(self: ^Input) {
    
    keys :: [16]rl.KeyboardKey{
        .ONE, .TWO, .THREE, .FOUR,
        .Q  , .W  , .E    , .R   ,
        .A  , .S  , .D    , .F   ,
        .Z  , .X  , .C    , .V   ,
    }

    for !rl.WindowShouldClose(){
        
        // if rl.IsKeyDown(.SPACE) {
        //     self._is_game_paused = !self._is_game_paused
        // }

        for key, index in keys {
            self._keyboard[index] = rl.IsKeyDown(key)
        }
    }
}