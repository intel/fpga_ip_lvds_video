--
-- VHDL Architecture: openldi2rgb
--
-- Description:
--   OpenLDI to RGB 8:8:8 Conversion - Demuxes the OpenLDI stream into
--   an RGB 8:8:8 output.
--
------------------------------------------------------------------------------------
-- Copyright (c) 2021 Intel Corporation
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to
-- deal in the Software without restriction, including without limitation the
-- rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
-- sell copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
-- IN THE SOFTWARE.
--
------------------------------------------------------------------------------------
--
library ieee;
use ieee.std_logic_1164.all;

entity openldi2rgb is
  port 
  (
    CLK       : in std_logic;
    MODE      : in std_logic;
    RES_18BPP : in std_logic;
    LDIDATA   : in std_logic_vector(55 downto 0);
    RGB_RU    : out std_logic_vector(7 downto 0);
    RGB_GU    : out std_logic_vector(7 downto 0);
    RGB_BU    : out std_logic_vector(7 downto 0);
    RGB_RL    : out std_logic_vector(7 downto 0);
    RGB_GL    : out std_logic_vector(7 downto 0);
    RGB_BL    : out std_logic_vector(7 downto 0);
    RGB_CNTLE : out std_logic;
    RGB_CNTLF : out std_logic;
    RGB_DE    : out std_logic_vector(1 downto 0);
    RGB_VSYNC : out std_logic_vector(1 downto 0);
    RGB_HSYNC : out std_logic_vector(1 downto 0)
  );

end entity;

architecture rtl of openldi2rgb is
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
  ldi_a <= LDIDATA( 6 downto  0);
  ldi_b <= LDIDATA(13 downto  7);
  ldi_c <= LDIDATA(20 downto 14);
  ldi_d <= LDIDATA(27 downto 21);
  ldi_e <= LDIDATA(34 downto 28);
  ldi_f <= LDIDATA(41 downto 35);
  ldi_g <= LDIDATA(48 downto 42);
  ldi_h <= LDIDATA(55 downto 49);
  
  -- Demux timing signals
  RGB_CNTLE <= ldi_g(4);
  RGB_CNTLF <= ldi_g(5);
  RGB_DE    <= (others => ldi_c(6));
  RGB_VSYNC <= (others => ldi_c(5));
  RGB_HSYNC <= (others => ldi_c(4));
  
  P_RGBOUT: process (ldi_a, ldi_b, ldi_c, ldi_d, ldi_e, ldi_f, ldi_g, ldi_h, MODE, RES_18BPP)
  begin
    if (MODE = '0') then
      if (RES_18BPP = '0') then
        -- Demux video RGB data, per SPWG/PSWG/VESA 24 bpp data mapping
        RGB_RU <= (ldi_d(1 downto 0) & ldi_a(5 downto 0));
        RGB_GU <= (ldi_d(3 downto 2) & ldi_b(4 downto 0) & ldi_a(6));
        RGB_BU <= (ldi_d(5 downto 4) & ldi_c(3 downto 0) & ldi_b(6 downto 5));
        RGB_RL <= (ldi_h(1 downto 0) & ldi_e(5 downto 0));
        RGB_GL <= (ldi_h(3 downto 2) & ldi_f(4 downto 0) & ldi_e(6));
        RGB_BL <= (ldi_h(5 downto 4) & ldi_g(3 downto 0) & ldi_f(6 downto 5));
      else
        -- Demux video RGB data, per SPWG/PSWG/VESA 18 bpp data mapping
        RGB_RU <= (ldi_a(5 downto 0) & "00");
        RGB_GU <= (ldi_b(4 downto 0) & ldi_a(6) & "00");
        RGB_BU <= (ldi_c(3 downto 0) & ldi_b(6 downto 5) & "00");
        RGB_RL <= (ldi_e(5 downto 0) & "00");
        RGB_GL <= (ldi_f(4 downto 0) & ldi_e(6) & "00");
        RGB_BL <= (ldi_g(3 downto 0) & ldi_f(6 downto 5) & "00");
      end if;
    else
      -- Demux video RGB data, per JEIDA 24 bpp data mapping
      RGB_RU <= (ldi_a(5 downto 0) & ldi_d(1 downto 0) );
      RGB_GU <= (ldi_b(4 downto 0) & ldi_a(6) & ldi_d(3 downto 2));
      RGB_BU <= (ldi_c(3 downto 0) & ldi_b(6 downto 5) & ldi_d(5 downto 4));
      RGB_RL <= (ldi_e(5 downto 0) & ldi_h(1 downto 0) );
      RGB_GL <= (ldi_f(4 downto 0) & ldi_e(6) & ldi_h(3 downto 2));
      RGB_BL <= (ldi_g(3 downto 0) & ldi_f(6 downto 5) & ldi_h(5 downto 4));
    end if;
  end process P_RGBOUT;

end rtl;
