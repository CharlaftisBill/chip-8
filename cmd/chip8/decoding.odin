package chip8

import "core:log"
import "core:fmt"
import "../display"
import "core:math/rand"

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
        case 0x2:
            decoded.execute = two_decoder
        case 0x3:
            decoded.execute = three_decoder
        case 0x4:
            decoded.execute = four_decoder
        case 0x5:
            decoded.execute = five_decoder
        case 0x6:
            decoded.execute = six_decoder
        case 0x7:
            decoded.execute = seven_decoder
        case 0x8:
            decoded.execute = eight_decoder
        case 0x9:
            decoded.execute = nine_decoder
        case 0xA:
            decoded.execute = alpha_decoder
        case 0xB:
            decoded.execute = beta_decoder
        case 0xC:
            decoded.execute = gamma_decoder
        case 0xD:
            decoded.execute = delta_decoder
        case 0xE:
            decoded.execute = epsilon_decoder
        case 0xF:
            decoded.execute = zeta_decoder
        case:
            log.fatalf("Instructions of type `%Xxxx` are not valid or not yet implemented!", decoded.selector)
    }
    return decoded
}

// 00E0: Clear screen
// 00EE: Return from a subroutine (PC = stack_pop())
zero_decoder :: proc(using self : ^decoded_instruction, using inter : ^Chip8){
    assert(selector == 0x0, "`zero_decoder` can be used only if instruction is of type `0xxx`")

    switch NNN{
        case 0x0E0:
            inter->display_clear()
        case 0x0EE:
            _PC = inter->stack_pop()
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

// 2NNN: calls the subroutine at memory location NNN
two_decoder :: proc(using self : ^decoded_instruction, using inter : ^Chip8){
    assert(selector == 0x2, "`two_decoder` can be used only if instruction is of type `2xxx`")
    assert(NNN < len(_memory) && NNN >= 512, "Instruction attempting jump into an illegal address")
    inter->stack_push(_PC)
    _PC = NNN
}

// 3XNN: skip next instruction if register[X] == NN
three_decoder :: proc(using self : ^decoded_instruction, using inter : ^Chip8){
    assert(selector == 0x3, "`three_decoder` can be used only if instruction is of type `3xxx`")
    if _registers[X] == NN {
        _PC += 2
    }
}

// 4XNN: skip next instruction if register[X] != NN
four_decoder :: proc(using self : ^decoded_instruction, using inter : ^Chip8){
    assert(selector == 0x4, "`four_decoder` can be used only if instruction is of type `4xxx`")
    if _registers[X] != NN {
        _PC += 2
    }
}

// 5XY0: skip next instruction if register[X] == register[Y]
five_decoder :: proc(using self : ^decoded_instruction, using inter : ^Chip8){
    assert(selector == 0x5, "`five_decoder` can be used only if instruction is of type `5xxx`")
    if _registers[X] == _registers[Y] {
        _PC += 2
    }
}

// 6XNN: set Register vX to NN
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

// 8XY0: Set vX = vY
// 8XY1: Set vX = vX  OR vY
// 8XY2: Set vX = vX AND vY
// 8XY3: Set vX = vX XOR vY
// 8XY4: Set vX = vX  +  vY, vF == 1 only if sum overflows
// 8XY5: Set vX = vX  -  vY, vF == 1 only if sub underflow
// 8XY6: Shift vX a bit right (Vx = Vx >> 1), vF == 1 only if shift out bit was 1
// 8XY7: Set vY = vY  -  vX, vF == 1 only if sub underflow
// 8XYE: Shift vX a bit left (Vx = Vx << 1), vF == 1 only if shift out bit was 1
eight_decoder :: proc(using self : ^decoded_instruction, using inter : ^Chip8){
    assert(selector == 0x8, "`eight_decoder` can be used only if instruction is of type `8xxx`")

    switch N {
        case 0:
            _registers[X] = _registers[Y]
        case 1:
            _registers[X] |= _registers[Y]
        case 2:
            _registers[X] &= _registers[Y]
        case 3:
            _registers[X] ~= _registers[Y]
        case 4:
            _registers[X] += _registers[Y]
            _registers[0xF] = 1 if u16(_registers[X]) + u16(_registers[Y]) > 255 else 0
        case 5:
            _registers[0xF] = 1 if _registers[X] > _registers[Y] else 0
            _registers[X] -= _registers[Y]
        case 6:
            sob := _registers[X] << 3
            _registers[0xF] = 1 if sob == 1 else 0
            _registers[X] >>= 1
        case 7:
            _registers[0xF] = 1 if _registers[Y] > _registers[X] else 0
            _registers[X] = _registers[Y] - _registers[X]
        case 0xE:
            sob := _registers[X] & 0b1000
            _registers[0xF] = 1 if sob == 1 else 0
            _registers[X] <<= 1
        case:
            log.fatalf("Instruction `8%X` is not valid or not yet implemented!", NNN)

    }
}

// 9XY0: skip next instruction if register[X] != register[Y]
nine_decoder :: proc(using self : ^decoded_instruction, using inter : ^Chip8){
    assert(selector == 0x9, "`nine_decoder` can be used only if instruction is of type `9xxx`")
    if _registers[X] != _registers[Y] {
        _PC += 2
    }
}

// ANNN: set Register I to NNN
alpha_decoder :: proc(using self : ^decoded_instruction, using inter : ^Chip8){
    assert(selector == 0xA, "`alpha_decoder` can be used only if instruction is of type `Axxx`")
    _I = NNN
}

// BNNN: set Register I to NNN
beta_decoder :: proc(using self : ^decoded_instruction, using inter : ^Chip8){
    assert(selector == 0xb, "`beta_decoder` can be used only if instruction is of type `Bxxx`")
    _PC = u16(_registers[0]) + NNN
}

// CXNN: Random NN
gamma_decoder :: proc(using self : ^decoded_instruction, using inter : ^Chip8){
    assert(selector == 0xA, "`beta_decoder` can be used only if instruction is of type `Bxxx`")
    _registers[0] = u8(rand.int_max(255)) & NN
}

// DXYN: Display on coordinates vX, vY the pixels that are in memory locations I..N
delta_decoder :: proc(using self : ^decoded_instruction, using inter : ^Chip8){
    assert(selector == 0xD, "`delta_decoder` can be used only if instruction is of type `Dxxx`")

    x := _registers[X]
	y := _registers[Y]
    _registers[0xf] = 0

    for sprite_row in 0..<u8(N) {
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
}

// EX9E: skip next instruction if Vx is pressed
// EXA1: skip next instruction if Vx is not pressed
epsilon_decoder :: proc(using self : ^decoded_instruction, using inter : ^Chip8){
    assert(selector == 0xE, "`epsilon_decoder` can be used only if instruction is of type `Exxx`")

    pressed, err := inter->is_key_pressed(_registers[X])
    assert(err == nil, "Error occurred while trying to read keyboard")

    switch N {
        case 0xE:           
            if pressed {
                _PC += 2
            }
        case 0x1:            
            if !pressed {
                _PC += 2
            }
            _PC += 2
        case:
            log.fatalf("Instruction `8%X` is not valid or not yet implemented!", NNN)

    }
}

// FX07: sets Vx = delay_timer
// FX15: sets delay_timer = Vx
// FX18: sets sound_timer = Vx
zeta_decoder :: proc(using self : ^decoded_instruction, using inter : ^Chip8){
    assert(selector == 0xF, "`zeta_decoder` can be used only if instruction is of type `Fxxx`")

    switch NN {
        case 0x07:
            _registers[X] = _delay_timer
        case 0x15:
            _delay_timer = _registers[X]
        case 0x18:
            _sound_timer =_registers[X]
        case 0x1E:
            _I += u16(_registers[X])
            _registers[0xF] = 1 if u32(_I) + u32(_registers[Y]) > 0x0FFF else 0
        case 0x0A:
            pressed, err := inter->wait_keypress()
            assert(err == nil, "Error occurred while waiting to read keyboard")
            _registers[X] = pressed
        case 0x29:
            _I = u16(_memory[u16(_registers[X])])
        case 0x33:
            _memory[_I] = _registers[X] / 100
            _memory[_I + 1] = (_registers[X] / 10) % 10
            _memory[_I + 2] = _registers[X] % 100
        case 0x55:
            for i in 0..=X{
                _memory[_I + u16(i)] = _registers[i]
            }
        case 0x65:
            for i in 0..=X{
                _registers[i] = _memory[_I + u16(i)]
            }
        case:
            log.fatalf("Instruction `8%X` is not valid or not yet implemented!", NNN)

    }
}