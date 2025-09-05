package display

import "core:c"
import "core:os"
import "core:fmt"
import "core:mem"
import rl "vendor:raylib"

DISPLAY_WIDTH 	:i32	: 64
DISPLAY_HEIGHT 	:i32	: 32

Pixel :: bool

Display :: struct{
	_canvas				: ^[DISPLAY_WIDTH][DISPLAY_HEIGHT]Pixel,

	// Methods
	display_deinit		: proc(self :^Display),
	display_clear		: proc(self :^Display),
	display_draw		: proc(self: ^Display),
	display_update		: proc(self: ^Display,  x, y: u8, pixel: Pixel) -> (collision: bool)
}

init :: proc() -> ^Display {
	self := new(Display)

	// fields
	self._canvas	 		= new([DISPLAY_WIDTH][DISPLAY_HEIGHT]Pixel)

	// methods
	self.display_deinit		= deinit
	self.display_clear   	= clear
	self.display_draw    	= draw
	self.display_update  	= update

	// init the canvas
	rl.InitWindow(DISPLAY_WIDTH * 10, DISPLAY_HEIGHT * 10, "Chip-8")

	self->display_clear()

	return self
}

deinit :: proc(self: ^Display){
	if self == nil {
		return
	}
	free(self._canvas)
	free(self)

    rl.CloseWindow()
}

@(private)
draw :: proc(self: ^Display) {
	
	fmt.println("Drawing")
	
	rl.BeginDrawing()
	rl.ClearBackground({160, 200, 255, 255})
	
	for y in 0..<DISPLAY_HEIGHT {
		for x in 0..<DISPLAY_WIDTH {
			if self._canvas[x][y] {
				rl.DrawRectangle(x * 10, y * 10, 10, 10, rl.WHITE)
			}
			// fmt.printf("%s", self._canvas[x][y]? "█":" ")
		}
		// fmt.println()
	}
	
	rl.EndDrawing()
}

@(private)
clear :: proc(self: ^Display){
	rl.ClearBackground({160, 200, 255, 255})
	for x in 0..<DISPLAY_WIDTH{
		for y in 0..<DISPLAY_HEIGHT{
			self._canvas[x][y] = false
		}
	}
}

@(private)
update :: proc(self: ^Display,  x, y: u8, pixel: Pixel) -> (collision: bool){
	local_x := x % u8(DISPLAY_WIDTH) 
	local_y := y % u8(DISPLAY_HEIGHT)

	if pixel && self._canvas[local_x][local_y]{
		collision = true
	}
	self._canvas[local_x][local_y] ~= pixel

	return collision
}
