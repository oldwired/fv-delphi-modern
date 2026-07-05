{*********************************************************}
{                                                         }
{       Free Vision - Serialization Tests                 }
{                                                         }
{       Covers TFVJsonHelper Point/Rect/StringList        }
{       round-trips and TFVSerializerRegistry factory     }
{       dispatch.                                          }
{                                                         }
{*********************************************************}

unit Test_Serialization;

interface

uses
  DUnitX.TestFramework;

type
  TDummyFactoryObject = class
  public
    Tag: string;
    constructor Create;
  end;

  [TestFixture]
  TSerializationTests = class
  public
    [Test] procedure Point_RoundTrip;
    [Test] procedure Rect_RoundTrip;
    [Test] procedure StringList_RoundTrip;
    [Test] procedure Registry_CanCreate_KnownType;
    [Test] procedure Registry_CreateFromTypeId;
    [Test] procedure Registry_UnknownType_ReturnsNil;
  end;

implementation

uses
  System.SysUtils, System.JSON, System.Classes,
  FVSerialization;

constructor TDummyFactoryObject.Create;
begin
  inherited Create;
  Tag := 'made-by-factory';
end;

function MakeDummy: TObject;
begin
  Result := TDummyFactoryObject.Create;
end;

procedure TSerializationTests.Point_RoundTrip;
var
  J: TJSONObject;
  P: TSerializablePoint;
begin
  J := TFVJsonHelper.PointToJSON(7, 13);
  try
    P := TFVJsonHelper.JSONToPoint(J);
    Assert.AreEqual(7, P.X);
    Assert.AreEqual(13, P.Y);
  finally
    J.Free;
  end;
end;

procedure TSerializationTests.Rect_RoundTrip;
var
  J: TJSONObject;
  R: TSerializableRect;
begin
  J := TFVJsonHelper.RectToJSON(1, 2, 30, 40);
  try
    R := TFVJsonHelper.JSONToRect(J);
    Assert.AreEqual(1,  R.A.X);
    Assert.AreEqual(2,  R.A.Y);
    Assert.AreEqual(30, R.B.X);
    Assert.AreEqual(40, R.B.Y);
  finally
    J.Free;
  end;
end;

procedure TSerializationTests.StringList_RoundTrip;
var
  Src, Dst: TStringList;
  Arr: TJSONArray;
begin
  Src := TStringList.Create;
  try
    Src.Add('alpha');
    Src.Add('beta');
    Src.Add('gamma');
    Arr := TFVJsonHelper.StringListToJSON(Src);
    try
      Dst := TFVJsonHelper.JSONToStringList(Arr);
      try
        Assert.AreEqual(3, Dst.Count);
        Assert.AreEqual('alpha', Dst[0]);
        Assert.AreEqual('beta',  Dst[1]);
        Assert.AreEqual('gamma', Dst[2]);
      finally
        Dst.Free;
      end;
    finally
      Arr.Free;
    end;
  finally
    Src.Free;
  end;
end;

procedure TSerializationTests.Registry_CanCreate_KnownType;
begin
  TFVSerializerRegistry.RegisterType('test.dummy', MakeDummy);
  Assert.IsTrue(TFVSerializerRegistry.CanCreate('test.dummy'));
end;

procedure TSerializationTests.Registry_CreateFromTypeId;
var
  Obj: TObject;
begin
  TFVSerializerRegistry.RegisterType('test.dummy2', MakeDummy);
  Obj := TFVSerializerRegistry.CreateFromTypeId('test.dummy2');
  try
    Assert.IsNotNull(Obj);
    Assert.IsTrue(Obj is TDummyFactoryObject);
    Assert.AreEqual('made-by-factory', TDummyFactoryObject(Obj).Tag);
  finally
    Obj.Free;
  end;
end;

procedure TSerializationTests.Registry_UnknownType_ReturnsNil;
begin
  Assert.IsFalse(TFVSerializerRegistry.CanCreate('does.not.exist'));
  Assert.WillRaise(
    procedure
    begin
      TFVSerializerRegistry.CreateFromTypeId('does.not.exist');
    end,
    EFVSerializationError);
end;

initialization
  TDUnitX.RegisterTestFixture(TSerializationTests);

end.
