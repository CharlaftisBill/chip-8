package main

import "core:os"
import "core:fmt"
import "core:sync"
import "core:time"
import "cmd/inputs"
import "cmd/display"
import "cmd/helpers"

// https://tobiasvl.github.io/blog/write-a-chip-8-emulator/
// https://github.com/dch-GH/chip8-odin/blob/main/src/interpreter.odin

main :: proc() {
	dis :=display.init()
	defer dis->destroy()

	inputs.init()

	for x in 0..<display.DISPLAY_WIDTH{
		for y in 0..<display.DISPLAY_HEIGHT{
			if x == y{
				dis->update(x, y, .On)
				dis->draw()
				time.sleep(200 * time.Millisecond)
				// dis->clear()
			}
		}

		if inputs.did_interrupted(){
			break
		}

	}

	dis->clear()

	for x in 0..<display.DISPLAY_WIDTH{
		for y in 0..<display.DISPLAY_HEIGHT{
			if y %2 ==0{
				dis->update(x, y, .On)
				dis->draw()
				time.sleep(200 * time.Millisecond)
				// dis->clear()
			}
		}

		if inputs.did_interrupted(){
			break
		}

	}
}