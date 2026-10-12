// cos_sdk: the cache functions Aurora's aurora_os lacks (docs/NATIVE_PORT_PHASE2_3.md, step 2.6b).
//
// Aurora's lib/dolphin/os/OSCache.cpp already has the range functions (DCFlushRange,
// DCInvalidateRange, DCStoreRange, DCZeroRange, ICInvalidateRange, ...) and the locked cache
// (LCEnable/LCDisable, LCGetBase over a 16 KiB buffer, LCLoadBlocks/LCStoreBlocks/LCLoadData/
// LCStoreData as memcpy, LCQueueLength/LCQueueWait/LCFlushQueue). What is left is here:
// - DCBlockZero clears its 32-byte block, as dcbz does (real data, unlike the others);
// - LCAlloc*, the whole-cache and per-block DC/IC operations, and L2 control do nothing: host
//   memory is coherent, there is no cache to enable, freeze, lock or invalidate, and the locked
//   cache is ordinary memory that needs no tags (LCAlloc's contents are undefined on the console
//   too);
// - ICSync is a memory fence.
//
// Provenance: not in Dusklight (it relies on Aurora's OSCache.cpp for the functions it uses).
#include <dolphin/os.h>

#include <atomic>
#include <cstdint>
#include <cstring>

extern "C" {

// ---- Locked cache -----------------------------------------------------------------------------

void LCAllocOneTag(BOOL invalidate, void* tag) {
    (void)invalidate;
    (void)tag;
}

void LCAllocTags(BOOL invalidate, void* startTag, u32 numBlocks) {
    (void)invalidate;
    (void)startTag;
    (void)numBlocks;
}

void LCAlloc(void* addr, u32 nBytes) {
    (void)addr;
    (void)nBytes;
}

void LCAllocNoInvalidate(void* addr, u32 nBytes) {
    (void)addr;
    (void)nBytes;
}

// ---- Data cache -------------------------------------------------------------------------------

void DCFlashInvalidate(void) {}
void DCEnable(void) {}
void DCDisable(void) {}
void DCFreeze(void) {}
void DCUnfreeze(void) {}

void DCTouchLoad(void* addr) {
    (void)addr;
}

void DCBlockZero(void* addr) {
    // dcbz clears the whole 32-byte cache block that holds `addr`.
    auto block = reinterpret_cast<std::uintptr_t>(addr) & ~static_cast<std::uintptr_t>(31);
    std::memset(reinterpret_cast<void*>(block), 0, 32);
}

void DCBlockStore(void* addr) {
    (void)addr;
}

void DCBlockFlush(void* addr) {
    (void)addr;
}

void DCBlockInvalidate(void* addr) {
    (void)addr;
}

// ---- Instruction cache ------------------------------------------------------------------------

void ICFlashInvalidate(void) {}
void ICEnable(void) {}
void ICDisable(void) {}
void ICFreeze(void) {}
void ICUnfreeze(void) {}

void ICBlockInvalidate(void* addr) {
    (void)addr;
}

void ICSync(void) {
    std::atomic_thread_fence(std::memory_order_seq_cst);
}

// ---- L2 cache ---------------------------------------------------------------------------------

void L2Enable(void) {}
void L2Disable(void) {}
void L2GlobalInvalidate(void) {}

void L2SetDataOnly(BOOL dataOnly) {
    (void)dataOnly;
}

void L2SetWriteThrough(BOOL writeThrough) {
    (void)writeThrough;
}

// ---- Range and locked cache functions (OSCache.h) ---------------------------------------------

void DCInvalidateRange(void* addr, u32 nBytes) {
    (void)addr;
    (void)nBytes;
}

void DCFlushRange(void* addr, u32 nBytes) {
    (void)addr;
    (void)nBytes;
}

void DCStoreRange(void* addr, u32 nBytes) {
    (void)addr;
    (void)nBytes;
}

void DCFlushRangeNoSync(void* addr, u32 nBytes) {
    (void)addr;
    (void)nBytes;
}

void DCStoreRangeNoSync(void* addr, u32 nBytes) {
    (void)addr;
    (void)nBytes;
}

void DCZeroRange(void* addr, u32 nBytes) {
    if (addr != nullptr && nBytes > 0) {
        std::memset(addr, 0, nBytes);
    }
}

void DCTouchRange(void* addr, u32 nBytes) {
    (void)addr;
    (void)nBytes;
}

void ICInvalidateRange(void* addr, u32 nBytes) {
    (void)addr;
    (void)nBytes;
}

void LCEnable(void) {}
void LCDisable(void) {}

void LCLoadBlocks(void* destTag, void* srcAddr, u32 numBlocks) {
    if (destTag != nullptr && srcAddr != nullptr) {
        std::memcpy(destTag, srcAddr, (size_t)numBlocks * 32);
    }
}

void LCStoreBlocks(void* destAddr, void* srcTag, u32 numBlocks) {
    if (destAddr != nullptr && srcTag != nullptr) {
        std::memcpy(destAddr, srcTag, (size_t)numBlocks * 32);
    }
}

u32 LCLoadData(void* destAddr, void* srcAddr, u32 nBytes) {
    if (destAddr != nullptr && srcAddr != nullptr) {
        std::memcpy(destAddr, srcAddr, nBytes);
    }
    return nBytes;
}

u32 LCStoreData(void* destAddr, void* srcAddr, u32 nBytes) {
    if (destAddr != nullptr && srcAddr != nullptr) {
        std::memcpy(destAddr, srcAddr, nBytes);
    }
    return nBytes;
}

u32 LCQueueLength(void) {
    return 0;
}

void LCQueueWait(u32 len) {
    (void)len;
}

void LCFlushQueue(void) {}

void __OSCacheInit(void) {}

void aurora_draw_census_request(const char* pathPrefix) {
    (void)pathPrefix;
}

} // extern "C"
