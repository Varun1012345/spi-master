// spi_regfile.v
// Simple synchronous register bus interface for the SPI master.
// Register map (see docs/spi_master_spec.md section 3):
//   0x00 CTRL    [0]=ENABLE [1]=CPOL [2]=CPHA [3]=LSB_FIRST
//   0x04 STATUS  [0]=BUSY   [1]=DONE (write 1 to clear) [2]=TX_EMPTY
//   0x08 CLKDIV  8-bit divider value
//   0x0C TX_DATA writing here triggers a transfer (pulses 'start' for 1 cycle)
//   0x10 RX_DATA last received byte (read-only)
//   0x14 SS_SEL  4-bit one-hot slave select

module spi_regfile (
    input  wire       clk,
    input  wire       rst_n,

    input  wire [7:0] addr,
    input  wire [7:0] wdata,
    input  wire       wr_en,
    input  wire       rd_en,
    output reg  [7:0] rdata,

    output wire        enable,
    output wire        cpol,
    output wire        cpha,
    output wire        lsb_first,
    output reg  [7:0]  clkdiv_val,
    output reg  [3:0]  ss_sel,
    output reg  [7:0]  tx_data,
    output reg         start,

    input  wire [7:0]  rx_data_in,
    input  wire        busy_in,
    input  wire        done_in
);

    localparam ADDR_CTRL    = 8'h00,
               ADDR_STATUS  = 8'h04,
               ADDR_CLKDIV  = 8'h08,
               ADDR_TX_DATA = 8'h0C,
               ADDR_RX_DATA = 8'h10,
               ADDR_SS_SEL  = 8'h14;

    reg [7:0] ctrl_reg;
    reg       done_latched;

    assign enable    = ctrl_reg[0];
    assign cpol      = ctrl_reg[1];
    assign cpha      = ctrl_reg[2];
    assign lsb_first = ctrl_reg[3];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_reg     <= 8'h00;
            clkdiv_val   <= 8'h00;
            ss_sel       <= 4'h1;
            tx_data      <= 8'h00;
            start        <= 1'b0;
            done_latched <= 1'b0;
        end else begin
            start <= 1'b0;

            if (wr_en) begin
                case (addr)
                    ADDR_CTRL:    ctrl_reg   <= wdata;
                    ADDR_CLKDIV:  clkdiv_val <= wdata;
                    ADDR_TX_DATA: begin
                        tx_data <= wdata;
                        if (ctrl_reg[0])
                            start <= 1'b1;
                    end
                    ADDR_SS_SEL:  ss_sel <= wdata[3:0];
                    ADDR_STATUS:  if (wdata[1]) done_latched <= 1'b0;
                    default: ;
                endcase
            end

            if (done_in)
                done_latched <= 1'b1;
        end
    end

    always @(*) begin
        case (addr)
            ADDR_CTRL:    rdata = ctrl_reg;
            ADDR_STATUS:  rdata = {5'b0, ~busy_in, done_latched, busy_in};
            ADDR_CLKDIV:  rdata = clkdiv_val;
            ADDR_RX_DATA: rdata = rx_data_in;
            ADDR_SS_SEL:  rdata = {4'b0, ss_sel};
            default:      rdata = 8'h00;
        endcase
    end

endmodule