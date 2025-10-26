`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/23 11:33:45
// Design Name: 
// Module Name: ad9516_spi_wr_config
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

module ad9516_spi_wr_config(
                        input clk_in,
                        input rst_n,
                        
                        output o_sclk,
                        output  o_sda,
                        output  o_cs_n,
                        output  o_adk_rst,
                        input datain_valid,
                        output reg datain_ready,
                        output reg ad9516_conf_finish   // <--- new output: 2-cycle finish pulse at END
                        );      
                        
localparam IDLE  = 8'd0;
localparam START = 8'd1;
localparam WAIT_GAP      = 8'd2;
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
localparam WR_STA_10      = 8'd13 ;
localparam WR_STA_11      = 8'd14 ;
localparam WR_STA_12      = 8'd15 ;
localparam WR_STA_13      = 8'd16 ;
localparam WR_STA_14      = 8'd17 ;
localparam WR_STA_15      = 8'd18 ;
localparam WR_STA_16      = 8'd19 ;
localparam WR_STA_17      = 8'd20 ;
localparam WR_STA_18      = 8'd21 ;
localparam WR_STA_19      = 8'd22 ;
localparam WR_STA_20      = 8'd23 ;
localparam WR_STA_21      = 8'd24 ;
localparam WR_STA_22      = 8'd25 ;
localparam WR_STA_23      = 8'd26 ;
localparam WR_STA_24      = 8'd27 ;
localparam WR_STA_25      = 8'd28 ;
localparam WR_STA_26      = 8'd29 ;
localparam WR_STA_27      = 8'd30 ;
localparam WR_STA_28      = 8'd31 ;
localparam WR_STA_29      = 8'd32 ;
localparam WR_STA_30      = 8'd33 ;
localparam WR_STA_31      = 8'd34 ;
localparam WR_STA_32      = 8'd35 ;
localparam WR_STA_33      = 8'd36 ;
localparam WR_STA_34      = 8'd37 ;
localparam WR_STA_35      = 8'd38 ;
localparam WR_STA_36      = 8'd39 ;
localparam WR_STA_37      = 8'd40 ;
localparam WR_STA_38      = 8'd41 ;
localparam WR_STA_39      = 8'd42 ;
localparam WR_STA_40      = 8'd43 ;
localparam WR_STA_41      = 8'd44 ;
localparam WR_STA_42      = 8'd45 ;
localparam WR_STA_43      = 8'd46 ;
localparam WR_STA_44      = 8'd47 ;
localparam WR_STA_45      = 8'd48 ;
localparam WR_STA_46      = 8'd49 ;
localparam WR_STA_47      = 8'd50 ;
localparam WR_STA_48      = 8'd51 ;
localparam WR_STA_49      = 8'd52 ;
localparam WR_STA_50      = 8'd53 ;
localparam WR_STA_51      = 8'd54 ;
localparam WR_STA_52      = 8'd55 ;
localparam WR_STA_53      = 8'd56 ;
localparam WR_STA_54      = 8'd57 ;
localparam WR_STA_55      = 8'd58 ;
localparam WR_STA_56      = 8'd59 ;
localparam WR_STA_57      = 8'd60 ;
localparam WR_STA_58      = 8'd61 ;
localparam WR_STA_59      = 8'd62 ;
localparam WR_STA_60      = 8'd63 ;
localparam WR_STA_61      = 8'd64 ;
localparam WR_STA_62      = 8'd65 ;
localparam WR_STA_63      = 8'd66 ;
localparam WR_STA_64      = 8'd67 ;
localparam WR_STA_65      = 8'd68 ;
localparam WR_STA_66      = 8'd69 ;
localparam WR_STA_67      = 8'd70 ;
localparam WR_STA_68      = 8'd71 ;
localparam WR_STA_69      = 8'd72 ;
localparam WR_STA_70      = 8'd73 ;
localparam WR_STA_71      = 8'd74 ;
localparam WR_STA_72      = 8'd75 ;
localparam WR_STA_73      = 8'd76 ;
localparam WR_STA_74      = 8'd77 ;
localparam WR_STA_75      = 8'd78 ;
localparam END  = 8'd79; 
                                                 
reg dataout_valid;
reg[7:0] state_cur = 8'd0, state_next = 8'd0;

reg[23:0] r_wr_infodata;
reg [1:0] r_wrrd_mode_sel;
wire dataout_ready;
reg [1:0] finish_cnt; // counter to generate 2-cycle finish pulse

always@ (posedge clk_in) begin
    if(!rst_n)
        state_cur <= IDLE;
    else 
        state_cur <= state_next;    
end
always@ (*) begin
case(state_cur)
        IDLE :     begin if(datain_valid) state_next = START; else state_next = IDLE; end
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
        WR_STA_10 :begin     if(dataout_ready) state_next = WR_STA_11 ; else state_next = WR_STA_10 ; end
        WR_STA_11 :begin     if(dataout_ready) state_next = WR_STA_12 ; else state_next = WR_STA_11 ; end
        WR_STA_12 :begin     if(dataout_ready) state_next = WR_STA_13 ; else state_next = WR_STA_12 ; end
        WR_STA_13 :begin     if(dataout_ready) state_next = WR_STA_14 ; else state_next = WR_STA_13 ; end
        WR_STA_14 :begin     if(dataout_ready) state_next = WR_STA_15 ; else state_next = WR_STA_14 ; end
        WR_STA_15 :begin     if(dataout_ready) state_next = WR_STA_16 ; else state_next = WR_STA_15 ; end 
        WR_STA_16 :begin     if(dataout_ready) state_next = WR_STA_17 ; else state_next = WR_STA_16 ; end
        WR_STA_17 :begin     if(dataout_ready) state_next = WR_STA_18 ; else state_next = WR_STA_17 ; end
        WR_STA_18 :begin     if(dataout_ready) state_next = WR_STA_19 ; else state_next = WR_STA_18 ; end
        WR_STA_19 :begin     if(dataout_ready) state_next = WR_STA_20 ; else state_next = WR_STA_19 ; end
        WR_STA_20 :begin     if(dataout_ready) state_next = WR_STA_21 ; else state_next = WR_STA_20 ; end
        WR_STA_21 :begin     if(dataout_ready) state_next = WR_STA_22 ; else state_next = WR_STA_21 ; end
        WR_STA_22 :begin     if(dataout_ready) state_next = WR_STA_23 ; else state_next = WR_STA_22 ; end
        WR_STA_23 :begin     if(dataout_ready) state_next = WR_STA_24 ; else state_next = WR_STA_23 ; end
        WR_STA_24 :begin     if(dataout_ready) state_next = WR_STA_25 ; else state_next = WR_STA_24 ; end
        WR_STA_25 :begin     if(dataout_ready) state_next = WR_STA_26 ; else state_next = WR_STA_25 ; end
        WR_STA_26 :begin     if(dataout_ready) state_next = WR_STA_27 ; else state_next = WR_STA_26 ; end
        WR_STA_27 :begin     if(dataout_ready) state_next = WR_STA_28 ; else state_next = WR_STA_27 ; end
        WR_STA_28 :begin     if(dataout_ready) state_next = WR_STA_29 ; else state_next = WR_STA_28 ; end
        WR_STA_29 :begin     if(dataout_ready) state_next = WR_STA_30 ; else state_next = WR_STA_29 ; end
        WR_STA_30 :begin     if(dataout_ready) state_next = WR_STA_31 ; else state_next = WR_STA_30 ; end
        WR_STA_31 :begin     if(dataout_ready) state_next = WR_STA_32 ; else state_next = WR_STA_31 ; end
        WR_STA_32 :begin     if(dataout_ready) state_next = WR_STA_33 ; else state_next = WR_STA_32 ; end
        WR_STA_33 :begin     if(dataout_ready) state_next = WR_STA_34 ; else state_next = WR_STA_33 ; end
        WR_STA_34 :begin     if(dataout_ready) state_next = WR_STA_35 ; else state_next = WR_STA_34 ; end
        WR_STA_35 :begin     if(dataout_ready) state_next = WR_STA_36 ; else state_next = WR_STA_35 ; end
        WR_STA_36 :begin     if(dataout_ready) state_next = WR_STA_37 ; else state_next = WR_STA_36 ; end
        WR_STA_37 :begin     if(dataout_ready) state_next = WR_STA_38 ; else state_next = WR_STA_37 ; end
        WR_STA_38 :begin     if(dataout_ready) state_next = WR_STA_39 ; else state_next = WR_STA_38 ; end
        WR_STA_39 :begin     if(dataout_ready) state_next = WR_STA_40 ; else state_next = WR_STA_39 ; end
        WR_STA_40 :begin     if(dataout_ready) state_next = WR_STA_41 ; else state_next = WR_STA_40 ; end
        WR_STA_41 :begin     if(dataout_ready) state_next = WR_STA_42 ; else state_next = WR_STA_41 ; end
        WR_STA_42 :begin     if(dataout_ready) state_next = WR_STA_43 ; else state_next = WR_STA_42 ; end
        WR_STA_43 :begin     if(dataout_ready) state_next = WR_STA_44 ; else state_next = WR_STA_43 ; end
        WR_STA_44 :begin     if(dataout_ready) state_next = WR_STA_45 ; else state_next = WR_STA_44 ; end
        WR_STA_45 :begin     if(dataout_ready) state_next = WR_STA_46 ; else state_next = WR_STA_45 ; end
        WR_STA_46 :begin     if(dataout_ready) state_next = WR_STA_47 ; else state_next = WR_STA_46 ; end
        WR_STA_47 :begin     if(dataout_ready) state_next = WR_STA_48 ; else state_next = WR_STA_47 ; end 
        WR_STA_48 :begin     if(dataout_ready) state_next = WR_STA_49 ; else state_next = WR_STA_48 ; end
        WR_STA_49 :begin     if(dataout_ready) state_next = WR_STA_50 ; else state_next = WR_STA_49 ; end
        WR_STA_50 :begin     if(dataout_ready) state_next = WR_STA_51 ; else state_next = WR_STA_50 ; end
        WR_STA_51 :begin     if(dataout_ready) state_next = WR_STA_52 ; else state_next = WR_STA_51 ; end
        WR_STA_52 :begin     if(dataout_ready) state_next = WR_STA_53 ; else state_next = WR_STA_52 ; end
        WR_STA_53 :begin     if(dataout_ready) state_next = WR_STA_54 ; else state_next = WR_STA_53 ; end
        WR_STA_54 :begin     if(dataout_ready) state_next = WR_STA_55 ; else state_next = WR_STA_54 ; end
        WR_STA_55 :begin     if(dataout_ready) state_next = WR_STA_56 ; else state_next = WR_STA_55 ; end
        WR_STA_56 :begin     if(dataout_ready) state_next = WR_STA_57 ; else state_next = WR_STA_56 ; end
        WR_STA_57 :begin     if(dataout_ready) state_next = WR_STA_58 ; else state_next = WR_STA_57 ; end
        WR_STA_58 :begin     if(dataout_ready) state_next = WR_STA_59 ; else state_next = WR_STA_58 ; end
        WR_STA_59 :begin     if(dataout_ready) state_next = WR_STA_60 ; else state_next = WR_STA_59 ; end
        WR_STA_60 :begin     if(dataout_ready) state_next = WR_STA_61 ; else state_next = WR_STA_60 ; end
        WR_STA_61 :begin     if(dataout_ready) state_next = WR_STA_62 ; else state_next = WR_STA_61 ; end
        WR_STA_62 :begin     if(dataout_ready) state_next = WR_STA_63 ; else state_next = WR_STA_62 ; end
        WR_STA_63 :begin     if(dataout_ready) state_next = WR_STA_64 ; else state_next = WR_STA_63 ; end 
        WR_STA_64 :begin     if(dataout_ready) state_next = WR_STA_65 ; else state_next = WR_STA_64 ; end
        WR_STA_65 :begin     if(dataout_ready) state_next = WR_STA_66 ; else state_next = WR_STA_65 ; end
        WR_STA_66 :begin     if(dataout_ready) state_next = WR_STA_67 ; else state_next = WR_STA_66 ; end
        WR_STA_67 :begin     if(dataout_ready) state_next = WR_STA_68 ; else state_next = WR_STA_67 ; end
        WR_STA_68 :begin     if(dataout_ready) state_next = WR_STA_69 ; else state_next = WR_STA_68 ; end
        WR_STA_69 :begin     if(dataout_ready) state_next = WR_STA_70 ; else state_next = WR_STA_69 ; end
        WR_STA_70 :begin     if(dataout_ready) state_next = WR_STA_71 ; else state_next = WR_STA_70 ; end
        WR_STA_71 :begin     if(dataout_ready) state_next = WR_STA_72 ; else state_next = WR_STA_71 ; end
        WR_STA_72 :begin     if(dataout_ready) state_next = WR_STA_73 ; else state_next = WR_STA_72 ; end
        WR_STA_73 :begin     if(dataout_ready) state_next = WR_STA_74 ; else state_next = WR_STA_73 ; end
        WR_STA_74 :begin     if(dataout_ready) state_next = WR_STA_75 ; else state_next = WR_STA_74 ; end
        WR_STA_75 :begin     if(dataout_ready) state_next = END ; else state_next = WR_STA_75 ; end                                                                   
        END : begin state_next = IDLE; end                           
    endcase
end


// 10M ref clk in
always@ (posedge clk_in) begin
    if(!rst_n) begin
       datain_ready <= 1'b0;
       dataout_valid <= 1'b0;
       r_wrrd_mode_sel <= 2'b0; //select spi_write_mode
       finish_cnt <= 2'd0;
       ad9516_conf_finish <= 1'b0;
    end
    else begin
        case(state_cur)
                IDLE : begin  dataout_valid <= 1'b0; datain_ready <= 1'b1; end
                START : begin dataout_valid <= 1'b1; datain_ready <= 1'b0; end
                WAIT_GAP : begin dataout_valid <= dataout_valid; datain_ready <= datain_ready; end
                WR_STA_0   : begin r_wr_infodata <= {3'b000,13'h0000,8'h18}; end  // 此行至WR_STA_67为ad9516官方上位机生成的寄存器参数，复制粘贴进来8位data部分即可
                WR_STA_1   : begin r_wr_infodata <= {3'b000,13'h0001,8'h00}; end    //
                WR_STA_2   : begin r_wr_infodata <= {3'b000,13'h0002,8'h10}; end
                WR_STA_3   : begin r_wr_infodata <= {3'b000,13'h0003,8'h43}; end
                WR_STA_4   : begin r_wr_infodata <= {3'b000,13'h0004,8'h00}; end
                WR_STA_5   : begin r_wr_infodata <= {3'b000,13'h0010,8'h7C}; end //PLL设置
                WR_STA_6   : begin r_wr_infodata <= {3'b000,13'h0011,8'h02}; end //PLL设置
                WR_STA_7   : begin r_wr_infodata <= {3'b000,13'h0012,8'h00}; end //  
                WR_STA_8   : begin r_wr_infodata <= {3'b000,13'h0013,8'h00}; end
                WR_STA_9   : begin r_wr_infodata <= {3'b000,13'h0014,8'h05}; end
                WR_STA_10  : begin r_wr_infodata <= {3'b000,13'h0015,8'h00}; end
                WR_STA_11  : begin r_wr_infodata <= {3'b000,13'h0016,8'h04}; end //VCO设置
                WR_STA_12  : begin r_wr_infodata <= {3'b000,13'h0017,8'hAC}; end //VCO设置
                WR_STA_13  : begin r_wr_infodata <= {3'b000,13'h0018,8'h07}; end //VCO设置
                WR_STA_14  : begin r_wr_infodata <= {3'b000,13'h0019,8'h40}; end //VCO设置
                WR_STA_15  : begin r_wr_infodata <= {3'b000,13'h001A,8'h00}; end //VCO设置
                WR_STA_16  : begin r_wr_infodata <= {3'b000,13'h001B,8'h01}; end //VCO设置
                WR_STA_17  : begin r_wr_infodata <= {3'b000,13'h001C,8'h07}; end 
                WR_STA_18  : begin r_wr_infodata <= {3'b000,13'h001D,8'h0A}; end
                WR_STA_19  : begin r_wr_infodata <= {3'b000,13'h001E,8'h00}; end
                WR_STA_20  : begin r_wr_infodata <= {3'b000,13'h001F,8'h0E}; end //VCO设置
                WR_STA_21  : begin r_wr_infodata <= {3'b000,13'h00A0,8'h01}; end
                WR_STA_22  : begin r_wr_infodata <= {3'b000,13'h00A1,8'h00}; end
                WR_STA_23  : begin r_wr_infodata <= {3'b000,13'h00A2,8'h00}; end
                WR_STA_24  : begin r_wr_infodata <= {3'b000,13'h00A3,8'h01}; end
                WR_STA_25  : begin r_wr_infodata <= {3'b000,13'h00A4,8'h00}; end
                WR_STA_26  : begin r_wr_infodata <= {3'b000,13'h00A5,8'h00}; end
                WR_STA_27  : begin r_wr_infodata <= {3'b000,13'h00A6,8'h01}; end
                WR_STA_28  : begin r_wr_infodata <= {3'b000,13'h00A7,8'h00}; end
                WR_STA_29  : begin r_wr_infodata <= {3'b000,13'h00A8,8'h00}; end
                WR_STA_30  : begin r_wr_infodata <= {3'b000,13'h00A9,8'h01}; end
                WR_STA_31  : begin r_wr_infodata <= {3'b000,13'h00AA,8'h00}; end
                WR_STA_32  : begin r_wr_infodata <= {3'b000,13'h00AB,8'h00}; end
                WR_STA_33  : begin r_wr_infodata <= {3'b000,13'h00F0,8'h0A}; end
                WR_STA_34  : begin r_wr_infodata <= {3'b000,13'h00F1,8'h0A}; end
                WR_STA_35  : begin r_wr_infodata <= {3'b000,13'h00F2,8'h0A}; end
                WR_STA_36  : begin r_wr_infodata <= {3'b000,13'h00F3,8'h0A}; end
                WR_STA_37  : begin r_wr_infodata <= {3'b000,13'h00F4,8'h0A}; end
                WR_STA_38  : begin r_wr_infodata <= {3'b000,13'h00F5,8'h08}; end
                WR_STA_39  : begin r_wr_infodata <= {3'b000,13'h0140,8'h42}; end
                WR_STA_40  : begin r_wr_infodata <= {3'b000,13'h0141,8'h43}; end
                WR_STA_41  : begin r_wr_infodata <= {3'b000,13'h0142,8'h42}; end
                WR_STA_42  : begin r_wr_infodata <= {3'b000,13'h0143,8'h42}; end
                WR_STA_43  : begin r_wr_infodata <= {3'b000,13'h0190,8'h00}; end
                WR_STA_44  : begin r_wr_infodata <= {3'b000,13'h0191,8'h80}; end
                WR_STA_45  : begin r_wr_infodata <= {3'b000,13'h0192,8'h00}; end
                WR_STA_46  : begin r_wr_infodata <= {3'b000,13'h0193,8'hBB}; end
                WR_STA_47  : begin r_wr_infodata <= {3'b000,13'h0194,8'h00}; end
                WR_STA_48  : begin r_wr_infodata <= {3'b000,13'h0195,8'h00}; end
                WR_STA_49  : begin r_wr_infodata <= {3'b000,13'h0196,8'h11}; end
                // WR_STA_50  : begin r_wr_infodata <= {3'b000,13'h0197,8'h80}; end// Divider 2 = 0
                WR_STA_50  : begin r_wr_infodata <= {3'b000,13'h0197,8'h00}; end // Divider 2 = 0, for 500MHz output
                WR_STA_51  : begin r_wr_infodata <= {3'b000,13'h0198,8'h00}; end
                WR_STA_52  : begin r_wr_infodata <= {3'b000,13'h0199,8'h11}; end
                WR_STA_53  : begin r_wr_infodata <= {3'b000,13'h019A,8'h00}; end
                WR_STA_54  : begin r_wr_infodata <= {3'b000,13'h019B,8'h00}; end
                WR_STA_55  : begin r_wr_infodata <= {3'b000,13'h019C,8'h00}; end
                WR_STA_56  : begin r_wr_infodata <= {3'b000,13'h019D,8'h00}; end
                WR_STA_57  : begin r_wr_infodata <= {3'b000,13'h019E,8'h11}; end
                WR_STA_58  : begin r_wr_infodata <= {3'b000,13'h019F,8'h00}; end
                WR_STA_59  : begin r_wr_infodata <= {3'b000,13'h01A0,8'h00}; end
                WR_STA_60  : begin r_wr_infodata <= {3'b000,13'h01A1,8'h00}; end
                WR_STA_61  : begin r_wr_infodata <= {3'b000,13'h01A2,8'h00}; end
                WR_STA_62  : begin r_wr_infodata <= {3'b000,13'h01A3,8'h00}; end
                WR_STA_63  : begin r_wr_infodata <= {3'b000,13'h01E0,8'h00}; end
                WR_STA_64  : begin r_wr_infodata <= {3'b000,13'h01E1,8'h02}; end
                WR_STA_65  : begin r_wr_infodata <= {3'b000,13'h0230,8'h00}; end
                WR_STA_66  : begin r_wr_infodata <= {3'b000,13'h0231,8'h00}; end
                WR_STA_67  : begin r_wr_infodata <= {3'b000,13'h0232,8'h00}; end //stp last line
                WR_STA_68  : begin r_wr_infodata <= {3'b000,13'h0018,8'h06}; end //此行开始和之后的寄存器必须赋值一次，以进行vco校准，并将SPI数据更新至AD9516芯片内部
                WR_STA_69  : begin r_wr_infodata <= {3'b000,13'h0232,8'h01}; end //Update all registers
                WR_STA_70  : begin r_wr_infodata <= {3'b000,13'h0018,8'h07}; end // 启动vco校准
                WR_STA_71  : begin r_wr_infodata <= {3'b000,13'h0232,8'h01}; end //Update all registers
                WR_STA_72  : begin r_wr_infodata <= {3'b000,13'h0230,8'h01}; end //以下4行进行soft sync，使时钟输出同步
                WR_STA_73  : begin r_wr_infodata <= {3'b000,13'h0232,8'h01}; end //Update all registers
                WR_STA_74  : begin r_wr_infodata <= {3'b000,13'h0230,8'h00}; end //恢复正常工作状态
                WR_STA_75  : begin r_wr_infodata <= {3'b000,13'h0232,8'h01}; end   //Update all registers                                                                           
                END : begin dataout_valid <= 1'b0; datain_ready <= 1'b0; end                       
            endcase
        end
end

// finish pulse generator: when state_cur == END start 2-cycle pulse
always @ (posedge clk_in) begin
    if (!rst_n) begin
        finish_cnt <= 2'd0;
        ad9516_conf_finish <= 1'b0;
    end else begin
        if ((state_cur == END) && (finish_cnt == 2'd0)) begin
            finish_cnt <= 2'd2;
            ad9516_conf_finish <= 1'b1;
        end else if (finish_cnt != 2'd0) begin
            finish_cnt <= finish_cnt - 1;
            if (finish_cnt == 2'd1)
                ad9516_conf_finish <= 1'b0;
        end
    end
end

assign o_adk_rst = 1'b0;

// spi 底层模块，只用到write功能，未使用read
spi_wr_rd_single #(
                    .SPI_INFO_LENGTH (16),
                    .SPI_DATA_LENGTH (8)
                )
           spi_wr_rd_single
               (
                    .clk_in (clk_in),
                    .rst_n (rst_n),
                    .i_wrrd_mode_sel(r_wrrd_mode_sel),
                    .i_wr_infodata(r_wr_infodata),
                    .i_rd_info (),
                    .r_rd_data (),
                    .o_sclk (o_sclk),
                    .i_sda (),
                    .o_sda(o_sda),
                    .o_sda_dir(),
                    .o_cs_n(o_cs_n),
                    .i_delay_cnt(),
                    .datain_valid (dataout_valid),
                    .datain_ready (dataout_ready)
               );

endmodule