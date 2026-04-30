# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a port of the Free Vision (FV) text-mode UI framework from Free Pascal to modern Delphi (12+). Free Vision is a classic console-based GUI toolkit originally from Turbo Pascal.

**Status**: Fully modernized with:
- Delphi `CLASS` syntax (converted from legacy `OBJECT` syntax)
- Interface-based design (`IFVDrawable`, `IFVEventHandler`, `IFVDataAware`, `ISerializable`)
- RTL generics (`TObjectList<T>`, `TStringList`) instead of custom collections
- JSON serialization infrastructure
- Full Unicode support via `TDrawCell`-based drawing system

## CRITICAL: OBJECT to CLASS Conversion Rules

When converting from OBJECT to CLASS syntax, these patterns MUST be followed:

### 1. Virtual Method Overrides - USE `override`, NOT `virtual`

```pascal
// OBJECT syntax (old) - redeclaring 'virtual' automatically overrides
TChild = object(TParent)
  procedure DoSomething; virtual;  { Overrides parent }
end;

// CLASS syntax (new) - MUST use 'override' explicitly
TChild = class(TParent)
  procedure DoSomething; virtual;  { WRONG - hides parent method! }
  procedure DoSomething; override; { CORRECT - overrides parent }
end;
```

**Compiler warning to watch for:** "Method 'X' hides virtual method from base type" - this indicates a missing `override`.

**Bugs caused by this mistake:**
- `GetEvent`/`PutEvent` not being called → events not processed
- `Execute` not being called → infinite loops or no response
- Any polymorphic method dispatch silently failing

### 2. Field Initialization - USE assignment, NOT method call

```pascal
// OBJECT syntax (old) - fields are inline, Init modifies existing memory
Strings.Init(10, 5);

// CLASS syntax (new) - fields are references, must create object
Strings := TStringCollection.Create(10, 5);
```

### 3. Destructor Pattern

```pascal
// OBJECT syntax (old)
destructor Done; virtual;
Strings.Done;

// CLASS syntax (new)
destructor Destroy; override;
Strings.Free;  // or FreeAndNil(Strings)
```

### 4. Object Creation

```pascal
// OBJECT syntax (old)
New(PView, Init(R));

// CLASS syntax (new)
P := TView.Create(R);
```

## Original source code

The original sourcecode for free vision is in C:\temp\fpc\fpc\packages\fv reference it as necessary.

## Build Commands

Use the MCP build tool with **Win32** platform and **Debug** configuration:

`mcp__dbuildmcp__msbuild with projectfile="C:/projects/fv-delphi-modern/FVTest.dproj", platform="Win32", config="Debug"`

**Important**: Always use Win32/Debug during development. The project targets 32-bit Windows.

## Testing

There is no automated test suite. Testing is done via the interactive `FVTest.exe` application:

```bash
# Run after building
FVTest.exe
```

The test app exercises all ported widgets through menu options (Test menu). Debug output is written to `fvtest.log`.

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed diagrams.

### Core Layering (bottom to top)
1. **FVCommon.pas** - Platform types (`Sw_Word`)
2. **FVInterfaces.pas** - Interface definitions (`IFVDrawable`, `IFVEventHandler`, `IFVDataAware`, `ISerializable`)
3. **FVSerialization.pas** - JSON serialization registry and helpers
4. **Objects.pas** - Stream classes (`TFVStream`, `TDosStream`, `TBufStream`), string utilities
5. **FVScreen.pas** - Console output via Windows Console API, `TDrawCell`-based rendering
6. **Drivers.pas** - Input handling (keyboard, mouse, event queue)
7. **Views.pas** - View hierarchy (`TView`, `TGroup`, `TWindow`, `TDesktop`)
8. **Menus.pas** - Menu system (`TMenuBar`, `TMenuBox`, `TStatusLine`)
9. **App.pas** - Application framework (`TProgram`, `TApplication`)
10. **Dialogs.pas** - Dialog controls (`TDialog`, `TButton`, `TInputLine`, `TListBox`, `TStringListBox`, etc.)

### Interface System
All views implement these interfaces (with reference counting disabled):
- `IFVDrawable` - `Draw`, `DrawView`
- `IFVEventHandler` - `ClearEvent`
- `IFVDataAware` - `GetData`, `SetData`, `Valid`, `DataSize`
- `ISerializable` - `ToJSON`, `FromJSON`, `GetTypeId`

### Extended Components
- **MsgBox.pas, StdDlg.pas** - Standard dialogs (message boxes, file dialogs)
- **Validate.pas** - Input validators (`TValidator` hierarchy)
- **Gadgets.pas** - `TClockView`, `THeapView`
- **Tabs.pas** - Tab control
- **TimedDlg.pas** - Auto-closing dialogs
- **ColorTxt.pas, InpLong.pas, AsciiTab.pas** - Specialized widgets

### Capability / Width Infrastructure
- **FVUnicodeWidth.pas** - Unicode 15.1 cell-width tables (wide / zero ranges) consumed by `FVUTF8.CodePointCharWidth`. Adapted from VSoft.AnsiConsole (MIT) - see Acknowledgments in `README.md`.
- **FVProfile.pas** - Singleton terminal-capability profile (`TFVColorSystem`, ANSI/VT probe, NO_COLOR / CLICOLOR_FORCE, CI sniff, hyperlink + Sixel detection). `FVScreen.UpdateScreen` consults `GetFVProfile.ColorSystem` to downsample 24-bit RGB to 256-cube / nearest-of-16 / suppressed.

### New Components (11 additional widgets)
- **ProgressBar.pas** - `TProgressBar` single-line visual indicator
- **Breadcrumb.pas** - `TBreadcrumb` clickable path navigation
- **ToolBar.pas** - `TToolBar` horizontal button bar (`TStatusLine` linked-list pattern)
- **ComboBox.pas** - `TComboBox`, `TComboViewer`, `TComboWindow` dropdown select (`THistory` pattern)
- **Splitter.pas** - `TSplitter` draggable divider + `TSplitGroup` convenience container
- **Accordion.pas** - `TAccordion` collapsible sections with `TAccordionHeader`
- **EditorGutter.pas** - `TEditorGutter` with pluggable providers (`TLineNumberProvider`, `TBookmarkProvider`, `TBreakpointProvider`, `TDiffProvider`)
- **Notification.pas** - `TNotification` non-modal auto-dismissing toast popup
- **SpinnerView.pas** - `TSpinnerView` animated spinner (12 named frame sets - dots, line, arc, bouncing-bar, etc.). Self-paced via `GetTickCount64`; drive `Update` from your idle loop.
- **TaskProgress.pas** - `TTaskProgress` multi-task progress widget (caption | spinner | bar | percent | ETA per row). Coexists with `TProgressBar`; not a replacement.
- **CheckListBox.pas** - `TCheckListBox` descends from `TStringListBox`, adds per-row Boolean state with `[ ]/[x]` prefix. Space toggles, Enter accepts, `CheckedItems` returns the picked rows.

## Code Conventions

### Type System
- Use `string` (UnicodeString) throughout
- Use `THandle` from `Winapi.Windows` for file handles
- CPU-native types: `CPUWord`, `CPUInt`, `PtrInt`

### Compiler Directives
- Range checking OFF (`{$R-}`) in units with pointer arithmetic
- Target: Windows-only Delphi 12+

### Memory Management
- Views are owned by their parent `TGroup` and freed automatically when the group is destroyed
- Use `TTypeName.Create(...)` for object creation
- Call `P.Free` or `FreeAndNil(P)` for cleanup
- Pointer type aliases like `PView = TView` are used for compatibility (not actual pointers)
- Interface references don't affect lifetime (`_AddRef`/`_Release` return -1)

### Collections
- Use `TStringList` for string content (e.g., `TStringListBox.Strings`)
- Use `TObjectList<TObject>` for generic objects (e.g., `TListBox.List`)
- File/directory collections extend `TObjectList<TObject>` with manual memory management

## Porting Status

Core port is complete. All widgets functional and tested via FVTest.exe.

**Modernization phases completed:**
1. OBJECT to CLASS syntax conversion
2. FreeAndNil replacement, P-alias removal
3. Interface system, RTL generics, JSON serialization infrastructure
