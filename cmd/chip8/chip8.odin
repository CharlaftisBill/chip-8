package chip8

import "../inputs"
import "../display"

FONTS :: [5 * 16]u8 {
    0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
    0x20, 0x60, 0x20, 0x20, 0x70, // 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
    0x90, 0x90, 0xF0, 0x10, 0x10, // 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
    0xF0, 0x10, 0x20, 0x40, 0x40, // 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, // A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
    0xF0, 0x80, 0x80, 0x80, 0xF0, // C
    0xE0, 0x90, 0x90, 0x90, 0xE0, // D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
    0xF0, 0x80, 0xF0, 0x80, 0x80, // F
}

Chip8 :: struct{
    _memory         : [4096]byte,
    _PC             : uint,
    _I              : u16,
    _callStack      : [dynamic]u16,
    _delayTimer     : u8,
    _soundTimer     : u8,
    _registers      : [16]byte,
    using _display  : ^display.Display,
    using _keyboard : ^inputs.Keyboard,

    // Methods
    deinit      : proc(self: ^Chip8),
    stack_push  : proc(self: ^Chip8, element_to_push: u16),
    stack_pop   : proc(self: ^Chip8) -> u16,
}

init :: proc() -> ^Chip8{
    chip8 := new(Chip8)
    chip8._callStack    = make([dynamic]u16)
    chip8._memory       = [4096]byte{}
    chip8._registers    = [16]byte{}
    chip8._display      = display.init()
    chip8._keyboard     = inputs.init()

    // Methods
    chip8.deinit        = deinit
    chip8.stack_push    = stack_push
    chip8.stack_pop     = stack_pop

    // Load FONTS
    for font_sprite, i in FONTS{
        chip8._memory[i] = font_sprite
    }

    return chip8
}

deinit :: proc(using self: ^Chip8){
    delete(_callStack)
    display_deinit(_display)
    inputs_deinit(_keyboard)
    free(self)
}

@(private)
stack_push :: proc(self: ^Chip8, element_to_push: u16){
    append(&self._callStack, 123)
}

@(private)
stack_pop :: proc(self: ^Chip8) -> u16{
    return pop(&self._callStack)
}