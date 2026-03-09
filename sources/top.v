`timescale 1ns / 1ps

module top(
  input clk,
  input reset,

  // vga stuff
  output hsync,
  output vsync,
  output [11:0] rgb,

  // joystick stuff
  input MISO,
  output SS1,  // JA joystick
  output SS2,  // JB joystick
  output MOSI,
  output SCK
);

  // parameters for vga display
  wire w_video_on, w_p_tick;
  wire [9:0] w_x, w_y;
  reg [11:0] rgb_reg;
  wire [11:0] rgb_next;

  // parameters for joystick
  wire [39:0] jstkData1;    // Data from PmodJSTK2 (JA)
  wire [39:0] jstkData2;    // Data from PmodJSTK2 (JB)

  // SPI and Joystick Interface
  PmodJSTK_Dual joysticks (
    .CLK(clk),
    .RST(reset),
    .MISO(MISO),
    .SS1(SS1),
    .SS2(SS2),
    .SCK(SCK),
    .MOSI(MOSI),
    .DOUT1(jstkData1),
    .DOUT2(jstkData2)
  );

  wire [9:0] data1_y, data1_x;      // JSTK 1 positions (JA)
  wire [9:0] data2_y, data2_x;      // JSTK 2 positions (JB)

  // TODO: possibly swap the x and y
  assign data1_y = {jstkData1[25:24], jstkData1[39:32]}; // 2 bits from the 2nd byte + 8 bits from the 1st byte
  assign data1_x = {jstkData1[9:8], jstkData1[23:16]};  // 2 bits from the 4th byte + 8 bits from the 3rd byte

  assign data2_y = {jstkData2[25:24], jstkData2[39:32]};
  assign data2_x = {jstkData2[9:8], jstkData2[23:16]};

  
  vga_controller vc (
    .clk(clk), 
    .reset(reset), 
    .video_on(w_video_on), 
    .hsync(hsync), 
    .vsync(vsync), 
    .p_tick(w_p_tick), 
    .x(w_x), 
    .y(w_y)
  );
  
  pixel_generation pg (
    .clk(clk), 
    .reset(reset), 
    .video_on(w_video_on), 
    .x(w_x), 
    .y(w_y),
    .joystick1_x(data1_x),
    .joystick1_y(data1_y),
    .joystick2_x(data2_x),
    .joystick2_y(data2_y),
    .rgb(rgb_next)
  );
    
  always @(posedge clk)
    if(w_p_tick)
      rgb_reg <= rgb_next;
  
  assign rgb = rgb_reg;
 
endmodule
