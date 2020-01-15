program BankOfDelphi;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  uBank in 'uBank.pas';

begin
  try
    { TODO -oUser -cConsole Main : Insert code here }
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
