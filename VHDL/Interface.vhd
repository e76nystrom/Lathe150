library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_arith;

entity CFSInterface is
 generic (opBits   : positive := 8;
          lenBits  : positive := 8;
          dataBits : positive := 32);
 port (
  clk     : in std_logic;               --clock
  re      : in std_ulogic;              --read request
  we      : in std_ulogic;              --write request
  reg     : in std_logic_vector(1 downto 0); --register number

  CFSdataIn  : in  std_ulogic_vector(31 downto 0); --cfs data in
  CFSdataOut : out std_ulogic_vector(31 downto 0); --cfs ddata out

  op         : out unsigned(opBits-1 downto 0); --register number
  dIn        : in  std_logic;           --input data
  shift      : out std_logic := '0';    --shift data
  copy       : out std_logic := '0';    --copy input data
  load       : out std_logic := '0';    --load output data
  dOut       : out std_logic := '0'     --output data
  );
end CFSInterface;

architecture Behavorial of CFSInterface is

 type sendFSM is (sIdle, sSend, SLoad);
 signal sendState : sendFSM := sIdle;

 type recvFSM is (rIdle, rCopy, rRecv);
 signal recvState : recvFSM := rIdle;

 signal sCount  : unsigned(lenBits-1 downto 0);
 signal rCount  : unsigned(lenBits-1 downto 0);

 signal dataOut : std_logic_vector(dataBits-1 downto 0);
 signal dataIn  : std_logic_vector(dataBits-1 downto 0);

 signal send    : std_logic := '0';
 signal recv    : std_logic := '0';

begin

 dOut <= dataOut(dataBits-1);

 data: process(clk)
 begin
  if (rising_edge(clk)) then            --if clock active
   if (we = '1') then                   --if write
    case reg  is                        --select operatin
     when "11" =>                       --if load op register
      op <= unsigned(CFSDataIn(opBits-1 downto 0)); --set op register
      if (CFSDataIn(opBits) = '0') then
       send <= '1';
      else
       recv <= '1';
      end if;

     when "01" =>                       --if data out
      dataOut <= std_logic_vector(CFSDataIn); --load data out register

     when others => null;
    end case;
   end if;

   if (re = '1') then                   --if read
    case reg  is                        --select operatin
     when "11" =>                       --if read
      CFSDataOut <= std_ulogic_vector(dataIn); --read data register

     when others => null;
    end case;
   end if;

   case sendState is
    when sIdle =>                       --idle
     if (send = '1') then
      sCount <= to_unsigned(dataBits, lenBits);
      shift <= '1';
      sendState <= sSend;
     end if;

    when sSend =>                       --send data
     if (sCount /= 0) then
      sCount <= sCount - 1;
      dataOut <= dataOut(dataBits-2 downto 0) & dataOut(dataBits-1);
     else
      shift <= '0';
      load <= '1';
      sendState <= sLoad;
     end if;

    when sLoad =>                       --load data
     load <= '0';
     send <= '0';
     op <= (others => '0');
     sendState <= sIdle;

    when others =>
     sendState <= sIdle;
   end case;

   case recvState is
    when rIdle =>
     if (recv = '1') then
      copy <= '1';
      recvState <= rCopy;
     end if;

    when rCopy =>
     copy <= '0';
     rCount <= to_unsigned(dataBits, lenBits);
     shift <= '1';
     recvState <= rRecv;

    when rRecv =>
     if (rCount /= 0) then
      rCount <= rCount - 1;
      dataIn <=  dataIn(dataBits-2 downto 0) & dIn;
     else
      shift <= '0';
      recv = '0';
      op <= (others => '0');
      recvState <= rIdle;
     end if;
   end case;

  end if;
 end process;

end Behavorial;
