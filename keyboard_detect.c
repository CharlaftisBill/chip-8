#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <linux/input.h>
#include <string.h>
#include <sys/ioctl.h>
#include <errno.h>

#define MAX_DEVICES 32

// Map some common key codes to names
const char* keycode_to_name(int code) {
    switch (code) {
        case KEY_A: return "A";
        case KEY_B: return "B";
        case KEY_C: return "C";
        case KEY_D: return "D";
        case KEY_E: return "E";
        case KEY_F: return "F";
        case KEY_G: return "G";
        case KEY_H: return "H";
        case KEY_I: return "I";
        case KEY_J: return "J";
        case KEY_K: return "K";
        case KEY_L: return "L";
        case KEY_M: return "M";
        case KEY_N: return "N";
        case KEY_O: return "O";
        case KEY_P: return "P";
        case KEY_Q: return "Q";
        case KEY_R: return "R";
        case KEY_S: return "S";
        case KEY_T: return "T";
        case KEY_U: return "U";
        case KEY_V: return "V";
        case KEY_W: return "W";
        case KEY_X: return "X";
        case KEY_Y: return "Y";
        case KEY_Z: return "Z";
        case KEY_1: return "1";
        case KEY_2: return "2";
        case KEY_3: return "3";
        case KEY_4: return "4";
        case KEY_5: return "5";
        case KEY_6: return "6";
        case KEY_7: return "7";
        case KEY_8: return "8";
        case KEY_9: return "9";
        case KEY_0: return "0";
        case KEY_ENTER: return "Enter";
        case KEY_ESC: return "Escape";
        case KEY_BACKSPACE: return "Backspace";
        case KEY_TAB: return "Tab";
        case KEY_SPACE: return "Space";
        case KEY_LEFTSHIFT: return "LeftShift";
        case KEY_RIGHTSHIFT: return "RightShift";
        case KEY_LEFTCTRL: return "LeftCtrl";
        case KEY_RIGHTCTRL: return "RightCtrl";
        case KEY_LEFTALT: return "LeftAlt";
        case KEY_RIGHTALT: return "RightAlt";
        case KEY_CAPSLOCK: return "CapsLock";
        default: return "Unknown";
    }
}

int main() {
    char name[256];
    int fd = -1;

    printf("Scanning for keyboards...\n");
    for (int i = 0; i < MAX_DEVICES; i++) {
        char filename[64];
        snprintf(filename, sizeof(filename), "/dev/input/event%d", i);

        int tempfd = open(filename, O_RDONLY);
        if (tempfd < 0) continue;

        if (ioctl(tempfd, EVIOCGNAME(sizeof(name)), name) >= 0) {
            printf("%s: %s\n", filename, name);

            if (strcasestr(name, "keyboard")) {
                printf("-> Using %s as keyboard device\n", filename);
                fd = tempfd;
                break;
            }
        }
        close(tempfd);
    }

    if (fd < 0) {
        fprintf(stderr, "No keyboard device found!\n");
        exit(EXIT_FAILURE);
    }

    struct input_event ev;
    while (1) {
        ssize_t n = read(fd, &ev, sizeof ev);
        if (n == (ssize_t)-1) {
            if (errno == EINTR) continue;
            perror("read");
            exit(EXIT_FAILURE);
        }
        if (n != sizeof ev) {
            fprintf(stderr, "Unexpected read size\n");
            exit(EXIT_FAILURE);
        }

        if (ev.type == EV_KEY) {
            const char* key_name = keycode_to_name(ev.code);

            if (ev.value == 1)
                printf("Key pressed:   %s\n", key_name);
            else if (ev.value == 0)
                printf("Key released:  %s\n", key_name);
            else if (ev.value == 2)
                printf("Key repeated:  %s\n", key_name);

            fflush(stdout);
        }
    }

    close(fd);
    return 0;
}
