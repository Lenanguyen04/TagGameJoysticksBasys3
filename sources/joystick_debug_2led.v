`timescale 1ns / 1ps

module joystick_debug_2led(
    input  wire [9:0] DataX,
    input  wire [9:0] DataY,
    output reg  [7:0] led_out
);

    localparam integer CENTER    = 10'd512;
    localparam integer LOW_ZONE  = 10'd448;
    localparam integer HIGH_ZONE = 10'd576;

    localparam integer MAG_DEAD = 10'd30;
    localparam integer MAG_MAX  = 10'd240;

    reg [9:0] x_mag;
    reg [9:0] y_mag;
    reg [1:0] x_level;
    reg [1:0] y_level;

    always @* begin
        led_out = 8'b00000000;
        x_mag   = 10'd0;
        y_mag   = 10'd0;
        x_level = 2'd0;
        y_level = 2'd0;

        if (DataX >= CENTER)
            x_mag = DataX - CENTER;
        else
            x_mag = CENTER - DataX;

        if (DataY >= CENTER)
            y_mag = DataY - CENTER;
        else
            y_mag = CENTER - DataY;

        if (x_mag < MAG_DEAD)
            x_level = 2'd0;
        else if (x_mag < (MAG_MAX >> 1))
            x_level = 2'd1;
        else
            x_level = 2'd2;

        if (y_mag < MAG_DEAD)
            y_level = 2'd0;
        else if (y_mag < (MAG_MAX >> 1))
            y_level = 2'd1;
        else
            y_level = 2'd2;

        // [7:6] up, [5:4] down, [3:2] left, [1:0] right

        if (DataY < LOW_ZONE) begin
            case (y_level)
                2'd0: led_out[7:6] = 2'b00;
                2'd1: led_out[7:6] = 2'b01;
                2'd2: led_out[7:6] = 2'b11;
                default: led_out[7:6] = 2'b00;
            endcase
            led_out[5:4] = 2'b00;
        end
        else if (DataY > HIGH_ZONE) begin
            led_out[7:6] = 2'b00;
            case (y_level)
                2'd0: led_out[5:4] = 2'b00;
                2'd1: led_out[5:4] = 2'b10;
                2'd2: led_out[5:4] = 2'b11;
                default: led_out[5:4] = 2'b00;
            endcase
        end
        else begin
            led_out[7:4] = 4'b0000;
        end

        if (DataX < LOW_ZONE) begin
            case (x_level)
                2'd0: led_out[3:2] = 2'b00;
                2'd1: led_out[3:2] = 2'b01;
                2'd2: led_out[3:2] = 2'b11;
                default: led_out[3:2] = 2'b00;
            endcase
            led_out[1:0] = 2'b00;
        end
        else if (DataX > HIGH_ZONE) begin
            led_out[3:2] = 2'b00;
            case (x_level)
                2'd0: led_out[1:0] = 2'b00;
                2'd1: led_out[1:0] = 2'b10;
                2'd2: led_out[1:0] = 2'b11;
                default: led_out[1:0] = 2'b00;
            endcase
        end
        else begin
            led_out[3:0] = 4'b0000;
        end
    end

endmodule