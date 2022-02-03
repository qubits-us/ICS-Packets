program PacketSrv;

uses
  Vcl.Forms,
  uFrmMain in 'uFrmMain.pas' {MainFrm},
  dmPacketSrv in '..\common\dmPacketSrv.pas' {ServerCommsDm: TDataModule},
  uPacketDefs in '..\common\uPacketDefs.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainFrm, MainFrm);
  Application.Run;
end.
