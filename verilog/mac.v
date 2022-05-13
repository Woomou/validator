//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Hunan Normal Univeristy
// Engineer: 刘华林
// 
// Create Date:    14:14:30 05/11/2022 
// Design Name: 
// Module Name:    mac 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 神经网络乘累加
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module mac(
	input layer_clk,
	input rst_n,
	input data_en,
	//深度6宽度32
	//串行数据X和W传输线
	input [7:0] x,
	input [7:0] w,
	output reg[4:0] y
    );

/*
串行传输协议为每次发送一个字节（8bit），每发送4个字节就切换到下一片地址，
X和W为宽度32深度6的数据，因此24个时钟周期发送完。
收到数据使能信号表示传输开始，发送完
*/

//字节计数器，每次数据使能就进行计数
reg[2:0] byte_clk;
localparam TIME_BYTE_CLK = 6;
assign add_byte_clk = data_en;
assign end_byte_clk = add_byte_clk && (byte_clk == TIME_BYTE_CLK - 1);
always @(posedge layer_clk or negedge rst_n) begin
	if(!rst_n) begin
		byte_clk <= 3'b000;
	end
	else if(add_byte_clk) begin
		if(end_byte_clk) begin
			byte_clk <= 3'b000;
		end
		else begin
			byte_clk <= byte_clk + 1'b1;
		end
	end
end

//片计数器
reg[5:0] slice_clk;
localparam TIME_SLICE_CLK = 62;
assign add_slice_clk = end_byte_clk;
assign end_slice_clk = add_slice_clk && (slice_clk == TIME_SLICE_CLK - 1);
always @(posedge layer_clk or negedge rst_n) begin
	if(!rst_n) begin
		slice_clk <= 6'b000_000;
	end
	else if(add_slice_clk) begin
		if(end_slice_clk) begin
			slice_clk <= 6'b000_000;
		end
		else begin
			slice_clk <= slice_clk + 1'b1;
		end
	end
end

reg[5:0] x_slice;
reg[5:0] w_slice;
//一片的串行输入
always @(posedge end_byte_clk or negedge rst_n) begin
	if(!rst_n) begin
		x_slice <= 6'd0;
		w_slice <= 6'd0;
	end
	else if(data_en) begin
		x_slice <= x;
		w_slice <= w;
	end
end

wire[3:0] conseq;
reg[3:0] conseq_r;
//例化点积运算模块
dotproduct dotproduct_i(
	.sync_clk(layer_clk),
	.rst_n(rst_n),
	.x_i(x_slice),
	.w_j(w_slice),
	.y_ij(conseq)
);
reg[68:0] y_long;//69bit
always @(posedge end_slice_clk or negedge rst_n) begin
	if(!rst_n) begin
		y_long <= 68'd0;
	end
	else begin
		conseq_r <= conseq;
		y_long <= y_long + (conseq_r << slice_clk);
	end
end

reg [68:0]y_div;
always @(posedge layer_clk or negedge rst_n) begin
	if(!rst_n) begin
		y <= 5'd0;
		y_div <= 69'd0;
	end
	else begin
		y_div <= y_long >> 64;
		y <= y_div[4:0];
	end
end

endmodule
