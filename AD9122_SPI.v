module AD9122_SPI(
 input                   clk         ,
 input                   rstn        ,
 input   [7:0]           ad_rw_addr  ,//寄存器地址
 input   [7:0]           w_ad_data   ,//写数据
 input                  read_req    ,//读触发信号，一个时钟上升沿触发    
 input                  write_req   ,//写触发信号 
 
 output      [7:0] read_data  ,//输出读数据 
 output  reg             r_w_end     ,//读/写 完使能，读写完产生一个时钟上升沿                              
 output  reg           AD_SCLK     ,
 output  reg           AD_CSB      ,  

 input                  AD_SDI     ,//separate SDIO input (device -> controller)
 output                 AD_SDO     ,//separate SDIO output (controller -> device)
 output                 SDIO_OUT_EN//1=controller drives AD_SDO, 0=controller should not drive (top-level may tri-state)
     );
 
 localparam IDLE     = 6'b000001 ;//空闲状态
 localparam R_SPI   = 6'b000010 ;
 localparam W_SPI    = 6'b000100 ;
 localparam R_SPI_DATA   = 6'b001000 ;
 localparam W_END     = 6'b010000 ;
 localparam R_END  = 6'b100000 ;    
 //根据芯片手册，AD_SDIO应该在AD_SCLK上升沿之前至少2ns就准备好数，此模块提前了2个clk周期
 parameter [7:0] sclk_cnt_max = 8'd10;//对clk周期分频(最好是偶数)、、对应mdc下降沿
 parameter [7:0] sclk_cnt_half = sclk_cnt_max >> 1;//对应AD_SCLK上升沿

 reg [5:0] state;
 reg [5:0] next_state;

 reg sdio_out;

 reg sclk_cnt_en,sclk_cnt_en_r;
 wire sclk_cnt_en_neg;
 reg [7:0] sclk_cnt;
 reg [7:0] sclk_bit_cnt;//每次产生18个sclk时钟(16个spi时钟+2个无用时钟)
 reg [7:0] read_data_r;  
// SDIO_OUT_EN is exposed as an output port (see module ports)

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
                  if(read_req)
                      next_state <= R_SPI;
                  else if(write_req)
                      next_state <= W_SPI;
                  else
                      next_state <= IDLE;
          end
          R_SPI : begin
                      if(sclk_bit_cnt == 8'd7 && sclk_cnt == (sclk_cnt_max - 8'd1))
                          next_state <= R_SPI_DATA;
                      else
                          next_state <= R_SPI;
          end
          R_SPI_DATA : begin
                      if(sclk_bit_cnt == 8'd16 && sclk_cnt == (sclk_cnt_max - 8'd1))
                          next_state <= R_END;
                      else
                          next_state <= R_SPI_DATA;                         
          end
          R_END : begin
                      if(sclk_cnt_en_neg)
                          next_state <= IDLE;
                      else
                          next_state <= R_END;
          end
          W_SPI : begin
                      if(sclk_bit_cnt == 8'd16 && sclk_cnt == (sclk_cnt_max - 8'd1))
                          next_state <= W_END;
                      else
                          next_state <= W_SPI;
          end
          W_END : begin
                      if(sclk_cnt_en_neg)
                          next_state <= IDLE;
                      else
                          next_state <= W_END;
          end
          default : next_state <= IDLE;
      endcase      
  end
//操作寄存器，负责写sdio部分
always@(posedge clk)
  if(~rstn)begin   
    //   sdio_out  <= 1'bz;
      sdio_out  <= 1'b1;
   read_data_r <= 8'b0;
  end
  else if(next_state == IDLE || next_state == W_END || next_state == R_END)
    //   sdio_out <= 1'bz;
      sdio_out  <= 1'b1;
  else if(next_state == R_SPI)begin
       case(sclk_bit_cnt) 
             8'd0   : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) sdio_out <= ad_rw_addr[7];
             8'd1   : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) sdio_out <= ad_rw_addr[6];
             8'd2   : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) sdio_out <= ad_rw_addr[5];
             8'd3   : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) sdio_out <= ad_rw_addr[4];
             8'd4   : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) sdio_out <= ad_rw_addr[3];
             8'd5   : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) sdio_out <= ad_rw_addr[2];
             8'd6   : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) sdio_out <= ad_rw_addr[1];
             8'd7   : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) sdio_out <= ad_rw_addr[0];
             default : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) sdio_out <= 1'b1    ;
       endcase
  end
  
    else if(next_state == R_SPI_DATA)begin
  case(sclk_bit_cnt)
        8'd8   : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) read_data_r[7] <= AD_SDI  ;
                         8'd9   : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) read_data_r[6] <= AD_SDI  ;
                         8'd10   : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) read_data_r[5] <= AD_SDI  ;
                         8'd11   : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) read_data_r[4] <= AD_SDI  ;
                         8'd12   : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) read_data_r[3] <= AD_SDI  ;
                         8'd13   : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) read_data_r[2] <= AD_SDI  ;
                         8'd14   : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) read_data_r[1] <= AD_SDI  ;
                         8'd15   : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) read_data_r[0] <= AD_SDI  ;
    default : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) read_data_r <= read_data_r  ; 
  endcase
  end
  
  else if(next_state == W_SPI)begin
      case(sclk_bit_cnt) 
             8'd0   : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) sdio_out <= ad_rw_addr[7];
             8'd1   : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) sdio_out <= ad_rw_addr[6];
             8'd2   : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) sdio_out <= ad_rw_addr[5];
             8'd3   : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) sdio_out <= ad_rw_addr[4];
             8'd4   : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) sdio_out <= ad_rw_addr[3];
             8'd5   : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) sdio_out <= ad_rw_addr[2];
             8'd6   : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) sdio_out <= ad_rw_addr[1];
             8'd7   : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) sdio_out <= ad_rw_addr[0];

             8'd8   : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) sdio_out <= w_ad_data[7] ;
             8'd9   : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) sdio_out <= w_ad_data[6] ;
             8'd10   : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) sdio_out <= w_ad_data[5] ;
             8'd11   : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) sdio_out <= w_ad_data[4] ;
             8'd12   : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) sdio_out <= w_ad_data[3] ;
             8'd13   : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) sdio_out <= w_ad_data[2] ;
             8'd14   : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) sdio_out <= w_ad_data[1] ;
             8'd15   : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) sdio_out <= w_ad_data[0] ;
    default : if(sclk_cnt_en && sclk_cnt == (sclk_cnt_half - 8'd3)) sdio_out <= 1'b1    ;//sdio_out <= 1'b1;
      endcase
  end
//操作寄存器，负责读sdio输出8位数据部分
assign SDIO_OUT_EN = (next_state == R_SPI_DATA) ? 1'b0 : 1'b1;               
// Drive separate output pin with the internal sdio_out value. Top-level should
// use SDIO_OUT_EN to tri-state the physical pin when SDIO_OUT_EN==0.
assign AD_SDO = sdio_out;

assign read_data = (sclk_bit_cnt==8'd16) ? read_data_r : read_data;

always@(posedge clk)
  if(~rstn)
      r_w_end <= 1'b0;
  else if(sclk_cnt_en_neg)
      r_w_end <= 1'b1;
  else
      r_w_end <= 1'b0;
//sclk产生计数器
always@(posedge clk) sclk_cnt_en_r <= sclk_cnt_en;
assign sclk_cnt_en_neg = (~sclk_cnt_en) & sclk_cnt_en_r;//sclk_cnt_en下降沿检测

always@(posedge clk)
    if(~rstn)
        sclk_cnt_en <= 1'b0;
    else if(sclk_bit_cnt == 8'd18)
        sclk_cnt_en <= 1'b0;
    else if(write_req || read_req)
        sclk_cnt_en <= 1'b1;
    else
        sclk_cnt_en <= sclk_cnt_en;
always@(posedge clk)
    if(~rstn)
        sclk_bit_cnt <= 8'd0;
    else if(sclk_bit_cnt == 8'd18)
        sclk_bit_cnt <= 8'd0;
    else if(sclk_cnt == (sclk_cnt_max - 8'd1))
        sclk_bit_cnt <= sclk_bit_cnt + 1'b1;

always@(posedge clk)
  if(~rstn)
      sclk_cnt <= 8'd0;
  else if(sclk_cnt_en && sclk_cnt == (sclk_cnt_max - 8'd1))
      sclk_cnt <= 8'd0;
  else if(sclk_cnt_en)
      sclk_cnt <= sclk_cnt + 1'b1;
  else 
      sclk_cnt <= 8'd0;
   
always@(posedge clk)
  if(~rstn)   
      AD_SCLK <= 1'b0;
  else if(sclk_cnt_en)begin
      if(sclk_cnt == (sclk_cnt_half - 8'd1))
          AD_SCLK <= 1'b1;
      else if(sclk_cnt == (sclk_cnt_max - 8'd1))
          AD_SCLK <= 1'b0;
  end
  else
      AD_SCLK <= 1'b0;

always@(posedge clk)
    if(!rstn)
        AD_CSB <= 1'b1;
    else if(write_req || read_req)
        AD_CSB <= 1'b0;
    else if(sclk_bit_cnt == 8'd16 && (sclk_cnt_half - 8'd2))
        AD_CSB <= 1'b1;
    else
        AD_CSB <= AD_CSB;
endmodule