`timescale 1ns / 1ps

module button_debug_leds(
    input  wire [39:0] jstkData1,
    input  wire [39:0] jstkData2,
    input  wire        joy2_btn_selected,
    input  wire        shield_active,
    input  wire        flash_toggle,
    input  wire [15:0] shield_led,
    output reg  [15:0] led
);

    always @* begin
        led = 16'h0000;

        // Raw candidate button bits from joystick 1
        led[0] = jstkData1[0];
        led[1] = jstkData1[1];

        // Raw candidate button bits from joystick 2
        led[2] = jstkData2[0];
        led[3] = jstkData2[1];

        // The bit currently selected in top.v as joy2_btn
        led[4] = joy2_btn_selected;

        // Shield state visibility
        led[5] = shield_active;
        led[6] = flash_toggle;

        // Keep part of the shield bar visible too
        led[15:7] = shield_led[15:7];
    end

endmodule
