`timescale 1ns / 1ps

module pixel_generation_tb;
  
  reg clk;
  reg reset;
  reg video_on;
  reg [9:0] joystick1_x;
  reg [9:0] joystick1_y;
  reg [9:0] joystick2_x;
  reg [9:0] joystick2_y;
  reg [9:0] x;
  reg [9:0] y;
  wire [11:0] rgb;

  pixel_generation test (
    .clk(clk),
    .reset(reset),
    .video_on(video_on),
    .joystick1_x(joystick1_x),
    .joystick1_y(joystick1_y),
    .joystick2_x(joystick2_x),
    .joystick2_y(joystick2_y),
    .x(x),
    .y(y),
    .rgb(rgb)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  task do_refresh_tick;
    begin
      x = 10'd0;
      y = 10'd481;

      @(posedge clk);
      #1;
    end
  endtask

  initial begin
    reset = 1;
    video_on = 1;
    joystick1_x = 10'd0;
    joystick1_y = 10'd0;
    joystick2_x = 10'd0;
    joystick2_y = 10'd0;
    x = 10'd0;
    y = 10'd0;

    #20
    reset = 0;

    // ----Move square 1 to top left, square 2 to bottom right----
    joystick1_x = 10'd0;
    joystick1_y = 10'd0;
    joystick2_x = 10'd1023;
    joystick2_y = 10'd1023;
    do_refresh_tick;

    // inside square 1
    x = 10'd10;
    y = 10'd10;
    #1;
    $display("Square 1 inside rgb = %h (expect 0FF)", rgb);

    // inside square 2
    x = 10'd600;
    y = 10'd440;
    #1;
    $display("Square 2 inside rgb = %h (expect 0F0)", rgb);

    // background
    x = 10'd300;
    y = 10'd200;
    #1;
    $display("Background rgb = %h (expect F00)", rgb);   

    // ----swap positinos----
    joystick1_x = 10'd1023;
    joystick1_y = 10'd1023;
    joystick2_x = 10'd0;
    joystick2_y = 10'd0;
    do_refresh_tick;

    // inside square 2
    x = 10'd10;
    y = 10'd10;
    #1;
    $display("Square 2 inside rgb = %h (expect 0F0)", rgb);

    // inside square 1
    x = 10'd600;
    y = 10'd440;
    #1;
    $display("Square 1 inside rgb = %h (expect 0FF)", rgb);

    // background
    x = 10'd300;
    y = 10'd200;
    #1;
    $display("Background rgb = %h (expect F00)", rgb);   

    // ----Test blank screen----
    video_on = 0;
    x = 10'd600;
    y = 10'd440;
    #1;
    $display("Blank test rgb = %h (expect 000)", rgb);

    $finish;
  end
endmodule
