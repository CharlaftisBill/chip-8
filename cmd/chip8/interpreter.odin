package chip8

import "../inputs"
import "../display"

import "core:os"
import "core:fmt"
import "core:log"
import "core:time"
import "core:encoding/hex"

Instruction :: u16

interpreter_load :: proc(using self: ^Chip8, path : string) -> (err :os.Error){
    rom_data, ok := os.read_entire_file(path)
    if !ok {
        return .Unknown
    }

    // fmt.println(path, len(rom_data))

    if 512 + len(rom_data) > len(_memory) {
        log.fatal("Rom size exceeds the memory constrains as described in the original CHIP-8 hardware spec")
    }

    for i in 0..<len(rom_data){
        // Original CHIP-8 loaded at 0x000–0x1FF (dec: 0-511); programs start at 0x200 (dec: 512)
        _memory[512 + i] = rom_data[i] 
    }

    return nil
}

interpreter_run :: proc(using self: ^Chip8){
    max_tic_time :: 1250 * time.Millisecond

    for _is_running{
        for _is_paused {}
        
        start := time.now()
        execute(self, decode(fetch(self)))
        elapsed := time.since(start)
        
        remaining := max_tic_time - elapsed
        if remaining > 0 {
            time.sleep(remaining)
        }
    }
}

interpreter_play :: proc(using self: ^Chip8){
    _is_running = true
}

interpreter_pause :: proc(using self: ^Chip8){
    _is_paused = true
}

interpreter_unpause :: proc(using self: ^Chip8){
    _is_paused = false
}

interpreter_stop :: proc(using self: ^Chip8){
    _is_running = false
}

@(private)
fetch :: proc(using self: ^Chip8) -> (instruction : Instruction){
    
    first_half := _memory[_PC]
    second_half := _memory[_PC + 1]

    instruction = combine_2_u8_to_u16(first_half, second_half)
    // fmt.printfln("%d) %02X %02X ->  %04X", _PC, first_half, second_half, instruction)

    _PC += 2

    return instruction
}

@(private)
execute :: proc(self: ^Chip8, using decoded : ^decoded_instruction){
    defer free(decoded)
    decoded->execute(self)
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
stack_push :: proc(self: ^Chip8, element_to_push: u16){
    append(&self._callStack, element_to_push)
}

@(private)
stack_pop :: proc(self: ^Chip8) -> u16{
    return pop(&self._callStack)
}