
// file: selectio_tx_selectio_wiz.v
// (c) Copyright 2009 - 2013 Xilinx, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//----------------------------------------------------------------------------
// User entered comments
//----------------------------------------------------------------------------
// None
//----------------------------------------------------------------------------

`timescale 1ps/1ps

module selectio_tx_selectio_wiz
   // width of the data for the system
 #(parameter SYS_W = 16,
   // width of the data for the device
   parameter DEV_W = 32)
 (
  // From the device out to the system
  input  [DEV_W-1:0] data_out_from_device,
  output [SYS_W-1:0] data_out_to_pins_p,
  output [SYS_W-1:0] data_out_to_pins_n,
  output  clk_to_pins_p,
  output  clk_to_pins_n,
  input              clk_in,        // Fast clock input from PLL/MMCM
  input              clk_reset,
  input              io_reset);
  wire clock_enable = 1'b1;
  // Signal declarations
  ////------------------------------
  wire clk_fwd_out;
  // Before the buffer
  wire   [SYS_W-1:0] data_out_to_pins_int;
  // Between the delay and serdes
  wire   [SYS_W-1:0] data_out_to_pins_predelay;
  wire ref_clock_bufg;
  // Create the clock logic
  wire clk_in_int_buf;

  assign clk_in_int_buf = clk_in; // clock coming from MMCM

  // We have multiple bits- step over every bit, instantiating the required elements
  genvar pin_count;
  generate for (pin_count = 0; pin_count < SYS_W; pin_count = pin_count + 1) begin: pins
    // Instantiate the buffers
    ////------------------------------
    // Instantiate a buffer for every bit of the data bus
    OBUFDS obufds_inst
       (.O          (data_out_to_pins_p  [pin_count]),
        .OB         (data_out_to_pins_n  [pin_count]),
        .I          (data_out_to_pins_int[pin_count]));

    // Pass through the delay
    ////-------------------------------
   assign data_out_to_pins_int[pin_count]    = data_out_to_pins_predelay[pin_count];
 
    // Connect the delayed data to the fabric
    ////--------------------------------------
//    // DDR register instantation
//    ODDRE1 #(
//       .IS_C_INVERTED(1'b0),      // Optional inversion for C
//       .IS_D1_INVERTED(1'b0),     // Unsupported, do not use
//       .IS_D2_INVERTED(1'b0),     // Unsupported, do not use
//       .SIM_DEVICE("ULTRASCALE_PLUS"), // Set the device version (ULTRASCALE, ULTRASCALE_PLUS, ULTRASCALE_PLUS_ES1,
//                                  // ULTRASCALE_PLUS_ES2, VERSAL, VERSAL_ES1, VERSAL_ES2)
//       .SRVAL(1'b0)               // Initializes the ODDRE1 Flip-Flops to the specified value (1'b0, 1'b1)
//    )
//    ODDRE1_inst (
//       .Q(data_out_to_pins_predelay[pin_count]),   // 1-bit output: Data output to IOB
//       .C(clk_in_int_buf),   // 1-bit input: High-speed clock input
//       .D1(data_out_from_device[pin_count]), // 1-bit input: Parallel data input 1
//       .D2(data_out_from_device[SYS_W + pin_count]), // 1-bit input: Parallel data input 2
//       .SR(io_reset)  // 1-bit input: Active High Async Reset
//    );
//   end
// 将ODDRE1替换�?7系列兼容的ODDR
ODDR #(
    .DDR_CLK_EDGE("OPPOSITE_EDGE"), // 必须添加的关键参�?
    .INIT(1'b0),                    // 对应SRVAL(1'b0)
    .SRTYPE("ASYNC")                // 异步复位类型
) ODDR_inst (
    .Q(data_out_to_pins_predelay[pin_count]), // 输出保持不变
    .C(clk_in_int_buf),             // 时钟输入
    .CE(1'b1),                      // 新增：时钟使能（常开�?
    .D1(data_out_from_device[pin_count]), // 数据输入1
    .D2(data_out_from_device[SYS_W + pin_count]), // 数据输入2
    .R(io_reset),                   // 复位（高有效�?
    .S(1'b0)                        // 新增：置位（不使用）
);
end
  endgenerate
   // ODDRE1 #(
   //    .IS_C_INVERTED(1'b0),      // Optional inversion for C
   //    .IS_D1_INVERTED(1'b0),     // Unsupported, do not use
   //    .IS_D2_INVERTED(1'b0),     // Unsupported, do not use
   //    .SIM_DEVICE("ULTRASCALE_PLUS"), // Set the device version (ULTRASCALE, ULTRASCALE_PLUS, ULTRASCALE_PLUS_ES1,
   //                               // ULTRASCALE_PLUS_ES2, VERSAL, VERSAL_ES1, VERSAL_ES2)
   //    .SRVAL(1'b0)               // Initializes the ODDRE1 Flip-Flops to the specified value (1'b0, 1'b1)
   // )
   // ODDRE1_inst (
   //    .Q(clk_fwd_out),   // 1-bit output: Data output to IOB
   //    .C(clk_in_int_buf),   // 1-bit input: High-speed clock input
   //    .D1(1'b1), // 1-bit input: Parallel data input 1
   //    .D2(1'b0), // 1-bit input: Parallel data input 2
   //    .SR(io_reset)  // 1-bit input: Active High Async Reset
   // );
   // 使用7系列正确的ODDR原语
ODDR #(
    .DDR_CLK_EDGE("OPPOSITE_EDGE"), // 时钟边沿模式
    .INIT(1'b0),                    // 初始�?
    .SRTYPE("SYNC")                 // 同步复位类型
) ODDR_inst (
    .Q(clk_fwd_out),   // 1-bit output: 输出到IOB
    .C(clk_in_int_buf),// 1-bit input: 高�?�时钟输�?
    .CE(1'b1),         // 1-bit input: 时钟使能（常�?�?
    .D1(1'b1),         // 1-bit input: 上升沿数�?
    .D2(1'b0),         // 1-bit input: 下降沿数�?
    .R(io_reset),      // 1-bit input: 异步复位（高有效�?
    .S(1'b0)           // 1-bit input: 置位（不使用�?
);
// Clock Output Buffer
    OBUFDS  obufds_inst_for_clk
       (.O          (clk_to_pins_p),
        .OB         (clk_to_pins_n),
        .I          (clk_fwd_out));
endmodule
