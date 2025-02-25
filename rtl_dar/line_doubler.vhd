---------------------------------------------------------------------------------
-- Line doubler - Dar - Feb 2014
---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity line_doubler is
port(
	clock   : in std_logic;
	ena_pix : in std_logic;
	video_i : in std_logic_vector(5 downto 0);
	hsync_i : in std_logic;
	video_o : out std_logic_vector(5 downto 0);
	hsync_o : out std_logic
);
end line_doubler;

architecture struct of line_doubler is

signal hsync_i_r  : std_logic;
signal hcnt_i     : std_logic_vector(8 downto 0);
signal hcnt_o     : std_logic_vector(8 downto 0);

signal flip_flop : std_logic;

type ram_1024 is array(0 to 511) of std_logic_vector(5 downto 0);
signal ram1  : ram_1024;
signal ram2  : ram_1024;
signal video : std_logic_vector(5 downto 0);

begin

process(clock)
begin
	if rising_edge(clock) then
	
		if ena_pix = '1' then
	
			hsync_i_r <= hsync_i;

			if (hsync_i = '0' and hsync_i_r = '1') then
				flip_flop <= not flip_flop;
				hcnt_i <= (others => '0');
			else
				hcnt_i <= hcnt_i + '1';
			end if;
			
		end if;
			
		if (hsync_i = '0' and hsync_i_r = '1') or hcnt_o = 383 then
			hcnt_o <= (others => '0');
		else
			hcnt_o <= hcnt_o + '1';
		end if;

		if     hcnt_o = 383-48 then hsync_o <= '0';
		elsif  hcnt_o = 383-2  then hsync_o <= '1';
		end if;

	end if;
end process;

process(clock)
begin
	if rising_edge(clock) then
		if flip_flop = '0' then
			ram1(to_integer(unsigned(hcnt_i))) <= video_i;
			video <= ram2(to_integer(unsigned(hcnt_o)));
		else
			ram2(to_integer(unsigned(hcnt_i))) <= video_i;
			video <= ram1(to_integer(unsigned(hcnt_o)));
		end if;
	end if;
	
	video_o <= video;
	
end process;

end architecture;