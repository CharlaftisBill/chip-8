package chip8

import "../display"

import "core:fmt"
import "core:log"
import "core:math/rand"

@(private)
decoded_instruction :: struct {
	selector: u8,
	X:        u8,
	Y:        u8,
	N:        u8,
	NN:       u8,
	NNN:      u16,
	execute:  proc(self: ^decoded_instruction, inter: ^Chip8),
}

decode :: proc(instruction: Instruction) -> ^decoded_instruction {
	decoded := new(decoded_instruction)
	decoded.selector = get_instruction_nibble(instruction, 1)
	decoded.X = get_instruction_nibble(instruction, 2)
	decoded.Y = get_instruction_nibble(instruction, 3)
	decoded.N = get_instruction_nibble(instruction, 4)
	decoded.NN = (u8)(instruction & 0x00FF)
	decoded.NNN = instruction & 0x0FFF

	// fmt.printfln("%4X -> %X %X %X %X", instruction, decoded.selector, decoded.X, decoded.Y, decoded.N)
	// fmt.printfln("%4X -> ..%2X", instruction, decoded.NN)
	// fmt.printfln("%4X -> .%3X", instruction, decoded.NNN)

	switch decoded.selector {
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
		log.fatalf(
			"Instructions of type `%Xxxx` are not valid or not yet implemented!",
			decoded.selector,
		)
	}
	return decoded
}

// 00E0: Clear screen
// 00EE: Return from a subroutine (PC = stack_pop())
zero_decoder :: proc(self: ^decoded_instruction, inter: ^Chip8) {
	assert(self.selector == 0x0, "`zero_decoder` can be used only if instruction is of type `0xxx`")

	switch self.NNN {
	case 0x0E0:
		inter->display_clear()
	case 0x0EE:
		inter._PC = inter->stack_pop()
	case:
		log.fatalf("Instruction `0%X` is not valid or not yet implemented!", self.NNN)
	}
}

// 1NNN: jump to NNN
one_decoder :: proc(self: ^decoded_instruction, inter: ^Chip8) {
	assert(self.selector == 0x1, "`one_decoder` can be used only if instruction is of type `1xxx`")
	assert(self.NNN < len(inter._memory) && self.NNN >= 512, "Instruction attempting jump into an illegal address")
	inter._PC = self.NNN
}

// 2NNN: calls the subroutine at memory location NNN
two_decoder :: proc(self: ^decoded_instruction, inter: ^Chip8) {
	assert(self.selector == 0x2, "`two_decoder` can be used only if instruction is of type `2xxx`")
	assert(self.NNN < len(inter._memory) && self.NNN >= 512, "Instruction attempting jump into an illegal address")
	inter->stack_push(inter._PC)
	inter._PC = self.NNN
}

// 3XNN: skip next instruction if register[X] == NN
three_decoder :: proc(self: ^decoded_instruction, inter: ^Chip8) {
	assert(self.selector == 0x3, "`three_decoder` can be used only if instruction is of type `3xxx`")
	if inter._registers[self.X] == self.NN {
		inter._PC += 2
	}
}

// 4XNN: skip next instruction if register[X] != NN
four_decoder :: proc(self: ^decoded_instruction, inter: ^Chip8) {
	assert(self.selector == 0x4, "`four_decoder` can be used only if instruction is of type `4xxx`")
	if inter._registers[self.X] != self.NN {
		inter._PC += 2
	}
}

// 5XY0: skip next instruction if register[X] == register[Y]
five_decoder :: proc(self: ^decoded_instruction, inter: ^Chip8) {
	assert(self.selector == 0x5, "`five_decoder` can be used only if instruction is of type `5xxx`")
	if inter._registers[self.X] == inter._registers[self.Y] {
		inter._PC += 2
	}
}

// 6XNN: set Register vX to NN
six_decoder :: proc(self: ^decoded_instruction, inter: ^Chip8) {
	assert(self.selector == 0x6, "`six_decoder` can be used only if instruction is of type `6xxx`")
	assert(
		self.X <= (len(inter._registers) - 1),
		"Instruction attempting to set a register that exceeds the CHIP-8 spec",
	)

	inter._registers[self.X] = self.NN
}

// 7XNN: set Register vX to vX + NN (not affecting register vF if overflow)
seven_decoder :: proc(self: ^decoded_instruction, inter: ^Chip8) {
	assert(self.selector == 0x7, "`seven_decoder` can be used only if instruction is of type `7xxx`")
	assert(
		self.X <= (len(inter._registers) - 1),
		"Instruction attempting to set a register that exceeds the CHIP-8 spec",
	)

	inter._registers[self.X] += self.NN
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
eight_decoder :: proc(self: ^decoded_instruction, inter: ^Chip8) {
	assert(self.selector == 0x8, "`eight_decoder` can be used only if instruction is of type `8xxx`")

	switch self.N {
	case 0:
		inter._registers[self.X] = inter._registers[self.Y]
	case 1:
		inter._registers[self.X] |= inter._registers[self.Y]
	case 2:
		inter._registers[self.X] &= inter._registers[self.Y]
	case 3:
		inter._registers[self.X] ~= inter._registers[self.Y]
	case 4:
		flag := u16(inter._registers[self.X]) + u16(inter._registers[self.Y]) >= 255
		inter._registers[self.X] += inter._registers[self.Y]
		inter._registers[0xF] = 1 if flag else 0
	case 5:
		flag := inter._registers[self.X] >= inter._registers[self.Y]
		inter._registers[self.X] -= inter._registers[self.Y]
		inter._registers[0xF] = 1 if flag else 0
	case 6:
		flag := inter._registers[self.X] & 0x1
		inter._registers[self.X] >>= 1
		inter._registers[0xF] = 1 if flag == 1 else 0
	case 7:
		flag := inter._registers[self.Y] >= inter._registers[self.X]
		inter._registers[self.X] = inter._registers[self.Y] - inter._registers[self.X]
		inter._registers[0xF] = 1 if flag else 0
	case 0xE:
		flag := (inter._registers[self.X] >> 7) & 0x1
		inter._registers[self.X] <<= 1
		inter._registers[0xF] = 1 if flag == 1 else 0
	case:
		log.fatalf("Instruction `8%X` is not valid or not yet implemented!", self.NNN)
	}
}

// 9XY0: skip next instruction if register[X] != register[Y]
nine_decoder :: proc(self: ^decoded_instruction, inter: ^Chip8) {
	assert(self.selector == 0x9, "`nine_decoder` can be used only if instruction is of type `9xxx`")
	if inter._registers[self.X] != inter._registers[self.Y] {
		inter._PC += 2
	}
}

// ANNN: set Register I to NNN
alpha_decoder :: proc(self: ^decoded_instruction, inter: ^Chip8) {
	assert(self.selector == 0xA, "`alpha_decoder` can be used only if instruction is of type `Axxx`")
	inter._I = self.NNN
}

// BNNN: set Register I to NNN
beta_decoder :: proc(self: ^decoded_instruction, inter: ^Chip8) {
	assert(self.selector == 0xb, "`beta_decoder` can be used only if instruction is of type `Bxxx`")
	inter._PC = u16(inter._registers[0]) + self.NNN
}

// CXNN: Random NN
gamma_decoder :: proc(self: ^decoded_instruction, inter: ^Chip8) {
	assert(self.selector == 0xC, "`gamma_decoder` can be used only if instruction is of type `Cxxx`")
	inter._registers[0] = u8(rand.int_max(255)) & self.NN
}

// DXYN: Display on coordinates vX, vY the pixels that are in memory locations I..N
delta_decoder :: proc(self: ^decoded_instruction, inter: ^Chip8) {
	assert(self.selector == 0xD, "`delta_decoder` can be used only if instruction is of type `Dxxx`")

	col := inter._registers[self.X]
	row := inter._registers[self.Y]
	inter._registers[0xf] = 0

	for byte_index in 0 ..< u8(self.N) {
		sprite := inter._memory[inter._I + u16(byte_index)]

		for bit_index in 0 ..< u8(8) {
			pixel := ((sprite >> bit_index) & 0x1) == 1

			if inter->display_update((col + (7 - bit_index)), (row + byte_index), pixel) {
				inter._registers[0xF] = 1
			}
		}
	}

	// inter->display_draw()
}

// EX9E: skip next instruction if Vx is pressed
// EXA1: skip next instruction if Vx is not pressed
epsilon_decoder :: proc(self: ^decoded_instruction,inter: ^Chip8) {
	assert(self.selector == 0xE, "`epsilon_decoder` can be used only if instruction is of type `Exxx`")

	pressed := inter->is_key_pressed(inter._registers[self.X])
	switch self.N {
	case 0xE:
		if pressed {
			inter._PC += 2
		}
	case 0x1:
		if !pressed {
			inter._PC += 2
		}
	case:
		log.fatalf("Instruction `8%X` is not valid or not yet implemented!", self.NNN)
	}
}

// FX07: sets Vx = delay_timer
// FX15: sets delay_timer = Vx
// FX18: sets sound_timer = Vx
zeta_decoder :: proc(self: ^decoded_instruction, inter: ^Chip8) {
	assert(self.selector == 0xF, "`zeta_decoder` can be used only if instruction is of type `Fxxx`")

	switch self.NN {
	case 0x07:
		inter._registers[self.X] = inter._delay_timer
	case 0x15:
		inter._delay_timer = inter._registers[self.X]
	case 0x18:
		inter._sound_timer = inter._registers[self.X]
	case 0x1E:
		inter._I += u16(inter._registers[self.X])
		inter._registers[0xF] = 1 if u32(inter._I) + u32(inter._registers[self.Y]) > 0x0FFF else 0
	case 0x0A:
		pressed := inter->wait_keypress()
		if pressed < 16 {
			inter._registers[self.X] = pressed	
		} else{
			inter._PC -= 2
		}
	case 0x29:
		inter._I = 0x50 + u16(5 * u16(inter._registers[self.X]))
	case 0x33:
		value := inter._registers[self.X]

		inter._memory[inter._I + 2] = value % 10
		value /= 10

		inter._memory[inter._I + 1] = value % 10
		value /= 10

		inter._memory[inter._I] = value % 10
	case 0x55:
		for i in 0 ..= self.X {
			inter._memory[inter._I + u16(i)] = inter._registers[i]
		}
	case 0x65:
		for i in 0 ..= self.X {
			inter._registers[i] = inter._memory[inter._I + u16(i)]
		}
	case:
		log.fatalf("Instruction `8%X` is not valid or not yet implemented!", self.NNN)
	}
}
