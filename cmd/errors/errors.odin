package errors

import "core:fmt"
import "../helpers"

NotSupportedPlatformError :: struct{
    platform :   string,
    operation:   string,
    message  :   string,
}

NewNotSupportedPlatformError :: proc(operation: string) -> NotSupportedPlatformError{
    return NotSupportedPlatformError{
        platform    = helpers.get_os_string(),
        operation   = operation,
        message     = "The platform is not supported for this operation",
    }
}

DisplayTerminalSizeError :: struct{
    operation:   string,
    message  :   string,
}

NewDisplayTerminalSizeError :: proc(operation: string) -> DisplayTerminalSizeError{
    return DisplayTerminalSizeError{
        operation   = operation,
        message     = "The terminal width and/or size should be at least w:64xh:32",
    }
}

DisplayTerminalPositionError :: struct{
    x           : int,
    y           : int,
    operation   : string,
    message     : string,
}

NewDisplayTerminalPositionError :: proc(x, y: int, operation: string) -> DisplayTerminalPositionError{
    return DisplayTerminalPositionError{
        x           = x,
        y           = y,
        operation   = operation,
        message     = "The requested position is out of the contexts of the screen",
    }
}

KeyboardNoKeyMapExistsError :: struct{
    operation   : string,
    message     : string,
}

NewKeyboardNoKeyMapExistsError :: proc(operation: string) -> KeyboardNoKeyMapExistsError{
    return KeyboardNoKeyMapExistsError{
        operation   = operation,
        message     = "There is no key mapped to",
    }
}