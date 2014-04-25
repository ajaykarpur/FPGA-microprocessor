library IEEE;
	use IEEE.STD_LOGIC_1164.ALL;
	use IEEE.NUMERIC_STD.ALL;
	use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity microprocessor is
	-- port
	-- (
	-- 	clock, reset: in std_logic
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
	signal cycle_count: integer range 0 to 4 := 0;

	signal deb_count: integer range 0 to 4;
	signal pulse: std_logic;
	signal button: std_logic;

	signal char1: std_logic_vector(3 downto 0);
	signal char2: std_logic_vector(3 downto 0);
	signal char3: std_logic_vector(3 downto 0);
	signal char4: std_logic_vector(3 downto 0);
	signal seg1: std_logic_vector(7 downto 0);
	signal seg2: std_logic_vector(7 downto 0);
	signal seg3: std_logic_vector(7 downto 0);
	signal seg4: std_logic_vector(7 downto 0);
	signal Y: std_logic_vector(7 downto 0);
	signal anode: std_logic_vector(3 downto 0);
	signal displaycounter: integer range 0 to 3;

	signal clock: std_logic := '0';
	signal reset: std_logic;

	signal PC_vector: std_logic_vector(15 downto 0);

	begin

		PC_vector <= std_logic_vector(to_unsigned(PC, 16));

		fetch: process(pulse, reset)
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
			elsif rising_edge(pulse) then
				IR <= IM(PC);
			end if;
		end process fetch;

		decode: process(pulse, reset)
		begin
			if (reset = '1') then
				opcode <= "UUUU";
				RA <= "UUUU";
				RB <= "UUUU";
				RD <= "UUUU";
				immediate <= "UUUUUUUU";
			elsif rising_edge(pulse) then
				opcode <= IR(15 downto 12);
				RA <= IR(11 downto 8);
				RB <= IR(7 downto 4);
				RD <= IR(3 downto 0);
				immediate <= IR(11 downto 4);
			end if;
		end process decode;

		execute: process(pulse, reset)
		begin
			if (reset = '1') then
				W <= x"00";
			elsif rising_edge(pulse) then
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

		store: process(pulse, reset)
		begin
			if (reset = '1') then
				RF(0 to 15) <= (others => x"00");
			elsif rising_edge(pulse) then
				RF(conv_integer(RD)) <= W;
			end if;
		end process store;

		-- generates clock signal
		clock_process: process
		begin
			clock <= not clock;
			wait for 10 ns;
		end process;

	PC_counter: process(pulse)
	  	begin
	  		if (reset = '1') then
	  			PC <= 0;
	  			cycle_count <= 0;
	    	elsif (rising_edge(pulse)) then
	      		if (cycle_count /= 4) then 
	      			cycle_count <= cycle_count + 1;
	      		else
		    		PC <= PC + 1;
		    		cycle_count <= 1;
		    	end if;
			end if;
	  	end process PC_counter;

--"debounce" process: Takes the input of the slower clock and ensures that only one 
--clock is running at a time when the button is pushed. This debounced clock is then
--sent to the FSM as the actual clock for sequential logic. Taken directly from the
--provided debounce.vhd file on blackboard, modified to allow an LED light to flash for
--0.5s while the clock turns on.
		debounce: process(clock)
	  	begin
	    	if button = '1' then
	      		deb_count <= 0;
	    	elsif (rising_edge(clock)) then
	      		if (deb_count /= 3) then 
	      			deb_count <= deb_count + 1; 
	      		end if;
	    	end if;
	    	if (deb_count = 2) and (button = '0') then 
	    		pulse <= clock;  
	    		else pulse <= '0';
			end if;
	  	end process debounce;
-- --------------------------------------------------

	char_process: process(PC_vector)
	begin
		char1 <= PC_vector(15 downto 12);
		char2 <= PC_vector(11 downto 8);
		char3 <= PC_vector(7 downto 4);
		char4 <= PC_vector(3 downto 0);
	end process char_process; -- mux
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
	with char1 select
		seg1 <= "00000011" when x"0",
			    "10011111" when x"1",
			    "00100101" when x"2",
			    "00001101" when x"3",
			    "10011001" when x"4",
			    "01001001" when x"5",
			    "01000001" when x"6",
			    "00011111" when x"7",
			    "00000001" when x"8",
			    "00001001" when x"9",
				"00010001" when x"A",
			    "00000001" when x"B",
			    "01100011" when x"C",
			    "10000101" when x"D",
			    "01100001" when x"E",
			    "01110001" when x"F",
			    "11111111" when others;

	with char2 select
		seg2 <= "00000011" when x"0",
			    "10011111" when x"1",
			    "00100101" when x"2",
			    "00001101" when x"3",
			    "10011001" when x"4",
			    "01001001" when x"5",
			    "01000001" when x"6",
			    "00011111" when x"7",
			    "00000001" when x"8",
			    "00001001" when x"9",
				"00010001" when x"A",
			    "00000001" when x"B",
			    "01100011" when x"C",
			    "10000101" when x"D",
			    "01100001" when x"E",
			    "01110001" when x"F",
			    "11111111" when others;

	with char3 select
		seg3 <= "00000011" when x"0",
			    "10011111" when x"1",
			    "00100101" when x"2",
			    "00001101" when x"3",
			    "10011001" when x"4",
			    "01001001" when x"5",
			    "01000001" when x"6",
			    "00011111" when x"7",
			    "00000001" when x"8",
			    "00001001" when x"9",
				"00010001" when x"A",
			    "00000001" when x"B",
			    "01100011" when x"C",
			    "10000101" when x"D",
			    "01100001" when x"E",
			    "01110001" when x"F",
			    "11111111" when others;

	with char4 select
		seg4 <= "00000011" when x"0",
			    "10011111" when x"1",
			    "00100101" when x"2",
			    "00001101" when x"3",
			    "10011001" when x"4",
			    "01001001" when x"5",
			    "01000001" when x"6",
			    "00011111" when x"7",
			    "00000001" when x"8",
			    "00001001" when x"9",
				"00010001" when x"A",
			    "00000001" when x"B",
			    "01100011" when x"C",
			    "10000101" when x"D",
			    "01100001" when x"E",
			    "01110001" when x"F",
			    "11111111" when others;

-- --------------------------------------------------

--"displaying" process: establishes a counter that will cycle through each of the anodes
--as to allow each character to be displayed one by one since they cannot all be sent
--to their corresponding anode at the same time
	displaying: process(seg1, seg2, seg3, seg4)
	begin
		if (rising_edge(pulse)) then
			if (displaycounter = 3) then
			displaycounter <= 0;
			else
			displaycounter <= displaycounter + 1;
			end if;
		end if;
		case(displaycounter) is
		
			when 0 	=> 	
				Y 		<= seg1;
				anode 	<= "0111";
			when 1 	=>	
				Y 		<= seg2;
				anode 	<= "1011";
			when 2 	=> 	
				Y 		<= seg3;
				anode 	<= "1101";
			when 3 	=> 	
				Y 		<= seg4;
				anode 	<= "1110";
			when others =>	
				Y 		<= "11111111";
				anode 	<= "1111";
		end case;
		
	end process displaying;

end architecture arch;