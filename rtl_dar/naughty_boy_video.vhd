---------------------------------------------------------------------------------
-- Naughty Boy video generator by Dar (darfpga@aol.fr)
-- http://darfpga.blogspot.fr
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;

entity naughty_boy_video is
port(
 clk12    : in std_logic;
 hcnt     : out std_logic_vector(8 downto 0);
 vcnt     : out std_logic_vector(7 downto 0);
 ena_pix  : inout std_logic;
 hsync    : out std_logic;
 vsync    : out std_logic;
 csync    : out std_logic;
 cpu_wait : out std_logic;
 clr_vid  : out std_logic;
 vblank   : out std_logic;
 
 sel_cpu_addr  : out std_logic;
 sel_scrl_addr : out std_logic
); end naughty_boy_video;

architecture struct of naughty_boy_video is 
 signal hcnt_i : unsigned(8 downto 0) := (others=>'0');
 signal vcnt_i : unsigned(7 downto 0) := (others=>'0');
 
 signal j1      : std_logic;
 signal k1      : std_logic;
 signal clr1_n  : std_logic;
 signal q1      : std_logic := '0';
 
 signal j2      : std_logic;
 signal k2      : std_logic;
 signal clr2_n  : std_logic;
 signal q2      : std_logic := '0';
 signal q2r     : std_logic := '0';
 
 signal mux1    : std_logic_vector(7 downto 0) := (others=>'0');
 
 signal sync1_n : std_logic;

 constant start_l : integer := 170;
 
begin

-- horizontal counter clock (pixel clock) 
process (clk12)
begin
 if rising_edge(clk12) then
  ena_pix <= not ena_pix;
 end if;
end process;

-- horizontal counter from 0x080 to 0x1FF : 384 pixels 
process (clk12)
begin
	if rising_edge(clk12) then
		if ena_pix = '1' then
			if hcnt_i = "111111111" then
				hcnt_i <= "010000000";
			else
				hcnt_i  <= hcnt_i + 1;
			end if;
		end if;
	end if;
end process;

-- Mux1 - 74138
mux1(0) <= '0' when hcnt_i(8) = '0' and hcnt_i(6 downto 4) = "000" else '1';
mux1(1) <= '0' when hcnt_i(8) = '0' and hcnt_i(6 downto 4) = "001" else '1';
mux1(4) <= '0' when hcnt_i(8) = '0' and hcnt_i(6 downto 4) = "100" else '1';
mux1(5) <= '0' when hcnt_i(8) = '0' and hcnt_i(6 downto 4) = "101" else '1';
mux1(6) <= '0' when hcnt_i(8) = '0' and hcnt_i(6 downto 4) = "110" else '1';
mux1(7) <= '0' when hcnt_i(8) = '0' and hcnt_i(6 downto 4) = "111" else '1';

-- JK1 - 74107
j1 <= not mux1(0);
k1 <= not mux1(6);
clr1_n <= not hcnt_i(8);

process (clk12)
begin
	if clr1_n = '0' then
		q1 <= '0';
	else
		if rising_edge(clk12) then
			if ena_pix = '1' and hcnt_i(3 downto 0) = "1111" then
				if (j1 xor k1) = '1' then
					q1 <= j1;
				elsif j1 = '1' then
					q1 <= not q1;
				else
					q1 <= q1;
				end if;
			end if;
		end if;		
	end if;		
end process;

-- JK2 - 74107
j2 <= not mux1(1);
k2 <= not mux1(5);
clr2_n <= not hcnt_i(8);

process (clk12)
begin
	if clr2_n = '0' then
		q2 <= '0';
	else
		if rising_edge(clk12) then
			if ena_pix = '1' and hcnt_i(3 downto 0) = "1111" then
				if (j2 xor k2) = '1' then
					q2 <= j2;
				elsif j2 = '1' then
					q2 <= not q2;
				else
					q2 <= q2;
				end if;
			end if;
		end if;		
	end if;		
end process;

-- vertical counter from 0x00 to 0xFF : 256 lines 
process (clk12)
begin
	if rising_edge(clk12) then
		q2r <= q2;
		if q2 = '1' and q2r = '0' then
			if vcnt_i = "11111111" then
				vcnt_i <= (others=>'0');
			else
				vcnt_i <= vcnt_i +1;
			end if;
		end if;  
	end if;
end process;

-- Misc
sync1_n <= not(vcnt_i(7) and vcnt_i(6) and vcnt_i(5));
sel_cpu_addr <= not(not(q1) and sync1_n);
sel_scrl_addr <= hcnt_i(8);
cpu_wait <= not(q2) and sync1_n;
clr_vid <= '1' when (hcnt_i > 143 and hcnt_i < 240) or sync1_n = '0' else '0';

hsync <= not(mux1(4));
vsync <= not(sync1_n) and vcnt_i(4) and vcnt_i(3) and vcnt_i(2);

vblank <= sync1_n;
hcnt <= std_logic_vector(hcnt_i);
vcnt <= std_logic_vector(vcnt_i);
 
-- Composite Sync 
process (clk12)
begin
	if rising_edge(clk12) then
		if ena_pix = '1' then
			
			if vcnt_i >= 224 and vcnt_i <= 225 then
				if	hcnt_i = start_l            then csync <= '0'; end if;
				if hcnt_i = start_l    +14 then csync <= '1'; end if;
				if hcnt_i = start_l+192    then csync <= '0'; end if;
				if hcnt_i = start_l+192+14 then csync <= '1'; end if;
				
			elsif vcnt_i = 226 then
				if hcnt_i = start_l        then csync <= '0'; end if;
				if hcnt_i = start_l    +14 then csync <= '1'; end if;
				if hcnt_i = start_l+192    then csync <= '0'; end if;
		
			elsif vcnt_i >= 227 and vcnt_i <= 228 then
				if hcnt_i = start_l    -14 then csync <= '1'; end if;
				if hcnt_i = start_l        then csync <= '0'; end if;
				if hcnt_i = start_l+192-14 then csync <= '1'; end if;
				if hcnt_i = start_l+192    then csync <= '0'; end if;

			elsif vcnt_i = 229 then
				if hcnt_i = start_l    -14 then csync <= '1'; end if;
				if hcnt_i = start_l        then csync <= '0'; end if;
				if hcnt_i = start_l    +14 then csync <= '1'; end if;
				if hcnt_i = start_l+192    then csync <= '0'; end if;
				if hcnt_i = start_l+192+14 then csync <= '1'; end if;
				
			elsif vcnt_i = 230 then
				if hcnt_i = start_l        then csync <= '0'; end if;
				if hcnt_i = start_l    +14 then csync <= '1'; end if;
				if hcnt_i = start_l+192    then csync <= '0'; end if;
				if hcnt_i = start_l+192+14 then csync <= '1'; end if;
				
			else
				if hcnt_i = start_l        then csync <= '0'; end if;
				if hcnt_i = start_l    +28 then csync <= '1'; end if;
			end if;
			
		end if;  
	end if;
end process;
	
end struct;
