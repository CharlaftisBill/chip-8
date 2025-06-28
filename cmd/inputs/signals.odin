package inputs

import "core:os"
import "core:fmt"
import "core:sync"
import "core:sys/posix"

should_quit: bool

@(private)
interrupt_signal_handler :: proc "c" (sig: posix.Signal){
	sync.atomic_store(&should_quit, sig == .SIGINT)
}

@(private)
set_up_interrupt_handler :: proc() -> bool {
	sa: posix.sigaction_t
	sa.sa_handler = interrupt_signal_handler
	posix.sigfillset(&sa.sa_mask)

	return posix.sigaction(.SIGINT, &sa, nil) == posix.result.OK
}


did_interrupted :: proc() -> bool{
	return sync.atomic_load(&should_quit)
}

init :: proc(){
	if !set_up_interrupt_handler() {
		fmt.eprintln("Error: Could not set up signal handler.")
		os.exit(1)
	}
}