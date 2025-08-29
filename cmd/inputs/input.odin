package inputs

import "core:io"
import "core:os"
import "core:fmt"
import "core:thread"
import "core:sys/unix"
import "core:sys/posix"
import "core:unicode/utf8"

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
    _is_game_running         :   bool,
    _is_game_paused          :   bool,

    _original_termios        : posix.termios,

    _keyboard                       :  [16]bool,    // location with index 16 is for not valid key
    _watch_last_key_pressed_thread  : ^thread.Thread,

    // Methods
    inputs_deinit   : proc(^Input),
    key_pressed     : proc(using self: ^Input, key : string),
    key_released    : proc(using self: ^Input, key : string),
    wait_keypress   : proc(^Input)-> u8,
    is_key_pressed  : proc(^Input, u8)-> (bool)
}

init :: proc() -> ^Input{
    input := new(Input)

    input._is_game_running  = true
    input._is_game_paused   = false

    input.wait_keypress     = wait_keypress
    input.is_key_pressed    = is_key_pressed
    input.key_pressed       = key_pressed
    input.key_released      = key_released

    input.inputs_deinit     = deinit

    // input._last_key_press       = 254
    // input._last_key_released    = 254
    when ODIN_OS == .Linux{
        fd := _detect_keyboard()
        input._watch_last_key_pressed_thread = thread.create_and_start_with_poly_data2(
            input,
            fd,
            _keyboard_watcher,
        )
    }

    enable_raw_mode()
    return input
}

deinit :: proc(using self: ^Input){

    _is_game_paused  = false
    _is_game_running = false

    thread.destroy(_watch_last_key_pressed_thread)
    disable_raw_mode()

    free(self)
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
map_qwerty_to_keyboard :: proc(qwerty_key : string) -> u8 {    
    for qwe, i in QWERTY_KEYBOARD {
        if qwe == qwerty_key{
            return u8(i)
        }
    }

    return 0xff
}

@(private)
map_qwerty_to_cosmac :: proc(qwerty_key : string) -> u8 {
    temp_cosmac := COSMAC_KEYBOARD
    
    for qwe, i in QWERTY_KEYBOARD {
        if qwe == qwerty_key{
            return temp_cosmac[i]
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

@(private)
key_pressed :: proc(using self: ^Input, key : string){
    if key == "ESC"{
        menu(self)
    }

    key := map_qwerty_to_keyboard(key)
    if key < 16 do _keyboard[key] = true
}

@(private)
key_released :: proc(using self: ^Input, key : string){
    key := map_qwerty_to_keyboard(key)
    if key < 16 do _keyboard[key] = false
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
menu :: proc(using self :^Input){

    _is_game_paused = true
    in_stream := os.stream_from_handle(os.stdin)

    // cleans the 'in_stream' 
    io.flush(in_stream)

    fmt.print("\033[1;1HGame `PAUSED` [q:exit, c:continue]")
    
    valid_option := false
    for !valid_option {
        key, _, err := io.read_rune(in_stream)
        assert(err == nil, "A input failure happened during menu!")
        
        valid_option = true
        switch key{
            case 'q', 'Q':
                _is_game_running = false
                _is_game_paused  = false
            case 'c', 'C':
                _is_game_paused  = false
            case:
                valid_option = false
        }
    }
    fmt.print("\033[1;1H                                  ")
}

@(private)
enable_raw_mode :: proc() {
	_enable_raw_mode()
}

@(private)
disable_raw_mode :: proc() {
	_disable_raw_mode()
}

@(private)
set_utf8_terminal :: proc() {
	_set_utf8_terminal()
}