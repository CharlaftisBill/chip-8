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
	
	res, err := strings.concatenate({os.get_current_directory(), "/roms/IBM.ch8"})
	if err != nil{
		log.error(err)
	}

	chip8->load(res)
	chip8->play()
	chip8->run()
	
	// drawing_test(chip8)
}

drawing_test :: proc(chip8 : ^chip8.Chip8){
	
	chip8->display_update(0, 0, true)
	chip8->display_update(63, 0, true)
	chip8->display_update(63, 31,true)
	chip8->display_update(0, 31, true)
	chip8->display_draw()

	x : u8 = 0
	y : u8 = 0
	for {
		last_key, err := chip8->wait_keypress()
		if err != nil {
			fmt.println("Error Occurred", err)
			os.exit(1)
		}

		switch last_key{
			case '5':
				y-=1
			case '8':
				y+=1
			case '9':
				x+=1
			case '7':
				x-=1
		}

		chip8->display_update(x, y, true) or_continue
		chip8->display_draw() or_continue
		// time.sleep(60 * time.Millisecond)
	}
}