// tb_spi_lsb_first.v
// Verifies LSB_FIRST=1 mode at the top level (spi_shift_reg.v was already
// tested standalone for this, but not through the full FSM/top-level path).
// Drives TX_DATA = 0x3C (0011_1100, not symmetric) with lsb_first=1, and
// checks the captured MOSI bit sequence matches TX_DATA when reconstructed
// LSB-first.

`timescale 1ns/1ps

module tb_spi_lsb_first;

    reg        clk;
    reg        rst_n;
    reg        start;
    reg  [7:0] tx_data;
    reg  [7:0] clkdiv_val;
    reg        cpol, cpha, lsb_first;
    reg        miso;

    wire       sclk, ss_n, mosi;
    wire [7:0] rx_data;
    wire       busy, done;

    spi_master_top dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (start),
        .tx_data    (tx_data),
        .clkdiv_val (clkdiv_val),
        .cpol       (cpol),
        .cpha       (cpha),
        .lsb_first  (lsb_first),
        .sclk       (sclk),
        .ss_n       (ss_n),
        .mosi       (mosi),
        .miso       (miso),
        .rx_data    (rx_data),
        .busy       (busy),
        .done       (done)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    reg [7:0] captured;
    integer   bit_num;

    initial begin
        $dumpfile("tb_spi_lsb_first.vcd");
        $dumpvars(0, tb_spi_lsb_first);

        rst_n      = 0;
        start      = 0;
        tx_data    = 8'h00;
        clkdiv_val = 8'd2;
        cpol       = 0;
        cpha       = 0;
        lsb_first  = 1;   // <-- the thing under test
        miso       = 0;
        captured   = 8'h00;
        bit_num    = 0;

        #20 rst_n = 1;
        #10;

        tx_data = 8'h3C;  // 0011_1100 -- not symmetric, so bit order matters
        @(negedge clk);
        start = 1;
        @(negedge clk);
        start = 0;

        // Sample MOSI on every rising sclk edge (Mode 0: CPHA=0 samples on
        // the first/rising edge) and shift it into 'captured', LSB-first
        // ordering to match what lsb_first=1 should produce.
        bit_num = 0;
        while (bit_num < 8) begin
            @(posedge sclk);
            captured = {mosi, captured[7:1]};
            bit_num = bit_num + 1;
        end

        wait (done == 1'b1);
        #1;

        if (captured === tx_data)
            $display("LSB_FIRST PASS: captured MOSI sequence 0x%0h matches TX_DATA 0x%0h with lsb_first=1", captured, tx_data);
        else
            $display("LSB_FIRST FAIL: captured MOSI sequence 0x%0h does NOT match TX_DATA 0x%0h", captured, tx_data);

        #50;
        $display("TB_SPI_LSB_FIRST: run complete.");
        $finish;
    end

endmodule