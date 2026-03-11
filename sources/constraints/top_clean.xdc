## Clock
set_property PACKAGE_PIN W5 [get_ports clk_100MHz]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100MHz]
create_clock -name sys_clk_pin -period 10.00 [get_ports clk_100MHz]

## Reset button
set_property PACKAGE_PIN U18 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

## JA joystick
set_property PACKAGE_PIN J1 [get_ports SS1]
set_property IOSTANDARD LVCMOS33 [get_ports SS1]

set_property PACKAGE_PIN L2 [get_ports MOSI1]
set_property IOSTANDARD LVCMOS33 [get_ports MOSI1]

set_property PACKAGE_PIN J2 [get_ports MISO1]
set_property IOSTANDARD LVCMOS33 [get_ports MISO1]

set_property PACKAGE_PIN G2 [get_ports SCK1]
set_property IOSTANDARD LVCMOS33 [get_ports SCK1]

## JB joystick
set_property PACKAGE_PIN A14 [get_ports SS2]
set_property IOSTANDARD LVCMOS33 [get_ports SS2]

set_property PACKAGE_PIN A16 [get_ports MOSI2]
set_property IOSTANDARD LVCMOS33 [get_ports MOSI2]

set_property PACKAGE_PIN B15 [get_ports MISO2]
set_property IOSTANDARD LVCMOS33 [get_ports MISO2]

set_property PACKAGE_PIN B16 [get_ports SCK2]
set_property IOSTANDARD LVCMOS33 [get_ports SCK2]

## VGA
set_property PACKAGE_PIN G19 [get_ports {rgb[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rgb[0]}]

set_property PACKAGE_PIN H19 [get_ports {rgb[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rgb[1]}]

set_property PACKAGE_PIN J19 [get_ports {rgb[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rgb[2]}]

set_property PACKAGE_PIN N19 [get_ports {rgb[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rgb[3]}]

set_property PACKAGE_PIN J17 [get_ports {rgb[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rgb[4]}]

set_property PACKAGE_PIN H17 [get_ports {rgb[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rgb[5]}]

set_property PACKAGE_PIN G17 [get_ports {rgb[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rgb[6]}]

set_property PACKAGE_PIN D17 [get_ports {rgb[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rgb[7]}]

set_property PACKAGE_PIN N18 [get_ports {rgb[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rgb[8]}]

set_property PACKAGE_PIN L18 [get_ports {rgb[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rgb[9]}]

set_property PACKAGE_PIN K18 [get_ports {rgb[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rgb[10]}]

set_property PACKAGE_PIN J18 [get_ports {rgb[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rgb[11]}]

set_property PACKAGE_PIN P19 [get_ports hsync]
set_property IOSTANDARD LVCMOS33 [get_ports hsync]

set_property PACKAGE_PIN R19 [get_ports vsync]
set_property IOSTANDARD LVCMOS33 [get_ports vsync]

## LEDs
set_property PACKAGE_PIN U16 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]

set_property PACKAGE_PIN E19 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]

set_property PACKAGE_PIN U19 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]

set_property PACKAGE_PIN V19 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]

set_property PACKAGE_PIN W18 [get_ports {led[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[4]}]

set_property PACKAGE_PIN U15 [get_ports {led[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[5]}]

set_property PACKAGE_PIN U14 [get_ports {led[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[6]}]

set_property PACKAGE_PIN V14 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[7]}]

set_property PACKAGE_PIN V13 [get_ports {led[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[8]}]

set_property PACKAGE_PIN V3 [get_ports {led[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[9]}]

set_property PACKAGE_PIN W3 [get_ports {led[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[10]}]

set_property PACKAGE_PIN U3 [get_ports {led[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[11]}]

set_property PACKAGE_PIN P3 [get_ports {led[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[12]}]

set_property PACKAGE_PIN N3 [get_ports {led[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[13]}]

set_property PACKAGE_PIN P1 [get_ports {led[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[14]}]

set_property PACKAGE_PIN L1 [get_ports {led[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[15]}]

## 7-segment display cathodes
#set_property PACKAGE_PIN W7  [get_ports {LED_out[0]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {LED_out[0]}]

#set_property PACKAGE_PIN W6  [get_ports {LED_out[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {LED_out[1]}]

#set_property PACKAGE_PIN U8  [get_ports {LED_out[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_out[2]}]

#set_property PACKAGE_PIN V8  [get_ports {LED_out[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {LED_out[3]}]

#set_property PACKAGE_PIN U5  [get_ports {LED_out[4]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {LED_out[4]}]

#set_property PACKAGE_PIN V5  [get_ports {LED_out[5]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {LED_out[5]}]

#set_property PACKAGE_PIN U7  [get_ports {LED_out[6]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {LED_out[6]}]

## 7-segment display cathodes
set_property PACKAGE_PIN W7  [get_ports {LED_out[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_out[6]}]

set_property PACKAGE_PIN W6  [get_ports {LED_out[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_out[5]}]

set_property PACKAGE_PIN U8  [get_ports {LED_out[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_out[4]}]

set_property PACKAGE_PIN V8  [get_ports {LED_out[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_out[3]}]

set_property PACKAGE_PIN U5  [get_ports {LED_out[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_out[2]}]

set_property PACKAGE_PIN V5  [get_ports {LED_out[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_out[1]}]

set_property PACKAGE_PIN U7  [get_ports {LED_out[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_out[0]}]

## 7-segment anodes
set_property PACKAGE_PIN U2  [get_ports {anode_activate[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {anode_activate[0]}]

set_property PACKAGE_PIN U4  [get_ports {anode_activate[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {anode_activate[1]}]

set_property PACKAGE_PIN V4  [get_ports {anode_activate[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {anode_activate[2]}]

set_property PACKAGE_PIN W4  [get_ports {anode_activate[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {anode_activate[3]}]
