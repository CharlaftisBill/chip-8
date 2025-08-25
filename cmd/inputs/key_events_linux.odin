#+build linux
package inputs

import "core:c"
import "core:os"
import "core:fmt"
import "core:os/os2"
import "core:strings"
import "core:sys/linux"

MAX_DEVICES :: 32

when ODIN_ARCH == .i386 {
    // Assume time64 ABI for modern 32-bit distros
    input_event :: struct {
        sec:   u64,
        usec:  u64,
        type:  u16,
        code:  u16,
        value: i32,
    }
} else {
    timeval :: struct {
        tv_sec:  c.long,
        tv_usec: c.long,
    }

    input_event :: struct {
        time:  timeval,
        type:  u16,
        code:  u16,
        value: i32,
    }
}

@(private)
EVIOCGNAME :: proc(length : int) -> u32 {
    IOC_NRBITS      :: u32(8)
    IOC_TYPEBITS    :: u32(8)
    IOC_SIZEBITS    :: u32(14)
    IOC_DIRBITS     :: u32(2)

    IOC_NRSHIFT     :: u32(0)
    IOC_TYPESHIFT   :: IOC_NRSHIFT + IOC_NRBITS
    IOC_SIZESHIFT   :: IOC_TYPESHIFT + IOC_TYPEBITS
    IOC_DIRSHIFT    :: IOC_SIZESHIFT + IOC_SIZEBITS

    IOC_READ        :: u32(2)

    return (IOC_READ << IOC_DIRSHIFT) |
        (u32('E') << IOC_TYPESHIFT) |
        (u32(0x06) << IOC_NRSHIFT) |
        (u32(length) << IOC_SIZESHIFT)
}

@(private)
key_codes := [186]string {
    "RESERVED",      // 0
    "ESC",           // 1
    "1",             // 2
    "2",             // 3
    "3",             // 4
    "4",             // 5
    "5",             // 6
    "6",             // 7
    "7",             // 8
    "8",             // 9
    "9",             // 10
    "0",             // 11
    "MINUS",         // 12
    "EQUAL",         // 13
    "BACKSPACE",     // 14
    "TAB",           // 15
    "Q",             // 16
    "W",             // 17
    "E",             // 18
    "R",             // 19
    "T",             // 20
    "Y",             // 21
    "U",             // 22
    "I",             // 23
    "O",             // 24
    "P",             // 25
    "LEFTBRACE",     // 26
    "RIGHTBRACE",    // 27
    "ENTER",         // 28
    "LEFTCTRL",      // 29
    "A",             // 30
    "S",             // 31
    "D",             // 32
    "F",             // 33
    "G",             // 34
    "H",             // 35
    "J",             // 36
    "K",             // 37
    "L",             // 38
    "SEMICOLON",     // 39
    "APOSTROPHE",    // 40
    "GRAVE",         // 41
    "LEFTSHIFT",     // 42
    "BACKSLASH",     // 43
    "Z",             // 44
    "X",             // 45
    "C",             // 46
    "V",             // 47
    "B",             // 48
    "N",             // 49
    "M",             // 50
    "COMMA",         // 51
    "DOT",           // 52
    "SLASH",         // 53
    "RIGHTSHIFT",    // 54
    "KPASTERISK",    // 55
    "LEFTALT",       // 56
    "SPACE",         // 57
    "CAPSLOCK",      // 58
    "F1",            // 59
    "F2",            // 60
    "F3",            // 61
    "F4",            // 62
    "F5",            // 63
    "F6",            // 64
    "F7",            // 65
    "F8",            // 66
    "F9",            // 67
    "F10",           // 68
    "NUMLOCK",       // 69
    "SCROLLLOCK",    // 70
    "KP7",           // 71
    "KP8",           // 72
    "KP9",           // 73
    "KPMINUS",       // 74
    "KP4",           // 75
    "KP5",           // 76
    "KP6",           // 77
    "KPPLUS",        // 78
    "KP1",           // 79
    "KP2",           // 80
    "KP3",           // 81
    "KP0",           // 82
    "KPDOT",         // 83
    "UNKNOWN",           // 84 (gap)
    "ZENKAKUHANKAKU", // 85
    "102ND",         // 86
    "F11",           // 87
    "F12",           // 88
    "RO",            // 89
    "KATAKANA",      // 90
    "HIRAGANA",      // 91
    "HENKAN",        // 92
    "KATAKANAHIRAGANA", // 93
    "MUHENKAN",      // 94
    "KPJPCOMMA",     // 95
    "KPENTER",       // 96
    "RIGHTCTRL",     // 97
    "KPSLASH",       // 98
    "SYSRQ",         // 99
    "RIGHTALT",      // 100
    "LINEFEED",      // 101
    "HOME",          // 102
    "UP",            // 103
    "PAGEUP",        // 104
    "LEFT",          // 105
    "RIGHT",         // 106
    "END",           // 107
    "DOWN",          // 108
    "PAGEDOWN",      // 109
    "INSERT",        // 110
    "DELETE",        // 111
    "MACRO",         // 112
    "MUTE",          // 113
    "VOLUMEDOWN",    // 114
    "VOLUMEUP",      // 115
    "POWER",         // 116
    "KPEQUAL",       // 117
    "KPPLUSMINUS",   // 118
    "PAUSE",         // 119
    "SCALE",         // 120
    "KPCOMMA",       // 121
    "HANGEUL",       // 122
    "HANGUEL",       // 123 alias
    "HANJA",         // 124
    "YEN",           // 125
    "LEFTMETA",      // 126
    "RIGHTMETA",     // 127
    "COMPOSE",       // 128
    "STOP",          // 129
    "AGAIN",         // 130
    "PROPS",         // 131
    "UNDO",          // 132
    "FRONT",         // 133
    "COPY",          // 134
    "OPEN",          // 135
    "PASTE",         // 136
    "FIND",          // 137
    "CUT",           // 138
    "HELP",          // 139
    "MENU",          // 140
    "CALC",          // 141
    "SETUP",         // 142
    "SLEEP",         // 143
    "WAKEUP",        // 144
    "FILE",          // 145
    "SENDFILE",      // 146
    "DELETEFILE",    // 147
    "XFER",          // 148
    "PROG1",         // 149
    "PROG2",         // 150
    "WWW",           // 151
    "MSDOS",         // 152
    "COFFEE",        // 153
    "SCREENLOCK",    // 154 alias
    "ROTATE_DISPLAY",// 155
    "DIRECTION",     // 156 alias
    "CYCLEWINDOWS",  // 157
    "MAIL",          // 158
    "BOOKMARKS",     // 159
    "COMPUTER",      // 160
    "BACK",          // 161
    "FORWARD",       // 162
    "CLOSECD",       // 163
    "EJECTCD",       // 164
    "EJECTCLOSECD",  // 165
    "NEXTSONG",      // 166
    "PLAYPAUSE",     // 167
    "PREVIOUSSONG",  // 168
    "STOPCD",        // 169
    "RECORD",        // 170
    "REWIND",        // 171
    "PHONE",         // 172
    "ISO",           // 173
    "CONFIG",        // 174
    "HOMEPAGE",      // 175
    "REFRESH",       // 176
    "EXIT",          // 177
    "MOVE",          // 178
    "EDIT",          // 179
    "SCROLLUP",      // 180
    "SCROLLDOWN",    // 181
    "KPLEFTPAREN",   // 182
    "KPRIGHTPAREN",  // 183
    "NEW",           // 184
    "REDO",          // 185
}

_detect_keyboard :: proc() -> (fd: os.Handle = -1) {
    name    : [256]u8    

    file_infos, err := os2.read_directory_by_path("/dev/input/", MAX_DEVICES, context.allocator)
    assert(err == nil, "could not list devices")

    for file_info in file_infos{
        temp_fd := os.open(file_info.fullpath, os.O_RDONLY) or_continue

        if linux.ioctl(linux.Fd(temp_fd), EVIOCGNAME(size_of(name)), uintptr(&name)) >= 0 {            
            fmt.printf("%s: %s\n", file_info.fullpath, strings.clone_from_bytes(name[:]))

            if strings.contains(strings.to_lower(strings.clone_from_bytes(name[:])), "keyboard"){
                fmt.printf("-> Using %s as keyboard device\n", file_info.fullpath)
                fd = temp_fd
                break
            }
        }
        os.close(temp_fd)
    }
    assert(fd > 0, "No keyboard device found!")

    return fd
}

_keyboard_watcher :: proc(self: ^Input, fd: os.Handle) {
    for {
        buf : [size_of(input_event)]u8

        n, errno := os.read(fd, buf[:])
        if errno == .EINTR do continue
        assert(n > 0, "Error while attempting to read the device")

        assert(size_of(input_event) == n, "Unexpected read size")
        ev := transmute(^input_event) & buf[0]

        if ev.type == 0x01 {
            key_name := key_codes[ev.code]

            if ev.value == 1 {
                self->key_pressed(key_name)
            }else if ev.value == 0 {
                self->key_released(key_name)
            }else if ev.value == 2 {
                // fmt.printf("Key repeated:  %s\n", key_name)
            }
        }
    }
}