package chip8

import "core:log"
import "core:fmt"
import "../display"

@(private)
decoded_instruction :: struct {
    selector    :   u8,
    X           :   u8,
    Y           :   u8,
    N           :   u8,
    NN          :   u8,
    NNN         :   u16,

    execute     :   proc(self : ^decoded_instruction, inter : ^Chip8)
}

decode :: proc(instruction : Instruction) -> ^decoded_instruction{
    decoded := new(decoded_instruction)
    decoded.selector    =  get_instruction_nibble(instruction, 1)
    decoded.X           =  get_instruction_nibble(instruction, 2)
    decoded.Y           =  get_instruction_nibble(instruction, 3)
    decoded.N           =  get_instruction_nibble(instruction, 4)
    decoded.NN          =  (u8)(instruction & 0x00FF)
    decoded.NNN         =  instruction & 0x0FFF

    // fmt.printfln("%4X -> %X %X %X %X", instruction, decoded.selector, decoded.X, decoded.Y, decoded.N)
    // fmt.printfln("%4X -> ..%2X", instruction, decoded.NN)
    // fmt.printfln("%4X -> .%3X", instruction, decoded.NNN)

    switch decoded.selector{
        case 0x0:
            decoded.execute = zero_decoder
        case 0x1:
            decoded.execute = one_decoder
        case 0x6:
            decoded.execute = six_decoder
        case 0x7:
            decoded.execute = seven_decoder
        case 0xA:
            decoded.execute = alpha_decoder
        case 0xD:
            decoded.execute = delta_decoder
        case:
            log.fatalf("Instructions of type `%Xxxx` are not valid or not yet implemented!", decoded.selector)
    }
    return decoded
}

zero_decoder :: proc(using self : ^decoded_instruction, using inter : ^Chip8){
    assert(selector == 0x0, "`zero_decoder` can be used only if instruction is of type `0xxx`")

    switch NNN{
        case 0x0E0:
            inter->display_clear()
        // case 0x0EE:
        case:
            log.fatalf("Instruction `0%X` is not valid or not yet implemented!", NNN)

    }
}

// 1NNN: jump to NNN
one_decoder :: proc(using self : ^decoded_instruction, using inter : ^Chip8){
    assert(selector == 0x1, "`one_decoder` can be used only if instruction is of type `1xxx`")
    assert(NNN < len(_memory) && NNN >= 512, "Instruction attempting jump into an illegal address")
    _PC = NNN
}

// 6XNN: // 6XNN: set Register vX to NN
six_decoder :: proc(using self : ^decoded_instruction, using inter : ^Chip8){
    assert(selector == 0x6, "`six_decoder` can be used only if instruction is of type `6xxx`")
    assert(X <= (len(_registers) - 1), "Instruction attempting to set a register that exceeds the CHIP-8 spec")

    _registers[X] = NN
}

// 7XNN: set Register vX to vX + NN (not affecting register vF if overflow)
seven_decoder :: proc(using self : ^decoded_instruction, using inter : ^Chip8){
    assert(selector == 0x7, "`seven_decoder` can be used only if instruction is of type `7xxx`")
    assert(X <= (len(_registers) - 1), "Instruction attempting to set a register that exceeds the CHIP-8 spec")

    _registers[X] += NN
}

// ANNN: set Register I to NNN
alpha_decoder :: proc(using self : ^decoded_instruction, using inter : ^Chip8){
    assert(selector == 0xA, "`alpha_decoder` can be used only if instruction is of type `Axxx`")
    _I = NNN
}

// DXYN: Display on coordinates vX, vY the pixels that are in memory locations I..N
delta_decoder :: proc(using self : ^decoded_instruction, using inter : ^Chip8){
    assert(selector == 0xD, "`delta_decoder` can be used only if instruction is of type `Dxxx`")

    x := _registers[X] // & display.DISPLAY_WIDTH	// same as x % 64
	y := _registers[Y] // & display.DISPLAY_HEIGHT	// same as y % 32
    _registers[0xf] = 0

    for sprite_row in 0..<u8(N) {
        // assert(sprite_row < len(_memory),"The sprite row exceeds the memory boundaries")
        sprite := _memory[_I + u16(sprite_row)]

        for cur_bit in 0..<u8(8){
            pixel := (sprite & (0b10000000 >> cur_bit)) != 0

            position_x := cur_bit + x
            position_y := sprite_row + y

            if inter->display_flip_pixel(position_x, position_y, pixel) {
                _registers[0xF] = 1
            }
        }
    }

    // err := inter->display_draw()
    // assert(err == nil, "Problem occurred during graphics rendering")
}