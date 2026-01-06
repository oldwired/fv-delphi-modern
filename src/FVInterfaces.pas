{*******************************************************}
{       Free Vision Interface Definitions               }
{       Modern Delphi 12+ version                       }
{*******************************************************}

unit FVInterfaces;

interface

uses
  System.JSON, Drivers;

type
  { IFVDrawable - for views that can render themselves }
  IFVDrawable = interface
    ['{A7E8C1D2-3F4B-5A6C-7D8E-9F0A1B2C3D4E}']
    procedure Draw;
    procedure DrawView;
  end;

  { IFVEventHandler - for views that handle events }
  IFVEventHandler = interface
    ['{B8F9D2E3-4A5C-6B7D-8E9F-0A1B2C3D4E5F}']
    procedure ClearEvent(var Event: TEvent);
  end;

  { IFVDataAware - for views with data binding capability }
  IFVDataAware = interface
    ['{C9A0E3F4-5B6D-7C8E-9F0A-1B2C3D4E5F60}']
    function DataSize: Word;
    procedure GetData(var Rec);
    procedure SetData(var Rec);
    function Valid(Command: Word): Boolean;
  end;

  { ISerializable - for JSON persistence }
  ISerializable = interface
    ['{D0B1F4A5-6C7E-8D9F-0A1B-2C3D4E5F6071}']
    function ToJSON: TJSONObject;
    procedure FromJSON(const AJson: TJSONObject);
    function GetTypeId: string;
  end;

  { Serialization attribute definitions }
  JsonSerializableAttribute = class(TCustomAttribute)
  end;

  JsonNameAttribute = class(TCustomAttribute)
  private
    FName: string;
  public
    constructor Create(const AName: string);
    property Name: string read FName;
  end;

  JsonIgnoreAttribute = class(TCustomAttribute)
  end;

implementation

{ JsonNameAttribute }

constructor JsonNameAttribute.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
end;

end.
