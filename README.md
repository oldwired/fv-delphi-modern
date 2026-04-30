# Free Vision Modern (fv-delphi-modern)

A modernized port of the Free Vision (FV) text-mode UI framework from Free Pascal to modern Delphi (12+).

Free Vision is a classic console-based GUI toolkit originally derived from Borland's Turbo Vision. This **modern variant** uses Delphi `CLASS` syntax instead of the legacy Turbo Pascal `OBJECT` syntax, providing better IDE integration, proper inheritance, and modern memory management.

## Features

- **Complete TUI Framework**: Windows, dialogs, menus, status bars, buttons, input fields, and more
- **Modern Architecture**: Interfaces (`IFVDrawable`, `ISerializable`), RTL generics (`TObjectList<T>`, `TStringList`)
- **Full Unicode Support**: Double-width characters, emoji, and CJK glyphs rendered correctly throughout the framework via `TDrawCell`-based drawing system
- **Text Editor**: Full-featured editor with find/replace, clipboard, undo, and file operations
- **Hex Editor**: Binary file viewer/editor with hex and ASCII modes
- **String Grid**: Spreadsheet-like grid with sorting, editing, selection, and CSV import/export
- **Standard Dialogs**: Message boxes, file open/save dialogs, color selection, ASCII table
- **Advanced Controls**: Tab controls, outline/tree views, progress gauges, timed dialogs
- **Layout Components**: Splitter panels with draggable divider, accordion with collapsible sections
- **Extended Widgets**: Toolbar, breadcrumb navigation, combo box dropdown, progress bar, editor gutter with pluggable providers, toast notifications, animated spinner, multi-task progress with ETA, checkbox list-box for multi-select
- **Terminal Capability Profile**: `FVProfile` probes VT support, color depth (no-color / 16 / 256 / 24-bit), interactivity, CI environment, hyperlink + Sixel support; `NO_COLOR` and `CLICOLOR_FORCE` honored. `FVScreen.UpdateScreen` downsamples 24-bit RGB to the host's color system.
- **Unicode 15.1 Width Tables**: `FVUnicodeWidth` provides correct wide / combining / zero-width measurement for emoji, CJK, ZWJ joiners, and variation selectors.
- **SIXEL Graphics**: Adaptive 256-color SIXEL encoder, direct SIXEL canvas drawing, and BMP/SIXEL image viewer
- **Input Validation**: Built-in validators for ranges, patterns, and lookups
- **JSON Serialization**: Views implement `ISerializable` for state persistence
- **Windows Console**: Native Windows Console API for display and input
- **Terminal Emulator**: Pseudo-terminal windows using Windows ConPTY

## SIXEL Graphics

SIXEL support is optimized for Windows Terminal sessions and integrates with the normal Free Vision view system.

### What is supported

- `TSixelEncoder` (`src/SixelEncoder.pas`): converts `TPixelGrid` data (`$00RRGGBB`) to SIXEL DCS strings using adaptive palette quantization (up to 256 registers)
- `TSixelView` (`src/SixelView.pas`): renders pre-encoded SIXEL data from memory or `.sixel/.six/.sxl` files
- `TSixelCanvasView` (`src/SixelView.pas`): direct pixel drawing API for generated/animated graphics (`SetPixel`, `FillRect`, `DrawLine`, `Clear`)
- `TImageWindow`/`TImageView` (`src/ImageView.pas`): loads both BMP and SIXEL files, supports scrolling and safe viewport cropping before SIXEL encoding

### True color vs SIXEL palette

Windows Terminal supports true-color text attributes, but SIXEL itself remains palette-based.  
Practical limit is still 256 color registers per emitted SIXEL image, so quality depends on quantization and dithering choices.

### Dithering control

`TSixelEncoder` supports error-diffusion dithering to reduce visible color banding:

- Auto-enabled for coarser quantization steps
- Force on: `FV_SIXEL_DITHER=1` (also accepts `on`, `true`)
- Force off: `FV_SIXEL_DITHER=0` (also accepts `off`, `false`)

### Cell-size override

If terminal pixel cell detection is wrong, you can override with:

- `FV_CELL_W=<pixels>`
- `FV_CELL_H=<pixels>`

### FVTest demos

`Test -> New Components` contains:

- `Image Viewer` (BMP + SIXEL files)
- `SIXEL Spectrometer` (direct animated bar rendering on `TSixelCanvasView`)
- `SIXEL Animated Sine` (direct animated waveform drawing on `TSixelCanvasView`)

## Clipboard Integration

System clipboard support is provided by `src/FVClipboard.pas` and is shared across editor-style controls.

### API

| Function | Description |
|----------|-------------|
| `ClipboardSetText(const Text: string): Boolean` | Writes Unicode text to Windows clipboard |
| `ClipboardGetText: string` | Reads text from Windows clipboard |
| `ClipboardHasText: Boolean` | Returns whether text data is available |

### Common key usage in FVTest demos

- `Ctrl+Ins`: copy selection
- `Shift+Ins`: paste clipboard text

The Test menu includes clipboard-focused examples:

- `Test -> Editor -> Clipboard`
- `Test -> New Components -> Clipboard`

## Terminal Emulator

The terminal component (`TTerminalWindow`) provides a VT100-compatible terminal emulator using Windows ConPTY. It supports running command-line applications including other Free Vision apps.

### Keyboard Controls

The terminal uses **Ctrl+A** as the escape prefix (like GNU screen):

| Key Sequence | Action |
|--------------|--------|
| **Ctrl+A, then any key** | Exit capture mode, send key to outer app |
| **Ctrl+A, Ctrl+A** | Send literal Ctrl+A to child process |
| **Ctrl+A, M** | Toggle terminal mouse mode (passthrough/select) |
| **Ctrl+C / Ctrl+Ins** | Copy terminal selection to clipboard |
| **Ctrl+V / Shift+Ins** | Paste clipboard text to terminal process |
| **Right click** | Copy selection, or paste when no selection |
| **Shift+PageUp/Down** | Scroll through scrollback buffer |
| **Mouse wheel** | Scroll through scrollback buffer |

### Re-entering Capture Mode

After exiting capture mode with Ctrl+A:
- **Click** on the terminal to re-enter capture mode
- Press **Enter** or **Esc** to re-enter capture mode

The terminal window title shows the current mouse mode:
- `Mouse:Pass` forwards mouse to child apps that enable VT mouse reporting
- `Mouse:Select` keeps mouse local for text selection/scrolling
- `Mouse:Select` keeps keyboard capture, so typing continues while mouse stays local
- New terminal windows start in `Mouse:Select`; use `Ctrl+A, M` to switch to passthrough
- Entering alternate screen (`?1049`/`?1047`/`?47`) auto-switches to `Mouse:Pass`, then restores previous mode on exit

### Features

- VT100/ANSI escape sequence support
- Scrollback buffer with configurable size
- Text selection with mouse (double-click for word selection)
- Copy/paste support (Ctrl+C/Ctrl+Ins copy selection, Ctrl+V/Shift+Ins paste)
- Visual bell
- Window title from OSC sequences
- Session logging
- Text reflow on resize

## String Grid

The `TStringGrid` component (`Grid.pas`) provides a spreadsheet-like data grid for console applications.

### Features

- Sortable columns with visual indicators
- Cell editing (F2 or direct typing)
- Row and cell selection modes
- Clipboard support (copy/paste)
- Undo support
- Column resizing and auto-fit
- Fixed header rows
- JSON serialization for layout

### CSV Import/Export

The grid supports RFC 4180-compliant CSV files:

```pascal
// Load CSV file
Grid.LoadFromCSV('data.csv');

// Save to CSV
Grid.SaveToCSV('output.csv');

// With options
var Opts := TCSVOptions.Create;
Opts.Delimiter := cdSemicolon;        // or cdComma, cdTab, cdPipe, cdAuto
Opts.CustomDelimiter := '~';          // Override with any character
Opts.UseFixedHeaderRow := True;       // Headers as fixed row 0
Opts.Encoding := ceUTF8BOM;           // UTF-8 with BOM (Excel compatible)
Grid.LoadFromCSV('data.csv', Opts);
Opts.Free;
```

### TCSVOptions Properties

| Property | Default | Description |
|----------|---------|-------------|
| `Delimiter` | `cdComma` | Field delimiter (comma, semicolon, tab, pipe, auto-detect) |
| `CustomDelimiter` | `#0` | Override delimiter with any character |
| `Encoding` | `ceUTF8BOM` | File encoding (UTF-8 BOM, UTF-8, ANSI) |
| `HasHeaders` | `True` | First row contains column headers |
| `UseFixedHeaderRow` | `False` | Put headers in fixed row 0 |
| `TrimWhitespace` | `False` | Trim spaces from values |
| `AutoCreateColumns` | `True` | Create columns from CSV structure |

## Hex Editor

The `THexEditor` component (`HexEdit.pas`) provides a binary file viewer and editor.

### Features

- Classic hex editor layout (address | hex bytes | ASCII)
- Dual editing modes: hex nibbles or ASCII characters
- Selection support with keyboard (Shift+arrows) and mouse
- Modified byte highlighting
- File load/save operations
- Pluggable data source interface (`IHexDataSource`)

### Keyboard Controls

| Key | Action |
|-----|--------|
| **Arrow keys** | Navigate bytes |
| **Tab** | Toggle between hex and ASCII mode |
| **Shift+Arrows** | Extend selection |
| **0-9, A-F** | Edit hex nibble (in hex mode) |
| **Any printable** | Edit ASCII character (in ASCII mode) |
| **Home/End** | Jump to start/end of row |
| **Ctrl+Home/End** | Jump to start/end of file |
| **Page Up/Down** | Scroll by page |

### Usage

```pascal
var
  HexEdit: THexEditor;
  Source: TMemoryHexSource;
begin
  Source := TMemoryHexSource.Create;
  Source.LoadFromFile('data.bin');

  HexEdit := THexEditor.Create(Bounds, Source);
  // ... add to window

  // Save changes
  Source.SaveToFile('data.bin');
end;
```

## Unicode and Emoji Support

The framework uses a `TDrawCell`-based drawing system where each screen cell stores a full `string` instead of a single `Char`. This allows proper rendering of:

- **Emoji**: Characters like `CheckMark`, `CrossMark`, `Diamond` rendered as true Unicode glyphs
- **CJK characters**: Double-width East Asian characters occupy two screen cells
- **Surrogate pairs**: Code points above U+FFFF (e.g. emoji) handled via Delphi's UTF-16 surrogate pair encoding
- **Box-drawing characters**: Full set of Unicode box-drawing and block elements (`FVBoxChars.pas`)

The rendering pipeline (`TDrawBuffer` -> `WriteBuf` -> `UnicodeCharBuf` -> VT escape sequences) preserves full Unicode fidelity from view drawing through to terminal output.

## Requirements

- Delphi 12.x or later
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
  FVCommon.pas      - Platform types (Sw_Word, PString, etc.)
  FVInterfaces.pas  - Interface definitions (IFVDrawable, ISerializable, etc.)
  FVSerialization.pas - JSON serialization helpers
  FVClipboard.pas   - Windows clipboard integration helpers
  Objects.pas       - Stream classes, string utilities
  Video.pas         - Console output (Windows Console API)
  Drivers.pas       - Keyboard and mouse input handling
  Views.pas         - View hierarchy (TView, TGroup, TWindow, etc.)
  Menus.pas         - Menu system (TMenuBar, TMenuBox, TStatusLine)
  App.pas           - Application framework (TApplication)
  Dialogs.pas       - Dialog controls (TDialog, TButton, TInputLine, etc.)
  Grid.pas          - TStringGrid with CSV import/export
  HexEdit.pas       - THexEditor binary viewer/editor
  SixelEncoder.pas  - Adaptive SIXEL encoder (palette + dithering)
  SixelView.pas     - TSixelView + TSixelCanvasView for SIXEL rendering
  ImageView.pas     - BMP/SIXEL viewer window and scrollable image view
  Validate.pas      - Input validation
  MsgBox.pas        - Message box helpers
  StdDlg.pas        - Standard file dialogs
  Editors.pas       - Text editor components
  ColorSel.pas      - Color selection dialog
  Outline.pas       - Tree/outline view
  Tabs.pas          - Tab control
  Statuses.pas      - Progress gauges
  Gadgets.pas       - Clock and heap views
  ProgressBar.pas   - Progress bar indicator
  Breadcrumb.pas    - Clickable path navigation
  ToolBar.pas       - Horizontal button bar
  ComboBox.pas      - Dropdown select control
  Splitter.pas      - Draggable panel divider + split group container
  Accordion.pas     - Collapsible section stack
  EditorGutter.pas  - Multi-column editor gutter (line numbers, bookmarks, breakpoints, diff)
  Notification.pas  - Auto-dismissing toast popups
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed class hierarchies and diagrams.

## Porting Notes

- Uses modern Delphi `CLASS` syntax with proper inheritance and `override`
- All view classes derive directly from `TObject` (no intermediate base class)
- Views implement interfaces: `IFVDrawable`, `IFVEventHandler`, `IFVDataAware`, `ISerializable`
- Uses RTL generics: `TObjectList<T>`, `TStringList` (no custom collection classes)
- `TClass.Create` / `Object.Free` instead of `New(P, Init)` / `Dispose(P, Done)`
- Pointer types aliased for compatibility: `PView = TView`
- `ShortString` used for FV string types (`Sw_String`, `PString`)
- Windows Console API for video output and input
- Range checking should be OFF at project level

## Known Limitations

- New **edge-cases**, **oversights** or **errors** may be introduced in this project

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

## Acknowledgments

Several units in `src/` are adapted from third-party MIT-licensed projects.
Upstream license texts live in `third_party/`.

| Unit | Upstream | License |
|---|---|---|
| `src/FVUnicodeWidth.pas` | [VSoft.AnsiConsole](https://github.com/VSoftTechnologies/VSoft.AnsiConsole) (Vincent Parrett); tables originate from [spectreconsole/wcwidth](https://github.com/spectreconsole/wcwidth), Unicode 15.1 data from the Unicode Consortium | MIT |
| `src/FVProfile.pas` | [VSoft.AnsiConsole](https://github.com/VSoftTechnologies/VSoft.AnsiConsole) — capability detection rules mirror [Spectre.Console](https://github.com/spectreconsole/spectre.console) (Patrik Svensson, Phil Scott, Nils Andresen) | MIT |
| `src/SpinnerView.pas` | [VSoft.AnsiConsole](https://github.com/VSoftTechnologies/VSoft.AnsiConsole) frame data; spinner frames originate from [`cli-spinners`](https://github.com/sindresorhus/cli-spinners) by Sindre Sorhus | MIT |
| `src/TaskProgress.pas` | Inspired by [VSoft.AnsiConsole](https://github.com/VSoftTechnologies/VSoft.AnsiConsole) `Live.Progress` / [Spectre.Console](https://github.com/spectreconsole/spectre.console) | MIT |
| `src/CheckListBox.pas` | Inspired by [VSoft.AnsiConsole](https://github.com/VSoftTechnologies/VSoft.AnsiConsole) `Prompts.MultiSelect` | MIT |

## Contributing

Bug reports and contributions are welcome. Please ensure any modifications maintain compatibility with the original Free Vision API where possible.
