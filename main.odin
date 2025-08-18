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
import "core:strings"

// https://tobiasvl.github.io/blog/write-a-chip-8-emulator/
// https://github.com/dch-GH/chip8-odin/blob/main/src/interpreter.odin
// https://johnearnest.github.io/Octo/docs/chip8ref.pdf

main :: proc() {

	chip8 := chip8.init()
	defer chip8->deinit()
	
	res, err := strings.concatenate({os.get_current_directory(), "/roms/BC_test.ch8"})
	if err != nil{
		log.error(err)
	}

	chip8->load(res)
	chip8->play()
	chip8->run()
	
}