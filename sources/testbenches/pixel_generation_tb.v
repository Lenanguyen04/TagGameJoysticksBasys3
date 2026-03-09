`timescale 1ns / 1ps

module pixel_generation_tb;
  
  reg clk;
  reg reset;
  reg video_on;
  reg [9:0] joystick_x;
  reg [9:0] joystick_y;
  reg [9:0] x;
  reg [9:0] y;
  wire [11:0] rgb;

  pixel_generation test (
    .clk(clk),
    .reset(reset),
    .video_on(video_on),
    .joystick_x(joystick_x),
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
    joystick_x = 10'd0;
    joystick_y = 10'd0;
    x = 10'd0;
    y = 10'd0;

    #20
    reset = 0;

    // Move square to top left:
    joystick_x = 10'd0;
    joystick_y = 10'd0;
    do_refresh_tick;

    x = 10'd0;
    y = 10'd0;
    #1;
    $display("Top left test rgb = %h (expect F00)", rgb);

    // Move square to center
    joystick_x = 10'd512;
    joystick_y = 10'd512;
    do_refresh_tick;

    x = 10'd320;
    y = 10'd240;
    #1;
    $display("Top left test rgb = %h (expect F00)", rgb);

    // Move square to bottom right
    joystick_x = 10'd1023;
    joystick_y = 10'd1023;
    do_refresh_tick;

    x = 10'd620;
    y = 10'd460;
    #1;
    $display("Top left test rgb = %h (expect F00)", rgb);

    // Test blank screen
    video_on = 1;
    x = 10'd100;
    y = 10'd100;
    #1;
    $display("Blank test rgb = %h (expect 000)", rgb);

    $finish;
  end
endmodule
