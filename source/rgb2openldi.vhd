--
-- VHDL Architecture: rgb2openldi
--
-- Description:
--   OpenLDI to RGB 8:8:8 Conversion - Muxes the RGB 8:8:8 input into the OpenLDI 
--     output stream.
--
-- Software Reference Design Files Header Notice/License
-- Copyright ©2014 Altera Corporation, San Jose, California, USA. All rights reserved.  
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to use,
-- copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
-- Software, and to permit persons to whom the Software is furnished to do so,
-- subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
-- INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
-- PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
-- HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
-- OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--
-- This agreement shall be governed in all respects by the laws of the State of
-- California and by the laws of the United States of America
--
library ieee;
use ieee.std_logic_1164.all;

entity rgb2openldi is
  port 
  (
    CLK       : in std_logic;
    MODE      : in std_logic;
    RES_18BPP : in std_logic;
    LDIDATA   : out std_logic_vector(55 downto 0);
    RGB_RU    : in std_logic_vector(7 downto 0);
    RGB_GU    : in std_logic_vector(7 downto 0);
    RGB_BU    : in std_logic_vector(7 downto 0);
    RGB_RL    : in std_logic_vector(7 downto 0);
    RGB_GL    : in std_logic_vector(7 downto 0);
    RGB_BL    : in std_logic_vector(7 downto 0);
    RGB_CNTLE : in std_logic;
    RGB_CNTLF : in std_logic;
    RGB_DE    : in std_logic_vector(1 downto 0);
    RGB_VSYNC : in std_logic_vector(1 downto 0);
    RGB_HSYNC : in std_logic_vector(1 downto 0)
  );

end entity;

architecture rtl of rgb2openldi is
  signal ldi_a : std_logic_vector(6 downto 0);
  signal ldi_b : std_logic_vector(6 downto 0);
  signal ldi_c : std_logic_vector(6 downto 0);
  signal ldi_d : std_logic_vector(6 downto 0);
  signal ldi_e : std_logic_vector(6 downto 0);
  signal ldi_f : std_logic_vector(6 downto 0);
  signal ldi_g : std_logic_vector(6 downto 0);
  signal ldi_h : std_logic_vector(6 downto 0);
begin
  -- Split OpenLDI bus into its four components, for clarity sake
  LDIDATA <= ldi_h & ldi_g & ldi_f & ldi_e & ldi_d & ldi_c & ldi_b & ldi_a when (RES_18BPP = '0') else
          "00000000000000" & ldi_g & ldi_f & ldi_e & ldi_c & ldi_b & ldi_a;
  
  P_OLDIOUT: process (RGB_RU, RGB_GU, RGB_BU, RGB_RL, RGB_GL, RGB_BL, RGB_CNTLE, RGB_CNTLF, RGB_DE, RGB_VSYNC, RGB_HSYNC, MODE, RES_18BPP)
  begin
    if (MODE = '0') then
      if (RES_18BPP = '0') then
        -- Demux video RGB data, per SPWG/PSWG/VESA 24 bpp data mapping
        ldi_a <= (RGB_GU(0) & RGB_RU(5 downto 0));
        ldi_b <= (RGB_BU(1 downto 0) & RGB_GU(5 downto 1));
        ldi_c <= (RGB_DE(0) & RGB_VSYNC(0) & RGB_HSYNC(0) & RGB_BU(5 downto 2));
        ldi_d <= ('0' & RGB_BU(7 downto 6) & RGB_GU(7 downto 6) & RGB_RU(7 downto 6));
        ldi_e <= (RGB_GL(0) & RGB_RL(5 downto 0));
        ldi_f <= (RGB_BL(1 downto 0) & RGB_GL(5 downto 1));
        ldi_g <= ('0' & RGB_CNTLF & RGB_CNTLE & RGB_BL(5 downto 2));
        ldi_h <= ('0' & RGB_BL(7 downto 6) & RGB_GL(7 downto 6) & RGB_RL(7 downto 6));
      else
        -- Demux video RGB data, per SPWG/PSWG/VESA 18 bpp data mapping
        ldi_a <= (RGB_GU(0) & RGB_RU(5 downto 0));
        ldi_b <= (RGB_BU(1 downto 0) & RGB_GU(5 downto 1));
        ldi_c <= (RGB_DE(0) & RGB_VSYNC(0) & RGB_HSYNC(0) & RGB_BU(5 downto 2));
        ldi_d <= (others => '0');
        ldi_e <= (RGB_GL(0) & RGB_RL(5 downto 0));
        ldi_f <= (RGB_BL(1 downto 0) & RGB_GL(5 downto 1));
        ldi_g <= ('0' & RGB_CNTLF & RGB_CNTLE & RGB_BL(5 downto 2));
        ldi_h <= (others => '0');
      end if;
    else
      -- Demux video RGB data, per JEIDA 24 bpp data mapping
      ldi_a <= (RGB_GU(2) & RGB_RU(7 downto 2));
      ldi_b <= (RGB_BU(3 downto 2) & RGB_GU(7 downto 3));
      ldi_c <= (RGB_DE(0) & RGB_VSYNC(0) & RGB_HSYNC(0) & RGB_BU(7 downto 4));
      ldi_d <= ('0' & RGB_BU(1 downto 0) & RGB_GU(1 downto 0) & RGB_RU(1 downto 0));
      ldi_e <= (RGB_GL(2) & RGB_RL(7 downto 2));
      ldi_f <= (RGB_BL(3 downto 2) & RGB_GL(7 downto 3));
      ldi_g <= ('0' & RGB_CNTLF & RGB_CNTLE & RGB_BL(7 downto 4));
      ldi_h <= ('0' & RGB_BL(1 downto 0) & RGB_GL(1 downto 0) & RGB_RL(1 downto 0));
    end if;
  end process P_OLDIOUT;

end rtl;
