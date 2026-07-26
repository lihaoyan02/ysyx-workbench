// Simple direct-mapped icache simulator header
#ifndef __CACHE_H__
#define __CACHE_H__

#include <stdint.h>
#include <stddef.h>

// Configurable macros (can be overridden with -D)
#ifndef CACHE_BLOCK_SIZE
#define CACHE_BLOCK_SIZE 16 // bytes
#endif

#ifndef CACHE_BLOCK_NUM
#define CACHE_BLOCK_NUM 16
#endif

#ifndef ACCESS_TIME
#define ACCESS_TIME 1 // cycles for a hit/access
#endif

#ifndef MISS_PENALTY
#define MISS_PENALTY 11840 // cycles for a miss
#endif

// SRAM region config (matches iCache.v)
#ifndef SRAM_ADDR_DOWN
#define SRAM_ADDR_DOWN 0x0f000000u
#endif

#ifndef SRAM_LEN
#define SRAM_LEN 0x2000u
#endif

// If set to 1, accesses in SRAM range bypass cache (not cached)
#ifndef IGNORE_SRAM_CACHE
#define IGNORE_SRAM_CACHE 1
#endif

// Extra cycles for SRAM access (in addition to ACCESS_TIME)
#ifndef SRAM_EXTRA_CYCLES
#define SRAM_EXTRA_CYCLES 1
#endif

typedef struct {
    uint8_t valid;
    uint32_t tag;
} cache_line_t;

typedef struct {
    cache_line_t lines[CACHE_BLOCK_NUM];
} icache_t;

typedef struct {
    size_t accesses;
    size_t hits;
    size_t misses;
    uint64_t cycles;
    size_t sram_accesses;
} cachesim_stats_t;

void icache_init(icache_t *c);
int icache_access(icache_t *c, uint32_t addr); // returns 1 on hit, 0 on miss

void cachesim_init(icache_t *cache, cachesim_stats_t *stats);
void cachesim_exec(icache_t *cache, const char *pcfile, const char *logfile,
                   size_t max_entries, cachesim_stats_t *stats);
void cachesim_stat(const cachesim_stats_t *stats);

#endif
