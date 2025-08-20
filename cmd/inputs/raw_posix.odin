#+build !windows
package inputs

import psx "core:sys/posix"
import "core:mem"

@(private="file")
orig_mode: psx.termios

_enable_raw_mode :: proc() {
	// Get the original terminal attributes.
	res := psx.tcgetattr(psx.STDIN_FILENO, &orig_mode)
	assert(res == .OK)

	raw : psx.termios
	mem.copy(&raw, &orig_mode, size_of(raw))
	
	psx.atexit(disable_raw_mode)

	// ECHO (so what is typed is not shown) and
	// ICANON (so we get each input instead of an entire line at once) flags.	
	raw.c_lflag = raw.c_lflag - {.ECHO, .ICANON}
	res = psx.tcsetattr(psx.STDIN_FILENO, .TCSANOW, &raw)
	assert(res == .OK)
}

_disable_raw_mode :: proc "c" () {
	psx.tcsetattr(psx.STDIN_FILENO, .TCSANOW, &orig_mode)
}

_set_utf8_terminal :: proc() {}
