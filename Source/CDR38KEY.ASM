; history:
; 1.0   initial release
;       tested with: CDRWin V3.8A Beta of 12/27/99
; 1.1   change of Expiration_Word, 0x4a2 blacklisted since 01/19/00,
;       Hi to Egis/Core.
;       also tested with: CDRWIN V3.8A Final of 03/20/00
; 1.2   change of Expiration_Word, 0x4a4 blacklisted since 28/06/00,
;       this is getting boring, why don't you finally use the rest of 
;       your key, Jeff? - i'm getting impatient :=>
; 2.0   option to change expiration range;
;       option to generate cdrwin.dat
;       option to get keycode from cdrwin.dat 
;       option to fix badly cracked cdrwin.dat
;
; tested with:
; - various betas of V3.8A
; - final of V3.8A
; - V3.8B June 2000
; - V3.8B July 2000

; CDRWin/DAO V3.8 Open-Source Keymaker V2.0 
; (C) The Riddler / X-FORCE / UNION

; #########################################################################
    .386
    .model flat, stdcall
    option casemap:none
; #########################################################################

    include \masm32\include\windows.inc

    include \masm32\include\kernel32.inc
    includelib \masm32\lib\kernel32.lib

    include \masm32\include\user32.inc
    includelib \masm32\lib\user32.lib

    include \masm32\include\comdlg32.inc
    includelib \masm32\lib\comdlg32.lib


; #########################################################################

;== local macros ==

    m2m MACRO M1, M2
        push M2
        pop  M1
    ENDM

    return MACRO arg
        mov eax, arg
        ret
    ENDM

;== local prototypes ==

DlgProc PROTO :DWORD,:DWORD,:DWORD,:DWORD
cdrwin_keyengine PROTO :DWORD
save_dat_routine PROTO :DWORD
dat_routine PROTO :DWORD

; #########################################################################


 .const
    IDC_STATIC          equ -1
    IDD_DIALOG          equ 100
    IDC_NAME            equ 3001
    IDC_EMAIL           equ 3002
    IDC_UNLOCKKEY       equ 3003
    IDC_CHECKKEY        equ 3004
    IDC_CDRWIN          equ 3006
    IDC_DAO             equ 3007
    IDC_MONTHSTART      equ 3010
    IDC_YEARSTART       equ 3011
    IDC_MONTHEND        equ 3012
    IDC_YEAREND         equ 3013
    IDC_RANDOMIZE       equ 3014
    IDC_GETDAT          equ 3100
    IDC_SAVE            equ 3101
    IDC_EDITFAQ         equ 3200

    IDM_EXIT            equ 5000

    MAXSIZE             equ 040h-1
    
 .data
    wsprintfa           dd 0
    userlib             db "user32.dll",0
ALIGN 4
    userfunction        db "wsprintfA",0
ALIGN 4
    lpError1            db "Please enter at least SIX characters!",0
ALIGN 4
    lpError2            db "ARGG! You're blacklisted!",0
ALIGN 4
    lpError3            db "Cannot read file!",0
ALIGN 4
    lpError4            db "Cdrwin.dat file is corrupted!",0
ALIGN 4
    lpError5            db "Date out of range you dummy!",0
ALIGN 4
    lpError6            db "COASTER warning! Bad Crack detected. Want to correct it?",0
ALIGN 4
    lpError7            db "You must enter valid Name/Company and Expiration before you save!",0
ALIGN 4
    lpCaption           db "CDRWin/DAO V3.8 Open-Source Keymaker V2.0",0
ALIGN 4
    lpCode              db "%08lX-%08lX-%08lX-%08lX",0
ALIGN 4
    lpSaved             db "Cdrwin.dat saved!",0
ALIGN 4
    szName              db MAXSIZE+1 dup (0)
ALIGN 4
    szEmail             db MAXSIZE+1 dup (0)
ALIGN 4
    Expiration_Word     dw 04b2h   ; 1.0: can be between 04a2h - 04bah
                                   ; 1.1: can be between 04a4h - 04bch
                                   ; 1.2: can be between 04a7h - 04beh
                                   ; 2.0: user defined                                 
ALIGN 4
    Default_Year        dd 1999
    Default_Month       dd 12      

    Base_Counter        equ 2       
    Base_Year           equ 1900
    Base_Month          equ 1       ; 1=Jan, ..., 12=Dec

    Length_of_Validity  equ 12      ; until now keys were 12 months valid.
                                    ; in V3.8B July'00 Goldenhawk extends it to 15 months?!

ALIGN 4
    szFileFilter        db "All Files (*.*)",0,"*.*",0
                        db "Cdrwin Registration File (cdrwin.dat)",0,"cdrwin.dat",0,0
ALIGN 4
    szFileOpenTitle     db "Select Cdrwin.dat to retrieve registration information...",0
ALIGN 4
    szFileSaveTitle     db "Select Cdrwin path to save Cdrwin.dat...",0
ALIGN 4
    Got_Fixed           db 0        ; Flag if Cdrwin.dat needed Fix and hence new Save
ALIGN 4
    Valid_Data          db 0        ; Flag if Input is valid and Save Cdrwin.dat is allowed

; == following data directly ripped from CDRWin code
ALIGN 4
    Empty_Dat label byte            ; The original cdrwin.dat taken from Cdrwin V3.8B :)
    db 002h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 079h, 0A7h, 0F8h, 04Dh, 043h, 044h, 052h, 04Fh
    db 04Dh, 020h, 052h, 065h, 063h, 06Fh, 072h, 064h, 069h, 06Eh, 067h, 020h, 053h, 06Fh, 066h, 074h
    db 077h, 061h, 072h, 065h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 047h, 06Fh, 06Ch, 064h
    db 065h, 06Eh, 020h, 048h, 061h, 077h, 06Bh, 020h, 054h, 065h, 063h, 068h, 06Eh, 06Fh, 06Ch, 06Fh
    db 067h, 079h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 031h, 032h, 035h, 020h
    db 049h, 06Eh, 064h, 069h, 061h, 06Eh, 020h, 052h, 06Fh, 063h, 06Bh, 020h, 052h, 06Fh, 061h, 064h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 04Dh, 065h, 072h, 072h
    db 069h, 06Dh, 061h, 063h, 06Bh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 04Eh, 048h, 000h, 000h
    db 030h, 033h, 030h, 035h, 034h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 036h, 030h, 033h, 02Dh
    db 034h, 032h, 039h, 02Dh, 031h, 030h, 032h, 037h, 000h, 000h, 000h, 000h, 036h, 030h, 033h, 02Dh
    db 034h, 032h, 039h, 02Dh, 030h, 030h, 037h, 033h, 000h, 000h, 000h, 000h, 044h, 065h, 06Dh, 06Fh
    db 06Eh, 073h, 074h, 072h, 061h, 074h, 069h, 06Fh, 06Eh, 020h, 056h, 065h, 072h, 073h, 069h, 06Fh
    db 06Eh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 047h, 06Fh, 06Ch, 064h
    db 065h, 06Eh, 020h, 048h, 061h, 077h, 06Bh, 020h, 054h, 065h, 063h, 068h, 06Eh, 06Fh, 06Ch, 06Fh
    db 067h, 079h, 000h, 065h, 02Eh, 064h, 065h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 084h, 0EDh, 077h, 057h
    db 0DAh, 053h, 080h, 027h, 0D9h, 09Dh, 0A6h, 0C4h, 032h, 0D0h, 0EAh, 09Dh, 055h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 018h, 000h, 006h, 000h, 0D0h, 007h, 006h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
               
ALIGN 4
Checksum_Table_1 db 4 dup(0), 7Eh, 88h,    3Eh, 1Ch, 0FCh,    10h, 7Dh, 38h, 82h
    db 98h,    43h, 24h, 0F8h,    21h, 0FAh, 70h,    86h, 0A9h, 0C4h
    db 6Ch,    4, 31h,    87h, 48h, 7Ah, 2 dup(0B9h), 54h, 0F0h
    db 43h,    0F4h, 0E1h, 8Eh, 0CBh, 0CAh, 0FDh, 0Ch,    53h, 89h
    db 0D9h, 72h, 0DBh, 0B7h, 0C5h,    8, 62h,    0Eh, 91h, 76h
    db 0EAh, 30h, 8Dh, 0F4h, 72h, 73h, 0A9h, 8Ah, 0FAh, 4Dh
    db 0B5h, 4 dup(0), 1, 56h, 0CEh, 18h, 2, 0ACh, 9Ch, 31h
    db 3, 0FAh, 52h, 29h, 4, 58h, 39h, 63h,    5, 0Eh,    0F7h, 7Bh
    db 6, 0F4h, 0A5h, 52h, 7, 0A2h,    6Bh, 4Ah, 8, 0B0h, 72h
    db 0C6h, 9, 0E6h, 0BCh,    0DEh, 0Ah, 1Ch,    0EEh, 0F7h, 0Bh
    db 4Ah,    20h, 0EFh, 0Ch,    0E8h, 4Bh, 0A5h, 0Dh, 0BEh, 85h
    db 0BDh, 0Eh, 44h, 0D7h, 94h, 0Fh, 12h,    19h, 8Ch, 5 dup(0)
    db 20h,    0, 14h,    0, 40h,    0, 28h,    0, 60h,    0, 3Ch,    0, 80h
    db 0, 50h, 0, 0A0h, 0, 44h, 0, 0C0h, 0,    78h, 0,    0E0h, 0
    db 6Ch,    2 dup(0), 1, 0A0h, 0, 20h, 1, 0B4h, 0, 40h, 1
    db 88h,    0, 60h,    1, 9Ch,    0, 80h,    1, 0F0h, 0, 0A0h, 1, 0E4h
    db 0, 0C0h, 1, 0D8h, 0,    0E0h, 1, 0CCh, 6 dup(0), 81h, 10h
    db 2 dup(0), 2,    21h, 2 dup(0), 83h, 31h, 2 dup(0), 4, 42h
    db 2 dup(0), 85h, 52h, 2 dup(0), 6, 63h, 2 dup(0), 87h
    db 73h,    2 dup(0), 8, 84h, 2 dup(0), 89h, 94h, 2    dup(0)
    db 0Ah,    0A5h, 2    dup(0),    8Bh, 0B5h, 2 dup(0), 0Ch, 0C6h
    db 2 dup(0), 8Dh, 0D6h,    2 dup(0), 0Eh, 0E7h, 2 dup(0)
    db 8Fh,    0F7h
ALIGN 4
Checksum_Table_2 db 4 dup(0), 0C0h, 0ADh, 55h, 19h, 80h, 5Bh, 0ABh, 32h
    db 40h,    0F6h, 0FEh, 2Bh, 0, 0B7h, 56h, 65h, 0C0h, 1Ah
    db 3, 7Ch, 80h,    0ECh, 0FDh, 57h, 40h, 41h, 0A8h, 4Eh, 0
    db 6Eh,    0ADh, 0CAh, 0C0h, 0C3h,    0F8h, 0D3h, 80h, 35h, 6
    db 0F8h, 40h, 98h, 53h,    0E1h, 0, 0D9h, 0FBh, 0AFh, 0C0h
    db 74h,    0AEh, 0B6h, 80h, 82h, 50h, 9Dh,    40h, 2Fh, 5, 84h
ALIGN 4
Checksum_Table_3 db 4 dup(0), 64h, 10h,    0B7h, 1Dh, 0C8h, 20h, 6Eh, 3Bh
    db 0ACh, 30h, 0D9h, 26h, 90h, 41h, 0DCh, 76h, 0F4h, 51h
    db 2 dup(6Bh), 58h, 61h, 0B2h, 4Dh, 3Ch, 71h, 5, 50h, 20h
    db 83h,    0B8h, 0EDh, 44h, 93h, 0Fh, 0F0h, 0E8h, 0A3h, 2 dup(0D6h)
    db 8Ch,    0B3h, 61h, 0CBh, 0B0h, 0C2h, 64h, 9Bh, 0D4h, 0D2h
    db 0D3h, 86h, 78h, 0E2h, 0Ah, 0A0h, 1Ch, 0F2h, 2 dup(0BDh)
    db 4 dup(0), 1,    10h, 1,    99h, 1,    20h, 1,    82h, 0,    30h, 0
    db 1Bh,    1, 40h,    1, 0B4h, 0, 50h, 0, 2Dh, 0, 60h, 0, 36h
    db 1, 70h, 1, 0AFh, 1, 80h, 1, 0D8h, 0,    90h, 0,    41h, 0
    db 0A0h, 0, 5Ah, 1, 0B0h, 1, 0C3h, 0, 0C0h, 0, 6Ch, 1
    db 0D0h, 1, 0F5h, 1, 0E0h, 1, 0EEh, 0, 0F0h, 0,    77h

include NOTES                       ; looooooong FAQ 

.data?
    BigBuffer               db 50 dup (?)   ; universally used :)
ALIGN 4
    License_Part_1          dd ?
    License_Part_2          dd ?
    License_Part_3          dd ?
    License_Part_4          dd ?

    Check_Part_1            dd ?
    Check_Part_2            dd ?
    Check_Part_3            dd ?
    Check_Part_4            dd ?

    hInstance               HINSTANCE ?
    CommandLine             LPSTR ?
    hWindow                 DWORD ?

    lpTranslated            LPSTR ?         ; not really needed, but M$ Win wants it

    FILESIZE                equ 260        
    SIZEOFDAT               equ 1024        ; cdrwin.dat = 0400h bytes
    szFileNameBuffer        db FILESIZE dup(?)
    ofn                     OPENFILENAME<>
    lpNumberOfBytesRead     dd ?

    DatFileBuffer           db SIZEOFDAT dup(?) ; buffer to contain cdrwin.dat information

    st_                     SYSTEMTIME<>    ; systemtime structure

 .code

start:
    invoke GetModuleHandle, NULL
    mov hInstance, eax
    invoke GetCommandLine
    mov CommandLine, eax
    invoke DialogBoxParam, hInstance, IDD_DIALOG, NULL, addr DlgProc, NULL
    invoke ExitProcess,eax

; ########################################################################
DlgProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    .IF uMsg == WM_INITDIALOG
        invoke GetDlgItem, hWnd, IDC_NAME
        invoke SetFocus, eax
        invoke LoadLibrary, addr userlib
        push eax
        invoke GetProcAddress, eax, addr userfunction
        mov dword ptr wsprintfa, eax
        pop eax
        invoke FreeLibrary, eax

        invoke SendDlgItemMessage, hWnd, IDC_NAME, EM_SETLIMITTEXT, MAXSIZE-1, 0
        invoke SendDlgItemMessage, hWnd, IDC_EMAIL, EM_SETLIMITTEXT, MAXSIZE-1, 0
        invoke SendDlgItemMessage, hWnd, IDC_MONTHSTART, EM_SETLIMITTEXT, 2, 0
        invoke SendDlgItemMessage, hWnd, IDC_YEARSTART, EM_SETLIMITTEXT, 4, 0

        invoke SetDlgItemInt, hWnd, IDC_MONTHSTART, Default_Month, FALSE
        invoke SetDlgItemInt, hWnd, IDC_YEARSTART, Default_Year, FALSE             

        invoke SendDlgItemMessage, hWnd, IDC_CDRWIN, BM_SETCHECK, 1, 0

        invoke SetDlgItemText, hWnd, IDC_EDITFAQ, addr FAQ_TEXT
    .ELSEIF uMsg == WM_CLOSE
        invoke SendMessage, hWnd, WM_COMMAND, IDM_EXIT, 0
    .ELSEIF uMsg == WM_COMMAND
        mov eax, wParam
        .IF lParam == 0
            .IF ax == IDM_EXIT
                invoke EndDialog, hWnd, NULL
            .ENDIF
        .ELSE
            mov edx, wParam
            shr edx, 16
            .IF dx == BN_CLICKED
                .IF ax == IDC_CDRWIN
                    jmp refresh_codes
                .ELSEIF ax == IDC_DAO
                refresh_codes:
                    mov dx, EN_CHANGE
                    shl edx, 16
                    mov dx, IDC_NAME
                    invoke SendMessage, hWnd, WM_COMMAND, edx, dx
                .ELSEIF ax == IDC_GETDAT
                    invoke dat_routine, hWnd 
                .ELSEIF ax == IDC_SAVE
                    invoke save_dat_routine, hWnd 
                .ENDIF
            .ELSEIF dx == EN_CHANGE
                cmp ax, IDC_NAME
                je proceed_info
                cmp ax, IDC_EMAIL
                je proceed_info
                cmp ax, IDC_MONTHSTART
                je proceed_info
                cmp ax, IDC_YEARSTART
                jne dont_proceed_info

proceed_info:
                invoke cdrwin_keyengine, hWnd
dont_proceed_info:
            .ENDIF
        .ENDIF
    .ELSE
        mov eax, FALSE
        ret
    .ENDIF
    mov eax, TRUE
    ret
DlgProc endp

; ########################################################################

cdrwin_keyengine proc hWnd:HWND
    pusha

; == Check Date Range and adjust Expiration Word
    invoke GetDlgItemInt, hWnd, IDC_YEARSTART, addr lpTranslated, FALSE
    cmp eax, Base_Year
    jae check_month
    invoke SetDlgItemText, hWnd, IDC_UNLOCKKEY, addr lpError5
    invoke SetDlgItemText, hWnd, IDC_CHECKKEY, addr lpError5
    invoke SetDlgItemInt, hWnd, IDC_YEAREND, 0, FALSE    
    invoke SetDlgItemInt, hWnd, IDC_MONTHEND, 0, FALSE   
    mov Valid_Data, 0
    jmp endof_keyengine   
check_month: 
    mov Default_Year, eax
    mov esi, eax
    invoke GetDlgItemInt, hWnd, IDC_MONTHSTART, addr lpTranslated, FALSE
    or eax, eax
    jne month_check_2
    jmp invalid_month
month_check_2:
    cmp eax, 12
    jbe done_date_check
invalid_month:
    invoke SetDlgItemText, hWnd, IDC_UNLOCKKEY, addr lpError5
    invoke SetDlgItemText, hWnd, IDC_CHECKKEY, addr lpError5
    invoke SetDlgItemInt, hWnd, IDC_YEAREND, 0, FALSE    
    invoke SetDlgItemInt, hWnd, IDC_MONTHEND, 0, FALSE   
    mov Valid_Data, 0
    jmp endof_keyengine   
done_date_check:
    mov Default_Month, eax

    mov edi, eax
    mov eax, esi
    mov ecx, 12
    mul ecx
    add eax, edi
    push eax
    add eax, Length_of_Validity     ; yes, 12 months...could've been done easier... 
                                    ; but we want to remain flexible in case of >12 months :)
    xor edx, edx
    mov edi, eax
    div ecx
    push eax
    mul ecx
    pop esi
    sub edi, eax
    jne not_end_of_year
    dec esi
    invoke SetDlgItemInt, hWnd, IDC_YEAREND, esi, FALSE    
    invoke SetDlgItemInt, hWnd, IDC_MONTHEND, 12, FALSE
    jmp done_date_check_2
not_end_of_year:
    invoke SetDlgItemInt, hWnd, IDC_YEAREND, esi, FALSE    
    invoke SetDlgItemInt, hWnd, IDC_MONTHEND, edi, FALSE       
               
done_date_check_2:
    pop eax
    sub eax, Base_Year*12-Base_Counter+Base_Month   ; calculate expiration word
    mov Expiration_Word, ax

; == Name/Company must be at least six characters long
    invoke GetDlgItemText, hWnd, IDC_NAME, addr szName, MAXSIZE
    .IF eax < 6
        invoke SetDlgItemText, hWnd, IDC_UNLOCKKEY, addr lpError1
        invoke SetDlgItemText, hWnd, IDC_CHECKKEY, addr lpError1
        mov Valid_Data, 0
    .ELSE
        invoke GetDlgItemText, hWnd, IDC_EMAIL, addr szEmail, MAXSIZE
        .IF eax < 6
            invoke SetDlgItemText, hWnd, IDC_UNLOCKKEY, addr lpError1
            invoke SetDlgItemText, hWnd, IDC_CHECKKEY, addr lpError1
            mov Valid_Data, 0
        .ELSE

; == Check if CDRWin or DAO Radiobutton
        invoke SendDlgItemMessage, hWnd, IDC_CDRWIN, BM_GETCHECK, 0, 0
        or eax, eax
        je is_DAO_1
        mov edi, 2
        jmp generate_checksum
is_DAO_1:
        mov edi, 1

; == Generate Checksum calculated from Name/Company
; == xxxxxxxx-xxxxxxxx-xxxxxxxx-XXXXXXXX

generate_checksum:
            push edi
            push offset szName
            call Checksum_1
            add esp, 4*2
            mov esi, eax
            push edi
            push offset szEmail
            call Checksum_1
            add esp, 4*2
            mov ecx, eax
            mov edx, eax
            and ecx, 0FF0000h
            shr edx, 10h
            or ecx, edx
            mov edx, eax
            and edx, 0FF00h
            shl eax, 10h
            or edx, eax
            xor eax, eax
            shr ecx, 8
            shl edx, 8
            or ecx, edx
            xor ecx, esi       ; ecx = xxxxxxxx-xxxxxxxx-xxxxxxxx-XXXXXXXX
            mov dword ptr [License_Part_4], ecx
            mov edi, ecx       ; keep License_Part_4 in edi for some time

; == Check if Blacklisted (compare License_Part_4 with a list of known blacklisted ones)
            push offset [License_Part_4]
; == Check if CDRWin or DAO Radiobutton
            invoke SendDlgItemMessage, hWnd, IDC_CDRWIN, BM_GETCHECK, 0, 0
            or eax, eax
            je is_DAO_2
            call CDRWin_Blacklisted_Routine
            jmp done_blacklistcheck
is_DAO_2:
            call DAO_Blacklisted_Routine
done_blacklistcheck:
            add esp, 4
            or ax, ax
            je not_blacklisted
            invoke SetDlgItemText, hWnd, IDC_UNLOCKKEY, addr lpError2
            invoke SetDlgItemText, hWnd, IDC_CHECKKEY, addr lpError2
            jmp endof_keyengine

not_blacklisted:
; == Generate Version/Expiration Info
; == xxxxxxxx-xxxxxxxx-xxxxXXXX-xxxxxxxx
            mov ecx, edi
            shr ecx, 10h
            xor cx, Expiration_Word	; xor cx, xxxxxxxx-xxxxxxxx-xxxxXXXX-xxxxxxxx
            mov word ptr [License_Part_3], cx

; == Checksum Check, occurs when program is started (fails = piracy message)
; == xxxxxxxx-xxxxxxxx-XXXXxxxx-xxxxxxxx
            push 0                          ; little fix for stack problem
            mov eax, edi
            push 0
            lea ecx, [esp+4]
            push 4
            add eax, 64h
            push ecx
            push offset Checksum_Table_3
            mov [esp+10h], eax
            call Checksum_32Bit_Routine
            add esp, 14h
            shr eax, 10h
            xor edx, edx
            mov word ptr [License_Part_3+2], ax ; xxxxxxxx-xxxxxxxx-XXXXxxxx-xxxxxxxxx


; == Hidden Check 1:
; == XXXXxxxx-xxxxxxxx-xxxxxxxx-xxxxxxxx
            mov eax, edi
            add eax, 40h
            mov edx, eax
            mov esi, eax
            shr edx, 19h
            shl esi, 7
            or edx, esi
            shr eax, 0Dh
            add edx, eax
            mov word ptr [License_Part_1+2], dx

; == Hidden Check 2: 
; == xxxxxxxx-xxxxXXXX-xxxxxxxx-xxxxxxxx
            xor edx, edx
            xor eax, eax
            mov ecx, edi
hidden2_1:
            test cl, 1
            jz hidden2_2
            add edx, ecx
hidden2_2:
            add edx, eax
            shr ecx, 1
            inc eax
            cmp eax, 20h
            jl hidden2_1
            mov word ptr [License_Part_2], dx

            invoke SendDlgItemMessage, hWnd, IDC_RANDOMIZE, BM_GETCHECK, 0, 0
            or eax, eax
            jne dont_randomize      ; don't use randome if user wants that


; == Hidden Check 3:
; == NOT YET USED! -- V3.8A 12/27/99, V3.8A 03/20/00, V3.8B July 00
; == Therefore use (very pseudo) pseudo random words for:
; == xxxxXXXX-XXXXxxxx-xxxxxxxx-xxxxxxxx
            invoke GetTickCount
            mov edi, eax
            imul edx, edi, 01343f123h
            mov word ptr [License_Part_1], dx
            imul edx, edi, 0c01439ach
            shr edx, 16
            mov word ptr [License_Part_2+2], dx
dont_randomize:

; == Generate Check Codes
            mov esi, offset [License_Part_1]
            mov ecx, offset [Check_Part_1]
            mov edi, [esi]
            mov eax, [esi+4]
            mov edx, edi
            xor edx, eax
            mov [ecx+4], edx
            mov edx, [esi+8]
            mov ebx, edx
            xor ebx, eax
            mov [ecx+8], ebx
            mov eax, [esi+0Ch]
            mov ebx, eax
            xor ebx, edx
            mov [ecx+0Ch], ebx
            xor eax, edi
            mov [ecx], eax

; == Display Codes
            xor edi, edi
            mov esi, offset [License_Part_1]
display_codes:
            push dword ptr [esi+0Ch]
            push dword ptr [esi+8]
            push dword ptr [esi+4]
            push dword ptr [esi]
            push offset lpCode
            push offset BigBuffer
            call dword ptr [wsprintfa]
            add esp, 6*4
            or edi, edi
            jne display_codes_2
            invoke SetDlgItemText, hWnd, IDC_UNLOCKKEY, addr BigBuffer
            inc edi
            mov esi, offset [Check_Part_1]
            jmp display_codes
display_codes_2:
            invoke SetDlgItemText, hWnd, IDC_CHECKKEY, addr BigBuffer

            mov Valid_Data, 1
        .ENDIF
    .ENDIF
endof_keyengine:
    popa
    ret
cdrwin_keyengine endp

save_dat_routine proc hWnd:HWND
    pusha
    cmp Valid_Data, 0
    jne save_dat
    invoke MessageBox, hWnd, addr lpError7, addr lpCaption, MB_ICONEXCLAMATION
    jmp end_save

save_dat:
    lea esi, Empty_Dat
    lea edi, DatFileBuffer
    mov ecx, SIZEOFDAT
    rep movsb

    invoke GetDlgItemText, hWnd, IDC_NAME, addr DatFileBuffer+460, MAXSIZE
    invoke GetDlgItemText, hWnd, IDC_EMAIL, addr DatFileBuffer+524, MAXSIZE

    lea ebx, License_Part_4
    lea ecx, DatFileBuffer+828
    mov eax, [ebx]
    mov [ecx], eax
    mov eax, [ebx-4]
    mov [ecx+4], eax
    mov eax, [ebx-8]
    mov [ecx+8], eax
    mov eax, [ebx-12]
    mov [ecx+12], eax

    invoke GetLocalTime, addr st_
    lea eax, DatFileBuffer+852
    mov cx, st_.wDay
    mov dx, st_.wMonth
    mov word ptr [eax], cx
    mov cx, st_.wYear
    mov word ptr [eax+2], dx
    mov dx, st_.wDayOfWeek
    mov word ptr [eax+4], cx
    mov word ptr [eax+6], dx

    push 0
    push 03f4h
    push offset DatFileBuffer+0ch
    push offset Checksum_Table_3
    call Checksum_32Bit_Routine
    add esp, 10h
    mov dword ptr DatFileBuffer+08h, eax
    mov ecx, SIZEOFDAT
    xor eax, eax
    lea edx, DatFileBuffer
@Encrypt:
    mov bl, byte ptr [eax+edx]
    add bl, al
    mov [eax+edx], bl
    inc eax
    loop @Encrypt 

    invoke RtlZeroMemory, addr ofn, sizeof ofn
    mov ofn.lStructSize, sizeof ofn
    m2m ofn.hWndOwner, hWnd
    m2m ofn.hInstance, hInstance
    mov ofn.lpstrFilter, offset szFileFilter
    invoke RtlZeroMemory, addr szFileNameBuffer, FILESIZE
    mov ofn.lpstrFile, offset szFileNameBuffer
    mov ofn.nFilterIndex, 2
    mov ofn.nMaxFile, FILESIZE
    mov ofn.Flags, OFN_CREATEPROMPT or \
                   OFN_LONGNAMES or OFN_EXPLORER or OFN_HIDEREADONLY
    mov ofn.lpstrTitle, offset szFileSaveTitle
    invoke GetSaveFileName, addr ofn
    .IF eax == TRUE
        invoke CreateFile, ofn.lpstrFile,
                           GENERIC_WRITE,
                           0, NULL,
                           CREATE_ALWAYS,
                           FILE_ATTRIBUTE_NORMAL,
                           NULL
    .ELSE
        jmp end_save
    .ENDIF
    push eax
    invoke WriteFile, eax, addr DatFileBuffer, SIZEOFDAT, addr lpNumberOfBytesRead,NULL
    pop eax
    invoke CloseHandle, eax
    invoke MessageBox, hWnd, addr lpSaved, addr lpCaption, MB_OK

end_save:
    popa
    ret
save_dat_routine endp

dat_routine proc hWnd:HWND

; == open dialog and read dat file
    pusha
    invoke RtlZeroMemory, addr ofn, sizeof ofn
    mov ofn.lStructSize, sizeof ofn
    m2m ofn.hWndOwner, hWnd
    m2m ofn.hInstance, hInstance
    mov ofn.lpstrFilter, offset szFileFilter
    invoke RtlZeroMemory, addr szFileNameBuffer, FILESIZE
    mov ofn.lpstrFile, offset szFileNameBuffer
    mov ofn.nFilterIndex, 2
    mov ofn.nMaxFile, FILESIZE
    mov ofn.Flags, OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST or \
                   OFN_LONGNAMES or OFN_EXPLORER or OFN_HIDEREADONLY
    mov ofn.lpstrTitle, offset szFileOpenTitle
    invoke GetOpenFileName, addr ofn
    .IF eax == TRUE
        invoke CreateFile, ofn.lpstrFile,
                           GENERIC_READ,
                           0, NULL,
                           OPEN_EXISTING,
                           FILE_ATTRIBUTE_NORMAL,
                           NULL
    .ELSE
        invoke MessageBox, hWnd, addr lpError3, addr lpCaption, MB_ICONEXCLAMATION
        jmp end_dat
    .ENDIF
    push eax
    invoke ReadFile, eax, addr DatFileBuffer, SIZEOFDAT, addr lpNumberOfBytesRead,NULL
    pop eax
    invoke CloseHandle, eax

; == decrypt cdrwin.dat file
    mov ecx, SIZEOFDAT
    xor eax, eax
    lea edx, DatFileBuffer
Decrypt_Dat:
    mov bl, byte ptr [eax+edx]
    sub bl, al
    mov [eax+edx], bl
    inc eax
    loop Decrypt_Dat    

; == check if cdrwin.dat ok
    push 0
    push 03f4h
    push offset DatFileBuffer+0ch
    push offset Checksum_Table_3
    call Checksum_32Bit_Routine
    add esp, 10h
    mov ecx, dword ptr DatFileBuffer+08h      ; checksum inside datfile
    .IF eax != ecx
        invoke MessageBox, hWnd, addr lpError4, addr lpCaption, MB_ICONEXCLAMATION
        jmp end_dat
    .ENDIF
    
; == do various checks if key is 100%
    push offset [DatFileBuffer+828]
    call CDRWin_Blacklisted_Routine
    add esp, 4
    or ax, ax
    je @2check
    invoke MessageBox, hWnd, addr lpError2, addr lpCaption, MB_ICONWARNING
    jmp end_dat

@2check:
    mov edi, 2
    push edi
    push offset DatFileBuffer+460
    call Checksum_1
    add esp, 4*2
    mov esi, eax
    push edi
    push offset DatFileBuffer+524
    call Checksum_1
    add esp, 4*2
    mov ecx, eax
    mov edx, eax
    and ecx, 0FF0000h
    shr edx, 10h
    or ecx, edx
    mov edx, eax
    and edx, 0FF00h
    shl eax, 10h
    or edx, eax
    xor eax, eax
    shr ecx, 8
    shl edx, 8
    or ecx, edx
    xor ecx, esi       
    mov edi, ecx
    cmp dword ptr DatFileBuffer+828, edi
    je @3check
    invoke MessageBox, hWnd, addr lpError6, addr lpCaption, MB_YESNO
    .IF eax == IDNO
        jmp end_dat 
    .ELSE
        mov dword ptr DatFileBuffer+828, edi
        mov Got_Fixed, 1
   .ENDIF
@3check:
    push 0                          ; little fix for stack problem
    mov eax, dword ptr DatFileBuffer+828
    push 0
    lea ecx, [esp+4]
    push 4
    add eax, 64h
    push ecx
    push offset Checksum_Table_3
    mov [esp+10h], eax
    call Checksum_32Bit_Routine
    add esp, 14h
    shr eax, 10h
    xor edx, edx
    mov edi, eax
    cmp word ptr DatFileBuffer+834, di
    je @4check
    cmp Got_Fixed, 1
    je @3fix
    invoke MessageBox, hWnd, addr lpError6, addr lpCaption, MB_YESNO
    .IF eax == IDNO
        jmp end_dat 
    .ELSE
    @3fix:
        mov word ptr DatFileBuffer+834, di
        mov Got_Fixed, 1
   .ENDIF
@4check:
    mov eax, dword ptr DatFileBuffer+828
    add eax, 40h
    mov edx, eax
    mov esi, eax
    shr edx, 19h
    shl esi, 7
    or edx, esi
    shr eax, 0Dh
    add edx, eax
    mov edi, edx
    cmp word ptr DatFileBuffer+842, di
    je @5check
    cmp Got_Fixed, 1
    je @4fix
    invoke MessageBox, hWnd, addr lpError6, addr lpCaption, MB_YESNO
    .IF eax == IDNO
        jmp end_dat 
    .ELSE
    @4fix:
        mov word ptr DatFileBuffer+842, di
        mov Got_Fixed, 1
   .ENDIF
@5check:
    xor edx, edx
    xor eax, eax
    mov ecx, dword ptr DatFileBuffer+828
@5check_1:
    test cl, 1
    jz @5check_2
    add edx, ecx
@5check_2:
    add edx, eax
    shr ecx, 1
    inc eax
    cmp eax, 20h
    jl @5check_1
    mov edi, edx
    cmp word ptr DatFileBuffer+836, di
    je @6check
    cmp Got_Fixed, 1
    je @5fix
    invoke MessageBox, hWnd, addr lpError6, addr lpCaption, MB_YESNO
    .IF eax == IDNO
        jmp end_dat 
    .ELSE
    @5fix:
        mov word ptr DatFileBuffer+836, di
        mov Got_Fixed, 1
   .ENDIF
@6check:
@donecheck:
    cmp Got_Fixed, 1
    jne no_fixing
    
; == fix dat and save back
    push 0
    push 03f4h
    push offset DatFileBuffer+0ch
    push offset Checksum_Table_3
    call Checksum_32Bit_Routine
    add esp, 10h
    mov dword ptr DatFileBuffer+08h, eax
    mov ecx, SIZEOFDAT
    xor eax, eax
    lea edx, DatFileBuffer
Encrypt_Dat:
    mov bl, byte ptr [eax+edx]
    add bl, al
    mov [eax+edx], bl
    inc eax
    loop Encrypt_Dat    
    invoke CreateFile, ofn.lpstrFile,
                       GENERIC_WRITE,
                       0, NULL,
                       OPEN_EXISTING,
                       FILE_ATTRIBUTE_NORMAL,
                       NULL
    push eax
    invoke WriteFile, eax, addr DatFileBuffer, SIZEOFDAT, addr lpNumberOfBytesRead,NULL
    pop eax
    invoke CloseHandle, eax
    mov ecx, SIZEOFDAT
    xor eax, eax
    lea edx, DatFileBuffer
@Fix:
    mov bl, byte ptr [eax+edx]
    sub bl, al
    mov [eax+edx], bl
    inc eax
    loop @Fix    

    mov Got_Fixed, 0

no_fixing:
; == fetch Name and Company
    invoke SetDlgItemText, hWnd, IDC_NAME, addr DatFileBuffer+460
    invoke SetDlgItemText, hWnd, IDC_EMAIL, addr DatFileBuffer+524

; == display expiration range 
    mov eax, dword ptr DatFileBuffer+832
    mov esi, dword ptr DatFileBuffer+828
    shr esi, 010h
    xor esi, eax
    and esi, 0ffffh
    add esi, Base_Year*12-Base_Counter+Base_Month
    mov eax, esi
    mov ecx, 12
    xor edx, edx
    div ecx
    or edx, edx
    jne not_end_of_da_year
    dec eax
    invoke SetDlgItemInt, hWnd, IDC_YEARSTART, eax, FALSE    
    invoke SetDlgItemInt, hWnd, IDC_MONTHSTART, 12, FALSE
    jmp finish_fetch_date 
not_end_of_da_year:
    mov edi, edx
    invoke SetDlgItemInt, hWnd, IDC_YEARSTART, eax, FALSE    
    invoke SetDlgItemInt, hWnd, IDC_MONTHSTART, edi, FALSE
finish_fetch_date:    

; == fetch Unlock Key and generate Check Key
    lea ebx, License_Part_4
    lea ecx, DatFileBuffer+828
    mov eax, [ecx]
    mov [ebx], eax
    mov eax, [ecx+4]
    mov [ebx-4], eax
    mov eax, [ecx+8]
    mov [ebx-8], eax
    mov eax, [ecx+12]
    mov [ebx-12], eax

    mov esi, offset [License_Part_1]
    mov ecx, offset [Check_Part_1]
    mov edi, [esi]
    mov eax, [esi+4]
    mov edx, edi
    xor edx, eax
    mov [ecx+4], edx
    mov edx, [esi+8]
    mov ebx, edx
    xor ebx, eax
    mov [ecx+8], ebx
    mov eax, [esi+0Ch]
    mov ebx, eax
    xor ebx, edx
    mov [ecx+0Ch], ebx
    xor eax, edi
    mov [ecx], eax

; == display code (must be at the end, otherwise overwrite through EN_CHANGE)
    xor edi, edi
    mov esi, offset [License_Part_1]
display_codes_again:
    push dword ptr [esi+0Ch]
    push dword ptr [esi+8]
    push dword ptr [esi+4]
    push dword ptr [esi]
    push offset lpCode
    push offset BigBuffer
    call dword ptr [wsprintfa]
    add esp, 6*4
    or edi, edi
    jne display_codes_2_again
    invoke SetDlgItemText, hWnd, IDC_UNLOCKKEY, addr BigBuffer
    inc edi
    mov esi, offset [Check_Part_1]
    jmp display_codes_again
display_codes_2_again:
    invoke SetDlgItemText, hWnd, IDC_CHECKKEY, addr BigBuffer


end_dat:
    popa
    ret
dat_routine endp

; == The following routines are directly ripped from CDRWin

Checksum_1 proc near
arg_0 = dword ptr  4
arg_4 = dword ptr  8
    mov eax, [esp+arg_4]
    push esi
    dec eax
    jz short loc_0_4203A6
    dec eax
    jz short loc_0_42039F
    xor eax, eax
    pop esi
    retn
loc_0_42039F:
    mov esi, offset Checksum_Table_1
    jmp short loc_0_4203AB
loc_0_4203A6:
    mov esi, offset Checksum_Table_2
loc_0_4203AB:
    mov edx, [esp+4+arg_0]
    push edi
    mov edi, edx
    or ecx, 0FFFFFFFFh
    xor eax, eax
    push 0
    repne scasb
    not ecx
    dec ecx
    push ecx
    push edx
    push esi
    call Checksum_32Bit_Routine
    add esp, 10h
    pop edi
    pop esi
    retn
Checksum_1 endp

Checksum_32Bit_Routine proc near
arg_0 = dword ptr 4
arg_4 = dword ptr 8
arg_8 = dword ptr 0Ch
arg_C = dword ptr 10h
    mov eax, [esp+arg_C]
    mov edx, [esp+arg_4]
    push edi
    mov edi, [esp+4+arg_8]
    test di, di
    jz short loc_0_43FDB0
    push ebx
    push ebp
    push esi
    mov esi, [esp+10h+arg_0]
    and edi, 0FFFFh
loc_0_43FD7F:
    xor ecx, ecx
    mov ebp, eax
    mov cl, [edx]
    inc edx
    mov ebx, ecx
    xor ebx, eax
    and ebx, 0Fh
    shr ebp, 4
    mov eax, [esi+ebx*4]
    xor eax, ebp
    shr ecx, 4
    mov ebx, eax
    and ecx, 0Fh
    and ebx, 0Fh
    xor ecx, ebx
    shr eax, 4
    mov ecx, [esi+ecx*4]
    xor eax, ecx
    dec edi
    jnz short loc_0_43FD7F
    pop esi
    pop ebp
    pop ebx
loc_0_43FDB0:
    pop edi
    retn
Checksum_32Bit_Routine endp

; ripped from CDRWin V3.8A 12/27/99, still up-to-date with DAO V3.8B July
CDRWin_Blacklisted_Routine proc near
var_250 = dword ptr -250h
var_24C = dword ptr -24Ch
var_248 = dword ptr -248h
var_244 = dword ptr -244h
var_240 = dword ptr -240h
var_23C = dword ptr -23Ch
var_238 = dword ptr -238h
var_234 = dword ptr -234h
var_230 = dword ptr -230h
var_22C = dword ptr -22Ch
var_228 = dword ptr -228h
var_224 = dword ptr -224h
var_220 = dword ptr -220h
var_21C = dword ptr -21Ch
var_218 = dword ptr -218h
var_214 = dword ptr -214h
var_210 = dword ptr -210h
var_20C = dword ptr -20Ch
var_208 = dword ptr -208h
var_204 = dword ptr -204h
var_200 = dword ptr -200h
var_1FC = dword ptr -1FCh
var_1F8 = dword ptr -1F8h
var_1F4 = dword ptr -1F4h
var_1F0 = dword ptr -1F0h
var_1EC = dword ptr -1ECh
var_1E8 = dword ptr -1E8h
var_1E4 = dword ptr -1E4h
var_1E0 = dword ptr -1E0h
var_1DC = dword ptr -1DCh
var_1D8 = dword ptr -1D8h
var_1D4 = dword ptr -1D4h
var_1D0 = dword ptr -1D0h
var_1CC = dword ptr -1CCh
var_1C8 = dword ptr -1C8h
var_1C4 = dword ptr -1C4h
var_1C0 = dword ptr -1C0h
var_1BC = dword ptr -1BCh
var_1B8 = dword ptr -1B8h
var_1B4 = dword ptr -1B4h
var_1B0 = dword ptr -1B0h
var_1AC = dword ptr -1ACh
var_1A8 = dword ptr -1A8h
var_1A4 = dword ptr -1A4h
var_1A0 = dword ptr -1A0h
var_19C = dword ptr -19Ch
var_198 = dword ptr -198h
var_194 = dword ptr -194h
var_190 = dword ptr -190h
var_18C = dword ptr -18Ch
var_188 = dword ptr -188h
var_184 = dword ptr -184h
var_180 = dword ptr -180h
var_17C = dword ptr -17Ch
var_178 = dword ptr -178h
var_174 = dword ptr -174h
var_170 = dword ptr -170h
var_16C = dword ptr -16Ch
var_168 = dword ptr -168h
var_164 = dword ptr -164h
var_160 = dword ptr -160h
var_15C = dword ptr -15Ch
var_158 = dword ptr -158h
var_154 = dword ptr -154h
var_150 = dword ptr -150h
var_14C = dword ptr -14Ch
var_148 = dword ptr -148h
var_144 = dword ptr -144h
var_140 = dword ptr -140h
var_13C = dword ptr -13Ch
var_138 = dword ptr -138h
var_134 = dword ptr -134h
var_130 = dword ptr -130h
var_12C = dword ptr -12Ch
var_128 = dword ptr -128h
var_124 = dword ptr -124h
var_120 = dword ptr -120h
var_11C = dword ptr -11Ch
var_118 = dword ptr -118h
var_114 = dword ptr -114h
var_110 = dword ptr -110h
var_10C = dword ptr -10Ch
var_108 = dword ptr -108h
var_104 = dword ptr -104h
var_100 = dword ptr -100h
var_FC = dword ptr -0FCh
var_F8 = dword ptr -0F8h
var_F4 = dword ptr -0F4h
var_F0 = dword ptr -0F0h
var_EC = dword ptr -0ECh
var_E8 = dword ptr -0E8h
var_E4 = dword ptr -0E4h
var_E0 = dword ptr -0E0h
var_DC = dword ptr -0DCh
var_D8 = dword ptr -0D8h
var_D4 = dword ptr -0D4h
var_D0 = dword ptr -0D0h
var_CC = dword ptr -0CCh
var_C8 = dword ptr -0C8h
var_C4 = dword ptr -0C4h
var_C0 = dword ptr -0C0h
var_BC = dword ptr -0BCh
var_B8 = dword ptr -0B8h
var_B4 = dword ptr -0B4h
var_B0 = dword ptr -0B0h
var_AC = dword ptr -0ACh
var_A8 = dword ptr -0A8h
var_A4 = dword ptr -0A4h
var_A0 = dword ptr -0A0h
var_9C = dword ptr -9Ch
var_98 = dword ptr -98h
var_94 = dword ptr -94h
var_90 = dword ptr -90h
var_8C = dword ptr -8Ch
var_88 = dword ptr -88h
var_84 = dword ptr -84h
var_80 = dword ptr -80h
var_7C = dword ptr -7Ch
var_78 = dword ptr -78h
var_74 = dword ptr -74h
var_70 = dword ptr -70h
var_6C = dword ptr -6Ch
var_68 = dword ptr -68h
var_64 = dword ptr -64h
var_60 = dword ptr -60h
var_5C = dword ptr -5Ch
var_58 = dword ptr -58h
var_54 = dword ptr -54h
var_50 = dword ptr -50h
var_4C = dword ptr -4Ch
var_48 = dword ptr -48h
var_44 = dword ptr -44h
var_40 = dword ptr -40h
var_3C = dword ptr -3Ch
var_38 = dword ptr -38h
var_34 = dword ptr -34h
var_30 = dword ptr -30h
var_2C = dword ptr -2Ch
var_28 = dword ptr -28h
var_24 = dword ptr -24h
var_20 = dword ptr -20h
var_1C = dword ptr -1Ch
var_18 = dword ptr -18h
var_14 = dword ptr -14h
var_10 = dword ptr -10h
var_C = dword ptr -0Ch
var_8 = dword ptr -8
var_4 = dword ptr -4
arg_0 = dword ptr  4
    sub esp, 250h
    push ebx
    mov ecx, 8574D6DAh
    mov eax, 52FAEF70h
    push esi
    push edi
    mov [esp+25Ch+var_248], 0A7ECB4BCh
    mov [esp+25Ch+var_244], 4F53C64Ch
    mov [esp+25Ch+var_240], 40BB4C25h
    mov [esp+25Ch+var_23C], 15B85CC9h
    mov [esp+25Ch+var_238], 60CF10ADh
    mov [esp+25Ch+var_234], 0C40DF385h
    mov [esp+25Ch+var_230], 3FBF9B41h
    mov [esp+25Ch+var_22C], 0C74BB7D7h
    mov [esp+25Ch+var_228], 0C1E43D51h
    mov [esp+25Ch+var_224], 345B3B7Eh
    mov [esp+25Ch+var_220], 717CDBC6h
    mov [esp+25Ch+var_21C], 4CF3D66Eh
    mov [esp+25Ch+var_218], 0FD1A3279h
    mov [esp+25Ch+var_214], 68D236F3h
    mov [esp+25Ch+var_210], 7D4BE720h
    mov [esp+25Ch+var_20C], 9C309CC1h
    mov [esp+25Ch+var_208], 659E52F8h
    mov [esp+25Ch+var_204], 0B42FED5Eh
    mov [esp+25Ch+var_200], 0E21BADD5h
    mov [esp+25Ch+var_1FC], 3E89D2B9h
    mov [esp+25Ch+var_1F8], 6D712456h
    mov [esp+25Ch+var_1F4], 0E1CF582Bh
    mov [esp+25Ch+var_1F0], 2B46EDEDh
    mov [esp+25Ch+var_1EC], 3285CC23h
    mov [esp+25Ch+var_1E8], 0F4465C0Eh
    mov [esp+25Ch+var_1E4], 31B3668Eh
    mov [esp+25Ch+var_1E0], 43799AFAh
    mov [esp+25Ch+var_1DC], 0F74F1CC8h
    mov [esp+25Ch+var_1D8], 0A194ED65h
    mov [esp+25Ch+var_1D4], 85468981h
    mov [esp+25Ch+var_1D0], 0DFFCA902h
    mov [esp+25Ch+var_1CC], 275590D1h
    mov [esp+25Ch+var_1C8], 37645E8Ah
    mov [esp+25Ch+var_1C4], 0D3AACB15h
    mov [esp+25Ch+var_1C0], 8672DEDBh
    mov [esp+25Ch+var_1BC], 0BD973BE0h
    mov [esp+25Ch+var_1B8], 278A0A4h
    mov [esp+25Ch+var_1B4], 0E911813Eh
    mov [esp+25Ch+var_1B0], 65DBAA75h
    mov [esp+25Ch+var_1AC], 49C93F5Eh
    mov [esp+25Ch+var_1A8], 784FFB86h
    mov [esp+25Ch+var_1A4], 0BE3D7B75h
    mov [esp+25Ch+var_1A0], ecx
    mov [esp+25Ch+var_19C], eax
    mov [esp+25Ch+var_198], 0FF695CF2h
    mov [esp+25Ch+var_194], 5425BDFCh
    mov [esp+25Ch+var_190], 0C964FD3Fh
    mov [esp+25Ch+var_18C], 0C3C307EFh
    mov [esp+25Ch+var_188], 99D948C7h
    mov [esp+25Ch+var_184], 0E65323AAh
    mov [esp+25Ch+var_180], 773F84B8h
    mov [esp+25Ch+var_17C], 0A79DF75Fh
    mov [esp+25Ch+var_178], 712A0DC8h
    mov [esp+25Ch+var_174], 0D84B09C1h
    mov [esp+25Ch+var_170], 0F7152AD8h
    mov [esp+25Ch+var_16C], 5F9355FEh
    mov [esp+25Ch+var_168], 0CF9B73B0h
    mov [esp+25Ch+var_164], 5EC34700h
    mov [esp+25Ch+var_160], 95D1B737h
    mov [esp+25Ch+var_15C], 0D590AA84h
    mov [esp+25Ch+var_158], 153F6E04h
    mov [esp+25Ch+var_154], 74797D39h
    mov [esp+25Ch+var_150], 213A82D2h
    mov [esp+25Ch+var_14C], 368A30EFh
    mov [esp+25Ch+var_148], 984244BBh
    mov [esp+25Ch+var_144], 782FA2Eh
    mov [esp+25Ch+var_140], 49934854h
    mov [esp+25Ch+var_13C], 0CB3552BAh
    mov [esp+25Ch+var_138], 44C23803h
    mov [esp+25Ch+var_134], 0E4524969h
    mov [esp+25Ch+var_130], 273D5E9Ah
    mov [esp+25Ch+var_12C], 0ED700070h
    mov [esp+25Ch+var_128], 55111A62h
    mov [esp+25Ch+var_124], 7D298F42h
    mov [esp+25Ch+var_120], 4F6D9D02h
    mov [esp+25Ch+var_11C], 92C9C7AAh
    mov esi, [esp+25Ch+arg_0]
    mov [esp+25Ch+var_30], ecx
    mov [esp+25Ch+var_2C], eax
    xor edi, edi
    mov edx, [esi]
    mov [esp+25Ch+var_118], 6360AA4Eh
    mov [esp+25Ch+var_114], 0ADFB8334h
    mov [esp+25Ch+var_110], 77723FA3h
    mov [esp+25Ch+var_10C], 41E7D9EDh
    mov [esp+25Ch+var_108], 8721489Ah
    mov [esp+25Ch+var_104], 3B7BEA3h
    mov [esp+25Ch+var_100], 69A7223Eh
    mov [esp+25Ch+var_FC], 54E1A472h
    mov [esp+25Ch+var_F8], 0D0A4C68Ch
    mov [esp+25Ch+var_F4], 874DF1F6h
    mov [esp+25Ch+var_F0], 20D67A7Dh
    mov [esp+25Ch+var_EC], 0CABA1697h
    mov [esp+25Ch+var_E8], 0FC6C2D00h
    mov [esp+25Ch+var_E4], 0C6A57724h
    mov [esp+25Ch+var_E0], 0C2DFC6F5h
    mov [esp+25Ch+var_DC], 9EDA9F18h
    mov [esp+25Ch+var_D8], 0D7359E61h
    mov [esp+25Ch+var_D4], 3BCDCE5Bh
    mov [esp+25Ch+var_D0], 13313369h
    mov [esp+25Ch+var_CC], 0E2387A8Dh
    mov [esp+25Ch+var_C8], 0FB8E0220h
    mov [esp+25Ch+var_C4], 8D340C1Dh
    mov [esp+25Ch+var_C0], 2067BCBDh
    mov [esp+25Ch+var_BC], 2AD25731h
    mov [esp+25Ch+var_B8], 35812D68h
    mov [esp+25Ch+var_B4], 1A983447h
    mov [esp+25Ch+var_B0], 7639059Fh
    mov [esp+25Ch+var_AC], 2998ADA3h
    mov [esp+25Ch+var_A8], 2FD98A24h
    mov [esp+25Ch+var_A4], 0F5ED8456h
    mov [esp+25Ch+var_A0], 0E36F3092h
    mov [esp+25Ch+var_9C], 673B95D7h
    mov [esp+25Ch+var_98], 0E3E6DBCh
    mov [esp+25Ch+var_94], 66640B75h
    mov [esp+25Ch+var_90], 726DC12Fh
    mov [esp+25Ch+var_8C], 0E6D27EBBh
    mov [esp+25Ch+var_88], 4C065EB7h
    mov [esp+25Ch+var_84], 7AFE08DDh
    mov [esp+25Ch+var_80], 0F3DF18B5h
    mov [esp+25Ch+var_7C], 0B98EC3D7h
    mov [esp+25Ch+var_78], 4BA2E58Fh
    mov [esp+25Ch+var_74], 8498F6FEh
    mov [esp+25Ch+var_70], 0BCF64FC4h
    mov [esp+25Ch+var_6C], 46146CB3h
    mov [esp+25Ch+var_68], 0A0AA6CAFh
    mov [esp+25Ch+var_64], 7A47638Bh
    mov [esp+25Ch+var_60], 349327CBh
    mov [esp+25Ch+var_5C], 0A02C5AE6h
    mov [esp+25Ch+var_58], 0A13A3621h
    mov [esp+25Ch+var_54], 0B9E56293h
    mov [esp+25Ch+var_50], 0C5B1A5CFh
    mov [esp+25Ch+var_4C], 0D048E99Dh
    mov [esp+25Ch+var_48], 0CC87CF0Bh
    mov [esp+25Ch+var_44], 0CBC276CFh
    mov [esp+25Ch+var_40], 9068495Fh
    mov [esp+25Ch+var_3C], 0D0FF7891h
    mov [esp+25Ch+var_38], 0BD4ED21h
    mov [esp+25Ch+var_34], 0A1BFEC57h
    mov [esp+25Ch+var_28], 2B0CA78Bh
    mov [esp+25Ch+var_24], 49209AB3h
    mov [esp+25Ch+var_20], 95974DC5h
    mov [esp+25Ch+var_1C], 539BA816h
    mov [esp+25Ch+var_18], 0F3495BB8h
    mov [esp+25Ch+var_14], 869EBBAAh
    mov [esp+25Ch+var_10], 485EF215h
    mov [esp+25Ch+var_C], 7189252Ch
    mov [esp+25Ch+var_8], 0E14095B4h
    mov [esp+25Ch+var_4], 0B1BFF10Ah
    mov [esp+25Ch+var_250], 6706B724h
    mov [esp+25Ch+var_24C], 0D4DBED5Ah
    xor ecx, ecx
    lea eax, [esp+25Ch+var_244]
loc_0_420A59:
    mov ebx, [eax]
    xor ebx, 83AC00DEh
    cmp edx, ebx
    jz short is_Blacklisted
    add eax, 8
    inc ecx
    cmp ecx, 49h
    jl short loc_0_420A59
    xor ecx, ecx
    lea eax, [esp+25Ch+var_24C]
loc_0_420A74:
    mov esi, [eax]
    xor esi, 83AC00DEh
    cmp edx, esi
    jz short loc_0_420A8F
    add eax, 8
    inc ecx
    cmp ecx, 1
    jl short loc_0_420A74
loc_0_420A8F:        
    pop edi
    pop esi
    pop ebx
    add esp, 250h
    xor eax, eax
    retn

is_Blacklisted:
    pop  edi
    pop  esi
    pop  ebx
    add  esp, 250h
    mov  eax, 1
    retn
CDRWin_Blacklisted_Routine endp

; ripped from DAO V3.7F, still up-to-date with DAO V3.8B July
DAO_Blacklisted_Routine proc
var_230  = dword ptr -230h
var_22C  = dword ptr -22Ch
var_228  = dword ptr -228h
var_224  = dword ptr -224h
var_220  = dword ptr -220h
var_21C  = dword ptr -21Ch
var_218  = dword ptr -218h
var_214  = dword ptr -214h
var_210  = dword ptr -210h
var_20C  = dword ptr -20Ch
var_208  = dword ptr -208h
var_204  = dword ptr -204h
var_200  = dword ptr -200h
var_1FC  = dword ptr -1FCh
var_1F8  = dword ptr -1F8h
var_1F4  = dword ptr -1F4h
var_1F0  = dword ptr -1F0h
var_1EC  = dword ptr -1ECh
var_1E8  = dword ptr -1E8h
var_1E4  = dword ptr -1E4h
var_1E0  = dword ptr -1E0h
var_1DC  = dword ptr -1DCh
var_1D8  = dword ptr -1D8h
var_1D4  = dword ptr -1D4h
var_1D0  = dword ptr -1D0h
var_1CC  = dword ptr -1CCh
var_1C8  = dword ptr -1C8h
var_1C4  = dword ptr -1C4h
var_1C0  = dword ptr -1C0h
var_1BC  = dword ptr -1BCh
var_1B8  = dword ptr -1B8h
var_1B4  = dword ptr -1B4h
var_1B0  = dword ptr -1B0h
var_1AC  = dword ptr -1ACh
var_1A8  = dword ptr -1A8h
var_1A4  = dword ptr -1A4h
var_1A0  = dword ptr -1A0h
var_19C  = dword ptr -19Ch
var_198  = dword ptr -198h
var_194  = dword ptr -194h
var_190  = dword ptr -190h
var_18C  = dword ptr -18Ch
var_188  = dword ptr -188h
var_184  = dword ptr -184h
var_180  = dword ptr -180h
var_17C  = dword ptr -17Ch
var_178  = dword ptr -178h
var_174  = dword ptr -174h
var_170  = dword ptr -170h
var_16C  = dword ptr -16Ch
var_168  = dword ptr -168h
var_164  = dword ptr -164h
var_160  = dword ptr -160h
var_15C  = dword ptr -15Ch
var_158  = dword ptr -158h
var_154  = dword ptr -154h
var_150  = dword ptr -150h
var_14C  = dword ptr -14Ch
var_148  = dword ptr -148h
var_144  = dword ptr -144h
var_140  = dword ptr -140h
var_13C  = dword ptr -13Ch
var_138  = dword ptr -138h
var_134  = dword ptr -134h
var_130  = dword ptr -130h
var_12C  = dword ptr -12Ch
var_128  = dword ptr -128h
var_124  = dword ptr -124h
var_120  = dword ptr -120h
var_11C  = dword ptr -11Ch
var_118  = dword ptr -118h
var_114  = dword ptr -114h
var_110  = dword ptr -110h
var_10C  = dword ptr -10Ch
var_108  = dword ptr -108h
var_104  = dword ptr -104h
var_100  = dword ptr -100h
var_FC  = dword ptr -0FCh
var_F8  = dword ptr -0F8h
var_F4  = dword ptr -0F4h
var_F0  = dword ptr -0F0h
var_EC  = dword ptr -0ECh
var_E8  = dword ptr -0E8h
var_E4  = dword ptr -0E4h
var_E0  = dword ptr -0E0h
var_DC  = dword ptr -0DCh
var_D8  = dword ptr -0D8h
var_D4  = dword ptr -0D4h
var_D0  = dword ptr -0D0h
var_CC  = dword ptr -0CCh
var_C8  = dword ptr -0C8h
var_C4  = dword ptr -0C4h
var_C0  = dword ptr -0C0h
var_BC  = dword ptr -0BCh
var_B8  = dword ptr -0B8h
var_B4  = dword ptr -0B4h
var_B0  = dword ptr -0B0h
var_AC  = dword ptr -0ACh
var_A8  = dword ptr -0A8h
var_A4  = dword ptr -0A4h
var_A0  = dword ptr -0A0h
var_9C  = dword ptr -9Ch
var_98  = dword ptr -98h
var_94  = dword ptr -94h
var_90  = dword ptr -90h
var_8C  = dword ptr -8Ch
var_88  = dword ptr -88h
var_84  = dword ptr -84h
var_80  = dword ptr -80h
var_7C  = dword ptr -7Ch
var_78  = dword ptr -78h
var_74  = dword ptr -74h
var_70  = dword ptr -70h
var_6C  = dword ptr -6Ch
var_68  = dword ptr -68h
var_64  = dword ptr -64h
var_60  = dword ptr -60h
var_5C  = dword ptr -5Ch
var_58  = dword ptr -58h
var_54  = dword ptr -54h
var_50  = dword ptr -50h
var_4C  = dword ptr -4Ch
var_48  = dword ptr -48h
var_44  = dword ptr -44h
var_40  = dword ptr -40h
var_3C  = dword ptr -3Ch
var_38  = dword ptr -38h
var_34  = dword ptr -34h
var_30  = dword ptr -30h
var_2C  = dword ptr -2Ch
var_28  = dword ptr -28h
var_24  = dword ptr -24h
var_20  = dword ptr -20h
var_1C  = dword ptr -1Ch
var_18  = dword ptr -18h
var_14  = dword ptr -14h
var_10  = dword ptr -10h
var_C  = dword ptr -0Ch
var_8  = dword ptr -8
var_4  = dword ptr -4
arg_0  = dword ptr  4

    sub esp, 230h
    push ebx
    mov ecx, 8FAAE28Dh
    mov eax, 5824DB27h
    push esi
    push edi
    mov [esp+23Ch+var_228], 0AD3280EBh
    mov [esp+23Ch+var_224], 458DF21Bh
    mov [esp+23Ch+var_220], 4A657872h
    mov [esp+23Ch+var_21C], 1F66689Eh
    mov [esp+23Ch+var_218], 6A1124FAh
    mov [esp+23Ch+var_214], 0CED3C7D2h
    mov [esp+23Ch+var_210], 3561AF16h
    mov [esp+23Ch+var_20C], 0CD958380h
    mov [esp+23Ch+var_208], 0CB3A0906h
    mov [esp+23Ch+var_204], 3E850F29h
    mov [esp+23Ch+var_200], 7BA2EF91h
    mov [esp+23Ch+var_1FC], 462DE239h
    mov [esp+23Ch+var_1F8], 0F7C4062Eh
    mov [esp+23Ch+var_1F4], 620C02A4h
    mov [esp+23Ch+var_1F0], 7795D377h
    mov [esp+23Ch+var_1EC], 96EEA896h
    mov [esp+23Ch+var_1E8], 6F4066AFh
    mov [esp+23Ch+var_1E4], 0BEF1D909h
    mov [esp+23Ch+var_1E0], 0E8C59982h
    mov [esp+23Ch+var_1DC], 3457E6EEh
    mov [esp+23Ch+var_1D8], 67AF1001h
    mov [esp+23Ch+var_1D4], 0EB116C7Ch
    mov [esp+23Ch+var_1D0], 2198D9BAh
    mov [esp+23Ch+var_1CC], 385BF874h
    mov [esp+23Ch+var_1C8], 0FE986859h
    mov [esp+23Ch+var_1C4], 3B6D52D9h
    mov [esp+23Ch+var_1C0], 49A7AEADh
    mov [esp+23Ch+var_1BC], 0FD91289Fh
    mov [esp+23Ch+var_1B8], 0AB4AD932h
    mov [esp+23Ch+var_1B4], 8F98BDD6h
    mov [esp+23Ch+var_1B0], 0D5229D55h
    mov [esp+23Ch+var_1AC], 2D8BA486h
    mov [esp+23Ch+var_1A8], 3DBA6ADDh
    mov [esp+23Ch+var_1A4], 0D974FF42h
    mov [esp+23Ch+var_1A0], 8CACEA8Ch
    mov [esp+23Ch+var_19C], 0B7490FB7h
    mov [esp+23Ch+var_198], 8A694F3h
    mov [esp+23Ch+var_194], 0E3CFB569h
    mov [esp+23Ch+var_190], 6F059E22h
    mov [esp+23Ch+var_18C], 43170B09h
    mov [esp+23Ch+var_188], 7291CFD1h
    mov [esp+23Ch+var_184], 0B4E34F22h
    mov [esp+23Ch+var_180], ecx
    mov [esp+23Ch+var_17C], eax
    mov [esp+23Ch+var_178], 0F5B768A5h
    mov [esp+23Ch+var_174], 5EFB89ABh
    mov [esp+23Ch+var_170], 0C3BAC968h
    mov [esp+23Ch+var_16C], 0C91D33B8h
    mov [esp+23Ch+var_168], 93077C90h
    mov [esp+23Ch+var_164], 0EC8D17FDh
    mov [esp+23Ch+var_160], 7DE1B0EFh
    mov [esp+23Ch+var_15C], 0AD43C308h
    mov [esp+23Ch+var_158], 7BF4399Fh
    mov [esp+23Ch+var_154], 0D2953D96h
    mov [esp+23Ch+var_150], 0FDCB1E8Fh
    mov [esp+23Ch+var_14C], 554D61A9h
    mov [esp+23Ch+var_148], 0C54547E7h
    mov [esp+23Ch+var_144], 541D7357h
    mov [esp+23Ch+var_140], 9F0F8360h
    mov [esp+23Ch+var_13C], 0DF4E9ED3h
    mov [esp+23Ch+var_138], 1FE15A53h
    mov [esp+23Ch+var_134], 7EA7496Eh
    mov [esp+23Ch+var_130], 2BE4B685h
    mov [esp+23Ch+var_12C], 3C5404B8h
    mov [esp+23Ch+var_128], 929C70ECh
    mov [esp+23Ch+var_124], 0D5CCE79h
    mov [esp+23Ch+var_120], 434D7C03h
    mov [esp+23Ch+var_11C], 0C1EB66EDh
    mov [esp+23Ch+var_118], 4E1C0C54h
    mov [esp+23Ch+var_114], 0EE8C7D3Eh
    mov [esp+23Ch+var_110], 2DE36ACDh
    mov [esp+23Ch+var_10C], 0E7AE3427h
    mov [esp+23Ch+var_108], 5FCF2E35h
    mov [esp+23Ch+var_104], 77F7BB15h
    mov [esp+23Ch+var_100], 45B3A955h
    mov [esp+23Ch+var_FC], 9817F3FDh
    mov esi, [esp+23Ch+arg_0]
    mov [esp+23Ch+var_10], ecx
    mov [esp+23Ch+var_C], eax
    xor edi, edi
    mov edx, [esi]
    mov [esp+23Ch+var_F8], 69BE9E19h
    mov [esp+23Ch+var_F4], 0A725B763h
    mov [esp+23Ch+var_F0], 7DAC0BF4h
    mov [esp+23Ch+var_EC], 4B39EDBAh
    mov [esp+23Ch+var_E8], 8DFF7CCDh
    mov [esp+23Ch+var_E4], 9698AF4h
    mov [esp+23Ch+var_E0], 63791669h
    mov [esp+23Ch+var_DC], 5E3F9025h
    mov [esp+23Ch+var_D8], 0DA7AF2DBh
    mov [esp+23Ch+var_D4], 8D93C5A1h
    mov [esp+23Ch+var_D0], 2A084E2Ah
    mov [esp+23Ch+var_CC], 0C06422C0h
    mov [esp+23Ch+var_C8], 0F6B21957h
    mov [esp+23Ch+var_C4], 0CC7B4373h
    mov [esp+23Ch+var_C0], 0C801F2A2h
    mov [esp+23Ch+var_BC], 9404AB4Fh
    mov [esp+23Ch+var_B8], 0DDEBAA36h
    mov [esp+23Ch+var_B4], 3113FA0Ch
    mov [esp+23Ch+var_B0], 19EF073Eh
    mov [esp+23Ch+var_AC], 0E8E64EDAh
    mov [esp+23Ch+var_A8], 0F1503677h
    mov [esp+23Ch+var_A4], 87EA384Ah
    mov [esp+23Ch+var_A0], 2AB988EAh
    mov [esp+23Ch+var_9C], 200C6366h
    mov [esp+23Ch+var_98], 3F5F193Fh
    mov [esp+23Ch+var_94], 10460010h
    mov [esp+23Ch+var_90], 7CE731C8h
    mov [esp+23Ch+var_8C], 234699F4h
    mov [esp+23Ch+var_88], 2507BE73h
    mov [esp+23Ch+var_84], 0FF33B001h
    mov [esp+23Ch+var_80], 0E9B104C5h
    mov [esp+23Ch+var_7C], 6DE5A180h
    mov [esp+23Ch+var_78], 4E059EBh
    mov [esp+23Ch+var_74], 6CBA3F22h
    mov [esp+23Ch+var_70], 78B3F578h
    mov [esp+23Ch+var_6C], 0EC0C4AECh
    mov [esp+23Ch+var_68], 46D86AE0h
    mov [esp+23Ch+var_64], 70203C8Ah
    mov [esp+23Ch+var_60], 0F9012CE2h
    mov [esp+23Ch+var_5C], 0B350F780h
    mov [esp+23Ch+var_58], 417CD1D8h
    mov [esp+23Ch+var_54], 8E46C2A9h
    mov [esp+23Ch+var_50], 0B6287B93h
    mov [esp+23Ch+var_4C], 4CCA58E4h
    mov [esp+23Ch+var_48], 0AA7458F8h
    mov [esp+23Ch+var_44], 709957DCh
    mov [esp+23Ch+var_40], 3E4D139Ch
    mov [esp+23Ch+var_3C], 0AAF26EB1h
    mov [esp+23Ch+var_38], 0ABE40276h
    mov [esp+23Ch+var_34], 0B33B56C4h
    mov [esp+23Ch+var_30], 0CF6F9198h
    mov [esp+23Ch+var_2C], 0DA96DDCAh
    mov [esp+23Ch+var_28], 0C659FB5Ch
    mov [esp+23Ch+var_24], 0C11C4298h
    mov [esp+23Ch+var_20], 9AB67D08h
    mov [esp+23Ch+var_1C], 0DA214CC6h
    mov [esp+23Ch+var_18], 10AD976h
    mov [esp+23Ch+var_14], 0AB61D800h
    mov [esp+23Ch+var_8], 21D293DCh
    mov [esp+23Ch+var_4], 43FEAEE4h
    mov [esp+23Ch+var_230], 6DD88373h
    mov [esp+23Ch+var_22C], 0DE05D90Dh
    xor ecx, ecx
    lea eax, [esp+23Ch+var_228]
loc_0_402A01:    
    mov ebx, [eax]
    xor ebx, 89723489h
    cmp edx, ebx
    jz short loc_0_402A41
    add eax, 8
    inc ecx
    cmp ecx, 45h
    jl short loc_0_402A01
    xor ecx, ecx
    lea eax, [esp+23Ch+var_230]
loc_0_402A1C:    
    mov esi, [eax]
    xor esi, 89723489h
    cmp edx, esi
    jz short loc_0_402A37
    add eax, 8
    inc ecx
    cmp ecx, 1
    jl short loc_0_402A1C
loc_0_402A37: 
    pop edi
    pop esi
    pop ebx
    xor   eax, eax
    add esp, 230h
    retn
loc_0_402A41: 
    pop edi
    pop esi
    pop ebx
    mov   eax, 1
    add esp, 230h
    retn
DAO_Blacklisted_Routine endp



end start
