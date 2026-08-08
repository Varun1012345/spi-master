// spi_master_top.v
// Top-level SPI master: wires clock divider, shift register, and control FSM.
// Phase 1 scope: Mode 0 only, single byte transfer, no register bus yet
// (register interface / multi-mode support to be added in Phase 2).

module spi_master_top (
    input  wire       clk,
    input  wire       rst_n,

    input  wire       start,       // pulse to begin a transfer
    input  wire [7:0] tx_data,     // byte to send
    input  wire [7:0] clkdiv_val,  // clock divider setting
    input  wire       cpol,
    input  wire       cpha,
    input  wire       lsb_first,

    output wire       sclk,
    output wire       ss_n,
    output wire       mosi,
    input  wire       miso,

    output wire [7:0] rx_data,
    output wire       busy,
    output wire       done
);

    wire sclk_en;
    wire load, shift;

    spi_clkdiv u_clkdiv (
        .clk     (clk),
        .rst_n   (rst_n),
        .enable  (busy),        // divider only runs during a transfer
        .div     (clkdiv_val),
        .sclk_en (sclk_en)
    );

    spi_ctrl_fsm u_fsm (
        .clk      (clk),
        .rst_n    (rst_n),
        .start    (start),
        .sclk_en  (sclk_en),
        .cpol     (cpol),
        .cpha     (cpha),
        .load     (load),
        .shift    (shift),
        .sclk     (sclk),
        .ss_n     (ss_n),
        .busy     (busy),
        .done     (done)
    );

    spi_shift_reg u_shreg (
        .clk          (clk),
        .rst_n        (rst_n),
        .load         (load),
        .shift        (shift),
        .lsb_first    (lsb_first),
        .tx_data      (tx_data),
        .miso_bit_in  (miso),
        .mosi_bit_out (mosi),
        .rx_data      (rx_data)
    );

endmodule
