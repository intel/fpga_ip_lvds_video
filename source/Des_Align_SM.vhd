--
-- VHDL Architecture: Des_Align_SM
--
-- Description:
--   Data Alignment State Machine for the RX OpenLDI Deserializer
--   This block sends a series of pulses to bit-slip the deserializer
--   to the proper byte alignment.
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
use ieee.std_logic_unsigned.all;

entity Des_Align_SM is
  generic (
    G_ALIGNMENT_VEC : std_logic_vector(11 downto 0) := "000000000000");
  port 
  (
    CLK        : in std_logic;
    RESET      : in std_logic;
    SLIP_ALGNR : in std_logic;
    SLIP_ACK   : out std_logic;
    DATA_ALIGN : out std_logic
  );

end entity;

architecture rtl of Des_Align_SM is
  signal wait_counter : std_logic_vector(3 downto 0);
  signal data_align_q : std_logic_vector(11 downto 0);
  signal slip_ack_q   : std_logic;

begin
  -- This process resets the alignment circuitry in the deserializer, and then
  --   slips it by the predetermined amount, specified in "G_ALIGNMENT_VEC".
  --   It also accepts an external slip request for further adjustment.
  P_WaitCnt: process(RESET, CLK)
  begin
    if (RESET = '1') then
      wait_counter <= (others => '0');
      data_align_q <= G_ALIGNMENT_VEC;
      slip_ack_q   <= '0';
    elsif (CLK'event and CLK = '1') then
      -- Once our counter saturates, send the byte alignment sequence.
      if (wait_counter = "111") then
        wait_counter <= wait_counter;
        -- Has a request been made to further bit-slip the aligner?
        if (SLIP_ALGNR = '1') then
          -- Do we need to service this request?
          if (slip_ack_q = '0') then
            -- Only slip the aligner if the MSB is '0'
            if (data_align_q(11) = '0') then
              slip_ack_q   <= '1';
              data_align_q <= '1' & data_align_q(11 downto 1);
            else
              slip_ack_q   <= '0';
              data_align_q <= '0' & data_align_q(11 downto 1);
            end if;
          -- We have already serviced this, hold ack until the request is cleared
          else
            slip_ack_q   <= '1';
            data_align_q <= '0' & data_align_q(11 downto 1);
          end if;
        else
          slip_ack_q   <= '0';
          data_align_q <= '0' & data_align_q(11 downto 1);
        end if;
      -- If we haven't reached the terminal count, keep counting...
      else
        slip_ack_q   <= '0';
        wait_counter <= wait_counter + '1';
        data_align_q <= data_align_q;
      end if;
    end if;
  end process P_WaitCnt;

  -- Assign internal signals to outputs
  SLIP_ACK   <= slip_ack_q;
  DATA_ALIGN <= data_align_q(0);

end rtl;
