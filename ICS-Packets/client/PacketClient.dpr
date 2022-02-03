program PacketClient;

uses
  Vcl.Forms,
  uFrmMain in 'uFrmMain.pas' {MainFrm},
  dmPacketClnt in '..\common\dmPacketClnt.pas' {PacketClntDm: TDataModule},
  uPacketDefs in '..\common\uPacketDefs.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainFrm, MainFrm);
  Application.Run;
end.
