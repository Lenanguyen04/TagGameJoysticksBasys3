`timescale 1ns / 1ps

module pixel_generation(
    input  wire        clk,
    input  wire        reset,
    input  wire        video_on,

    input  wire [9:0]  joystick_x,
    input  wire [9:0]  joystick_y,

    input  wire [9:0]  x, y,
    output reg  [11:0] rgb
);

    localparam integer X_MAX = 639;
    localparam integer Y_MAX = 479;

    localparam [11:0] SQ_RGB = 12'h0FF; // yellow
    localparam [11:0] BG_RGB = 12'hF00; // blue-ish background in your original

    localparam integer SQUARE_SIZE = 64;

    // 60 Hz-ish refresh tick (same idea as your original)
    wire refresh_tick = (y == 10'd481) && (x == 10'd0);

    // joystick raw: 0..255
    wire [7:0] jx = joystick_x[7:0];
    wire [7:0] jy = joystick_y[7:0];

    // keep square fully on screen
    localparam integer X_LIM = X_MAX - (SQUARE_SIZE - 1);  // max left x
    localparam integer Y_LIM = Y_MAX - (SQUARE_SIZE - 1);  // max top y

    // scale: (jx * X_LIM) / 256
    wire [17:0] mul_x = jx * X_LIM;
    wire [17:0] mul_y = jy * Y_LIM;

    wire [9:0] x_target = mul_x[17:8];
    wire [9:0] y_target = mul_y[17:8];

    reg [9:0] sq_x_reg, sq_y_reg;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sq_x_reg <= 10'd0;
            sq_y_reg <= 10'd0;
        end else if (refresh_tick) begin
            sq_x_reg <= x_target;
            sq_y_reg <= y_target;
        end
    end

    wire [9:0] sq_x_l = sq_x_reg;
    wire [9:0] sq_y_t = sq_y_reg;
    wire [9:0] sq_x_r = sq_x_l + SQUARE_SIZE - 1;
    wire [9:0] sq_y_b = sq_y_t + SQUARE_SIZE - 1;

    wire sq_on = (sq_x_l <= x) && (x <= sq_x_r) &&
                 (sq_y_t <= y) && (y <= sq_y_b);

    always @* begin
        if (!video_on)       rgb = 12'h000;
        else if (sq_on)      rgb = SQ_RGB;
        else                 rgb = BG_RGB;
    end

endmodule


