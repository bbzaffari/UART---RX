
vlib work
vcom uart_rx.vhd
vcom uart_rx_tb.vhd
vsim -wlf /sim/uart_rx_tb -voptargs="+acc" -wlfdeleteonquit uart_rx_tb
add wave sim:/uart_rx_tb/*
add wave sim:/uart_rx_tb/uart/*
run 16 ms

