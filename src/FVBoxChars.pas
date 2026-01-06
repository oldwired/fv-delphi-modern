{*********************************************************}
{                                                         }
{       Free Vision - Unicode Box Drawing Characters      }
{                                                         }
{       Unicode box drawing and UI element constants      }
{       for VT sequence-based rendering                   }
{                                                         }
{*********************************************************}

unit FVBoxChars;

interface

const
  { Single line box drawing (U+2500 block) }
  BoxHoriz       = #$2500;  // ─ Horizontal line
  BoxVert        = #$2502;  // │ Vertical line
  BoxTopLeft     = #$250C;  // ┌ Top left corner
  BoxTopRight    = #$2510;  // ┐ Top right corner
  BoxBottomLeft  = #$2514;  // └ Bottom left corner
  BoxBottomRight = #$2518;  // ┘ Bottom right corner
  BoxVertRight   = #$251C;  // ├ Vertical and right
  BoxVertLeft    = #$2524;  // ┤ Vertical and left
  BoxHorizDown   = #$252C;  // ┬ Horizontal and down
  BoxHorizUp     = #$2534;  // ┴ Horizontal and up
  BoxCross       = #$253C;  // ┼ Cross

  { Double line box drawing }
  BoxDblHoriz       = #$2550;  // ═ Double horizontal
  BoxDblVert        = #$2551;  // ║ Double vertical
  BoxDblTopLeft     = #$2554;  // ╔ Double top left
  BoxDblTopRight    = #$2557;  // ╗ Double top right
  BoxDblBottomLeft  = #$255A;  // ╚ Double bottom left
  BoxDblBottomRight = #$255D;  // ╝ Double bottom right
  BoxDblVertRight   = #$2560;  // ╠ Double vertical and right
  BoxDblVertLeft    = #$2563;  // ╣ Double vertical and left
  BoxDblHorizDown   = #$2566;  // ╦ Double horizontal and down
  BoxDblHorizUp     = #$2569;  // ╩ Double horizontal and up
  BoxDblCross       = #$256C;  // ╬ Double cross

  { Mixed single/double corners (for window frames) }
  BoxSngDblTopLeft     = #$2552;  // ╒ Single horiz, double vert top left
  BoxSngDblTopRight    = #$2555;  // ╕ Single horiz, double vert top right
  BoxSngDblBottomLeft  = #$2558;  // ╘ Single horiz, double vert bottom left
  BoxSngDblBottomRight = #$255B;  // ╛ Single horiz, double vert bottom right
  BoxDblSngTopLeft     = #$2553;  // ╓ Double horiz, single vert top left
  BoxDblSngTopRight    = #$2556;  // ╖ Double horiz, single vert top right
  BoxDblSngBottomLeft  = #$2559;  // ╙ Double horiz, single vert bottom left
  BoxDblSngBottomRight = #$255C;  // ╜ Double horiz, single vert bottom right

  { Arrow symbols }
  ArrowUp        = #$25B2;  // ▲ Up arrow (solid)
  ArrowDown      = #$25BC;  // ▼ Down arrow (solid)
  ArrowLeft      = #$25C0;  // ◀ Left arrow (solid)
  ArrowRight     = #$25B6;  // ▶ Right arrow (solid)
  ArrowUpOpen    = #$25B3;  // △ Up arrow (outline)
  ArrowDownOpen  = #$25BD;  // ▽ Down arrow (outline)
  ArrowLeftOpen  = #$25C1;  // ◁ Left arrow (outline)
  ArrowRightOpen = #$25B7;  // ▷ Right arrow (outline)

  { Small arrows (for scroll bars) }
  SmallArrowUp    = #$25B4;  // ▴ Small up arrow
  SmallArrowDown  = #$25BE;  // ▾ Small down arrow
  SmallArrowLeft  = #$25C2;  // ◂ Small left arrow
  SmallArrowRight = #$25B8;  // ▸ Small right arrow

  { Block elements }
  BlockFull      = #$2588;  // █ Full block
  BlockUpper     = #$2580;  // ▀ Upper half block
  BlockLower     = #$2584;  // ▄ Lower half block
  BlockLeft      = #$258C;  // ▌ Left half block
  BlockRight     = #$2590;  // ▐ Right half block
  BlockLight     = #$2591;  // ░ Light shade
  BlockMed       = #$2592;  // ▒ Medium shade
  BlockDark      = #$2593;  // ▓ Dark shade

  { Special UI characters }
  CheckMark      = #$2713;  // ✓ Check mark
  CheckMarkHeavy = #$2714;  // ✔ Heavy check mark
  CrossMark      = #$2717;  // ✗ Cross mark
  CrossMarkHeavy = #$2718;  // ✘ Heavy cross mark
  BulletPt       = #$2022;  // • Bullet point
  BulletWhite    = #$25E6;  // ◦ White bullet
  Diamond        = #$25C6;  // ◆ Diamond (solid)
  DiamondOpen    = #$25C7;  // ◇ Diamond (outline)
  Circle         = #$25CF;  // ● Circle (solid)
  CircleOpen     = #$25CB;  // ○ Circle (outline)
  Square         = #$25A0;  // ■ Square (solid)
  SquareOpen     = #$25A1;  // □ Square (outline)

  { Window control symbols }
  CloseButton    = #$2715;  // ✕ Close (multiplication X)
  MaximizeButton = #$25A1;  // □ Maximize (square outline)
  MinimizeButton = #$2500;  // ─ Minimize (horizontal line)
  RestoreButton  = #$29C9;  // ⧉ Restore (two overlapping squares - may need fallback)

  { Radio button and checkbox }
  RadioOff       = #$25CB;  // ○ Radio button off
  RadioOn        = #$25C9;  // ◉ Radio button on (fisheye)
  CheckboxOff    = #$2610;  // ☐ Checkbox off
  CheckboxOn     = #$2611;  // ☑ Checkbox on
  CheckboxX      = #$2612;  // ☒ Checkbox with X

  { Scroll bar thumb }
  ScrollThumb    = #$2588;  // █ Full block for scroll thumb
  ScrollTrack    = #$2591;  // ░ Light shade for scroll track

  { Shadow character }
  ShadowChar     = #$2591;  // ░ Light shade for shadow effect

  { Ellipsis }
  Ellipsis       = #$2026;  // … Horizontal ellipsis

  { Mathematical symbols that might be useful }
  PlusMinus      = #$00B1;  // ± Plus-minus
  Multiply       = #$00D7;  // × Multiplication
  Divide         = #$00F7;  // ÷ Division
  LessEqual      = #$2264;  // ≤ Less than or equal
  GreaterEqual   = #$2265;  // ≥ Greater than or equal
  NotEqual       = #$2260;  // ≠ Not equal
  Approx         = #$2248;  // ≈ Approximately equal

implementation

end.
