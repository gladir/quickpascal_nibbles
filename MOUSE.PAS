{$R-,S-}
UNIT mouse;

{=============================================================

    MOUSE.PAS   Low-level mouse unit for QuickPascal

    Real mode Mouse control routines.  Derived from
    Microsoft OS/2 Programmer's Reference, chapter 3.

==============================================================}

INTERFACE

CONST
    { button masks }
    left_b    = $0001;
    right_b   = $0002;
    center_b  = $0004;

    { call masks }
    pos_changed    = $0001;
    left_press     = $0002;
    left_release   = $0004;
    right_press    = $0008;
    right_release  = $0010;
    center_press   = $0020;
    center_release = $0040;

    { text pointer selectors }
    software_pointer = 0;
    hardware_pointer = 1;

VAR
    { indicates the presence of a mouse
      initialized in unit startup
    }
    mouse_present : Boolean;

{ See the IMPLEMENTATION section for full descriptions of each
  procedure and function.
}
FUNCTION  ms_init( VAR nButtons : Integer ) : Boolean;
PROCEDURE ms_show;
PROCEDURE ms_hide;
PROCEDURE ms_read( VAR x, y, b_mask : Word );
PROCEDURE ms_read_motion ( VAR hCount, vCount : Word );
PROCEDURE ms_set_pos( x, y : Word );

PROCEDURE ms_lightpen_on;
PROCEDURE ms_lightpen_off;

FUNCTION  ms_get_b(     b_mask         : Word;
                    VAR count          : Word;
                    VAR last_x, last_y : Word ) : Word;
FUNCTION  ms_get_b_release(     b_mask         : Word;
                            VAR count          : Word;
                            VAR last_x, last_y : Word ):Word;

PROCEDURE ms_set_hminmax( min, max : Word );
PROCEDURE ms_set_vminmax( min, max : Word );
PROCEDURE ms_set_graphPointer( hotx, hoty : Word;
                               image      : POINTER );
PROCEDURE ms_set_textPointer( select       : Word;
                              screen_char  : Char;
                              screen_attr  : Byte;
                              pointer_char : Char;
                              pointer_attr : Byte );

PROCEDURE ms_set_MPP( hMPP, vMPP : Word );
PROCEDURE ms_cond_off( top, left, bottom, right : Word );
PROCEDURE ms_set_2speed( MPS : Word );

PROCEDURE ms_set_routine( call_mask : Word; sub : POINTER );
PROCEDURE ms_swap_routine(     call_mask      : Word;
                               sub            : POINTER;
                           VAR last_call_mask : Word;
                           VAR last_sub       : POINTER );

FUNCTION  ms_get_state_bfsz : Word;
PROCEDURE ms_get_state( ms_state : POINTER );
PROCEDURE ms_set_state( ms_state : POINTER );


{=============================================================}
                     IMPLEMENTATION
{=============================================================}

USES  Dos;

CONST
    ms_call = $33;  { mouse interrupt number }
    iret    = $cf;  { iret (return from interrupt) instruction }
VAR
    r  : Registers; { scratch Registers variable }
    mi : Pointer;   { mouse interrupt vector for initial test }

{ The following functions are used to unpack pointers
  into segment and offset
}
FUNCTION PSeg( x : POINTER ) : Word; INLINE( $5a/$58 );
FUNCTION POfs( x : POINTER ) : Word; INLINE( $58/$5a );

{==============================================================
    ms_init                          real-mode mouse function 0
 ==============================================================
    Return True and initialize the mouse if a mouse device is
    present, False if no mouse present.

    nButtons contains the number of buttons on the mouse.

    The mouse is initialized to the following default values:
        position                  : screen center
        pointer-draw flag         : -1 (pointer hidden)
        graphics pointer          : default image
        text pointer              : reverse video
        interrupt mask            : 0, no user routine in use
        light pen emulation       : on
        Mickeys/pixel(horizontal) :  8:8
        Mickeys/pixel(vertical)   : 16:8
        min/max position          : depends on display mode
}
FUNCTION ms_init( VAR nButtons : Integer ) : Boolean;
    BEGIN
    IF mouse_present THEN
        BEGIN
        r.AX := 0;
        Intr( ms_call, r );
        IF r.AX = 0 THEN    { no mouse }
            BEGIN
            nButtons := 0;
            ms_init  := False;
            END
        ELSE
            BEGIN
            nButtons := r.BX;
            ms_init  := True;
            END;
        END
    ELSE
        BEGIN
        nButtons := 0;
        ms_init := False;
        END;
    END;


{==============================================================
    ms_show                          real-mode mouse function 1
 ==============================================================
    If already visible, then do nothing.
    If pointer-draw flag is nonzero, increment flag,
    if pointer-draw flag is incremented to zero, display the
    pointer image.
}
PROCEDURE ms_show;
    BEGIN
    r.AX := 1;
    Intr( ms_call, r );
    END;

{==============================================================
    ms_hide                          real-mode mouse function 2
 ==============================================================
    Decrement pointer-draw flag.
    If pointer already hidden, then return.
    If pointer-draw flag is decremented to -1, then pointer is
    hidden.
    Always decrements pointer-draw flag.
}
PROCEDURE ms_hide;
    BEGIN
    r.AX:=2;
    Intr( ms_call, r );
    END;


{==============================================================
    ms_read                          real-mode mouse function 3
 ==============================================================
    Read mouse button state(s) and screen coordinates of the
    pointer screen coordinates are relative to the range for
    virtual screen (mode-dependent).
    Button is pressed if bit is set:
        2-button mouse:
            bit 0 = left button
            bit 1 = right button
        3-button mouse:
            bit 0 = left button
            bit 1 = right button
            bit 2 = Center button
}
PROCEDURE ms_read( VAR x, y, b_mask : Word );
    BEGIN
    r.AX := 3;
    Intr( ms_call, r );
    x := r.CX;
    y := r.DX;
    b_mask := r.BX;
    END;


{==============================================================
    ms_set_pos                       real-mode mouse function 4
 ==============================================================
    set mouse position
    x and y are clipped to min/max values
}
PROCEDURE ms_set_pos( x, y : Word );
    BEGIN
    r.AX := 4;
    r.CX := x;
    r.DX := y;
    Intr( ms_call, r );
    END;


{==============================================================
    ms_get_b                      real-mode mouse function 5
 ==============================================================
    Return mouse button-press status.
    count contains the number of times button was pressed since
    since the last call to this function. The count is reset to
    zero.
    Does not detect button-press counter overflow.
    last_x, last_y are the screen coordinates of the pointer at
    the last button press.
}
FUNCTION ms_get_b(     b_mask : Word;
                   VAR count, last_x, last_y : Word ) : Word;
    BEGIN
    r.AX := 5;
    r.BX := b_mask;
    Intr( ms_call, r );

    count    := r.BX;
    last_x   := r.CX;
    last_y   := r.DX;
    ms_get_b := r.AX;
    END;


{==============================================================
    ms_get_b_release              real-mode mouse function 6
 ==============================================================
    returns mouse button release status
    count contains the number of times button was released
    since the last call to this function.  The count is reset
    to zero.
    Does not detect button-release counter overflow.
    last_x, last_y are the screen coordinates of the pointer at
    the last button release.
}
FUNCTION ms_get_b_release(     b_mask         : Word;
                           VAR count          : Word;
                           VAR last_x, last_y : Word ) : Word;
    BEGIN
    r.AX := 6;
    r.BX := b_mask;
    Intr( ms_call, r );

    count  := r.BX;
    last_x := r.CX;
    last_y := r.DX;
    ms_get_b_release := r.AX;
    END;


{==============================================================
    ms_set_hminmax                   real-mode mouse function 7
 ==============================================================
    set horizontal mouse movement constraint range
    if min>max then they are swapped
    min/max are clipped to virtual screen size
    if mouse pointer is outside the range, it is moved to just
    inside the range
}
PROCEDURE ms_set_hminmax( min, max : Word );
    BEGIN
    r.AX := 7;
    r.CX := min;
    r.DX := max;
    Intr( ms_call, r );
    END;


{==============================================================
    ms_set_vminmax                   real-mode mouse function 8
 ==============================================================
    set vertical mouse movement constraint range
    if min>max then they are swapped
    min/max are clipped to virtual screen size
    if mouse pointer is outside the range, it is moved to just
    inside the range
}
PROCEDURE ms_set_vminmax( min, max : Word );
    BEGIN
    r.AX := 8;
    r.CX := min;
    r.DX := max;
    Intr( ms_call, r );
    END;


{==============================================================
    ms_set_graphPointer              real-mode mouse function 9
 ==============================================================
    hotx, hoty (+/-16) are the hot spot coordinates relative to
    the upper-left of the pointer image.
    image = pointer to the mouse pointer image bitmap
        The first 32 bytes define the screen mask
        The last 32 bytes define the pointer mask
    The pointer is drawn by:
        AND screen mask with pixels under the pointer,
        XOR pointer mask with result
    In mode 6, each bit defines the color of a pixel.
    In modes 4 and 5, each pair of bits defines the color of a
    pixel.
}
PROCEDURE ms_set_graphPointer( hotx, hoty : Word;
                               image      : POINTER );
    BEGIN
    r.AX := 9;
    r.BX := hotx;
    r.CX := hoty;
    r.DX := POfs(image);
    r.ES := PSeg(image);
    Intr( ms_call, r );
    END;


{==============================================================
    ms_set_textPointer              real-mode mouse function 10
 ==============================================================
    select determines which pointer: software or hardware
}
PROCEDURE ms_set_textPointer( select       : Word;
                              screen_char  : Char;
                              screen_attr  : Byte;
                              pointer_char : Char;
                              pointer_attr : Byte );
    BEGIN
    r.AX := 10;
    r.BX := select;
    r.CL := Byte(screen_char);
    r.CH := screen_attr;
    r.DL := Byte(pointer_char);
    r.DH := pointer_attr;
    Intr( ms_call, r );
    END;


{==============================================================
    ms_read_motion                  real-mode mouse function 11
 ==============================================================
    Return the number of Mickeys the mouse has moved since the
    last call to this function.
    A positive number is right/down.
    Reset counter to zero.
}
PROCEDURE ms_read_motion( VAR hCount, vCount : Word );
    BEGIN
    r.AX := 11;
    Intr( ms_call, r );
    hCount := r.CX;
    vCount := r.DX;
    END;


{==============================================================
    ms_set_routine                  real-mode mouse function 12
 ==============================================================
    Set the call mask and subroutine address for user-defined
    mouse hardware interrupt handler.
}
PROCEDURE ms_set_routine( call_mask : Word; sub : POINTER );
    BEGIN
    r.AX := 12;
    r.CX := call_mask;
    r.DX := POfs(sub);
    r.ES := PSeg(sub);
    Intr( ms_call, r );
    END;


{==============================================================
    ms_lightpen_on                  real-mode mouse function 13
 ==============================================================
    turn light pen emulation on
}
PROCEDURE ms_lightpen_on;
    BEGIN
    r.AX := 13;
    Intr( ms_call, r );
    END;


{==============================================================
    ms_lightpen_off                 real-mode mouse function 14
 ==============================================================
    turn light pen emulation off
}
PROCEDURE ms_lightpen_off;
    BEGIN
    r.AX := 14;
    Intr( ms_call, r );
    END;


{==============================================================
    ms_set_MPP                      real-mode mouse function 15
 ==============================================================
    set horizontal and vertical mouse motion rates
    MPP (1 <= MPP <= 32767) = Mickeys / 8 pixels
    default hMPP is 8:8
    default vMPP is 16:8
}
PROCEDURE ms_set_MPP( hMPP, vMPP : Word );
    BEGIN
    IF (hMPP >= 1) AND (hMPP <= 32767) AND
       (vMPP >= 1) AND (vMPP <= 32767) THEN
        BEGIN
        r.AX := 15;
        r.CX := hMPP;
        r.DX := vMPP;
        Intr( ms_call, r );
        END;
    END;


{================================================================
    ms_cond_off                       real-mode mouse function 16
 ================================================================
    If the pointer is in the defined region, function 16 hides
    the pointer while the region is being updated.
    After this call is issued, you must call function 1
    (ms_show) to show the pointer again.
    Coordinates specified in pixels.
}
PROCEDURE ms_cond_off( top, left, bottom, right : Word );
    BEGIN
    r.AX := 16;
    r.CX := left;
    r.DX := top;
    r.SI := right;
    r.DI := bottom;
    Intr( ms_call, r );
    END;


{================================================================
    ms_set_2speed                     real-mode mouse function 19
 ================================================================
    Set the threshold speed for doubling pointer motion to the
    screen, specified in Mickeys Per Second
    The default double speed threshold is 128 mickeys per second.
}
PROCEDURE ms_set_2speed( MPS : Word );
    BEGIN
    r.AX := 19;
    r.DX := MPS;
    Intr( ms_call, r );
    END;


{================================================================
    ms_swap_routine                   real-mode mouse function 20
 ================================================================
    Set call mask and user-defined interrupt routine,
    return previous call mask and interrupt vector.

    The Quick Pascal header for the mouse interrupt handler
    would be:

    PROCEDURE myMouseInt( Flags, CS, IP,  (* not used *)
                          condition_mask,
                          b_state,
                          hPos, vPos,
                          lastVM, lastHM : Word ); INTERRUPT;

    The interrupt routine will be called with the following
    values in the registers:
        AX : condition mask (bit set = condition occurred)
        BX : button state
        CX : horizontal pointer coordinate
        DX : vertical pointer coordinate
        SI : last raw vertical Mickey count
        DI : last raw horizontal Mickey count

    DS will contain the segment address of the mouse driver's
    data segment, so the interrupt routine must set DS to it's
    own data segment.

}
PROCEDURE ms_swap_routine(     call_mask      : Word;
                               sub            : POINTER;
                           VAR last_call_mask : Word;
                           VAR last_sub       : POINTER );
    BEGIN
    r.AX := 20;
    r.CX := call_mask;
    r.DX := POfs(sub);
    r.ES := PSeg(sub);
    Intr( ms_call, r );

    last_call_mask := r.CX;
    last_sub := Ptr( r.ES, r.DX );
    END;


{================================================================
    ms_get_state_bfsz              real-mode mouse function 21
 ================================================================
    Return buffer size in bytes required to save the mouse driver
    state.
}
FUNCTION ms_get_state_bfsz: Word;
    BEGIN
    r.AX := 21;
    Intr( ms_call, r );
    ms_get_state_bfsz := r.BX;
    END;


{================================================================
    ms_get_state                      real-mode mouse function 22
 ================================================================
    Get the mouse driver state.
}
PROCEDURE ms_get_state( ms_state : POINTER );
    BEGIN
    r.AX := 22;
    r.DX := POfs(ms_state);
    r.ES := PSeg(ms_state);
    Intr( ms_call, r );
    END;


{================================================================
    ms_set_state                      real-mode mouse function 23
 ================================================================
    Set mouse driver state, given a previously saved state.
}
PROCEDURE ms_set_state( ms_state : POINTER );
    BEGIN
    r.AX := 23;
    r.DX := POfs(ms_state);
    r.ES := PSeg(ms_state);
    Intr( ms_call, r );
    END;


{=============== initialization =================================}
BEGIN

GetIntVec( ms_call, mi );
IF mi = NIL THEN               { mouse interrupt vector null }
    mouse_present := False
ELSE IF Byte(mi^) = iret THEN  { vector points to iret }
    mouse_present := False
ELSE
    mouse_present := True;

END. { mouse unit }
