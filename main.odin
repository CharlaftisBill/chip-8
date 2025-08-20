package main

import "core:log"
import "core:os"
import "core:fmt"
import "cmd/chip8"
import "core:sync"
import "core:time"
import "cmd/inputs"
import "cmd/display"
import "cmd/helpers"
import "core:path/filepath"

// https://tobiasvl.github.io/blog/write-a-chip-8-emulator/
// https://github.com/Timendus/chip8-test-suite
// https://github.com/dch-GH/chip8-odin/blob/main/src/interpreter.odin
// https://johnearnest.github.io/Octo/docs/chip8ref.pdf

// -> Run all test and find why may some instructions failing
// -> Make the timers functional
// -> Make rework the keyboard module. Make `waiting-keypress` proc and `immediate keypress` 
// -> Double the width of the screen during draw function so to be able to use ██ instead of █
// -> Make the application to get parameters from the command line using flags
// -> Expand the opcodes to also support SUPER-CHIP and XO-CHIP
main :: proc() {

	chip8 := chip8.init()
	defer chip8->deinit()
	
	res, err := filepath.join({os.get_current_directory(), "roms/br8kout.ch8"})
	if err != nil{
		log.error(err)
	}

	chip8->load(res)
	chip8->play()
	chip8->run()
}