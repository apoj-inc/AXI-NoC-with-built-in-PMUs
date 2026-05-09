#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdint.h>
#include <fcntl.h>
#include <pthread.h>
#include <time.h>

#define ARRAY_SIZE (uint64_t)(1024*16/8)
#define DMA_CHANNEL_COUNT 1
#define ITERATION_COUNT (uint64_t)(10000)

#define FIFO_DEPTH 64
#define PMU_METRIC_COUNT 19
#define PMU_DATA_WIDTH 32
#define ROUTERS_COUNT 16
#define COMMAND_WIDTH 128

#define PMU_DATA_BYTES     (PMU_DATA_WIDTH/8)
#define COMMAND_BYTES      (COMMAND_WIDTH/8)
#define PMU_WIDTH_RATIO    ((PMU_METRIC_COUNT*PMU_DATA_WIDTH / COMMAND_WIDTH) + (PMU_METRIC_COUNT*PMU_DATA_WIDTH % COMMAND_WIDTH != 0))
#define PMU_TRANSFER_BYTES (PMU_WIDTH_RATIO*COMMAND_BYTES)

#define ROUTERS_COUNT_WIDTH 4
#define AXI_DATA_WIDTH 32
#define AXI_ID_W_WIDTH 5
#define AXI_ID_R_WIDTH 5
#define AXI_ADDR_WIDTH 16 
#define AXI_MAX_ID_WIDTH ((AXI_ID_W_WIDTH > AXI_ID_R_WIDTH) ? AXI_ID_W_WIDTH : AXI_ID_R_WIDTH)

#define ROUTERS_COUNT_BYTES (ROUTERS_COUNT_WIDTH / 8 + (ROUTERS_COUNT_WIDTH % 8 != 0))
#define AXI_DATA_BYTES      (AXI_DATA_WIDTH      / 8 + (AXI_DATA_WIDTH      % 8 != 0))
#define AXI_MAX_ID_BYTES    (AXI_MAX_ID_WIDTH    / 8 + (AXI_MAX_ID_WIDTH    % 8 != 0))
#define AXI_ADDR_BYTES      (AXI_ADDR_WIDTH      / 8 + (AXI_ADDR_WIDTH      % 8 != 0))
#define AXI_WSTRB_BYTES     (AXI_DATA_BYTES      / 8 + (AXI_DATA_BYTES      % 8 != 0))


uint8_t tasks[DMA_CHANNEL_COUNT][FIFO_DEPTH*ROUTERS_COUNT*2 * COMMAND_BYTES + COMMAND_BYTES];
uint8_t pmu[DMA_CHANNEL_COUNT][ROUTERS_COUNT * PMU_TRANSFER_BYTES];
int fd[DMA_CHANNEL_COUNT];
int user_irq_fd;
int env_csr_fd;
int fail[DMA_CHANNEL_COUNT];

void *dma_test_and_extract (void *index) {
    int index_int = (uint64_t)index;
    uint8_t user_irq;
    uint8_t user_irq_clear = 0;
    uint32_t rst_assert = 0xFFFFFFFF;
    uint32_t rst_state;

    pwrite(env_csr_fd, &rst_assert, 4, (off_t)0x8);
    do {
        pread(env_csr_fd, &rst_state, 4, (off_t)0x4);
    } while (rst_state != 0);

    write(fd[index_int], tasks[index_int], sizeof(tasks[index_int]));

    do {
        pread(user_irq_fd, &user_irq, sizeof(user_irq), (off_t)index_int);
    } while (user_irq != 1);
    read(fd[index_int], pmu[index_int], sizeof(pmu[index_int]));
    pwrite(user_irq_fd, &user_irq_clear, sizeof(user_irq_clear), (off_t)index_int);
}

int main () {
    pthread_t threads[DMA_CHANNEL_COUNT];

    struct timespec start, stop;
    double elapsed = 0;


    for (int i = 0; i < DMA_CHANNEL_COUNT; i++) {
        char *filepath;

        int size = asprintf(&filepath, "/dev/hdlnocgen_c5p%d", i);
        if (size < 0) {
            return size;
        }

        fd[i] = open(filepath, O_RDWR);
        free(filepath);
        if (fd[i] < 0) {
            for (int j = 0; j < i; j++) {
                close(fd[j]);
            }
            return fd[i];
        }
    }

    user_irq_fd = open("/dev/hdlnocgen_c5p_user_irq", O_RDWR);
    if (user_irq_fd < 0) {
        return user_irq_fd;
    }

    env_csr_fd = open("/dev/hdlnocgen_c5p_env_csr", O_RDWR);
    if (env_csr_fd < 0) {
        return env_csr_fd;
    }


    for (int i = 0; i < DMA_CHANNEL_COUNT; i++) {
        uint64_t byte_counter = 0;
        for (int j = 0; j < FIFO_DEPTH*ROUTERS_COUNT; j++) {
            uint64_t router_id = j / FIFO_DEPTH;
            uint8_t resp_wait = rand() % 2;
            uint64_t axi_id = rand();
            uint8_t write  = 1;
            uint64_t address = 0;
            uint8_t axlen = 4;

            for (int k = 0; k < AXI_WSTRB_BYTES; k++) {
                tasks[i][byte_counter] = rand() % 256;
                byte_counter++;
            }
            for (int k = 0; k < AXI_DATA_BYTES; k++) {
                tasks[i][byte_counter] = rand() % 256;
                byte_counter++;
            }
            tasks[i][byte_counter] = axlen;
            byte_counter++;
            for (int k = 0; k < AXI_ADDR_BYTES; k++) {
                tasks[i][byte_counter] = (uint8_t)address;
                address = address >> 8;
                byte_counter++;
            }
            tasks[i][byte_counter] = write;
            byte_counter++;
            for (int k = 0; k < AXI_MAX_ID_BYTES; k++) {
                tasks[i][byte_counter] = (uint8_t)axi_id;
                axi_id = axi_id >> 8;
                byte_counter++;
            }
            tasks[i][byte_counter] = resp_wait;
            byte_counter++;
            for (int k = 0; k < ROUTERS_COUNT_BYTES; k++) {
                tasks[i][byte_counter] = (uint8_t)router_id;
                router_id = router_id >> 8;
                byte_counter++;
            }

            while (byte_counter % COMMAND_BYTES != 0) {
                byte_counter++;
            }
        }

        for (int j = 0; j < FIFO_DEPTH*ROUTERS_COUNT; j++) {
            uint64_t router_id = j / FIFO_DEPTH;
            uint8_t resp_wait = rand() % 2;
            uint64_t axi_id = rand();
            uint8_t write  = 0;
            uint64_t address = 0;
            uint8_t axlen = 4;

            for (int k = 0; k < AXI_WSTRB_BYTES; k++) {
                tasks[i][byte_counter] = rand() % 256;
                byte_counter++;
            }
            for (int k = 0; k < AXI_DATA_BYTES; k++) {
                tasks[i][byte_counter] = rand() % 256;
                byte_counter++;
            }
            tasks[i][byte_counter] = axlen;
            byte_counter++;
            for (int k = 0; k < AXI_ADDR_BYTES; k++) {
                tasks[i][byte_counter] = (uint8_t)address;
                address = address >> 8;
                byte_counter++;
            }
            tasks[i][byte_counter] = write;
            byte_counter++;
            for (int k = 0; k < AXI_MAX_ID_BYTES; k++) {
                tasks[i][byte_counter] = (uint8_t)axi_id;
                axi_id = axi_id >> 8;
                byte_counter++;
            }
            tasks[i][byte_counter] = resp_wait;
            byte_counter++;
            for (int k = 0; k < ROUTERS_COUNT_BYTES; k++) {
                tasks[i][byte_counter] = (uint8_t)router_id;
                router_id = router_id >> 8;
                byte_counter++;
            }
            
            while (byte_counter % COMMAND_BYTES != 0) {
                byte_counter++;
            }
        }

        for (int j = 0; j < 16; j++) {
            tasks[i][byte_counter] = 0xFF;
            byte_counter++;
        }
    }
    printf("All channels initialized data\n");

    printf("Iter: ");
    for (int iter = 0; iter < ITERATION_COUNT; iter++) {

        clock_gettime(CLOCK_MONOTONIC, &start);
        for (int i = 0; i < DMA_CHANNEL_COUNT; i++) {
            pthread_create(&threads[i], NULL, dma_test_and_extract, (void *)(uint64_t)i);
        }
        for (int i = 0; i < DMA_CHANNEL_COUNT; i++) {
            pthread_join(threads[i], NULL);
        }
        clock_gettime(CLOCK_MONOTONIC, &stop);

        elapsed += (stop.tv_sec*1e9 + stop.tv_nsec) - (start.tv_sec*1e9 + start.tv_nsec);

        printf("%d ", iter);
    }
    printf("\n");
    printf("Test done\n");

    for (int i = 0; i < DMA_CHANNEL_COUNT; i++) {
        printf("Channel %d:\n", i);
        for (int r = 0; r < ROUTERS_COUNT*PMU_TRANSFER_BYTES; r += PMU_TRANSFER_BYTES) {
            printf("    Router %d:\n", r/(PMU_TRANSFER_BYTES));
            for (int j = PMU_TRANSFER_BYTES-PMU_DATA_BYTES; j >= 0; j -= PMU_DATA_BYTES) {
                for (int k = PMU_DATA_BYTES-1; k >= 0; k--) {
                    if (k % 4 == 3) {
                        printf("        0x%02x", pmu[i][r+j+k]);
                    } else if (k % 4 == 0) {
                        printf("%02x\n", pmu[i][r+j+k]);
                    } else {
                        printf("%02x", pmu[i][r+j+k]);
                    }
                }
            }
        }
    }

    uint64_t bitcount = (sizeof(tasks)*8 + sizeof(pmu)*8) * ITERATION_COUNT;
    printf("Speed: %lf Gbit/sec\n", bitcount/elapsed);
    

    for (int i = 0; i < DMA_CHANNEL_COUNT; i++) {
        close(fd[i]);
    }
}
