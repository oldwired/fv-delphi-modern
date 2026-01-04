# Porting Guide: Classic FV-Delphi to FV-Delphi-Modern

This guide helps you migrate applications from classic Free Vision (using `object` syntax) to the modern version (using `class` syntax).

## Quick Reference

| Aspect | Classic (object) | Modern (class) |
|--------|------------------|----------------|
| Type definition | `TView = object(TParent)` | `TView = class(TParent)` |
| Creation | `New(P, Init(...))` | `P := TType.Create(...)` |
| Destruction | `P.Done; Dispose(P)` | `FreeAndNil(P)` |
| Pointer types | `PView = ^TView` | Just use `TView` |
| Override methods | `procedure X; virtual;` | `procedure X; override;` |
| Constructor | `constructor Init(...)` | `constructor Create(...); reintroduce; virtual;` |
| Destructor | `destructor Done; virtual;` | `destructor Destroy; override;` |
| Stream class | `TStream` | `TFVStream` |
| Collections | `TCollection`, `TStringCollection` | `TObjectList<T>`, `TStringList` |

---

## 1. Object Creation

```pascal
// CLASSIC
var
  P: PView;
begin
  New(P, Init(Bounds));
  P^.Show;
end;

// MODERN
var
  P: TView;
begin
  P := TView.Create(Bounds);
  P.Show;
end;
```

**Search & Replace:**
- `New(P, Init(` → `P := TType.Create(`
- Remove trailing `))`  → `)`
- `P^.` → `P.`

---

## 2. Object Destruction

```pascal
// CLASSIC
P^.Done;
Dispose(P);

// MODERN
FreeAndNil(P);
// Or just: P.Free;
```

**Search & Replace:**
- `P^.Done; Dispose(P);` → `FreeAndNil(P);`
- `.Done;` → `.Free;` (if standalone)

---

## 3. Pointer Type Declarations

Remove all `P` pointer aliases from variable declarations:

```pascal
// CLASSIC
var
  MyWindow: PWindow;
  MyDialog: PDialog;
  MyButton: PButton;

// MODERN
var
  MyWindow: TWindow;
  MyDialog: TDialog;
  MyButton: TButton;
```

**Search & Replace (variables/parameters):**
- `PView` → `TView`
- `PGroup` → `TGroup`
- `PWindow` → `TWindow`
- `PDialog` → `TDialog`
- `PButton` → `TButton`
- `PInputLine` → `TInputLine`
- `PScrollBar` → `TScrollBar`
- `PMenuBar` → `TMenuBar`
- `PStatusLine` → `TStatusLine`
- `PCollection` → `TObjectList<TObject>`
- `PStringCollection` → `TStringList`

**Keep as-is:** `PString` (this IS an actual pointer to ShortString)

---

## 4. Virtual Method Overrides (CRITICAL!)

In `object` syntax, redeclaring `virtual` automatically overrides. In `class` syntax, you MUST use `override`:

```pascal
// CLASSIC - redeclaring 'virtual' overrides parent
TMyView = object(TView)
  procedure HandleEvent(var Event: TEvent); virtual;
  procedure Draw; virtual;
end;

// MODERN - MUST use 'override'
TMyView = class(TView)
  procedure HandleEvent(var Event: TEvent); override;
  procedure Draw; override;
end;
```

**Warning:** Using `virtual` instead of `override` will HIDE the parent method, causing:
- Events not processed (`HandleEvent` not called)
- Views not drawn (`Draw` not called)
- Infinite loops or silent failures

**Compiler warning to watch:** `Method 'X' hides virtual method from base type`

---

## 5. Constructor and Destructor Declarations

```pascal
// CLASSIC
TMyDialog = object(TDialog)
  constructor Init(var Bounds: TRect; ATitle: TTitleStr);
  destructor Done; virtual;
end;

// MODERN
TMyDialog = class(TDialog)
  constructor Create(var Bounds: TRect; ATitle: TTitleStr); reintroduce; virtual;
  destructor Destroy; override;
end;
```

**Changes:**
- `Init` → `Create`
- `Done` → `Destroy`
- Add `reintroduce; virtual;` to constructors with different parameters
- Add `override` to destructors

---

## 6. Constructor/Destructor Implementation

```pascal
// CLASSIC
constructor TMyDialog.Init(var Bounds: TRect; ATitle: TTitleStr);
begin
  inherited Init(Bounds, ATitle);
  // ... field initialization
  Strings.Init(10, 5);  // Inline collection init
end;

destructor TMyDialog.Done;
begin
  Strings.Done;  // Inline collection cleanup
  inherited Done;
end;

// MODERN
constructor TMyDialog.Create(var Bounds: TRect; ATitle: TTitleStr);
begin
  inherited Create(Bounds, ATitle);
  // ... field initialization
  FStrings := TStringList.Create;  // Create object
end;

destructor TMyDialog.Destroy;
begin
  FreeAndNil(FStrings);  // Free object
  inherited Destroy;
end;
```

---

## 7. Stream Class Rename

The stream class was renamed to avoid conflicts with Delphi's RTL:

```pascal
// CLASSIC
var S: TStream;

// MODERN
var S: TFVStream;
```

Also update method parameters:
```pascal
// CLASSIC
procedure Store(var S: TStream);
constructor Load(var S: TStream);

// MODERN
procedure Store(var S: TFVStream);
constructor Load(var S: TFVStream); override;
```

---

## 8. Collections

### String Collections

```pascal
// CLASSIC
var
  Strings: TStringCollection;
begin
  Strings.Init(10, 5);
  Strings.Insert(NewStr('Item'));
  S := PString(Strings.At(0))^;
  Strings.Done;
end;

// MODERN
var
  Strings: TStringList;
begin
  Strings := TStringList.Create;
  Strings.Add('Item');
  S := Strings[0];
  FreeAndNil(Strings);
end;
```

### Object Collections

```pascal
// CLASSIC
var
  List: PCollection;
begin
  New(List, Init(10, 5));
  List^.Insert(SomeObject);
  Obj := List^.At(0);
  Dispose(List, Done);
end;

// MODERN
var
  List: TObjectList<TObject>;
begin
  List := TObjectList<TObject>.Create;
  List.Add(SomeObject);
  Obj := List[0];
  FreeAndNil(List);
end;
```

---

## 9. Uses Clause Updates

Add these units for generics and JSON support:

```pascal
uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,  // For TObjectList<T>
  // ... FV units
  Objects, Drivers, Views, Menus, Dialogs, App;
```

---

## 10. Common Patterns

### Application Skeleton

```pascal
// CLASSIC
var
  MyApp: TMyApplication;
begin
  MyApp.Init;
  MyApp.Run;
  MyApp.Done;
end.

// MODERN
var
  MyApp: TMyApplication;
begin
  MyApp := TMyApplication.Create;
  MyApp.Run;
  FreeAndNil(MyApp);
end.
```

### Dialog Creation

```pascal
// CLASSIC
var
  D: PDialog;
  R: TRect;
begin
  R.Assign(0, 0, 40, 10);
  New(D, Init(R, 'Title'));
  R.Assign(2, 2, 12, 4);
  D^.Insert(New(PButton, Init(R, '~O~K', cmOK, bfDefault)));
  Desktop^.ExecView(D);
  Dispose(D, Done);
end;

// MODERN
var
  D: TDialog;
  R: TRect;
begin
  R.Assign(0, 0, 40, 10);
  D := TDialog.Create(R, 'Title');
  R.Assign(2, 2, 12, 4);
  D.Insert(TButton.Create(R, '~O~K', cmOK, bfDefault));
  Desktop.ExecView(D);
  FreeAndNil(D);
end;
```

### Custom View Class

```pascal
// CLASSIC
type
  PMyView = ^TMyView;
  TMyView = object(TView)
    constructor Init(var Bounds: TRect);
    procedure Draw; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

// MODERN
type
  TMyView = class(TView)
    constructor Create(var Bounds: TRect); reintroduce; virtual;
    procedure Draw; override;
    procedure HandleEvent(var Event: TEvent); override;
  end;
```

---

## Porting Checklist

- [ ] Replace all `New(P, Init(` with `P := TType.Create(`
- [ ] Replace all `Dispose(P, Done)` / `P.Done` with `FreeAndNil(P)`
- [ ] Change `PView`, `PDialog`, etc. to `TView`, `TDialog`, etc.
- [ ] Change all `virtual` overrides to `override` in derived classes
- [ ] Rename `Init` constructors to `Create`
- [ ] Rename `Done` destructors to `Destroy`
- [ ] Change `TStream` to `TFVStream`
- [ ] Replace `TCollection` with `TObjectList<T>`
- [ ] Replace `TStringCollection` with `TStringList`
- [ ] Add `System.Generics.Collections` to uses clause
- [ ] Remove `^` dereference operators (e.g., `P^.Show` → `P.Show`)
- [ ] Test all menu options and dialogs after porting

---

## Build & Test

```bash
# Build with Win32/Debug
msbuild YourProject.dproj /p:Platform=Win32 /p:Config=Debug
```

Watch for compiler warnings - especially:
- `Method 'X' hides virtual method` → Need `override`
- Implicit string conversions → Usually safe, but verify

---

## Reference

- Original FV: `C:\projects\fv-delphi` (object syntax)
- Modern FV: `C:\projects\fv-delphi-modern` (class syntax)
- Architecture: See `ARCHITECTURE.md`
- Claude Code guidance: See `CLAUDE.md`
