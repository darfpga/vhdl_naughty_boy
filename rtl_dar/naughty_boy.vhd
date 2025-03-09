---------------------------------------------------------------------------------
-- Naughty Boy by Dar (darfpga@aol.fr)
-- http://darfpga.blogspot.fr
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;

entity naughty_boy is
port(
 clock_50     : in std_logic;
 clock_12     : in std_logic;
 reset        : in std_logic;
 dip_switch   : in std_logic_vector(7 downto 0);
 coin         : in std_logic;
 starts       : in std_logic_vector(1 downto 0);
 player1_btns : in std_logic_vector(4 downto 0);
 player2_btns : in std_logic_vector(4 downto 0);
 video_r      : out std_logic_vector(1 downto 0);
 video_g      : out std_logic_vector(1 downto 0);
 video_b      : out std_logic_vector(1 downto 0);
 video_csync  : out std_logic;
 video_hs     : out std_logic;
 video_vs     : out std_logic;
 video_hblank : out std_logic;
 video_vblank : out std_logic; 
 ce_pix       : inout std_logic
-- audio_select : in std_logic_vector(2 downto 0);
-- audio        : out std_logic_vector(11 downto 0)
);
end naughty_boy;

architecture struct of naughty_boy is

 signal reset_n: std_logic;

 signal clock_12n : std_logic;
 signal hcnt      : std_logic_vector(8 downto 0);
 signal hcnt_1r   : std_logic;
 signal ena_pix   : std_logic;
 signal vcnt      : std_logic_vector(7 downto 0);
 signal hsync     : std_logic;
 signal vsync     : std_logic;
 
 signal rdy           : std_logic; 
 signal cpu_wait      : std_logic; 
 signal sel_cpu_addr  : std_logic; 
 signal sel_scrl_addr : std_logic;  
 signal hblank        : std_logic;
 signal vblank        : std_logic;
  
 signal cpu_ena  : std_logic;
 signal cpu_adr  : std_logic_vector(15 downto 0);
 signal cpu_di   : std_logic_vector( 7 downto 0);
 signal cpu_do   : std_logic_vector( 7 downto 0);
 signal cpu_wr_n : std_logic;
 signal prog_do  : std_logic_vector( 7 downto 0);
 
 signal wrk_ram_do  : std_logic_vector( 7 downto 0);
 signal wrk_ram_we  : std_logic; 
 
 signal horz_cnt : std_logic_vector(8 downto 0) := (others =>'0');
 signal vert_cnt : std_logic_vector(7 downto 0) := (others =>'0');
 signal hcnt_s   : std_logic_vector(2 downto 0) := (others =>'0');

 signal frgnd_ram_adr: std_logic_vector(10 downto 0) := (others =>'0');
 signal bkgnd_ram_adr: std_logic_vector(10 downto 0) := (others =>'0');
 signal frgnd_ram_do : std_logic_vector( 7 downto 0) := (others =>'0');
 signal bkgnd_ram_do : std_logic_vector( 7 downto 0) := (others =>'0');
 signal frgnd_ram_we : std_logic := '0';
 signal bkgnd_ram_we : std_logic := '0';
 
 signal frgnd_graph_adr : std_logic_vector(11 downto 0) := (others =>'0');
 signal bkgnd_graph_adr : std_logic_vector(11 downto 0) := (others =>'0');
 signal palette_adr     : std_logic_vector( 7 downto 0) := (others =>'0'); 
 
 signal frgnd_tile_id : std_logic_vector(7 downto 0) := (others =>'0');
 signal bkgnd_tile_id : std_logic_vector(7 downto 0) := (others =>'0');

 signal frgnd_bit0_graph : std_logic_vector(7 downto 0) := (others =>'0');
 signal frgnd_bit1_graph : std_logic_vector(7 downto 0) := (others =>'0');
 signal bkgnd_bit0_graph : std_logic_vector(7 downto 0) := (others =>'0');
 signal bkgnd_bit1_graph : std_logic_vector(7 downto 0) := (others =>'0');
 
 signal fr_bit0  : std_logic;
 signal fr_bit1  : std_logic;
 signal bk_bit0  : std_logic;
 signal bk_bit1  : std_logic;
 signal fr_lin   : std_logic_vector(2 downto 0);
 signal bk_lin   : std_logic_vector(2 downto 0);
 
 signal color_set : std_logic_vector(1 downto 0);
 signal color_id  : std_logic_vector(5 downto 0);
 signal rgb_0     : std_logic_vector(7 downto 0);
 signal rgb_1     : std_logic_vector(7 downto 0);
  
 signal graphx_bank  : std_logic := '0';
 signal player2      : std_logic := '0';
 signal pl2_cocktail : std_logic := '0';
 signal bkgnd_offset : std_logic_vector(7 downto 0) := (others =>'0');
-- signal sound_a      : std_logic_vector(7 downto 0) := (others =>'0');
-- signal sound_b      : std_logic_vector(7 downto 0) := (others =>'0');
 
-- signal clk10 : std_logic;
-- signal snd1  : std_logic_vector( 7 downto 0) := (others =>'0');
-- signal snd2  : std_logic_vector( 1 downto 0) := (others =>'0');
-- signal snd3  : std_logic_vector( 7 downto 0) := (others =>'0');
-- signal song  : std_logic_vector( 7 downto 0) := (others =>'0');
-- signal mixed : std_logic_vector(11 downto 0) := (others =>'0');
-- signal sound_string : std_logic_vector(31 downto 0);
 
 signal coin_n   : std_logic;
 signal buttons  : std_logic_vector(4 downto 0);
 
begin

---- make 10MHz clock from 50MHz
--process (clock_50)
-- variable cnt : std_logic_vector(3 downto 0) := (others => '0');
--begin
-- if rising_edge(clock_50) then
--  cnt := std_logic_vector(unsigned(cnt) + 1);
--  clk10 <= '0';
--  if cnt = X"5" then
--   cnt := (others => '0');
--   clk10 <= '1';
--  end if;   
-- end if;
--end process;

-- video address/sync generator
video_gen : entity work.naughty_boy_video
port map(
 clk12    => clock_12,
 hcnt     => hcnt,
 vcnt     => vcnt,
 ena_pix  => ena_pix,
 hsync    => video_hs,
 vsync    => video_vs,
 csync    => video_csync,
 cpu_wait => cpu_wait,
 hblank   => hblank,
 vblank   => vblank,
 sel_cpu_addr  => sel_cpu_addr,
 sel_scrl_addr => sel_scrl_addr
);

-- misc
clock_12n<= not clock_12;
reset_n  <= not reset;
rdy      <= not cpu_wait;
ce_pix   <= ena_pix;


coin_n   <= not coin;
buttons  <= player1_btns when player2 = '0' else player2_btns;

-- ena_cpu
cpu_ena <= '1' when hcnt_1r ='0' and hcnt(0) = '1' else '0';

process (clock_12)
begin
	if rising_edge(clock_12) then
		hcnt_1r <= hcnt(0);
	end if;   
end process;

-- microprocessor Z80 - 1
Z80 : entity work.T80se
generic map(Mode => 0, T2Write => 1, IOWait => 1)
port map(
  RESET_n => reset_n,
  CLK_n   => clock_12,
  CLKEN   => cpu_ena,
  WAIT_n  => rdy,
  INT_n   => '1',
  NMI_n   => coin_n,
  BUSRQ_n => '1',
  M1_n    => open,
  MREQ_n  => open,
  IORQ_n  => open,
  RD_n    => open,
  WR_n    => cpu_wr_n,
  RFSH_n  => open,
  HALT_n  => open,
  BUSAK_n => open,
  A       => cpu_adr,
  DI      => cpu_di,
  DO      => cpu_do
);

-- mux prog, ram, vblank, switch... to processor data bus in
cpu_di <= prog_do      when cpu_adr(15 downto 14) = "00" else
			 wrk_ram_do   when cpu_adr(15 downto 14) = "01" else
          frgnd_ram_do when cpu_adr(15 downto 11) = "10000" else
          bkgnd_ram_do when cpu_adr(15 downto 11) = "10001" else
			 buttons&'0'&starts when cpu_adr(15 downto 11) = "10110" else
			 not(vblank) & dip_switch(6 downto 0) when cpu_adr(15 downto 11) = "10111" else
			 x"FF";

-- write enable to RAMs from cpu
wrk_ram_we   <= '1' when cpu_wr_n = '0' and cpu_adr(15 downto 14) = "01" else '0'; 
frgnd_ram_we <= '1' when cpu_wr_n = '0' and cpu_adr(15) = '1' and cpu_adr(13 downto 11) = "000" and sel_cpu_addr = '1' else '0';
bkgnd_ram_we <= '1' when cpu_wr_n = '0' and cpu_adr(15) = '1' and cpu_adr(13 downto 11) = "001" and sel_cpu_addr = '1' else '0';

-- RAMs address mux cpu/video_generator
frgnd_ram_adr <= 	cpu_adr(10 downto 0) when sel_cpu_addr ='1' else 
						vert_cnt(7 downto 3) & horz_cnt(8 downto 3) when sel_scrl_addr = '1' else 
						"1110" & vert_cnt(7 downto 3) & hcnt(4 downto 3) when pl2_cocktail = '0' else
						"1110" & vert_cnt(7 downto 3) & not hcnt(4 downto 3);
						
bkgnd_ram_adr <= 	frgnd_ram_adr;

-- demux cpu data to registers : background scrolling, sound control,
-- player id (1/2), palette color set. 
process (clock_12)
begin
	if rising_edge(clock_12) then
		if cpu_wr_n = '0' then
			case cpu_adr(15 downto 11) is
				when "10010" => 	player2 <= cpu_do(0);
										color_set <= cpu_do(2 downto 1);
				when "10011" => 	bkgnd_offset <= cpu_do;
--    when "11000" => sound_b      <= cpu_do;
--    when "11010" => sound_a      <= cpu_do;
				when others => null;
			end case;
		end if; 
	end if;
end process;

---- player2 and cocktail mode (flip horizontal/vertical)
pl2_cocktail <= player2 and dip_switch(7);
--
---- horizontal scan video RAMs address background and foreground
---- with flip and scroll offset
horz_cnt <=
	('0'&hcnt(7 downto 0)) + ('0'&bkgnd_offset) when pl2_cocktail = '0'else
	('0'&not hcnt(7 downto 0)) + ('0'&bkgnd_offset);

---- vertical scan video RAMs address
vert_cnt <= vcnt when pl2_cocktail = '0' else not (vcnt + X"20");

-- get tile_ids from RAMs
frgnd_tile_id <= frgnd_ram_do;
bkgnd_tile_id <= bkgnd_ram_do; 

-- address graphix ROMs with tile_ids and line counter
graphx_bank <= color_set(1);
frgnd_graph_adr <= graphx_bank & frgnd_tile_id & vert_cnt(2 downto 0);
bkgnd_graph_adr <= graphx_bank & bkgnd_tile_id & vert_cnt(2 downto 0);

hcnt_s <= 
	horz_cnt(2 downto 0) when sel_scrl_addr = '1' else 
	hcnt(2 downto 0) when pl2_cocktail = '0' else
	not hcnt(2 downto 0);

---- latch foreground/background next graphix byte, high bit and low bit
---- and palette_ids (fr_lin, bklin)
---- demux background and foreground pixel bits (0/1) from graphix byte with horizontal counter
---- and apply blanking
process (clock_12)
begin
	if rising_edge(clock_12) then
		if ena_pix = '1' then
			if (hblank = '0' and vblank = '0') then
				fr_bit0 <= frgnd_bit0_graph(to_integer(unsigned(hcnt_s))); 
				fr_bit1 <= frgnd_bit1_graph(to_integer(unsigned(hcnt_s))); 
				bk_bit0 <= bkgnd_bit0_graph(to_integer(unsigned(hcnt_s))); 
				bk_bit1 <= bkgnd_bit1_graph(to_integer(unsigned(hcnt_s))); 
			else
				fr_bit0 <= '0'; 
				fr_bit1 <= '0'; 
				bk_bit0 <= '0'; 
				bk_bit1 <= '0'; 
			end if;
			fr_lin <= frgnd_tile_id(7 downto 5);
			bk_lin <= bkgnd_tile_id(7 downto 5);
	end if;	
end if;
end process;

---- select pixel bits and palette_id with foreground priority
color_id  <=  (fr_bit0 or fr_bit1) &  fr_bit1 & fr_bit0 & fr_lin when (fr_bit0 or fr_bit1) = '1' else
              (fr_bit0 or fr_bit1) &  bk_bit1 & bk_bit0 & bk_lin;

-- address palette with pixel bits color and color set
palette_adr <= color_set & color_id;

-- output video to top level
video_r <= rgb_1(0) & rgb_0(0);
video_g <= rgb_1(2) & rgb_0(2);
video_b <= rgb_1(1) & rgb_0(1);

video_hblank <= hblank;
video_vblank <= vblank;

-- foreground graphix ROM bit0
frgnd_bit0 : entity work.prom_graphx_2_bit0
port map(
 clk  => clock_12,
 addr => frgnd_graph_adr,
 data => frgnd_bit0_graph
);

-- foreground graphix ROM bit1
frgnd_bit1 : entity work.prom_graphx_2_bit1
port map(
 clk  => clock_12,
 addr => frgnd_graph_adr,
 data => frgnd_bit1_graph
);

-- background graphix ROM bit0
bkgnd_bit0 : entity work.prom_graphx_1_bit0
port map(
 clk  => clock_12,
 addr => bkgnd_graph_adr,
 data => bkgnd_bit0_graph
);

-- background graphix ROM bit1
bkgnd_bit1 : entity work.prom_graphx_1_bit1
port map(
 clk  => clock_12,
 addr => bkgnd_graph_adr,
 data => bkgnd_bit1_graph
);

-- color palette ROM RBG low intensity
palette_0 : entity work.prom_palette_1
port map(
 clk  => clock_12,
 addr => palette_adr,
 data => rgb_0
);

-- color palette ROM RBG high intensity
palette_1 : entity work.prom_palette_2
port map(
 clk  => clock_12,
 addr => palette_adr,
 data => rgb_1
);

-- Program PROM 0x0000-0x3FFF
prog : entity work.prom_prog 
port map(
 clk  => clock_12,
 addr => cpu_adr(13 downto 0),
 data => prog_do
);

-- working RAM   0x4000-0x47FF
working_ram : entity work.gen_ram
generic map( dWidth => 8, aWidth => 10)
port map(
 clk  => clock_12,
 we   => wrk_ram_we,
 addr => cpu_adr(9 downto 0),
 d    => cpu_do,
 q    => wrk_ram_do
);

-- foreground RAM   0x8000-0x87FF
frgnd_ram : entity work.gen_ram
generic map( dWidth => 8, aWidth => 11)
port map(
 clk  => clock_12n,
 we   => frgnd_ram_we,
 addr => frgnd_ram_adr,
 d    => cpu_do,
 q    => frgnd_ram_do
);

-- background RAM   0x8800-0x8FFF
bkgnd_ram : entity work.gen_ram
generic map( dWidth => 8, aWidth => 11)
port map(
 clk  => clock_12n,
 we   => bkgnd_ram_we,
 addr => bkgnd_ram_adr,
 d    => cpu_do,
 q    => bkgnd_ram_do
);
--
---- sound effect1
----effect1 : entity work.phoenix_effect1
----port map(
----clk50    => clock_50,
----clk10    => clk10,
----reset    => '0',
----trigger  => sound_a(4),
----filter   => sound_a(5),
----divider  => sound_a(3 downto 0),
----snd      => snd1
----);
--
---- sound effect2
----effect2 : entity work.phoenix_effect2
----port map(
----clk50    => clock_50,
----clk10    => clk10,
----reset    => '0',
----trigger1 => sound_b(4),
----trigger2 => sound_b(5),
----divider  => sound_b(3 downto 0),
----snd      => snd2
----);
--
---- sound effect3
----effect3 : entity work.phoenix_effect3
----port map(
----clk50    => clock_50,
----clk10    => clk10,
----reset    => '0',
----trigger1 => sound_b(6),
----trigger2 => sound_b(7),
----snd      => snd3
----);
--
---- melody
----music : entity work.phoenix_music
----port map(
----clk10    => clk10,
----reset    => '0',
----trigger  => sound_a(7),
----sel_song => sound_a(6),
----snd      => song
----);
--
---- mix effects and music
----mixed <= std_logic_vector(
----      unsigned("00"  & snd1 & "00") +
----      unsigned("0"   & snd2 & "000000000")+
----      unsigned("00"  & snd3 & "00")+
----      unsigned("00"  & song & "00" ));
--
---- select sound or/and effect
----with audio_select select
----audio <= "00"   & snd1  & "00"        when "100",
----         "0"    & snd2  & "000000000" when "101",
----         "00"   & snd3  & "00"        when "110",
----         "00"  &  song  & "00"        when "111",
----                  mixed               when others;
--

end struct;
