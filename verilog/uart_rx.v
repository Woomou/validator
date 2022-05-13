//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:32:20 05/01/2022 
// Design Name: 
// Module Name:    uart_rx 
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
module uart_rx(
	input clk,
	input rst_n,
	input uart_rx,
	input clk_bps,
	output bps_start,//波特率时钟
	output [7:0] rx_data,//接收数据寄存器
	output rx_int//接收数据期间指示信号
    );

reg uart_rx0,uart_rx1,uart_rx2,uart_rx3;//接受数据的滤波寄存器
wire neg_uart_rx; //表示数据线的下降沿

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		uart_rx0 <= 1'b0;
		uart_rx1 <= 1'b0;
		uart_rx2 <= 1'b0;
		uart_rx3 <= 1'b0;
	end
	else begin
		uart_rx0 <= uart_rx;
		uart_rx1 <= uart_rx0;
		uart_rx2 <= uart_rx1;
		uart_rx3 <= uart_rx2;
	end
end

assign neg_uart_rx = uart_rx3 & uart_rx2 & ~uart_rx1 & ~uart_rx0;

reg bps_start_r;
reg [3:0] num;//移位次数
reg rx_int_r;//接收数据的中断信号
assign rx_int = rx_int_r;
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		bps_start_r <= 1'bz;
		rx_int_r <= 1'b0;
	end
	//检测到数据线的下降沿
	else if(neg_uart_rx) begin
		bps_start_r <= 1'b1;
		rx_int_r <= 1'b1;
	end
	//接收9位数据
	else if(num == 4'd9) begin
		bps_start_r <= 1'b0;
		rx_int_r <= 1'b0;
	end
end

assign bps_start = bps_start_r;

reg [7:0] rx_data_r;
reg [7:0] rx_temp_data;

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		rx_temp_data <= 8'd0;
		num <= 4'd0;
		rx_data_r <= 8'd0;
	end
	else if(rx_int) begin//允许接收数据
		if(clk_bps) begin//波特率时钟支持
			num <= num + 1'b1;
			case(num)
				//信号锁存
				4'd1: rx_temp_data[0] <= uart_rx;
				4'd2: rx_temp_data[1] <= uart_rx;
				4'd3: rx_temp_data[2] <= uart_rx;
				4'd4: rx_temp_data[3] <= uart_rx;
				4'd5: rx_temp_data[4] <= uart_rx;
				4'd6: rx_temp_data[5] <= uart_rx;
				4'd7: rx_temp_data[6] <= uart_rx;
				4'd8: rx_temp_data[7] <= uart_rx;
				default: ;
			endcase
		end
		else if(num == 4'd9) begin
			num <= 4'd0;
			rx_data_r <= rx_temp_data;
		end
	end
end
assign rx_data = rx_data_r;
endmodule