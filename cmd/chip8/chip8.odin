package chip8

import "core:fmt"
import "../inputs"
import "../display"

import "core:os"
import "core:time"
import "core:thread"



FONTS :: [80]u8 {
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
	0xF0, 0x80, 0xF0, 0x80, 0x80  // F
}

Chip8 :: struct{
    _memory         : [4096]byte,
    _PC             : u16,
    _I              : u16,
    _callStack      : [dynamic]u16,
    _delay_timer     : u8,
    _sound_timer     : u8,
    _registers      : [16]byte,

    using _display  : ^display.Display,
    using _input : ^inputs.Input,

    _instr_exec_last_sec    :   u8,
    _last_time_reset        :   time.Time,

    _timers_thread          :    ^thread.Thread,

    // Methods
    deinit      : proc(self: ^Chip8),
    run         : proc(self: ^Chip8),
    load        : proc(self: ^Chip8, path : string),
    stack_push  : proc(self: ^Chip8, element_to_push: u16),
    stack_pop   : proc(self: ^Chip8) -> u16,
}

init :: proc() -> ^Chip8{
    chip8 := new(Chip8)

    chip8._callStack    = make([dynamic]u16)
    chip8._memory       = [4096]byte{}
    chip8._registers    = [16]byte{}
    chip8._PC           = 512

    chip8._input     = inputs.init()
    chip8._display      = display.init()

    // Methods
    chip8.run     = interpreter_run
    chip8.load    = interpreter_load

    chip8.deinit        = deinit
    chip8.stack_push    = stack_push
    chip8.stack_pop     = stack_pop

    // Load FONTS
    for font_sprite, i in FONTS{
        chip8._memory[0x50 + i] = font_sprite
    }

    return chip8
}

deinit :: proc(using self: ^Chip8){
    if self == nil {
		return
	}

    thread.destroy(_timers_thread)

    display_deinit(_display)
    inputs_deinit(_input)

    delete(_callStack)
    free(self)
}