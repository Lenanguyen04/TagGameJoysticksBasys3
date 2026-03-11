`timescale 1ns / 1ps

module top(
    input  wire clk_100MHz,
    input  wire reset,

    // VGA
    output wire hsync,
    output wire vsync,
    output wire [11:0] rgb,

    // JA joystick
    input  wire MISO1,
    output wire MOSI1,
    output wire SCK1,
    output wire SS1,

    // JB joystick
    input  wire MISO2,
    output wire MOSI2,
    output wire SCK2,
    output wire SS2,

    // LEDs
    output wire [15:0] led,

    // Seven Segment Display
    output wire [3:0] anode_activate,
    output wire [6:0] LED_out
);

    wire timer_expired;
    wire game_over;
    wire winner;

    // ----- Parameters for VGA -----
    wire w_video_on, w_p_tick;
    wire [9:0] w_x, w_y;
    reg  [11:0] rgb_reg;
    wire [11:0] rgb_next;

    // ----- Parameters for joysticks -----
    wire [39:0] jstkData1;
    wire [39:0] jstkData2;
    
    // Coordinates and button
    wire [9:0] joy1_x;
    wire [9:0] joy1_y;
    wire [9:0] joy2_x;
    wire [9:0] joy2_y;
    wire joy2_btn;

    // Shield parameters
    wire clk_100hz;
    wire shield_active;
    wire flash_toggle;
    wire [15:0] shield_led;
    
    PmodJSTK_Dual_hw joysticks (    // Gets data from the joysticks
        .CLK(clk_100MHz),
        .RST(reset),

        .MISO1(MISO1),
        .MISO2(MISO2),

        .MOSI1(MOSI1),
        .MOSI2(MOSI2),
        .SCK1(SCK1),
        .SCK2(SCK2),
        .SS1(SS1),
        .SS2(SS2),

        .DOUT1(jstkData1),
        .DOUT2(jstkData2)
    );

    // decode the coordinates and button
    assign joy1_y = {jstkData1[25:24], jstkData1[39:32]};
    assign joy1_x = {jstkData1[9:8],   jstkData1[23:16]};

    assign joy2_y = {jstkData2[25:24], jstkData2[39:32]};
    assign joy2_x = {jstkData2[9:8],   jstkData2[23:16]};

    assign joy2_btn = jstkData2[1]; // TODO: possibly 0
    assign led = shield_led;

    ClkDiv_100Hz shield_clk (
        .CLK(clk_100MHz),
        .RST(reset),
        .CLKOUT(clk_100hz)
    );

    shield_controller shield (
        .clk_100hz(clk_100hz),
        .reset(reset),
        .button_pressed(joy2_btn),
        .shield_active(shield_active),
        .flash_toggle(flash_toggle),
        .led(shield_led)
    );

    countdown_timer_ssd #(
        .START_SECONDS(20)
    ) round_timer (
        .clk(clk_100MHz),
        .reset(reset),
        .enable(~game_over),
        .anode_activate(anode_activate),
        .LED_out(LED_out),
        .expired(timer_expired)
    );

    vga_controller vc (
        .clk(clk_100MHz),
        .reset(reset),
        .video_on(w_video_on),
        .hsync(hsync),
        .vsync(vsync),
        .p_tick(w_p_tick),
        .x(w_x),
        .y(w_y)
    );

    pixel_generation pg (
        .clk(clk_100MHz),
        .reset(reset),
        .video_on(w_video_on),
        .joystick1_x(joy1_x),
        .joystick1_y(joy1_y),
        .joystick2_x(joy2_x),
        .joystick2_y(joy2_y),
        .shield_active(shield_active),
        .flash_toggle(flash_toggle),
        .time_expired(timer_expired),
        .x(w_x),
        .y(w_y),
        .rgb(rgb_next),
        .game_over(game_over),
        .winner(winner)
    );

    always @(posedge clk_100MHz) begin
        if (w_p_tick)
            rgb_reg <= rgb_next;
    end

    assign rgb = rgb_reg;

endmodule
