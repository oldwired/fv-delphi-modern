{*******************************************************}
{       Free Vision JSON Serialization                  }
{       Modern Delphi 12+ version                       }
{*******************************************************}

unit FVSerialization;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Generics.Collections,
  FVInterfaces;

type
  { Factory function type for creating objects from type ID }
  TFVObjectFactory = function: TObject;

  { Serialization registry - maps type IDs to factories }
  TFVSerializerRegistry = class
  private
    class var FFactories: TDictionary<string, TFVObjectFactory>;
    class constructor Create;
    class destructor Destroy;
  public
    class procedure RegisterType(const ATypeId: string; AFactory: TFVObjectFactory);
    class function CreateFromTypeId(const ATypeId: string): TObject;
    class function CanCreate(const ATypeId: string): Boolean;
  end;

  { Point record for serialization }
  TSerializablePoint = record
    X, Y: Integer;
  end;

  { Rect record for serialization }
  TSerializableRect = record
    A, B: TSerializablePoint;
  end;

  { JSON helper class for common serialization patterns }
  TFVJsonHelper = class
  public
    { Point serialization }
    class function PointToJSON(X, Y: Integer): TJSONObject; overload;
    class function PointToJSON(const P: TSerializablePoint): TJSONObject; overload;
    class function JSONToPoint(const J: TJSONObject): TSerializablePoint;

    { Rect serialization }
    class function RectToJSON(AX, AY, BX, BY: Integer): TJSONObject; overload;
    class function RectToJSON(const R: TSerializableRect): TJSONObject; overload;
    class function JSONToRect(const J: TJSONObject): TSerializableRect;

    { String list serialization }
    class function StringListToJSON(const List: TStrings): TJSONArray;
    class function JSONToStringList(const Arr: TJSONArray): TStringList;

    { Generic object serialization via ISerializable }
    class function SerializeObject(const Obj: TObject): TJSONObject;
    class function DeserializeObject(const Json: TJSONObject): TObject;
  end;

  { Exception for serialization errors }
  EFVSerializationError = class(Exception);

implementation

{ TFVSerializerRegistry }

class constructor TFVSerializerRegistry.Create;
begin
  FFactories := TDictionary<string, TFVObjectFactory>.Create;
end;

class destructor TFVSerializerRegistry.Destroy;
begin
  FFactories.Free;
end;

class procedure TFVSerializerRegistry.RegisterType(const ATypeId: string; AFactory: TFVObjectFactory);
begin
  FFactories.AddOrSetValue(ATypeId, AFactory);
end;

class function TFVSerializerRegistry.CreateFromTypeId(const ATypeId: string): TObject;
var
  Factory: TFVObjectFactory;
begin
  if FFactories.TryGetValue(ATypeId, Factory) then
    Result := Factory()
  else
    raise EFVSerializationError.CreateFmt('Unknown type ID: %s', [ATypeId]);
end;

class function TFVSerializerRegistry.CanCreate(const ATypeId: string): Boolean;
begin
  Result := FFactories.ContainsKey(ATypeId);
end;

{ TFVJsonHelper }

class function TFVJsonHelper.PointToJSON(X, Y: Integer): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('x', TJSONNumber.Create(X));
  Result.AddPair('y', TJSONNumber.Create(Y));
end;

class function TFVJsonHelper.PointToJSON(const P: TSerializablePoint): TJSONObject;
begin
  Result := PointToJSON(P.X, P.Y);
end;

class function TFVJsonHelper.JSONToPoint(const J: TJSONObject): TSerializablePoint;
begin
  if J = nil then begin
    Result.X := 0;
    Result.Y := 0;
    Exit;
  end;
  Result.X := J.GetValue<Integer>('x', 0);
  Result.Y := J.GetValue<Integer>('y', 0);
end;

class function TFVJsonHelper.RectToJSON(AX, AY, BX, BY: Integer): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('a', PointToJSON(AX, AY));
  Result.AddPair('b', PointToJSON(BX, BY));
end;

class function TFVJsonHelper.RectToJSON(const R: TSerializableRect): TJSONObject;
begin
  Result := RectToJSON(R.A.X, R.A.Y, R.B.X, R.B.Y);
end;

class function TFVJsonHelper.JSONToRect(const J: TJSONObject): TSerializableRect;
begin
  if J = nil then begin
    Result.A.X := 0;
    Result.A.Y := 0;
    Result.B.X := 0;
    Result.B.Y := 0;
    Exit;
  end;
  Result.A := JSONToPoint(J.GetValue<TJSONObject>('a'));
  Result.B := JSONToPoint(J.GetValue<TJSONObject>('b'));
end;

class function TFVJsonHelper.StringListToJSON(const List: TStrings): TJSONArray;
begin
  Result := TJSONArray.Create;
  if List <> nil then
    for var S in List do
      Result.Add(S);
end;

class function TFVJsonHelper.JSONToStringList(const Arr: TJSONArray): TStringList;
begin
  Result := TStringList.Create;
  if Arr <> nil then
    for var I := 0 to Arr.Count - 1 do
      Result.Add(Arr.Items[I].Value);
end;

class function TFVJsonHelper.SerializeObject(const Obj: TObject): TJSONObject;
var
  Serializable: ISerializable;
begin
  if Obj = nil then
    Result := nil
  else if Supports(Obj, ISerializable, Serializable) then
    Result := Serializable.ToJSON
  else
    raise EFVSerializationError.CreateFmt('Object %s does not support ISerializable', [Obj.ClassName]);
end;

class function TFVJsonHelper.DeserializeObject(const Json: TJSONObject): TObject;
var
  TypeId: string;
  Serializable: ISerializable;
begin
  if Json = nil then
    Exit(nil);

  TypeId := Json.GetValue<string>('_type', '');
  if TypeId = '' then
    raise EFVSerializationError.Create('JSON object missing _type field');

  Result := TFVSerializerRegistry.CreateFromTypeId(TypeId);
  if Supports(Result, ISerializable, Serializable) then
    Serializable.FromJSON(Json)
  else begin
    Result.Free;
    raise EFVSerializationError.CreateFmt('Created object does not support ISerializable: %s', [TypeId]);
  end;
end;

end.
