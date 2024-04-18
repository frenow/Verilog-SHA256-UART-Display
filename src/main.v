module top #(parameter STARTUP_WAIT = 32'd10000000)
            (input CLK, 
             RXD, 
             output TXD,
             output LED0, LED1, LED2, LED3, LED4, LED5,
             output ioSclk, ioSdin, ioCs, ioDc, ioReset
            );

    localparam len = 3; //tamanho da string

   //display
   wire [9:0] pixelAddress;
   wire [7:0] textPixelData, chosenPixelData;
   wire [5:0] charAddress;
   reg  [7:0] charOutput;
   wire [1:0] rowNumber;
   wire [7:0] charOut1, charOut2, charOut3, charOut4;

   //uart 
   reg        start   = 1'b0;
   wire       busy;
   wire       byteReady;
   wire [7:0] uartDataIn;
   reg 	      send    = 0;
   reg  [0:(8*len)-1] tx_char = 24'b0;
   reg  [0:7] data = 8'b0;
   reg  [6:0] cont    = 0;

   //sha256
   reg  [6:0] pos   = 0;
   reg        reset = 1'b1;
   reg     data_end = 1'b0;
   //                          a           b           c
   //reg  [0:23]  data = {8'b01100001, 8'b01100010, 8'b01100011};
   wire [0:255] hash;
   wire hash_done, delay;
   wire [7:0] ascii [0:15]; 

   sha256 sha(.clk(CLK), .master_reset(reset), .data_in(data), .data_end(data_end), .delay(delay), .hash_done(hash_done), .hash_out(hash));

   wire [7:0] char = ascii[hash[((pos-1) * 4) +: 4]]; //convert bin to ascii
   
   uart_rx rx(.clk(CLK), .byteReady(byteReady), .dataIn(uartDataIn), .rx(RXD)); //rec   
   uart_tx tx(.clk(CLK), .tx(TXD), .send(send), .data(char), .busy(busy));      //env

   screen #(STARTUP_WAIT) scr(.clk(CLK), .ioSclk(ioSclk), .ioSdin(ioSdin), .ioCs(ioCs), .ioDc(ioDc), .ioReset(ioReset), .pixelAddress(pixelAddress), .pixelData(textPixelData)); //inicializa tela
   assign rowNumber = charAddress[5:4]; //posiciona a linha da impressao na memoria
   uartTextRow row(.clk(CLK), .byteReady(send), .data(char), .outputCharIndex(charAddress[3:0]), .outByte1(charOut1), .outByte2(charOut2), .outByte3(charOut3), .outByte4(charOut4)); //prepara linha
   textEngine te(.clk(CLK), .pixelAddress(pixelAddress), .pixelData(textPixelData), .charAddress(charAddress), .charOutput(charOutput)); //escreve na tela

  always @(posedge CLK) 
  begin
    if (busy)
      send = 0;

      if (byteReady)
      begin
          cont     = cont + 1; 
          tx_char  = {tx_char, uartDataIn};

          if (cont == len)
          begin
              start = 1'b1;
              cont  = 0;
          end
      end

      if (!byteReady && start)
      begin
          cont     = cont + 1; 

          if (cont == 1)
          begin
              reset = 1'b0;  
              data = tx_char[0:7];  
              data_end = 1'b0;
          end
          if (cont == 2)
          begin
              data = tx_char[8:15];  
              data_end = 1'b0;
          end
          if (cont == len)
          begin
              data = tx_char[16:23];  
              data_end = 1'b1; //fim da string e calcular hash
              start    = 1'b0;
          end 
      end

      if (!busy && !send && hash_done)
         begin
            if(pos < 64)
            begin
               send = 1;      //envia char para uart
               pos  = pos + 1;
            end 
         end

       case (rowNumber)
          0: charOutput <= charOut1;
          1: charOutput <= charOut2;
          2: charOutput <= charOut3;
          3: charOutput <= charOut4;
       endcase

  end
  assign LED0 = ~cont[5:5]; 
  assign LED1 = ~cont[4:4];
  assign LED2 = ~cont[3:3];
  assign LED3 = ~cont[2:2];
  assign LED4 = ~cont[1:1];
  assign LED5 = ~cont[0:0];  

  assign ascii[ 0] = 8'h30;
  assign ascii[ 1] = 8'h31;
  assign ascii[ 2] = 8'h32;
  assign ascii[ 3] = 8'h33;
  assign ascii[ 4] = 8'h34;
  assign ascii[ 5] = 8'h35;
  assign ascii[ 6] = 8'h36;
  assign ascii[ 7] = 8'h37;
  assign ascii[ 8] = 8'h38;
  assign ascii[ 9] = 8'h39;
  assign ascii[10] = 8'h61;
  assign ascii[11] = 8'h62;
  assign ascii[12] = 8'h63;
  assign ascii[13] = 8'h64;
  assign ascii[14] = 8'h65;
  assign ascii[15] = 8'h66;  

endmodule