library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.all;
use work.LogicAnalyserPackage.all;
 
entity SDRAM_controller_tb is
end entity;
 
architecture behavior of SDRAM_controller_tb is 

   -- Inputs
   signal clock_100MHz     : std_logic := '0';
   signal clock_100MHz_n   : std_logic := '1';
   signal reset            : std_logic := '0';
   signal cmd_enable       : std_logic := '0';
   signal cmd_wr           : std_logic := '0';
   signal cmd_address      : sdram_AddrType := (others => '0');
   signal cmd_dataIn       : sdram_DataType := (others => '0');

	-- Bidirs
   signal sdram_data       : sdram_phy_DataType := (others => 'Z');

 	-- Outputs
   signal cmd_done         : std_logic;
   signal intializing      : std_logic;
   signal cmd_dataOut      : sdram_phy_DataType;
   signal cmd_dataOutReady : std_logic;
   signal sdram_clk        : std_logic;
   signal sdram_cke        : std_logic;
   signal sdram_cs         : std_logic;
   signal sdram_ras_n      : std_logic;
   signal sdram_cas_n      : std_logic;
   signal sdram_we_n       : std_logic;
   signal sdram_dqm        : sdram_phy_ByteSelType;
   signal sdram_addr       : sdram_phy_AddrType;
   signal sdram_ba         : sdram_phy_BankSelType;

   -- Clock period definitions
   constant clock_period   : time     := 10 ns;
   signal   complete       : boolean  := false;
 
   signal   status : string (1 to 6);

begin
 
	-- instantiate the unit under test (uut)
   uut: 
   entity work.SDRAM_controller 
      port map (
          clock_100MHz     => clock_100MHz,
          clock_100MHz_n   => clock_100MHz_n,
          reset            => reset,
          cmd_done         => cmd_done,
          cmd_enable       => cmd_enable,
          cmd_wr           => cmd_wr,
          cmd_address      => cmd_address,
          cmd_dataIn       => cmd_dataIn,
          cmd_dataOut      => cmd_dataOut,
          cmd_dataOutReady => cmd_dataOutReady,
          intializing      => intializing,
          
          sdram_clk        => sdram_clk,
          sdram_cke        => sdram_cke,
          sdram_cs         => sdram_cs,
          sdram_ras_n      => sdram_ras_n,
          sdram_cas_n      => sdram_cas_n,
          sdram_we_n       => sdram_we_n,
          sdram_dqm        => sdram_dqm,
          sdram_addr       => sdram_addr,
          sdram_ba         => sdram_ba,
          sdram_data       => sdram_data
      );

   clock_100MHz_n <= clock_100MHz;
   
   -- Clock process definitions
   Clock_process :
   process
   begin
      while not complete loop
         clock_100MHz <= '1';
         wait for clock_period/2;
         clock_100MHz <= '0';
         wait for clock_period/2;
      end loop;
      -- kill clock
      wait;
   end process; 
  
   sdramProc:
   process(sdram_we_n, sdram_dqm, sdram_clk, sdram_cke, sdram_cs)
      constant latency : natural := 2;
      
      type readQueueType is array(latency-1 downto 0) of sdram_phy_DataType;
      variable readQueue               : readQueueType                              := (others => (others => '0'));
      variable readValue               : unsigned(SDRAM_PHY_DATA_WIDTH-1 downto 0)  := x"1230";
      variable readQueueDataAvailable  : std_logic_vector(latency-1 downto 0);
      variable command                 : std_logic_vector(3 downto 0);
      constant CmdValue_READ           : std_logic_vector(3 downto 0)               := "0101";
      constant invalidData             : sdram_phy_DataType                         := (others => 'X');
      
   begin
      command := sdram_cs&sdram_ras_n&sdram_cas_n&sdram_we_n;
      
      if rising_edge(sdram_clk) then
         readQueueDataAvailable := '0'&readQueueDataAvailable(readQueueDataAvailable'left downto 1);
         if ((command = CmdValue_READ) and (sdram_dqm = "00")) then
            readValue := readValue + 1;
            readQueueDataAvailable(readQueueDataAvailable'left) := '1';
            readQueue := std_logic_vector(readValue) & readQueue(readQueue'left downto 1);
         else
            readQueue := std_logic_vector(invalidData) & readQueue(readQueue'left downto 1);
         end if;
      end if;
      if (readQueueDataAvailable(0) = '1') then
         sdram_data <= readQueue(readQueue'right);
      else
         sdram_data <= (others => 'Z');
      end if;
   end process;
   
   -- Stimulus process
   Stim_proc: process
   
   procedure write(addr : sdram_AddrType; data : sdram_DataType) is
   begin
      cmd_address <= addr;
      cmd_dataIn  <= data;
      cmd_enable  <= '1';
      cmd_wr      <= '1';
      wait until rising_edge(clock_100MHz) and (cmd_done = '1');
      wait for 1 ns;
      cmd_address <= (others => 'X');
      cmd_dataIn  <= (others => 'X');
      cmd_enable  <= '0';
      cmd_wr      <= 'X';
   end procedure;
       
   procedure read(addr : sdram_AddrType; data : out sdram_DataType) is
   begin
      cmd_address <= addr;
      cmd_enable  <= '1';
      cmd_wr      <= '0';
      wait until rising_edge(clock_100MHz) and (cmd_done = '1');
      wait for 1 ns;
      cmd_address <= (others => 'X');
      cmd_dataIn  <= (others => 'X');
      cmd_enable  <= '0';
      cmd_wr      <= 'X';
   end procedure;
       
   variable readDatareadData : sdram_DataType;
   
   begin		
      status <= "RESET ";

      reset <= '1';
      wait for clock_period*10;
      reset <= '0';
      wait for clock_period;

      wait until rising_edge(clock_100MHz);
      if (intializing = '1') then
         wait until intializing = '0';
      end if;
      
      status <= "ft2232h_wr A1 ";
      write(x"031010", x"1234");
      status <= "ft2232h_wr A2 ";
      write(x"031012", x"5678");
      status <= "ft2232h_wr A3 ";
      write(x"031014", x"9ABC");
      status <= "ft2232h_wr A4 ";
      write(x"031016", x"DEF0");
      status <= "ft2232h_wr B1 ";
      write(x"041010", x"9ABC");
      status <= "ft2232h_wr B2 ";
      write(x"041012", x"DEF0");
      status <= "ft2232h_wr C1 ";
      write(x"061010", x"9876");
      status <= "ft2232h_wr C2 ";
      write(x"071010", x"5432");
      
      status <= "RD A1 ";
      read(x"A71010", readDatareadData);
      status <= "RD A2 ";
      read(x"A71010", readDatareadData);
      status <= "RD A3 ";
      read(x"A71010", readDatareadData);
      status <= "RD A4 ";
      read(x"A71010", readDatareadData);

      status <= "RD A1 ";
      read(x"2F1010", readDatareadData);
      status <= "RD A2 ";
      read(x"2F1010", readDatareadData);
      status <= "RD A3 ";
      read(x"2F1010", readDatareadData);
      status <= "RD A4 ";
      read(x"2F1010", readDatareadData);

      status <= "DONE  ";
      
      wait for clock_period*10;

      complete <= true;
      wait for 10 ns;
      wait;
   end process;

end;
