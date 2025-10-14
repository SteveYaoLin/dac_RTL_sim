`timescale 1ns/1ps
module AD9122_SPI_tb;
  // clock and reset
  reg clk;
  reg rstn;

  // DUT control signals
  reg [7:0] ad_rw_addr;
  reg [7:0] w_ad_data;
  reg read_req;
  reg write_req;

  wire [7:0] read_data;
  wire r_w_end;
  wire AD_SCLK;
  wire AD_CSB;
  wire AD_SDO;
  wire SDIO_OUT_EN;

  // SDIO input driven by TB (device -> controller)
  reg AD_SDI;
  // test vectors and loop index (declare at top-level, not inside initial blocks)
  reg [6:0] addrs [0:2];
  reg [7:0] datas [0:2];
  integer i;

  // instantiate DUT
  AD9122_SPI dut (
    .clk(clk),
    .rstn(rstn),
    .ad_rw_addr(ad_rw_addr),
    .w_ad_data(w_ad_data),
    .read_req(read_req),
    .write_req(write_req),
    .read_data(read_data),
    .r_w_end(r_w_end),
    .AD_SCLK(AD_SCLK),
    .AD_CSB(AD_CSB),
    .AD_SDI(AD_SDI),
    .AD_SDO(AD_SDO),
    .SDIO_OUT_EN(SDIO_OUT_EN)
  );

  // simple memory to emulate AD9122 registers (7-bit address space)
  reg [7:0] mem [0:127];

  // slave-side shift registers and state
  reg [7:0] shift_in;
  integer bitcnt;
  reg [7:0] addr_byte;
  reg [7:0] assembled;
  reg expecting_read;
  reg [7:0] data_to_send;
  integer send_bit_idx;

  // keep previous CSB to detect edges
  reg prev_csb;

  // clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100MHz
  end

  // reset
  initial begin
    rstn = 0;
    read_req = 0;
    write_req = 0;
    ad_rw_addr = 8'd0;
    w_ad_data = 8'd0;
    AD_SDI = 1'bz; // high-impedance when not driving
    prev_csb = 1'b1;
    bitcnt = 0;
    shift_in = 8'd0;
    expecting_read = 0;
    send_bit_idx = 7;
    #100;
    rstn = 1;
  end

  // monitor AD_CSB and AD_SCLK to implement simple SDIO slave behavior
  always @(posedge AD_SCLK or posedge rstn) begin
    if (!rstn) begin
      shift_in <= 8'd0;
      bitcnt <= 0;
    end else begin
      // only sample bits when controller is driving SDIO (SDIO_OUT_EN==1)
      if (AD_CSB == 1'b0 && SDIO_OUT_EN == 1'b1) begin
        // sample MSB-first as AD_SDO is driven MSB-first by the controller
        shift_in <= {shift_in[6:0], AD_SDO};
        bitcnt = bitcnt + 1;
        if (bitcnt == 8) begin
          // assemble the sampled address byte (avoid indexing a concatenation expression)
          assembled = {shift_in[6:0], AD_SDO};
          addr_byte <= assembled;
          // if MSB==1 it's a read request (address byte)
          if (assembled[7] == 1'b1) begin
            expecting_read <= 1'b1;
            data_to_send <= mem[assembled[6:0]];
            send_bit_idx = 7;
          end else begin
            expecting_read <= 1'b0;
          end
        end
        if (bitcnt == 16) begin
          // second byte is write data
          // assemble byte and write to memory when address MSB==0
          // assembled as MSB-first in shift_in
          // data_byte = shift_in after 8 more bits
          // shift_in currently holds the last 8 sampled bits
          // compute data and write
          // address was captured earlier as addr_byte
          if (addr_byte[7] == 1'b0) begin
            mem[addr_byte[6:0]] <= shift_in;
            $display("[TB] Write captured: addr=0x%02h data=0x%02h at time %0t", addr_byte[6:0], shift_in, $time);
          end
        end
      end
    end
  end

  // Drive AD_SDI during read-data phase. Change AD_SDI on falling edge of AD_SCLK
  always @(negedge AD_SCLK or posedge rstn) begin
    if (!rstn) begin
      AD_SDI <= 1'bz;
    end else begin
      // only drive when controller indicates it is reading data (SDIO_OUT_EN==0)
      if (AD_CSB == 1'b0 && SDIO_OUT_EN == 1'b0 && expecting_read) begin
        // drive next bit (MSB-first)
        AD_SDI <= data_to_send[send_bit_idx];
        send_bit_idx = send_bit_idx - 1;
      end else begin
        // release line when not driving
        AD_SDI <= 1'bz;
      end
    end
  end

  // detect transaction boundaries from AD_CSB
  always @(posedge clk) begin
    prev_csb <= AD_CSB;
    if (prev_csb == 1'b1 && AD_CSB == 1'b0) begin
      // start of transaction
      bitcnt <= 0;
      shift_in <= 8'd0;
      expecting_read <= 0;
      send_bit_idx <= 7;
    end
    if (prev_csb == 1'b0 && AD_CSB == 1'b1) begin
      // end of transaction
      bitcnt <= 0;
      shift_in <= 8'd0;
      expecting_read <= 0;
      AD_SDI <= 1'bz;
    end
  end

  // test sequence: write random data to three addresses, then read back and print
  initial begin
    // wait for reset release
    @(posedge rstn);
    #20;

    // choose three addresses
    addrs[0] = 7'h05;
    addrs[1] = 7'h0A;
    addrs[2] = 7'h10;

    // generate random data
    for (i = 0; i < 3; i = i + 1) begin
      datas[i] = $urandom & 8'hFF;
    end

    // perform write then read for each address
    for (i = 0; i < 3; i = i + 1) begin
      // WRITE: MSB=0
      ad_rw_addr = {1'b0, addrs[i]};
      w_ad_data = datas[i];
      @(posedge clk);
      write_req = 1'b1;
      @(posedge clk);
      write_req = 1'b0;

      // wait for completion
      wait (r_w_end == 1'b1);
      @(posedge clk);

      // READ: MSB=1
      ad_rw_addr = {1'b1, addrs[i]};
      @(posedge clk);
      read_req = 1'b1;
      @(posedge clk);
      read_req = 1'b0;

      // wait for completion
      wait (r_w_end == 1'b1);
      @(posedge clk);

      $display("[TB] Transaction %0d: addr=0x%02h wrote=0x%02h read_back=0x%02h at time %0t", i, addrs[i], datas[i], read_data, $time);
      if (read_data !== datas[i]) begin
        $display("[TB] MISMATCH at addr 0x%02h: expected 0x%02h got 0x%02h", addrs[i], datas[i], read_data);
      end
      #200; // small gap between transactions
    end

    $display("[TB] Test complete at time %0t", $time);
    #100;
    $finish;
  end

endmodule
