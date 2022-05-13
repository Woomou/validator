//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Hunan Normal University
// Engineer: 刘华林
// 
// Create Date:    17:02:46 05/01/2022 
// Design Name: 
// Module Name:    uart_top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: FPGA顶层启动模块
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module uart_top(
	input ext_clk_50m,
	input ext_rst_n,
	input uart_rx,
	input [7:0] keyboard,
	output uart_tx,
	output [7:0] led,
	output adxl345_iic_scl,
	inout adxl345_iic_sda,
	output adxl345_int1,
	output adxl345_int2,
	output hmc5883l_vcc,
	output hmc5883l_iic_scl,
	output hmc5883l_iic_sda,
	output [7:0] key_pressed,
	output key_down,
	output key_up
    );
assign hmc5883l_vcc = 1'b1;
assign adxl345_int1 = 1'b0;
assign adxl345_int2 = 1'b0;
assign led[5:0] = 6'b11_1111;
assign led[6] = uart_rx;
assign led[7] = uart_tx;

wire sys_rst_n;
wire clk_25m;
wire clk_50m;
wire clk_100m;
wire clk_200m;

pll pll_i
(// Clock in ports
.CLK_IN1(ext_clk_50m),      // IN
// Clock out ports
.CLK_OUT1(clk_25m),     // OUT
.CLK_OUT2(clk_50m),     // OUT
.CLK_OUT3(clk_100m),     // OUT
.CLK_OUT4(clk_200m),     // OUT
// Status and control signals
.RESET(~ext_rst_n),// IN
.LOCKED(sys_rst_n)
);      // OUT

//接收到数据后，波特率时钟启动，置为1
wire bps_start1,bps_start2;
//高电平，表示接收数据位(1bit+8bit+1bit)的中间采样点
wire clk_bps1,clk_bps2;
//接收数据寄存器
wire[7:0] rx_data;
//接收数据的中断信号，在接收期间保持高电平
wire rx_int;

//UART接收信号波特率设置
speed_config speed_rx(
	.clk(clk_100m),
	.rst_n(sys_rst_n),
	.bps_start(bps_start1),
	.clk_bps(clk_bps1)
);
uart_rx rx_i(
	.clk(clk_100m),
	.rst_n(sys_rst_n),
	.uart_rx(uart_rx),
	.rx_data(rx_data),
	.rx_int(rx_int),
	.clk_bps(clk_bps1),
	.bps_start(bps_start1)
);
//UART发送信号波特率设置
speed_config speed_tx(
	.clk(clk_100m),
	.rst_n(sys_rst_n),
	.bps_start(bps_start2),
	.clk_bps(clk_bps2)
);

wire[15:0] x_axis;
wire[15:0] y_axis;
wire[15:0] z_axis;
wire[15:0] x_axis_2;
wire[15:0] y_axis_2;
wire[15:0] z_axis_2;

uart_tx tx_i(
	.clk(clk_100m),
	.rst_n(sys_rst_n),
	.rx_data(rx_data),
	.rx_int(rx_int),
	.x_axis(x_axis),
	.y_axis(y_axis),
	.z_axis(z_axis),
	.uart_tx(uart_tx),
	.clk_bps(clk_bps2),
	.bps_start(bps_start2)
);


adxl345_top adxl345_top_i(
	.clk(clk_100m),
	.rst_n(sys_rst_n),
	.adxl345_iic_scl(adxl345_iic_scl),
	.adxl345_iic_sda(adxl345_iic_sda),
	.x_axis(x_axis),
	.y_axis(y_axis),
	.z_axis(z_axis)
);

hmc5883l_top hmc5883l_top_i(
	.clk(clk_100m),
	.rst_n(sys_rst_n),
	.hmc5883l_iic_scl(hmc5883l_iic_scl),
	.hmc5883l_iic_sda(hmc5883l_iic_sda),
	.x_axis(x_axis_2),
	.y_axis(y_axis_2),
	.z_axis(z_axis_2)
);

stablize stablize_i(
	.clk(clk_100m),
	.rst_n(sys_rst_n),
	.button(keyboard),
	.pressed(pressed),
	.key_pos(key_up),
	.key_neg(key_down)
);

wire layer_en;
wire [7:0] layer_input_x;
wire [7:0] layer_input_w;
wire [4:0] layer_output_y;

mac mac_i(
	.layer_clk(clk_100m),
	.rst_n(sys_rst_n),
	.data_en(layer_en),
	//深度6宽度32
	//串行数据X和W传输线
	.x(layer_input_x),
	.w(layer_input_w),
	.y(layer_output_y)
);

endmodule
