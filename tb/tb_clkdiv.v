// tb_clkdiv.v
// Simple standalone testbench for spi_clkdiv.
// Confirms sclk_en pulses at the expected rate for a given div value.

`timescale 1ns/1ps

module tb_clkdiv;

    reg        clk;
    reg        rst_n;
    reg        enable;
    reg  [7:0] div;
    wire       sclk_en;

    spi_clkdiv dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .enable  (enable),
        .div     (div),
        .sclk_en (sclk_en)
    );

    // 100MHz system clock -> 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_clkdiv.vcd");
        $dumpvars(0, tb_clkdiv);

        rst_n  = 0;
        enable = 0;
        div    = 8'd3;   // expect sclk_en pulse every 4 cycles (2*(3+1)/2... see note below)

        #20 rst_n = 1;
        #10 enable = 1;

        // run long enough to see several pulses
        #500;

        $display("TB_CLKDIV: simulation finished. Check waveform for sclk_en pulse spacing.");
        $finish;
    end

    // Simple pulse counter/printer for quick sanity check in console
    integer pulse_count;
    initial pulse_count = 0;
    always @(posedge clk) begin
        if (sclk_en) begin
            pulse_count = pulse_count + 1;
            $display("t=%0t : sclk_en pulse #%0d", $time, pulse_count);
        end
    end

endmodule
