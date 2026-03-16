`timescale 1ns / 1ps

module shield_controller #(
    parameter MIRROR = 0   // 0 = player1 upper bank, 1 = player2 lower bank
)(
    input  wire clk_100hz,
    input  wire reset,
    input  wire button_level,     // raw held level for debug LED
    input  wire button_pressed,   // one-shot pulse for state transition
    output reg  shield_active,
    output reg  flash_toggle,
    output reg  [7:0] led_bank
);

    localparam SHIELD_READY    = 2'd0;
    localparam SHIELD_ACTIVE   = 2'd1;
    localparam SHIELD_COOLDOWN = 2'd2;

    reg [1:0] state;
    reg [9:0] timer;

    reg [5:0] bar;

    // ------------------------------------------------------------
    // State machine
    // ------------------------------------------------------------
    always @(posedge clk_100hz or posedge reset) begin
        if (reset) begin
            state         <= SHIELD_READY;
            timer         <= 10'd0;
            shield_active <= 1'b0;
            flash_toggle  <= 1'b0;
        end
        else begin
            case (state)
                SHIELD_READY: begin
                    state         <= SHIELD_READY;
                    timer         <= 10'd0;
                    shield_active <= 1'b0;
                    flash_toggle  <= 1'b0;

                    if (button_pressed) begin
                        state         <= SHIELD_ACTIVE;
                        timer         <= 10'd0;
                        shield_active <= 1'b1;
                        flash_toggle  <= 1'b0;
                    end
                end

                SHIELD_ACTIVE: begin
                    shield_active <= 1'b1;
                    timer         <= timer + 10'd1;

                    if (timer % 10 == 0)
                        flash_toggle <= ~flash_toggle;

                    if (timer == 10'd399) begin
                        state         <= SHIELD_COOLDOWN;
                        timer         <= 10'd0;
                        shield_active <= 1'b0;
                        flash_toggle  <= 1'b0;
                    end
                end

                SHIELD_COOLDOWN: begin
                    shield_active <= 1'b0;
                    flash_toggle  <= 1'b0;
                    timer         <= timer + 10'd1;

                    if (timer == 10'd799) begin
                        state         <= SHIELD_READY;
                        timer         <= 10'd0;
                        shield_active <= 1'b0;
                        flash_toggle  <= 1'b0;
                    end
                end

                default: begin
                    state         <= SHIELD_READY;
                    timer         <= 10'd0;
                    shield_active <= 1'b0;
                    flash_toggle  <= 1'b0;
                end
            endcase
        end
    end

    // ------------------------------------------------------------
    // 6-bit shield bar generation
    //
    // Upper-bank style (player 1):
    // READY:    111111
    // ACTIVE:   111111,111110,111100,111000,110000,100000,000000
    // COOLDOWN: 000000,100000,110000,111000,111100,111110,111111
    //
    // Lower-bank mirrored style (player 2):
    // READY:    111111
    // ACTIVE:   111111,011111,001111,000111,000011,000001,000000
    // COOLDOWN: 000000,000001,000011,000111,001111,011111,111111
    // ------------------------------------------------------------
    always @* begin
        bar = 6'b111111;

        case (state)
            SHIELD_READY: begin
                bar = 6'b111111;
            end

            SHIELD_ACTIVE: begin
                if (MIRROR == 0) begin
                    if      (timer < 10'd67)  bar = 6'b111111;
                    else if (timer < 10'd134) bar = 6'b111110;
                    else if (timer < 10'd201) bar = 6'b111100;
                    else if (timer < 10'd268) bar = 6'b111000;
                    else if (timer < 10'd335) bar = 6'b110000;
                    else if (timer < 10'd399) bar = 6'b100000;
                    else                      bar = 6'b000000;
                end
                else begin
                    if      (timer < 10'd67)  bar = 6'b111111;
                    else if (timer < 10'd134) bar = 6'b011111;
                    else if (timer < 10'd201) bar = 6'b001111;
                    else if (timer < 10'd268) bar = 6'b000111;
                    else if (timer < 10'd335) bar = 6'b000011;
                    else if (timer < 10'd399) bar = 6'b000001;
                    else                      bar = 6'b000000;
                end
            end

            SHIELD_COOLDOWN: begin
                if (MIRROR == 0) begin
                    if      (timer < 10'd133) bar = 6'b000000;
                    else if (timer < 10'd266) bar = 6'b100000;
                    else if (timer < 10'd399) bar = 6'b110000;
                    else if (timer < 10'd532) bar = 6'b111000;
                    else if (timer < 10'd665) bar = 6'b111100;
                    else if (timer < 10'd798) bar = 6'b111110;
                    else                      bar = 6'b111111;
                end
                else begin
                    if      (timer < 10'd133) bar = 6'b000000;
                    else if (timer < 10'd266) bar = 6'b000001;
                    else if (timer < 10'd399) bar = 6'b000011;
                    else if (timer < 10'd532) bar = 6'b000111;
                    else if (timer < 10'd665) bar = 6'b001111;
                    else if (timer < 10'd798) bar = 6'b011111;
                    else                      bar = 6'b111111;
                end
            end

            default: begin
                bar = 6'b111111;
            end
        endcase
    end

    // ------------------------------------------------------------
    // Exact LED bank mapping
    //
    // Player 1 bank (led[15:8]):
    // bit0 -> led8  = button
    // bit1 -> led9  = active
    // bit2..bit7 -> led10..led15 = bar
    //
    // Player 2 bank (led[7:0]):
    // bit7 -> led7  = button
    // bit6 -> led6  = active
    // bit5..bit0 -> led5..led0  = bar
    // ------------------------------------------------------------
    always @* begin
        if (MIRROR == 0) begin
            led_bank[0] = button_level;
            led_bank[1] = shield_active;
            led_bank[7:2] = bar;
        end
        else begin
            led_bank[7] = button_level;
            led_bank[6] = shield_active;
            led_bank[5:0] = bar;
        end
    end

endmodule
