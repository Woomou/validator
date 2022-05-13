//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Hunan Normal University
// Engineer: 刘华林
// 
// Create Date:    17:32:20 05/01/2022 
// Design Name: 
// Module Name:    uart_rx 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: UART-USB发送端口模块
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module uart_tx(
	input clk,
	input rst_n,
	input clk_bps,
	input [7:0] rx_data,
	//根据rx_data编码发送对应轴向的数据
	input [12:0] x_axis,
	input [12:0] y_axis,
	input [12:0] z_axis,
	input rx_int,
	output uart_tx,
	output bps_start
    );

reg rx_int0,rx_int1,rx_int2;
wire neg_rx_int;

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		rx_int0 <= 1'b0;
		rx_int1 <= 1'b0;
		rx_int2 <= 1'b0;
	end
	else begin
		rx_int0 <= rx_int;
		rx_int1 <= rx_int0;
		rx_int2 <= rx_int1;
	end
end
//rx_int1 == 0 且 rx_int2 == 1时neg_rx_int有效为1
assign neg_rx_int = ~rx_int1 & rx_int2;

reg [7:0] tx_data;
reg bps_start_r;
reg tx_en;
reg [3:0] num;

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		bps_start_r <= 1'bz;
		tx_en <= 1'b0;
		tx_data <= 8'd0;
	end
	else if(neg_rx_int) begin
		//对编码器的按情况switch-case处理，只涉及了ADXL345的编码部分
		case(rx_data)
			8'h78:begin 
				tx_data <= x_axis[7:0];//小写x，表示x0
			end
			8'h79:begin
				tx_data <= y_axis[7:0];//小写y，表示y0
			end
			8'h7a:begin
				tx_data <= z_axis[7:0];//小写z，表示z0
			end
			8'h58:begin
				tx_data <= {x_axis[12],x_axis[12],x_axis[12],x_axis[12:8]};//大写x，表示x1
			end
			8'h59:begin
				tx_data <= {y_axis[12],y_axis[12],y_axis[12],y_axis[12:8]};//大写y，表示y1
			end
			8'h5a:begin
				tx_data <= {z_axis[12],z_axis[12],z_axis[12],z_axis[12:8]};//大写z，表示z1
			end
			default:begin
				tx_data <= 8'h00;
			end
		endcase
		bps_start_r <= 1'b1;
		tx_en <= 1'b1;
	end
	else if(num == 4'd10) begin
		bps_start_r <= 1'b0;
		tx_en <= 1'b0;
	end
end

assign bps_start = bps_start_r;

reg uart_tx_r;
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		num <= 4'd0;
		uart_tx_r <= 1'b1;
	end
	else if(tx_en) begin
		if(clk_bps) begin
			num <= num + 1'b1;
			case(num)
				4'd0:uart_tx_r <= 1'b0;//起始位
				4'd1:uart_tx_r <= tx_data[0];
				4'd2:uart_tx_r <= tx_data[1];
				4'd3:uart_tx_r <= tx_data[2];
				4'd4:uart_tx_r <= tx_data[3];
				4'd5:uart_tx_r <= tx_data[4];
				4'd6:uart_tx_r <= tx_data[5];
				4'd7:uart_tx_r <= tx_data[6];
				4'd8:uart_tx_r <= tx_data[7];
				4'd9:uart_tx_r <= 1'b1;//结束位
				default: uart_tx_r <= 1'b1;
			endcase
		end
		else if(num == 4'd10) begin
			num <= 4'd0;
		end
	end
end

assign uart_tx = uart_tx_r;

endmodule
