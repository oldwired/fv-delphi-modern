{*********************************************************}
{                                                         }
{       Free Vision - GridSerializer Self-Test            }
{                                                         }
{       The serializer is the rig's contract with golden  }
{       files; this fixture verifies it directly with     }
{       hand-built TCellMatrix inputs.                     }
{                                                         }
{*********************************************************}

unit Test_GridSerializer;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TGridSerializerTests = class
  public
    [Test] procedure Grid_EmptyMatrix_EmptyString;
    [Test] procedure Grid_SingleRow_SpacesForDefault;
    [Test] procedure Grid_ContentInOneRow;
    [Test] procedure Grid_ControlCharsBecomeSpaces;
    [Test] procedure JSONL_DefaultCellOmitted;
    [Test] procedure JSONL_ColorAttrsEmitted;
    [Test] procedure JSONL_SortedByYThenX;
    [Test] procedure JSONL_QuotesEscaped;
  end;

implementation

uses
  System.SysUtils, System.StrUtils,
  FVCommon,
  GridSerializer;

function MakeMatrix(W, H: Integer): TCellMatrix;
var
  X, Y: Integer;
begin
  SetLength(Result, H, W);
  for Y := 0 to H - 1 do
    for X := 0 to W - 1 do
      Result[Y, X] := TScreenCell.Empty;
end;

procedure SetCh(var M: TCellMatrix; X, Y: Integer; const Ch: string);
begin
  M[Y, X].Ch := Ch;
end;

procedure TGridSerializerTests.Grid_EmptyMatrix_EmptyString;
var M: TCellMatrix;
begin
  SetLength(M, 0, 0);
  Assert.AreEqual('', CellsToGrid(M));
end;

procedure TGridSerializerTests.Grid_SingleRow_SpacesForDefault;
var
  M: TCellMatrix;
  G: string;
begin
  M := MakeMatrix(5, 1);
  G := CellsToGrid(M);
  Assert.AreEqual('     ' + #13#10, G);
end;

procedure TGridSerializerTests.Grid_ContentInOneRow;
var
  M: TCellMatrix;
  G: string;
begin
  M := MakeMatrix(5, 1);
  SetCh(M, 0, 0, 'A');
  SetCh(M, 1, 0, 'B');
  SetCh(M, 2, 0, 'C');
  G := CellsToGrid(M);
  Assert.AreEqual('ABC  ' + #13#10, G);
end;

procedure TGridSerializerTests.Grid_ControlCharsBecomeSpaces;
var
  M: TCellMatrix;
  G: string;
begin
  M := MakeMatrix(3, 1);
  SetCh(M, 0, 0, #0);
  SetCh(M, 1, 0, #9);
  SetCh(M, 2, 0, 'X');
  G := CellsToGrid(M);
  Assert.AreEqual('  X' + #13#10, G);
end;

procedure TGridSerializerTests.JSONL_DefaultCellOmitted;
var
  M: TCellMatrix;
  J: string;
begin
  M := MakeMatrix(3, 2);
  J := CellsToJSONL(M);
  Assert.AreEqual('', J, 'all-default matrix produces no JSONL lines');
end;

procedure TGridSerializerTests.JSONL_ColorAttrsEmitted;
var
  M: TCellMatrix;
  J: string;
begin
  M := MakeMatrix(3, 1);
  M[0, 1].Ch := 'X';
  M[0, 1].FG := 14;     // non-default fg
  M[0, 1].Bold := True;
  J := CellsToJSONL(M);
  Assert.IsTrue(ContainsStr(J, '"x":1'));
  Assert.IsTrue(ContainsStr(J, '"y":0'));
  Assert.IsTrue(ContainsStr(J, '"ch":"X"'));
  Assert.IsTrue(ContainsStr(J, '"fg":14'));
  Assert.IsTrue(ContainsStr(J, '"bold":true'));
end;

procedure TGridSerializerTests.JSONL_SortedByYThenX;
var
  M: TCellMatrix;
  J: string;
  P0, P1, P2: Integer;
begin
  M := MakeMatrix(3, 2);
  M[1, 2].Ch := 'C';   // (y=1, x=2)
  M[0, 1].Ch := 'A';   // (y=0, x=1)
  M[1, 0].Ch := 'B';   // (y=1, x=0)
  J := CellsToJSONL(M);
  P0 := Pos('"ch":"A"', J);
  P1 := Pos('"ch":"B"', J);
  P2 := Pos('"ch":"C"', J);
  Assert.IsTrue(P0 > 0); Assert.IsTrue(P1 > 0); Assert.IsTrue(P2 > 0);
  Assert.IsTrue(P0 < P1, 'A (y=0) before B (y=1)');
  Assert.IsTrue(P1 < P2, 'B (y=1 x=0) before C (y=1 x=2)');
end;

procedure TGridSerializerTests.JSONL_QuotesEscaped;
var
  M: TCellMatrix;
  J: string;
begin
  M := MakeMatrix(1, 1);
  M[0, 0].Ch := '"';
  J := CellsToJSONL(M);
  Assert.IsTrue(ContainsStr(J, '"ch":"\""'), 'double-quote must be JSON-escaped');
end;

initialization
  TDUnitX.RegisterTestFixture(TGridSerializerTests);

end.
