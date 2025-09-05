package main

import "core:os"
import "core:fmt"
import "cmd/chip8"
import "cmd/inputs"
import "core:path/filepath"

// https://chip8.gulrak.net/
// https://tobiasvl.github.io/blog/write-a-chip-8-emulator/
// https://github.com/Timendus/chip8-test-suite
// https://github.com/dch-GH/chip8-odin/blob/main/src/interpreter.odin
// https://johnearnest.github.io/Octo/docs/chip8ref.pdf
// https://github.com/RaphGL/TermCL/blob/main/platform_posix.odin

// -> Make the application to get parameters from the command line using flags
// -> Make a better menu that (quit, speed, resume, screen-shot, load)
// -> Expand the opcodes to also support SUPER-CHIP and XO-CHIP
main :: proc() {
	chip8 := chip8.init()
	
	res, err := filepath.join({os.get_current_directory(), "roms/6-keypad.ch8"})
	assert(err == nil, "Could not make the path of the rom")
	
	chip8->load(res)
	chip8->run()

	chip8->deinit()

	fmt.println("Thanks for playing!")
	
	os.exit(0)
}