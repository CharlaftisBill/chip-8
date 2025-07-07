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

main :: proc() {

	chip8 := chip8.init()
	defer chip8->deinit()
	
	inputs.init()

	for x in 0..<display.DISPLAY_WIDTH{
		for y in 0..<display.DISPLAY_HEIGHT{
			if y % 2 == x % 2 {
				chip8->display_update(x, y, .On)
				time.sleep(200 * time.Millisecond)
			}
		}
		
		chip8->display_draw()

		if inputs.did_interrupted(){
			break
		}

	}
}