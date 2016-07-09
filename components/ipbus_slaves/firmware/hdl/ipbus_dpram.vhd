-- ipbus_dpram
--
-- Generic 32b (or less) wide dual-port memory with ipbus access on one port
-- This is a 'flat memory' mapping the RAM directly into ipbus address space
-- Note that 1 wait state is required due to design of Xilinx block RAM
--
-- Should lead to an inferred block RAM in Xilinx parts with modern tools
--
--
-- Dave Newbold, July 2013

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.ipbus.all;

entity ipbus_dpram is
	generic(
		ADDR_WIDTH: positive;
		DATA_WIDTH: positive := 32
	);
	port(
		clk: in std_logic;
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		rclk: in std_logic;
		we: in std_logic := '0';
		d: in std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
		q: out std_logic_vector(DATA_WIDTH - 1 downto 0);
		addr: in std_logic_vector(ADDR_WIDTH - 1 downto 0)
	);
	
end ipbus_dpram;

architecture rtl of ipbus_dpram is

	type ram_array is array(2 ** ADDR_WIDTH - 1 downto 0) of std_logic_vector(DATA_WIDTH - 1 downto 0);
	shared variable ram: ram_array;
	signal sel, rsel: integer range 0 to 2 ** ADDR_WIDTH - 1 := 0;
	signal ack: std_logic;

begin

	sel <= to_integer(unsigned(ipb_in.ipb_addr(ADDR_WIDTH - 1 downto 0)));

	process(clk)
	begin
		if rising_edge(clk) then
			ipb_out.ipb_rdata <= (32 - DATA_WIDTH downto 0 => '0') & ram(sel); -- Order of statements is important to infer read-first RAM!
			if ipb_in.ipb_strobe='1' and ipb_in.ipb_write='1' then
				ram(sel) := ipb_in.ipb_wdata(DATA_WIDTH - 1 downto 0);
			end if;
			ack <= ipb_in.ipb_strobe and not ack;
		end if;
	end process;
	
	ipb_out.ipb_ack <= ack;
	ipb_out.ipb_err <= '0';
	
	rsel <= to_integer(unsigned(addr));
	
	process(rclk)
	begin
		if rising_edge(rclk) then
			q <= ram(rsel); -- Order of statements is important to infer read-first RAM!
			if we = '1' then
				ram(rsel) := d;
			end if;
		end if;
	end process;

end rtl;
