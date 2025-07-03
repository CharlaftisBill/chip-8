package display

import "core:c"
import "core:os"
import "core:fmt"
import "core:mem"
import "../errors"

DISPLAY_WIDTH 	:: 64
DISPLAY_HEIGHT 	:: 32

@(private)
START_ALTERNATE_SCREEN_BUFFER :: "\033[?1049h"
@(private)
END_ALTERNATE_SCREEN_BUFFER :: "\033[?1049l"

DisplayError :: union {
	errors.NotSupportedPlatformError,
	errors.DisplayTerminalSizeError,
	errors.DisplayTerminalPositionError
}

Pixel :: enum{
	Off,	// Pixel is off
	Dim, 	// Pixel was On and in next refresh should be off
	On, 	// Pixel is not off
}

Display ::struct{
	_canvas			: ^[DISPLAY_WIDTH][DISPLAY_HEIGHT]Pixel,

	// Methods
	destroy  : proc(self :^Display),
	clear    : proc(self :^Display),
	draw  	 : proc(display :^Display) -> DisplayError,
	update 	 : proc(self :^Display, x, y: int, turn_to: Pixel) -> (err: DisplayError)
}

init :: proc() -> ^Display{
	// Starts a new screen buffer
	fmt.println(START_ALTERNATE_SCREEN_BUFFER)

	self := new(Display)

	// fields
	self._canvas 		= new([DISPLAY_WIDTH][DISPLAY_HEIGHT]Pixel)
	// methods
	self.destroy = deinit
	self.clear   = clear
	self.draw    = draw2
	self.update  = update

	// Hide cursor
    fmt.println("\033[?25l");

	self->clear()
	return self
}

deinit :: proc(self: ^Display){
	if self == nil {
		return
	}
	free(self._canvas)
	free(self)


    // Show cursor before exit
    fmt.println("\033[?25h");

	// Returns to previous screen buffer
	fmt.println(END_ALTERNATE_SCREEN_BUFFER)
}

@(private)
draw :: proc(self: ^Display) -> (err: DisplayError){

	current_width, current_height := get_terminal_size() or_return
	width_offset	:= (current_width - DISPLAY_WIDTH) / 2
	height_offset	:= (current_height - DISPLAY_HEIGHT) / 2
	
	if current_width < DISPLAY_WIDTH || current_height < DISPLAY_HEIGHT {
		return errors.NewDisplayTerminalSizeError("DRAW")
	}

	// Clears the terminal
	fmt.print("\x1b[2J\x1b[H")

	// to center vertically
	for _ in  0..=height_offset do fmt.println()
	
	for y in 0..<DISPLAY_HEIGHT{
		// to center horizontally
		fmt.printf("%*s%s", width_offset, " ", "\x1b[90m█\x1b[0m")

		for x in 0..<DISPLAY_WIDTH{

			switch self._canvas[x][y]{
				case .On:
					fmt.printf("\x1b[97m█\x1b[0m")
				case .Dim:
					fmt.printf("\x1b[90m█\x1b[0m")
				case .Off:
					fmt.printf("\x1b[30m█\x1b[0m")
			}
		}
		fmt.println()
	}
	return nil
}

@(private)
draw2 :: proc(self: ^Display) -> (err: DisplayError){

	current_width, current_height := get_terminal_size() or_return
	width_offset	:= (current_width - DISPLAY_WIDTH) / 2
	height_offset	:= (current_height - DISPLAY_HEIGHT) / 2
	
	if current_width < DISPLAY_WIDTH || current_height < DISPLAY_HEIGHT {
		return errors.NewDisplayTerminalSizeError("DRAW")
	}

	// Clears the terminal
	fmt.print("\x1b[2J\x1b[H")
	
	for y in 0..<current_height{

		if y < height_offset || (y - height_offset) > DISPLAY_HEIGHT{
			// for _ in  0..<current_width do fmt.printf("\x1b[90m█\x1b[0m")
			fmt.println()
			continue
		}else if y == height_offset{
			horizontal_display_border(width_offset, "┌", "┐")
			continue
		}else if (y - height_offset) == DISPLAY_HEIGHT{
			horizontal_display_border(width_offset, "└", "┘")
			continue
		}

		for x in 0..<current_width{
			if x < width_offset || (x - width_offset) > DISPLAY_WIDTH{
				fmt.printf(" ")
				continue
			}else if x == width_offset || (x - width_offset) == DISPLAY_WIDTH{
				fmt.printf("\033[32m│\033[0m")
				continue
			}

			// fmt.printfln("'%d'", x - width_offset)
			switch self._canvas[x - width_offset][y - height_offset]{
				case .On:
					fmt.printf("\x1b[97m█\x1b[0m")
				case .Dim:
					fmt.printf("\x1b[90m█\x1b[0m")
				case .Off:
					fmt.printf("\x1b[30m█\x1b[0m")
			}
		}
		fmt.println()
	}

	return nil
}

@(private)
clear :: proc(self: ^Display){
	for x in 0..<DISPLAY_WIDTH{
		for y in 0..<DISPLAY_HEIGHT{
			if self._canvas[x][y] == .On{
				self._canvas[x][y] = .Dim
			} else if self._canvas[x][y] == .Dim{
				self._canvas[x][y] = .Off
			}
		}
	}
}

@(private)
update :: proc(self: ^Display, x, y: int, turn_to: Pixel) -> (err: DisplayError){
	if x < 0 || x >= DISPLAY_WIDTH || y < 0 || y >= DISPLAY_HEIGHT{
		return errors.NewDisplayTerminalPositionError(x, y, "update")
	}

	if turn_to == .Off{
		if self._canvas[x][y] == .On{
			self._canvas[x][y] = .Dim
		} else if self._canvas[x][y] == .Dim{
			self._canvas[x][y] = .Off
		}
	}else {
		self._canvas[x][y] = turn_to		
	}

	return nil
}

// ---------------- Helpers ----------------
//#region GET_TERMINAL_SIZE
@(private)
get_terminal_size :: proc() -> (width, height: int, err: DisplayError) {

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
	get_terminal_size_posix :: proc() -> (width, height: int, ok: bool) {
		ws: winsize
		
        res := ioctl(cast(c.int)os.stdout, TIOCGWINSZ, &ws)
		if res < 0 {
			return 0, 0, false
		}
		
		return int(ws.ws_col), int(ws.ws_row), true
	}
}
//#endregion

//#region GET_TERMINAL_SIZE
@(private)
horizontal_display_border :: proc(width_offset: int, leftChar, rightChar: string){
	fmt.printf("%*s\033[32m%s\033[0m", width_offset, " ", leftChar)
	for _ in  0..<DISPLAY_WIDTH-1 do fmt.printf("\033[32m─\033[0m")
	fmt.printfln("\033[32m%s\033[0m",rightChar)
}
//#endregion