package display

import "core:c"
import "core:os"
import "core:fmt"
import "core:mem"
import "../errors"
import psx "core:sys/posix"

DISPLAY_WIDTH 	:: u8(64)
DISPLAY_HEIGHT 	:: u8(32)

@(private)
START_ALTERNATE_SCREEN_BUFFER :: "\033[?1049h"
@(private)
END_ALTERNATE_SCREEN_BUFFER :: "\033[?1049l"

DisplayError :: union {
	errors.NotSupportedPlatformError,
	errors.DisplayTerminalSizeError,
	errors.DisplayTerminalPositionError
}

Pixel :: bool

Display ::struct{
	_canvas			: ^[DISPLAY_WIDTH][DISPLAY_HEIGHT]Pixel,

	// Methods
	display_deinit		: proc(self :^Display),
	display_clear		: proc(self :^Display),
	display_draw		: proc(display :^Display) -> DisplayError,
	display_update		: proc(self :^Display, x, y: u8, turn_to: Pixel) -> (err: DisplayError),
	display_flip_pixel	: proc(using self: ^Display,  x, y: u8, pixel_active: Pixel) -> (collision: bool)
}

init :: proc() -> ^Display{
	// Starts a new screen buffer
	fmt.println(START_ALTERNATE_SCREEN_BUFFER)

	self := new(Display)

	// fields
	self._canvas 		= new([DISPLAY_WIDTH][DISPLAY_HEIGHT]Pixel)
	
	// methods
	self.display_deinit		= deinit
	self.display_clear   	= clear
	self.display_draw    	= draw2
	self.display_update  	= update
	self.display_flip_pixel	= flip_pixel

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
initial_frame_print :: proc() -> (err: DisplayError){
	
	current_width, current_height := get_terminal_size() or_return
	width_offset	:= ((current_width  - DISPLAY_WIDTH)  / 2) - 1
	height_offset	:= ((current_height - DISPLAY_HEIGHT) / 2) - 1
	
	if current_width < DISPLAY_WIDTH || current_height < DISPLAY_HEIGHT {
		return errors.NewDisplayTerminalSizeError("DRAW")
	}

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

	return nil
}

@(private)
draw :: proc(self: ^Display, x, y: u8) -> (err: DisplayError){

	current_width, current_height := get_terminal_size() or_return
	width_offset	:= (current_width  - DISPLAY_WIDTH)  / 2
	height_offset	:= (current_height - DISPLAY_HEIGHT) / 2

	// fmt.printfln("Draw in %d,%d '%v'", x, y, self._canvas[x][y]? "█": " ")

	if self._canvas[x][y]{
		fmt.print("\033[1;1H'█'")
		fmt.printfln("\033[%d;%dH\x1b[97m█\x1b[0m", y + height_offset + 1, x + width_offset + 1)
	} else{
		fmt.print("\033[1;1H' '")
		fmt.printfln("\033[%d;%dH ", y + height_offset + 1, x + width_offset + 1)
	}

	return nil
}

@(private)
draw2 :: proc(self: ^Display) -> (err: DisplayError){

	current_width, current_height := get_terminal_size() or_return
	width_offset	:= (current_width  - DISPLAY_WIDTH)  / 2
	height_offset	:= (current_height - DISPLAY_HEIGHT) / 2

	for y in 0..<DISPLAY_HEIGHT{
		for x in 0..<DISPLAY_WIDTH{
			if self._canvas[x][y]{
				fmt.printfln("\033[%d;%dH\x1b[97m█\x1b[0m", y + height_offset + 1, x + width_offset + 1)
			}
		}
	}
	return nil
}

@(private)
clear :: proc(using self: ^Display){
	for x in 0..<DISPLAY_WIDTH{
		for y in 0..<DISPLAY_HEIGHT{
			_canvas[x][y] = false
		}
	}
}

@(private)
update :: proc(using self: ^Display, x, y: u8, turn_to: Pixel) -> (err: DisplayError){
	if x < 0 || x >= DISPLAY_WIDTH || y < 0 || y >= DISPLAY_HEIGHT{
		return errors.NewDisplayTerminalPositionError(x, y, "update")
	}

	_canvas[x][y] = turn_to

	return nil
}

@(private)
flip_pixel :: proc(using self: ^Display,  x, y: u8, pixel_active: Pixel) -> (collision: bool){
	assert(x < DISPLAY_WIDTH, "The x coordinate exceeds the screen size limit")
	assert(y  < DISPLAY_HEIGHT, "The y coordinate exceeds the screen size limit")
	
	if pixel_active && _canvas[x][y]{
		collision = false
	}

	if pixel_active {
		_canvas[x][y] ~= true
	}

	draw(self, x, y)

	return collision
}

// ---------------- Helpers ----------------
//#region GET_TERMINAL_SIZE
@(private)
get_terminal_size :: proc() -> (width, height: u8, err: DisplayError) {

	ok := true
	when ODIN_OS == .Windows {
		width, height, ok =get_terminal_size_windows()
	} else when ODIN_OS == .Linux || ODIN_OS == .Darwin {
		width, height, ok =get_terminal_size_posix()
	} else {
		ok = false	
	}

	return  width, height, errors.NewNotSupportedPlatformError("GET_TERMINAL_SIZE") if !ok else nil
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