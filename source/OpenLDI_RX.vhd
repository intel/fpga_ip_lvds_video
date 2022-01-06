--
-- VHDL Architecture: OpenLDI_RX
--
-- Description:
--   Top Level Reference Design for non-blocking 4:2 OpenLDI Mux
--   with OpenLDI and RGB888 output, and I2C-like control interface
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
USE ieee.std_logic_unsigned.all;

entity OpenLDI_RX is 
  generic (
    G_BITS_PER_PIXEL : integer := 24;
    G_JEIDA_MAP      : std_logic := '0';
    G_DUALPIXEL      : integer := 0;
    G_BALANCED       : std_logic := '0';
    G_ALIGNMENT_VEC  : std_logic_vector(11 downto 0) := "000000000000");
  port
  (
    RESET         :  in  std_logic;
    LDI_CLK_IN    :  in  std_logic;
    LDI_DATA_IN   :  in  std_logic_vector(G_DUALPIXEL*4 + 3 downto 0);
    LDIPLL_LOCKED :  out  std_logic;
    SLIP_ALGNR    :  in  std_logic;
    SLIP_ACK      :  out  std_logic;
    RGB_PCLK     :  out std_logic;
    RGB_DATA     :  out std_logic_vector(G_BITS_PER_PIXEL -1 downto 0);
    RGB_DE       :  out std_logic;
    RGB_VSYNC    :  out std_logic;
    RGB_HSYNC    :  out std_logic
  );
end OpenLDI_RX;

architecture rtl of OpenLDI_RX is 
  component Des_Align_SM
    generic (
      G_ALIGNMENT_VEC : std_logic_vector(11 downto 0) := "000000000000");
    port ( 
      CLK        : in std_logic;
      RESET      : in std_logic;
      SLIP_ALGNR : in std_logic;
      SLIP_ACK   : out std_logic;
      DATA_ALIGN : out std_logic);
    end component;

  component LDI_RXLVDS
    port(pll_areset            : IN STD_LOGIC ;
         rx_channel_data_align : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
         rx_in                 : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
         rx_inclock            : IN STD_LOGIC ;
         rx_locked             : OUT STD_LOGIC ;
         rx_out                : OUT STD_LOGIC_VECTOR (27 DOWNTO 0);
         rx_outclock           : OUT STD_LOGIC);
  end component;

  component openldi2rgb
    port(
      CLK        : in std_logic;
      MODE       : in std_logic;
      RES_18BPP  : in std_logic;
      LDIDATA    : in std_logic_vector(27 downto 0);
      RGB_R     : out std_logic_vector(7 downto 0);
      RGB_G     : out std_logic_vector(7 downto 0);
      RGB_B     : out std_logic_vector(7 downto 0);
      RGB_DE    : out std_logic;
      RGB_VSYNC : out std_logic;
      RGB_HSYNC : out std_logic);
  end component;

  signal  reset_n             :  std_logic;
  signal  reset_int           :  std_logic;
  signal  ldipll_locked_int   :  std_logic;
  signal  rx_align            :  std_logic;
  signal  ldi_pclk            :  std_logic;
  signal  ldi_parallel        :  std_logic_vector(G_BITS_PER_PIXEL - 1 downto 0);
  signal  ldi_parallel_q      :  std_logic_vector(G_BITS_PER_PIXEL - 1 downto 0);
  signal  rx_align_bus        :  std_logic_vector(G_DUALPIXEL*4 + 3 downto 0);
  signal  res_18bpp           :  std_logic;


begin
  -- Combine the internal reset with the state of the RXPLL locked signal
  reset_int <= RESET or NOT ldipll_locked_int;
  reset_n   <= not reset_int;

  -- Byte Alignment State Machine for the RX Deserializer
  U_RXLDI_ALIGN : Des_Align_SM
  generic map(G_ALIGNMENT_VEC => "000010101010")
  port map(CLK        => ldi_pclk,
           RESET      => reset_int,
           SLIP_ALGNR => SLIP_ALGNR,
           SLIP_ACK   => SLIP_ACK,
           DATA_ALIGN => rx_align);

  rx_align_bus <= (others => rx_align);

  -- Deserializer for the OpenLDI interface
  U_RXLDI : LDI_RXLVDS
  port map(pll_areset            => RESET,
           rx_channel_data_align => rx_align_bus,
           rx_inclock            => LDI_CLK_IN,
           rx_in                 => LDI_DATA_IN,
           rx_locked             => ldipll_locked_int,
           rx_outclock           => ldi_pclk,
           rx_out                => ldi_parallel);

  LDIPLL_LOCKED <= ldipll_locked_int;

  -- Register the incoming deserialized OpenLDI data to the read clock, which
  --   is required by the ALTLVDS user guide.
  P_RXLDI_BUF: process (reset_int, ldi_pclk)
  begin
    if (reset_int = '1') then
      ldi_parallel_q <= (others => '0');
    elsif (ldi_pclk'event and ldi_pclk= '1') then 
      ldi_parallel_q <= ldi_parallel;
    end if;
  end process P_RXLDI_BUF;

  res_18bpp <= '1' when (G_BITS_PER_PIXEL = 18) else '0';

  -- Decodes OpenLDI data into a parallel RGB888 
  U_TXRGB : openldi2rgb
  port map(CLK        => ldi_pclk,
           MODE       => G_JEIDA_MAP,
           RES_18BPP  => res_18bpp,
           LDIDATA    => ldi_parallel_q,
           RGB_R(G_BITS_PER_PIXEL/3 - 1  downto 0) => RGB_DATA(G_BITS_PER_PIXEL -1     downto G_BITS_PER_PIXEL/3*2),
           RGB_G(G_BITS_PER_PIXEL/3 - 1  downto 0) => RGB_DATA(G_BITS_PER_PIXEL/3*2 -1 downto G_BITS_PER_PIXEL/3),
           RGB_B(G_BITS_PER_PIXEL/3 - 1  downto 0) => RGB_DATA(G_BITS_PER_PIXEL/3 - 1  downto 0),
           RGB_DE    => RGB_DE,
           RGB_VSYNC => RGB_VSYNC,
           RGB_HSYNC => RGB_HSYNC);

  RGB_PCLK <= ldi_pclk;

end rtl;
