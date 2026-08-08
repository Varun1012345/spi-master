// spi_clkdiv.v
// Generates a slower SPI clock enable pulse from the system clock.
// sclk_en pulses high for 1 cycle every 2*(DIV+1) system clock cycles,
// so the resulting SCLK toggles at sysclk / (2*(DIV+1)).

module spi_clkdiv (
    input  wire       clk,        // system clock
    input  wire       rst_n,      // active-low reset
    input  wire        enable,     // 1 = divider running
    input  wire [7:0] div,        // clock divide value
    output reg        sclk_en     // 1-cycle pulse each time SCLK should toggle
);

    reg [7:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count   <= 8'd0;
            sclk_en <= 1'b0;
        end else if (!enable) begin
            count   <= 8'd0;
            sclk_en <= 1'b0;
        end else if (count == div) begin
            count   <= 8'd0;
            sclk_en <= 1'b1;   // pulse: time to toggle SCLK
        end else begin
            count   <= count + 8'd1;
            sclk_en <= 1'b0;
        end
    end

endmodule
