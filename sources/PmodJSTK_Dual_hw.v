`timescale 1ns / 1ps

module PmodJSTK_Dual_hw(
    input  wire CLK,
    input  wire RST,

    input  wire MISO1,   // JA MISO
    input  wire MISO2,   // JB MISO

    output wire MOSI1,   // JA MOSI
    output wire MOSI2,   // JB MOSI
    output wire SCK1,    // JA SCK
    output wire SCK2,    // JB SCK
    output wire SS1,     // JA SS
    output wire SS2,     // JB SS

    output reg [39:0] DOUT1,
    output reg [39:0] DOUT2
);

    wire iSCK;
    wire poll_tick;
    wire BUSY;
    wire getByte;
    wire [7:0] sndData;
    wire [7:0] RxData;
    wire [39:0] spi_dout;
    wire ss_int;

    wire mosi_int;
    wire sck_int;
    wire miso_sel;

    reg sndRec;
    reg device_sel;   // 0 = joystick 1, 1 = joystick 2
    
    reg poll_tick_d;
    reg ss_int_d;

    localparam IDLE      = 2'd0,
               START     = 2'd1,
               WAIT_DONE = 2'd2,
               RELEASE   = 2'd3;

    reg [1:0] state;

    wire poll_rise = poll_tick & ~poll_tick_d;
    wire ss_rise   = ss_int & ~ss_int_d;

    // Shared bus outputs duplicated onto both PMOD headers
    assign MOSI1 = mosi_int;
    assign MOSI2 = mosi_int;
    assign SCK1  = sck_int;
    assign SCK2  = sck_int;

    // Only one SS active at a time
    assign SS1 = (device_sel == 1'b0) ? ss_int : 1'b1;
    assign SS2 = (device_sel == 1'b1) ? ss_int : 1'b1;

    // Choose the correct MISO input based on which joystick is selected
    assign miso_sel = (device_sel == 1'b0) ? MISO1 : MISO2;

    ClkDiv_66_67kHz SerialClock (
        .CLK(CLK),
        .RST(RST),
        .CLKOUT(iSCK)
    );

    ClkDiv_100Hz PollClock (
        .CLK(CLK),
        .RST(RST),
        .CLKOUT(poll_tick)
    );

    spiCtrl SPI_Ctrl (
        .CLK(iSCK),
        .RST(RST),
        .sndRec(sndRec),
        .BUSY(BUSY),
        .DIN(8'h00),
        .RxData(RxData),
        .SS(ss_int),
        .getByte(getByte),
        .sndData(sndData),
        .DOUT(spi_dout)
    );

    spiMode0 SPI_Int (
        .CLK(iSCK),
        .RST(RST),
        .sndRec(getByte),
        .DIN(sndData),
        .MISO(miso_sel),
        .MOSI(mosi_int),
        .SCK(sck_int),
        .BUSY(BUSY),
        .DOUT(RxData)
    );

    always @(posedge iSCK or posedge RST) begin
        if (RST) begin
            device_sel  <= 1'b0;
            sndRec      <= 1'b0;
            poll_tick_d <= 1'b0;
            ss_int_d    <= 1'b1;
            state       <= IDLE;
            DOUT1       <= 40'd0;
            DOUT2       <= 40'd0;
        end
        else begin
            poll_tick_d <= poll_tick;
            ss_int_d    <= ss_int;

            case (state)
                IDLE: begin
                    sndRec <= 1'b0;
                    if (poll_rise)
                        state <= START;
                    else
                        state <= IDLE;
                end

                START: begin
                    sndRec <= 1'b1;
                    state  <= WAIT_DONE;
                end

                WAIT_DONE: begin
                    sndRec <= 1'b1;
                    if (ss_rise) begin
                        if (device_sel == 1'b0)
                            DOUT1 <= spi_dout;
                        else
                            DOUT2 <= spi_dout;
                        state <= RELEASE;
                    end
                    else begin
                        state <= WAIT_DONE;
                    end
                end

                RELEASE: begin
                    sndRec <= 1'b0;
                    device_sel <= ~device_sel;
                    state <= IDLE;
                end

                default: begin
                    sndRec <= 1'b0;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule