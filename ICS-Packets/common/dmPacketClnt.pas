{ICS Demo Packet Client
  Created 2.2.2022 -q
  be it harm none, do as ye wish..


 Sends and recvs jpegs..

  }
unit dmPacketClnt;

interface

uses
  System.SysUtils, System.Classes, OverbyteIcsWndControl, OverbyteIcsWSocket, uPacketDefs, Vcl.Imaging.jpeg;

type
  TRecvJpeg_Event  = procedure (Sender:TObject; aJpeg:tJpegImage) of object;


type
  TPacketClntDm = class(TDataModule)
    cliSock: TWSocket;
    procedure cliSockDataAvailable(Sender: TObject; ErrCode: Word);
    procedure cliSockSessionConnected(Sender: TObject; ErrCode: Word);
    procedure cliSockSessionClosed(Sender: TObject; ErrCode: Word);
    procedure ProcessIncoming;
    procedure piRecvJpeg;
  private
    { Private declarations }
    fRecvJpeg:TRecvJpeg_Event;
  public
    { Public declarations }
  property OnRecvJpeg:TRecvJpeg_Event read fRecvJpeg write fRecvJpeg;
  end;

var
  PacketClntDm: TPacketClntDm;
  ClientBuff:Array[0..9999999] of byte;
  RecvCount:integer;
  ClientIP:string;
  ClientMAC:String;
  ClientName:String;

implementation
  uses uFrmMain;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TPacketClntDm.cliSockDataAvailable(Sender: TObject; ErrCode: Word);
  var
  aPacket:tPacketHdr;
  Len:integer;
begin

      MainFrm.DisplayMemo.Lines.Add('Data Available:'+IntToStr(RecvCount));

    Len:=cliSock.Receive(@ClientBuff[RecvCount],SizeOf(ClientBuff)-RecvCount);
     MainFrm.DisplayMemo.Lines.Add('Len:'+IntToStr(Len));
    //did we get some!!
    if Len <= 0 then
        Exit;

        //count it..
        RecvCount:=RecvCount+Len;
       //see if we got enough for a packet
     if RecvCount>=SizeOf(TPacketHdr) then
        begin
        Move(ClientBuff,aPacket,SizeOf(aPacket));
        if CheckPacketIdent(aPacket.Ident) then
         begin
          //packets can have extra data.. check for a datasize..
        if RecvCount>=(aPacket.DataSize+SizeOf(aPacket)) then
          begin
           MainFrm.DisplayMemo.Lines.Add('Received packet from ' + cliSock.GetPeerAddr);
           MainFrm.DisplayMemo.Lines.Add('Command:'+IntToStr(aPacket.Command));
           MainFrm.DisplayMemo.Lines.Add('Data Size:'+IntToStr(aPacket.DataSize));
           ProcessIncoming;
           RecvCount:=0;//reset our count
           FillChar(ClientBuff,SizeOf(ClientBuff),#0);//reset buffer..
          end else
             begin
               MainFrm.DisplayMemo.Lines.Add('Valid Ident but recv. count:'+IntToStr(RecvCount)+
                                       ' <> Expected Packet Size:'+IntToStr(aPacket.DataSize+SizeOf(aPacket)));
               if RecvCount>aPacket.DataSize then
                 begin
                 RecvCount:=0;//reset our count
                 FillChar(ClientBuff,SizeOf(ClientBuff),#0);//reset buffer..
                 end;
             end;
         end else
           begin
             MainFrm.DisplayMemo.Lines.Add('Invalid Packet Ident');
             Recvcount:=0;
             FillChar(ClientBuff,SizeOf(ClientBuff),#0);//reset buffer..
           end;
        end else
           begin
             MainFrm.DisplayMemo.Lines.Add('Recvd:'+IntToStr(RecvCount)+' bytes - expected:'+IntToStr(SizeOf(aPacket)));
           end;

       if ErrCode<>0 then
         MainFrm.DisplayMemo.Lines.Add('Recv Data ErrCode:'+IntToStr(ErrCode));

end;


procedure TPacketClntDm.ProcessIncoming;
  //process incoming packet
var
  aPacket:tPacketHdr;
begin

     if RecvCount>=SizeOf(TPacketHdr) then
        begin
        Move(ClientBuff,aPacket,SizeOf(aPacket));
          //packets can have extra data.. check for a datasize..
        if RecvCount>=(aPacket.DataSize+SizeOf(aPacket)) then
          begin
            case aPacket.Command of
            CMD_NOP:;//nothing
            CMD_JPG:piRecvJpeg;
            end;
          end;
        end;
end;

procedure TPacketClntDm.piRecvJpeg;
var
aPacketHdr:tPacketHdr;
offset:integer;
aMemStream:tMemoryStream;
aJpg:tJpegImage;
begin
  //get header..
  Move(ClientBuff,aPacketHdr,SizeOf(aPacketHdr));

    aMemStream:=tMemoryStream.Create;
    try
    //just want the extra data, set offset to reflect this
    Offset:=SizeOf(tPacketHdr);
    aMemStream.SetSize(aPacketHdr.DataSize);
    aMemStream.Write(ClientBuff[offset],aPacketHdr.DataSize);
    aMemStream.Position:=0;
    aJpg:=tJpegImage.Create;
    aJpg.LoadFromStream(aMemStream);
    if Assigned(fRecvJpeg) then
        fRecvJpeg(nil,aJpg);
    finally
     aJpg.Free;
     aMemStream.SetSize(0);
     aMemStream.Free;
    end;
end;




procedure TPacketClntDm.cliSockSessionClosed(Sender: TObject; ErrCode: Word);
begin
//closed
MainFrm.DisplayMemo.Lines.Add('Session closed:'+intToStr(ErrCode));

end;

procedure TPacketClntDm.cliSockSessionConnected(Sender: TObject; ErrCode: Word);
begin
//connected
MainFrm.DisplayMemo.Lines.Add('Session connected:'+intToStr(ErrCode));

end;

end.
