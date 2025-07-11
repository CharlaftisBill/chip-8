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
	
	x := 1
	y := 1
	for {

		if x < 0{
			x = 0
		} else if x >= 64{
			x =63
		}

		if y < 0{
			y = 0
		} else if y >= 32{
			y = 31
		}

		chip8->display_update(x, y, .On)
		chip8->display_draw()
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

		time.sleep(60 * time.Millisecond)
	}
}