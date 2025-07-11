package inputs

import "core:os"
import "core:io"
import "core:fmt"
import "../errors"
import "core:sys/posix"
import "core:unicode/utf8"

KeyboardError :: union {
	os.Error,
    io.Error,
	errors.KeyboardNoKeyMapExistsError,
}

Keyboard ::struct{
    _original_termios: posix.termios,

    // Methods
    inputs_deinit   : proc(^Keyboard),
    wait_keypress   : proc(^Keyboard)-> (mappedKey: rune, err: KeyboardError),
    is_key_pressed  : proc(^Keyboard, rune)-> (bool, KeyboardError)
}

init :: proc() -> ^Keyboard{
    keyboard := new(Keyboard)
    keyboard.wait_keypress  = wait_keypress
    keyboard.is_key_pressed = is_key_pressed
    
    keyboard.inputs_deinit = deinit

    // we ignore the ctrl+c 
    // posix.sigignore(.SIGINT)

    return keyboard
}

deinit :: proc(using self: ^Keyboard){
    free(self)
}


QWERTY :: []rune{
    '1', '2', '3', '4',
    'q', 'w', 'e', 'r',
    'Q', 'W', 'E', 'R',
    'a', 's', 'd', 'f',
    'A', 'S', 'D', 'F',
    'z', 'x', 'c', 'v',
    'Z', 'X', 'C', 'V',
}

COSMAC :: []rune{
    '1', '2', '3', 'C',
    '4', '5', '6', 'D',
    '4', '5', '6', 'D',
    '7', '8', '9', 'E',
    '7', '8', '9', 'E',
    'A', '0', 'B', 'F',
    'A', '0', 'B', 'F',
}

wait_keypress :: proc(self :^Keyboard)-> (mappedKey: rune, err: KeyboardError){
    
    enable_raw_mode()
    
    buf: [1]u8
    in_stream := os.stream_from_handle(os.stdin)
    ch, size := io.read_rune(in_stream) or_return
    
    cosmac := COSMAC
    for qch, i in QWERTY{
        if qch == ch{
            return cosmac[i], nil
        }
    }
    
    disable_raw_mode()
    return self->wait_keypress()
}

is_key_pressed :: proc(self :^Keyboard, key : rune)-> (bool, KeyboardError){
    mappedKey, err := self->wait_keypress()
    return mappedKey == key, err
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