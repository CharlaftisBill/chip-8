package main

import "core:os"
import "core:fmt"
import "cmd/chip8"
import "core:sync"
import "core:time"
import "cmd/inputs"
import "cmd/display"
import "cmd/helpers"

// https://tobiasvl.github.io/blog/write-a-chip-8-emulator/
// https://github.com/dch-GH/chip8-odin/blob/main/src/interpreter.odin
// https://johnearnest.github.io/Octo/docs/chip8ref.pdf

main :: proc() {

	chip8 := chip8.init()
	defer chip8->deinit()
	
	chip8->display_update(0, 0, .On)
	chip8->display_update(63, 0, .On)
	chip8->display_update(63, 31, .On)
	chip8->display_update(0, 31, .On)
	chip8->display_draw()

	x := 0
	y := 0
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

		chip8->display_update(x, y, .On) or_continue
		chip8->display_draw() or_continue
		// time.sleep(60 * time.Millisecond)
	}
}