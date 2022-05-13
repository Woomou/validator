//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Hunan Normal Univeristy
// Engineer: 刘华林
// 
// Create Date:    10:35:05 05/10/2022 
// Design Name: 
// Module Name:    dotproduct 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 神经网络点积运算
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module dotproduct(
	//数位同步时钟
    input sync_clk,
	input rst_n,
    input [5:0] x_i,
    input [5:0] w_j,
    output reg[3:0] y_ij
    );

wire [5:0] multip;
assign multip = x_i ^~ w_j;
reg [3:0] look_up [63:0];

always @(posedge sync_clk or negedge rst_n) begin
	if(!rst_n) begin
		y_ij <= 4'b0000;
	end
	else begin
		y_ij <= {look_up[multip],1'b0};
	end
end

initial begin
	look_up[0] = 3'b111; //输入6'b000000
	look_up[1] = 3'b110; //输入6'b000001
	look_up[2] = 3'b110; //输入6'b000010
	look_up[3] = 3'b101; //输入6'b000011
	look_up[4] = 3'b110; //输入6'b000100
	look_up[5] = 3'b101; //输入6'b000101
	look_up[6] = 3'b101; //输入6'b000110
	look_up[7] = 3'b000; //输入6'b000111
	look_up[8] = 3'b110; //输入6'b001000
	look_up[9] = 3'b101; //输入6'b001001
	look_up[10] = 3'b101; //输入6'b001010
	look_up[11] = 3'b000; //输入6'b001011
	look_up[12] = 3'b101; //输入6'b001100
	look_up[13] = 3'b000; //输入6'b001101
	look_up[14] = 3'b000; //输入6'b001110
	look_up[15] = 3'b001; //输入6'b001111
	look_up[16] = 3'b110; //输入6'b010000
	look_up[17] = 3'b101; //输入6'b010001
	look_up[18] = 3'b101; //输入6'b010010
	look_up[19] = 3'b000; //输入6'b010011
	look_up[20] = 3'b101; //输入6'b010100
	look_up[21] = 3'b000; //输入6'b010101
	look_up[22] = 3'b000; //输入6'b010110
	look_up[23] = 3'b001; //输入6'b010111
	look_up[24] = 3'b101; //输入6'b011000
	look_up[25] = 3'b000; //输入6'b011001
	look_up[26] = 3'b000; //输入6'b011010
	look_up[27] = 3'b001; //输入6'b011011
	look_up[28] = 3'b000; //输入6'b011100
	look_up[29] = 3'b001; //输入6'b011101
	look_up[30] = 3'b001; //输入6'b011110
	look_up[31] = 3'b010; //输入6'b011111
	look_up[32] = 3'b110; //输入6'b100000
	look_up[33] = 3'b101; //输入6'b100001
	look_up[34] = 3'b101; //输入6'b100010
	look_up[35] = 3'b000; //输入6'b100011
	look_up[36] = 3'b101; //输入6'b100100
	look_up[37] = 3'b000; //输入6'b100101
	look_up[38] = 3'b000; //输入6'b100110
	look_up[39] = 3'b001; //输入6'b100111
	look_up[40] = 3'b101; //输入6'b101000
	look_up[41] = 3'b000; //输入6'b101001
	look_up[42] = 3'b000; //输入6'b101010
	look_up[43] = 3'b001; //输入6'b101011
	look_up[44] = 3'b000; //输入6'b101100
	look_up[45] = 3'b001; //输入6'b101101
	look_up[46] = 3'b001; //输入6'b101110
	look_up[47] = 3'b010; //输入6'b101111
	look_up[48] = 3'b101; //输入6'b110000
	look_up[49] = 3'b000; //输入6'b110001
	look_up[50] = 3'b000; //输入6'b110010
	look_up[51] = 3'b001; //输入6'b110011
	look_up[52] = 3'b000; //输入6'b110100
	look_up[53] = 3'b001; //输入6'b110101
	look_up[54] = 3'b001; //输入6'b110110
	look_up[55] = 3'b010; //输入6'b110111
	look_up[56] = 3'b000; //输入6'b111000
	look_up[57] = 3'b001; //输入6'b111001
	look_up[58] = 3'b001; //输入6'b111010
	look_up[59] = 3'b010; //输入6'b111011
	look_up[60] = 3'b001; //输入6'b111100
	look_up[61] = 3'b010; //输入6'b111101
	look_up[62] = 3'b010; //输入6'b111110
	look_up[63] = 3'b011; //输入6'b111111
end
endmodule
