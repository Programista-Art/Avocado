unit formatowanie;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, math;

procedure piszf(const Fmt: string; const Args: array of const);

implementation


function ParsePrecision(const FormatStr: string; var Pos: Integer): Integer;
var
  PrecisionStr: string;
begin
  Result := -1;
  if (Pos <= Length(FormatStr)) and (FormatStr[Pos] = '.') then
  begin
    Inc(Pos);
    PrecisionStr := '';
    while (Pos <= Length(FormatStr)) and (FormatStr[Pos] in ['0'..'9']) do
    begin
      PrecisionStr := PrecisionStr + FormatStr[Pos];
      Inc(Pos);
    end;
    if PrecisionStr <> '' then
      Result := StrToIntDef(PrecisionStr, -1)
    else
      Result := -1;
  end;
end;

procedure piszf(const Fmt: string; const Args: array of const);
var
  ResultString: string;
  FmtPos, ArgIndex, Precision: Integer;
  FloatVal: Double;
begin
  ResultString := '';
  FmtPos := 1;
  ArgIndex := 0;

  while FmtPos <= Length(Fmt) do
  begin
    if Fmt[FmtPos] = '%' then
    begin
      Inc(FmtPos);
      if FmtPos > Length(Fmt) then
      begin
        ResultString += '%';
        Break;
      end;

      Precision := ParsePrecision(Fmt, FmtPos);

      if FmtPos > Length(Fmt) then
      begin
        ResultString += '%';
        if Precision >= 0 then ResultString += IntToStr(Precision);
        Break;
      end;

      if ArgIndex > High(Args) then
      begin
        ResultString += '%' + Fmt[FmtPos];
        Inc(FmtPos);
        Continue;
      end;

      case Fmt[FmtPos] of
        'd', 'i':
          begin
            case Args[ArgIndex].VType of
              vtInteger: ResultString += IntToStr(Args[ArgIndex].VInteger);
              vtInt64: ResultString += IntToStr(PInt64(Args[ArgIndex].VInt64)^);
              vtQWord: ResultString += IntToStr(PQWord(Args[ArgIndex].VQWord)^);
              else ResultString += '[TYPEMISMATCH_D]';
            end;
            Inc(ArgIndex);
          end;

        's':
          begin
            case Args[ArgIndex].VType of
              vtString: ResultString += string(Args[ArgIndex].VString^);
              vtAnsiString: ResultString += AnsiString(Args[ArgIndex].VAnsiString);
              vtUnicodeString: ResultString += UnicodeString(Args[ArgIndex].VUnicodeString);
              vtPChar: if Args[ArgIndex].VPChar <> nil then ResultString += string(Args[ArgIndex].VPChar);
              else ResultString += '[TYPEMISMATCH_S]';
            end;
            Inc(ArgIndex);
          end;

        'f':
          begin
            if Args[ArgIndex].VType = vtExtended then
            begin
              if Precision < 0 then Precision := 6;
              FloatVal := PExtended(Args[ArgIndex].VExtended)^;
              ResultString += FloatToStrF(FloatVal, ffFixed, 0, Precision);
            end
            {$IF DECLARED(vtCurrency)}
            else if Args[ArgIndex].VType = vtCurrency then
            begin
              if Precision < 0 then Precision := 6;
              FloatVal := PCurrency(Args[ArgIndex].VCurrency)^ / 10000;
              ResultString += FloatToStrF(FloatVal, ffFixed, 0, Precision);
            end
            {$ENDIF}
            else
              ResultString += '[TYPEMISMATCH_F]';
            Inc(ArgIndex);
          end;

        '%': ResultString += '%';

        else
          ResultString += '%' + Fmt[FmtPos];
      end;
      Inc(FmtPos);
    end
    else
    begin
      ResultString += Fmt[FmtPos];
      Inc(FmtPos);
    end;
  end;

  WriteLn(ResultString);
end;

end.
