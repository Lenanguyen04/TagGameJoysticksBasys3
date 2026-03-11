`timescale 1ns / 1ps

module pixel_generation(
    input  wire        clk,
    input  wire        reset,
    input  wire        video_on,

    input  wire [9:0]  joystick1_x,
    input  wire [9:0]  joystick1_y,
    input  wire [9:0]  joystick2_x,
    input  wire [9:0]  joystick2_y,

    input  wire        shield_active,
    input  wire        flash_toggle,

    input  wire [9:0]  x,
    input  wire [9:0]  y,
    output reg  [11:0] rgb
);

    localparam integer X_MAX = 639;
    localparam integer Y_MAX = 479;
    localparam integer SQUARE_SIZE = 64;
    localparam SQUARE_VELOCITY_POS = 2;      
    localparam SQUARE_VELOCITY_NEG = -2;      


    // Colors
    localparam [11:0] BG_RGB        = 12'h00F; // red background
    localparam [11:0] P1_RGB        = 12'h0FF; // yellow square
    localparam [11:0] P2_RGB        = 12'h0F0; // green square
    localparam [11:0] P1_WIN_RGB    = 12'h0FF; // full screen when player 1 wins
    localparam [11:0] P2_WIN_RGB    = 12'h0F0; // full screen when player 2 wins

    // update positions once per frame
    wire refresh_tick;
    assign refresh_tick = ((y == 10'd481) && (x == 10'd0)) ? 1'b1 : 1'b0;

    localparam integer X_LIM = X_MAX - (SQUARE_SIZE - 1);
    localparam integer Y_LIM = Y_MAX - (SQUARE_SIZE - 1);

    // coordinates for squares
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
    
    // velocity parameters
    reg signed [10:0] x1_delta_reg, y1_delta_reg;
    reg signed [10:0] x2_delta_reg, y2_delta_reg;
       
    reg signed [10:0] x1_delta_next, y1_delta_next;
    reg signed [10:0] x2_delta_next, y2_delta_next;

    // clamping parameters
    wire signed [10:0] p1_x_next, p1_y_next;
    wire signed [10:0] p2_x_next, p2_y_next;

    // next position (extend position and treat it as signed so we can add signed velocity)
    assign p1_x_next = $signed({1'b0, p1_x_reg}) + x1_delta_reg;
    assign p1_y_next = $signed({1'b0, p1_y_reg}) + y1_delta_reg;
    assign p2_x_next = $signed({1'b0, p2_x_reg}) + x2_delta_reg;
    assign p2_y_next = $signed({1'b0, p2_y_reg}) + y2_delta_reg;
    
    localparam [9:0] JOY_CENTER = 10'd512;    // center position of joystick
    localparam [9:0] JOY_DEAD   = 10'd100;    // dead zone radius because the joystick drifts

     // register control                   
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // default square positions
            p1_x_reg  <= 10'd40;
            p1_y_reg  <= 10'd40;
            p2_x_reg  <= 10'd520;
            p2_y_reg  <= 10'd360;

            game_over <= 1'b0;
            winner    <= 1'b0;

            x1_delta_reg <= 0;
            y1_delta_reg <= 0;
            x2_delta_reg <= 0;
            y2_delta_reg <= 0;
        end
        else begin
            if (refresh_tick) begin
                if (!game_over) begin

                    // Square 1 - x
                    if (p1_x_next < 0)
                        p1_x_reg <= 10'd0;
                    else if (p1_x_next > X_LIM)
                        p1_x_reg <= X_LIM[9:0];
                    else
                        p1_x_reg <= p1_x_next[9:0];

                    // Square 1 - y
                    if (p1_y_next < 0)
                        p1_y_reg <= 10'd0;
                    else if (p1_y_next > Y_LIM)
                        p1_y_reg <= Y_LIM[9:0];
                    else
                        p1_y_reg <= p1_y_next[9:0];

                    // Square 2 - x
                    if (p2_x_next < 0)
                        p2_x_reg <= 10'd0;
                    else if (p2_x_next > X_LIM)
                        p2_x_reg <= X_LIM[9:0];
                    else
                        p2_x_reg <= p2_x_next[9:0];

                    // Square 2 - y
                    if (p2_y_next < 0)
                        p2_y_reg <= 10'd0;
                    else if (p2_y_next > Y_LIM)
                        p2_y_reg <= Y_LIM[9:0];
                    else
                        p2_y_reg <= p2_y_next[9:0];

                    if (collide && !shield_active) begin
                        game_over <= 1'b1;
                        winner    <= 1'b0; // player 1 is the tagger for now
                    end
                end
            end

            x1_delta_reg <= x1_delta_next;
            y1_delta_reg <= y1_delta_next;
            x2_delta_reg <= x2_delta_next;
            y2_delta_reg <= y2_delta_next;
        end
    end
    
  // Velocity controls
      always @* begin
        // ----- Square 1 -----
        // y movement
        if (joystick1_y > JOY_CENTER + JOY_DEAD)
            y1_delta_next = SQUARE_VELOCITY_POS;
        else if (joystick1_y < JOY_CENTER - JOY_DEAD)
            y1_delta_next = SQUARE_VELOCITY_NEG;
        else
            y1_delta_next = 0;

        // x movement
        if (joystick1_x > JOY_CENTER + JOY_DEAD)
            x1_delta_next = SQUARE_VELOCITY_POS;
        else if (joystick1_x < JOY_CENTER - JOY_DEAD)
            x1_delta_next = SQUARE_VELOCITY_NEG;
        else
            x1_delta_next = 0;

        // ----- Square 2 -----
        // y movement (Mirrored because JB mirrors JA directions)
        if (joystick2_y > JOY_CENTER + JOY_DEAD)
            y2_delta_next = SQUARE_VELOCITY_NEG;
        else if (joystick2_y < JOY_CENTER - JOY_DEAD)
            y2_delta_next = SQUARE_VELOCITY_POS;
        else
            y2_delta_next = 0;

        // x movement (Mirrored because JB mirrors JA directions)
        if (joystick2_x > JOY_CENTER + JOY_DEAD)
            x2_delta_next = SQUARE_VELOCITY_NEG;
        else if (joystick2_x < JOY_CENTER - JOY_DEAD)
            x2_delta_next = SQUARE_VELOCITY_POS;
        else
            x2_delta_next = 0;
      end
      
    // pixel-on checks (within boundaries)
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
            if (shield_active && flash_toggle)
                rgb = 12'hFFF; // Flash white while shield activated
            else
                rgb = P2_RGB;
        end
        else begin
            rgb = BG_RGB;
        end
    end

endmodule