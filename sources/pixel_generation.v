`timescale 1ns / 1ps

module pixel_generation(
    input  wire        clk,
    input  wire        reset,
    input  wire        video_on,

    input  wire [9:0]  joystick1_x,
    input  wire [9:0]  joystick1_y,
    input  wire [9:0]  joystick2_x,
    input  wire [9:0]  joystick2_y,

    input  wire [9:0]  x,
    input  wire [9:0]  y,
    output reg  [11:0] rgb
);

    localparam integer X_MAX = 639;
    localparam integer Y_MAX = 479;
    localparam integer SQUARE_SIZE = 64;

    // Colors
    localparam [11:0] BG_RGB        = 12'h00F; // blue background
    localparam [11:0] P1_RGB        = 12'h0FF; // yellow/cyan-ish depending on wiring order
    localparam [11:0] P2_RGB        = 12'h0F0; // green
    localparam [11:0] P1_WIN_RGB    = 12'h0FF; // full screen when player 1 wins
    localparam [11:0] P2_WIN_RGB    = 12'h0F0; // full screen when player 2 wins

    // update positions once per frame
    wire refresh_tick;
    assign refresh_tick = ((y == 10'd481) && (x == 10'd0)) ? 1'b1 : 1'b0;

    localparam integer X_LIM = X_MAX - (SQUARE_SIZE - 1);
    localparam integer Y_LIM = Y_MAX - (SQUARE_SIZE - 1);

    // Scale joystick 10-bit range into visible area
    wire [19:0] mul1_x = joystick1_x * X_LIM;
    wire [19:0] mul1_y = joystick1_y * Y_LIM;
    wire [19:0] mul2_x = joystick2_x * X_LIM;
    wire [19:0] mul2_y = joystick2_y * Y_LIM;

    wire [9:0] p1_x_target = mul1_x / 10'd1023;
    wire [9:0] p1_y_target = mul1_y / 10'd1023;
    wire [9:0] p2_x_target = mul2_x / 10'd1023;
    wire [9:0] p2_y_target = mul2_y / 10'd1023;

    reg [9:0] p1_x_reg, p1_y_reg;
    reg [9:0] p2_x_reg, p2_y_reg;

    reg game_over;
    reg winner;   // 0 = player 1, 1 = player 2

    // boundaries
    wire [9:0] p1_x_l = p1_x_reg;
    wire [9:0] p1_y_t = p1_y_reg;
    wire [9:0] p1_x_r = p1_x_l + SQUARE_SIZE - 1;
    wire [9:0] p1_y_b = p1_y_t + SQUARE_SIZE - 1;

    wire [9:0] p2_x_l = p2_x_reg;
    wire [9:0] p2_y_t = p2_y_reg;
    wire [9:0] p2_x_r = p2_x_l + SQUARE_SIZE - 1;
    wire [9:0] p2_y_b = p2_y_t + SQUARE_SIZE - 1;

    // overlap detection
    wire collide;
    assign collide = (p1_x_l <= p2_x_r) && (p1_x_r >= p2_x_l) &&
                     (p1_y_t <= p2_y_b) && (p1_y_b >= p2_y_t);

    // register control
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            p1_x_reg  <= 10'd40;
            p1_y_reg  <= 10'd40;
            p2_x_reg  <= 10'd520;
            p2_y_reg  <= 10'd360;
            game_over <= 1'b0;
            winner    <= 1'b0;
        end
        else if (refresh_tick) begin
            if (!game_over) begin
                p1_x_reg <= p1_x_target;
                p1_y_reg <= p1_y_target;
                p2_x_reg <= p2_x_target;
                p2_y_reg <= p2_y_target;

                if (collide) begin
                    game_over <= 1'b1;
                    winner    <= 1'b0; // player 1 is the tagger for now
                end
            end
        end
    end

    // pixel-on checks
    wire p1_on;
    wire p2_on;

    assign p1_on = (p1_x_l <= x) && (x <= p1_x_r) &&
                   (p1_y_t <= y) && (y <= p1_y_b);

    assign p2_on = (p2_x_l <= x) && (x <= p2_x_r) &&
                   (p2_y_t <= y) && (y <= p2_y_b);

    // RGB control
    always @* begin
        if (!video_on) begin
            rgb = 12'h000;
        end
        else if (game_over) begin
            if (winner == 1'b0)
                rgb = P1_WIN_RGB;
            else
                rgb = P2_WIN_RGB;
        end
        else if (p1_on) begin
            rgb = P1_RGB;
        end
        else if (p2_on) begin
            rgb = P2_RGB;
        end
        else begin
            rgb = BG_RGB;
        end
    end

endmodule