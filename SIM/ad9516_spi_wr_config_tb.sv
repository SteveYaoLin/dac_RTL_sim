`timescale 1ns/1ps
module ad9516_spi_wr_config_tb;
  // signals
  reg clk_in = 0;
  reg rst_n = 0;
  wire o_sclk;
  wire o_sda;
  wire o_cs_n;
  wire o_adk_rst;
  reg datain_valid = 0;
  wire datain_ready;

  // instantiate DUT
  ad9516_spi_wr_config dut (
    .clk_in(clk_in),
    .rst_n(rst_n),
    .o_sclk(o_sclk),
    .o_sda(o_sda),
    .o_cs_n(o_cs_n),
    .o_adk_rst(o_adk_rst),
    .datain_valid(datain_valid),
    .datain_ready(datain_ready)
  );

  // memory to record writes (use 16-bit address space, but we'll store by lower 16 bits index mod 256)
  reg [7:0] mem [0:65535]; // large enough

  // capture shift register (24 bits: info(16) + data(8))
  reg [23:0] shift_reg = 24'd0;
  reg [23:0] assembled = 24'd0;
  reg [23:0] assembled_rev = 24'd0;
  reg [4:0] bit_count = 0; // up to 24

  integer k;

  // clock
  initial begin
    clk_in = 0;
    forever #10 clk_in = ~clk_in; // 50MHz
  end

  // reset and start pulse for datain_valid (2000 ns active after reset)
  initial begin
    rst_n = 0;
    datain_valid = 0;
    #200;
    rst_n = 1;
    #1000;
    datain_valid = 1'b1;
    #2000;
    datain_valid = 1'b0;
  end

  // VCD dump
//   initial begin
//     $dumpfile("ad9516_spi_wr_config_tb.vcd");
//     $dumpvars(0, ad9516_spi_wr_config_tb);
//   end

  // Capture MOSI on rising edge of o_sclk when CS is active low
  always @(posedge o_sclk or negedge rst_n) begin
    if (!rst_n) begin
      shift_reg <= 24'd0;
      bit_count <= 0;
    end else begin
      if (o_cs_n == 1'b0) begin
        // append bit MSB-first stream; append to LSB side then reverse later
        shift_reg <= {shift_reg[22:0], o_sda};
        bit_count <= bit_count + 1;
        if (bit_count == 23) begin
          assembled <= {shift_reg[22:0], o_sda};
          // reverse bit order so assembled_rev[23] is first transmitted bit
          for (k = 0; k < 24; k = k + 1) begin
            assembled_rev[k] = assembled[23-k];
          end
          // extract fields: top 16 bits = info/address, low 8 bits = data
          $display("%0t [TB] SPI frame captured: info=0x%04h data=0x%02h", $time, assembled_rev[23:8], assembled_rev[7:0]);
          // store data into mem at index info (use lower 16 bits)
          mem[assembled_rev[23:8]] <= assembled_rev[7:0];
          // reset for next frame
          bit_count <= 0;
          shift_reg <= 24'd0;
        end
      end else begin
        // CS inactive: clear counters
        bit_count <= 0;
        shift_reg <= 24'd0;
      end
    end
  end

  // End simulation after a generous timeout if not finished
  initial begin
    #40000; // 40 us
    $display("[TB] Timeout - finishing simulation");
    // $finish;
  end

endmodule
