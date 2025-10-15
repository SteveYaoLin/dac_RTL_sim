`timescale 1ns/1ps
module ad9122_spi_wr_config_tb;
  // signals
  reg clk_in = 0;
  reg rst_n = 0;
  reg io_sda = 1'bz; // MISO from device
  reg datain_valid = 0;
  wire datain_ready;
  wire o_sclk;
  wire o_sda;
  wire o_sda_dir;
  wire o_sen_n;
  wire o_sda_dir_w; // alias
  wire o_sda_w;
  wire o_sen_n_w;
  wire o_sclk_w;
  reg datain_ready_reg;

  // instantiate DUT
  ad9122_spi_wr_config dut (
    .clk_in(clk_in),
    .rst_n(rst_n),
    .o_sclk(o_sclk),
    .o_sda(o_sda),
    .o_sda_dir(o_sda_dir),
    .o_sen_n(o_sen_n),
    .o_reset(),
    .io_sda(io_sda),
    .datain_valid(datain_valid),
    .datain_ready(datain_ready)
  );

  // local model of device registers for read responses (128 bytes)
  reg [7:0] mem [0:127];

  // capture state
  reg [15:0] shift_reg = 16'd0; // captures MOSI (addr+data)
  integer bit_count = 0;
  reg [6:0] last_addr = 7'd0;

  // drive clock
  initial begin
    clk_in = 0;
    forever #5 clk_in = ~clk_in; // 100MHz
  end

  // reset sequence
  initial begin
    rst_n = 0;
    datain_valid = 0;
    io_sda = 1'bz;
    #200;
    rst_n = 1;
    #20;
    // trigger the configuration sequence: hold datain_valid high for 2000 ns
    datain_valid = 1'b1;
    #2000;
    datain_valid = 1'b0;
  end

  // VCD dump for Questa/GTKWave
//   initial begin
//     $dumpfile("ad9122_spi_wr_config_tb.vcd");
//     $dumpvars(0, ad9122_spi_wr_config_tb);
//   end

  // Capture MOSI (controller -> device) when chip select is asserted low and controller is driving (o_sda_dir==0)
  // Sample on rising edge of o_sclk
  always @(posedge o_sclk or negedge rst_n) begin
    if (!rst_n) begin
      shift_reg <= 16'd0;
      bit_count <= 0;
    end else begin
      if (o_sen_n == 1'b0 && o_sda_dir == 1'b0) begin
        // controller is driving MOSI
        shift_reg <= {shift_reg[14:0], o_sda};
        bit_count <= bit_count + 1;
        if (bit_count == 15) begin
          // full 16-bit word (address+data)
          last_addr <= shift_reg[14:8];
          mem[shift_reg[14:8]] <= shift_reg[7:0];
          $display("%0t [TB] WRITE captured: addr=0x%02h data=0x%02h", $time, shift_reg[14:8], shift_reg[7:0]);
          bit_count <= 0;
          shift_reg <= 16'd0;
        end
      end else begin
        // not driving, clear counters
        bit_count <= 0;
        shift_reg <= 16'd0;
      end
    end
  end

  // Drive io_sda (MISO) during read transactions when controller releases line (o_sda_dir==1)
  // We'll load mem[last_addr] and shift out MSB-first on falling edge of o_sclk so data is stable prior to sampling
  reg [7:0] read_byte = 8'd0;
  integer read_bit_idx = 7;
  reg in_read_phase = 0;

  always @(negedge o_sclk or negedge rst_n) begin
    if (!rst_n) begin
      io_sda <= 1'bz;
      read_byte <= 8'd0;
      read_bit_idx <= 7;
      in_read_phase <= 0;
    end else begin
      if (o_sen_n == 1'b0 && o_sda_dir == 1'b1) begin
        if (!in_read_phase) begin
          // begin of read-data phase: load the last addressed register
          read_byte <= mem[last_addr];
          read_bit_idx <= 7;
          in_read_phase <= 1;
        end
        io_sda <= read_byte[read_bit_idx];
        if (read_bit_idx == 0) read_bit_idx <= 7; else read_bit_idx = read_bit_idx - 1;
      end else begin
        io_sda <= 1'bz;
        in_read_phase <= 0;
      end
    end
  end

  // End simulation when the DUT reaches END state - approximate by waiting some time
  initial begin
    #20000;
    $display("[TB] Timeout - finishing simulation");
    $finish;
  end

endmodule
