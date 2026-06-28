#include "cache.h"
#include <stdio.h>
#include <inttypes.h>

void icache_init(icache_t *c) {
    for (int i = 0; i < CACHE_BLOCK_NUM; i++) {
        c->lines[i].valid = 0;
        c->lines[i].tag = 0;
    }
}

int icache_access(icache_t *c, uint32_t addr) {
    const int offset_bits = __builtin_ctz(CACHE_BLOCK_SIZE);
    const int index_bits = __builtin_ctz(CACHE_BLOCK_NUM);

    uint32_t index = (addr >> offset_bits) & ((1u << index_bits) - 1u);
    uint32_t tag = addr >> (offset_bits + index_bits);

    cache_line_t *line = &c->lines[index];
    if (line->valid && line->tag == tag) {
        return 1;
    }

    line->valid = 1;
    line->tag = tag;
    return 0;
}

void cachesim_init(icache_t *cache, cachesim_stats_t *stats) {
    icache_init(cache);
    if (stats != NULL) {
        stats->accesses = 0;
        stats->hits = 0;
        stats->misses = 0;
        stats->cycles = 0;
    }
}

void cachesim_exec(icache_t *cache, const char *pcfile, const char *logfile,
                   size_t max_entries, cachesim_stats_t *stats) {
    FILE *f = fopen(pcfile, "rb");
    if (f == NULL) {
        perror("fopen pc file");
        return;
    }

    FILE *lf = fopen(logfile, "w");
    if (lf == NULL) {
        perror("fopen log file");
        fclose(f);
        return;
    }

    uint32_t pc;
    size_t cnt = 0;
    while (fread(&pc, sizeof(pc), 1, f) == 1) {
        if (max_entries != 0 && cnt >= max_entries) {
            break;
        }
        int is_sram = (pc >= SRAM_ADDR_DOWN) && (pc < (SRAM_ADDR_DOWN + SRAM_LEN));

        if (is_sram) {
            // SRAM access: may bypass cache
            stats->sram_accesses++;
            int hit = 0;
            if (IGNORE_SRAM_CACHE) {
                // treat as miss for cache but cost only ACCESS_TIME + SRAM_EXTRA_CYCLES
                stats->misses++;
                stats->cycles += ACCESS_TIME + SRAM_EXTRA_CYCLES;
                fprintf(lf, "0x%08" PRIx32 " SRAM MISS\n", pc);
            } else {
                hit = icache_access(cache, pc);
                if (hit) {
                    stats->hits++;
                    stats->cycles += ACCESS_TIME + SRAM_EXTRA_CYCLES;
                    fprintf(lf, "0x%08" PRIx32 " HIT\n", pc);
                } else {
                    stats->misses++;
                    stats->cycles += ACCESS_TIME + MISS_PENALTY + SRAM_EXTRA_CYCLES;
                    fprintf(lf, "0x%08" PRIx32 " MISS\n", pc);
                }
            }
            stats->accesses++;
        } else {
            int hit = icache_access(cache, pc);
            if (hit) {
                stats->hits++;
                stats->cycles += ACCESS_TIME;
            } else {
                stats->misses++;
                stats->cycles += ACCESS_TIME + MISS_PENALTY;
            }
            fprintf(lf, "0x%08" PRIx32 " %s\n", pc, hit ? "HIT" : "MISS");
            stats->accesses++;
        }
        cnt++;
    }

    fclose(f);
    fclose(lf);
}

void cachesim_stat(const cachesim_stats_t *stats) {
    double p = stats->accesses ? ((double)stats->hits / (double)stats->accesses) : 0.0;
    double amat = (double)ACCESS_TIME + (1.0 - p) * (double)MISS_PENALTY;

    printf("Total accesses: %zu\n", stats->accesses);
    printf("Hits: %zu, Misses: %zu\n", stats->hits, stats->misses);
    printf("Hit rate: %.6f\n", p);
    printf("Total cycles: %llu\n", (unsigned long long)stats->cycles);
    printf("AMAT (cycles): %.6f\n", amat);
}
