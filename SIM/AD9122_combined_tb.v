`timescale 1ns/1ps
module AD9122_combined_tb;
  // clock & reset
  reg clk = 0;
  reg rstn = 0;

  // connections between reg_config and SPI
  wire [7:0] ad_rw_addr;
  wire [7:0] w_ad_data;
  wire read_req;
  wire write_req;
  wire config_end;

  // SPI outputs
  wire [7:0] read_data;
  wire r_w_end;
  wire AD_SCLK;
  wire AD_CSB;
  wire AD_SDO;
  wire SDIO_OUT_EN;
  reg AD_SDI = 1'bz; // device drives SDI when SDIO_OUT_EN==0

  // instantiate register sequencer
  AD9122_reg_config regcfg (
    .clk(clk),
    .rstn(rstn),
    .r_w_end(r_w_end),
    .config_end(config_end),
    .ad_rw_addr(ad_rw_addr),
    .w_ad_data(w_ad_data),
    .read_req(read_req),
    .write_req(write_req)
  );

  // instantiate SPI controller
  AD9122_SPI spi (
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

  // simple memory to emulate device registers
  reg [7:0] mem [0:127];

  // transaction capture
  reg [7:0] shiftreg;
  reg [7:0] bitcnt;
  reg [7:0] addr_byte;
  reg [7:0] data_byte;
  reg in_transaction;
  reg last_was_read;
  reg [7:0] assembled; // helper to avoid indexing concatenation expressions

  // clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100MHz
  end

  // reset
  initial begin
    rstn = 0;
    in_transaction = 0;
    bitcnt = 0;
    shiftreg = 8'd0;
    addr_byte = 8'd0;
    data_byte = 8'd0;
    #100;
    rstn = 1;
  end

  // detect transaction start/end via AD_CSB edges
  always @(posedge clk) begin
    if (!rstn) begin
      in_transaction <= 0;
    end else begin
      if (AD_CSB == 1'b0 && !in_transaction) begin
        in_transaction <= 1;
        bitcnt <= 0;
        shiftreg <= 8'd0;
        last_was_read <= 1'b0;
      end else if (AD_CSB == 1'b1 && in_transaction) begin
        // transaction finished; if it was a read, SPI has captured read_data
        if (last_was_read) begin
          $display("[TB] READ  addr=0x%02h -> data=0x%02h", addr_byte[6:0], read_data);
        end else begin
          $display("[TB] WRITE addr=0x%02h <- data=0x%02h", addr_byte[6:0], mem[addr_byte[6:0]]);
        end
        in_transaction <= 0;
      end
    end
  end

  // sample AD_SDO when controller drives (SDIO_OUT_EN==1). Use AD_SCLK rising edge to capture.
  always @(posedge AD_SCLK or negedge rstn) begin
    if (!rstn) begin
      shiftreg <= 8'd0;
      bitcnt <= 0;
      addr_byte <= 8'd0;
      data_byte <= 8'd0;
    end else begin
      if (in_transaction && SDIO_OUT_EN == 1'b1) begin
        // sample MSB-first
        shiftreg <= {shiftreg[6:0], AD_SDO};
        bitcnt <= bitcnt + 1;
        if (bitcnt == 7) begin
          // assemble the sampled byte into a temp reg to avoid indexing a concatenation
          assembled = {shiftreg[6:0], AD_SDO};
          addr_byte <= assembled;
          // remember if this will be a read (MSB==1)
          last_was_read <= (assembled[7] == 1'b1);
        end else if (bitcnt == 15) begin
          assembled = {shiftreg[6:0], AD_SDO};
          data_byte <= assembled;
          // if write transaction (addr MSB==0), write to mem
          if (addr_byte[7] == 1'b0) begin
            mem[addr_byte[6:0]] <= assembled;
          end
        end
      end
    end
  end

  // drive AD_SDI during read-data phase. Use AD_SCLK falling edge to change SDI so it's stable before controller samples.
  reg [7:0] read_out_byte;
  integer read_bit_idx;
  always @(negedge AD_SCLK or negedge rstn) begin
    if (!rstn) begin
      AD_SDI <= 1'bz;
      read_out_byte <= 8'd0;
      read_bit_idx <= 7;
    end else begin
      if (in_transaction && SDIO_OUT_EN == 1'b0) begin
        // controller expects slave to drive read-data. When bitcnt reaches 8, addr has been sampled.
        // Use addr_byte to fetch mem and shift bits out MSB-first
        if (bitcnt >= 8 && bitcnt <= 15) begin
          // load read_out_byte when starting data bits
          if (bitcnt == 8) begin
            read_out_byte <= mem[addr_byte[6:0]];
            read_bit_idx <= 7;
          end
          AD_SDI <= read_out_byte[read_bit_idx];
          if (read_bit_idx == 0)
            read_bit_idx <= 7;
          else
            read_bit_idx <= read_bit_idx - 1;
        end else begin
          AD_SDI <= 1'bz;
        end
      end else begin
        AD_SDI <= 1'bz;
      end
    end
  end

  // stop simulation when config_end asserted and sequencer is done
  always @(posedge clk) begin
    if (rstn && config_end) begin
      #100;
      $display("[TB] Sequencer completed (config_end asserted). Exiting.");
      $finish;
    end
  end

endmodule
