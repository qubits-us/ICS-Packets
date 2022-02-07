{ICS Packet Server Demo - Main Form
  Created 2.2.2022-q

  be it harm none, do as ye wish..


  }
unit uFrmMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,System.SyncObjs,System.Types,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,Vcl.Imaging.jpeg,dmPacketSrv, Vcl.ExtCtrls,IpHlpApi,IpTypes,uPacketDefs;

type
  TMainFrm = class(TForm)
    DisplayMemo: TMemo;
    im: TImage;
    btnListen: TButton;
    btnStop: TButton;
    Button1: TButton;
    imSend: TImage;
    Button2: TButton;
    edFirstName: TEdit;
    edLastName: TEdit;
    edMsg: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Button3: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure DiscoverMACIP;
    procedure btnListenClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure UpdateLog(sender: tObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);

  private
    { Private declarations }
    procedure DisplayIm(sender: tObject);
  public
    { Public declarations }

  end;

var
  MainFrm: TMainFrm;
  ServerIp:String;
  ServerMac:String;

implementation

{$R *.dfm}



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
      strMAC := '';
      for I := 0 to pTempAdapterInfo^.AddressLength - 1 do
        strMAC := strMAC + '-' + IntToHex(pTempAdapterInfo^.Address[I], 2);
      Delete(strMAC, 1, 1);
      if pTempAdapterInfo^.IpAddressList.IpAddress.S<>'0.0.0.0' then
        begin
          ServerIp:=pTempAdapterInfo^.IpAddressList.IpAddress.S;
          ServerMAC:=StrMAC;
        end;
      pTempAdapterInfo := pTempAdapterInfo^.Next;
    end;
  finally
    FreeMem(pAdapterInfo);
  end;


end;




procedure TMainFrm.FormClose(Sender: TObject; var Action: TCloseAction);
begin

ServerCommsDm.srvSock.DisconnectAll;
ServerCommsDm.srvSock.Close;
ServerCommsDm.Free;

end;

procedure TMainFrm.FormCreate(Sender: TObject);
begin

ReportMemoryLeaksOnShutDown:=true;

 DiscoverMACIP;
//
 ServerCommsDm:=TServerCommsDm.Create(application);
ServerCommsDm.srvSock.Proto:='tcp';
ServerCommsDm.srvSock.Port:='9000';
ServerCommsDm.srvSock.Addr:=ServerIp;
ServerCommsDm.srvSock.ClientClass:=tPacketClient;
ServerCommsDm.OnDisplayLog:=UpdateLog;
ServerCommsDm.OnRecvPacket:=DisplayIm;




end;

procedure TMainFrm.btnListenClick(Sender: TObject);
begin

ServerCommsDm.srvSock.Listen;

end;

procedure TMainFrm.btnStopClick(Sender: TObject);
begin
ServerCommsDm.srvSock.DisconnectAll;
ServerCommsDm.srvSock.Close;
end;


procedure TMainFrm.Button1Click(Sender: TObject);
var
aJpg:TJpegImage;
aStrm:TMemoryStream;
aHdr:tPacketHdr;
aBuff:tByteDynArray;
offset:integer;
begin
//make sure someone is connected..
if ServerCommsDm.srvSock.ClientCount>0 then
begin
aJpg:=TJpegImage.Create;
aJpg.Assign(imSend.Picture);
aStrm:=tMemoryStream.Create;
aJpg.SaveToStream(aStrm);

FillPacketIdent(aHdr.Ident);
aHdr.Command:=CMD_JPG;
aHdr.DataSize:=aStrm.Size;
aStrm.Position:=0;
SetLength(aBuff,SizeOf(aHdr)+aHdr.DataSize);
move(aHdr,aBuff[0],SizeOf(aHdr));
offset:=SizeOf(aHdr);
aStrm.ReadBuffer(aBuff[offset],aHdr.DataSize);

ServerCommsDm.srvSock.Client[0].Send(aBuff,Length(aBuff));

aJpg.Free;
aStrm.Free;
SetLength(aBuff,0);

end;


end;

procedure TMainFrm.Button2Click(Sender: TObject);
var
aHdr:tPacketHdr;
aStr:String;
aBytes:TBytes;
aBuff:TBytes;
begin
if ServerCommsDm.srvSock.ClientCount<1 then exit;//nope

  aStr:='Hello from server!!';
  if Length(aStr)>0 then
   begin
   FillPacketIdent(aHdr.Ident);
   aHdr.Command:=CMD_STR;
   aBytes:=TEncoding.ANSI.GetBytes(aStr);//for example using ansi
   SetLength(aBuff,SizeOf(tPacketHdr)+Length(aBytes));//make room for hdr + string
   aHdr.DataSize:=Length(aBytes);
   Move(aHdr,aBuff[0],SizeOf(tPacketHdr));
   Move(aBytes[0],aBuff[SizeOf(tPacketHdr)],Length(aBytes));
   ServerCommsDm.srvSock.Client[0].Send(aBuff,Length(aBuff));
   SetLength(aBytes,0);
   SetLength(aBuff,0);
   end;

end;

procedure TMainFrm.Button3Click(Sender: TObject);
//send a peep
var
aPeepPck:TPeepPacket;
aBytes:tBytes;
begin

FillPacketIdent(aPeepPck.hdr.Ident);
aPeepPck.hdr.Command:=CMD_PEEP;
aPeepPck.hdr.DataSize:=SizeOf(tPeep);
//init peep string arrays.. fill with spaces.. trim off later..
FillChar(aPeepPck.peep.FirstName,SizeOf(aPeepPck.peep.FirstName),#32);
FillChar(aPeepPck.peep.LastName,SizeOf(aPeepPck.peep.LastName),#32);
FillChar(aPeepPck.peep.Msg,SizeOf(aPeepPck.peep.Msg),#32);
// i set MaxLength on the edits to ensure data is not too big
if Length(edFirstName.Text)>0 then
  begin
    aBytes:=TEncoding.ANSI.GetBytes(edFirstName.Text);
    Move(aBytes[0],aPeepPck.peep.FirstName[0],Length(aBytes));
  end;
SetLength(aBytes,0);
if Length(edLastName.Text)>0 then
  begin
    aBytes:=TEncoding.ANSI.GetBytes(edLastName.Text);
    Move(aBytes[0],aPeepPck.peep.LastName[0],Length(aBytes));
  end;
SetLength(aBytes,0);
if Length(edMsg.Text)>0 then
  begin
    aBytes:=TEncoding.ANSI.GetBytes(edMsg.Text);
    Move(aBytes[0],aPeepPck.peep.Msg[0],Length(aBytes));
  end;
SetLength(aBytes,0);

ServerCommsDm.srvSock.Client[0].Send(@aPeepPck,SizeOf(tPeepPacket));

end;

procedure TMainFrm.UpdateLog(sender: TObject);
var
    I : Integer;
begin
    DisplayMemo.Lines.BeginUpdate;
    try
        if DisplayMemo.Lines.Count > 200 then begin
            for I := 1 to 50 do
                DisplayMemo.Lines.Delete(0);
        end;
        LockDisplay.Enter;
        try
            DisplayMemo.Lines.AddStrings(ServerCommsDm.FLogList);
            ServerCommsDm.FLogList.Clear;
        finally
            LockDisplay.Leave;
        end;
    finally
        DisplayMemo.Lines.EndUpdate;
        DisplayMemo.Perform(EM_SCROLLCARET, 0, 0);
    end;

end;


procedure tMainFrm.DisplayIm(sender: tObject);
var
ajpg:tJpegImage;
aData:tPacketData;
aMemStrm:tMemoryStream;
aBytes:tBytes;
aPeep:tPeep;
aStr:String;
begin
  //update form
   if ServerCommsDm.PacketCount>0 then
    begin
    aData:=ServerCommsDm.PopPacket;
    if aData.DataType=CMD_JPG then
      begin
       aJpg:=tJpegImage.Create;
       aMemStrm:=tMemoryStream.Create;
       aMemStrm.SetSize(Length(aData.Data));
       aMemStrm.WriteBuffer(aData.Data[0],Length(aData.Data));
       aMemStrm.Position:=0;
       aJpg.LoadFromStream(aMemStrm);
       if Assigned(aJpg) then
        begin
         im.Picture.Assign(aJpg);
        end;
       aMemStrm.SetSize(0);
       aMemStrm.Free;
       SetLength(aData.Data,0);
       aData.Free;
       aJpg.Free;

      end else
      if aData.DataType=CMD_STR then
        begin
         AStr:=TEncoding.ANSI.GetString(aData.Data);
         if Length(aStr)>0 then
          DisplayMemo.Lines.Add(aStr);
         SetLength(aData.Data,0);
         aData.Free;

        end else
      if aData.DataType=CMD_PEEP then
        begin
         Move(aData.Data[0],aPeep,SizeOf(TPeep));
         SetLength(aBytes,SizeOf(aPeep.FirstName));
         Move(aPeep.FirstName[0],aBytes[0],SizeOf(aPeep.FirstName));
         edFirstName.Text:=TEncoding.ANSI.GetString(aBytes);
         Move(aPeep.LastName[0],aBytes[0],SizeOf(aPeep.LastName));
         edLastName.Text:=TEncoding.ANSI.GetString(aBytes);
         SetLength(aBytes,SizeOf(aPeep.Msg));
         Move(aPeep.Msg[0],aBytes[0],SizeOf(aPeep.Msg));
         edMsg.Text:=TEncoding.ANSI.GetString(aBytes);
         SetLength(aBytes,0);
         SetLength(aData.Data,0);
         aData.Free;
        end else
           begin
           //unnkown
           SetLength(aData.Data,0);
           aData.Free;
           end;
    end;
end;




end.
