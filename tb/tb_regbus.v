// tb_regbus.v
// Simulates a host driving the register bus: configure CTRL/CLKDIV,
// write TX_DATA to trigger a transfer, poll STATUS for DONE, read RX_DATA.
// Also tests ENABLE gating and SS_SEL multi-slave decode.

`timescale 1ns/1ps

module tb_regbus;

    reg        clk;
    reg        rst_n;
    reg  [7:0] addr;
    reg  [7:0] wdata;
    reg        wr_en;
    reg        rd_en;
    wire [7:0] rdata;

    wire       sclk, mosi;
    wire [3:0] ss_n;
    reg        miso;

    spi_master_regbus_top dut (
        .clk    (clk),
        .rst_n  (rst_n),
        .addr   (addr),
        .wdata  (wdata),
        .wr_en  (wr_en),
        .rd_en  (rd_en),
        .rdata  (rdata),
        .sclk   (sclk),
        .ss_n   (ss_n),
        .mosi   (mosi),
        .miso   (miso)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    localparam ADDR_CTRL    = 8'h00,
               ADDR_STATUS  = 8'h04,
               ADDR_CLKDIV  = 8'h08,
               ADDR_TX_DATA = 8'h0C,
               ADDR_RX_DATA = 8'h10,
               ADDR_SS_SEL  = 8'h14;

    task reg_write(input [7:0] a, input [7:0] d);
        begin
            @(negedge clk);
            addr  = a;
            wdata = d;
            wr_en = 1;
            @(negedge clk);
            wr_en = 0;
        end
    endtask

    task reg_read(input [7:0] a, output [7:0] d);
        begin
            @(negedge clk);
            addr  = a;
            rd_en = 1;
            #1;
            d = rdata;
            @(negedge clk);
            rd_en = 0;
        end
    endtask

    reg [7:0] status_val;
    reg [7:0] rx_val;
    integer   timeout;

    initial begin
        $dumpfile("tb_regbus.vcd");
        $dumpvars(0, tb_regbus);

        rst_n = 0;
        addr  = 0; wdata = 0; wr_en = 0; rd_en = 0; miso = 0;
        #20 rst_n = 1;
        #10;

        reg_write(ADDR_CTRL, 8'b0000_0001);
        $display("REGBUS: wrote CTRL = 0x01 (ENABLE=1, Mode 0)");

        reg_write(ADDR_CLKDIV, 8'd2);
        $display("REGBUS: wrote CLKDIV = 2");

        reg_write(ADDR_TX_DATA, 8'hA5);
        $display("REGBUS: wrote TX_DATA = 0xA5 (triggers transfer)");

        timeout = 0;
        status_val = 8'h00;
        while (!status_val[1] && timeout < 200) begin
            reg_read(ADDR_STATUS, status_val);
            timeout = timeout + 1;
        end

        if (status_val[1])
            $display("REGBUS PASS: STATUS.DONE set after %0d polls (status=0x%0h)", timeout, status_val);
        else
            $display("REGBUS FAIL: STATUS.DONE never set (timeout)");

        reg_read(ADDR_RX_DATA, rx_val);
        $display("REGBUS INFO: RX_DATA = 0x%0h", rx_val);

        reg_write(ADDR_STATUS, 8'b0000_0010);
        reg_read(ADDR_STATUS, status_val);
        if (!status_val[1])
            $display("REGBUS PASS: STATUS.DONE cleared successfully (status=0x%0h)", status_val);
        else
            $display("REGBUS FAIL: STATUS.DONE did not clear (status=0x%0h)", status_val);

        reg_read(ADDR_CTRL, status_val);
        if (status_val == 8'b0000_0001)
            $display("REGBUS PASS: CTRL readback matches what was written (0x01)");
        else
            $display("REGBUS FAIL: CTRL readback = 0x%0h, expected 0x01", status_val);

        reg_write(ADDR_CTRL, 8'b0000_0000);
        reg_write(ADDR_STATUS, 8'b0000_0010);
        reg_write(ADDR_TX_DATA, 8'hFF);
        #100;
        reg_read(ADDR_STATUS, status_val);
        if (!status_val[1])
            $display("ENABLE-GATE PASS: no transfer occurred while ENABLE=0 (status=0x%0h)", status_val);
        else
            $display("ENABLE-GATE FAIL: transfer completed despite ENABLE=0 (status=0x%0h)", status_val);

        reg_write(ADDR_CTRL, 8'b0000_0001);
        reg_write(ADDR_TX_DATA, 8'h3C);
        timeout = 0;
        status_val = 8'h00;
        while (!status_val[1] && timeout < 200) begin
            reg_read(ADDR_STATUS, status_val);
            timeout = timeout + 1;
        end
        if (status_val[1])
            $display("ENABLE-GATE PASS: transfer completes normally after re-enabling (status=0x%0h)", status_val);
        else
            $display("ENABLE-GATE FAIL: transfer did not complete after re-enabling");

        reg_write(ADDR_STATUS, 8'b0000_0010);
        reg_write(ADDR_SS_SEL, 8'b0000_0100);
        reg_write(ADDR_TX_DATA, 8'h5A);
        #30;
        if (ss_n[2] == 1'b0 && ss_n[0] == 1'b1 && ss_n[1] == 1'b1 && ss_n[3] == 1'b1)
            $display("SS_SEL PASS: only ss_n[2] asserted low during transfer (ss_n=%b)", ss_n);
        else
            $display("SS_SEL FAIL: unexpected ss_n pattern during transfer (ss_n=%b)", ss_n);

        timeout = 0;
        status_val = 8'h00;
        while (!status_val[1] && timeout < 200) begin
            reg_read(ADDR_STATUS, status_val);
            timeout = timeout + 1;
        end

        #50;
        $display("TB_REGBUS: run complete.");
        $finish;
    end

endmodule