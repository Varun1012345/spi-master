// spi_master_regbus_top.v
// Top-level SPI master with a register-bus host interface.

module spi_master_regbus_top (
    input  wire       clk,
    input  wire       rst_n,

    input  wire [7:0] addr,
    input  wire [7:0] wdata,
    input  wire       wr_en,
    input  wire       rd_en,
    output wire [7:0] rdata,

    output wire        sclk,
    output wire [3:0]  ss_n,
    output wire        mosi,
    input  wire        miso
);

    wire [7:0] clkdiv_val;
    wire [3:0] ss_sel;
    wire [7:0] tx_data;
    wire       start;
    wire [7:0] rx_data;
    wire       busy, done;
    wire       enable, cpol, cpha, lsb_first;
    wire       ss_n_active;

    spi_regfile u_regfile (
        .clk         (clk),
        .rst_n       (rst_n),
        .addr        (addr),
        .wdata       (wdata),
        .wr_en       (wr_en),
        .rd_en       (rd_en),
        .rdata       (rdata),
        .enable      (enable),
        .cpol        (cpol),
        .cpha        (cpha),
        .lsb_first   (lsb_first),
        .clkdiv_val  (clkdiv_val),
        .ss_sel      (ss_sel),
        .tx_data     (tx_data),
        .start       (start),
        .rx_data_in  (rx_data),
        .busy_in     (busy),
        .done_in     (done)
    );

    spi_master_top u_spi (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (start),
        .tx_data    (tx_data),
        .clkdiv_val (clkdiv_val),
        .cpol       (cpol),
        .cpha       (cpha),
        .lsb_first  (lsb_first),
        .sclk       (sclk),
        .ss_n       (ss_n_active),
        .mosi       (mosi),
        .miso       (miso),
        .rx_data    (rx_data),
        .busy       (busy),
        .done       (done)
    );

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : ss_decode
            assign ss_n[i] = ss_n_active | ~ss_sel[i];
        end
    endgenerate

endmodule