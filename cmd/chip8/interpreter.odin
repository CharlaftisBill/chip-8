package chip8

import "../inputs"
import "../display"

import "core:os"
import "core:fmt"
import "core:log"
import "core:time"
import "core:thread"
import "core:encoding/hex"

Instruction :: u16

interpreter_load :: proc(inter: ^Chip8, path : string) {
    rom_data, ok := os.read_entire_file(path)
    fmt.assertf(ok,
		"Could not read ROM file '%s'",
		path,
	)

    // fmt.println(path, len(rom_data))
    assert(512 + len(rom_data) <= len(inter._memory), "Rom size exceeds the memory constrains as described in the original CHIP-8 hardware spec")

    for i in 0..<len(rom_data){
        // Original CHIP-8 loaded at 0x000–0x1FF (dec: 0-511); programs start at 0x200 (dec: 512)
        inter._memory[512 + i] = rom_data[i] 
    }
}

// 1250  -> 800 inst/sec
// 2500  -> 400 inst/sec
// 5000  -> 200 inst/sec
// 10000 -> 100 inst/sec
interpreter_run :: proc(inter: ^Chip8){
    max_tic_time :: 2500 * time.Microsecond

    inter._timers_thread = thread.create_and_start_with_poly_data(
        inter,
        tic_timers,
    )

    for inter._is_game_running{
        for inter._is_game_paused {}
        
        start := time.now()
        
        instr := fetch(inter)
        decoded := decode(instr)
        execute(inter, decoded)

        elapsed := time.since(start)
        remaining := max_tic_time - elapsed

        if remaining > 0 {
            time.sleep(remaining)
        }
    }
}

@(private)
tic_timers :: proc(inter: ^Chip8) {
    for inter._is_game_running{
        for inter._is_game_paused {}

        if inter._delay_timer > 0 do inter._delay_timer -= 1

        if inter._sound_timer > 0 {
            fmt.print("\a")
            fmt.printf("\033[1;%dH🔔", display.DISPLAY_WIDTH)
            inter._sound_timer -= 1
        } else {
            fmt.printf("\033[1;%dH ", display.DISPLAY_WIDTH)
        }

        inter->display_draw()
        time.sleep((1000 / 60) * time.Millisecond)
    }
}

@(private)
fetch :: proc(inter: ^Chip8) -> (instruction : Instruction){
    
    first_half := inter._memory[inter._PC]
    second_half := inter._memory[inter._PC + 1]

    instruction = combine_2_u8_to_u16(first_half, second_half)
    // fmt.printfln("%d) %02X %02X ->  %04X", _PC, first_half, second_half, instruction)

    inter._PC += 2

    return instruction
}

@(private)
execute :: proc(inter: ^Chip8, decoded : ^decoded_instruction){
    defer free(decoded)
    decoded->execute(inter)
}

// ------------ Helpers ------------
@(private)
get_instruction_nibble :: proc(instruction : Instruction, position : u16) -> u8{
    assert(position <= 4, "An instruction has always 4 nibbles as hex.")
    shift := (4 - position) << 2
    return (u8)(instruction >> shift) & 0xF
}

@(private)
combine_2_u8_to_u16 :: proc(first_half: u8, second_half: u8) -> u16{
    return ((u16)(first_half) << 8) | (u16)(second_half)
}

@(private)
stack_push :: proc(inter: ^Chip8, element_to_push: u16){
    append(&inter._callStack, element_to_push)
}

@(private)
stack_pop :: proc(inter: ^Chip8) -> u16{
    return pop(&inter._callStack)
}