---------------------------------------------------------------------------------
-- DE1_soc Top level Naughty boy by Dar (darfpga@aol.fr) (30/01/2025)
-- http://darfpga.blogspot.fr
---------------------------------------------------------------------------------
-- Educational use only
-- Do not redistribute synthetized file with roms
-- Do not redistribute roms whatever the form
-- Use at your own risk
---------------------------------------------------------------------------------
-- Use Naughty_boy_de1_soc.sdc to compile (Timequest constraints)
-- /!\
-- Don't forget to set device configuration mode with memory initialization 
--  (Assignments/Device/Pin options/Configuration mode)
---------------------------------------------------------------------------------
--  bb    eeee   tttttt  aaa         ww   ww    ww   iiiiii  pppp 
--  bb    ee     tttttt aaaaa         ww wwww  ww    iiiiii  p  p
--  bbbb  eeee     tt   aa aa  ----   ww ww ww ww      ii    pppp
--  b  b  ee       tt   aaaaa          www   www     iiiiii  p 
--  bbbb  eeee     tt   aa aa          www   www     iiiiii  p
---------------------------------------------------------------------------------
--
-- Main features :
--  PS2 keyboard input @gpio pins 35/34 (beware voltage translation/protection) 
--  Audio pwm output   @gpio pins 1/3 (beware voltage translation/protection) 
--
-- Uses 1 pll for 12MHz generation from 50MHz
--
-- Board key :
--   0 : reset game
--
-- Board switch : sw(7 downto 0)
-- --------------------------------------------------------
--|Option |Factory|Descrpt| 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
-- ------------------------|-------------------------------
--|Lives  |       |2      |on |on |   |   |   |   |   |   |
-- ------------------------ -------------------------------
--|       |   X   |3      |off|on |   |   |   |   |   |   |
-- ------------------------ -------------------------------
--|       |       |4      |on |off|   |   |   |   |   |   |
-- ------------------------ -------------------------------
--|       |       |5      |off|off|   |   |   |   |   |   |
-- ------------------------ -------------------------------
--|Extra  |       |10000  |   |   |on |on |   |   |   |   |
-- ------------------------ -------------------------------
--|       |   X   |30000  |   |   |off|on |   |   |   |   |
-- ------------------------ -------------------------------
--|       |       |50000  |   |   |on |off|   |   |   |   |
-- ------------------------ -------------------------------
--|       |       |70000  |   |   |off|off|   |   |   |   |
-- ------------------------ -------------------------------
--|Credits|       |2c, 1p |   |   |   |   |on |on |   |   |
-- ------------------------ -------------------------------
--|       |   X   |1c, 1p |   |   |   |   |off|on |   |   |
-- ------------------------ -------------------------------
--|       |       |1c, 2p |   |   |   |   |on |off|   |   |
-- ------------------------ -------------------------------
--|       |       |4c, 3p |   |   |   |   |off|off|   |   |
-- ------------------------ -------------------------------
--|Dffclty|   X   |Easier |   |   |   |   |   |   |on |   |
-- ------------------------ -------------------------------
--|       |       |Harder |   |   |   |   |   |   |off|   |
-- ------------------------ -------------------------------
--| Type  |       |Upright|   |   |   |   |   |   |   |on |
-- ------------------------ -------------------------------
--|       |       |Cktail |   |   |   |   |   |   |   |off|
-- ------------------------ -------------------------------
--
--  sw(9) : 15/31kHz select
--
-- Other details : see phoenix.vhd
-- For USB inputs and SGT5000 audio output see my other project: xevious_de10_lite
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;

entity naughty_boy_de1_soc is
port(
 clock_50  : in std_logic;
-- max10_clk2_50  : in std_logic;
-- adc_clk_10     : in std_logic;
 ledr           : out std_logic_vector(9 downto 0);
 key            : in std_logic_vector(3 downto 0);
 sw             : in std_logic_vector(9 downto 0);

-- dram_ba    : out std_logic_vector(1 downto 0);
-- dram_ldqm  : out std_logic;
-- dram_udqm  : out std_logic;
-- dram_ras_n : out std_logic;
-- dram_cas_n : out std_logic;
-- dram_cke   : out std_logic;
-- dram_clk   : out std_logic;
-- dram_we_n  : out std_logic;
-- dram_cs_n  : out std_logic;
-- dram_dq    : inout std_logic_vector(15 downto 0);
-- dram_addr  : out std_logic_vector(12 downto 0);

-- hex0 : out std_logic_vector(7 downto 0);
-- hex1 : out std_logic_vector(7 downto 0);
-- hex2 : out std_logic_vector(7 downto 0);
-- hex3 : out std_logic_vector(7 downto 0);
-- hex4 : out std_logic_vector(7 downto 0);
-- hex5 : out std_logic_vector(7 downto 0);

 vga_r       : out std_logic_vector(7 downto 0);
 vga_g       : out std_logic_vector(7 downto 0);
 vga_b       : out std_logic_vector(7 downto 0);
 vga_hs      : out std_logic;
 vga_vs      : out std_logic;
 vga_blank_n : out std_logic;
 vga_sync_n  : out std_logic;
 vga_clk     : out std_logic;
 
-- gsensor_cs_n : out   std_logic;
-- gsensor_int  : in    std_logic_vector(2 downto 0); 
-- gsensor_sdi  : inout std_logic;
-- gsensor_sdo  : inout std_logic;
-- gsensor_sclk : out   std_logic;

-- arduino_io      : inout std_logic_vector(15 downto 0); 
-- arduino_reset_n : inout std_logic;
 
-- gpio          : inout std_logic_vector(35 downto 0)

 ps2_clk : in std_logic;
 ps2_dat : in std_logic
 
);
end naughty_boy_de1_soc;

architecture struct of naughty_boy_de1_soc is


 signal clk12  : std_logic;
 signal pll_locked :std_logic;
 
 signal r         : std_logic_vector(1 downto 0);
 signal g         : std_logic_vector(1 downto 0);
 signal b         : std_logic_vector(1 downto 0);
 signal video_clk : std_logic;
 signal hsync     : std_logic;
 signal vsync     : std_logic;
 signal csync     : std_logic;
 
 signal reset        : std_logic;
 signal tv15kHz_mode : std_logic;
 
 alias  dip_switch   : std_logic_vector(7 downto 0) is sw(7 downto 0);
 
 signal kbd_intr      : std_logic;
 signal kbd_scancode  : std_logic_vector(7 downto 0);
 signal JoyPCFRLDU    : std_logic_vector(7 downto 0);

 signal coin     : std_logic;
 signal starts   : std_logic_vector(1 downto 0);
 signal buttons  : std_logic_vector(4 downto 0);
 
 signal audio           : std_logic_vector(11 downto 0);
 signal pwm_accumulator : std_logic_vector(12 downto 0);

 alias reset_n         : std_logic is key(0);

 signal video_15kHz : std_logic_vector(5 downto 0);
 signal ce_pix      : std_logic;
 signal video_31kHz : std_logic_vector(5 downto 0);
 signal hsync_31kHz : std_logic;
 
-- signal dbg_cpu_addr : std_logic_vector(15 downto 0);

begin

reset <= not reset_n;
tv15kHz_mode <= sw(9);

-- Clock 11MHz for Phoenix core
clocks : entity work.de1_soc_pll_12m
port map( 
 refclk   => clock_50, --  refclk.clk
 rst      => '0',      --   reset.reset
 outclk_0 => clk12,    -- outclk0.clk
 locked   => open      --  locked.export
);

naughty_boy : entity work.naughty_boy
port map(
 clock_50     => clock_50,
 clock_12     => clk12,
 reset        => reset,
-- tv15kHz_mode => tv15kHz_mode,
 dip_switch   => sw(7 downto 0),
 coin         => coin,
 starts       => starts,
 player1_btns => buttons,
 player2_btns => buttons,
 video_r      => r,
 video_g      => g,
 video_b      => b,
 video_csync  => csync,
 video_hs     => hsync,
 video_vs     => vsync,
 ce_pix       => ce_pix
-- audio_select => "000", --audio_select,
-- audio        => audio
);


-- line doubler
video_15kHz <= r & g & b;

doubler : entity work.line_doubler
port map(
	clock   => clk12,
	ena_pix => ce_pix,
	video_i => video_15kHz,
	hsync_i => hsync,
	video_o => video_31kHz,
	hsync_o => hsync_31kHz
);

-- adapt video to 4bits/color only
vga_r <= r&"000000" when tv15kHz_mode = '1' else video_31kHz(5 downto 4)&"000000";
vga_g <= g&"000000" when tv15kHz_mode = '1' else video_31kHz(3 downto 2)&"000000";
vga_b <= b&"000000" when tv15kHz_mode = '1' else video_31kHz(1 downto 0)&"000000";

-- synchro composite/ synchro horizontale
vga_hs <= csync when tv15kHz_mode = '1' else hsync_31kHz;
-- commutation rapide / synchro verticale
vga_vs <= '1'   when tv15kHz_mode = '1' else vsync;

vga_blank_n <= '1';
vga_sync_n  <= '0';
vga_clk     <= clk12;

-- get scancode from keyboard
keyboard : entity work.io_ps2_keyboard
port map (
  clk       => clk12,
  kbd_clk   => ps2_clk,
  kbd_dat   => ps2_dat,
  interrupt => kbd_intr,
  scancode  => kbd_scancode
);

-- translate scancode to joystick
Joystick : entity work.kbd_joystick
port map (
  clk         => clk12,
  kbdint      => kbd_intr,
  kbdscancode => std_logic_vector(kbd_scancode), 
  JoyPCFRLDU  => JoyPCFRLDU 
);

-- joystick to inputs
coin        <= not JoyPCFRLDU(7); -- F3 : Add coin
starts(1)   <= not JoyPCFRLDU(6); -- F2 : Start 2 Players
starts(0)   <= not JoyPCFRLDU(5); -- F1 : Start 1 Player
buttons(0)  <= not JoyPCFRLDU(4); -- SPACE : Fire
buttons(3)  <= not JoyPCFRLDU(3); -- RIGHT arrow : Right
buttons(4)  <= not JoyPCFRLDU(2); -- LEFT arrow  : Left
buttons(2)  <= not JoyPCFRLDU(1); -- DOWN arrow  : Down
buttons(1)  <= not JoyPCFRLDU(0); -- UP arrow    : Up
-- debug display

ledr(8 downto 0) <= "101010101";
--
--h0 : entity work.decodeur_7_seg port map(dbg_cpu_addr( 3 downto  0),hex0);
--h1 : entity work.decodeur_7_seg port map(dbg_cpu_addr( 7 downto  4),hex1);
--h2 : entity work.decodeur_7_seg port map(dbg_cpu_addr(11 downto  8),hex2);
--h3 : entity work.decodeur_7_seg port map(dbg_cpu_addr(15 downto 12),hex3);
--h4 : entity work.decodeur_7_seg port map(,hex4);
--h5 : entity work.decodeur_7_seg port map(,hex5);

-- pwm sound output

process(clk12)  -- use same clock as core
begin
  if rising_edge(clk12) then
    pwm_accumulator  <=  std_logic_vector(unsigned('0' & pwm_accumulator(11 downto 0)) + unsigned(audio & '0'));
  end if;
end process;

--pwm_audio_out_l <= pwm_accumulator(12);
--pwm_audio_out_r <= pwm_accumulator(12); 

end struct;
