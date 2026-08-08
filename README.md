# SPI Master Controller (Self-Initiated Project)

A configurable SPI Master controller written in Verilog, designed and verified
in Icarus Verilog / GTKWave (ModelSim/QuestaSim compatible).

## Status
**Phase 1 (in progress):** Mode 0 transfer working, verified with directed tests.
Modes 1–3, register bus interface, and self-checking scoreboard are planned
next (see Roadmap below).

## What's implemented
- `spi_clkdiv.v` — programmable clock divider, generates SCLK timing pulses
- `spi_shift_reg.v` — 8-bit shift register, supports MSB-first and LSB-first
- `spi_ctrl_fsm.v` — control FSM sequencing a full SPI transfer (Mode 0)
- `spi_master_top.v` — top-level integration of the above

## Verification so far
| Test | Description                          | Status |
|------|---------------------------------------|--------|
| T1   | Reset behavior                        | PASS   |
| T2   | Mode 0 basic MOSI transfer            | PASS   |
| T3   | Modes 1–3                             | TODO (Phase 2) |
| T4   | MISO capture into rx_data             | Needs bit-accurate MISO drive timing (Phase 2) |
| T5   | Clock divider frequency check         | TODO |
| T6   | Slave-select line selection           | TODO (SS_SEL bus not yet added) |
| T7   | LSB-first vs MSB-first                | Implemented in shift_reg, not yet tested at top level |
| T8   | BUSY/DONE flag timing                 | Verified via T1/T2 |

Each RTL block also has its own standalone testbench (`tb_clkdiv.v`,
`tb_shift_reg.v`) confirming correct behavior in isolation before integration
— this made debugging the top-level FSM much easier.

## How to run the simulations

### Option A: ModelSim / QuestaSim (recommended)

From a terminal, inside the `sim/` directory:

```bash
vsim -do run_all.do
```

Or from within the ModelSim GUI console:

```tcl
cd sim
do run_all.do
```

This compiles all RTL + testbenches, runs the two standalone module tests in
the console, then opens `tb_spi_directed` in the Wave window with SCLK, SS_n,
MOSI, MISO, rx_data, busy, and done already added — compare this against the
timing diagram in `docs/spi_master_spec.md` section 5.

To re-run just the top-level test after making RTL changes:
```tcl
vlog ../rtl/*.v ../tb/tb_spi_directed.v
vsim tb_spi_directed
do run_all.do
```
(or simply re-run `do run_all.do` from scratch — it recompiles everything)

### Option B: Icarus Verilog (free, no license needed)

```bash
# Standalone module tests
iverilog -o sim/tb_clkdiv.vvp rtl/spi_clkdiv.v tb/tb_clkdiv.v
vvp sim/tb_clkdiv.vvp

iverilog -o sim/tb_shift_reg.vvp rtl/spi_shift_reg.v tb/tb_shift_reg.v
vvp sim/tb_shift_reg.vvp

# Top-level integration test
iverilog -o sim/tb_spi_directed.vvp rtl/spi_clkdiv.v rtl/spi_shift_reg.v \
    rtl/spi_ctrl_fsm.v rtl/spi_master_top.v tb/tb_spi_directed.v
vvp sim/tb_spi_directed.vvp

# View waveforms (after running the sim above, .vcd files land in sim/waves/)
gtkwave sim/waves/tb_spi_directed.vcd
```

## Design spec
Full register map, timing diagrams, and verification plan: see
[`docs/spi_master_spec.md`](docs/spi_master_spec.md).

## Roadmap (Phase 2)
- [ ] Add CPOL/CPHA handling for Modes 1, 2, 3 in `spi_ctrl_fsm.v`
- [ ] Bit-accurate MISO drive timing in testbench for reliable T4
- [ ] Register bus interface (CTRL/STATUS/CLKDIV/TX_DATA/RX_DATA/SS_SEL)
- [ ] Multi-slave SS_SEL support
- [ ] Self-checking scoreboard testbench with randomized transactions
- [ ] UVM-based testbench (stretch goal)

## Why this project
Built to develop hands-on RTL design and verification skills for embedded
protocol IP, extending prior digital design work (RISC-V core) into a
smaller, complete, spec-to-verified-silicon-style deliverable.
