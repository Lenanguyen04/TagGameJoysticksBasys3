`timescale 1ns / 1ps

module PmodJSTK_Dual_tb;

    reg CLK;
    reg RST;
    reg MISO;

    wire SS1;
    wire SS2;
    wire MOSI;
    wire SCK;
    wire [39:0] DOUT1;
    wire [39:0] DOUT2;

    // Instantiate DUT
    PmodJSTK_Dual dut (
        .CLK(CLK),
        .RST(RST),
        .MISO(MISO),
        .SS1(SS1),
        .SS2(SS2),
        .MOSI(MOSI),
        .SCK(SCK),
        .DOUT1(DOUT1),
        .DOUT2(DOUT2)
    );

    // Fake packets returned by our stub spiCtrl
    // Format = {byte1, byte2, byte3, byte4, byte5}
    localparam [39:0] PACKET1 = {8'h34, 8'h01, 8'h56, 8'h02, 8'hAA};
    localparam [39:0] PACKET2 = {8'h78, 8'h03, 8'h9A, 8'h00, 8'h55};

    // Decode helper wires just to make waveform/debug easier
    wire [9:0] joy1_x = {DOUT1[25:24], DOUT1[39:32]};
    wire [9:0] joy1_y = {DOUT1[9:8],   DOUT1[23:16]};

    wire [9:0] joy2_x = {DOUT2[25:24], DOUT2[39:32]};
    wire [9:0] joy2_y = {DOUT2[9:8],   DOUT2[23:16]};

    integer ss1_count;
    integer ss2_count;

    // Clock
    initial CLK = 1'b0;
    always #5 CLK = ~CLK;   // 100 MHz style sim clock

    initial begin
        ss1_count = 0;
        ss2_count = 0;
    end

    // Count each joystick selection event
    always @(negedge SS1) begin
        ss1_count = ss1_count + 1;
        $display("[%0t] SS1 selected", $time);
    end

    always @(negedge SS2) begin
        ss2_count = ss2_count + 1;
        $display("[%0t] SS2 selected", $time);
    end

    // Sanity check: both SS lines should never be active at once
    always @(posedge CLK) begin
        if (!RST && (SS1 === 1'b0) && (SS2 === 1'b0)) begin
            $display("[%0t] ERROR: SS1 and SS2 are both low!", $time);
            $stop;
        end
    end

    initial begin
        MISO = 1'b0;  // unused by stubs
        RST  = 1'b1;

        #40;
        RST = 1'b0;

        // Wait until joystick 1 gets its packet
        wait (DOUT1 == PACKET1);
        $display("[%0t] DOUT1 updated correctly: %h", $time, DOUT1);
        $display("        joy1_x = %0d, joy1_y = %0d", joy1_x, joy1_y);

        // Wait until joystick 2 gets its packet
        wait (DOUT2 == PACKET2);
        $display("[%0t] DOUT2 updated correctly: %h", $time, DOUT2);
        $display("        joy2_x = %0d, joy2_y = %0d", joy2_x, joy2_y);

        // Let it run a bit longer to prove alternation continues
        #300;

        if (ss1_count < 1) begin
            $display("ERROR: SS1 was never selected.");
            $stop;
        end

        if (ss2_count < 1) begin
            $display("ERROR: SS2 was never selected.");
            $stop;
        end

        $display("PASS: Dual joystick wrapper alternated correctly.");
        $display("      SS1 selections = %0d", ss1_count);
        $display("      SS2 selections = %0d", ss2_count);

        $finish;
    end

endmodule


// ============================================================
// Stub clock divider for iSCLK
// Fast simulation version
// ============================================================
module ClkDiv_66_67kHz(
    input CLK,
    input RST,
    output reg CLKOUT
);
    always @(posedge CLK or posedge RST) begin
        if (RST)
            CLKOUT <= 1'b0;
        else
            CLKOUT <= ~CLKOUT;   // very fast toggle for simulation
    end
endmodule


// ============================================================
// Stub poll divider
// Rename/keep the one that matches your PmodJSTK_Dual instantiation
// ============================================================
module ClkDiv_100Hz(
    input CLK,
    input RST,
    output reg CLKOUT
);
    reg [3:0] cnt;
    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            CLKOUT <= 1'b0;
            cnt <= 4'd0;
        end else begin
            if (cnt == 4'd5) begin
                CLKOUT <= ~CLKOUT;
                cnt <= 4'd0;
            end else begin
                cnt <= cnt + 1'b1;
            end
        end
    end
endmodule

module ClkDiv_200Hz(
    input CLK,
    input RST,
    output reg CLKOUT
);
    reg [2:0] cnt;
    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            CLKOUT <= 1'b0;
            cnt <= 3'd0;
        end else begin
            if (cnt == 3'd3) begin
                CLKOUT <= ~CLKOUT;
                cnt <= 3'd0;
            end else begin
                cnt <= cnt + 1'b1;
            end
        end
    end
endmodule

module ClkDiv_5Hz(
    input CLK,
    input RST,
    output reg CLKOUT
);
    reg [4:0] cnt;
    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            CLKOUT <= 1'b0;
            cnt <= 5'd0;
        end else begin
            if (cnt == 5'd10) begin
                CLKOUT <= ~CLKOUT;
                cnt <= 5'd0;
            end else begin
                cnt <= cnt + 1'b1;
            end
        end
    end
endmodule


// ============================================================
// Stub spiCtrl
// This fakes a full 5-byte transaction and alternates packets:
// first transaction  -> PACKET1
// second transaction -> PACKET2
// third              -> PACKET1
// etc.
// ============================================================
module spiCtrl(
    input CLK,
    input RST,
    input sndRec,
    input BUSY,          // ignored in this stub
    input [7:0] DIN,     // ignored in this stub
    input [7:0] RxData,  // ignored in this stub
    output reg SS,
    output reg getByte,
    output reg [7:0] sndData,
    output reg [39:0] DOUT
);

    localparam [39:0] PACKET1 = {8'h34, 8'h01, 8'h56, 8'h02, 8'hAA};
    localparam [39:0] PACKET2 = {8'h78, 8'h03, 8'h9A, 8'h00, 8'h55};

    reg active;
    reg done_waiting_for_release;
    reg [2:0] cnt;
    reg trans_sel;   // 0 -> packet1, 1 -> packet2

    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            SS <= 1'b1;
            getByte <= 1'b0;
            sndData <= 8'h00;
            DOUT <= 40'd0;
            active <= 1'b0;
            done_waiting_for_release <= 1'b0;
            cnt <= 3'd0;
            trans_sel <= 1'b0;
        end else begin
            getByte <= 1'b0;
            sndData <= 8'h00;

            // Start fake transaction
            if (!active && !done_waiting_for_release && sndRec) begin
                active <= 1'b1;
                SS <= 1'b0;
                cnt <= 3'd0;
            end
            // Run fake transaction for a few clocks
            else if (active) begin
                cnt <= cnt + 1'b1;
                getByte <= 1'b1;

                if (cnt == 3'd3) begin
                    active <= 1'b0;
                    SS <= 1'b1;  // rising edge means done

                    if (trans_sel == 1'b0)
                        DOUT <= PACKET1;
                    else
                        DOUT <= PACKET2;

                    trans_sel <= ~trans_sel;
                    done_waiting_for_release <= 1'b1;
                end
            end
            // Stay done until sndRec goes low, matching the real spiCtrl behavior
            else if (done_waiting_for_release) begin
                SS <= 1'b1;
                if (!sndRec)
                    done_waiting_for_release <= 1'b0;
            end
            else begin
                SS <= 1'b1;
            end
        end
    end

endmodule


// ============================================================
// Stub spiMode0
// Not really used because stub spiCtrl ignores BUSY/RxData,
// but PmodJSTK_Dual still instantiates it, so we provide it.
// ============================================================
module spiMode0(
    input CLK,
    input RST,
    input sndRec,
    input [7:0] DIN,
    input MISO,
    output MOSI,
    output SCK,
    output BUSY,
    output [7:0] DOUT
);
    assign MOSI = 1'b0;
    assign SCK  = 1'b0;
    assign BUSY = 1'b0;
    assign DOUT = 8'h00;
endmodule
