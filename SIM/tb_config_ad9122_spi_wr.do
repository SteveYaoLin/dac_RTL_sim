
#vlib work
#
#
#vlog ../AD9122_SPI.v
#vlog AD9122_SPI_tb.v
#
#
#vsim -c work.AD9122_SPI_tb -do "run -all; quit -f"
#

#if {[file exists work]} {
#    file delete -force work
#}
vlib work
vmap work work
vlog -work work +define+questasim +acc +fullpar ad9122_spi_wr_config_tb.sv ../41727804_RTL/ad9122_spi_wr_config.v ../41727804_RTL/spi_wr_rd_single.v -l vlog.g
vsim -c -l vsim.log +define+questasim -voptargs=+acc -fsmdebug work.ad9122_spi_wr_config_tb

# 1. 在运行 DO 文件后直接进行 2ms 的仿真
run 20ms

# 2. 自动运行 all 子命令，以便将所有信号加入波形图中
add wave -r *