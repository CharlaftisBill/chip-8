package inputs

import "core:os"
import "../errors"
import "core:sys/posix"

KeyboardError :: union {
	os.Error,
	errors.KeyboardNoKeyMapExistsError,
}

Keyboard ::struct{
    _original_termios: posix.termios,

    // Methods
    inputs_deinit   : proc(^Keyboard),
    wait_keypress   : proc(^Keyboard)-> (mappedKey: string, err: KeyboardError),
    is_key_pressed  : proc(^Keyboard, string)-> (bool, KeyboardError)
}

init :: proc() -> ^Keyboard{
    keyboard := new(Keyboard)
    keyboard.wait_keypress  = wait_keypress
    keyboard.is_key_pressed = is_key_pressed
    
    keyboard.inputs_deinit = deinit

    // we ignore the ctrl+c 
    posix.sigignore(.SIGINT)
    terminal_raw_mode(keyboard)

    return keyboard
}

deinit :: proc(using self: ^Keyboard){
    posix.tcsetattr(posix.STDIN_FILENO, .TCSANOW, &_original_termios)
    free(self)
}

//  |QWERTY   Keyboard|         |Chip-8   Keyboard|
//  || 1 | 2 | 3 | 4 ||         || 1 | 2 | 3 | C ||
//  || Q | W | E | R ||  ====>  || 4 | 5 | 6 | D ||
//  || A | S | D | F ||         || 7 | 8 | 9 | E ||
//  || Z | X | C | V ||         || A | 0 | B | F ||
wait_keypress :: proc(_ :^Keyboard)-> (mappedKey: string, err: KeyboardError){
    
    buf: [1]u8
    bytesRead := os.read(posix.STDIN_FILENO, buf[:]) or_return
    if bytesRead == 0 {
        return "", nil
    }
    
    switch buf[0]{
        case 49:
            mappedKey = "1"
        case 50:
            mappedKey = "2"
        case 51:
            mappedKey = "3"
        case 52:
            mappedKey = "C"
        case 113:
            mappedKey = "4" 
        case 119:
            mappedKey = "5"
        case 101:
            mappedKey = "6"
        case 114:
            mappedKey = "d"
        case 97:
            mappedKey = "7"
        case 115:
            mappedKey = "8"
        case 100:
            mappedKey = "9"
        case 102:
            mappedKey = "e"
        case 122:
            mappedKey = "a"
        case 120:
            mappedKey = "0"
        case 99:
            mappedKey = "b"
        case 118:
            mappedKey = "f"
        case:
            err = errors.NewKeyboardNoKeyMapExistsError("getkeypressed")
    }

    return mappedKey, err
}

is_key_pressed :: proc(self :^Keyboard, key : string)-> (bool, KeyboardError){
    mappedKey, err := self->wait_keypress()
    return mappedKey == key, err
}

@(private)
terminal_raw_mode :: proc(using self: ^Keyboard){
    raw := _original_termios

    // dissable CANNONICAL and ECHO from terminal interface
    raw.c_lflag -=  {.ICANON, .ECHO}

    // minimum number of characters to read
    raw.c_cc[.VMIN] = 0
    // timeout
    raw.c_cc[.VTIME] = 0

    posix.tcsetattr(posix.STDIN_FILENO, .TCSANOW, &raw)
}