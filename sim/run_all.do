# run_all.do
# ModelSim/QuestaSim script: compiles all RTL + testbenches and runs each sim.
# Usage (from ModelSim console, inside the sim/ directory):
#   do run_all.do

# --- create work library ---
vlib work
vmap work work

# --- compile RTL ---
vlog ../rtl/spi_clkdiv.v
vlog ../rtl/spi_shift_reg.v
vlog ../rtl/spi_ctrl_fsm.v
vlog ../rtl/spi_master_top.v

# --- compile testbenches ---
vlog ../tb/tb_clkdiv.v
vlog ../tb/tb_shift_reg.v
vlog ../tb/tb_spi_directed.v
vlog ../tb/tb_spi_mode1.v
vlog ../tb/tb_spi_mode2.v
vlog ../tb/tb_spi_mode3.v
vlog ../tb/tb_spi_lsb_first.v

# --- run clkdiv test ---
vsim -c tb_clkdiv -do "run -all; quit"

# --- run shift_reg test ---
vsim -c tb_shift_reg -do "run -all; quit"

# --- run Mode 1, 2, 3 tests (console only) ---
vsim -c tb_spi_mode1 -do "run -all; quit"
vsim -c tb_spi_mode2 -do "run -all; quit"
vsim -c tb_spi_mode3 -do "run -all; quit"
vsim -c tb_spi_lsb_first -do "run -all; quit"

# --- run top-level directed test (GUI so you can view waves after) ---
vsim tb_spi_directed
add wave -radix binary sim:/tb_spi_directed/dut/sclk
add wave -radix binary sim:/tb_spi_directed/dut/ss_n
add wave -radix binary sim:/tb_spi_directed/dut/mosi
add wave -radix binary sim:/tb_spi_directed/dut/miso
add wave -radix hex    sim:/tb_spi_directed/dut/rx_data
add wave -radix binary sim:/tb_spi_directed/dut/busy
add wave -radix binary sim:/tb_spi_directed/dut/done
add wave -radix hex    sim:/tb_spi_directed/tx_data
run -all
wave zoom full