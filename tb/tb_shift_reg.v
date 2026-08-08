// tb_shift_reg.v
// Standalone testbench for spi_shift_reg: loads a known byte, shifts it out
// MSB-first, checks each output bit against expected value.

`timescale 1ns/1ps

module tb_shift_reg;

    reg        clk;
    reg        rst_n;
    reg        load;
    reg        shift;
    reg        lsb_first;
    reg  [7:0] tx_data;
    reg        miso_bit_in;
    wire       mosi_bit_out;
    wire [7:0] rx_data;

    spi_shift_reg dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .load         (load),
        .shift        (shift),
        .lsb_first    (lsb_first),
        .tx_data      (tx_data),
        .miso_bit_in  (miso_bit_in),
        .mosi_bit_out (mosi_bit_out),
        .rx_data      (rx_data)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer i;
    reg [7:0] expected;
    reg       pass;

    initial begin
        $dumpfile("tb_shift_reg.vcd");
        $dumpvars(0, tb_shift_reg);

        rst_n       = 0;
        load        = 0;
        shift       = 0;
        lsb_first   = 0;      // MSB-first test
        tx_data     = 8'hA5;  // 1010_0101
        miso_bit_in = 0;
        pass        = 1;

        #12 rst_n = 1;

        // Load the byte
        @(negedge clk);
        load = 1;
        @(negedge clk);
        load = 0;

        // Check MSB-first output bit by bit
        expected = 8'hA5;
        for (i = 7; i >= 0; i = i - 1) begin
            if (mosi_bit_out !== expected[i]) begin
                $display("FAIL: bit %0d expected %b got %b", i, expected[i], mosi_bit_out);
                pass = 0;
            end else begin
                $display("PASS: bit %0d = %b as expected", i, mosi_bit_out);
            end
            @(negedge clk);
            shift = 1;
            @(negedge clk);
            shift = 0;
        end

        if (pass)
            $display("TB_SHIFT_REG: ALL TESTS PASSED");
        else
            $display("TB_SHIFT_REG: SOME TESTS FAILED");

        $finish;
    end

endmodule
