`timescale 1ns / 1ps

module countdown_timer_ssd #(
    parameter START_SECONDS = 10
)(
    input  wire clk,
    input  wire reset,
    input  wire enable,              // count only while game is active
    output reg  [3:0] anode_activate,
    output reg  [6:0] LED_out,
    output reg        expired,       // stays high for the 0-second moment
    output reg        swap_pulse     // 1-clock pulse when timer hits 0
);

    reg [5:0] seconds_remaining;     // enough for 0..59

    reg [3:0] digit0;                // ones
    reg [3:0] digit1;                // tens
    reg [3:0] digit2;                // blank
    reg [3:0] digit3;                // blank
    reg [3:0] LED_BCD;

    reg [1:0] mux_counter;

    // -------------------------
    // 1 Hz tick generator
    // -------------------------
    reg [26:0] sec_counter;
    localparam integer SEC_COUNT_MAX = 100_000_000 - 1;

    wire tick_1Hz = (sec_counter == SEC_COUNT_MAX);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sec_counter <= 27'd0;
        end
        else if (!enable) begin
            sec_counter <= 27'd0;
        end
        else begin
            if (sec_counter == SEC_COUNT_MAX)
                sec_counter <= 27'd0;
            else
                sec_counter <= sec_counter + 1'd1;
        end
    end

    // -------------------------
    // ~400 Hz refresh tick
    // -------------------------
    reg [16:0] refresh_counter;
    localparam integer REFRESH_COUNT_MAX = 250_000 - 1;

    wire tick_400Hz = (refresh_counter == REFRESH_COUNT_MAX);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            refresh_counter <= 17'd0;
        end
        else begin
            if (refresh_counter == REFRESH_COUNT_MAX)
                refresh_counter <= 17'd0;
            else
                refresh_counter <= refresh_counter + 1'd1;
        end
    end

    // -------------------------
    // Countdown logic
    // auto-reload after reaching 0
    // -------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            seconds_remaining <= START_SECONDS[5:0];
            expired           <= 1'b0;
            swap_pulse        <= 1'b0;
        end
        else begin
            swap_pulse <= 1'b0;  // default every cycle

            if (enable && tick_1Hz) begin
                if (seconds_remaining == 0) begin
                    // hold 0 for one second, then restart
                    seconds_remaining <= START_SECONDS[5:0];
                    expired           <= 1'b0;
                end
                else if (seconds_remaining == 1) begin
                    // next displayed value becomes 0, and we trigger swap
                    seconds_remaining <= 6'd0;
                    expired           <= 1'b1;
                    swap_pulse        <= 1'b1;
                end
                else begin
                    seconds_remaining <= seconds_remaining - 1'd1;
                    expired           <= 1'b0;
                end
            end
        end
    end

    // -------------------------
    // Convert to displayed digits
    // blank blank tens ones
    // -------------------------
    always @* begin
        digit0 = seconds_remaining % 10;
        digit1 = seconds_remaining / 10;

        // use 15 as "blank"
        digit2 = 4'd15;
        digit3 = 4'd15;
    end

    // -------------------------
    // Multiplex anodes
    // -------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            mux_counter <= 2'b00;
        end
        else if (tick_400Hz) begin
            mux_counter <= mux_counter + 1'b1;
        end
    end

    always @* begin
        case (mux_counter)
            2'b00: begin
                anode_activate = 4'b1110;
                LED_BCD = digit0;
            end
            2'b01: begin
                anode_activate = 4'b1101;
                LED_BCD = digit1;
            end
            2'b10: begin
                anode_activate = 4'b1011;
                LED_BCD = digit2;
            end
            2'b11: begin
                anode_activate = 4'b0111;
                LED_BCD = digit3;
            end
            default: begin
                anode_activate = 4'b1111;
                LED_BCD = 4'd15;
            end
        endcase
    end

    // -------------------------
    // 7-segment decoder
    // active-low segments
    // -------------------------
    always @* begin
        case (LED_BCD)
            4'd0:  LED_out = 7'b0000001;
            4'd1:  LED_out = 7'b1001111;
            4'd2:  LED_out = 7'b0010010;
            4'd3:  LED_out = 7'b0000110;
            4'd4:  LED_out = 7'b1001100;
            4'd5:  LED_out = 7'b0100100;
            4'd6:  LED_out = 7'b0100000;
            4'd7:  LED_out = 7'b0001111;
            4'd8:  LED_out = 7'b0000000;
            4'd9:  LED_out = 7'b0000100;
            default: LED_out = 7'b1111111; // blank
        endcase
    end

endmodule
