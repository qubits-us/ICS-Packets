{ICS Packet Server
  Created 2.2.2022-q

  be it harm none, do as ye wish..


  just one command, recv jpeg..
  not counting the nop..


  }

unit dmPacketSrv;

interface

uses //dope we needs..
  Winapi.Windows,System.SysUtils, System.Classes, System.SyncObjs, OverbyteIcsWndControl, OverbyteIcsWSocket,
   OverbyteIcsWSocketS, OverbyteIcsWSocketTS,Vcl.Imaging.jpeg,System.Generics.Collections,uPacketDefs;



 //our client class, each connection gets one..
type
  TPacketClient = class(TWSocketClient)
  public
    Buff        : array[0..9999999] of byte; //big ass buffer..
    Count:integer;//how much we've recvd
    ConnectTime : TDateTime;//when did we connect
    ClearToSend :boolean;//
    GoodHeader  :boolean;//did we get a good header
  end;

type
  TRecvPacket_Event  = procedure (Sender:TObject) of object;
  TDisplayLog_Event  = procedure (Sender:TObject) of object;




type
  TServerCommsDm = class(TDataModule)
    srvSock: TWSocketServer;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    function  CheckPacketIdent(Const AIdent:TIdentArray):boolean;
    procedure LogMsg(const Msg: string);
    procedure ImRecv;
    procedure srvSockClientCreate(Sender: TObject; Client: TWSocketClient);
    procedure srvSockClientConnect(Sender: TObject; Client: TWSocketClient; Error: Word);
    procedure srvSockBgException(Sender: TObject; E: Exception; var CanClose: Boolean);
    procedure srvSockDataAvailable(Sender: TObject; ErrCode: Word);
    procedure ProcessData(Client : TPacketClient);
    procedure piRecvImage(Client: TPacketClient);
    procedure srvSockDataSent(Sender: TObject; ErrCode: Word);
    procedure srvSockClientDisconnect(Sender: TObject; Client: TWSocketClient; Error: Word);
    procedure srvSockSessionConnected(Sender: TObject; ErrCode: Word);

private
    { Private declarations }
    fRecvEvent:TRecvPacket_Event;
    fLogEvent:TDisplayLog_Event;
    fImageQue:TQueue<tJpegImage>;
    function  GetImageCount:integer;
    procedure EmptyQ;

  public
    { Public declarations }
    fLogList:TStringList;
    function  PopImage:tJpegImage;
    property  ImageCount:integer read GetImageCount;
    property  OnRecvJpeg:TRecvPacket_Event read fRecvEvent write fRecvEvent;
    property  OnDisplayLog:TDisplayLog_Event read fLogEvent write fLogEvent;
  end;

var
  ServerCommsDm: TServerCommsDm;
  LockDisplay : TCriticalSection;
  LockQ : TCriticalSection;


implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TServerCommsDm.DataModuleCreate(Sender: TObject);
begin
//create some things
LockDisplay:=TCriticalSection.Create;
LockQ:=TCriticalSection.Create;
fLogList:=tStringList.Create;
fImageQue:=TQueue<tJpegImage>.Create;

end;

procedure TServerCommsDm.DataModuleDestroy(Sender: TObject);
begin
//set them all free..
EmptyQ;
fImageQue.Free;
fLogList.Free;
LockDisplay.Free;
LockQ.Free;
end;


//does it match our packet identifier
function TServerCommsDm.CheckPacketIdent(Const AIdent:TIdentArray):boolean;
var
i:integer;
begin
   Result:=true;
     for I := Low(aIdent) to High(AIdent) do
       if AIdent[i]<>Ident_Packet[i] then result:=false;
end;


procedure TServerCommsDm.srvSockBgException(Sender: TObject; E: Exception; var CanClose: Boolean);
begin
        LogMsg('Socket background exception occured: ' + E.ClassName + ': ' + E.Message);
        CanClose := TRUE;   { Goodbye! }
end;

procedure TServerCommsDm.srvSockClientConnect(Sender: TObject; Client: TWSocketClient; Error: Word);
begin
    with Client as TPacketClient do begin
        LogMsg('Client connected.' +
                ' Remote: ' + PeerAddr + '/' + PeerPort +
                ' Local: '  + GetXAddr + '/' + GetXPort +
                'There is now ' +
                IntToStr(TWSocketThrdServer(Sender).ClientCount) +
                ' clients connected.');

        Client.LineMode            := False;
        Client.LineEdit            := False;
        Client.BufSize             := SizeOf(TPacketClient(Client).Buff);
        Client.OnDataAvailable     := srvSockDataAvailable;
        Client.OnBgException       := srvSockBgException;
        Client.OnDataSent          := srvSockDataSent;
        TPacketClient(Client).ConnectTime  := Now;

    end;


end;

//create a new client..
procedure TServerCommsDm.srvSockClientCreate(Sender: TObject; Client: TWSocketClient);
var
    Cli : TPacketClient;
begin
    Cli := Client as  TPacketClient;
    Cli.LineMode            := False;
    Cli.LineEdit            := False;
    Cli.BufSize             := SizeOf(Cli.Buff);
    Cli.OnDataAvailable     := srvSockDataAvailable;
    Cli.OnBgException       := srvSockBgException;
    Cli.OnDataSent          := srvSockDataSent;
    Cli.ConnectTime         := Now;
    Cli.Count               :=0;
    Cli.ClearToSend         := true;
end;


procedure TServerCommsDm.srvSockClientDisconnect(Sender: TObject; Client: TWSocketClient; Error: Word);
var
    MyClient       : TPacketClient;
begin
    MyClient := Client as TPacketClient;

    LogMsg('Client disconnecting: ' + MyClient.PeerAddr + '   ' +
            'Duration: ' + FormatDateTime('hh:nn:ss',
            Now - MyClient.ConnectTime) + ' Error: ' + IntTostr(Error) +
            'There is now ' +
            IntToStr(TWSocketThrdServer(Sender).ClientCount - 1) +
            ' clients connected.');

end;

procedure TServerCommsDm.srvSockDataAvailable(Sender: TObject; ErrCode: Word);
var
    Cli : TPacketClient;
    Len:integer;
    aPacketHdr:TPacketHdr;
begin
    Cli := Sender as TPacketClient;
    //recv bin data into our buffer..
    Len:=Cli.Receive(@Cli.Buff[Cli.Count],SizeOf(Cli.Buff)-Cli.Count);

    //did we get some!!
    if Len <= 0 then
        Exit;

        //count it..
        Cli.Count:=Cli.Count +Len;
       //see if we got enough for a packet
     if Cli.Count>=SizeOf(TPacketHdr) then
        begin
        Move(Cli.Buff,aPacketHdr,SizeOf(aPacketHdr));
        if CheckPacketIdent(aPacketHdr.Ident) then
         begin
         Cli.GoodHeader:=true;
         LogMsg('Recvd Valid Header:DataSize='+IntToStr(aPacketHdr.DataSize));
          //packets can have extra data.. check for a datasize..
          if Cli.Count>=(aPacketHdr.DataSize+SizeOf(aPacketHdr)) then
           begin
            LogMsg('Received packet from ' + Cli.GetPeerAddr);
            ProcessData(Cli);
           end;
         end else
            begin
              Cli.GoodHeader:=false;
              LogMsg('Received bad header from '+Cli.GetPeerAddr);
              Cli.Count:=0;//start it all again
              FillChar(Cli.Buff,SizeOf(Cli.Buff),#0);//zero the buffer
            end;
        end;


end;


procedure TServerCommsDm.srvSockDataSent(Sender: TObject; ErrCode: Word);
begin
//
end;

procedure TServerCommsDm.srvSockSessionConnected(Sender: TObject; ErrCode: Word);
begin

end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TServerCommsDm.ProcessData(Client : TPacketClient);
var
aPacketHdr:TPacketHdr;
begin

        //copy our header out of buffer..
        Move(Client.Buff,aPacketHdr,SizeOf(aPacketHdr));
           //display header info.. :)
           LogMsg(' Command:'+IntToStr(aPacketHdr.Command)+
                   ' Expected:'+IntToStr(aPacketHdr.DataSize+SizeOf(aPacketHdr))+' Recv:'+IntToStr(Client.Count));

                //process command
                case aPacketHdr.Command of
                0:;//nothing do.. send just packet header command 0 to keep alive..
                1:piRecvImage(Client);//
                else
                     LogMsg('Unknowm Command.. ignoring packet');
                end;


        //always restart things..
        Client.Count:=0;//start it all again
        FillChar(Client.Buff,SizeOf(Client.Buff),#0);//zero the buffer
end;


procedure TServerCommsDm.piRecvImage(Client: TPacketClient);
var
aPacketHdr:tPacketHdr;
offset:integer;
aMemStream:tMemoryStream;
aJpg:tJpegImage;
begin
  //get header..
  Move(Client.Buff,aPacketHdr,SizeOf(aPacketHdr));

    aMemStream:=tMemoryStream.Create;
    try
    //just want the extra data, set offset to reflect this
    Offset:=SizeOf(tPacketHdr);
    aMemStream.SetSize(aPacketHdr.DataSize);
    aMemStream.Write(Client.Buff[offset],aPacketHdr.DataSize);
    aMemStream.Position:=0;
    aJpg:=tJpegImage.Create;
    aJpg.LoadFromStream(aMemStream);
     //put the jpeg in the q
      LockQ.Enter;
        try
         if fImageQue.Count<MAX_QUES then
          fImageQue.Enqueue(aJpg);
        finally
         LockQ.Leave;
        end;
      //trig
      ImRecv;

    finally
     aMemStream.SetSize(0);
     aMemStream.Free;
     aJpg.Free;
    end;
end;


procedure tServerCommsDm.ImRecv;
begin
if assigned(fRecvEvent) then fRecvEvent(nil);

end;



//save debug messages into ouir tStringList..
procedure tServerCommsDm.LogMsg(const Msg: string);
begin
    LockDisplay.Enter;//one at a time boys..
    try
       //clear it if we need too..
       if fLogList.Count>100 then
           fLogList.Clear;
       FLogList.Add(Msg);//add the message
     finally
      LockDisplay.Leave;//get outta here..
    end;

  if assigned(fLogEvent) then fLogEvent(nil);


end;


function tServerCommsDm.PopImage:tJpegImage;
begin
 result:=nil;
 LockQ.Enter;
 try
  if fImageQue.Count>0 then
    result:=fImageQue.Dequeue;
 finally
   LockQ.Leave;
 end;
end;

function tServerCommsDm.GetImageCount:integer;
begin
result:=-1;
 LockQ.Enter;
  try
    result:=fImageQue.Count;
  finally
   LockQ.Leave;
  end;

end;

procedure tServerCommsDm.EmptyQ;
var
i,j:integer;
aJpg:tJpegImage;
begin
  LockQ.Enter;
  try
     J:=fImageQue.Count-1;
    for I :=0 to J do
      begin
        aJpg:=fImageQue.Dequeue;
        aJpg.Free;
      end;

  finally
   LockQ.Leave;
  end;
end;


end.
