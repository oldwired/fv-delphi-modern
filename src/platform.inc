{***************[ PLATFORM INCLUDE UNIT ]******************}
{                                                          }
{    System independent INCLUDE file to sort PLATFORMS     }
{                                                          }
{    Parts Copyright (c) 1997 by Balazs Scheidler          }
{    Parts Copyright (c) 1999, 2000 by Leon de Boer        }
{    Delphi 10+ port 2024                                  }
{                                                          }
{****************[ THIS CODE IS FREEWARE ]*****************}
{                                                          }
{     This sourcecode is released for the purpose to       }
{   promote the pascal language on all platforms. You may  }
{   redistribute it and/or modify with the following       }
{   DISCLAIMER.                                            }
{                                                          }
{     This SOURCE CODE is distributed "AS IS" WITHOUT      }
{   WARRANTIES AS TO PERFORMANCE OF MERCHANTABILITY OR     }
{   ANY OTHER WARRANTIES WHETHER EXPRESSED OR IMPLIED.     }
{                                                          }
{*****************[ SUPPORTED PLATFORMS ]******************}
{     Delphi 10.x (Seattle, Berlin, Tokyo, Rio, etc.)      }
{     Delphi 11.x (Alexandria)                             }
{     Delphi 12.x (Athens)                                 }
{     Windows 32-bit and 64-bit                            }
{     Also maintains FPC compatibility                     }
{**********************************************************}

{---------------------------------------------------------------------------}
{  FPC COMPILER DETECTION - must come first                                 }
{---------------------------------------------------------------------------}
{$IFDEF FPC}
  {$mode objfpc}
  {$MACRO ON}

  {$DEFINE PPC_FPC}

  {$IFDEF FV_UNICODE}
    {$DEFINE Sw_PString_DeRef:=}
    {$DEFINE Sw_NewStr:=}
  {$ELSE FV_UNICODE}
    {$DEFINE Sw_PString_DeRef:=^}
    {$DEFINE Sw_NewStr:=NewStr}
  {$ENDIF FV_UNICODE}

  {$DEFINE ASM_FPC}
  {$UNDEF BP_VMTLink}
  {$DEFINE Use_API}

  {$IFNDEF CPU16}
    {$IFDEF CPU64}
      {$DEFINE BIT_64}
    {$ELSE}
      {$DEFINE BIT_32}
    {$ENDIF}
  {$ELSE}
    {$DEFINE BIT_16}
  {$ENDIF}

  {$DEFINE PROC_Protected}

  {$IFDEF CPULLVM}
    {$DEFINE TYPED_LOCAL_CALLBACKS}
  {$ENDIF}

  {$IFDEF TYPED_LOCAL_CALLBACKS}
    {$MODESWITCH NESTEDPROCVARS}
  {$ENDIF}

  { FPC OS detection }
  {$IFDEF LINUX}
    {$DEFINE OS_LINUX}
    {$DEFINE OS_UNIX}
  {$ENDIF}

  {$IFDEF FreeBSD}
    {$DEFINE OS_FREEBSD}
    {$DEFINE OS_UNIX}
  {$ENDIF}

  {$IFDEF Darwin}
    {$DEFINE OS_DARWIN}
    {$DEFINE OS_UNIX}
  {$ENDIF}

  {$IFDEF WINDOWS}
    {$DEFINE OS_WINDOWS}
  {$ENDIF}

  {$IFDEF WIN32}
    {$DEFINE OS_WINDOWS}
  {$ENDIF}

  {$IFDEF WIN64}
    {$DEFINE OS_WINDOWS}
  {$ENDIF}
{$ENDIF FPC}

{---------------------------------------------------------------------------}
{  DELPHI COMPILER DETECTION                                                }
{---------------------------------------------------------------------------}
{$IFNDEF FPC}

  { Modern Delphi detection using CompilerVersion }
  {$IFDEF CONDITIONALEXPRESSIONS}
    {$IF CompilerVersion >= 24.0}  { Delphi XE3+ }
      {$DEFINE PPC_DELPHI}
      {$DEFINE PPC_DELPHI_MODERN}
      {$UNDEF BP_VMTLink}
      {$DEFINE Use_API}
    {$IFEND}
  {$ENDIF}

  { Fallback for specific versions }
  {$IFDEF VER350}  { Delphi 12 Athens }
    {$IFNDEF PPC_DELPHI}
      {$DEFINE PPC_DELPHI}
      {$DEFINE PPC_DELPHI_MODERN}
    {$ENDIF}
  {$ENDIF}

  {$IFDEF VER340}  { Delphi 11 Alexandria }
    {$IFNDEF PPC_DELPHI}
      {$DEFINE PPC_DELPHI}
      {$DEFINE PPC_DELPHI_MODERN}
    {$ENDIF}
  {$ENDIF}

  {$IFDEF VER330}  { Delphi 10.3 Rio }
    {$IFNDEF PPC_DELPHI}
      {$DEFINE PPC_DELPHI}
      {$DEFINE PPC_DELPHI_MODERN}
    {$ENDIF}
  {$ENDIF}

  {$IFDEF VER320}  { Delphi 10.2 Tokyo }
    {$IFNDEF PPC_DELPHI}
      {$DEFINE PPC_DELPHI}
      {$DEFINE PPC_DELPHI_MODERN}
    {$ENDIF}
  {$ENDIF}

  {$IFDEF VER310}  { Delphi 10.1 Berlin }
    {$IFNDEF PPC_DELPHI}
      {$DEFINE PPC_DELPHI}
      {$DEFINE PPC_DELPHI_MODERN}
    {$ENDIF}
  {$ENDIF}

  {$IFDEF VER300}  { Delphi 10 Seattle }
    {$IFNDEF PPC_DELPHI}
      {$DEFINE PPC_DELPHI}
      {$DEFINE PPC_DELPHI_MODERN}
    {$ENDIF}
  {$ENDIF}

{$ENDIF !FPC}

{---------------------------------------------------------------------------}
{  DELPHI-SPECIFIC CONFIGURATION                                            }
{---------------------------------------------------------------------------}
{$IFDEF PPC_DELPHI}
  {$DEFINE ASM_BP}
  {$UNDEF BP_VMTLink}
  {$DEFINE PROC_Protected}

  { Delphi doesn't support "is nested" syntax for callbacks }
  {$UNDEF TYPED_LOCAL_CALLBACKS}

  { Delphi uses Video unit replacement }
  {$DEFINE FV_DELPHI_VIDEO}

  { Disable warnings for legacy code patterns }
  {$WARN UNSAFE_TYPE OFF}
  {$WARN UNSAFE_CODE OFF}
  {$WARN UNSAFE_CAST OFF}
  {$WARN SYMBOL_DEPRECATED OFF}

  { Modern Delphi uses Unicode by default }
  {$IFDEF PPC_DELPHI_MODERN}
    {$DEFINE DELPHI_UNICODE}
  {$ENDIF}
{$ENDIF}

{---------------------------------------------------------------------------}
{  OPERATING SYSTEM DETECTION (Delphi)                                      }
{---------------------------------------------------------------------------}
{$IFDEF PPC_DELPHI}
  {$IFDEF MSWINDOWS}
    {$DEFINE OS_WINDOWS}
  {$ENDIF}

  {$IFDEF WIN32}
    {$DEFINE OS_WINDOWS}
    {$DEFINE BIT_32}
  {$ENDIF}

  {$IFDEF WIN64}
    {$DEFINE OS_WINDOWS}
    {$DEFINE BIT_64}
  {$ENDIF}

  {$IFDEF LINUX}
    {$DEFINE OS_LINUX}
    {$DEFINE OS_UNIX}
  {$ENDIF}

  {$IFDEF MACOS}
    {$DEFINE OS_DARWIN}
    {$DEFINE OS_UNIX}
  {$ENDIF}
{$ENDIF}

{---------------------------------------------------------------------------}
{  BIT SIZE AUTO-DETECTION                                                  }
{---------------------------------------------------------------------------}
{$IFNDEF BIT_16}
  {$IFNDEF BIT_32}
    {$IFNDEF BIT_64}
      { Auto-detect based on pointer size }
      {$IF SizeOf(Pointer) = 8}
        {$DEFINE BIT_64}
      {$ELSE}
        {$DEFINE BIT_32}
      {$IFEND}
    {$ENDIF}
  {$ENDIF}
{$ENDIF}

{$IFDEF BIT_64}
  {$DEFINE BIT_32_OR_MORE}
{$ENDIF}

{$IFDEF BIT_32}
  {$DEFINE BIT_32_OR_MORE}
{$ENDIF}

{---------------------------------------------------------------------------}
{  CPU DETECTION                                                            }
{---------------------------------------------------------------------------}
{$IFDEF CPUX86}
  {$DEFINE CPU86}
{$ENDIF}

{$IFDEF CPUX64}
  {$DEFINE CPU86}
  {$DEFINE CPUX86_64}
{$ENDIF}

{$IFDEF CPU386}
  {$DEFINE CPU86}
{$ENDIF}

{ Fallback for Delphi which may not define CPU symbols }
{$IFDEF PPC_DELPHI}
  {$IFNDEF CPU86}
    {$DEFINE CPU86}
  {$ENDIF}
{$ENDIF}
