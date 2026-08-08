// spi_shift_reg.v
// 8-bit shift register for SPI data path.
// On 'load', parallel-loads tx_data and drives miso_bit_out via the MSB.
// On 'shift', shifts left (MSB-first) or right (LSB-first), capturing
// miso_bit_in into the empty end. rx_data reflects current register content.

module spi_shift_reg (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       load,          // parallel load tx_data into shreg
    input  wire       shift,         // shift by one bit
    input  wire        lsb_first,     // 0 = MSB first, 1 = LSB first
    input  wire [7:0] tx_data,       // byte to transmit
    input  wire       miso_bit_in,   // incoming bit from slave
    output wire        mosi_bit_out,  // current outgoing bit
    output wire [7:0] rx_data        // captured received byte
);

    reg [7:0] shreg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shreg <= 8'h00;
        end else if (load) begin
            shreg <= tx_data;
        end else if (shift) begin
            if (lsb_first)
                shreg <= {miso_bit_in, shreg[7:1]};   // shift right, capture at MSB
            else
                shreg <= {shreg[6:0], miso_bit_in};   // shift left, capture at LSB
        end
    end

    // Outgoing bit: MSB for MSB-first, LSB for LSB-first
    assign mosi_bit_out = lsb_first ? shreg[0] : shreg[7];
    assign rx_data       = shreg;

endmodule
