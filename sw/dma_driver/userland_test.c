#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdint.h>
#include <fcntl.h>

int main (int argc, char **argv) {

    if (argc < 2) {
        return 0;
    }


    int fd;
    char *filepath;

    int size = asprintf(&filepath, "/dev/hdlnocgen_c5p%s", argv[1]);
    if (size < 0) {
        return size;
    }

    fd = open(filepath, O_RDWR);
    free(filepath);
    if (fd < 0) {
        return fd;
    }

    uint64_t kal[128];
    for (int i = 0; i < 128; i++) {
        kal[i] = i * ((int)(argv[1][0] - '0') + 1);
    }

    printf("Channel %s init: ", argv[1]);
    for (int i = 0; i < 128; i++) {
        printf("%lu ", kal[i]);
    }
    printf("\n");
    write(fd, kal, sizeof(kal));
    printf("Channel %s wrote to dma\n", argv[1]);

    for (int i = 0; i < 128; i++) {
        kal[i] = 0;
    }
    printf("Channel %s destroyed: ", argv[1]);
    for (int i = 0; i < 128; i++) {
        printf("%lu ", kal[i]);
    }
    printf("\n");

    read(fd, kal, sizeof(kal));
    printf("Channel %s read from dma\n", argv[1]);
    printf("Channel %s restored: ", argv[1]);
    for (int i = 0; i < 128; i++) {
        printf("%lu ", kal[i]);
    }
    printf("\n");
}