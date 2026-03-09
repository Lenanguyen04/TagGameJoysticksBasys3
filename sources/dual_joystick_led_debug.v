`timescale 1ns / 1ps

module dual_joystick_led_debug(
    input  wire [9:0] joy1_x,
    input  wire [9:0] joy1_y,
    input  wire [9:0] joy2_x,
    input  wire [9:0] joy2_y,
    output wire [15:0] led
);

    wire [7:0] led_j1;
    wire [7:0] led_j2;

    joystick_debug_2led dbg1 (
        .DataX(joy1_x),
        .DataY(joy1_y),
        .led_out(led_j1)
    );

    joystick_debug_2led dbg2 (
        .DataX(joy2_x),
        .DataY(joy2_y),
        .led_out(led_j2)
    );

    assign led[7:0]   = led_j1;  // joystick on JA
    assign led[15:8] = {
        led_j2[4],  // down   -> led[11:10]
        led_j2[5],
        led_j2[6],
        led_j2[7],   // up     -> led[9:8]
        led_j2[0],  // right  -> led[15:14]
        led_j2[1],
        led_j2[2],  // left   -> led[13:12]
        led_j2[3]
    };

endmodule