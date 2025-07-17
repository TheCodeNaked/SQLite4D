program projSQLite4D;

uses
  System.StartUpCopy,
  FMX.Forms,
  SQLite4D in 'scr\SQLite4D.pas',
  MainForm in 'MainForm.pas' {FormMain};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
