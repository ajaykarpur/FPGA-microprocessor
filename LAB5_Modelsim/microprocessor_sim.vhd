library IEEE;
	use IEEE.STD_LOGIC_1164.ALL;
	use IEEE.NUMERIC_STD.ALL;
	use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity microprocessor is
end entity microprocessor;

architecture arch of microprocessor is

	type IM_array is array(0 to 255) of std_logic_vector(15 downto 0);
	type RF_array is array(0 to 15) of std_logic_vector(7 downto 0);

	signal IM: IM_array;
	signal PC: integer range 0 to 255 := 0;
	signal PC_temp: integer range 0 to 255;
	signal PC_return: std_logic;
	signal IR: std_logic_vector(15 downto 0);
	signal opcode: std_logic_vector (3 downto 0);
	signal RA: std_logic_vector(3 downto 0);
	signal RB: std_logic_vector(3 downto 0);
	signal RD: std_logic_vector(3 downto 0);
	signal RF: RF_array;
	signal immediate: std_logic_vector(7 downto 0);
	signal W: std_logic_vector(7 downto 0);
	signal terminate: std_logic;
	signal cycle_count: integer range 0 to 4 := 0;

	signal clock: std_logic := '0';
	signal reset: std_logic;

	begin

		fetch: process(clock, reset)
		begin
			if (reset = '1') then
				IM(0) <= x"1000";
				IM(1) <= x"1005";
				IM(2) <= x"1006";
				IM(3) <= x"1241";
				IM(4) <= x"11B2";
				IM(5) <= x"2123";
				IM(6) <= x"8234";
				IM(7) <= x"9110";
				IM(8) <= x"4475";
				IM(9) <= x"1948";
				IM(10) <= x"15B9";
				IM(11) <= x"3899";
				IM(12) <= x"135A";
				IM(13) <= x"161B";
				IM(14) <= x"2895";
				IM(15) <= x"8AB4";
				IM(16) <= x"48A6";
				IM(17) <= x"3547";
				IM(18 to 255) <= (others => x"0000");
			elsif rising_edge(clock) then
				IR <= IM(PC);
			end if;
		end process fetch;

		decode: process(clock, reset)
		begin
			if (reset = '1') then
				opcode <= "UUUU";
				RA <= "UUUU";
				RB <= "UUUU";
				RD <= "UUUU";
				immediate <= "UUUUUUUU";
			elsif rising_edge(clock) then
				opcode <= IR(15 downto 12);
				RA <= IR(11 downto 8);
				RB <= IR(7 downto 4);
				RD <= IR(3 downto 0);
				immediate <= IR(11 downto 4);
			end if;
		end process decode;

		execute: process(clock, reset)
		begin
			if (reset = '1') then
				W <= x"00";
			elsif rising_edge(clock) then
				case(opcode) is
				
					when "0000" => -- HALT
						terminate <= '1';

					when "0001" => -- LDI
						W <= immediate;

					when "0010" => -- ADD
						W <= RF(conv_integer(RA)) + RF(conv_integer(RB));

					when "0011" => -- SUB
						W <= RF(conv_integer(RA)) - RF(conv_integer(RB));
						
					when "0100" => -- OR
						W <= RF(conv_integer(RA)) OR RF(conv_integer(RB));

					when "1000" => -- XOR
						W <= RF(conv_integer(RA)) XOR RF(conv_integer(RB));

					when "1001" => -- JMP
						W <= immediate;
				
					when others =>
						W <= "UUUUUUUU";
				
				end case;
			end if;
		end process execute;

		store: process(clock, reset)
		begin
			if (reset = '1') then
				RF(0 to 15) <= (others => x"00");
			elsif rising_edge(clock) then
				RF(conv_integer(RD)) <= W;
			end if;
		end process store;

		--simulation processes-------------------------------

		-- generates clock signal
		clock_process: process
		begin
			clock <= not clock;
			wait for 10 ns;
		end process;

		PC_counter: process(clock)
	  	begin
	  		if (reset = '1') then
	  			PC <= 0;
	  			cycle_count <= 0;
	    	elsif (rising_edge(clock)) then
	      		if (cycle_count /= 4) then 
	      			cycle_count <= cycle_count + 1;
	      		else
			    	if (opcode = "1001") then
						PC_temp <= PC;
						PC <= conv_integer(immediate);
						PC_return <= '1';
					elsif (PC_return = '1') then
						PC <= PC_temp + 1;
						PC_return <= '0';
					else
						PC <= PC + 1;
					end if;
		    		cycle_count <= 1;
		    	end if;
			end if;
	  	end process PC_counter;

	  	----------------------------------------------------

end architecture arch;