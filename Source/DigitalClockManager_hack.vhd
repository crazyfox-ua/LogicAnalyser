library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity DigitalClockManager is
port
 (-- Clock in ports
  CLK_IN1           : in     std_logic;
  -- Clock out ports
  CLK_OUT1          : out    std_logic;
  -- Status and control signals
  RESET             : in     std_logic;
  LOCKED            : out    std_logic
 );
end DigitalClockManager;

architecture xilinx of DigitalClockManager is
  
  constant CLOCK_PERIOD : time := 10 ns;

begin
   LOCKED <= not RESET;
  
   process
   begin
      CLK_OUT1 <= '0';
      wait until reset = '0';
      loop
        CLK_OUT1 <= '0';
        wait for CLOCK_PERIOD/2;
        CLK_OUT1 <= '1';
        wait for CLOCK_PERIOD/2;
      end loop;
   end process;
end xilinx;