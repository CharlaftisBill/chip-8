#+build !windows
package inputs

import "core:bytes"
import "core:mem"
import "core:fmt"
import posix "core:sys/posix"

@(private="file")
orig_mode: posix.termios

_enable_raw_mode :: proc() {

	res := posix.tcgetattr(posix.STDIN_FILENO, &orig_mode)
	assert(res == .OK)

	ok := posix.tcgetattr(posix.STDIN_FILENO, &orig_mode) == .OK
	assert(ok, "Failed to get the current terminal state")

	raw : posix.termios
	ok = posix.tcgetattr(posix.STDIN_FILENO, &raw) == .OK
	assert(ok, "Failed to get the raw terminal state")
	
	// ECHO (so what is typed is not shown) and
	// ICANON (so we get each input instead of an entire line at once) flags.	
	raw.c_lflag -= {.ECHO, .ICANON, .ISIG, .IEXTEN}

	res = posix.tcsetattr(posix.STDIN_FILENO, .TCSAFLUSH, &raw)
	assert(res == .OK, "failed to set new terminal state")
}

_disable_raw_mode :: proc () {
	res := posix.tcsetattr(posix.STDIN_FILENO, .TCSAFLUSH, &orig_mode)
	assert(res == .OK, "failed to set new terminal state")
}

_set_utf8_terminal :: proc() {}
