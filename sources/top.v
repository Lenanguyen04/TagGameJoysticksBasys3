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

    // Seven Segement Display
    output wire [3:0] anode_activate,
    output wire [6:0] LED_out
);

    wire tag_switch_pulse;
    wire timer_expired;
    
    // ----- VGA -----
    wire w_video_on, w_p_tick;
    wire [9:0] w_x, w_y;
    reg  [11:0] rgb_reg;
    wire [11:0] rgb_next;

    // ----- Joystick packets -----
    wire [39:0] jstkData1;
    wire [39:0] jstkData2;

    // ----- Decoded joystick values -----
    wire [9:0] joy1_x;
    wire [9:0] joy1_y;
    wire [9:0] joy2_x;
    wire [9:0] joy2_y;
    wire joy1_btn;
    wire joy2_btn;

    // ----- 100 Hz shield clock -----
    wire clk_100hz;

    // ----- Button pulses -----
    reg joy1_btn_d;
    reg joy2_btn_d;
    wire joy1_btn_pulse;
    wire joy2_btn_pulse;

    // ----- Shield controller outputs -----
    wire p1_shield_active;
    wire p1_flash_toggle;
    wire [7:0] p1_shield_led_bank;

    wire p2_shield_active;
    wire p2_flash_toggle;
    wire [7:0] p2_shield_led_bank;

    // ----------------------------------------------------------------
    // Dual joystick reader
    // ----------------------------------------------------------------
    PmodJSTK_Dual_hw joysticks (
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

    // Decode coordinates
    assign joy1_y = {jstkData1[25:24], jstkData1[39:32]};
    assign joy1_x = {jstkData1[9:8],   jstkData1[23:16]};

    assign joy2_y = {jstkData2[25:24], jstkData2[39:32]};
    assign joy2_x = {jstkData2[9:8],   jstkData2[23:16]};

    // Confirmed button bit
    assign joy1_btn = jstkData1[1];
    assign joy2_btn = jstkData2[1];

    // Shield timing clock
    ClkDiv_100Hz shield_clk (
        .CLK(clk_100MHz),
        .RST(reset),
        .CLKOUT(clk_100hz)
    );

    // Button edge detect at 100 Hz
    always @(posedge clk_100hz or posedge reset) begin
        if (reset) begin
            joy1_btn_d <= 1'b0;
            joy2_btn_d <= 1'b0;
        end
        else begin
            joy1_btn_d <= joy1_btn;
            joy2_btn_d <= joy2_btn;
        end
    end

    assign joy1_btn_pulse = joy1_btn & ~joy1_btn_d;
    assign joy2_btn_pulse = joy2_btn & ~joy2_btn_d;

    // ----------------------------------------------------------------
    // Player 1 shield controller (upper LED bank style)
    // ----------------------------------------------------------------
    shield_controller #(
        .MIRROR(0)
    ) shield_p1 (
        .clk_100hz(clk_100hz),
        .reset(reset),
        .button_level(joy1_btn),
        .button_pressed(joy1_btn_pulse),
        .shield_active(p1_shield_active),
        .flash_toggle(p1_flash_toggle),
        .led_bank(p1_shield_led_bank)
    );

    // ----------------------------------------------------------------
    // Player 2 shield controller (lower LED bank mirrored style)
    // ----------------------------------------------------------------
    shield_controller #(
        .MIRROR(1)
    ) shield_p2 (
        .clk_100hz(clk_100hz),
        .reset(reset),
        .button_level(joy2_btn),
        .button_pressed(joy2_btn_pulse),
        .shield_active(p2_shield_active),
        .flash_toggle(p2_flash_toggle),
        .led_bank(p2_shield_led_bank)
    );

    // LED mapping
    assign led[15:8] = p1_shield_led_bank;
    assign led[7:0]  = p2_shield_led_bank;

    // ----------------------------------------------------------------
    // VGA
    // ----------------------------------------------------------------
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

    countdown_timer_ssd #(
        .START_SECONDS(5)
    ) timer_inst (
        .clk(clk_100MHz),
        .reset(reset),
        .enable(1'b1),              // or !game_over if you expose that
        .anode_activate(anode_activate),
        .LED_out(LED_out),
        .expired(timer_expired),
        .swap_pulse(tag_switch_pulse)
    );
    
    pixel_generation pg (
        .clk(clk_100MHz),
        .reset(reset),
        .video_on(w_video_on),

        .joystick1_x(joy1_x),
        .joystick1_y(joy1_y),
        .joystick2_x(joy2_x),
        .joystick2_y(joy2_y),

        .p1_shield_active(p1_shield_active),
        .p1_flash_toggle(p1_flash_toggle),
        .p2_shield_active(p2_shield_active),
        .p2_flash_toggle(p2_flash_toggle),

        .tag_switch(tag_switch_pulse),

        .x(w_x),
        .y(w_y),
        .rgb(rgb_next)
    );

    always @(posedge clk_100MHz) begin
        if (w_p_tick)
            rgb_reg <= rgb_next;
    end

    assign rgb = rgb_reg;

endmodule
