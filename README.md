# UART Receiver Module (VHDL)

This project implements a UART receiver in VHDL, developed during the Integrated Systems Design II course at PUCRS.

The module, named `uart_rx`, was designed to receive serial data using the UART protocol, handle 8-bit parallel output, and allow configurable baud rates (9600, 19200, 28800, 57600 bps). It uses a finite state machine (FSM) to manage the reception process, including start, data, parity, and stop bits.

### Main points

- Input clock: 100 MHz
- Baud rate selector: 2-bit input (`uart_rate_rx_sel`)
- Parallel output: 8 bits (`data_p_out`) with enable signal (`data_p_en_out`)
- Serial input: `uart_data_rx`
- Synchronous reset (`reset_in`)

### Tools used

- ModelSim (simulation)
- Cadence Genus (synthesis, timing, area, and power analysis)

### Additional notes

Constraints were carefully set for synthesis, and I experimented with different synthesis efforts (low and high) to compare the impact on timing and area. Reports generated during the process helped to analyze and validate the design.

This project was mainly focused on applying theoretical knowledge in practice, testing protocol implementation, and learning synthesis tool workflows.

