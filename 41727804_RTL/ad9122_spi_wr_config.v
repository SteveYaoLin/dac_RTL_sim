`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/24 17:06:26
// Design Name: 
// Module Name: ad9122_spi_wr_config
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module ad9122_spi_wr_config(
                        input clk_in,
                        input rst_n,
                        
                        output o_sclk,
                        output o_sda,
                        output o_sda_dir,
                        output o_sen_n,
                        output reg o_reset,
                        
                        input io_sda,
                        input datain_valid,
                        output reg datain_ready
                        ); 
localparam IDLE             = 8'd0;
localparam START            = 8'd1;
localparam PRE_REST_H         = 8'd46;
localparam PRE_REST_L         = 8'd47;
localparam WAIT_GAP       = 8'd2;
localparam WR_STA_0       = 8'd3  ;
localparam WR_STA_1       = 8'd4  ;
localparam WR_STA_2       = 8'd5  ;
localparam WR_STA_3       = 8'd6  ;
localparam WR_STA_4       = 8'd7  ;
localparam WR_STA_5       = 8'd8  ;
localparam WR_STA_6       = 8'd9  ;
localparam WR_STA_7       = 8'd10 ;
localparam WR_STA_8       = 8'd11 ;
localparam WR_STA_9       = 8'd12 ;
localparam WR_STA_10       = 8'd13 ;
localparam WR_STA_11       = 8'd14 ;
localparam WR_STA_12       = 8'd15 ;
localparam WR_STA_13       = 8'd16 ;
localparam WR_STA_14       = 8'd17 ;
localparam WR_STA_15       = 8'd18 ;
localparam WR_STA_16       = 8'd19 ;
localparam WR_STA_17       = 8'd20 ;
localparam WR_STA_18       = 8'd21 ;
localparam WR_STA_19       = 8'd22 ;
localparam WR_STA_20       = 8'd23 ;
localparam WR_STA_21       = 8'd24 ;  
localparam WR_STA_22       = 8'd25 ;
localparam WR_STA_23       = 8'd26 ;
localparam WR_STA_24       = 8'd27 ;
localparam WR_STA_25       = 8'd28 ;
localparam WR_STA_26       = 8'd29 ;
localparam WR_STA_27       = 8'd30 ;
localparam WR_STA_28       = 8'd31 ;
localparam WR_STA_29       = 8'd32 ;
localparam WR_STA_30       = 8'd33 ;
localparam WR_STA_31       = 8'd34 ;
localparam WR_STA_32       = 8'd35 ;
localparam WR_STA_33       = 8'd36 ;
localparam WR_STA_34       = 8'd37 ;
localparam WR_STA_35       = 8'd38 ;
localparam WR_STA_36       = 8'd39 ;
localparam WR_STA_37       = 8'd40 ;
localparam WR_STA_38       = 8'd41 ;
localparam WR_STA_39       = 8'd42 ;
localparam WR_STA_40       = 8'd43 ;
localparam WR_STA_41       = 8'd44 ;
localparam END  = 8'd45; 
localparam SPI_WRITE_MODE  = 2'b00;       
localparam SPI_READ_MODE  = 2'b01;    
localparam SPI_DELAY_MODE  = 2'b10;       
    
reg dataout_valid;
reg delay_timer_valid;
reg[7:0] state_cur = 8'd0;
reg[7:0] state_next = 8'd0;

wire dataout_ready;
wire delay_timer_ready;
reg[31:0] rst_delay_cnt;

reg[15:0] r_dac_spi_delay_cnt;
reg[7:0] r_rd_info;
wire[7:0] w_rd_data;
reg[1:0] r_wrrd_mode_sel;
reg[15:0] r_wr_infodata;
wire w_hold_save_read;
wire w_sclk_test;

always@ (posedge clk_in) begin
    if(!rst_n)
        state_cur <= IDLE;
    else 
        state_cur <= state_next;    
end
always@ (*) begin
case(state_cur)
        IDLE :     begin if(datain_valid) state_next = PRE_REST_H; else state_next = IDLE; end
        PRE_REST_H:  begin     if(rst_delay_cnt == 32'd10000) state_next = PRE_REST_L; else state_next = PRE_REST_H; end
        PRE_REST_L:  begin     if(rst_delay_cnt == 32'd30000) state_next = START; else state_next = PRE_REST_L; end
        START :    begin     if(dataout_ready) state_next = WAIT_GAP; else state_next = START;   end
        WAIT_GAP : begin    state_next = WR_STA_0; end               
        WR_STA_0  :begin     if(dataout_ready) state_next = WR_STA_1  ; else state_next = WR_STA_0  ; end
        WR_STA_1  :begin     if(dataout_ready) state_next = WR_STA_2  ; else state_next = WR_STA_1  ; end
        WR_STA_2  :begin     if(dataout_ready) state_next = WR_STA_3  ; else state_next = WR_STA_2  ; end
        WR_STA_3  :begin     if(dataout_ready) state_next = WR_STA_4  ; else state_next = WR_STA_3  ; end
        WR_STA_4  :begin     if(dataout_ready) state_next = WR_STA_5  ; else state_next = WR_STA_4  ; end
        WR_STA_5  :begin     if(dataout_ready) state_next = WR_STA_6  ; else state_next = WR_STA_5  ; end
        WR_STA_6  :begin     if(dataout_ready) state_next = WR_STA_7  ; else state_next = WR_STA_6  ; end
        WR_STA_7  :begin     if(dataout_ready) state_next = WR_STA_8  ; else state_next = WR_STA_7  ; end
        WR_STA_8  :begin     if(dataout_ready) state_next = WR_STA_9  ; else state_next = WR_STA_8  ; end
        WR_STA_9  :begin     if(dataout_ready) state_next = WR_STA_10 ; else state_next = WR_STA_9  ; end
        WR_STA_10  :begin     if(dataout_ready) state_next = WR_STA_11 ; else state_next = WR_STA_10  ; end
        WR_STA_11  :begin     if(dataout_ready) state_next = WR_STA_12 ; else state_next = WR_STA_11  ; end
        WR_STA_12  :begin     if(dataout_ready) state_next = WR_STA_13 ; else state_next = WR_STA_12 ;  end
        WR_STA_13  :begin     if(dataout_ready) state_next = WR_STA_14 ; else state_next = WR_STA_13 ;  end
        WR_STA_14  :begin     if(dataout_ready) state_next = WR_STA_15 ; else state_next = WR_STA_14  ; end
        WR_STA_15  :begin     if(dataout_ready) state_next = WR_STA_16 ; else state_next = WR_STA_15  ; end
        WR_STA_16  :begin     if(dataout_ready) state_next = WR_STA_17 ; else state_next = WR_STA_16  ; end        
        WR_STA_17  :begin     if(dataout_ready) state_next = WR_STA_18 ; else state_next = WR_STA_17  ; end        
        WR_STA_18  :begin     if(dataout_ready) state_next = WR_STA_19 ; else state_next = WR_STA_18  ; end        
        WR_STA_19  :begin     if(dataout_ready) state_next = WR_STA_20 ; else state_next = WR_STA_19  ; end  
        WR_STA_20  :begin     if(dataout_ready) state_next = WR_STA_21 ; else state_next = WR_STA_20  ; end        
        WR_STA_21  :begin     if(dataout_ready) state_next = WR_STA_31 ; else state_next = WR_STA_21  ; end     
        
        WR_STA_31  :begin     if(dataout_ready) state_next = WR_STA_32 ; else state_next = WR_STA_31  ; end
        WR_STA_32  :begin     if(dataout_ready) state_next = WR_STA_33 ; else state_next = WR_STA_32  ; end     
        WR_STA_33  :begin     if(dataout_ready) state_next = WR_STA_34 ; else state_next = WR_STA_33  ; end     
        WR_STA_34  :begin     if(dataout_ready) state_next = WR_STA_22 ; else state_next = WR_STA_34  ; end        
        
        WR_STA_22  :begin     if(dataout_ready) state_next = WR_STA_23 ; else state_next = WR_STA_22 ;  end        
        WR_STA_23  :begin     if(dataout_ready) state_next = WR_STA_24 ; else state_next = WR_STA_23 ;  end  
        WR_STA_24  :begin     if(dataout_ready) state_next = WR_STA_25 ; else state_next = WR_STA_24 ;  end  
        WR_STA_25  :begin     if(dataout_ready) state_next = WR_STA_26 ; else state_next = WR_STA_25 ;  end    
        WR_STA_26  :begin     if(dataout_ready) 
                                if(w_rd_data == 7'h07)
                                    state_next = WR_STA_27;
                                else
                                    state_next = WR_STA_26;
                              else      
                                 state_next = WR_STA_26  ; end       
        WR_STA_27  :begin     if(dataout_ready) state_next = WR_STA_28 ; else state_next = WR_STA_27  ; end        
        WR_STA_28  :begin     if(dataout_ready) 
                                if(w_rd_data == 7'h0F || w_rd_data == 7'h07)
                                    state_next = END;
                                else if(w_rd_data == 7'h03)
                                    state_next = WR_STA_29;
                                else if(w_rd_data == 7'h1F)  
                                    state_next = WR_STA_30;  
                              else      
                                 state_next = WR_STA_28  ; end  
        WR_STA_29  :begin     if(dataout_ready) state_next = WR_STA_24 ; else state_next = WR_STA_29 ;  end
        WR_STA_30  :begin     if(dataout_ready) state_next = WR_STA_24 ; else state_next = WR_STA_30 ;  end                                                                                                 
        END : begin state_next = IDLE; end                           
    endcase
end

always@ (posedge clk_in) begin
    if(!rst_n) begin
       datain_ready <= 1'b0;
       dataout_valid <= 1'b0;
       rst_delay_cnt <= 10'd0;
       o_reset <= 1'b0;
       r_wrrd_mode_sel <= 2'b0;//select spi_write_mode
       delay_timer_valid <= 1'b0;
    end
    else begin
        case(state_cur)
                IDLE : begin  dataout_valid <= 1'b0; datain_ready <= 1'b1; rst_delay_cnt <= 10'd0; o_reset <= 1'b0; delay_timer_valid <= 1'b0;end
                PRE_REST_H: begin o_reset <= 1'b1; rst_delay_cnt <= rst_delay_cnt + 1'd1; end
                PRE_REST_L: begin o_reset <= 1'b0; rst_delay_cnt <= rst_delay_cnt + 1'd1; end
                START : begin dataout_valid <= 1'b1; datain_ready <= 1'b0; end
                WAIT_GAP : begin dataout_valid <= dataout_valid; datain_ready <= datain_ready; end                
                    //For spi write: bit15 , bit14~8 : address , bit7~0 : reg data   
                WR_STA_0   : begin r_wr_infodata <= {1'h0,7'h00,8'hA0};   r_wrrd_mode_sel <= SPI_WRITE_MODE;  end  // sdio bidirect           
                WR_STA_1   : begin r_wr_infodata <= {1'h0,7'h00,8'h80}; end  //  soft reset
                WR_STA_2   : begin r_wr_infodata <= {1'h0,7'h03,8'h00}; end  //  complet-binary , word mode                 
                WR_STA_3   : begin r_wr_infodata <= {1'h0,7'h04,8'h00}; end  //  disable any interrupt           
                WR_STA_4   : begin r_wr_infodata <= {1'h0,7'h05,8'h00}; end  //  disable any interrupt        
                WR_STA_5  :  begin r_wr_infodata <= {1'h0,7'h08,8'hA0}; end  //  enable DACCLK input correct
                WR_STA_6  :  begin r_wr_infodata <= {1'h0,7'h0A,8'h00}; end  //  disable PLL
                WR_STA_7  :  begin r_wr_infodata <= {1'h0,7'h0C,8'h00}; end  //  PLL bandwith select, CP-current select
                WR_STA_8   : begin r_wr_infodata <= {1'h0,7'h0D,8'h00}; end  //  PLL control parameter
                WR_STA_9   : begin r_wr_infodata <= {1'h0,7'h10,8'h00}; end  // Sync disable
                WR_STA_10  : begin r_wr_infodata <= {1'h0,7'h11,8'h00}; end  // Sync disable
                WR_STA_11  : begin r_wr_infodata <= {1'h0,7'h16,8'h02}; end  // DCI Delay mode = 0B'10
                WR_STA_12  : begin r_wr_infodata <= {1'h0,7'h1B,8'hA4}; end  // Bypass premodule and NCO, Don't send I data to Q data
                WR_STA_13  : begin r_wr_infodata <= {1'h0,7'h1C,8'h00}; end  // HB1 select, enable interplot *2  mode = 00
                WR_STA_14  : begin r_wr_infodata <= {1'h0,7'h1D,8'h00}; end  // HB2 select, enable interplot *2  mode = 000000
                WR_STA_15  : begin r_wr_infodata <= {1'h0,7'h1E,8'h01}; end  // bypass HB3
                WR_STA_16  : begin r_wr_infodata <= {1'h0,7'h30,8'h00}; end  // NCO value FTW LSB 
                WR_STA_17  : begin r_wr_infodata <= {1'h0,7'h31,8'h00}; end  // NCO value FTW 
                WR_STA_18  : begin r_wr_infodata <= {1'h0,7'h32,8'h00}; end  // NCO value FTW 
                WR_STA_19  : begin r_wr_infodata <= {1'h0,7'h33,8'h00}; end  // NCO value FTW  MSB
                WR_STA_20  : begin r_wr_infodata <= {1'h0,7'h36,8'h01}; end  //  update NCO
                WR_STA_21  : begin r_wr_infodata <= {1'h0,7'h36,8'h00}; end  // 
                
                WR_STA_31  : begin  r_wr_infodata <= {1'h0,7'h40,8'hFF}; end
                WR_STA_32  : begin  r_wr_infodata <= {1'h0,7'h41,8'h03}; end
                WR_STA_33  : begin  r_wr_infodata <= {1'h0,7'h44,8'hFF}; end
                WR_STA_34  : begin  r_wr_infodata <= {1'h0,7'h45,8'h03}; end
                
                WR_STA_22  : begin r_wr_infodata <= {1'h0,7'h10,8'h48}; end  //  setup sync data rate
                WR_STA_23  : begin r_wr_infodata <= {1'h0,7'h17,8'h05}; end  //  FIFO write pointer phase offset following FIFO reset.
                WR_STA_24  : begin r_wr_infodata <= {1'h0,7'h18,8'h02}; end  // FIFO soft align acknowledge
                WR_STA_25 : begin  r_dac_spi_delay_cnt <= 16'd4;   r_wrrd_mode_sel <= SPI_DELAY_MODE;  end  // Delay for wait
                WR_STA_26 : begin r_rd_info <= {1'b1,7'h18};     r_wrrd_mode_sel <= SPI_READ_MODE;   end  //  Read address-0x18 reg
                WR_STA_27  : begin r_wr_infodata <= {1'h0,7'h18,8'h00}; r_wrrd_mode_sel <= SPI_WRITE_MODE;  end  // 
                WR_STA_28  : begin  r_rd_info <= {1'b1,7'h19}; r_wrrd_mode_sel <= SPI_READ_MODE; end  //  Read address-0x19 reg
                WR_STA_29  : begin r_wr_infodata <= {1'h0,7'h17,8'h06}; r_wrrd_mode_sel <= SPI_WRITE_MODE; end
                WR_STA_30  : begin r_wr_infodata <= {1'h0,7'h17,8'h04}; r_wrrd_mode_sel <= SPI_WRITE_MODE; end
                END : begin dataout_valid <= 1'b0; datain_ready <= 1'b0; rst_delay_cnt <= 10'd0; r_wrrd_mode_sel <= SPI_WRITE_MODE;end                       
            endcase                                                   
        end
end  
// spi µ×²ãÄ£¿é
spi_wr_rd_single #(
                    .SPI_INFO_LENGTH (8),
                    .SPI_DATA_LENGTH (8)
                )
           spi_wr_rd_single
               (
                    .clk_in (clk_in),
                    .rst_n (rst_n),
                    .i_wrrd_mode_sel(r_wrrd_mode_sel),
                    .i_wr_infodata(r_wr_infodata),
                    .i_rd_info (r_rd_info),
                    .r_rd_data (w_rd_data),
                    .o_sclk (o_sclk),
                    .i_sda (io_sda),
                    .o_sda(o_sda),
                    .o_sda_dir(o_sda_dir),
                    .o_cs_n(o_sen_n),
                    .i_delay_cnt(r_dac_spi_delay_cnt),
                    .datain_valid (dataout_valid),
                    .datain_ready (dataout_ready),
                    .r_sclk(w_sclk_test),
                    .hold_save_read(w_hold_save_read)
               );
//ila_0 myila_lmk_spi_inst (
//	.clk(clk_in), // input wire clk
	
//	.probe0(o_sclk), // input wire [0:0]  probe0  
//	.probe1(o_sen_n), // input wire [0:0]  probe1 
//	.probe2(io_sda), // input wire [0:0]  probe2 
//	.probe3(o_sda_dir), // input wire [0:0]  probe3 
//	.probe4(state_cur), // input wire [7:0]  probe4
//	.probe5(w_rd_data), // input wire [7:0]  probe5
//	.probe6(w_sclk_test), // input wire [0:0]  probe6
//	.probe7(w_hold_save_read) // input wire [0:0]  probe7 
	
//	);// input wire [7:0]  probe5               
endmodule