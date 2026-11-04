(*
Avoraiser UI Framework - High-Performance WinAPI UI for Avocado
Avoraiser is a framework for creating modern user interfaces for the Polish programming language Avocado.
Copyright (c) 2025-2026 Dymitr Wygowski (Programista Art)
Project Created: 23.12.2025

Author:     Dymitr Wygowski (Programista Art)
Contact:    programista.art@gmail.com
GitHub:     https://github.com/Programista-Art/Avoraiser
Version:    1.0
License:    Dual-Licensed: Avoraiser Community / Commercial
            See LICENSE.md for terms and conditions.

Module:     avoraiser.events
Description:
*)

unit avoraiser.events;

{$mode ObjFPC}{$H+}

interface

uses
  Windows, avoraiser.core;


type
    // Mysz i Klawiatura
    TMouseCallbacks = record
      OnMove: TAvocadoMouseEvent;
      OnLDown, OnLUp, OnLDblClick: TAvocadoMouseEvent;
      OnRDown, OnRUp, OnRDblClick: TAvocadoMouseEvent;
      OnMDown, OnMUp, OnMDblClick: TAvocadoMouseEvent;
      OnWheel, OnHWheel: TAvocadoWheelEvent;
      OnHitTest: TAvocadoHitTestEvent;
      // Pola Non-Client
      OnNCMove, OnNCLDown, OnNCLUp, OnNCLDblClick, OnNCRDown, OnNCRUp: TAvocadoNCMouseEvent;
    end;


    TMouseEntry = record
      Handle: HWND;
      Callbacks: TMouseCallbacks;
    end;


    TKeyboardCallbacks = record
      OnKeyDown, OnKeyUp: TAvocadoKeyEvent;
      OnSysKeyDown, OnSysKeyUp: TAvocadoKeyEvent;
      OnChar, OnSysChar: TAvocadoCharEvent;
      OnDeadChar, OnUniChar: TAvocadoCharEvent;
    end;

    TKeyboardEntry = record
      Handle: HWND;
      Callbacks: TKeyboardCallbacks;
    end;

    TFocusCallbacks = record
      OnSetFocus, OnKillFocus: TAvocadoFocusEvent;
      OnActivateApp: TAvocadoActivateAppEvent;
      OnEnable: TAvocadoEnableEvent;
    end;

    TFocusEntry = record
      Handle: HWND;
      Callbacks: TFocusCallbacks;
    end;

    // Menu i inne
    TMenuCallbacks = record
      OnInitPopup: TAvocadoInitMenuEvent;
      OnSelect: TAvocadoMenuSelectEvent;
    end;

    TMenuEntry = record
      Handle: HWND;
      Callbacks: TMenuCallbacks;
    end;

    //TEventEntry = record Handle: HWND; Callback: TAvocadoEvent; end;
    //TResizeEntry = record Handle: HWND; Callback: TAvocadoEvent; end; // Stary typ resize
   // TKeyEntry = record Handle: HWND; Callback: TAvocadoKeyEvent; end;
   // TMoveEntry = record Handle: HWND; Callback: TAvocadoEvent; end;
   // TMinMaxEntry = record Handle: HWND; OnMinMax: TAvocadoMinMaxEvent; end;
    //TContextEntry = record Handle: HWND; OnContext: TAvocadoContextEvent; end;
    //TCloseEntry = record Handle: HWND; Callback: TAvocadoCloseEvent; end;
   // TSizingEntry = record Handle: HWND; Callback: TAvocadoSizingEvent; end;
   // TMovingEntry = record Handle: HWND; Callback: TAvocadoMovingEvent; end;
    //TPosChangingEntry = record Handle: HWND; Callback: TAvocadoWindowPosEvent; end;


    //TDropEntry = record Handle: HWND; OnDrop: TAvocadoDropFilesEvent; end;
    TScrollEntry = record Handle: HWND; OnScroll: TAvocadoScrollEvent; end;
    //
    //TClipEntry = record Handle: HWND; OnRender: TAvocadoRenderFormatEvent; OnRenderAll: TAvocadoRenderAllEvent; end;
    //TTimerEntry = record Handle: HWND; OnTimer: TAvocadoTimerEvent; end;
    //TPowerEntry = record Handle: HWND; OnPower: TAvocadoPowerEvent; end;




    TSessionEntry = record
      Handle: HWND;
      OnQuery: TAvocadoQueryEndSessionEvent;
      OnEnd: TAvocadoEndSessionEvent;
    end;


var
     MenuRegistry: array of TMenuEntry;


implementation


end.

