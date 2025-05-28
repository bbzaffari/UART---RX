
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx_tb is
    generic(
        baud_rate : std_logic_vector (1 downto 0) := "00"
    );
end uart_rx_tb;

architecture tb of uart_rx_tb is
    signal reset_in_tb         : std_logic := '0';
    signal clock_in_tb         : std_logic := '0';
    signal uart_data_rx_tb     : std_logic := '1';
    signal uart_rate_rx_sel_tb : std_logic_vector(1 downto 0) := baud_rate;
    signal data_p_out_tb       : std_logic_vector(7 downto 0);
    signal data_p_en_out_tb    : std_logic;
    signal data_received       : std_logic_vector(7 downto 0);

    type data_array is array (7 downto 0) of std_logic_vector(0 to 7);
	
    signal data : data_array := (
        0 => "10110101", -- B5
        1 => "01001111", -- 9F
        2 => "11010001", -- D1
        3 => "00111100", -- 3C
        4 => "10001110", -- 8E
        5 => "11111000", -- F8
        6 => "01100110", -- 66
        7 => "10000101"  -- 85
    );
	signal Tbit : time := 10416 ns;
	
begin

    -- Clock gerado com base no clk_period
    clock_in_tb <= not clock_in_tb after 5 ns;
	--------------------------------------------------------------
    data_received <= data_p_out_tb when data_p_en_out_tb = '1';
	
	uart_rate_rx_sel_tb <= baud_rate;
	
	Tbit<= 10416 ns when baud_rate = "00" else-- 9600 bps
			5208 ns when baud_rate = "01" else -- 19200 bps
			3472 ns when baud_rate = "10" else -- 28800 bps
			1736 ns when baud_rate = "11" else -- 57600 bps
			10416 ns;
		
	uart: entity work.uart_rx
    PORT MAP(
        clock_in => clock_in_tb,
        reset_in => reset_in_tb,
        uart_data_rx => uart_data_rx_tb,
        uart_rate_rx_sel => uart_rate_rx_sel_tb,
        data_p_out => data_p_out_tb,
        data_p_en_out => data_p_en_out_tb
    );

    stim_proc: process
    begin
        -- Reset
        reset_in_tb <= '1';
        wait for 100 ns;
        reset_in_tb <= '0';
        wait for 100 ns;

        -- Loop de transmissão UART
        for i in 0 to 7 loop -- data list
			--- Start bit
			uart_data_rx_tb <= '0';
			wait for Tbit;
			----------------------------------------------------------------------------
            for j in 0 to 7 loop
				uart_data_rx_tb <= data(i)(j);
				wait for Tbit;
			end loop;
			--- Stop bit
			uart_data_rx_tb <= '1';
			
			-- Espera ativa até DUT sinalizar que o dado foi recebido
			wait until data_p_en_out_tb = '1';
			wait for Tbit;
			-- Aqui, opcionalmente, imprimir o que foi recebido
			report "Byte recebido: " & integer'image(to_integer(unsigned(data_p_out_tb)));
			
			assert data_p_out_tb = data(i)(0 to 7)
				report "ERRO: byte recebido incorreto!" severity error;
            -- Aguarda um pouco após o stop bit
            uart_data_rx_tb <= '1';
            wait for Tbit * 2;
        end loop;

        wait; -- fim da simulação
    end process;

end tb;
