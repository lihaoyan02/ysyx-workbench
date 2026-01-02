// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtop.h for the primary calling header

#include "Vtop__pch.h"

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop___024root___dump_triggers__ico(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG

void Vtop___024root___eval_triggers__ico(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_triggers__ico\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VicoTriggered[0U] = ((0xfffffffffffffffeULL 
                                      & vlSelfRef.__VicoTriggered
                                      [0U]) | (IData)((IData)(vlSelfRef.__VicoFirstIteration)));
    vlSelfRef.__VicoFirstIteration = 0U;
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vtop___024root___dump_triggers__ico(vlSelfRef.__VicoTriggered, "ico"s);
    }
#endif
}

bool Vtop___024root___trigger_anySet__ico(const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___trigger_anySet__ico\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        if (in[n]) {
            return (1U);
        }
        n = ((IData)(1U) + n);
    } while ((1U > n));
    return (0U);
}

void Vtop___024root___ico_sequent__TOP__0(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___ico_sequent__TOP__0\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ top__DOT__u_IDU__DOT____VdfgExtracted_h992958f5__0;
    top__DOT__u_IDU__DOT____VdfgExtracted_h992958f5__0 = 0;
    // Body
    top__DOT__u_IDU__DOT____VdfgExtracted_h992958f5__0 
        = (((- (IData)((vlSelfRef.inst >> 0x0000001fU))) 
            << 0x0000000cU) | (vlSelfRef.inst >> 0x00000014U));
    if ((0x13U == (0x0000007fU & vlSelfRef.inst))) {
        if ((0U == (7U & (vlSelfRef.inst >> 0x0000000cU)))) {
            vlSelfRef.top__DOT__wb_ctrl = 1U;
            vlSelfRef.top__DOT__j_pc = 0U;
            vlSelfRef.top__DOT__wb_en = 1U;
            vlSelfRef.top__DOT__alu_ctrl = 1U;
            vlSelfRef.top__DOT__imm_sel = 1U;
            vlSelfRef.top__DOT__imm = top__DOT__u_IDU__DOT____VdfgExtracted_h992958f5__0;
        }
    } else if ((0x67U == (0x0000007fU & vlSelfRef.inst))) {
        if ((0U == (7U & (vlSelfRef.inst >> 0x0000000cU)))) {
            vlSelfRef.top__DOT__wb_ctrl = 2U;
            vlSelfRef.top__DOT__j_pc = 1U;
            vlSelfRef.top__DOT__wb_en = 1U;
            vlSelfRef.top__DOT__alu_ctrl = 1U;
            vlSelfRef.top__DOT__imm_sel = 1U;
            vlSelfRef.top__DOT__imm = top__DOT__u_IDU__DOT____VdfgExtracted_h992958f5__0;
        }
    } else {
        vlSelfRef.top__DOT__wb_ctrl = 0U;
        vlSelfRef.top__DOT__j_pc = 0U;
        vlSelfRef.top__DOT__wb_en = 0U;
        vlSelfRef.top__DOT__alu_ctrl = 0U;
        vlSelfRef.top__DOT__imm_sel = 0U;
        vlSelfRef.top__DOT__imm = 0U;
    }
    vlSelfRef.top__DOT__alu_out = ((0U == (IData)(vlSelfRef.top__DOT__alu_ctrl))
                                    ? 0U : ((1U == (IData)(vlSelfRef.top__DOT__alu_ctrl))
                                             ? (((0U 
                                                  == 
                                                  (0x0000001fU 
                                                   & (vlSelfRef.inst 
                                                      >> 0x0000000fU)))
                                                  ? 0U
                                                  : 
                                                 vlSelfRef.top__DOT__u_gpr__DOT__rf
                                                 [(0x0000001fU 
                                                   & (vlSelfRef.inst 
                                                      >> 0x0000000fU))]) 
                                                + ((IData)(vlSelfRef.top__DOT__imm_sel)
                                                    ? vlSelfRef.top__DOT__imm
                                                    : 
                                                   ((0U 
                                                     == 
                                                     (0x0000001fU 
                                                      & (vlSelfRef.inst 
                                                         >> 0x00000014U)))
                                                     ? 0U
                                                     : 
                                                    vlSelfRef.top__DOT__u_gpr__DOT__rf
                                                    [
                                                    (0x0000001fU 
                                                     & (vlSelfRef.inst 
                                                        >> 0x00000014U))])))
                                             : 0U));
}

void Vtop___024root___eval_ico(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_ico\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VicoTriggered[0U])) {
        Vtop___024root___ico_sequent__TOP__0(vlSelf);
    }
}

bool Vtop___024root___eval_phase__ico(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_phase__ico\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VicoExecute;
    // Body
    Vtop___024root___eval_triggers__ico(vlSelf);
    __VicoExecute = Vtop___024root___trigger_anySet__ico(vlSelfRef.__VicoTriggered);
    if (__VicoExecute) {
        Vtop___024root___eval_ico(vlSelf);
    }
    return (__VicoExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop___024root___dump_triggers__act(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG

void Vtop___024root___eval_triggers__act(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_triggers__act\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VactTriggered[0U] = (QData)((IData)(
                                                    ((IData)(vlSelfRef.clk) 
                                                     & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__clk__0)))));
    vlSelfRef.__Vtrigprevexpr___TOP__clk__0 = vlSelfRef.clk;
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vtop___024root___dump_triggers__act(vlSelfRef.__VactTriggered, "act"s);
    }
#endif
}

bool Vtop___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___trigger_anySet__act\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        if (in[n]) {
            return (1U);
        }
        n = ((IData)(1U) + n);
    } while ((1U > n));
    return (0U);
}

void Vtop___024root___nba_sequent__TOP__0(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___nba_sequent__TOP__0\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ __Vdly__pc;
    __Vdly__pc = 0;
    CData/*0:0*/ __VdlySet__top__DOT__u_gpr__DOT__rf__v0;
    __VdlySet__top__DOT__u_gpr__DOT__rf__v0 = 0;
    IData/*31:0*/ __VdlyVal__top__DOT__u_gpr__DOT__rf__v32;
    __VdlyVal__top__DOT__u_gpr__DOT__rf__v32 = 0;
    CData/*4:0*/ __VdlyDim0__top__DOT__u_gpr__DOT__rf__v32;
    __VdlyDim0__top__DOT__u_gpr__DOT__rf__v32 = 0;
    CData/*0:0*/ __VdlySet__top__DOT__u_gpr__DOT__rf__v32;
    __VdlySet__top__DOT__u_gpr__DOT__rf__v32 = 0;
    // Body
    __Vdly__pc = vlSelfRef.pc;
    __VdlySet__top__DOT__u_gpr__DOT__rf__v0 = 0U;
    __VdlySet__top__DOT__u_gpr__DOT__rf__v32 = 0U;
    if (vlSelfRef.rst) {
        __Vdly__pc = 0U;
        __VdlySet__top__DOT__u_gpr__DOT__rf__v0 = 1U;
    } else {
        __Vdly__pc = ((IData)(vlSelfRef.top__DOT__j_pc)
                       ? vlSelfRef.top__DOT__alu_out
                       : ((IData)(1U) + vlSelfRef.pc));
        if (vlSelfRef.top__DOT__wb_en) {
            __VdlyVal__top__DOT__u_gpr__DOT__rf__v32 
                = ((0U == (IData)(vlSelfRef.top__DOT__wb_ctrl))
                    ? 0U : ((1U == (IData)(vlSelfRef.top__DOT__wb_ctrl))
                             ? vlSelfRef.top__DOT__alu_out
                             : ((2U == (IData)(vlSelfRef.top__DOT__wb_ctrl))
                                 ? ((IData)(1U) + vlSelfRef.pc)
                                 : 0U)));
            __VdlyDim0__top__DOT__u_gpr__DOT__rf__v32 
                = (0x0000001fU & (vlSelfRef.inst >> 7U));
            __VdlySet__top__DOT__u_gpr__DOT__rf__v32 = 1U;
        }
    }
    vlSelfRef.pc = __Vdly__pc;
    if (__VdlySet__top__DOT__u_gpr__DOT__rf__v0) {
        vlSelfRef.top__DOT__u_gpr__DOT__rf[0U] = 0U;
        vlSelfRef.top__DOT__u_gpr__DOT__rf[1U] = 0U;
        vlSelfRef.top__DOT__u_gpr__DOT__rf[2U] = 0U;
        vlSelfRef.top__DOT__u_gpr__DOT__rf[3U] = 0U;
        vlSelfRef.top__DOT__u_gpr__DOT__rf[4U] = 0U;
        vlSelfRef.top__DOT__u_gpr__DOT__rf[5U] = 0U;
        vlSelfRef.top__DOT__u_gpr__DOT__rf[6U] = 0U;
        vlSelfRef.top__DOT__u_gpr__DOT__rf[7U] = 0U;
        vlSelfRef.top__DOT__u_gpr__DOT__rf[8U] = 0U;
        vlSelfRef.top__DOT__u_gpr__DOT__rf[9U] = 0U;
        vlSelfRef.top__DOT__u_gpr__DOT__rf[0x0aU] = 0U;
        vlSelfRef.top__DOT__u_gpr__DOT__rf[0x0bU] = 0U;
        vlSelfRef.top__DOT__u_gpr__DOT__rf[0x0cU] = 0U;
        vlSelfRef.top__DOT__u_gpr__DOT__rf[0x0dU] = 0U;
        vlSelfRef.top__DOT__u_gpr__DOT__rf[0x0eU] = 0U;
        vlSelfRef.top__DOT__u_gpr__DOT__rf[0x0fU] = 0U;
        vlSelfRef.top__DOT__u_gpr__DOT__rf[0x10U] = 0U;
        vlSelfRef.top__DOT__u_gpr__DOT__rf[0x11U] = 0U;
        vlSelfRef.top__DOT__u_gpr__DOT__rf[0x12U] = 0U;
        vlSelfRef.top__DOT__u_gpr__DOT__rf[0x13U] = 0U;
        vlSelfRef.top__DOT__u_gpr__DOT__rf[0x14U] = 0U;
        vlSelfRef.top__DOT__u_gpr__DOT__rf[0x15U] = 0U;
        vlSelfRef.top__DOT__u_gpr__DOT__rf[0x16U] = 0U;
        vlSelfRef.top__DOT__u_gpr__DOT__rf[0x17U] = 0U;
        vlSelfRef.top__DOT__u_gpr__DOT__rf[0x18U] = 0U;
        vlSelfRef.top__DOT__u_gpr__DOT__rf[0x19U] = 0U;
        vlSelfRef.top__DOT__u_gpr__DOT__rf[0x1aU] = 0U;
        vlSelfRef.top__DOT__u_gpr__DOT__rf[0x1bU] = 0U;
        vlSelfRef.top__DOT__u_gpr__DOT__rf[0x1cU] = 0U;
        vlSelfRef.top__DOT__u_gpr__DOT__rf[0x1dU] = 0U;
        vlSelfRef.top__DOT__u_gpr__DOT__rf[0x1eU] = 0U;
        vlSelfRef.top__DOT__u_gpr__DOT__rf[0x1fU] = 0U;
    }
    if (__VdlySet__top__DOT__u_gpr__DOT__rf__v32) {
        vlSelfRef.top__DOT__u_gpr__DOT__rf[__VdlyDim0__top__DOT__u_gpr__DOT__rf__v32] 
            = __VdlyVal__top__DOT__u_gpr__DOT__rf__v32;
    }
    vlSelfRef.top__DOT__alu_out = ((0U == (IData)(vlSelfRef.top__DOT__alu_ctrl))
                                    ? 0U : ((1U == (IData)(vlSelfRef.top__DOT__alu_ctrl))
                                             ? (((0U 
                                                  == 
                                                  (0x0000001fU 
                                                   & (vlSelfRef.inst 
                                                      >> 0x0000000fU)))
                                                  ? 0U
                                                  : 
                                                 vlSelfRef.top__DOT__u_gpr__DOT__rf
                                                 [(0x0000001fU 
                                                   & (vlSelfRef.inst 
                                                      >> 0x0000000fU))]) 
                                                + ((IData)(vlSelfRef.top__DOT__imm_sel)
                                                    ? vlSelfRef.top__DOT__imm
                                                    : 
                                                   ((0U 
                                                     == 
                                                     (0x0000001fU 
                                                      & (vlSelfRef.inst 
                                                         >> 0x00000014U)))
                                                     ? 0U
                                                     : 
                                                    vlSelfRef.top__DOT__u_gpr__DOT__rf
                                                    [
                                                    (0x0000001fU 
                                                     & (vlSelfRef.inst 
                                                        >> 0x00000014U))])))
                                             : 0U));
}

void Vtop___024root___eval_nba(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_nba\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VnbaTriggered[0U])) {
        Vtop___024root___nba_sequent__TOP__0(vlSelf);
    }
}

void Vtop___024root___trigger_orInto__act(VlUnpacked<QData/*63:0*/, 1> &out, const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___trigger_orInto__act\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        out[n] = (out[n] | in[n]);
        n = ((IData)(1U) + n);
    } while ((1U > n));
}

bool Vtop___024root___eval_phase__act(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_phase__act\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    Vtop___024root___eval_triggers__act(vlSelf);
    Vtop___024root___trigger_orInto__act(vlSelfRef.__VnbaTriggered, vlSelfRef.__VactTriggered);
    return (0U);
}

void Vtop___024root___trigger_clear__act(VlUnpacked<QData/*63:0*/, 1> &out) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___trigger_clear__act\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        out[n] = 0ULL;
        n = ((IData)(1U) + n);
    } while ((1U > n));
}

bool Vtop___024root___eval_phase__nba(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_phase__nba\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = Vtop___024root___trigger_anySet__act(vlSelfRef.__VnbaTriggered);
    if (__VnbaExecute) {
        Vtop___024root___eval_nba(vlSelf);
        Vtop___024root___trigger_clear__act(vlSelfRef.__VnbaTriggered);
    }
    return (__VnbaExecute);
}

void Vtop___024root___eval(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ __VicoIterCount;
    IData/*31:0*/ __VnbaIterCount;
    // Body
    __VicoIterCount = 0U;
    vlSelfRef.__VicoFirstIteration = 1U;
    do {
        if (VL_UNLIKELY(((0x00000064U < __VicoIterCount)))) {
#ifdef VL_DEBUG
            Vtop___024root___dump_triggers__ico(vlSelfRef.__VicoTriggered, "ico"s);
#endif
            VL_FATAL_MT("vsrc/top.v", 1, "", "Input combinational region did not converge after 100 tries");
        }
        __VicoIterCount = ((IData)(1U) + __VicoIterCount);
    } while (Vtop___024root___eval_phase__ico(vlSelf));
    __VnbaIterCount = 0U;
    do {
        if (VL_UNLIKELY(((0x00000064U < __VnbaIterCount)))) {
#ifdef VL_DEBUG
            Vtop___024root___dump_triggers__act(vlSelfRef.__VnbaTriggered, "nba"s);
#endif
            VL_FATAL_MT("vsrc/top.v", 1, "", "NBA region did not converge after 100 tries");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        vlSelfRef.__VactIterCount = 0U;
        do {
            if (VL_UNLIKELY(((0x00000064U < vlSelfRef.__VactIterCount)))) {
#ifdef VL_DEBUG
                Vtop___024root___dump_triggers__act(vlSelfRef.__VactTriggered, "act"s);
#endif
                VL_FATAL_MT("vsrc/top.v", 1, "", "Active region did not converge after 100 tries");
            }
            vlSelfRef.__VactIterCount = ((IData)(1U) 
                                         + vlSelfRef.__VactIterCount);
        } while (Vtop___024root___eval_phase__act(vlSelf));
    } while (Vtop___024root___eval_phase__nba(vlSelf));
}

#ifdef VL_DEBUG
void Vtop___024root___eval_debug_assertions(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_debug_assertions\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (VL_UNLIKELY(((vlSelfRef.clk & 0xfeU)))) {
        Verilated::overWidthError("clk");
    }
    if (VL_UNLIKELY(((vlSelfRef.rst & 0xfeU)))) {
        Verilated::overWidthError("rst");
    }
}
#endif  // VL_DEBUG
