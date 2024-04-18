module uart_tx
  #(parameter CLKFREQ=27000000, BAUD=115200)
   (
    input wire 	        clk,

    input wire 	        send,
    input wire [7:0]    data,

    output reg 	        tx,
    output wire         busy
    );

   initial tx <= 1'b1;

   reg [24:0] clk_count = 7'b0;

   
   always @(posedge clk)
     clk_count <= (baud_clk)? 0 : clk_count + 1;

   wire baud_clk = ((clk_count +1) == (CLKFREQ/BAUD));

   reg [9:0]   buff = 10'b1111111111;
   reg [3:0]   len = 0;
   assign busy = (len < 10);

   always @(posedge clk)
     begin

         if (!busy && send) 
         begin
            buff <= { 1'b1, data[7:0], 1'b0 };
            len = 4'd0;
            tx <= 1;
         end
         else if (busy && baud_clk) 
         begin
            tx <= buff[len];
            len = len + 1;
         end

     end
endmodule


module uart_rx
#(
    parameter DELAY_FRAMES = 234 // 27,000,000 (27Mhz) / 115200 Baud rate
)
(
    input clk,
    input rx,
    output reg byteReady,
    output reg [7:0] dataIn
);

localparam HALF_DELAY_WAIT = (DELAY_FRAMES / 2);

reg [3:0] rxState = 0;
reg [12:0] rxCounter = 0;
reg [2:0] rxBitNumber = 0;

localparam RX_STATE_IDLE = 0;
localparam RX_STATE_START_BIT = 1;
localparam RX_STATE_READ_WAIT = 2;
localparam RX_STATE_READ = 3;
localparam RX_STATE_STOP_BIT = 5;

always @(posedge clk) begin
    case (rxState)
        RX_STATE_IDLE: 
        begin
            byteReady <= 0;
            if (rx == 0) 
            begin
                rxState <= RX_STATE_START_BIT;
                rxCounter <= 1;
                rxBitNumber <= 0;
                byteReady <= 0;
            end
        end 
        RX_STATE_START_BIT: 
        begin
            if (rxCounter == HALF_DELAY_WAIT) begin
                rxState <= RX_STATE_READ_WAIT;
                rxCounter <= 1;
            end else 
                rxCounter <= rxCounter + 1;
        end
        RX_STATE_READ_WAIT: 
        begin
            rxCounter <= rxCounter + 1;
            if ((rxCounter + 1) == DELAY_FRAMES) begin
                rxState <= RX_STATE_READ;
            end
        end
        RX_STATE_READ: 
        begin
            rxCounter <= 1;
            dataIn <= {rx, dataIn[7:1]};
            rxBitNumber <= rxBitNumber + 1;
            if (rxBitNumber == 3'b111)
                rxState <= RX_STATE_STOP_BIT;
            else
                rxState <= RX_STATE_READ_WAIT;
        end
        RX_STATE_STOP_BIT: 
        begin
            rxCounter <= rxCounter + 1;
            if ((rxCounter + 1) == DELAY_FRAMES) 
            begin
                rxState <= RX_STATE_IDLE;
                rxCounter <= 0;
                byteReady <= 1;
            end
        end
    endcase
end
endmodule