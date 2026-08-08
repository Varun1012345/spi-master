# SPI Master Controller — Design Specification

**Project:** Self-Initiated | RTL Design & Verification
**Author:** Varun Kumar Chickballapur Venugopal
**Status:** Draft v1.0

---

## 1. Overview

A configurable SPI Master controller with a register-based interface, supporting all
four standard SPI clock modes (CPOL/CPHA combinations), an 8-bit data path, and a
programmable clock divider. Designed for FPGA implementation and simulated in
ModelSim/QuestaSim.

---

## 2. Block Diagram (described)

```
        ┌─────────────────────────────────────────┐
        │             SPI Master Top               │
        │                                           │
System  │  ┌──────────┐   ┌──────────┐   ┌───────┐ │
Clock ─►│  │  Clock   │──►│  Control │──►│ Shift │ │──► MOSI
        │  │ Divider  │   │   FSM    │   │  Reg  │ │
Reset ─►│  └──────────┘   └────┬─────┘   └───┬───┘ │◄── MISO
        │                      │             │      │
        │  ┌──────────┐        │        ┌────▼───┐ │
Reg     │  │ Register │◄───────┴───────►│ SCLK/  │ │──► SCLK
Bus  ◄─►│  │Interface │                 │  SS_n  │ │──► SS_n[3:0]
        │  └──────────┘                 │  Gen   │ │
        └─────────────────────────────────────────┘
```

---

## 3. Register Map

| Offset | Name       | Width | Access | Description                                      |
|--------|-----------|-------|--------|--------------------------------------------------|
| 0x00   | CTRL       | 8     | R/W    | Control register (see 3.1)                       |
| 0x04   | STATUS     | 8     | R      | Status register (see 3.2)                        |
| 0x08   | CLKDIV     | 8     | R/W    | Clock divider value (SCLK = sysclk / (2×(N+1)))  |
| 0x0C   | TX_DATA    | 8     | W      | Write triggers a transfer                        |
| 0x10   | RX_DATA    | 8     | R      | Last received byte                                |
| 0x14   | SS_SEL     | 4     | R/W    | Slave select (one-hot, bits [3:0])               |

### 3.1 CTRL Register

| Bit | Name    | Description                          |
|-----|---------|---------------------------------------|
| 0   | ENABLE  | 1 = SPI block enabled                |
| 1   | CPOL    | Clock polarity                        |
| 2   | CPHA    | Clock phase                           |
| 3   | LSB_FIRST | 0 = MSB first, 1 = LSB first        |
| 7:4 | Reserved | —                                    |

### 3.2 STATUS Register

| Bit | Name    | Description                          |
|-----|---------|---------------------------------------|
| 0   | BUSY    | 1 = transfer in progress             |
| 1   | DONE    | 1 = transfer complete (write 1 to clear) |
| 2   | TX_EMPTY | 1 = TX_DATA can accept new byte      |
| 7:3 | Reserved | —                                    |

---

## 4. SPI Modes (CPOL/CPHA)

| Mode | CPOL | CPHA | Sample edge     | Idle clock |
|------|------|------|-----------------|------------|
| 0    | 0    | 0    | Rising edge     | Low        |
| 1    | 0    | 1    | Falling edge    | Low        |
| 2    | 1    | 0    | Falling edge    | High       |
| 3    | 1    | 1    | Rising edge     | High       |

---

## 5. Timing Diagram (Mode 0, textual)

```
SS_n   ‾‾\_________________________________/‾‾
SCLK   ___/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\____
MOSI   ---<D7><D6><D5><D4><D3><D2><D1><D0>----
MISO   ---<Q7><Q6><Q5><Q4><Q3><Q2><Q1><Q0>----
                ^ sample on rising SCLK edge
```

- SS_n asserted (low) one clock cycle before first SCLK edge
- Data shifted MSB-first by default (LSB_FIRST=0)
- SS_n deasserted one clock cycle after last SCLK edge

---

## 6. Functional Requirements

1. FR1 — Support all 4 SPI modes via CPOL/CPHA bits
2. FR2 — Configurable clock divider (min divide-by-2, 8-bit range)
3. FR3 — 8-bit full-duplex transfer (simultaneous TX/RX)
4. FR4 — Support up to 4 slave select lines (SS_SEL one-hot)
5. FR5 — BUSY flag asserted during transfer, DONE flag on completion
6. FR6 — MSB-first or LSB-first shift order, selectable
7. FR7 — Back-to-back transfers without SS_n deassertion (optional/stretch)

---

## 7. Verification Plan

### 7.1 Directed Tests (Phase 1)
- T1: Reset behavior — all registers reset to known state
- T2: Mode 0 basic transfer — known TX byte, check MOSI waveform matches expected bit sequence
- T3: Repeat T2 for Modes 1, 2, 3
- T4: MISO capture — drive known pattern on MISO, verify RX_DATA matches
- T5: Clock divider — verify SCLK frequency for 2–3 different CLKDIV values
- T6: SS_SEL — verify correct SS_n line asserted for each SS_SEL value
- T7: LSB-first vs MSB-first ordering
- T8: BUSY/DONE flag timing — verify flags assert/deassert at correct cycles

### 7.2 Self-Checking Testbench (Phase 2)
- Build a scoreboard: generate random 8-bit TX values + random mode/clkdiv combinations
- Reference model (simple Verilog task or Python/cocotb model) computes expected MOSI bit sequence
- Compare DUT output against reference model automatically, log pass/fail
- Add coverage tracking: have all 4 modes, both bit orders, and a range of clock divider values been exercised?

### 7.3 Corner Cases (Phase 3)
- Mode switched between transfers (CTRL updated while IDLE)
- New TX_DATA write attempted while BUSY (should be ignored or queued — define behavior)
- CLKDIV = 0 (fastest possible clock)
- Back-to-back transfers with no gap

### 7.4 Stretch: UVM Testbench (Phase 4)
- Convert directed/scoreboard testbench into UVM: driver, monitor, sequencer, scoreboard, agent
- Reuse the reference model from 7.2 as the UVM scoreboard's predictor

---

## 8. Deliverables Checklist

- [ ] RTL: clock divider module
- [ ] RTL: control FSM
- [ ] RTL: shift register + SCLK/SS_n generation
- [ ] RTL: register interface
- [ ] RTL: top-level integration
- [ ] Directed testbench (Phase 1 tests, T1–T8)
- [ ] Self-checking testbench + reference model (Phase 2)
- [ ] Corner case tests (Phase 3)
- [ ] Waveform screenshots (GTKWave/ModelSim) for README
- [ ] README with block diagram, register map, and how to run sims
- [ ] (Stretch) UVM testbench (Phase 4)
- [ ] Push to GitHub with clear commit history

---

## 9. Suggested File Structure

```
spi-master/
├── rtl/
│   ├── spi_clkdiv.v
│   ├── spi_ctrl_fsm.v
│   ├── spi_shift_reg.v
│   ├── spi_regfile.v
│   └── spi_master_top.v
├── tb/
│   ├── tb_spi_directed.v
│   ├── tb_spi_scoreboard.sv
│   └── ref_model.py (or .sv)
├── sim/
│   └── (ModelSim scripts, wave.do files)
├── docs/
│   └── spi_master_spec.md   (this file)
└── README.md
```

---

## 10. Notes

- Start with T1–T3 to get a minimal working pipeline (RTL → sim → waveform) before
  building out the full FSM. Confirming the toolchain works early avoids debugging
  two things (design bugs vs. environment issues) at once.
- Keep the reference model simple at first — even a manual bit-by-bit expected-value
  table for a handful of transfers is enough to validate T1–T3 before investing in
  a full self-checking scoreboard.
