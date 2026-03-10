`timescale 1ns / 1ps

module shield_controller(
    input wire clk_100hz,
    input wire reset,
    input wire button_pressed,
    output reg shield_active,
    output reg flash_toggle,
    output reg [15:0] led
);

localparam SHIELD_READY = 2'd0;
localparam SHIELD_ACTIVE = 2'd1;
localparam SHIELD_COOLDOWN = 2'd2;

reg [1:0] state;    // 2 bits for 3 states
reg [9:0] timer;    // 10 bit counter (We need it to count to 900 max)

always @(posedge clk_100hz or posedge reset) begin
    if (reset) begin
        state <= SHIELD_READY;
        timer <= 10'd0;
        shield_active <= 1'b0;
        flash_toggle <= 1'b0;
    end
    else begin
        case (state)
            SHIELD_READY: begin
                timer <= 10'd0;
                shield_active <= 1'b0;
                flash_toggle <= 1'b0;   

                if (button_pressed) begin
                    state <= SHIELD_ACTIVE;
                    timer <= 10'd0;
                    shield_active <= 1'b1;
                end
            end

            SHIELD_ACTIVE: begin
                shield_active <= 1'b1;
                timer <= timer + 10'd1;

                if (timer % 10 == 0)   // Flashes square every 0.10 seconds
                    flash_toggle <= ~flash_toggle;

                if (timer == 10'd399) begin    // Shield is active for 4 seconds
                    state <= SHIELD_COOLDOWN;
                    timer <= 10'd0;
                    shield_active <= 1'b0;
                    flash_toggle <= 1'b0;
                end
            end

            SHIELD_COOLDOWN: begin
                timer <= timer + 10'd1;
                shield_active <= 1'b0;
                flash_toggle <= 1'b0;

                if (timer == 10'd799) begin   // Cooldown is active for 8 seconds
                    state <= SHIELD_READY;
                    timer <= 10'd0;
                end
            end

            default: begin
                state <= SHIELD_READY;
                timer <= 10'd0;
                shield_active <= 1'b0;
                flash_toggle <= 1'b0;

            end
        endcase
    end
end

// LED Controller
always @* begin
    case (state)
        // All LEDs are on 
        SHIELD_READY: begin
            led = 16'hFFFF;
        end

        // LEDs turn off, four at a time (4 sec)
        SHIELD_ACTIVE: begin
            if (timer < 100)
                led = 16'hFFFF;     // 16 LEDs
            else if (timer < 200)
                led = 16'h0FFF;     // 12 LEDs
            else if (timer < 300)
                led = 16'h00FF;     // 8 LEDs
            else if (timer < 400)
                led = 16'h000F;     // 4 LEDs
            else
                led = 16'h0000;     // 0 LEDs
        end

        // LEDs turn on, 2 at a time (8 sec)
        SHIELD_COOLDOWN: begin
            if (timer < 100)
                led = 16'h0000;     // 0 LEDs
            else if (timer < 200)
                led = 16'h0003;     // 2 LEDs
            else if (timer < 300)
                led = 16'h000F;     // 4 LEDs
            else if (timer < 400)
                led = 16'h003F;     // 6 LEDs
            else if (timer < 500)
                led = 16'h00FF;     // 8 LEDs
            else if (timer < 600)
                led = 16'h03FF;     // 10 LEDs
            else if (timer < 700)
                led = 16'h0FFF;     // 12 LEDs
            else if (timer < 800)
                led = 16'h3FFF;     // 14 LEDs
            else
                led = 16'hFFFF;     // 16 LEDs
        end

        default: begin
            led = 16'hFFFF;
        end
    endcase
end
endmodule