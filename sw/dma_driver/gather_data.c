#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdint.h>
#include <fcntl.h>
#include <pthread.h>
#include <time.h>
#include <sys/time.h>

#define ITERATION_COUNT (uint64_t)(4096)

#define FIFO_DEPTH 64
#define PMU_METRIC_COUNT 19
#define PMU_DATA_WIDTH 32
#define ROUTERS_COUNT 9
#define COMMAND_WIDTH 128

#define PMU_DATA_BYTES     (PMU_DATA_WIDTH/8)
#define PMU_TOTAL_BYTES    (PMU_DATA_BYTES*PMU_METRIC_COUNT)
#define COMMAND_BYTES      (COMMAND_WIDTH/8)
#define PMU_WIDTH_RATIO    ((PMU_METRIC_COUNT*PMU_DATA_WIDTH / COMMAND_WIDTH) + (PMU_METRIC_COUNT*PMU_DATA_WIDTH % COMMAND_WIDTH != 0))
#define PMU_TRANSFER_BYTES (PMU_WIDTH_RATIO*COMMAND_BYTES)

#define ROUTERS_COUNT_WIDTH 4
#define AXI_DATA_WIDTH 32
#define AXI_ID_W_WIDTH 5
#define AXI_ID_R_WIDTH 5
#define AXI_ADDR_WIDTH 8 
#define AXI_MAX_ID_WIDTH ((AXI_ID_W_WIDTH > AXI_ID_R_WIDTH) ? AXI_ID_W_WIDTH : AXI_ID_R_WIDTH)

#define ROUTERS_COUNT_BYTES (ROUTERS_COUNT_WIDTH / 8 + (ROUTERS_COUNT_WIDTH % 8 != 0))
#define AXI_DATA_BYTES      (AXI_DATA_WIDTH      / 8 + (AXI_DATA_WIDTH      % 8 != 0))
#define AXI_MAX_ID_BYTES    (AXI_MAX_ID_WIDTH    / 8 + (AXI_MAX_ID_WIDTH    % 8 != 0))
#define AXI_ADDR_BYTES      (AXI_ADDR_WIDTH      / 8 + (AXI_ADDR_WIDTH      % 8 != 0))
#define AXI_WSTRB_BYTES     (AXI_DATA_BYTES      / 8 + (AXI_DATA_BYTES      % 8 != 0))


uint32_t randomize_core_mask(int active_core_count) {
    uint32_t core_mask = -1;
    uint8_t core_array[ROUTERS_COUNT];
    uint8_t index_array[ROUTERS_COUNT];
    for (int i = 0; i < ROUTERS_COUNT; i++) {
        core_array[i] = 1;
        index_array[i] = i;
    }

    int chosen;
    for (int i = 0; i < active_core_count; i++) {
        chosen = rand() % (ROUTERS_COUNT-i);
        core_array[index_array[chosen]] = 0;
        for (int j = chosen; j < ROUTERS_COUNT-i-1; j++) {
            index_array[j] = index_array[j+1];
        }
    }

    for (int i = 0; i < ROUTERS_COUNT; i++) {
        core_mask -= (1-core_array[i]) * (1 << i);
    }

    return core_mask;
}

void generate_tasks(uint8_t *task_array, uint32_t core_mask, int write_count, int axlen_arg, int queue_depth) {

    uint64_t byte_counter = 0;
    
    for (uint64_t i = 0; i < ROUTERS_COUNT; i++) {
        if (((core_mask >> i) % 2)) {
            continue;
        }

        for (int j = 0; j < FIFO_DEPTH; j++) {
            uint64_t router_id = i;
            uint8_t resp_wait = (j < write_count) ?
                                ((((j+1) % queue_depth) == 0) ? 1 : 0) :
                                ((((j-write_count+1) % queue_depth) == 0) ? 1 : 0);
            uint64_t axi_id = rand() % ROUTERS_COUNT + 1;
            uint8_t write = (j < write_count) ? 1 : 0;
            uint64_t address = 0;
            uint8_t axlen = axlen_arg;

            for (int k = 0; k < AXI_WSTRB_BYTES; k++) {
                task_array[byte_counter] = rand() % 256;
                byte_counter++;
            }
            for (int k = 0; k < AXI_DATA_BYTES; k++) {
                task_array[byte_counter] = rand() % 256;
                byte_counter++;
            }
            task_array[byte_counter] = axlen;
            byte_counter++;
            for (int k = 0; k < AXI_ADDR_BYTES; k++) {
                task_array[byte_counter] = (uint8_t)address;
                address = address >> 8;
                byte_counter++;
            }
            task_array[byte_counter] = write;
            byte_counter++;
            for (int k = 0; k < AXI_MAX_ID_BYTES; k++) {
                task_array[byte_counter] = (uint8_t)axi_id;
                axi_id = axi_id >> 8;
                byte_counter++;
            }
            task_array[byte_counter] = resp_wait;
            byte_counter++;
            for (int k = 0; k < ROUTERS_COUNT_BYTES; k++) {
                task_array[byte_counter] = (uint8_t)router_id;
                router_id = router_id >> 8;
                byte_counter++;
            }

            while (byte_counter % COMMAND_BYTES != 0) {
                byte_counter++;
            }
        }
    }
}


int main (int argc, char** argv) {
    if (argc < 2) {
        return -1;
    }

    struct timeval tm;
    gettimeofday(&tm, NULL);
    srandom(tm.tv_sec + tm.tv_usec * 1000000ul);

    int fd;
    int user_irq_fd;
    int env_csr_fd;
    
    fd = open("/dev/hdlnocgen_c5p0", O_RDWR);
    if (fd < 0) {
        return fd;
    }

    user_irq_fd = open("/dev/hdlnocgen_c5p_user_irq", O_RDWR);
    if (user_irq_fd < 0) {
        return user_irq_fd;
    }

    env_csr_fd = open("/dev/hdlnocgen_c5p_env_csr", O_RDWR);
    if (env_csr_fd < 0) {
        return env_csr_fd;
    }

    char *csv_filename;
    int size = asprintf(&csv_filename, "%s.csv", argv[1]);
    if (!size) {
        printf("Failed to generate filename\n");
        perror("Reason:");
        return size;
    }

    FILE *file;
    file = fopen(csv_filename, "w");
    if (!file) {
        printf("Failed to open/create file %s\n", csv_filename);
        perror("Reason:");
        return -1;
    }

    const char *table_header[] = {
        "active_core_count",
        "write_count",
        "axlen",
        "queue_depth",
        "router_index",
        "read_idle",
        "read_outstanding",
        "read_ar_stall",
        "read_ar_handshake",
        "read_rvalid_stall",
        "read_rready_stall",
        "read_r_handshake",
        "write_idle",
        "write_outstanding",
        "write_responding",
        "write_aw_stall",
        "write_aw_handshake",
        "write_wvalid_stall",
        "write_wready_stall",
        "write_w_handshake",
        "write_bvalid_stall",
        "write_bready_stall",
        "write_b_handshake",
        "clock_counter"
    };

    for (int i = 0; i < sizeof(table_header)/sizeof(table_header[0]); i++) {
        fprintf(file, "%s", table_header[i]);
        if (i+1 < sizeof(table_header)/sizeof(table_header[0])) {
            fprintf(file, ",");
        }
    }
    fprintf(file, "\n");

    uint32_t struct_ptr;
    pread(env_csr_fd, &struct_ptr, 4, (off_t)0x0);

    uint8_t user_irq;
    uint8_t user_irq_clear = 0;


    int active_core_count = 0;
    int active_core_count_index = 0;
    uint32_t core_mask;
    int write_count;
    int axlen;
    int queue_depth = 16;


    struct timespec start, stop;
    double elapsed = 0;
    uint64_t bitcount;

    uint32_t test_activate = 0xFFFFFFFF;
    uint32_t rst_assert = 0xFFFFFFFF;
    uint32_t rst_state;

    while (active_core_count < ROUTERS_COUNT) {
        active_core_count = 1 << active_core_count_index;
        active_core_count = (active_core_count >= ROUTERS_COUNT) ? ROUTERS_COUNT : active_core_count;
        active_core_count_index++;
        printf("Active core count: %d\n", active_core_count);

        uint8_t tasks[FIFO_DEPTH*active_core_count * COMMAND_BYTES];
        uint8_t pmu[ROUTERS_COUNT * PMU_TRANSFER_BYTES];

        for (write_count = 1; write_count < FIFO_DEPTH; write_count += 2) {
            printf("Write count: %d\n", write_count);
            for (axlen = 1; axlen < 8; axlen += 2) {
                printf("Axlen: %d\n", axlen);
                for (queue_depth = 1; queue_depth <= 34; queue_depth += 4) {
                    clock_gettime(CLOCK_MONOTONIC, &start);
                    pwrite(env_csr_fd, &rst_assert, 4, (off_t)0x8);
                    do {
                        pread(env_csr_fd, &rst_state, 4, (off_t)0x4);
                    } while (rst_state != 0);
                    for (int iter = 0; iter < ITERATION_COUNT; iter++) {
                        core_mask = randomize_core_mask(active_core_count);
                        pwrite(env_csr_fd, &core_mask, 4, (off_t)(struct_ptr + 0x4));

                        generate_tasks(tasks, core_mask, write_count, axlen, queue_depth);

                        write(fd, tasks, sizeof(tasks));
                        pwrite(env_csr_fd, &test_activate, 4, (off_t)(struct_ptr+0x18));
                        int deadlock_counter = 0;
                        for (deadlock_counter; deadlock_counter < 1000000; deadlock_counter++) {
                            pread(user_irq_fd, &user_irq, sizeof(user_irq), (off_t)0x0);
                            if (user_irq == 1) {
                                break;
                            }
                        }
                        pwrite(user_irq_fd, &user_irq_clear, sizeof(user_irq_clear), (off_t)0x0);
                        if (deadlock_counter == 1000000) {
                            printf("DEADLOCK: %d,%d,%d,%d\n", active_core_count, write_count, axlen, queue_depth);
                            break;
                        }
                    }
                    pwrite(env_csr_fd, &test_activate, 4, (off_t)(struct_ptr+0x14));
                    read(fd, pmu, sizeof(pmu));
                    clock_gettime(CLOCK_MONOTONIC, &stop);

                    elapsed += (stop.tv_sec*1e9 + stop.tv_nsec) - (start.tv_sec*1e9 + start.tv_nsec);
                    bitcount += (sizeof(tasks)*8) * ITERATION_COUNT + sizeof(pmu)*8;

                    for (int i = 0; i < ROUTERS_COUNT*PMU_TRANSFER_BYTES; i += PMU_TRANSFER_BYTES) {
                        fprintf(file, "%d,%d,%d,%d,%d,", active_core_count, write_count, axlen, queue_depth, i/PMU_TRANSFER_BYTES);
                        for (int j = 0; j < PMU_TOTAL_BYTES; j += PMU_DATA_BYTES) {
                            uint32_t metric = 0;
                            for (int k = 0; k < PMU_DATA_BYTES; k++) {
                                metric += (pmu[i+j+k] << (k*8));
                            }
                            fprintf(file, "%u", metric);
                            if (j+PMU_DATA_BYTES < PMU_TOTAL_BYTES) {
                                fprintf(file, ",");
                            }
                        }
                        fprintf(file, "\n");
                    }

                }
            }
        }
    }

    printf("\n");
    printf("Test done\n");
    printf("Bitcount: %ld, Speed: %lf Gbit/sec\n", bitcount, bitcount/elapsed);

    close(env_csr_fd);
    close(user_irq_fd);
    close(fd);
}
