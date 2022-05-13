//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Hunan Normal University
// Engineer: 刘华林
// 
// Create Date:    11:46:04 05/03/2022 
// Design Name: 
// Module Name:    adxl345_top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: ADXL345顶层控制模块
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module adxl345_top(
	input clk,//提供100MHz时钟
	input rst_n,
	output adxl345_iic_scl,
	inout adxl345_iic_sda,
	output[12:0] x_axis,
	output[12:0] y_axis,
	output[12:0] z_axis
    );

//IIC读写请求指示
wire iicwr_req;
wire iicrd_req;
//读写地址寄存器（从机寄存器地址）
wire [7:0] iic_addr;
//写入数据寄存器（向从机写的数据）
wire [7:0] iic_wrdb;
//读出数据寄存器（从从机读的数据）
wire [7:0] iic_rddb;
//读写完成的响应信号
wire iic_ack;

adxl345_controller axdxl345_controller_i(
	//Input
	.clk(clk),
	.rst_n(rst_n),
	.iic_rddb(iic_rddb),
	.iic_ack(iic_ack),
	//Output
	.iicwr_req(iicwr_req),
	.iicrd_req(iicrd_req),
	.iic_addr(iic_addr),
	.iic_wrdb(iic_wrdb),
	//ADXL345模块读出的三轴数据
	.x_axis(x_axis),
	.y_axis(y_axis),
	.z_axis(z_axis)
);

iic_controller iic_controller_i(
	//Input
	.clk(clk),
	.rst_n(rst_n),
	//Input from Controller
	.iicwr_req(iicwr_req),
	.iicrd_req(iicrd_req),
	//Data register
	.iic_addr(iic_addr),
	.iic_wrdb(iic_wrdb),
	.iic_rddb(iic_rddb),
	.iic_ack(iic_ack),
	//IIC通信的时间线和数据线
	.scl(adxl345_iic_scl),
	.sda(adxl345_iic_sda)
);

endmodule
