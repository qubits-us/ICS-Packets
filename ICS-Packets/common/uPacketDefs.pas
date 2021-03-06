{ Packet Definitions and helpers..
  2.2.2022- q

  be it harm none, do as ye wish..

}

unit uPacketDefs;

interface
uses
  Winapi.Windows, Winapi.Messages,System.SysUtils, System.Classes, System.SyncObjs, OverbyteIcsWndControl, OverbyteIcsWSocket,
   OverbyteIcsWSocketS, OverbyteIcsWSocketTS,Vcl.Imaging.jpeg,System.Generics.Collections;


const
//Packet Ident - change the values for your prog
Ident_Packet :array[0..15] of byte =(0,1,2,3,4,5,6,7,0,1,2,3,4,5,6,7);
//max items in the q before we start dropping
MAX_QUES=101;

//Command bytes
CMD_NOP=0;
CMD_JPG=1;
CMD_STR=2;
CMD_PEEP=3;


//type used in helper function
type
 TIdentArray = array[0..15] of byte;

//packet header, preceeds all packets..
type
 pPacketHdr=^tPacketHdr;
 tPacketHdr= packed record
  Ident:TIdentArray;//16 bytes
  Command:byte;//1 byte -255 commands
  DataSize:integer;//4 bytes -addional data size after header and not including header..
end;



type
  tPeep = packed record
    FirstName:array[0..39] of byte;
    LastName:array[0..39] of byte;
    Msg:array[0..499] of byte;
  end;

type
  tPeepPacket = packed record
     hdr:tPacketHdr;
     peep:tPeep;
  end;



function  CheckPacketIdent(Const AIdent:TIdentArray):boolean;
procedure FillPacketIdent(var aIdent:tIdentArray);





implementation


//does it match our packet identifier
function CheckPacketIdent(Const AIdent:TIdentArray):boolean;
var
i:integer;
begin
   Result:=true;
     for I := Low(aIdent) to High(AIdent) do
       if AIdent[i]<>Ident_Packet[i] then result:=false;
end;
//fill our identifier
procedure FillPacketIdent(var aIdent:TIdentArray);
var
i:integer;
begin
     for I := Low(AIdent) to High(AIdent) do
        AIdent[i]:=Ident_Packet[i];

end;


end.
