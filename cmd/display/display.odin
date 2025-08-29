package display

import "core:c"
import "core:os"
import "core:fmt"
import "core:mem"
import psx "core:sys/posix"

DISPLAY_WIDTH 	:: u8(64)
DISPLAY_HEIGHT 	:: u8(32)

@(private)
START_ALTERNATE_SCREEN_BUFFER :: "\033[?1049h"
@(private)
END_ALTERNATE_SCREEN_BUFFER :: "\033[?1049l"

Pixel :: bool

Display ::struct{
	_canvas				: ^[DISPLAY_WIDTH][DISPLAY_HEIGHT]Pixel,

	// Methods
	display_deinit		: proc(self :^Display),
	display_clear		: proc(self :^Display),
	display_draw		: proc(self: ^Display),
	display_update		: proc(using self: ^Display,  x, y: u8, pixel: Pixel) -> (collision: bool)
}

init :: proc() -> ^Display{
	// Starts a new screen buffer
	fmt.println(START_ALTERNATE_SCREEN_BUFFER)

	self := new(Display)

	// fields
	self._canvas	 		= new([DISPLAY_WIDTH][DISPLAY_HEIGHT]Pixel)

	// methods
	self.display_deinit		= deinit
	self.display_clear   	= clear
	self.display_draw    	= draw
	self.display_update  	= update

	// Hide cursor
    fmt.println("\033[?25l");

	// init the canvas
	self->display_clear()

	initial_frame_print()

	return self
}

deinit :: proc(self: ^Display){
	if self == nil {
		return
	}
	free(self._canvas)
	free(self)

    // Show cursor before exit
    fmt.println("\033[?25h")

	// Returns to previous screen buffer
	fmt.println(END_ALTERNATE_SCREEN_BUFFER)
}

@(private)
initial_frame_print :: proc(){
	
	current_width, current_height := get_terminal_size()
	width_offset	:= ((current_width  - DISPLAY_WIDTH)  / 2) - 1
	height_offset	:= ((current_height - DISPLAY_HEIGHT) / 2) - 1
	
	fmt.assertf(current_width >= DISPLAY_WIDTH,
		"The Terminal width is '%d', not fitting chip-8's '%d'",
		current_width,
		DISPLAY_WIDTH,
	)

	fmt.assertf(current_height >= DISPLAY_HEIGHT,
		"The Terminal height '%d'is '%d', not fitting chip-8's '%d'",
		current_height,
		DISPLAY_HEIGHT,
	)

	// Clears the terminal
	fmt.print("\x1b[2J\x1b[H")

	// Go to proper terminal point
	fmt.printfln("\033[%d;1H", height_offset)
	horizontal_display_border(width_offset, "╭", "╮")

	for y in height_offset+2..<height_offset + DISPLAY_HEIGHT + 2{
		fmt.printf("\033[%d;%dH\033[32m│\033[0m", y, width_offset + 1)
		fmt.printf("\033[%d;%dH\033[32m│\033[0m", y, width_offset + DISPLAY_WIDTH + 2)
	}
	fmt.println()
	horizontal_display_border(width_offset, "╰", "╯")
}

@(private)
draw :: proc(using self: ^Display) {

	current_width, current_height := get_terminal_size()
	width_offset	:= (current_width  - DISPLAY_WIDTH)  / 2
	height_offset	:= (current_height - DISPLAY_HEIGHT) / 2

	// fmt.printfln("Draw in %d,%d '%v'", x, y, self._canvas[x][y]? "█": " ")
	
	for y in 0..<DISPLAY_HEIGHT {
		for x in 0..<DISPLAY_WIDTH {
			if self._canvas[x][y]{
				fmt.printfln("\033[%d;%dH\x1b[97m█\x1b[0m", y + height_offset + 1, x + width_offset + 1)
			} else{
				fmt.printfln("\033[%d;%dH ", y + height_offset + 1, x + width_offset + 1)
			}
		}
	}	
}

@(private)
clear :: proc(using self: ^Display){
	for x in 0..<DISPLAY_WIDTH{
		for y in 0..<DISPLAY_HEIGHT{
			_canvas[x][y] = false
		}
	}
	// draw(self)
}


@(private)
update :: proc(using self: ^Display,  x, y: u8, pixel: Pixel) -> (collision: bool){
	local_x := x % DISPLAY_WIDTH 
	local_y :=  y % DISPLAY_HEIGHT

	if pixel && _canvas[local_x][local_y]{
		collision = true
	}
	_canvas[local_x][local_y] ~= pixel

	return collision
}

// ---------------- Helpers ----------------
//#region GET_TERMINAL_SIZE
@(private)
get_terminal_size :: proc() -> (width, height: u8) {

	ok := true
	when ODIN_OS == .Windows {
		width, height, ok =get_terminal_size_windows()
	} else when ODIN_OS == .Linux || ODIN_OS == .Darwin {
		width, height, ok =get_terminal_size_posix()
	} else {
		ok = false	
	}
	
	assert(ok, "Failed to get the terminal size")

	return  width, height
}

when ODIN_OS == .Windows {
	foreign import kernel32 "system:kernel32.lib"

	foreign kernel32 {
		GetStdHandle :: proc(nStdHandle: windows.DWORD) -> windows.HANDLE ---
		GetConsoleScreenBufferInfo :: proc(hConsoleOutput: windows.HANDLE, lpConsoleScreenBufferInfo: ^windows.CONSOLE_SCREEN_BUFFER_INFO) -> windows.BOOL ---
	}

	@(private)
	get_terminal_size_windows :: proc() -> (width, height: int, ok: bool) {
		handle := GetStdHandle(windows.STD_OUTPUT_HANDLE)
		if handle == windows.INVALID_HANDLE_VALUE {
			return 0, 0, false
		}

		csbi: windows.CONSOLE_SCREEN_BUFFER_INFO
		if GetConsoleScreenBufferInfo(handle, &csbi) == 0 {
			return 0, 0, false
		}

		width  = int(csbi.srWindow.Right - csbi.srWindow.Left + 1)
		height = int(csbi.srWindow.Bottom - csbi.srWindow.Top + 1)
		return width, height, true
	}
}

when ODIN_OS == .Linux || ODIN_OS == .Darwin {
   
    foreign import libc "system:libc.so.6"

	foreign libc {
		ioctl :: proc(fd: c.int, request: c.ulong,  argp: rawptr) -> c.int ---
	}

	winsize :: struct {
		ws_row:    c.ushort,
		ws_col:    c.ushort,
		ws_xpixel: c.ushort,
		ws_ypixel: c.ushort,
	}

	TIOCGWINSZ :: 0x5413

	@(private)
	get_terminal_size_posix :: proc() -> (width, height: u8, ok: bool) {
		ws: winsize
		
        res := ioctl(cast(c.int)os.stdout, TIOCGWINSZ, &ws)
		if res < 0 {
			return 0, 0, false
		}
		
		return u8(ws.ws_col), u8(ws.ws_row), true
	}
}
//#endregion

//#region GET_TERMINAL_SIZE
@(private)
horizontal_display_border :: proc(width_offset: u8, leftChar, rightChar: string){
	fmt.printf("%*s\033[32m%s\033[0m", width_offset, " ", leftChar)
	for _ in  0..<DISPLAY_WIDTH do fmt.printf("\033[32m─\033[0m")
	fmt.printfln("\033[32m%s\033[0m",rightChar)
}
//#endregion