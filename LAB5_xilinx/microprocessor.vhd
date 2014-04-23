library IEEE;
	use IEEE.STD_LOGIC_1164.ALL;
	use IEEE.NUMERIC_STD.ALL;
	use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity microprocessor is
	-- port
	-- (
	-- 	clock: in std_logic
	-- );
end entity microprocessor;

architecture arch of microprocessor is

	type IM_array is array(0 to 255) of std_logic_vector(15 downto 0);
	type RF_array is array(0 to 15) of std_logic_vector(7 downto 0);

	signal IM: IM_array;
	signal PC: integer range 0 to 255 := 0;
	signal IR: std_logic_vector(15 downto 0);
	signal opcode: std_logic_vector (3 downto 0);
	signal RA: std_logic_vector(3 downto 0);
	signal RB: std_logic_vector(3 downto 0);
	signal RD: std_logic_vector(3 downto 0);
	signal RF: RF_array;
	signal immediate: std_logic_vector(7 downto 0);
	signal W: std_logic_vector(7 downto 0);
	signal terminate: std_logic;

	signal clock: std_logic := '0';

	begin

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
		IM(18) <= x"0000";
		-- IM(18 to 255) <= x"0000";

		fetch: process(clock)
		begin
			IR <= IM(PC);
		end process fetch;

		decode: process(clock)
		begin
			opcode <= IR(15 downto 12);
			RA <= IR(11 downto 8);
			RB <= IR(7 downto 4);
			RD <= IR(3 downto 0);
			immediate <= IR(11 downto 4);

			PC <= PC + 1;

		end process decode;

		execute: process(clock)
		begin

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
			
		end process execute;

		store: process(clock)
		begin
			RF(conv_integer(RD)) <= W;
		end process store;

		-- generates clock signal
		clock_process: process
		begin
			clock <= not clock;
			wait for 10 ns;
		end process;

-- --"debounce" process: Takes the input of the slower clock and ensures that only one 
-- --clock is running at a time when the button is pushed. This debounced clock is then
-- --sent to the FSM as the actual clock for sequential logic. Taken directly from the
-- --provided debounce.vhd file on blackboard, modified to allow an LED light to flash for
-- --0.5s while the clock turns on.
-- 		debounce: process(slow_clock)
-- 	  	begin
-- 	    	if button = '1' then
-- 	      		deb_count <= "00";
-- 	    	elsif (rising_edge(slow_clock)) then
-- 	      		if (deb_count /= "11") then 
-- 	      			deb_count <= deb_count + 1; 
-- 	      		end if;
-- 	    	end if;
-- 	    	if (deb_count = "10") and (button = '0') then 
-- 	    		pulse <= slow_clock;  
-- 	    		else pulse <= '0';
-- 			end if;
-- 	  	end process debounce;
-- --------------------------------------------------

-- --"char_process" Determines which characters are sent to the output according
-- --to the current state
-- 	char_process: process(P_S)
-- 	begin
-- 		case P_S is
		
-- 			when P00 =>
-- 				char1 <= P;
-- 				char2 <= dash;
-- 				char3 <= 0;
-- 				char4 <= 0;

-- 			when A1G =>
-- 				char1 <= A;
-- 				char2 <= dash;
-- 				char3 <= 1;
-- 				char4 <= G;

-- 			when B2H =>
-- 				char1 <= B;
-- 				char2 <= dash;
-- 				char3 <= 2;
-- 				char4 <= H;

-- 			when C3I =>
-- 				char1 <= C;
-- 				char2 <= dash;
-- 				char3 <= 3;
-- 				char4 <= I;

-- 			when D4J =>
-- 				char1 <= D;
-- 				char2 <= dash;
-- 				char3 <= 4;
-- 				char4 <= J;

-- 			when E5K =>
-- 				char1 <= E;
-- 				char2 <= dash;
-- 				char3 <= 5;
-- 				char4 <= K;
		
-- 			when others =>
-- 				char1 <= P;
-- 				char2 <= dash;
-- 				char3 <= 0;
-- 				char4 <= 0;
		
-- 		end case;
-- 	end process char_process;

-- --Determines the actual 8-bit vector that gets sent to the cathode to be displayed on 
-- --the 7-segment display.
-- 	with char1 select
-- 		seg1 <= "00010001" when A,
-- 			    "00000001" when B,
-- 			    "01100011" when C,
-- 			    "10000101" when D,
-- 			    "01100001" when E,
-- 			    "00110001" when P,
-- 			    "11111111" when others;

-- 	with char2 select
-- 		seg2 <= "11111101" when dash,
-- 			    "11111111" when others;

-- 	with char3 select
-- 		seg3 <= "00000011" when 0,
-- 			    "10011111" when 1,
-- 			    "00100101" when 2,
-- 			    "00001101" when 3,
-- 			    "10011001" when 4,
-- 			    "01001001" when 5,
-- 			    "11111111" when others;

-- 	with char4 select
-- 		seg4 <= "00000011" when 0,
-- 			    "01000001" when G,
-- 			    "11010001" when H,
-- 			    "11110011" when I,
-- 			    "10001111" when J,
-- 			    "10010001" when K,
-- 			    "11111111" when others;

-- --------------------------------------------------

-- --"displaying" process: establishes a counter that will cycle through each of the anodes
-- --as to allow each character to be displayed one by one since they cannot all be sent
-- --to their corresponding anode at the same time
-- 	displaying: process(seg1, seg2, seg3, seg4)
-- 	begin
-- 		if (rising_edge(pulse)) then
-- 			if (displaycounter == "11") then
-- 			displaycounter <= "00";
-- 			else
-- 			displaycounter <= displaycounter + 1;
-- 			end if;
-- 		end if;
-- 		case(displaycounter) is
		
-- 			when "00" 	=> 	
-- 				Y 		<= seg1;
-- 				anode 	<= "0111"
-- 			when "01" 	=>	
-- 				Y 		<= seg2;
-- 				anode 	<= "1011";
-- 			when "10" 	=> 	
-- 				Y 		<= seg3;
-- 				anode 	<= "1101";
-- 			when "11" 	=> 	
-- 				Y 		<= seg4;
-- 				anode 	<= "1110";
-- 			when others =>	
-- 				Y 		<= "11111111";
-- 				anode 	<= "1111";
-- 		end case ;
		
-- 	end process displaying;



end architecture arch;