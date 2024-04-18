module textRow (
    input        clk,
    input        byteReady,
    input [7:0]  data,
    input [3:0]  outputCharIndex,
    output [7:0] outByte1,
    output [7:0] outByte2,
    output [7:0] outByte3,
    output [7:0] outByte4
);
    localparam bufferWidth = 512; //4*128 - uma linha de 16 char (16*8)
    reg [(bufferWidth-1):0] textBuffer = 0;
    reg [5:0] inputCharIndex = 0;
    reg [1:0] state = 0;
    
    localparam WAIT_FOR_NEXT_CHAR_STATE = 0;
    localparam WAIT_FOR_TRANSFER_FINISH = 1;
    localparam SAVING_CHARACTER_STATE = 2;
    
always @(posedge clk) 
    begin
        case (state)
            WAIT_FOR_NEXT_CHAR_STATE: 
            begin
                if (byteReady == 0)
                    state <= WAIT_FOR_TRANSFER_FINISH;
            end
            WAIT_FOR_TRANSFER_FINISH: 
            begin
                if (byteReady == 1)
                    state <= SAVING_CHARACTER_STATE;
            end
            SAVING_CHARACTER_STATE: 
            begin
                inputCharIndex <= inputCharIndex + 1;
                textBuffer[({4'd0,inputCharIndex}<<3)+:8] <= data;
                state <= WAIT_FOR_NEXT_CHAR_STATE;
            end
        endcase
    end
    
    assign outByte1 = textBuffer[({4'd0, outputCharIndex + 0  } << 3)+:8];
    assign outByte2 = textBuffer[({4'd0, outputCharIndex + 16 } << 3)+:8];
    assign outByte3 = textBuffer[({4'd0, outputCharIndex + 32 } << 3)+:8];
    assign outByte4 = textBuffer[({4'd0, outputCharIndex + 48 } << 3)+:8];
endmodule