program project1;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, anchordockpkg, lazcontrols, unit1, usettings, AvocadoTranslator,
  unitopcjeprojektu, unitoprogramie, unitautor, uinformacjaoide;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Title:='IDE Avocado';
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TFormSettingIntepreter, FormSettingIntepreter);
  Application.CreateForm(TFormOpcjeProjektu, FormOpcjeProjektu);
  Application.CreateForm(TFormOprogramie, FormOprogramie);
  Application.CreateForm(TFormAutor, FormAutor);
  Application.CreateForm(TFinformacjaide, Finformacjaide);
  Application.Run;
end.

