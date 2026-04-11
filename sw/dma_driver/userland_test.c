#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdint.h>

int main()
{
	int fd;
	char c;
    uint64_t kal[126];

	fd = open("/dev/hdlnocgen_c5p0", O_RDWR);

	if (fd < 0) {
		perror("open");
		return fd;
	}

	write(fd, (void *)kal, sizeof(kal));

	read(fd, (void *)kal, sizeof(kal));

    for (int i = 0; i < 126; i++) {
        printf("0x%lx\n", kal[i]);
    }

	close(fd);
	return 0;
}
