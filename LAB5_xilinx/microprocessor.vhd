library IEEE;
	use IEEE.STD_LOGIC_1164.ALL;
	use IEEE.NUMERIC_STD.ALL;
	use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity microprocessor is
	port
	(
		clock: in std_logic
	);
end entity microprocessor;

architecture arch of microprocessor is

	signal IM: std_logic_vector(15 downto 0);
	signal PC: integer range 0 to 255;
	signal IR: std_logic_vector(15 downto 0);
	signal opcode: std_logic_vector (3 downto 0);
	signal RA: std_logic_vector(3 downto 0);
	signal RB: std_logic_vector(3 downto 0);
	signal RD: std_logic_vector(3 downto 0);
	signal immediate: std_logic_vector(7 downto 0);
	signal W: std_logic_vector(7 downto 0);

	begin

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
			immediate <= IR(7 downto 0);

			PC <= PC + 1;

		end process decode;

		execute: process(clock)
		begin
			
		end process execute;

		store: process(clock)
		begin
			
		end process store;


end architecture arch;