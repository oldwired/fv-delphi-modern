# Free Vision Modern (fv-delphi-modern)

An experimental port of the Free Vision (FV) text-mode UI framework from Free Pascal to modern Delphi (13.x).

Free Vision is a classic console-based GUI toolkit originally derived from Borland's Turbo Vision. This **modern variant** uses Delphi `CLASS` syntax instead of the legacy Turbo Pascal `OBJECT` syntax, providing better IDE integration, proper inheritance, and modern memory management.

## Features

- **Complete TUI Framework**: Windows, dialogs, menus, status bars, buttons, input fields, and more
- **Text Editor**: Full-featured editor with find/replace, clipboard, undo, and file operations
- **Standard Dialogs**: Message boxes, file open/save dialogs, color selection, ASCII table
- **Advanced Controls**: Tab controls, outline/tree views, progress gauges, timed dialogs
- **Input Validation**: Built-in validators for ranges, patterns, and lookups
- **Windows Console**: Native Windows Console API for display and input

## Requirements

- Delphi 13.x
- Windows 32-bit or 64-bit target

## Getting Started

1. Open `FVTest.dproj` in the Delphi IDE
2. Build and run the project
3. Explore the Test menu to see various components in action

### Minimal Application

```pascal
program MyApp;

uses
  App, Views, Menus, Drivers;

type
  TMyApp = class(TApplication)
    procedure InitMenuBar; override;
    procedure InitStatusLine; override;
  end;

procedure TMyApp.InitMenuBar;
var
  R: TRect;
begin
  GetExtent(R);
  R.B.Y := R.A.Y + 1;
  MenuBar := TMenuBar.Create(R, NewMenu(
    NewSubMenu('~F~ile', hcNoContext, NewMenu(
      NewItem('E~x~it', 'Alt-X', kbAltX, cmQuit, hcNoContext, nil)),
    nil)));
end;

procedure TMyApp.InitStatusLine;
var
  R: TRect;
begin
  GetExtent(R);
  R.A.Y := R.B.Y - 1;
  StatusLine := TStatusLine.Create(R,
    NewStatusDef(0, $FFFF,
      NewStatusKey('~Alt-X~ Exit', kbAltX, cmQuit, nil),
    nil));
end;

var
  App: TMyApp;
begin
  App := TMyApp.Create;
  App.Run;
  App.Free;
end.
```

## Project Structure

```
src/
  FVCommon.pas    - Common types and definitions
  Objects.pas     - Base object system, streams, collections
  Video.pas       - Console output abstraction
  Drivers.pas     - Keyboard and mouse input handling
  Views.pas       - View hierarchy (TView, TGroup, TWindow, etc.)
  Menus.pas       - Menu system (TMenuBar, TMenuBox, TStatusLine)
  App.pas         - Application framework (TApplication)
  Dialogs.pas     - Dialog controls (TDialog, TButton, TInputLine, etc.)
  Validate.pas    - Input validation
  MsgBox.pas      - Message box helpers
  StdDlg.pas      - Standard file dialogs
  Editors.pas     - Text editor components
  ColorSel.pas    - Color selection dialog
  Outline.pas     - Tree/outline view
  Tabs.pas        - Tab control
  Statuses.pas    - Progress gauges
  Gadgets.pas     - Clock and heap views
  ...
```

## Porting Notes

- Uses modern Delphi `CLASS` syntax with proper inheritance and `override`
- `TClass.Create` / `Object.Free` instead of `New(P, Init)` / `Dispose(P, Done)`
- Pointer types aliased for compatibility: `PView = TView`
- `ShortString` used for FV string types (`Sw_String`, `PString`)
- Windows Console API for video output and input
- Range checking should be OFF on Project level

## Known Limitations

1. **ANSI Encoding**: Editor uses ANSI encoding; UTF-8 files may not display correctly
2. New **edge-cases**, **oversights** or **errors** may be introduced in this project

## License

This library is distributed under the **GNU Lesser General Public License (LGPL)** with the following linking exception:

> As a special exception, the copyright holders of this library give you
> permission to link this library with independent modules to produce an
> executable, regardless of the license terms of these independent modules,
> and to copy and distribute the resulting executable under terms of your choice,
> provided that you also meet, for each linked independent module, the terms
> and conditions of the license of that module. An independent module is a module
> which is not derived from or based on this library. If you modify this
> library, you may extend this exception to your version of the library, but you are
> not obligated to do so. If you do not wish to do so, delete this exception
> statement from your version.

See `COPYING.TXT` for the complete license text.

## Credits

- Original Turbo Vision by Borland International
- Free Vision by the Free Pascal Development Team
- Delphi port by Claude Code (Anthropic)

## Contributing

Bug reports and contributions are welcome. Please ensure any modifications maintain compatibility with the original Free Vision API where possible.