library ieee;

use ieee.std_logic_1164.all;

entity SystemClk is
 port (
  inclk  : in  std_logic;               -- inclk
  outclk : out std_logic                -- outclk
  );
end SystemClk;

architecture Behavioral of SystemClk is

begin 

 outClk <= inClk;
 
end behavioral;
