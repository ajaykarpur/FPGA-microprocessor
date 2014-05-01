library IEEE;
	use IEEE.STD_LOGIC_1164.ALL;
	use IEEE.NUMERIC_STD.ALL;
	use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity microprocessor is
	port
	(
		clock, reset, PC_button, mux_button: in std_logic;
		PC_LED: out std_logic;
		mux_LED: out std_logic_vector(0 to 3);
		anode: out std_logic_vector(3 downto 0);
		Y: out std_logic_vector(7 downto 0)
	);
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

	signal PC_deb_count: integer range 0 to 100;
	signal mux_deb_count: integer range 0 to 100;
	signal PC_pulse: std_logic;
	signal mux_pulse: std_logic;
	signal mux_count: integer range 0 to 3 := 0;

	signal slow_clock: std_logic;
	signal slow_count: integer range 0 to 20001 := 0;
	signal char1: std_logic_vector(3 downto 0);
	signal char2: std_logic_vector(3 downto 0);
	signal char3: std_logic_vector(3 downto 0);
	signal char4: std_logic_vector(3 downto 0);
	signal seg1: std_logic_vector(7 downto 0);
	signal seg2: std_logic_vector(7 downto 0);
	signal seg3: std_logic_vector(7 downto 0);
	signal seg4: std_logic_vector(7 downto 0);
	signal displaycounter: integer range 0 to 3;

	signal display_vector: std_logic_vector(15 downto 0);

	begin

		-- microprocessor stages ===========================================

		fetch: process(slow_clock, reset)
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
			elsif rising_edge(slow_clock) then
				IR <= IM(PC);
			end if;
		end process fetch;

		decode: process(slow_clock, reset)
		begin
			if (reset = '1') then
				opcode <= "1111";
				RA <= "0000";
				RB <= "0000";
				RD <= "0000";
				immediate <= x"00";
			elsif rising_edge(slow_clock) then
				opcode <= IR(15 downto 12);
				RA <= IR(11 downto 8);
				RB <= IR(7 downto 4);
				RD <= IR(3 downto 0);
				immediate <= IR(11 downto 4);
			end if;
		end process decode;

		execute: process(slow_clock, reset)
		begin
			if (reset = '1') then
				W <= x"00";
				terminate <= '0';
			elsif rising_edge(slow_clock) then
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
						W <= x"00";
				
				end case;
			end if;
		end process execute;

		store: process(slow_clock, reset)
		begin
			if (reset = '1') then
				RF(0 to 15) <= (others => x"00");
			elsif rising_edge(slow_clock) then
				RF(conv_integer(RD)) <= W;
			end if;
		end process store;
		
		PC_counter: process(PC_pulse)
	  	begin
	  		if (reset = '1') then
	  			PC <= 0;
	  		elsif (terminate = '1') then
	  			PC <= PC;
	    	elsif rising_edge(PC_pulse) then
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
			end if;
	  	end process PC_counter;
		
		
		
		-- clock and PC ===================================================
		
		--"slow clock" process: Takes the FPGA built in clock and slows it down to a speed of
		--2.5kHz to be used in the FSM and the debounce.	
		slow_clock_process: process(clock)
		begin
			if (rising_edge(clock)) then
				slow_count <= slow_count + 1;
				if (slow_count = 20000) then
					slow_count <= 0;
					slow_clock <= '0';
				elsif (slow_count = 10000) then
					slow_clock <= '1';
				end if;
			end if;
		end process slow_clock_process;

		--"debounce" process: Takes the input of the slower clock and ensures that only one 
		--clock is running at a time when the PC_button is pushed. This debounced clock is then
		--sent to the FSM as the actual clock for sequential logic. Taken directly from the
		--provided debounce.vhd file on blackboard, modified to allow an LED light to flash for
		--0.5s while the clock turns on.
		PC_debounce: process(slow_clock)
	  	begin
	    	if PC_button = '1' then
	      		PC_deb_count <= 0;
	    	elsif (rising_edge(slow_clock)) then
	      		if (PC_deb_count /= 41) then 
	      			PC_deb_count <= PC_deb_count + 1;
	      		end if;
	    	end if;
	    	if (PC_deb_count = 40) and (PC_button = '0') then 
	    		PC_pulse <= '1';  
	    		else PC_pulse <= '0';
			end if;
	  	end process PC_debounce;
		
		PC_LED <= PC_pulse;
		
		
		
		-- display mux =====================================================
		
		display_mux: process(mux_pulse)
		begin
			if rising_edge(mux_pulse) then
				mux_count <= mux_count + 1;
				if (mux_count = 3) then
					mux_count <= 0;
				end if;
			end if;
		end process display_mux;

		with mux_count select
			display_vector <= std_logic_vector(to_unsigned(PC, 16)) when 0,
							  (x"000" & opcode) when 1,
							  IR when 2,
							  (x"00" & RF(conv_integer(RD))) when 3,
							  std_logic_vector(to_unsigned(PC, 16)) when others;

		mux_debounce: process(slow_clock)
	  	begin
	    	if mux_button = '1' then
	      		mux_deb_count <= 0;
	    	elsif (rising_edge(slow_clock)) then
	      		if (mux_deb_count /= 41) then 
	      			mux_deb_count <= mux_deb_count + 1;
	      		end if;
	    	end if;
	    	if (mux_deb_count = 40) and (mux_button = '0') then 
	    		mux_pulse <= '1';  
	    		else mux_pulse <= '0';
			end if;
	  	end process mux_debounce;
		
		with mux_count select
			mux_LED <= "1000" when 0,
					   "0100" when 1,
					   "0010" when 2,
					   "0001" when 3,
					   "0000" when others;
		
		
		
		-- display driver ==================================================

		char_process: process(display_vector)
		begin
			char1 <= display_vector(15 downto 12);
			char2 <= display_vector(11 downto 8);
			char3 <= display_vector(7 downto 4);
			char4 <= display_vector(3 downto 0);
		end process char_process;

		--Determines the actual 8-bit vector that gets sent to the cathode to be displayed on 
		--the 7-segment display.
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
				     "11000001" when x"b",
				     "01100011" when x"C",
				     "10000101" when x"d",
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
				     "11000001" when x"b",
				     "01100011" when x"C",
				     "10000101" when x"d",
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
				     "11000001" when x"b",
				     "01100011" when x"C",
				     "10000101" when x"d",
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
				     "11000001" when x"b",
				     "01100011" when x"C",
				     "10000101" when x"d",
				     "01100001" when x"E",
				     "01110001" when x"F",
				     "11111111" when others;

		--"displaying" process: establishes a counter that will cycle through each of the anodes
		--as to allow each character to be displayed one by one since they cannot all be sent
		--to their corresponding anode at the same time
		displaying: process(seg1, seg2, seg3, seg4)
		begin
			if (rising_edge(slow_clock)) then
				if (displaycounter = 3) then
				displaycounter <= 0;
				else
				displaycounter <= displaycounter + 1;
				end if;
			end if;
			case(displaycounter) is
				when 0 =>
					Y <= seg1;
					anode <= "0111";
				
				when 1 =>	
					Y <= seg2;
					anode <= "1011";
				
				when 2 => 	
					Y <= seg3;
					anode <= "1101";
				
				when 3 => 	
					Y <= seg4;
					anode <= "1110";
				
				when others =>	
					Y <= "11111111";
					anode <= "1111";
			end case;
			
		end process displaying;

end architecture arch;