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
	
	// for x in 0..<display.DISPLAY_WIDTH{
	// 	for y in 0..<display.DISPLAY_HEIGHT{
	// 		if y % 2 == x % 2 {
	// 			chip8->display_update(x, y, .On)
	// 			time.sleep(200 * time.Millisecond)
	// 		}
	// 	}
		
	// 	chip8->display_draw()
	// }

	for {
		last_key := chip8->wait_keypress() or_break

		x,y :int
		switch last_key{
			case "w":
				y+=1
			case "s":
				y-=1
			case "d":
				x+=1
			case "a":
				x-=1
		}

		chip8->display_update(x, y, .On)
		chip8->display_draw()
		time.sleep(200 * time.Millisecond)
	}
}