module sha256(clk, master_reset, data_in, data_end, delay, hash_done, hash_out);
	input clk, data_end, master_reset;
	input [7:0] data_in;
	integer index;
	wire scheduling_done;
	output reg delay;
	reg rst,tmp_chk;
	reg [1:0] second_route;
	reg[63:0] length;
	reg [31:0] h0,h1,h2,h3,h4,h5,h6,h7;
	wire [255:0] digest;
	output reg hash_done;
	output reg [255:0] hash_out;
	reg [511:0] block_512;

	message_scheduler_and_compressor m1(.reset(rst),.chunk_512(block_512),.clk(clk),.h0(h0),.h1(h1),.h2(h2),.h3(h3),.h4(h4),.h5(h5),.h6(h6),.h7(h7),.digest(digest),.done(scheduling_done));

	always@(posedge clk) begin
		if(master_reset == 1'b1) 
        begin
			hash_done <= 1'b0;
			hash_out<=256'b0;
			tmp_chk <= 1'b1;
			delay <= 1'b0;
			block_512<=512'b0;
			rst<=1'b1;
			index = 0;
			length<= 64'b0;
			second_route = 2'b0;
			h0 <= 32'b01101010000010011110011001100111;
			h1 <= 32'b10111011011001111010111010000101;
			h2 <= 32'b00111100011011101111001101110010;
			h3 <= 32'b10100101010011111111010100111010;
			h4 <= 32'b01010001000011100101001001111111;
			h5 <= 32'b10011011000001010110100010001100;
			h6 <= 32'b00011111100000111101100110101011;
			h7 <= 32'b01011011111000001100110100011001;
		end
		else 
        begin
			if(second_route == 2'd3) 
            begin
				rst = 1'b0;
				delay = 1'b1;
				second_route = 2'd2;
			end
			else if(second_route == 2'd1) 
            begin
				block_512[63:0] = length[63:0];
				rst = 1'b0;
				delay = 1'b1;
				second_route = 2'd0;
			end
			else if(delay==1'b1) 
            begin
				if(scheduling_done == 1'b1) 
                begin
					rst = 1'b1;
					delay = 1'b0;
					block_512=512'b0;
					h0 = digest[255:224];
					h1 = digest[223:192];
					h2 = digest[191:160];
					h3 = digest[159:128];
					h4 = digest[127:96];
					h5 = digest[95:64];
					h6 = digest[63:32];
					h7 = digest[31:0];
					if(second_route == 2'd2) 
                    begin
						second_route = 2'd1;
					end
					else if (second_route == 2'b0 && tmp_chk==1'b0) 
                    begin
						hash_done = 1'b1;
						hash_out = {h0,h1,h2,h3,h4,h5,h6,h7};
					end
				end
			end
			else begin
				if(data_end==1'b0) 
                begin
					block_512[511-index]= data_in[7];
					block_512[511-index-1]= data_in[6];
					block_512[511-index-2]= data_in[5];
					block_512[511-index-3]= data_in[4];
					block_512[511-index-4]= data_in[3];
					block_512[511-index-5]= data_in[2];
					block_512[511-index-6]= data_in[1];
					block_512[511-index-7]= data_in[0];
					index = index + 8;
					if (index>511) 
                    begin 
						rst = 1'b0;
						delay = 1'b1;
						length = length + 512;
						index = 0;
					end

				end
				else if(data_end==1'b1 && tmp_chk==1'b1) 
                begin 
					block_512[511-index]= data_in[7];
					block_512[511-index-1]= data_in[6];
					block_512[511-index-2]= data_in[5];
					block_512[511-index-3]= data_in[4];
					block_512[511-index-4]= data_in[3];
					block_512[511-index-5]= data_in[2];
					block_512[511-index-6]= data_in[1];
					block_512[511-index-7]= data_in[0];
					index = index + 8;
					block_512[511-index] = 1'b1;
					length = length+index;
					tmp_chk = 1'b0;
					if(index<=448) 
                    begin
						block_512[63:0] = length[63:0];
						rst = 1'b0;
						delay = 1'b1;
					end
					else 
                    begin
						second_route=2'd3;
					end
				end
			end
		end
	end
endmodule

module message_scheduler_and_compressor(clk, reset, chunk_512, h0, h1, h2, h3, h4, h5, h6, h7, digest, done);
	input [511:0]chunk_512;
	input clk,reset;
	input [31:0]h0,h1,h2,h3,h4,h5,h6,h7;
	output reg done;
	output reg[255:0] digest;
	reg tmp_chk;
	reg[31:0] m0,m1,m2,m3,m4,m5,m6,m7,m8,m9,m10,m11,m12,m13,m14,m15,a,b,c,d,e,f,g,h;
	wire[31:0]a_new,b_new,c_new,d_new,e_new,f_new,g_new,h_new,s0,s1;
	wire [33:0]val;
	reg [6:0] iter;

	assign s0 = ({m1[6:0],m1[31:7]} ^ {m1[17:0],m1[31:18]} ^ {1'b0,1'b0,1'b0,m1[31:3]});
	assign s1 = {m14[16:0],m14[31:17]} ^ {m14[18:0],m14[31:19]} ^ {1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,m14[31:10]};
    assign val = m0 + s0 + m9 + s1;

	compressor c1(.msg(m0),.iteration(iter),.a(a),.b(b),.c(c),.d(d),.e(e),.f(f),.g(g),.h(h),.out1(a_new),.out2(b_new),.out3(c_new),.out4(d_new),.out5(e_new),.out6(f_new),.out7(g_new),.out8(h_new));

	
	always @(posedge clk) 
    begin
		if (reset == 1'b1) 
        begin
			tmp_chk<=1'b1;
			done<=1'b0;
			iter = 7'b0;
			digest<=256'b0;
		end
		else if (reset==1'b0 && tmp_chk==1'b1) 
        begin
			m15<=chunk_512[31:0];
			m14<=chunk_512[63:32];
			m13<=chunk_512[95:64];
			m12<=chunk_512[127:96];
			m11<=chunk_512[159:128];
			m10<=chunk_512[191:160];
			m9<=chunk_512[223:192];
			m8<=chunk_512[255:224];
			m7<=chunk_512[287:256];
			m6<=chunk_512[319:288];
			m5<=chunk_512[351:320];
			m4<=chunk_512[383:352];
			m3<=chunk_512[415:384];
			m2<=chunk_512[447:416];
			m1<=chunk_512[479:448];
			m0<=chunk_512[511:480];
			a<=h0;
			b<=h1;
			c<=h2;
			d<=h3;
			e<=h4;
			f<=h5;
			g<=h6;
			h<=h7;
			tmp_chk<=1'b0;
		end
		else if(reset == 1'b0 && done==1'b0) 
        begin
			if(iter<64) 
            begin
				a <= a_new;
				b <= b_new;
				c <= c_new;
				d <= d_new;
				e <= e_new;
				f <= f_new;
				g <= g_new;
				h <= h_new;
				m15 <= val[31:0];
				m14 <= m15;
				m13 <= m14;
				m12 <= m13;
				m11 <= m12;
				m10 <= m11;
				m9 <= m10;
				m8 <= m9;
				m7 <= m8;
				m6 <= m7;
				m5 <= m6;
				m4 <= m5;
				m3 <= m4;
				m2 <= m3;
				m1 <= m2;
				m0 <= m1;
				iter <= iter+1;
				
			end
			else if(iter == 7'b1000000) 
            begin
				done = 1'b1;
				a = h0+a;
				b = h1+b;
				c = h2+c;
				d = h3+d;
				e = h4+e;
				f = h5+f;
				g = h6+g;
				h = h7+h;
				digest = {a,b,c,d,e,f,g,h};
			end
		end
	end

endmodule

module compressor(msg,iteration,a,b,c,d,e,f,g,h,out1,out2,out3,out4,out5,out6,out7,out8);

input [31:0]msg,a,b,c,d,e,f,g,h;
input [6:0]iteration;
wire [31:0]K[63:0];
wire[31:0] s1,ch,s0,maj;
wire[33:0] temp1,temp2,t1,t2;
output[31:0]out1,out2,out3,out4,out5,out6,out7,out8;

assign K[0]=32'h428a2f98;
assign K[1]=32'h71374491;
assign K[2]=32'hb5c0fbcf;
assign K[3]=32'he9b5dba5;
assign K[4]=32'h3956c25b;
assign K[5]=32'h59f111f1;
assign K[6]=32'h923f82a4;
assign K[7]=32'hab1c5ed5;
assign K[8]=32'hd807aa98;
assign K[9]=32'h12835b01;
assign K[10]=32'h243185be;
assign K[11]=32'h550c7dc3;
assign K[12]=32'h72be5d74;
assign K[13]=32'h80deb1fe;
assign K[14]=32'h9bdc06a7;
assign K[15]=32'hc19bf174;
assign K[16]=32'he49b69c1;
assign K[17]=32'hefbe4786;
assign K[18]=32'h0fc19dc6;
assign K[19]=32'h240ca1cc;
assign K[20]=32'h2de92c6f;
assign K[21]=32'h4a7484aa;
assign K[22]=32'h5cb0a9dc;
assign K[23]=32'h76f988da;
assign K[24]=32'h983e5152;
assign K[25]=32'ha831c66d;
assign K[26]=32'hb00327c8;
assign K[27]=32'hbf597fc7;
assign K[28]=32'hc6e00bf3;
assign K[29]=32'hd5a79147;
assign K[30]=32'h06ca6351;
assign K[31]=32'h14292967;
assign K[32]=32'h27b70a85;
assign K[33]=32'h2e1b2138;
assign K[34]=32'h4d2c6dfc;
assign K[35]=32'h53380d13;
assign K[36]=32'h650a7354;
assign K[37]=32'h766a0abb;
assign K[38]=32'h81c2c92e;
assign K[39]=32'h92722c85;
assign K[40]=32'ha2bfe8a1;
assign K[41]=32'ha81a664b;
assign K[42]=32'hc24b8b70;
assign K[43]=32'hc76c51a3;
assign K[44]=32'hd192e819;
assign K[45]=32'hd6990624;
assign K[46]=32'hf40e3585;
assign K[47]=32'h106aa070;
assign K[48]=32'h19a4c116;
assign K[49]=32'h1e376c08;
assign K[50]=32'h2748774c;
assign K[51]=32'h34b0bcb5;
assign K[52]=32'h391c0cb3;
assign K[53]=32'h4ed8aa4a;
assign K[54]=32'h5b9cca4f;
assign K[55]=32'h682e6ff3;
assign K[56]=32'h748f82ee;
assign K[57]=32'h78a5636f;
assign K[58]=32'h84c87814;
assign K[59]=32'h8cc70208;
assign K[60]=32'h90befffa;
assign K[61]=32'ha4506ceb;
assign K[62]=32'hbef9a3f7;
assign K[63]=32'hc67178f2;


assign s1 = {e[5:0],e[31:6]} ^ {e[10:0],e[31:11]} ^ {e[24:0],e[31:25]};
assign ch = (e&f) ^ (~e & g);
assign temp1 = h+s1+ch+K[iteration]+msg;
assign s0 = {a[1:0],a[31:2]} ^ {a[12:0],a[31:13]} ^ {a[21:0],a[31:22]};
assign maj = (a&b) ^ (a&c) ^ (b&c);
assign temp2 = s0+maj;
assign t2 = temp1[31:0]+temp2[31:0];
assign out1 = t2[31:0];
assign out8 = g;
assign out7 = f;
assign out6 = e;
assign t1 = d+temp1[31:0];
assign out5 = t1[31:0];
assign out4 = c;
assign out3 = b;
assign out2 = a;

endmodule