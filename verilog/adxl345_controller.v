//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Hunan Normal University
// Engineer: 刘华林
// 
// Create Date:    22:29:34 05/02/2022 
// Design Name: 
// Module Name:    adxl345_controller 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: ADXL345传感器级通讯控制器
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module adxl345_controller(
	input clk,//100Mhz时钟
	input rst_n,
	output reg iicwr_req,
	output reg iicrd_req,
	output reg[7:0] iic_addr,
	output reg[7:0] iic_wrdb,
	input [7:0] iic_rddb,
	input iic_ack,
	output reg[12:0] x_axis,
	output reg[12:0] y_axis,
	output reg[12:0] z_axis
    );

//初始化寄存器和配置数值
parameter DATA_FORMAT_ADDR = 8'h31,
		  DATA_FORMAT_INIT = 8'h0B,
		  POWER_CTL_ADDR = 8'h2D,
		  POWER_CTL_INIT = 8'h08,
		  INT_ENABLE_ADDR = 8'h2E,
		  INT_ENABLE_INIT = 8'h80;

//上电时间计数器1.1ms = 1100us = 1100_000ns = 110_000 * 10ns
reg[15:0] cnt_1100us;
reg load_done;
localparam TIME_1100us = 110000;
assign add_cnt_1100us = 1'b1;
assign end_cnt_1100us = add_cnt_1100us && (cnt_1100us == TIME_1100us - 1);
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt_1100us <= 16'd0;
		load_done <= 1'b0;
	end
	else if(add_cnt_1100us) begin
		if(end_cnt_1100us) begin
			cnt_1100us <= 16'd0;
			load_done <= 1'b1;
		end
		else begin
			cnt_1100us <= cnt_1100us + 1'b1;
		end
	end
end

reg init_done_r;
/*最小化初始序列，该信号标志初始化是否完成*/
initial begin
	init_done_r <= 1'b0;
end
parameter CIDLE = 3'b000,
		  CWR1 = 3'b001,
		  CWA1 = 3'b010,
		  CWR2 = 3'b011,
		  CWA2 = 3'b100,
		  CWR3 = 3'b101,
		  CSTOP = 3'b110;
reg [2:0] i_cstate;
reg [2:0] i_nstate;

//现态次态切换程序
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		i_cstate <= CIDLE;
	end
	else begin
		i_cstate <= i_nstate;
	end
end

//每隔约10ms就取一次数据的定时器计数器
//10ms = 10_000us = 10_000_000ns = 1000_000*10ns
reg [18:0] cnt_10ms;
parameter TIME_10ms = 1000_000;
assign add_cnt_10ms = 1'b1;
assign end_cnt_10ms = add_cnt_10ms && cnt_10ms == TIME_10ms - 1;
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt_10ms <= 19'd0;
	end
	else if(add_cnt_10ms) begin
		if(end_cnt_10ms) begin
			cnt_10ms <= 19'd0;
		end
		else begin
			cnt_10ms <= cnt_10ms + 1'b1;
		end
	end
end

wire [5:0] timer;
//每两次间隔大于1ms
assign timer[0] = (cnt_10ms == 19'd299_999);
assign timer[1] = (cnt_10ms == 19'd399_999);
assign timer[2] = (cnt_10ms == 19'd599_999);
assign timer[3] = (cnt_10ms == 19'd699_999);
assign timer[4] = (cnt_10ms == 19'd899_999);
assign timer[5] = (cnt_10ms == 19'd999_999);

/*MSB高位的4位是符号位，截取到[12:0]即可*/
parameter X_LSB_ADDR = 8'h32,
		  X_MSB_ADDR = 8'h33,
		  Y_LSB_ADDR = 8'h34,
		  Y_MSB_ADDR = 8'h35,
		  Z_LSB_ADDR = 8'h36,
		  Z_MSB_ADDR = 8'h37;

parameter RIDLE = 4'h0,
		  //读X寄存器
		  RRDX0 = 4'h1,
		  RWAX0 = 4'h2,
		  RRDX1 = 4'h3,
		  RWAX1 = 4'h4,
		  //读Y寄存器
		  RRDY0 = 4'h5,
		  RWAY0 = 4'h6,
		  RRDY1 = 4'h7,
		  RWAY1 = 4'h8,
		  //读Z寄存器
		  RRDZ0 = 4'h9,
		  RWAZ0 = 4'hA,
		  RRDZ1 = 4'hB;
reg [3:0] cstate;
reg [3:0] nstate;

//现态次态切换程序
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cstate <= RIDLE;
	end
	else begin
		cstate <= nstate;
	end
end

//次态的状态转移程序
always @(cstate or i_cstate or iic_ack or init_done_r or load_done or end_cnt_1100us
		or timer[0] or timer[1] or timer[2] or timer[3] or timer[4] or timer[5]) begin
	//初始化配置，未初始化且上电完成
	if(~init_done_r && load_done) begin
		case(i_cstate)
			CIDLE: begin
				if(end_cnt_1100us) begin
					i_nstate <= CWR1;
				end
				else begin
					i_nstate <= CIDLE;
				end
			end
			CWR1: begin
				if(iic_ack) begin
					i_nstate <= CWA1;
				end
				else begin
					i_nstate <= CWR1;
				end
			end
			CWA1: begin
				if(end_cnt_1100us) begin
					i_nstate <= CWR2;
				end
				else begin
					i_nstate <= CWA1;
				end
			end
			CWR2: begin
				if(iic_ack) begin
					i_nstate <= CWA2;
				end
				else begin
					i_nstate <= CWR2;
				end
			end
			CWA2: begin
				if(end_cnt_1100us) begin
					i_nstate <= CWR3;
				end
				else begin
					i_nstate <= CWA2;
				end
			end
			CWR3: begin
				if(iic_ack) begin
					i_nstate <= CSTOP;
				end
				else begin
					i_nstate <= CWR3;
				end
			end
			CSTOP: begin
				if(~init_done_r) begin
					init_done_r <= 1'b1;
				end
				i_nstate <= CIDLE;
			end
			default: i_nstate <= CIDLE;
		endcase
	end
	else begin
		case(cstate)
			RIDLE: begin
				if(timer[0]) begin
					nstate <= RRDX0;
				end
				else begin
					nstate <= RIDLE;
				end
			end
			RRDX0: begin
				if(iic_ack) begin
					nstate <= RWAX0;
				end
				else begin
					nstate <= RRDX0;
				end
			end
			RWAX0: begin
				if(timer[1]) begin
					nstate <= RRDX1;
				end
				else begin
					nstate <= RWAX0;
				end
			end
			RRDX1: begin
				if(iic_ack) begin
					nstate <= RWAX1;
				end
				else begin
					nstate <= RRDX1;
				end
			end
			RWAX1: begin
				if(timer[2]) begin
					nstate <= RRDY0;
				end
				else begin
					nstate <= RWAX1;
				end
			end
			RRDY0: begin
				if(iic_ack) begin
					nstate <= RWAY0;
				end
				else begin
					nstate <= RRDY0;
				end
			end
			RWAY0: begin
				if(timer[3]) begin
					nstate <= RRDY1;
				end
				else begin
					nstate <= RWAY0;
				end
			end
			RRDY1: begin
				if(iic_ack) begin
					nstate <= RWAY1;
				end
				else begin
					nstate <= RRDY1;
				end
			end
			RWAY1: begin
				if(timer[4]) begin
					nstate <= RRDZ0;
				end
				else begin
					nstate <= RWAY1;
				end
			end
			RRDZ0: begin
				if(iic_ack) begin
					nstate <= RWAZ0;
				end
				else begin
					nstate <= RRDZ0;
				end
			end
			RWAZ0: begin
				if(timer[5]) begin
					nstate <= RRDZ1;
				end
				else begin
					nstate <= RWAZ0;
				end
			end
			RRDZ1: begin
				if(iic_ack) begin
					nstate <= RIDLE;
				end
				else begin
					nstate <= RRDZ1;
				end
			end
			default: nstate <= RIDLE;
		endcase
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		iicwr_req <= 1'b0;
		iicrd_req <= 1'b0;
		iic_addr <= 8'd0;
		iic_wrdb <= 8'd0;
	end
	//根据状态机信号初始化写入寄存器
	else if(~init_done_r) begin
		case(i_cstate)
			//写DATA_FORMAT寄存器
			CWR1: begin
				iicwr_req <= 1'b1;
				//读请求高电平有效
				iicrd_req <= 1'b0;
				//读写地址寄存器
				iic_addr <= DATA_FORMAT_ADDR;
				//要写入的数据的寄存器
				iic_wrdb <= DATA_FORMAT_INIT;
			end
			//写POWER_CTL寄存器
			CWR2: begin
				iicwr_req <= 1'b1;
				//读请求高电平有效
				iicrd_req <= 1'b0;
				//读写地址寄存器
				iic_addr <= POWER_CTL_ADDR;
				//要写入的数据的寄存器
				iic_wrdb <= POWER_CTL_INIT;
			end
			//写INT_ENALBLE寄存器
			CWR3: begin
				iicwr_req <= 1'b1;
				//读请求高电平有效
				iicrd_req <= 1'b0;
				//读写地址寄存器
				iic_addr <= INT_ENABLE_ADDR;
				//要写入的数据的寄存器
				iic_wrdb <= INT_ENABLE_INIT;
			end
			default: begin
				iicwr_req <= 1'b0;
				iicrd_req <= 1'b0;
				iic_addr <= 8'd0;
				iic_wrdb <= 8'd0;
			end
		endcase
	end
	else begin
		case(cstate)
			//读X0寄存器
			RRDX0: begin
				iicwr_req <= 1'b0;
				//读请求高电平有效
				iicrd_req <= 1'b1;
				//读写地址寄存器
				iic_addr <= X_LSB_ADDR;
				//要写入的数据的寄存器
				iic_wrdb <= 8'd0;
			end
			//读X1寄存器
			RRDX1: begin
				iicwr_req <= 1'b0;
				//读请求高电平有效
				iicrd_req <= 1'b1;
				//读写地址寄存器
				iic_addr <= X_MSB_ADDR;
				//要写入的数据的寄存器
				iic_wrdb <= 8'd0;
			end
			//读Y0寄存器
			RRDY0: begin
				iicwr_req <= 1'b0;
				//读请求高电平有效
				iicrd_req <= 1'b1;
				//读写地址寄存器
				iic_addr <= Y_LSB_ADDR;
				//要写入的数据的寄存器
				iic_wrdb <= 8'd0;
			end
			//读Y1寄存器
			RRDY1: begin
				iicwr_req <= 1'b0;
				//读请求高电平有效
				iicrd_req <= 1'b1;
				//读写地址寄存器
				iic_addr <= Y_MSB_ADDR;
				//要写入的数据的寄存器
				iic_wrdb <= 8'd0;
			end
			//读Z0寄存器
			RRDZ0: begin
				iicwr_req <= 1'b0;
				//读请求高电平有效
				iicrd_req <= 1'b1;
				//读写地址寄存器
				iic_addr <= Z_LSB_ADDR;
				//要写入的数据的寄存器
				iic_wrdb <= 8'd0;
			end
			//读Z1寄存器
			RRDZ1: begin
				iicwr_req <= 1'b0;
				//读请求高电平有效
				iicrd_req <= 1'b1;
				//读写地址寄存器
				iic_addr <= Z_MSB_ADDR;
				//要写入的数据的寄存器
				iic_wrdb <= 8'd0;
			end
			default: begin
				iicwr_req <= 1'b0;
				iicrd_req <= 1'b0;
				iic_addr <= 8'd0;
				iic_wrdb <= 8'd0;
			end
		endcase
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		x_axis <= 13'd0;
		y_axis <= 13'd0;
		z_axis <= 13'd0;
	end
	else begin
		case(cstate)
			RRDX0: if(iic_ack) begin
				x_axis[7:0] <= iic_rddb;
			end
			RRDX1: if(iic_ack) begin
				x_axis[12:8] <= iic_rddb[4:0];
			end
			RRDY0: if(iic_ack) begin
				y_axis[7:0] <= iic_rddb;
			end
			RRDY1: if(iic_ack) begin
				y_axis[12:8] <= iic_rddb[4:0];
			end
			RRDZ0: if(iic_ack) begin
				z_axis[7:0] <= iic_rddb;
			end
			RRDZ1: if(iic_ack) begin
				z_axis[12:8] <= iic_rddb[4:0];
			end
			default: ;
		endcase
	end
end

endmodule
