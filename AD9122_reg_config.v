`include "Register_address.v"
module AD9122_reg_config(
 input                   clk         ,
 input                   rstn        ,
 
 input      r_w_end  , 
 
 output     config_end,
 output  reg [7:0]        ad_rw_addr  ,//寄存器地址
 output  reg [7:0]        w_ad_data   ,//写数据
 output  reg              read_req    ,//读触发信号，一个时钟上升沿触发    
 output  reg              write_req    //写触发信号 
    );
 
 localparam IDLE   = 3'b001;
 localparam WRITE  = 3'b010;
 localparam READ   = 3'b100;
 
 parameter w_cnt_max = 8'd11;
 parameter r_cnt_max = 5'd8;
 
 reg [2:0] state;
 reg [2:0] next_state;
 reg [7:0] w_cnt;
 reg [4:0] r_cnt;
 reg      rstn_r;
 wire   rstn_pos;
 
always @(posedge clk)
  if (~rstn)
    state  <=  IDLE  ;
  else
    state  <= next_state ;
 
always @(*)
  if(~rstn)
      next_state <= IDLE;
  else begin
   case(state)
   IDLE : begin
     if(w_cnt < (w_cnt_max))
      next_state <= WRITE;
     else
      next_state <= IDLE;
   end
   
   WRITE: begin
     if(w_cnt < (w_cnt_max))
      next_state <= WRITE;
     else if((w_cnt == w_cnt_max) && (r_cnt < r_cnt_max))
      next_state <= READ;
     else
      next_state <= WRITE;
   end
   
   READ : begin
     if(r_cnt < r_cnt_max)
      next_state <= READ;
     else
      next_state <= IDLE;
   end
   default : next_state <= IDLE;
   endcase
  end
 
always @(posedge clk)
 if(!rstn)
  {ad_rw_addr,w_ad_data} <= 16'd0;
 else if(next_state == IDLE)
  {ad_rw_addr,w_ad_data} <= 16'd0;
 else if(next_state == WRITE)begin
  case(w_cnt)
      5'd0 :{ad_rw_addr,w_ad_data} <= {1'b0 , `COMM      , `RESET          };      //00h,20h
    5'd1 :{ad_rw_addr,w_ad_data} <= {1'b0 , `COMM       , `COMM_DEFAULT | `SDIO       };//00h,80h
    5'd2 :{ad_rw_addr,w_ad_data} <= {1'b0 , 7'h0D , 8'hD9 };
    5'd3 :{ad_rw_addr,w_ad_data} <= {1'b0 , 7'h0A , 8'hCF };
      5'd4 :{ad_rw_addr,w_ad_data} <= {1'b0 , 7'h0A , 8'hA0 }; //PLL配置，默认0XD9，1101-1001，f_DACCLK=4f_REFCLK,f_VCO=4f_REFCLK,PLL交叉控制使能，DAC时钟与PLL控制器时钟比值为16    
    5'd5 :{ad_rw_addr,w_ad_data} <= {1'b0 , 7'h18 , 8'h02 }; //FIFO复位，位1置1
    5'd6 :{ad_rw_addr,w_ad_data} <= {1'b0 , 7'h18 , 8'h00 }; //FIFO复位，位1置0
    5'd7 :{ad_rw_addr,w_ad_data} <= {1'b0 , 7'h1B , 8'hE4 }; //0010-0010预调制，反sin滤波器，旁路NCO，相位补偿与直流偏置,调制器输出是低边带镜像，I,Q数据独立 0010
    5'd8 :{ad_rw_addr,w_ad_data} <= {1'b0 , 7'h1C , 8'h01}; //HB1滤波器 0000-011[1] ,第0位置1跳过，第2与第3位选择模式
    5'd9:{ad_rw_addr,w_ad_data} <=  {1'b0 , 7'h1D , 8'h01 }; //HB2滤波器
       5'd10:{ad_rw_addr,w_ad_data} <= {1'b0 , 7'h1E , 8'h01 }; //HB3滤波器
    5'd11:{ad_rw_addr,w_ad_data} <= {1'b0 , 7'h30 , 8'h00 }; //频率调节字[7:0]  331313eb
    5'd12:{ad_rw_addr,w_ad_data} <= {1'b0 , 7'h31 , 8'h00 }; //频率调节字[15:8]
    5'd13:{ad_rw_addr,w_ad_data} <= {1'b0 , 7'h32 , 8'h00}; //频率调节字[23:16]
    5'd14:{ad_rw_addr,w_ad_data} <= {1'b0 , 7'h33 , 8'h00 }; //频率调节字[31:24]
    5'd15:{ad_rw_addr,w_ad_data} <= {1'b0 , 7'h36 , 8'h01 };
    5'd16:{ad_rw_addr,w_ad_data} <= {1'b0 , 7'h36 , 8'h00 };
    5'd17:{ad_rw_addr,w_ad_data} <= {1'b0 , 7'h0A , 8'hCF };
    5'd18:{ad_rw_addr,w_ad_data} <= {1'b0 , 7'h0A , 8'hA0 }; 
    default :{ad_rw_addr,w_ad_data} <= 16'd0;
  endcase
 end
 
 else if(next_state == READ) begin
  case(r_cnt)
      5'd0 :ad_rw_addr <= {1'b1 , `COMM   };
            5'd1 :ad_rw_addr <= {1'b1 , 7'h0E };
            5'd2 :ad_rw_addr <= {1'b1 , 7'h0F };
            5'd3 :ad_rw_addr <= {1'b1 , 7'h18 };
            5'd4 :ad_rw_addr <= {1'b1 , 7'h19 };
            5'd5 :ad_rw_addr <= {1'b1 , 7'h15 };
            5'd6 :ad_rw_addr <= {1'b1 , 7'h4A };
            5'd7 :ad_rw_addr <= {1'b1 , 7'h49 };
            5'd8 :ad_rw_addr <= {1'b1 , `HB3_CONTROL_3 };
            5'd9 :ad_rw_addr <= {1'b1 , `FTW_LSB  };
            5'd10:ad_rw_addr <= {1'b1 , `FTW_1   };
            5'd11:ad_rw_addr <= {1'b1 , `FTW_2   };
            5'd12:ad_rw_addr <= {1'b1 , `FTW_MSB  };
            5'd13:ad_rw_addr <= {1'b1 , `NCO_FTW_UPDATE };
   default : ad_rw_addr <= 8'd0;
  endcase
 end
    
always @ (posedge clk) rstn_r <= rstn;
assign rstn_pos = (~rstn_r) & rstn;

always @ (posedge clk) 
 if (!rstn)
  write_req <= 1'b0;
 else if((rstn_pos | r_w_end)&&(w_cnt<w_cnt_max-1'b1))
  write_req <= 1'b1;
 else
  write_req <= 1'b0;

always @ (posedge clk) 
 if (!rstn)
  read_req <= 1'b0;
 else if(r_w_end&&(w_cnt>=w_cnt_max-1'b1)&&(r_cnt<r_cnt_max-1'b1))
  read_req <= 1'b1;
 else
  read_req <= 1'b0;

always @ (posedge clk) 
 if(!rstn)
  w_cnt <= 8'd0;
 else if(r_w_end && (w_cnt<w_cnt_max))
  w_cnt <= w_cnt + 1'b1;
 else
  w_cnt <= w_cnt;
  
always @ (posedge clk) 
 if(!rstn)
  r_cnt <= 5'd0;
 else if(r_w_end && (w_cnt==w_cnt_max)&&(r_cnt<r_cnt_max))
  r_cnt <= r_cnt + 1'b1;
 else
  r_cnt <= r_cnt;  

assign config_end = (r_cnt == r_cnt_max) ? 1'b1:1'b0;  
endmodule