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
  Forms, anchordockpkg, lazcontrols, runtimetypeinfocontrols, printer4lazarus,
  tachartlazaruspkg, pascalscript, unit1, usettings, AvocadoTranslator,
  unitopcjeprojektu, unitoprogramie, unitautor, uinformacjaoide, matematyka,
  formatowanie, chatgptavocado, uwsparcie, ustawieniaai, pliki, internet;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Title:='IDE Avocado';
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TFustawieniaChatGPT, FustawieniaChatGPT);
  Application.CreateForm(TFormSettingIntepreter, FormSettingIntepreter);
  Application.CreateForm(TFormOpcjeProjektu, FormOpcjeProjektu);
  Application.CreateForm(TFormOprogramie, FormOprogramie);
  Application.CreateForm(TFormAutor, FormAutor);
  Application.CreateForm(TFinformacjaide, Finformacjaide);
  Application.CreateForm(TWsparcie, Wsparcie);
  Application.CreateForm(TFustawieniaAI, FustawieniaChatGPT);
  Application.Run;
end.

