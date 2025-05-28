
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx is
  port (
    clock_in        : in  std_logic;
    reset_in        : in  std_logic;
    uart_data_rx    : in  std_logic;
    uart_rate_rx_sel: in  std_logic_vector(1 downto 0);
    data_p_out      : out std_logic_vector(7 downto 0);
    data_p_en_out   : out std_logic
  );
end uart_rx;

architecture rtl of uart_rx is

  -- Estados da máquina de estados
  type states is (IDLE, START, RECEIVE, STOP, DONE);
  signal state  : states := IDLE;
  signal bit_index    : integer range 0 to 7 := 0;
  signal shift_reg    : std_logic_vector(0 to 7) := (others => '0');
  signal counter      : integer range 0 to 10416 := 0;  -- 14 bits cobrem até 16383
  signal counter_half      : integer range 0 to 10416 := 0;  -- 14 bits cobrem até 16383
  signal baud_divisor : integer range 0 to 10416 := 0;
  signal tick         : std_logic:= '0';
  signal tick_half    : std_logic:= '0';
  signal tick_half2   : std_logic:= '0';
  
begin
  --------------------------------------------------------------------------------------------
  ----------------------------- Instância do gerador de baud rate-----------------------------
  --------------------------------------------------------------------------------------------
    baud_divisor <= 1040 when uart_rate_rx_sel = "00"else -- (int)10416/(int)10(ns) = 1041
					520 when uart_rate_rx_sel = "01" else -- (int)5208/(int)10(ns) = 520
					346 when uart_rate_rx_sel = "10" else -- (int)3472/(int)10(ns) = 347
					172 when uart_rate_rx_sel = "11" else -- (int)1736/(int)10(ns) = 173
					1040;-- (int)10416/(int)10(ns) = 1041 + 1 = 1042
					
  --------------------------------------------------------------------------------------------
  ------------------------------ FSM principal da recepção UART ------------------------------
  --------------------------------------------------------------------------------------------
 process(clock_in)
	begin
	  if rising_edge(clock_in) then
		if reset_in = '1' then
		  state         <= IDLE;
		  bit_index     <= 0;
		  shift_reg     <= (others => '0');
		  data_p_out    <= (others => '0');
		  data_p_en_out <= '0';
		  -----------------------------
		  counter    <= 0;
		  tick       <= '0';
		  tick_half  <= '0';
		  -----------------------------
		else
		  data_p_en_out <= '0';  -- padrão: sem dado novo
		  -----------------------------
		  tick      <= '0';
		  -----------------------------
		  ------------------------------------------------------
		  case state is
		    ----------<<<<<<<<<<<<< IDLE >>>>>>>>>>>>>----------
			when IDLE =>
			  if uart_data_rx = '0' then
				state   <= START;
			  end if;
            ----------<<<<<<<<<<<<< START >>>>>>>>>>>>>---------- 				
			when START =>
			  -----------------------------
			  if counter_half = (baud_divisor/2) then
					tick_half <= '1';
					counter_half <= 0;
			  else
				counter_half <= counter_half + 1;
				if tick_half = '1' then 
					counter <= counter + 1;  
				end if;
			  end if;
			  if counter = (baud_divisor/2) then 
					tick_half2 <= '1';
			  end if;
			  -----------------------------
			  if tick_half2 = '1' then
				if uart_data_rx = '0' then
				  state     <= RECEIVE;
				  bit_index <= 0;
				  tick_half <= '0';
				  tick_half2 <= '0';
				  
				else
				  state <= IDLE;  -- ruído
				end if;
			  end if;
			  -----------------------------
			----------<<<<<<<<<<<<< RECEIVE >>>>>>>>>>>>>----------
			when RECEIVE =>
			  if counter = baud_divisor then
				tick    <= '1';
				counter <= 0;
			  else
				counter <= counter + 1;
			  end if;
			  -----------------------------
			  if tick = '1' then
				shift_reg(bit_index) <= uart_data_rx;
				if bit_index = 7 then
				  state <= STOP;
				else
				  bit_index <= bit_index + 1;
				end if;
			  end if;
			-----------<<<<<<<<<<<<< STOP >>>>>>>>>>>>>-----------
			when STOP =>
			  if counter = baud_divisor then
				tick    <= '1';
				counter <= 0;
			  else
				counter <= counter + 1;
			  end if;
			  -----------------------------
			  if tick = '1' then
				if uart_data_rx = '1' then
				  state <= DONE;
				else
				  state <= IDLE;  -- erro de stop bit
				end if;
			  end if;
			-----------<<<<<<<<<<<<< DONE >>>>>>>>>>>>>-----------
			when DONE =>
			  data_p_out    <= shift_reg;
			  data_p_en_out <= '1';
			  state         <= IDLE;
			  -----------------------------
			  counter <= 0;
			  counter_half <= 0;
		  end case;
		  -----------------------------------------------------------
		end if;
	  end if;
	end process;

end rtl;