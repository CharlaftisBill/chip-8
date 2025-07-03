package chip8

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
    _Memory     : [4096]byte,
    _PC         : uint,
    _I          : u16,
    _CallStack  : [dynamic]u16,
    _DelayTimer : u8,
    _SoundTimer : u8,
    _Registers  : [16]byte,
    _Display    : ^display.Display,

    // Methods
    destroy     : proc(self: ^Chip8),
    stack_push  : proc(self: ^Chip8, element_to_push: u16),
    stack_pop   : proc(self: ^Chip8) -> u16,
}

init :: proc() -> ^Chip8{
    chip8 := new(Chip8)
    chip8._CallStack    = make([dynamic]u16)
    chip8._Memory       = [4096]byte{}
    chip8._Registers    = [16]byte{}
    chip8._Display      = display.init()

    // Methods
    chip8.destroy       = deinit
    chip8.stack_push    = stack_push
    chip8.stack_pop     = stack_pop

    // Load FONTS
    for font_sprite, i in FONTS{
        chip8._Memory[i] = font_sprite
    }

    return chip8
}

deinit :: proc(self: ^Chip8){
    delete(self._CallStack)
    self._Display->destroy()
    free(self)
}

stack_push :: proc(self: ^Chip8, element_to_push: u16){
    append(&self._CallStack, 123)
}

stack_pop :: proc(self: ^Chip8) -> u16{
    return pop(&self._CallStack)
}