{ICS Packet Client Demo - Main Form
Created 2.2.2022 -q

be it harm none, do as ye wish..

}
unit uFrmMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,System.Types, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,Vcl.Imaging.jpeg,dmPacketClnt,
  IpHlpApi, IpTypes,OverbyteIcsWSocket,uPacketDefs;

type
  TMainFrm = class(TForm)
    btnConnect: TButton;
    edSrvIp: TEdit;
    DisplayMemo: TMemo;
    im: TImage;
    btnSend: TButton;
    edPort: TEdit;
    btnDisconnect: TButton;
    edCommand: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure DiscoverMACIP;
    procedure btnConnectClick(Sender: TObject);
    procedure btnSendClick(Sender: TObject);
    procedure SendPacketHdr;
    procedure SendString;
    procedure SendJpeg;
    procedure ShowJpeg(sender:tObject; aJpeg:tJpegImage);
    procedure ShowString(sender:tObject; aStr:String);
    procedure btnDisconnectClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainFrm: TMainFrm;

implementation

{$R *.dfm}

function GetName: string;
var
  buffer: array[0..MAX_COMPUTERNAME_LENGTH + 1] of Char;
  Size: Cardinal;
begin
  Size := MAX_COMPUTERNAME_LENGTH + 1;
  GetComputerName(@buffer, Size);
  Result := StrPas(buffer);
end;


procedure TMainFrm.btnConnectClick(Sender: TObject);
begin
if PacketClntDm.cliSock.State in [TSocketState.wsClosed] then
begin
    PacketClntDm.cliSock.Port:=edPort.Text;
    PacketClntDm.cliSock.Addr:=edSrvIp.Text;
    PacketClntDm.cliSock.Connect;
end;

end;

procedure TMainFrm.btnDisconnectClick(Sender: TObject);
begin
PacketClntDm.cliSock.Close;
end;

procedure TMainFrm.btnSendClick(Sender: TObject);
var
aCommand:integer;
begin
   aCommand:=StrToInt(edCommand.Text);

   case aCommand of
   CMD_NOP:SendPacketHdr;
   CMD_JPG:SendJpeg;
   CMD_STR:SendString;
   end;


end;



procedure TMainFrm.SendPacketHdr;
var
aPacket:tPacketHdr;
begin
     FillPacketIdent(aPacket.Ident);
     aPacket.Command:=CMD_NOP;//do nothing..
     aPacket.DataSize:=0;//no data
     PacketClntDm.cliSock.Send(@aPacket,SizeOf(aPacket));
end;

procedure TMainFrm.SendString;
var
aHdr:tPacketHdr;
aStr:String;
aBytes:TBytes;
aBuff:TBytes;
begin

  aStr:='Hello from client!!';

  if Length(aStr)>0 then
   begin
   FillPacketIdent(aHdr.Ident);
   aHdr.Command:=CMD_STR;
   aBytes:=TEncoding.ANSI.GetBytes(aStr);//for example using ansi
   SetLength(aBuff,SizeOf(tPacketHdr)+Length(aBytes));//make room for hdr + string
   aHdr.DataSize:=Length(aBytes);
   Move(aHdr,aBuff[0],SizeOf(tPacketHdr));
   Move(aBytes[0],aBuff[SizeOf(tPacketHdr)],Length(aBytes));
   PacketClntDm.cliSock.Send(aBuff,Length(aBuff));
   SetLength(aBytes,0);
   SetLength(aBuff,0);
   end;




end;

procedure TMainFrm.SendJpeg;
var
aHdr:tPacketHdr;
aJpg:TJpegImage;
aBuff:tByteDynArray;
aMemStrm:TMemoryStream;
offset:integer;
begin

aJpg:=TJpegImage.Create;
aJpg.Assign(im.Picture);
aMemStrm:=tMemoryStream.Create;
aJpg.SaveToStream(aMemStrm);

FillPacketIdent(aHdr.Ident);
aHdr.Command:=CMD_JPG;//recv jpeg
aHdr.DataSize:=aMemStrm.Size;//size of jpeg
aMemStrm.Position:=0;
SetLength(aBuff,SizeOf(aHdr)+aHdr.DataSize);
move(aHdr,aBuff[0],SizeOf(aHdr));
offset:=SizeOf(aHdr);
aMemStrm.ReadBuffer(aBuff[offset],aHdr.DataSize);

PacketClntDm.cliSock.Send(aBuff,Length(aBuff));

aJpg.Free;
aMemStrm.SetSize(0);
aMemStrm.Free;
SetLength(aBuff,0);


end;

procedure tMainFrm.ShowJpeg(sender:tObject; aJpeg:tJpegImage);
begin
//
  im.Picture.Assign(aJpeg);
end;

procedure tMainFrm.ShowString(sender: TObject; aStr: string);
begin
  DisplayMemo.Lines.Add(aStr);
end;



procedure tMainFrm.DiscoverMACIP;
var
  pAdapterInfo, pTempAdapterInfo: PIP_ADAPTER_INFO;
  BufLen: DWORD;
  Status: DWORD;
  strMAC: String;
  i: Integer;
begin

  BufLen := SizeOf(IP_Adapter_Info);
  GetMem(pAdapterInfo, BufLen);
  try
    repeat
      Status := GetAdaptersInfo(pAdapterInfo, BufLen);
      if (Status = ERROR_SUCCESS) then
      begin
        if BufLen <> 0 then Break;
        Status := ERROR_NO_DATA;
      end;
      if (Status = ERROR_BUFFER_OVERFLOW) then
      begin
        ReallocMem(pAdapterInfo, BufLen);
      end else
      begin
        case Status of
          ERROR_NOT_SUPPORTED:
            ;//DisplayMemo.Lines.Add('GetAdaptersInfo is not supported by the operating system running on the local computer.');
          ERROR_NO_DATA:
           ;// DisplayMemo.Lines.Add('No network adapter on the local computer.');
        else
           ;// DisplayMemo.Lines.Add('GetAdaptersInfo failed with error #' + IntToStr(Status));
        end;
        Exit;
      end;
    until False;

    pTempAdapterInfo := pAdapterInfo;
    while (pTempAdapterInfo <> nil) do
    begin
      //DisplayMemo.Lines.Add('Description: ' + pTempAdapterInfo^.Description);
      //DisplayMemo.Lines.Add('Name: ' + pTempAdapterInfo^.AdapterName);

      strMAC := '';
      for I := 0 to pTempAdapterInfo^.AddressLength - 1 do
        strMAC := strMAC + '-' + IntToHex(pTempAdapterInfo^.Address[I], 2);

      Delete(strMAC, 1, 1);
      //DisplayMemo.Lines.Add('MAC address: ' + strMAC);
      //DisplayMemo.Lines.Add('IP address: ' + pTempAdapterInfo^.IpAddressList.IpAddress.S);
      if pTempAdapterInfo^.IpAddressList.IpAddress.S<>'0.0.0.0' then
        begin
          ClientIp:=pTempAdapterInfo^.IpAddressList.IpAddress.S;
          ClientMAC:=StrMAC;
        end;


      pTempAdapterInfo := pTempAdapterInfo^.Next;
    end;
  finally
    FreeMem(pAdapterInfo);
  end;



end;



procedure TMainFrm.FormCreate(Sender: TObject);
begin
ReportMemoryLeaksOnShutdown:=True;
PacketClntDm:=TPacketClntDm.Create(application);
PacketClntDm.OnRecvJpeg:=ShowJpeg;
PacketClntDm.OnRecvStr:=ShowString;
RecvCount:=0;


ClientName:=GetName;
DiscoverMACIP;
DisplayMemo.Lines.Add('Host: '+ClientName);
DisplayMemo.Lines.Add('IP: '+ClientIP);
DisplayMemo.Lines.Add('MAC: '+ClientMac);
edSrvIp.Text:=ClientIP;





end;

end.
