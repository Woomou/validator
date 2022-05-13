//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Hunan Normal University
// Engineer: 刘华林
// 
// Create Date:    18:34:38 05/02/2022 
// Design Name: 
// Module Name:    iic_controller 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 底层IIC协议通讯模块
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module iic_controller(
	input clk,
	input rst_n,
	//IIC读写请求信号，高电平有效
	input iicwr_req,
	input iicrd_req,
	//IIC地址寄存器
	input [7:0] iic_addr,
	//IIC写入和读出数据寄存器
	input [7:0] iic_wrdb,//要写入到从设备的数据
	output reg[7:0] iic_rddb,//已由从设备读出的数据
	//IIC读写完成的ACK信号
	output iic_ack,
	output reg scl,
	inout sda
);
//Current State & Next State
reg [3:0] cstate,nstate;
//IIC读或写控制-状态命名
parameter DIDLE = 4'b0000,
		  DSTAR = 4'b0001,
		  //写出从机地址
		  DSADRW = 4'b0010,//slave address(write)
		  D1ACK = 4'b0011,
		  //写出设备地址
		  DRADR = 4'b0100,//device address write
		  D2ACK = 4'b0101,
		  /*write data*/
		  DWRDB = 4'b0110,//write data
		  D3ACK = 4'b0111,
		  /*read data*/
		  DRSTA = 4'b1000,
		  DSADRR = 4'b1001,//slave address(read)
		  D4ACK = 4'b1010,
		  DRDDB = 4'b1011,//read data
		  D5ACK = 4'b1100,
		  DSTOP = 4'b1101;

/*设备的读写地址,十六进制表示*/
parameter DEVICE_WRADDR = 8'ha6,
		  DEVICE_RDADDR = 8'ha7;

//产生IIC时钟信号
/*100KHz = 10us 100M/100K = 1000个单位*/
reg [9:0] scl_cnt;
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		scl_cnt <= 10'd0;
	end
	else begin
		scl_cnt <= scl_cnt + 1'b1;
	end
end

//只要scl_cnt最高位为零或dcstate处于IDLE就输出高电平
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		scl <= 1'b1;
	end
	else if(nstate == DIDLE) begin
		scl <= 1'b1;
	end
	else begin
		scl <= ~scl_cnt[9];
	end
end

//SCL时钟状态信号
wire scl_h_sta = (scl_cnt == 12'd1);
wire scl_h_cen = (scl_cnt == 12'd257);
wire scl_l_sta = (scl_cnt == 12'd513);
wire scl_l_cen = (scl_cnt == 12'd769);

/*每一字节的第几位的计数器,0~7*/
reg [2:0] bit_cnt;
/*SDA输出数据的串行寄存器*/
reg sda_r;
/*sda_link = 1->output
  sda_link = 0->input*/
reg sda_link;

//现态次态切换程序
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cstate <= DIDLE;
	end
	else begin
		cstate <= nstate;
	end
end

//次态的状态转移程序
always @(cstate or iicwr_req or iicrd_req
		 or scl_h_cen or scl_l_cen
		 or scl_h_sta or scl_l_sta
		 or bit_cnt) begin
	case(cstate)
		/*空闲状态 DIDLE*/
		DIDLE: if( (iicwr_req || iicrd_req) && scl_h_sta ) begin
			nstate <= DSTAR;
		end
		else begin
			nstate <= DIDLE;
		end
		/*开始传输状态 DSTAR*/
		DSTAR: if(scl_l_sta) begin //数据开始传输的标志
			nstate <= DSADRW;
		end
		else begin
			nstate <= DSTAR;
		end
		/*写出从机地址 DSADRW*/
		DSADRW: if(scl_l_cen && (bit_cnt == 3'd0)) begin
			//一个字节传完且低电平中间位置，则转移
			nstate <= D1ACK;
		end
		else begin
			nstate <= DSADRW;
		end
		/*从机应答 D1ACK*/
		D1ACK: if(scl_l_sta && (bit_cnt == 3'd7)) begin //第一个应答信号接收
			//数据位计数器重置且低电平开始，则转移
			nstate <= DRADR;
		end
		else begin
			nstate <= D1ACK;
		end
		/*写出设备地址 DRADR*/
		DRADR: if(scl_l_cen && (bit_cnt == 3'd0)) begin
			//一个字节传完且低电平中间位置，则转移
			nstate <= D2ACK;
		end
		else begin
			nstate <= DRADR;
		end
		/*从机应答 D2ACK 决定下一步怎么做*/
		//数据位计数器重置且低电平开始，则转移
		D2ACK: if(scl_l_sta && (bit_cnt == 3'd7) && iicwr_req) begin
			nstate <= DWRDB;
		end
		else if(scl_l_sta && (bit_cnt == 3'd7) && iicrd_req) begin
			nstate <= DRSTA;
		end
		else begin
			nstate <= D2ACK;
		end
		/*------写出数据------*/
		DWRDB: if(scl_l_cen && (bit_cnt == 3'd0)) begin
			//一个字节传完且低电平中间位置，则转移
			nstate <= D3ACK;
		end
		else begin
			nstate <= DWRDB;
		end
		/*从机应答写出数据*/
		D3ACK: if(scl_l_sta && (bit_cnt == 3'd7)) begin
			//数据位计数器重置且低电平开始，则转移
			nstate <= DSTOP;
		end
		else begin
			nstate <= D3ACK;
		end
		/*------读入数据------*/
		DRSTA: if(scl_l_sta) begin
			//时钟拉低表示开始
			nstate <= DSADRR;
		end
		else begin
			nstate <= DRSTA;
		end
		/*从机地址，用于读出*/
		DSADRR: if(scl_l_cen && (bit_cnt == 3'd0)) begin
			//一个字节传完且低电平中间位置，则转移
			nstate <= D4ACK;
		end
		else begin
			nstate <= DSADRR;
		end
		/*从机应答*/
		D4ACK: if(scl_l_sta && (bit_cnt == 3'd7)) begin
			//数据位计数器重置且低电平开始，则转移
			nstate <= DRDDB;
		end
		else begin
			nstate <= D4ACK;
		end
		/*从从机读出数据*/
		DRDDB: if(scl_h_cen && (bit_cnt == 3'd7)) begin
			//高电平中间位置开始
			nstate <= D5ACK;
		end
		else begin
			nstate <= DRDDB;
		end
		/*从机应答*/
		D5ACK: if(scl_l_sta && (bit_cnt == 3'd6)) begin
			//低电平开始位置，传完1个结束bit
			nstate <= DSTOP;
		end
		else begin
			nstate <= D5ACK;
		end
		/*停止转空闲状态*/
		DSTOP: if(scl_l_sta) begin
			//时钟重新拉高就转入空闲状态等待下一轮
			nstate <= DIDLE;
		end
		else begin
			nstate <= DSTOP;
		end
	endcase
end

/*数据位寄存器的控制逻辑
  该寄存器从高位递减到低位*/
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		bit_cnt <= 3'd0;
	end
	else begin
		case(cstate)
			//空闲状态保持
			DIDLE: bit_cnt <= 3'd7;
			//写出从机地址、设备地址等均移动数据位(上升沿时)
			DSADRW,DRADR,DWRDB,DSADRR: if(scl_h_sta) begin
				bit_cnt <= bit_cnt - 1'b1;
			end
			DRDDB: if(scl_h_sta) begin
				bit_cnt <= bit_cnt - 1'b1;
			end
			//D1~D4应答信号，重置数据位寄存器
			D1ACK,D2ACK,D3ACK: if(scl_l_cen) begin
				bit_cnt <= 3'd7;
			end
			D4ACK: if(scl_l_sta) begin
				bit_cnt <= 3'd7;
			end
			//D5ACK，移动一个数据位bit(高电平中间位置时)
			D5ACK: if(scl_l_cen) begin
				bit_cnt <= bit_cnt - 1'b1;
			end
			default: ;
		endcase
	end
end

/*IIC根据控制完成数据输入输出*/
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		sda_r <= 1'b1;
		sda_link <= 1'b1;
		iic_rddb <= 8'd0;
	end
	else begin
		case(cstate)
			//sda线保持高电平
			DIDLE: begin
				sda_r <= 1'b1;
				//sda为输出方向
				sda_link <= 1'b1;
			end
			//高电平时，拉低sda线
			DSTAR: begin
				if(scl_h_cen) begin
					sda_r <= 1'b0;
				end
			end
			//低电平时，逐位输出从设备的写地址
			DSADRW: begin
				if(scl_l_cen) begin
					sda_r <= DEVICE_WRADDR[bit_cnt];
				end
			end
			//低电平时，sda线拉到高阻态
			D1ACK: begin
				if(scl_l_cen) begin
					sda_r <= 1'b1;
					//sda转输入方向
					sda_link <= 1'b0;
				end
			end
			//低电平时，逐位输出本设备地址
			DRADR: begin
				if(scl_l_cen) begin
					sda_r <= iic_addr[bit_cnt];
					//sda转输出方向
					sda_link <= 1'b1;
				end
			end
			//低电平时，sda线拉至高阻态
			D2ACK: begin
				if(scl_l_cen) begin
					sda_r <= 1'b1;
					//sda转输入方向
					sda_link <= 1'b0;
				end
			end
			/*写出操作*/
			//低电平，逐位输出待写出的数据的地址
			DWRDB: begin
				if(scl_l_cen) begin
					sda_r <= iic_wrdb[bit_cnt];
					//sda转输出方向
					sda_link <= 1'b1;
				end
			end
			//低电平时，sda线拉至高阻态
			D3ACK: begin
				if(scl_l_cen) begin
					sda_r <= 1'b1;
					//sda转输入方向
					sda_link <= 1'b0;
				end
			end
			/*读入操作*/
			//高电平时，拉低sda线
			//低电平时，维持sda线高电平
			DRSTA: begin
				if(scl_h_cen) begin
					sda_r <= 1'b0;
				end
				else if(scl_l_cen) begin
					sda_r <= 1'b1;
					//sda转输出方向
					sda_link <= 1'b1;
				end
			end
			//低电平，逐位输出设备读地址
			DSADRR: begin
				if(scl_l_cen) begin
					sda_r <= DEVICE_RDADDR[bit_cnt];
				end
			end
			//低电平且数据位寄存器已重置，sda线拉高
			D4ACK: begin
				if(scl_l_cen && (bit_cnt == 3'd7)) begin
					//sda转输入方向
					sda_link <= 1'b0;
				end
			end
			//高电平时，从sda读出数据
			DRDDB: begin
				if(scl_h_cen) begin
					iic_rddb[bit_cnt + 1'b1] <= sda;
					sda_r <= 1'b1;
				end
			end
			//低电平时，拉低sda线
			D5ACK: begin
				if(scl_l_cen) begin
					sda_r <= 1'b0;
					sda_link <= 1'b1;
				end
			end
			//低电平时，拉低sda线
			//高电平时，拉高sda线
			DSTOP: begin
				if(scl_l_cen) begin
					sda_link <= 1'b1;
					sda_r <= 1'b0;
				end
				else if(scl_h_cen) begin
					sda_r <= 1'b1;
				end
			end
			default: ;
		endcase
	end
end

assign sda = sda_link? sda_r:1'bz;
//IIC读写完成响应信号
assign iic_ack = (cstate == DSTOP) && scl_h_sta;

endmodule
