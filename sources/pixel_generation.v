`timescale 1ns / 1ps

module pixel_generation(
    input  wire        clk,
    input  wire        reset,
    input  wire        video_on,

    input  wire [9:0]  joystick1_x,
    input  wire [9:0]  joystick1_y,
    input  wire [9:0]  joystick2_x,
    input  wire [9:0]  joystick2_y,

    input  wire        p1_shield_active,
    input  wire        p1_flash_toggle,
    input  wire        p2_shield_active,
    input  wire        p2_flash_toggle,

    input  wire        tag_switch,

    input  wire [9:0]  x,
    input  wire [9:0]  y,
    output reg  [11:0] rgb
);

    localparam integer X_MAX = 639;
    localparam integer Y_MAX = 479;
    localparam integer SQUARE_SIZE = 64;
    localparam integer SHIELD_PAD  = 8;

    localparam [9:0] JOY_CENTER = 10'd512;
    localparam [9:0] JOY_DEAD   = 10'd80;

    localparam [11:0] BG_RGB      = 12'h333;
    localparam [11:0] P1_RGB      = 12'h00F;
    localparam [11:0] P2_RGB      = 12'hF00;
    localparam [11:0] TAGGER_RGB  = 12'hFFF;
    localparam [11:0] SHIELD1_RGB = 12'h80F; // p1 bubble
    localparam [11:0] SHIELD2_RGB = 12'hF08; // p2 bubble
    localparam [11:0] P1_WIN_RGB  = 12'h00F;
    localparam [11:0] P2_WIN_RGB  = 12'hF00;

    localparam integer X_LIM = X_MAX - (SQUARE_SIZE - 1);
    localparam integer Y_LIM = Y_MAX - (SQUARE_SIZE - 1);

    wire refresh_tick;
    assign refresh_tick = ((y == 10'd481) && (x == 10'd0)) ? 1'b1 : 1'b0;

    // ------------------------------------------------------------
    // Player positions
    // ------------------------------------------------------------
    reg [9:0] p1_x_reg, p1_y_reg;
    reg [9:0] p2_x_reg, p2_y_reg;

    reg signed [10:0] x1_delta_reg, y1_delta_reg;
    reg signed [10:0] x2_delta_reg, y2_delta_reg;

    reg signed [10:0] x1_delta_next, y1_delta_next;
    reg signed [10:0] x2_delta_next, y2_delta_next;

    wire signed [10:0] p1_x_next, p1_y_next;
    wire signed [10:0] p2_x_next, p2_y_next;

    assign p1_x_next = $signed({1'b0, p1_x_reg}) + x1_delta_reg;
    assign p1_y_next = $signed({1'b0, p1_y_reg}) + y1_delta_reg;
    assign p2_x_next = $signed({1'b0, p2_x_reg}) + x2_delta_reg;
    assign p2_y_next = $signed({1'b0, p2_y_reg}) + y2_delta_reg;

    // ------------------------------------------------------------
    // Game state
    // ------------------------------------------------------------
    reg game_over;
    reg winner;          // 0 = player 1 wins, 1 = player 2 wins
    reg current_tagger;  // 0 = p1 tagger, 1 = p2 tagger

    // ------------------------------------------------------------
    // Player boundaries
    // ------------------------------------------------------------
    wire [9:0] p1_x_l = p1_x_reg;
    wire [9:0] p1_y_t = p1_y_reg;
    wire [9:0] p1_x_r = p1_x_l + SQUARE_SIZE - 1;
    wire [9:0] p1_y_b = p1_y_t + SQUARE_SIZE - 1;

    wire [9:0] p2_x_l = p2_x_reg;
    wire [9:0] p2_y_t = p2_y_reg;
    wire [9:0] p2_x_r = p2_x_l + SQUARE_SIZE - 1;
    wire [9:0] p2_y_b = p2_y_t + SQUARE_SIZE - 1;

    // Safe 1-pixel border bounds
    wire [9:0] p1_bd_x_l = (p1_x_l == 0)     ? 10'd0     : (p1_x_l - 1'b1);
    wire [9:0] p1_bd_y_t = (p1_y_t == 0)     ? 10'd0     : (p1_y_t - 1'b1);
    wire [9:0] p1_bd_x_r = (p1_x_r >= X_MAX) ? X_MAX[9:0] : (p1_x_r + 1'b1);
    wire [9:0] p1_bd_y_b = (p1_y_b >= Y_MAX) ? Y_MAX[9:0] : (p1_y_b + 1'b1);

    wire [9:0] p2_bd_x_l = (p2_x_l == 0)     ? 10'd0     : (p2_x_l - 1'b1);
    wire [9:0] p2_bd_y_t = (p2_y_t == 0)     ? 10'd0     : (p2_y_t - 1'b1);
    wire [9:0] p2_bd_x_r = (p2_x_r >= X_MAX) ? X_MAX[9:0] : (p2_x_r + 1'b1);
    wire [9:0] p2_bd_y_b = (p2_y_b >= Y_MAX) ? Y_MAX[9:0] : (p2_y_b + 1'b1);

    // Shield bubble around player 1
    wire [9:0] p1_sh_x_l = (p1_x_l > SHIELD_PAD) ? (p1_x_l - SHIELD_PAD) : 10'd0;
    wire [9:0] p1_sh_y_t = (p1_y_t > SHIELD_PAD) ? (p1_y_t - SHIELD_PAD) : 10'd0;
    wire [9:0] p1_sh_x_r = (p1_x_r + SHIELD_PAD < X_MAX) ? (p1_x_r + SHIELD_PAD) : X_MAX[9:0];
    wire [9:0] p1_sh_y_b = (p1_y_b + SHIELD_PAD < Y_MAX) ? (p1_y_b + SHIELD_PAD) : Y_MAX[9:0];

    // Shield bubble around player 2
    wire [9:0] p2_sh_x_l = (p2_x_l > SHIELD_PAD) ? (p2_x_l - SHIELD_PAD) : 10'd0;
    wire [9:0] p2_sh_y_t = (p2_y_t > SHIELD_PAD) ? (p2_y_t - SHIELD_PAD) : 10'd0;
    wire [9:0] p2_sh_x_r = (p2_x_r + SHIELD_PAD < X_MAX) ? (p2_x_r + SHIELD_PAD) : X_MAX[9:0];
    wire [9:0] p2_sh_y_b = (p2_y_b + SHIELD_PAD < Y_MAX) ? (p2_y_b + SHIELD_PAD) : Y_MAX[9:0];

    // ------------------------------------------------------------
    // Collision
    // ------------------------------------------------------------
    wire collide;
    assign collide = (p1_x_l <= p2_x_r) && (p1_x_r >= p2_x_l) &&
                     (p1_y_t <= p2_y_b) && (p1_y_b >= p2_y_t);

    // The current runner is protected only if THEIR shield is active
    wire runner_protected;
    assign runner_protected =
        ((current_tagger == 1'b0) && p2_shield_active) ||
        ((current_tagger == 1'b1) && p1_shield_active);

    // ------------------------------------------------------------
    // Joystick magnitude -> speed
    // ------------------------------------------------------------
    reg [9:0] j1x_mag, j1y_mag, j2x_mag, j2y_mag;
    reg [2:0] j1x_speed, j1y_speed, j2x_speed, j2y_speed;

    always @* begin
        if (joystick1_x >= JOY_CENTER) j1x_mag = joystick1_x - JOY_CENTER;
        else                           j1x_mag = JOY_CENTER - joystick1_x;

        if (joystick1_y >= JOY_CENTER) j1y_mag = joystick1_y - JOY_CENTER;
        else                           j1y_mag = JOY_CENTER - joystick1_y;

        if (joystick2_x >= JOY_CENTER) j2x_mag = joystick2_x - JOY_CENTER;
        else                           j2x_mag = JOY_CENTER - joystick2_x;

        if (joystick2_y >= JOY_CENTER) j2y_mag = joystick2_y - JOY_CENTER;
        else                           j2y_mag = JOY_CENTER - joystick2_y;

        j1x_speed = 3'd0;
        j1y_speed = 3'd0;
        j2x_speed = 3'd0;
        j2y_speed = 3'd0;

        if (j1x_mag > JOY_DEAD + 10'd250)      j1x_speed = 3'd4;
        else if (j1x_mag > JOY_DEAD + 10'd180) j1x_speed = 3'd3;
        else if (j1x_mag > JOY_DEAD + 10'd110) j1x_speed = 3'd2;
        else if (j1x_mag > JOY_DEAD)           j1x_speed = 3'd1;

        if (j1y_mag > JOY_DEAD + 10'd250)      j1y_speed = 3'd4;
        else if (j1y_mag > JOY_DEAD + 10'd180) j1y_speed = 3'd3;
        else if (j1y_mag > JOY_DEAD + 10'd110) j1y_speed = 3'd2;
        else if (j1y_mag > JOY_DEAD)           j1y_speed = 3'd1;

        if (j2x_mag > JOY_DEAD + 10'd250)      j2x_speed = 3'd4;
        else if (j2x_mag > JOY_DEAD + 10'd180) j2x_speed = 3'd3;
        else if (j2x_mag > JOY_DEAD + 10'd110) j2x_speed = 3'd2;
        else if (j2x_mag > JOY_DEAD)           j2x_speed = 3'd1;

        if (j2y_mag > JOY_DEAD + 10'd250)      j2y_speed = 3'd4;
        else if (j2y_mag > JOY_DEAD + 10'd180) j2y_speed = 3'd3;
        else if (j2y_mag > JOY_DEAD + 10'd110) j2y_speed = 3'd2;
        else if (j2y_mag > JOY_DEAD)           j2y_speed = 3'd1;
    end

    // ------------------------------------------------------------
    // Velocity control
    // ------------------------------------------------------------
    always @* begin
        x1_delta_next = 11'sd0;
        y1_delta_next = 11'sd0;
        x2_delta_next = 11'sd0;
        y2_delta_next = 11'sd0;

        // Player 1 normal
        if (joystick1_x > JOY_CENTER + JOY_DEAD)
            x1_delta_next =  $signed({8'd0, j1x_speed});
        else if (joystick1_x < JOY_CENTER - JOY_DEAD)
            x1_delta_next = -$signed({8'd0, j1x_speed});

        if (joystick1_y > JOY_CENTER + JOY_DEAD)
            y1_delta_next =  $signed({8'd0, j1y_speed});
        else if (joystick1_y < JOY_CENTER - JOY_DEAD)
            y1_delta_next = -$signed({8'd0, j1y_speed});

        // Player 2 mirrored to match your current hardware orientation
        if (joystick2_x > JOY_CENTER + JOY_DEAD)
            x2_delta_next = -$signed({8'd0, j2x_speed});
        else if (joystick2_x < JOY_CENTER - JOY_DEAD)
            x2_delta_next =  $signed({8'd0, j2x_speed});

        if (joystick2_y > JOY_CENTER + JOY_DEAD)
            y2_delta_next = -$signed({8'd0, j2y_speed});
        else if (joystick2_y < JOY_CENTER - JOY_DEAD)
            y2_delta_next =  $signed({8'd0, j2y_speed});
    end

    // ------------------------------------------------------------
    // Game update
    // ------------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            p1_x_reg <= 10'd40;
            p1_y_reg <= 10'd40;
            p2_x_reg <= 10'd520;
            p2_y_reg <= 10'd360;

            x1_delta_reg <= 11'sd0;
            y1_delta_reg <= 11'sd0;
            x2_delta_reg <= 11'sd0;
            y2_delta_reg <= 11'sd0;

            game_over      <= 1'b0;
            winner         <= 1'b0;
            current_tagger <= 1'b0;
        end
        else begin
            x1_delta_reg <= x1_delta_next;
            y1_delta_reg <= y1_delta_next;
            x2_delta_reg <= x2_delta_next;
            y2_delta_reg <= y2_delta_next;

            // switch tagger whenever countdown timer expires
            if (!game_over && tag_switch) begin
                current_tagger <= ~current_tagger;
            end
            
            if (refresh_tick && !game_over) begin
                // Move player 1
                if (p1_x_next < 0)
                    p1_x_reg <= 10'd0;
                else if (p1_x_next > X_LIM)
                    p1_x_reg <= X_LIM[9:0];
                else
                    p1_x_reg <= p1_x_next[9:0];

                if (p1_y_next < 0)
                    p1_y_reg <= 10'd0;
                else if (p1_y_next > Y_LIM)
                    p1_y_reg <= Y_LIM[9:0];
                else
                    p1_y_reg <= p1_y_next[9:0];

                // Move player 2
                if (p2_x_next < 0)
                    p2_x_reg <= 10'd0;
                else if (p2_x_next > X_LIM)
                    p2_x_reg <= X_LIM[9:0];
                else
                    p2_x_reg <= p2_x_next[9:0];

                if (p2_y_next < 0)
                    p2_y_reg <= 10'd0;
                else if (p2_y_next > Y_LIM)
                    p2_y_reg <= Y_LIM[9:0];
                else
                    p2_y_reg <= p2_y_next[9:0];

                if (collide && !runner_protected) begin
                    game_over <= 1'b1;
                    winner    <= current_tagger;
                end
            end
        end
    end

    // ------------------------------------------------------------
    // Pixel coverage
    // ------------------------------------------------------------
    wire p1_on, p2_on;
    wire p1_border_on, p2_border_on;
    wire p1_shield_on, p2_shield_on;

    assign p1_on = (p1_x_l <= x) && (x <= p1_x_r) &&
                   (p1_y_t <= y) && (y <= p1_y_b);

    assign p2_on = (p2_x_l <= x) && (x <= p2_x_r) &&
                   (p2_y_t <= y) && (y <= p2_y_b);

    assign p1_border_on = (x >= p1_bd_x_l) && (x <= p1_bd_x_r) &&
                          (y >= p1_bd_y_t) && (y <= p1_bd_y_b) &&
                          !p1_on;

    assign p2_border_on = (x >= p2_bd_x_l) && (x <= p2_bd_x_r) &&
                          (y >= p2_bd_y_t) && (y <= p2_bd_y_b) &&
                          !p2_on;

    assign p1_shield_on = (x >= p1_sh_x_l) && (x <= p1_sh_x_r) &&
                          (y >= p1_sh_y_t) && (y <= p1_sh_y_b) &&
                          !p1_on &&
                          !((x > p1_sh_x_l+1) && (x < p1_sh_x_r-1) &&
                            (y > p1_sh_y_t+1) && (y < p1_sh_y_b-1));

    assign p2_shield_on = (x >= p2_sh_x_l) && (x <= p2_sh_x_r) &&
                          (y >= p2_sh_y_t) && (y <= p2_sh_y_b) &&
                          !p2_on &&
                          !((x > p2_sh_x_l+1) && (x < p2_sh_x_r-1) &&
                            (y > p2_sh_y_t+1) && (y < p2_sh_y_b-1));

    // ------------------------------------------------------------
    // RGB
    // ------------------------------------------------------------
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
        else if (p1_shield_active && p1_flash_toggle && p1_shield_on) begin
            rgb = SHIELD1_RGB;
        end
        else if (p2_shield_active && p2_flash_toggle && p2_shield_on) begin
            rgb = SHIELD2_RGB;
        end
        else if ((current_tagger == 1'b0) && p1_border_on) begin
            rgb = TAGGER_RGB;
        end
        else if ((current_tagger == 1'b1) && p2_border_on) begin
            rgb = TAGGER_RGB;
        end
        else if (p1_on) begin
            if (p1_shield_active && p1_flash_toggle)
                rgb = 12'hFFF;
            else
                rgb = P1_RGB;
        end
        else if (p2_on) begin
            if (p2_shield_active && p2_flash_toggle)
                rgb = 12'hFFF;
            else
                rgb = P2_RGB;
        end
        else begin
            rgb = BG_RGB;
        end
    end

endmodule
