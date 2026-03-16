`timescale 1ns / 1ps

module ClkDiv_100Hz(
    input  CLK,
    input  RST,
    output reg CLKOUT
);

    // Toggle every 500,000 clocks:
    // 100 MHz / (2 * 500,000) = 100 Hz
    parameter cntEndVal = 19'd499999;
    reg [18:0] clkCount;

    always @(posedge CLK) begin
        if (RST) begin
            CLKOUT   <= 1'b0;
            clkCount <= 19'd0;
        end
        else begin
            if (clkCount == cntEndVal) begin
                CLKOUT   <= ~CLKOUT;
                clkCount <= 19'd0;
            end
            else begin
                clkCount <= clkCount + 1'b1;
            end
        end
    end

endmodule