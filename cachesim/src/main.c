#include <stdio.h>
#include <stdlib.h>
#include "cache.h"

int main(int argc, char **argv) {
    if (argc < 3) {
        fprintf(stderr, "Usage: %s <pc_binary_file> <log_file> [max_entries]\n", argv[0]);
        return 1;
    }

    const char *pcfile = argv[1];
    const char *logfile = argv[2];
    size_t max_entries = 0;
    if (argc >= 4) {
        max_entries = (size_t)atoll(argv[3]);
    }

    icache_t cache;
    cachesim_stats_t stats;
    cachesim_init(&cache, &stats);
    cachesim_exec(&cache, pcfile, logfile, max_entries, &stats);
    cachesim_stat(&stats);

    return 0;
}