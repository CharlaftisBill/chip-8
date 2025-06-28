package helpers

import "core:os"

get_os_string :: proc() -> string {
    when ODIN_OS == .Windows {
        return "WINDOWS"
    } else when ODIN_OS == .Linux {
        return "LINUX"
    } else when ODIN_OS == .Darwin { // macOS
        return "DARWIN"
    } else when ODIN_OS == .FreeBSD {
        return "FREEBSD"
    } else {
        return "UNKNOWN"
    }
}