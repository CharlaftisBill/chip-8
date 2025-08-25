package inputs

import "core:io"
import "core:os"
import "core:fmt"
import "../errors"
import "core:thread"
import "core:sys/unix"
import "core:sys/posix"
import "core:unicode/utf8"

InputError :: union {
	os.Error,
    io.Error,
	errors.InputNoKeyMapExistsError,
}

Input ::struct{
    _is_game_running         :   bool,
    _is_game_paused          :   bool,

    _original_termios        : posix.termios,

    _keyboard                       :  [17]bool,    // location with index 16 is for not valid key
    _last_key_pressed               : u8,
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

    input._watch_last_key_pressed_thread = thread.create_and_start_with_poly_data(
        input,
        watch_last_key_pressed,
    )

    // input._last_key_press       = 254
    // input._last_key_released    = 254
    when ODIN_OS == .Linux{
        fd := _detect_keyboard()
	    _keyboard_watcher(input, fd)
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
map_cosmac_to_keyboard :: proc(cosmac_key : u8) -> (keyboard_index : u8 = 16){    

    switch keyboard_index{
        case 0x1 : keyboard_index = 0     // 0x1
        case 0x2 : keyboard_index = 1     // 0x2
        case 0x3 : keyboard_index = 2     // 0x3
        case 0xC : keyboard_index = 3     // 0xC
        case 0x4 : keyboard_index = 4     // 0x4
        case 0x5 : keyboard_index = 5     // 0x5
        case 0x6 : keyboard_index = 6     // 0x6
        case 0xD : keyboard_index = 7     // 0xD
        case 0x7 : keyboard_index = 8     // 0x7
        case 0x8 : keyboard_index = 9     // 0x8
        case 0x9 : keyboard_index = 10    // 0x9
        case 0xE : keyboard_index = 11    // 0xE
        case 0xA : keyboard_index = 12    // 0xA
        case 0x0 : keyboard_index = 13    // 0x0
        case 0xB : keyboard_index = 14    // 0xB
        case 0xF : keyboard_index = 15    // 0xF
    }

    return keyboard_index
}

// if keyboard_index is 16 then the given `qwerty_key` cannot be matched 
@(private)
map_qwerty_to_keyboard :: proc(qwerty_key : string) -> (keyboard_index : u8 = 16){    

    switch qwerty_key{
        case "1": keyboard_index = 0     // 0x1 
        case "2": keyboard_index = 1     // 0x2 
        case "3": keyboard_index = 2     // 0x3 
        case "4": keyboard_index = 3     // 0xC 
        case "Q": keyboard_index = 4     // 0x4 
        case "W": keyboard_index = 5     // 0x5 
        case "E": keyboard_index = 6     // 0x6 
        case "R": keyboard_index = 7     // 0xD 
        case "A": keyboard_index = 8     // 0x7 
        case "S": keyboard_index = 9     // 0x8 
        case "D": keyboard_index = 10    // 0x9
        case "F": keyboard_index = 11    // 0xE
        case "Z": keyboard_index = 12    // 0xA
        case "X": keyboard_index = 13    // 0x0
        case "C": keyboard_index = 14    // 0xB
        case "V": keyboard_index = 15    // 0xF
    }
    return keyboard_index
}

@(private)
map_qwerty_to_cosmac :: proc(qwerty_key : string) -> (cosmac_key : u8 = 16){    

    switch qwerty_key{
        case "1": cosmac_key = 0x1 
        case "2": cosmac_key = 0x2 
        case "3": cosmac_key = 0x3 
        case "4": cosmac_key = 0xC 
        case "Q": cosmac_key = 0x4 
        case "W": cosmac_key = 0x5 
        case "E": cosmac_key = 0x6 
        case "R": cosmac_key = 0xD 
        case "A": cosmac_key = 0x7 
        case "S": cosmac_key = 0x8 
        case "D": cosmac_key = 0x9
        case "F": cosmac_key = 0xE
        case "Z": cosmac_key = 0xA
        case "X": cosmac_key = 0x0
        case "C": cosmac_key = 0xB
        case "V": cosmac_key = 0xF
    }
    return cosmac_key
}

@(private)
key_pressed :: proc(using self: ^Input, key : string){
    self._last_key_pressed = map_qwerty_to_keyboard(key) 
    _keyboard[map_qwerty_to_cosmac(key)] = true
}

@(private)
key_released :: proc(using self: ^Input, key : string){
    _keyboard[map_qwerty_to_keyboard(key)] = false
}

wait_keypress :: proc(self :^Input)-> u8{

    self._last_key_pressed = 16
    for self._last_key_pressed == 16 {}
    // fmt.printf("\033[1;1H`wait_keypress`'%r'",  self._last_key_press)

    return self._last_key_pressed
}

is_key_pressed :: proc(self :^Input, keyNo : u8)-> (found : bool){
    fmt.printf("\033[2;1H wanted '%4X'.", keyNo)
    return self._keyboard[map_cosmac_to_keyboard(keyNo)]
}

@(private)
watch_last_key_pressed :: proc(using self :^Input){

    for _is_game_running {
        in_stream := os.stream_from_handle(os.stdin)
        key, _, err := io.read_rune(in_stream)
        assert(err == nil, "A input failure happened!")

       if key == ' ' {
           _is_game_paused = true
           fmt.print("\033[1;1HGame `PAUSED` [q:exit, c:continue]")
            
           valid_option := false
            for !valid_option {
                key, _, err = io.read_rune(in_stream)
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

        // _last_key_pressed = input_map(key)
    }
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