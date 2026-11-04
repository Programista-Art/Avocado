unit avocado_tokens;

{$mode objfpc}{$H+}

{ Token kinds and token records for the Avocado lexer. }

interface

uses
  SysUtils, avocado_source;

type
  TAvocadoTokenKind = (
    // special
    tkEndOfFile, tkEndOfLine, tkUnknown,

    // literals
    tkIdentifier, tkInteger, tkFloat, tkString, tkHex, tkChar,

    // keywords (canonical roles; spelling kept in Spelling)
    tkKwProgram, tkKwProgramUi, tkKwImport, tkKwModulePas,
    tkKwMainOpen,      // początek/poczatek/start/główny/glowny/main
    tkKwBlockEnd,      // koniec/end
    tkKwProcedure, tkKwFunction,
    tkKwReturn,
    tkKwIf, tkKwThen, tkKwElse,
    tkKwFor, tkKwTo, tkKwDownto, tkKwIn,
    tkKwDo,            // do/wykonaj/wykonać/make
    tkKwWhile,
    tkKwRepeat, tkKwUntil,
    tkKwBreak, tkKwContinue, tkKwExit,
    tkKwTrue, tkKwFalse,
    tkKwNot, tkKwAnd, tkKwOr, tkKwDiv, tkKwMod,
    tkKwNil,

    // escape blocks (raw content in Spelling)
    tkPascalBlock, tkPascalLine, tkAsmBlock,

    // punctuation / operators
    tkPlus, tkMinus, tkStar, tkSlash,
    tkAssign,          // =
    tkNotEqual, tkLess, tkGreater, tkLessEqual, tkGreaterEqual,
    tkColon, tkSemi, tkComma, tkDot, tkDotDot,
    tkLParen, tkRParen, tkLBracket, tkRBracket,
    tkAt, tkCaret, tkHash
  );

  TAvocadoToken = record
    Kind: TAvocadoTokenKind;
    Spelling: string;   // original text (or raw escape content)
    Text: string;       // decoded literal value / identifier name as written
    IntValue: Int64;
    FloatValue: Double;
    HasValue: Boolean;
    StartOffset: Integer; // 0-based byte offset
    EndOffset: Integer;   // exclusive
    Line: Integer;
    Col: Integer;
    NewlineBefore: Boolean;
    NewlineAfter: Boolean;
  end;

  TAvocadoTokenArray = array of TAvocadoToken;

function TokenKindName(AKind: TAvocadoTokenKind): string;

implementation

function TokenKindName(AKind: TAvocadoTokenKind): string;
begin
  case AKind of
    tkEndOfFile: Result := 'koniec pliku';
    tkEndOfLine: Result := 'koniec wiersza';
    tkUnknown: Result := 'nieznany znak';
    tkIdentifier: Result := 'identyfikator';
    tkInteger: Result := 'liczba całkowita';
    tkFloat: Result := 'liczba zmiennoprzecinkowa';
    tkString: Result := 'napis';
    tkHex: Result := 'liczba szesnastkowa';
    tkChar: Result := 'znak';
    tkKwProgram: Result := 'program';
    tkKwProgramUi: Result := 'program_ui';
    tkKwImport: Result := 'import';
    tkKwModulePas: Result := 'moduły_pas';
    tkKwMainOpen: Result := 'początek/start/main';
    tkKwBlockEnd: Result := 'koniec/end';
    tkKwProcedure: Result := 'procedura';
    tkKwFunction: Result := 'funkcja';
    tkKwReturn: Result := 'zwróć/return';
    tkKwIf: Result := 'jeżeli/if';
    tkKwThen: Result := 'wtedy/then';
    tkKwElse: Result := 'inaczej/else';
    tkKwFor: Result := 'dla/for';
    tkKwTo: Result := 'do/to';
    tkKwDownto: Result := 'malejąco/downto';
    tkKwIn: Result := 'w/in';
    tkKwDo: Result := 'wykonaj/do';
    tkKwWhile: Result := 'dopóki/while';
    tkKwRepeat: Result := 'repeat';
    tkKwUntil: Result := 'until/aż';
    tkKwBreak: Result := 'przerwij/break';
    tkKwContinue: Result := 'kontynuuj/continue';
    tkKwExit: Result := 'exit';
    tkKwTrue: Result := 'prawda/true';
    tkKwFalse: Result := 'fałsz/false';
    tkKwNot: Result := 'not';
    tkKwAnd: Result := 'and/i';
    tkKwOr: Result := 'or/lub';
    tkKwDiv: Result := 'div';
    tkKwMod: Result := 'mod';
    tkKwNil: Result := 'nil';
    tkPascalBlock: Result := 'pascal{';
    tkPascalLine: Result := 'pascal_linia{';
    tkAsmBlock: Result := 'asm{';
    tkPlus: Result := '+';
    tkMinus: Result := '-';
    tkStar: Result := '*';
    tkSlash: Result := '/';
    tkAssign: Result := '=';
    tkNotEqual: Result := '<>';
    tkLess: Result := '<';
    tkGreater: Result := '>';
    tkLessEqual: Result := '<=';
    tkGreaterEqual: Result := '>=';
    tkColon: Result := ':';
    tkSemi: Result := ';';
    tkComma: Result := ',';
    tkDot: Result := '.';
    tkDotDot: Result := '..';
    tkLParen: Result := '(';
    tkRParen: Result := ')';
    tkLBracket: Result := '[';
    tkRBracket: Result := ']';
    tkAt: Result := '@';
    tkCaret: Result := '^';
    tkHash: Result := '#';
  else
    Result := '?';
  end;
end;

end.
