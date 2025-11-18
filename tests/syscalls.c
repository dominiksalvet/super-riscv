/*
    Super RISC-V - superscalar dual-issue RISC-V processor
    Copyright (C) 2025 Dominik Salvet

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>
#include <stdio.h>

#undef errno
extern int errno;

int _fstat(int file, struct stat *st) {
    st->st_mode = S_IFCHR;
    return 0;
}

off_t _lseek(int file, off_t ptr, int dir) {
    errno = ESPIPE;
    return (off_t)-1;
}

int _close(int file) {
    return -1;
}

int _isatty(int file) {
    return 1;
}

int _kill(int pid, int sig) {
    errno = EINVAL;
    return -1;
}

int _getpid(void) {
    return 1;
}

void _exit(int status) {
    asm volatile ("tail _finish");
    __builtin_unreachable();
}

int _read(int file, char *ptr, int len) {
    extern volatile int __mb_getc;

    // only input from host terminal is implemented
    if (file != STDIN_FILENO) {
        errno = ENOSYS;
        return -1;
    }

    int count = 0;
    while (count < len) {
        int read_data = __mb_getc;

        if (read_data == EOF) {
            break;
        }

        char read_byte = read_data & 0xFF;
        ptr[count] = read_byte;
        count++;

        // stop filling buffer on interesting chars (to inspect by caller)
        if (read_byte == '\n' || read_byte == '\r') {
            break;
        }
    }

    return count;
}

int _write(int file, char *ptr, int len) {
    extern volatile char __mb_putc;

    // only output to host terminal is implemented
    if (file != STDOUT_FILENO && file != STDERR_FILENO) {
        errno = ENOSYS;
        return -1;
    }

    char *end_ptr = ptr + len;

    while (ptr < end_ptr) {
        __mb_putc = (*ptr++);
    }

    return len;
}

caddr_t _sbrk(int incr) {
    extern char __heap_start;
    extern char __heap_end;

    static char *heap_ptr; // current heap end pointer

    // initialize heap on first use
    if (heap_ptr == 0) {
        heap_ptr = &__heap_start;
    }

    char *next_heap_ptr = heap_ptr + incr;

    if (next_heap_ptr > &__heap_end) {
        errno = ENOMEM;
        return (caddr_t) -1;
    }

    char *prev_heap_ptr = heap_ptr;
    heap_ptr = next_heap_ptr;

    return (caddr_t) prev_heap_ptr;
}
