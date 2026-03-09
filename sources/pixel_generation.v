`timescale 1ns / 1ps

module pixel_generation(
    input  wire        clk,
    input  wire        reset,
    input  wire        video_on,

    input  wire [9:0]  joystick1_x,
    input  wire [9:0]  joystick1_y,
    input  wire [9:0]  joystick2_x,
    input  wire [9:0]  joystick2_y,

    input  wire [9:0]  x, y,
    output reg  [11:0] rgb
);

    localparam integer X_MAX = 639;
    localparam integer Y_MAX = 479;

    localparam [11:0] SQ1_RGB = 12'h0FF; // yellow
    localparam [11:0] SQ2_RGB = 12'h0F0;    // green or red?
    localparam [11:0] BG_RGB = 12'hF00; // blue

    localparam integer SQUARE_SIZE = 64;

    // 60 Hz-ish refresh tick (same idea as your original)
    wire refresh_tick = (y == 10'd481) && (x == 10'd0);

    // joystick raw: 0..255
    wire [7:0] j1x = joystick1_x[9:2];
    wire [7:0] j1y = joystick1_y[9:2];
    wire [7:0] j2x = joystick2_x[9:2];
    wire [7:0] j2y = joystick2_y[9:2];

    // keep square fully on screen
    localparam integer X_LIM = X_MAX - (SQUARE_SIZE - 1);  // max left x
    localparam integer Y_LIM = Y_MAX - (SQUARE_SIZE - 1);  // max top y

    // scale: (jx * X_LIM) / 256
    wire [17:0] mul1_x = j1x * X_LIM;
    wire [17:0] mul1_y = j1y * Y_LIM;
    wire [9:0] x1_target = mul1_x[17:8];
    wire [9:0] y1_target = mul1_y[17:8];
    
    wire [17:0] mul2_x = j2x * X_LIM;
    wire [17:0] mul2_y = j2y * Y_LIM;
    wire [9:0] x2_target = mul2_x[17:8];
    wire [9:0] y2_target = mul2_y[17:8];
    

    reg [9:0] sq1_x_reg, sq1_y_reg;
    reg [9:0] sq2_x_reg, sq2_y_reg;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // put the squares at different locations
            sq1_x_reg <= 10'd0;
            sq1_y_reg <= 10'd0;

            sq2_x_reg <= 10'd100;
            sq2_y_reg <= 10'd100;
        end else if (refresh_tick) begin
            sq1_x_reg <= x1_target;
            sq1_y_reg <= y1_target;
            
            sq2_x_reg <= x2_target;
            sq2_y_reg <= y2_target;
        end
    end

    wire [9:0] sq1_x_l = sq1_x_reg;
    wire [9:0] sq1_y_t = sq1_y_reg;
    wire [9:0] sq1_x_r = sq1_x_l + SQUARE_SIZE - 1;
    wire [9:0] sq1_y_b = sq1_y_t + SQUARE_SIZE - 1;

    wire [9:0] sq2_x_l = sq2_x_reg;
    wire [9:0] sq2_y_t = sq2_y_reg;
    wire [9:0] sq2_x_r = sq2_x_l + SQUARE_SIZE - 1;
    wire [9:0] sq2_y_b = sq2_y_t + SQUARE_SIZE - 1;

    wire sq1_on = (sq1_x_l <= x) && (x <= sq1_x_r) &&
            (sq1_y_t <= y) && (y <= sq1_y_b);

    wire sq2_on = (sq2_x_l <= x) && (x <= sq2_x_r) &&
            (sq2_y_t <= y) && (y <= sq2_y_b);

    always @* begin
        if (!video_on)       rgb = 12'h000;
        else if (sq1_on)      rgb = SQ1_RGB;
        else if (sq2_on)     rgb = SQ2_RGB;
        else                 rgb = BG_RGB;
    end

endmodule


