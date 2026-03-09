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
  output SS,
  output MOSI,
  output SCK
);

  // parameters for vga display
  wire w_video_on, w_p_tick;
  wire [9:0] w_x, w_y;
  reg [11:0] rgb_reg;
  wire [11:0] rgb_next;

  // parameters for joystick
  wire [39:0] jstkData;    // Data from PmodJSTK2
  wire [9:0] DataY;      // JSTK Y-axis position
  wire [9:0] DataX;      // JSTK Y-axis position
  wire sndRec;             // Signal to send/receive data

  assign DataX = {jstkData[25:24], jstkData[39:32]}; // 2 bits from the 2nd byte + 8 bits from the 1st byte
  assign DataY = {jstkData[9:8], jstkData[23:16]};  // 2 bits from the 4th byte + 8 bits from the 3rd byte

  // SPI and Joystick Interface
  PmodJSTK joystick (
    .clk(clk),
    .reset(reset),
    .sndRec(sndRec),
    .DIN(8'b0),           // Unused, sending static data
    .MISO(MISO),
    .SS(SS),
    .SCK(SCK),
    .MOSI(MOSI),
    .DOUT(jstkData)
  );

    // Clock Divider for Send/Receive Signal (~5Hz for smoother updates)
    ClkDiv_5Hz genSndRec (
      .clk(clk),
      .reset(reset),
      .CLKOUT(sndRec)
    );
  
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
    .joystick_x(DataX),
    .joystick_y(DataY),
    .rgb(rgb_next)
  );
    
  always @(posedge clk)
    if(w_p_tick)
      rgb_reg <= rgb_next;
  
  assign rgb = rgb_reg;
 
endmodule
