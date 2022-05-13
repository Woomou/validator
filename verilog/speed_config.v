//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:22:03 05/01/2022 
// Design Name: 
// Module Name:    speed_config 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module speed_config(
	input clk,
	input rst_n,
	input bps_start,
	output clk_bps
    );

`define CLK_PERIOD 10 //10ns,100MHz
`define BPS_SET	   1152 //"115200/100"=1152表示波特率
`define BPS_PARA (10_000_000/`CLK_PERIOD/`BPS_SET) //波特率时钟周期
`define BPS_PARA_2 (`BPS_PARA/2)

reg [12:0] cnt;	//分频计数器
reg clk_bps_r;	//波特率时钟的寄存器

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		cnt <= 13'd0;//计数器复位
	end
	else if((cnt == `BPS_PARA) || !bps_start) begin
		cnt <= 13'd0;//计数器清零
	end
	else begin
		cnt <= cnt + 1'b1;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		clk_bps_r <= 1'b0;
	end
	else if(cnt == `BPS_PARA_2) begin
		clk_bps_r <= 1'b1;//接收数据位的中间采样点
	end
	else begin
		clk_bps_r <= 1'b0;
	end
end

assign clk_bps = clk_bps_r;

endmodule
