# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a port of the Free Vision (FV) text-mode UI framework from Free Pascal to modern Delphi (10.x, 11.x, 12.x). Free Vision is a classic console-based GUI toolkit originally from Turbo Pascal.

**Status**: The codebase has been converted from legacy Turbo Pascal `OBJECT` syntax to modern Delphi `CLASS` syntax.

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

`mcp__dbuildmcp__msbuild with projectfile="C:/projects/fv-delphi/FVTest.dproj", platform="Win32", config="Debug"`

**Important**: Always use Win32/Debug during development. The project targets 32-bit Windows.

## Testing

There is no automated test suite. Testing is done via the interactive `FVTest.exe` application:

```bash
# Run after building
FVTest.exe
```

The test app exercises all ported widgets through menu options (Test menu). Debug output is written to `fvtest.log`.

## Architecture

### Core Layering (bottom to top)
1. **FVCommon.pas** - Platform types (`Sw_Word`, `Sw_String = ShortString`, `PString`)
2. **Objects.pas** - Base object system, streams, collections (`TObject`, `TStream`, `TCollection`)
3. **Video.pas** - Console output via Windows Console API
4. **Drivers.pas** - Input handling (keyboard, mouse, event queue)
5. **Views.pas** - View hierarchy (`TView`, `TGroup`, `TWindow`, `TDesktop`)
6. **Menus.pas** - Menu system (`TMenuBar`, `TMenuBox`, `TStatusLine`)
7. **App.pas** - Application framework (`TProgram`, `TApplication`)
8. **Dialogs.pas** - Dialog controls (`TDialog`, `TButton`, `TInputLine`, `TCheckBoxes`, etc.)

### Extended Components
- **MsgBox.pas, StdDlg.pas** - Standard dialogs (message boxes, file dialogs)
- **Validate.pas** - Input validators
- **Gadgets.pas** - `TClockView`, `THeapView`
- **Tabs.pas** - Tab control
- **TimedDlg.pas** - Auto-closing dialogs
- **ColorTxt.pas, InpLong.pas, AsciiTab.pas** - Specialized widgets

### Platform Abstraction
`src/platform.inc` handles compiler/platform detection. Key defines:
- `PPC_DELPHI` / `PPC_FPC` - Compiler type
- `BIT_32` / `BIT_64` - Architecture
- `OS_WINDOWS` - Target OS

## Code Conventions

### Type System
- Use `ShortString` (aliased as `Sw_String`) for FV string types
- Use `PString` (pointer to ShortString) with `NewStr`/`DisposeStr` from Objects.pas
- Use `THandle` from `Winapi.Windows` for file handles
- CPU-native types: `CPUWord`, `CPUInt`, `PtrInt`

### Compiler Directives
- Range checking OFF (`{$R-}`) in units with pointer arithmetic
- Warnings suppressed for legacy patterns (see platform.inc)
- Include `{$I platform.inc}` at the top of source units

### Memory Management
- Views are owned by their parent `TGroup` and freed automatically when the group is destroyed
- Use `TTypeName.Create(...)` for object creation
- Call `P.Free` or `FreeAndNil(P)` for cleanup
- Pointer type aliases like `PView = TView` are used for compatibility (not actual pointers)

## Porting Status

See `PORTING_STATUS.txt` for detailed status. Core functionality is complete. Recently ported:
- **Editors.pas** - Text editor (compiles, needs testing)
- **ColorSel.pas** - Color selection dialogs
- **Outline.pas** - Tree view (with mousewheel support)

## Known Issues

- Console window resize causes visual artifacts (resize not handled)
- Some units use FPC-specific features like `get_caller_frame` that need alternatives in Delphi
