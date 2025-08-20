package inputs

import "core:io"
import "core:os"
import "core:fmt"
import "../errors"
import "core:thread"
import "core:sys/unix"
import "core:sys/posix"
import "core:unicode/utf8"

KeyboardError :: union {
	os.Error,
    io.Error,
	errors.KeyboardNoKeyMapExistsError,
}

Keyboard ::struct{
    _last_key_press     : u8,
    _original_termios   : posix.termios,

    // Methods
    inputs_deinit   : proc(^Keyboard),
    wait_keypress   : proc(^Keyboard)-> (mappedKey: u8, err: KeyboardError),
    is_key_pressed  : proc(^Keyboard, u8)-> (bool, KeyboardError)
}

init :: proc() -> ^Keyboard{
    keyboard := new(Keyboard)
    keyboard.wait_keypress  = wait_keypress
    keyboard.is_key_pressed = is_key_pressed
    
    keyboard.inputs_deinit = deinit

    thread := thread.create_and_start_with_poly_data(keyboard, watch_last_key_pressed)

    enable_raw_mode()
    return keyboard
}

deinit :: proc(using self: ^Keyboard){
    disable_raw_mode()
    free(self)
}

@(private)
keyboard_map :: proc(qwerty_key : rune) -> (cosmac_key : u8){
    
    cosmac_key = 0xff
    
    switch qwerty_key{
        case '1': cosmac_key = 0x1
        case '2': cosmac_key = 0x2
        case '3': cosmac_key = 0x3
        case '4': cosmac_key = 0xC

        case 'q': cosmac_key = 0x4
        case 'w': cosmac_key = 0x5
        case 'e': cosmac_key = 0x6
        case 'r': cosmac_key = 0xD

        case 'a': cosmac_key = 0x7
        case 's': cosmac_key = 0x8
        case 'd': cosmac_key = 0x9
        case 'f': cosmac_key = 0xE
        
        case 'z': cosmac_key = 0xA
        case 'x': cosmac_key = 0x0
        case 'c': cosmac_key = 0xB
        case 'v': cosmac_key = 0xF
    }

    return cosmac_key
}

wait_keypress :: proc(self :^Keyboard)-> (u8, KeyboardError){
    
    // in_stream := os.stream_from_handle(os.stdin)
    // qwerty_key, size := io.read_rune(in_stream) or_return
    
    // mappedKey = keyboard_map(qwerty_key)

    // fmt.printf("\033[1;1H`wait_keypress `%r->%4X", qwerty_key, mappedKey)

    self._last_key_press = 254
    for self._last_key_press == 254{}
    fmt.printf("\033[1;1H`wait_keypressw`'%r'",  self._last_key_press)

    return self._last_key_press, nil
}

is_key_pressed :: proc(self :^Keyboard, keyNo : u8)-> (found : bool, err : KeyboardError){
    return self._last_key_press == keyNo, err
}


@(private)
watch_last_key_pressed :: proc(self :^Keyboard){
    for true {
        in_stream := os.stream_from_handle(os.stdin)
        qwerty_key, size, err := io.read_rune(in_stream)
        assert(err == nil, "A keyboard failure happened!")        
        self._last_key_press = keyboard_map(qwerty_key)
    }
}

@(private)
enable_raw_mode :: proc() {
	_enable_raw_mode()
}

@(private)
disable_raw_mode :: proc "c" () {
	_disable_raw_mode()
}

@(private)
set_utf8_terminal :: proc() {
	_set_utf8_terminal()
}