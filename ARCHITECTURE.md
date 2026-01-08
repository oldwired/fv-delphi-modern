# Free Vision Modern - Architecture

This document describes the architecture of the modernized Free Vision framework for Delphi 12+.

## Overview

Free Vision Modern is a text-mode UI framework that provides a complete widget toolkit for console applications. It follows a classic Model-View-Controller-inspired design with a hierarchical view system.

```
+------------------------------------------------------------------+
|                         TApplication                              |
|  +------------------------------------------------------------+  |
|  |  TMenuBar                                                   |  |
|  +------------------------------------------------------------+  |
|  |                        TDesktop                             |  |
|  |  +------------------+  +------------------+                 |  |
|  |  |    TWindow       |  |    TDialog       |                 |  |
|  |  |  +-----------+   |  |  +-----------+   |                 |  |
|  |  |  | TScroller |   |  |  | TButton   |   |                 |  |
|  |  |  +-----------+   |  |  +-----------+   |                 |  |
|  |  +------------------+  +------------------+                 |  |
|  +------------------------------------------------------------+  |
|  |  TStatusLine                                                |  |
|  +------------------------------------------------------------+  |
+------------------------------------------------------------------+
```

## Layer Architecture

```
+------------------------------------------------------------------+
|                    Application Layer                              |
|         App.pas: TApplication, TProgram, TDesktop                |
+------------------------------------------------------------------+
|                     Widget Layer                                  |
|    Dialogs.pas: TDialog, TButton, TInputLine, TListBox, etc.     |
|    Menus.pas: TMenuBar, TMenuBox, TStatusLine                    |
|    Editors.pas, ColorSel.pas, Outline.pas, Tabs.pas, etc.        |
+------------------------------------------------------------------+
|                      View Layer                                   |
|         Views.pas: TView, TGroup, TWindow, TFrame                |
+------------------------------------------------------------------+
|                    Driver Layer                                   |
|         Drivers.pas: Event queue, keyboard, mouse                |
|         Video.pas: Console output (Windows Console API)          |
+------------------------------------------------------------------+
|                   Foundation Layer                                |
|         Objects.pas: TFVStream, string helpers                   |
|         FVCommon.pas: Platform types                             |
|         FVInterfaces.pas: Interface definitions                  |
+------------------------------------------------------------------+
```

## Interface Hierarchy

All view classes implement these interfaces for consistent behavior:

```mermaid
classDiagram
    class IFVDrawable {
        <<interface>>
        +Draw()
        +DrawView()
    }

    class IFVEventHandler {
        <<interface>>
        +ClearEvent(Event)
    }

    class IFVDataAware {
        <<interface>>
        +DataSize() Word
        +GetData(Rec)
        +SetData(Rec)
        +Valid(Command) Boolean
    }

    class ISerializable {
        <<interface>>
        +ToJSON() TJSONObject
        +FromJSON(AJson)
        +GetTypeId() string
    }

    class TView {
        +Origin: TPoint
        +Size: TPoint
        +State: Word
        +Options: Word
    }

    TView ..|> IFVDrawable
    TView ..|> IFVEventHandler
    TView ..|> IFVDataAware
    TView ..|> ISerializable
```

### Interface Details

| Interface | Purpose | Key Methods |
|-----------|---------|-------------|
| `IFVDrawable` | Rendering capability | `Draw`, `DrawView` |
| `IFVEventHandler` | Event handling | `ClearEvent` |
| `IFVDataAware` | Data binding for dialogs | `GetData`, `SetData`, `Valid` |
| `ISerializable` | JSON persistence | `ToJSON`, `FromJSON`, `GetTypeId` |

**Note**: Reference counting is disabled (`_AddRef`/`_Release` return -1) so views are managed manually, not by interface references.

## Class Hierarchy

### Core View Hierarchy

```mermaid
classDiagram
    TObject <|-- TView
    TView <|-- TGroup
    TView <|-- TFrame
    TView <|-- TScrollBar
    TView <|-- TScroller
    TView <|-- TListViewer
    TView <|-- TMenuView
    TView <|-- TStatusLine
    TView <|-- TBackground

    TGroup <|-- TWindow
    TGroup <|-- TDesktop
    TGroup <|-- TProgram

    TWindow <|-- TDialog

    TProgram <|-- TApplication

    TMenuView <|-- TMenuBar
    TMenuView <|-- TMenuBox
    TMenuBox <|-- TMenuPopup
```

### ASCII Diagram: Core Views

```
TObject
    |
    +-- TView (implements IFVDrawable, IFVEventHandler, IFVDataAware, ISerializable)
          |
          +-- TGroup (container for child views)
          |     |
          |     +-- TWindow (framed, moveable window)
          |     |     |
          |     |     +-- TDialog (modal dialog)
          |     |
          |     +-- TDesktop (main application area)
          |     |
          |     +-- TProgram (application base)
          |           |
          |           +-- TApplication (full application with video init)
          |
          +-- TFrame (window frame decoration)
          |
          +-- TScrollBar (horizontal/vertical scrollbar)
          |
          +-- TScroller (scrollable content area)
          |
          +-- TListViewer (abstract list display)
          |
          +-- TMenuView (menu base)
          |     |
          |     +-- TMenuBar (horizontal menu bar)
          |     +-- TMenuBox (dropdown menu)
          |           |
          |           +-- TMenuPopup (context menu)
          |
          +-- TStatusLine (bottom status bar)
          |
          +-- TBackground (desktop background)
```

### Dialog Controls Hierarchy

```mermaid
classDiagram
    TView <|-- TInputLine
    TView <|-- TButton
    TView <|-- TCluster
    TView <|-- TStaticText
    TView <|-- THistory
    TListViewer <|-- TListBox
    TListViewer <|-- TStringListBox
    TListViewer <|-- THistoryViewer
    TWindow <|-- TDialog
    TWindow <|-- THistoryWindow

    TCluster <|-- TRadioButtons
    TCluster <|-- TCheckBoxes

    TStaticText <|-- TParamText
    TStaticText <|-- TLabel

    TListBox <|-- TSortedListBox
    TListBox <|-- TDirListBox
    TSortedListBox <|-- TFileList

    TDialog <|-- TFileDialog
    TDialog <|-- TChDirDialog
    TChDirDialog <|-- TEditChDirDialog

    TInputLine <|-- TFileInputLine
```

### ASCII Diagram: Dialog Controls

```
TView
    |
    +-- TInputLine (text input field)
    |     |
    |     +-- TFileInputLine (file path input)
    |
    +-- TButton (clickable button)
    |
    +-- TCluster (group of options)
    |     |
    |     +-- TRadioButtons (single selection)
    |     +-- TCheckBoxes (multiple selection)
    |
    +-- TStaticText (label/text display)
    |     |
    |     +-- TParamText (parameterized text)
    |     +-- TLabel (linked label)
    |
    +-- THistory (input history dropdown)
    |
    +-- TStringGrid (spreadsheet-like data grid)
    |
    +-- THexEditor (binary hex viewer/editor)

TListViewer
    |
    +-- TListBox (generic object list display)
    |     |
    |     +-- TSortedListBox (searchable list)
    |     |     |
    |     |     +-- TFileList (file listing)
    |     |
    |     +-- TDirListBox (directory tree)
    |
    +-- TStringListBox (string list display - uses TStringList)
    |
    +-- THistoryViewer (history popup list)

TDialog
    |
    +-- TFileDialog (file open/save)
    +-- TChDirDialog (change directory)
          |
          +-- TEditChDirDialog (editable directory)
```

### TStringGrid Architecture

The `TStringGrid` component provides a spreadsheet-like grid with the following structure:

```
TStringGrid (TView)
    |
    +-- FData: TDictionary<string, string>  (sparse cell storage, key="Col,Row")
    +-- FColumns: TGridColumns              (TObjectList<TGridColumn>)
    +-- FRowIDs: TList<Integer>             (row tracking for sort stability)
    +-- Selection state (FFocusedCell, FSelectedCells, FAnchorCell)
    +-- Scrolling (FTopRow, FLeftCol, scrollbars)
    +-- Edit state (FEditMode, FEditing, undo support)
    +-- Sort state (FSortColumn, FSortDirection)

TGridColumn
    +-- Title, Width, Alignment
    +-- MinWidth, MaxWidth
    +-- Sortable, Visible
    +-- Validator, DefaultValue

TCSVOptions
    +-- Delimiter (cdComma, cdSemicolon, cdTab, cdPipe, cdAuto)
    +-- CustomDelimiter (override with any char)
    +-- Encoding (ceUTF8BOM, ceUTF8, ceANSI)
    +-- HasHeaders, UseFixedHeaderRow
    +-- TrimWhitespace, AutoCreateColumns
```

#### CSV Import/Export Flow

```
LoadFromCSV          SaveToCSV
     |                    |
     v                    v
LoadFromCSVStream    SaveToCSVStream
     |                    |
     v                    v
LoadFromCSVString    SaveToCSVString
     |                    |
     +-- DetectDelimiter  +-- QuoteCSVField (RFC 4180)
     +-- ParseCSVLine     +-- GetDelimiterChar
```

### Stream Hierarchy

```
TObject
    |
    +-- TFVStream (abstract stream base)
          |
          +-- TDosStream (file stream)
          |     |
          |     +-- TBufStream (buffered file stream)
          |
          +-- TMemoryStream (memory-based stream)
```

### Validator Hierarchy

```
TObject
    |
    +-- TValidator (abstract input validator)
          |
          +-- TPXPictureValidator (picture mask validation)
          |
          +-- TFilterValidator (character filter)
          |     |
          |     +-- TRangeValidator (numeric range)
          |
          +-- TLookupValidator (lookup-based validation)
                |
                +-- TStringLookupValidator (string list lookup)
```

### Collection Types

The framework uses modern Delphi generics:

| Type | Usage | Notes |
|------|-------|-------|
| `TStringList` | String content in `TStringListBox` | Standard RTL class |
| `TObjectList<TObject>` | Generic objects in `TListBox`, file/dir entries | RTL generic, manual memory management |
| `TFileCollection` | File search results | Extends `TObjectList<TObject>`, stores `PSearchRec` |
| `TDirCollection` | Directory entries | Extends `TObjectList<TObject>`, stores `PDirEntry` |

## Event Flow

```
+-------------+     +---------+     +----------+     +--------+
| Keyboard/   | --> | Drivers | --> | TProgram | --> | TView  |
| Mouse Input |     | GetEvent|     | HandleEvent    | HandleEvent
+-------------+     +---------+     +----------+     +--------+
                                          |
                                          v
                                    +----------+
                                    | TGroup   |
                                    | (routes to|
                                    | children) |
                                    +----------+
```

Events flow from hardware through `Drivers.GetEvent`, are dispatched by `TProgram.HandleEvent`, and propagate down through the view hierarchy. Views call `ClearEvent` to indicate an event was handled.

## View Ownership

```
TApplication (owns)
    |
    +-- MenuBar (TMenuBar)
    +-- Desktop (TDesktop) (owns)
    |     |
    |     +-- Window1 (TWindow) (owns)
    |     |     +-- Frame, ScrollBars, Content...
    |     +-- Window2 (TDialog) (owns)
    |           +-- Buttons, InputLines, ListBoxes...
    +-- StatusLine (TStatusLine)
```

**Key Ownership Rules:**
- `TGroup.Insert(View)` transfers ownership to the group
- When a `TGroup` is destroyed, all owned views are automatically freed
- Use `TGroup.Delete(View)` to remove without freeing
- Use `TGroup.Dispose(View)` to remove and free

## Color Palette System

Views use a palette-based color system for consistent theming:

```
TApplication.GetPalette (96+ colors)
    |
    +-- TWindow.GetPalette (8 colors, mapped from app palette)
          |
          +-- TButton.GetPalette (8 colors, mapped from window)
```

Each view's `GetColor(Index)` resolves through the palette chain to the application's master palette.

## Unicode Drawing System

The framework uses a Unicode-capable drawing system based on `TDrawCell`:

### Core Types

```pascal
type
  TDrawCell = record
    Ch: string;   // Unicode character (can be multi-byte)
    Attr: Word;   // Color attribute (foreground + background)
  end;

  TDrawBuffer = array[0..MaxViewWidth-1] of TDrawCell;
```

### Drawing Routines (Drivers.pas)

| Routine | Purpose | Parameters |
|---------|---------|------------|
| `DrawChar` | Fill cells with a character | `Buf, Pos, Ch, Attr, Count` |
| `DrawStr` | Draw a string | `Buf, Pos, Str, Attr` |
| `DrawCStr` | Draw string with `~` highlight markers | `Buf, Pos, Str, Attrs` |
| `DrawBuf` | Copy between draw buffers | `Dest, DestPos, Source, SourcePos, Count` |

### Rendering Flow

```
Draw routines     WriteBuf/WriteLine     WriteView        Video.pas
(DrawChar, etc.)  (in TView)            (clips to owner)  (console output)
     |                  |                     |                |
     v                  v                     v                v
TDrawBuffer  -->  Screen coords  -->  Clipped region  -->  Console API
```

1. **Views build content**: `Draw` method fills a `TDrawBuffer` using `DrawChar`/`DrawStr`/`DrawCStr`
2. **Views output to screen**: Call `WriteBuf` or `WriteLine` with coordinates and buffer
3. **Clipping applied**: `WriteView` clips output to visible region within parent groups
4. **Console output**: `Video.pas` writes cells to Windows Console via `WriteConsoleOutputW`

### Example: TView.Draw

```pascal
procedure TView.Draw;
var
  B: TDrawBuffer;
begin
  DrawChar(B, 0, ' ', GetColor($01), Size.X);  // Fill with spaces
  WriteLine(0, 0, Size.X, Size.Y, B);          // Output to screen
end;
```

### Helper Methods in TView

| Method | Purpose |
|--------|---------|
| `WriteStr(X, Y, Str, Color)` | Draw a string at position |
| `WriteChar(X, Y, Ch, Color, Count)` | Draw repeated character |
| `WriteBuf(X, Y, W, H, Buf)` | Output buffer region |
| `WriteLine(X, Y, W, H, Buf)` | Output buffer as repeated lines |

## Serialization Architecture

```mermaid
flowchart LR
    A[TView] -->|ToJSON| B[TJSONObject]
    B -->|FromJSON| A
    C[TFVSerializerRegistry] -->|RegisterType| D[Type Registry]
    D -->|CreateFromTypeId| A
```

JSON serialization is implemented via `ISerializable`:

```pascal
function TView.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('_type', GetTypeId);
  Result.AddPair('origin', PointToJSON(Origin));
  Result.AddPair('size', PointToJSON(Size));
  // ... additional properties
end;
```

## File Organization

```
src/
  FVCommon.pas        Platform types (Sw_Word, PString, etc.)
  FVInterfaces.pas    Interface definitions (IFVDrawable, ISerializable, etc.)
  FVSerialization.pas JSON serialization helpers and registry
  Objects.pas         Stream classes, string utilities
  Video.pas           Console output (Windows Console API)
  Drivers.pas         Input handling, event queue
  Views.pas           Core view classes (TView, TGroup, TWindow)
  Menus.pas           Menu system (TMenuBar, TMenuBox, TStatusLine)
  App.pas             Application framework (TApplication)
  Dialogs.pas         Dialog controls (TDialog, TButton, TInputLine, etc.)
  Grid.pas            TStringGrid component with CSV import/export
  HexEdit.pas         THexEditor binary viewer/editor
  Validate.pas        Input validators
  MsgBox.pas          Message box helpers
  StdDlg.pas          File dialogs (TFileDialog, TChDirDialog)
  Editors.pas         Text editor component
  ColorSel.pas        Color selection dialog
  Outline.pas         Tree/outline view
  Tabs.pas            Tab control
  Statuses.pas        Progress indicators
  Gadgets.pas         Clock, heap views
  HistList.pas        Input history management
  fvconsts.pas        String constants
```

## Memory Management

| Pattern | Usage |
|---------|-------|
| `TClass.Create(...)` | Object creation |
| `Object.Free` or `FreeAndNil(Object)` | Object destruction |
| `TGroup` ownership | Views freed when parent group destroyed |
| `TObjectList<T>` with `OwnsObjects=False` | Collections of record pointers |

## Build Configuration

- **Platform**: Win32 (32-bit Windows)
- **Configuration**: Debug for development
- **Range checking**: OFF (`{$R-}`) in units with pointer arithmetic
- **Test application**: `FVTest.exe`
