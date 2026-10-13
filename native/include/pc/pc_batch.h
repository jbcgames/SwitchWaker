#pragma once

#include "dolphin/types.h"
#include "dolphin/gx/GXEnum.h"
#include "dolphin/gx/GXStruct.h"
#include "dolphin/gx/GXVert.h"
#include "dolphin/mtx/mtx.h"
#include "aurora/dl.hpp"

namespace pc::batch {

struct Template {
    static constexpr u32 kMaxVtx = 192;
    static constexpr u32 kMaxPosRefs = 64;

    struct Vtx {
        u8 pos;
        u8 clr;
        u8 tex;
    };
    Vtx vtx[kMaxVtx];
    u16 vtxCount = 0;
    u8 posRefs[kMaxPosRefs];
    u8 posRefCount = 0;
};

inline void decode_template(const u8* dl, u32 size, Template& out) {
    out.vtxCount = 0;
    out.posRefCount = 0;
    bool posSeen[256] = {};

    static constexpr GXVtxDescList kDesc[] = {
        {GX_VA_POS, GX_INDEX8},
        {GX_VA_CLR0, GX_INDEX8},
        {GX_VA_TEX0, GX_INDEX8},
        {GX_VA_NULL, GX_NONE},
    };

    aurora::gx::dl::Reader reader{dl, size, kDesc};
    while (const auto cmd = reader.next()) {
        if (cmd->kind != aurora::gx::dl::Command::Kind::Draw) {
            continue;
        }

        const auto& draw = cmd->draw;
        aurora::gx::dl::expand_triangles(draw.prim, draw.vtxCount, [&](u16 i0, u16 i1, u16 i2) {
            for (const u16 elem : {i0, i1, i2}) {
                if (out.vtxCount >= Template::kMaxVtx) return;
                Template::Vtx& v = out.vtx[out.vtxCount++];
                v.pos = draw.attr_idx(elem, GX_VA_POS);
                v.clr = draw.attr_idx(elem, GX_VA_CLR0);
                v.tex = draw.attr_idx(elem, GX_VA_TEX0);
                if (!posSeen[v.pos]) {
                    posSeen[v.pos] = true;
                    if (out.posRefCount < Template::kMaxPosRefs) {
                        out.posRefs[out.posRefCount++] = v.pos;
                    }
                }
            }
        });
    }
}

inline void transform_positions(const Template& tpl, const Vec* srcPos, const Mtx mtx, Vec* dstPos) {
    for (u8 i = 0; i < tpl.posRefCount; ++i) {
        const u8 pIdx = tpl.posRefs[i];
        const Vec& v = srcPos[pIdx];
        dstPos[pIdx].x = mtx[0][0] * v.x + mtx[0][1] * v.y + mtx[0][2] * v.z + mtx[0][3];
        dstPos[pIdx].y = mtx[1][0] * v.x + mtx[1][1] * v.y + mtx[1][2] * v.z + mtx[1][3];
        dstPos[pIdx].z = mtx[2][0] * v.x + mtx[2][1] * v.y + mtx[2][2] * v.z + mtx[2][3];
    }
}

inline void emit_element(const Template& tpl, const Vec* xfPos) {
    for (u16 i = 0; i < tpl.vtxCount; ++i) {
        const Template::Vtx& v = tpl.vtx[i];
        const Vec& p = xfPos[v.pos];
        GXPosition3f32(p.x, p.y, p.z);
        GXColor1x8(v.clr);
        GXTexCoord1x8(v.tex);
    }
}

inline void split_batch(u32& emitted, u16 count) {
    if (emitted + count > 60000) {
        GXEnd();
        GXBegin(GX_TRIANGLES, GX_VTXFMT1, GX_AUTO);
        emitted = 0;
    }
    emitted += count;
}

} // namespace pc::batch
