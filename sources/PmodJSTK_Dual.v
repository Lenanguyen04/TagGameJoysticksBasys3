`timescale 1ns / 1ps

module PmodJSTK_Dual(
    input  CLK,
    input  RST,
    input  MISO,
    output MOSI,
    output SCK,
    output SS1,
    output SS2,
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

    reg sndRec;
    reg device_sel;   // 0 = joystick 1, 1 = joystick 2
    
    reg poll_tick_d;
    reg ss_int_d;

// FSM states
    localparam IDLE      = 2'd0,
               START     = 2'd1,
               WAIT_DONE = 2'd2,
               RELEASE   = 2'd3;

    reg [1:0] state;

    // Edge detect
    wire poll_rise = poll_tick & ~poll_tick_d;
    wire ss_rise   = ss_int & ~ss_int_d;

    // Route the internal SPI controller SS to one joystick at a time
    assign SS1 = (device_sel == 1'b0) ? ss_int : 1'b1;
    assign SS2 = (device_sel == 1'b1) ? ss_int : 1'b1;

    // ------------------------------------------------
    // Clock divider for SPI serial clock
    // ------------------------------------------------
    ClkDiv_66_67kHz SerialClock (
        .CLK(CLK),
        .RST(RST),
        .CLKOUT(iSCK)
    );

    // ------------------------------------------------
    // Polling divider
    // ------------------------------------------------
    ClkDiv_5Hz PollClock (
        .CLK(CLK),
        .RST(RST),
        .CLKOUT(poll_tick)
    );

    // ------------------------------------------------
    // SPI transaction controller (5-byte packet)
    // ------------------------------------------------
    spiCtrl SPI_Ctrl (
        .CLK(iSCK),
        .RST(RST),
        .sndRec(sndRec),
        .BUSY(BUSY),
        .DIN(8'h00),       // dummy byte sent each transfer
        .RxData(RxData),
        .SS(ss_int),
        .getByte(getByte),
        .sndData(sndData),
        .DOUT(spi_dout)
    );

    // ------------------------------------------------
    // SPI byte engine
    // ------------------------------------------------
    spiMode0 SPI_Int (
        .CLK(iSCK),
        .RST(RST),
        .sndRec(getByte),
        .DIN(sndData),
        .MISO(MISO),
        .MOSI(MOSI),
        .SCK(SCK),
        .BUSY(BUSY),
        .DOUT(RxData)
    );

    // ------------------------------------------------
    // Dual joystick polling FSM
    // ------------------------------------------------
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
            // Save previous values for rising-edge detection
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
                    // Tell spiCtrl to begin one full 5-byte transaction
                    sndRec <= 1'b1;
                    state  <= WAIT_DONE;
                end

                WAIT_DONE: begin
                    // Keep sndRec high while spiCtrl is busy with the transaction
                    sndRec <= 1'b1;

                    // ss_int rises back to 1 when transaction completes
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
                    // Drop sndRec so spiCtrl can leave Done state
                    sndRec <= 1'b0;

                    // Switch to the other joystick for next poll
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
