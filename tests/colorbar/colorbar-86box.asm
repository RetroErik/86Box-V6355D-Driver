; 86Box test variant generated from Olivetti-PC1-Hidden graphics mode/colorbar.asm.
; Use -D V6355_MODE=0x4A (hidden) or 0x0A (CGA control).
%ifndef V6355_MODE
%define V6355_MODE 0x4A
%endif

; ============================================================================
; COLORBAR.ASM (v 1.1) - Hidden graphics mode demo for Olivetti Prodest PC1
; Hidden 160x200x16 Graphics Mode
; v1.1: Switched all V6355D I/O to canonical full 0x3Dx ports (via DX) so the
;       demo also runs correctly on SerdaVision in AT-class 286/386/486 PCs.
; Written for NASM - NEC V40 (80186 compatible)
; By Retro Erik - 2026 using VS Code with Co-Pilot
;
; Controls:
;   SPACE - Cycle palette colors (random from 512-color palette)
;   W     - Reset to startup screen (CGA palette, 16 bars)
;   A     - Cycle border color (0-15)
;   Q     - Draw random colored circle(ish)
;   D     - Gradient dither demo (cycles Red→Green→Blue→Gray on each press)
;   T     - Draw test pattern (10x10 grid, 8 color boxes, gradient)
;   0     - Set bar width to 10 pixels (fills entire screen width)
;   1-9   - Set bar width to 1-9 pixels (16 bars from left edge)
;   ESC   - Exit to DOS in text mode
; ============================================================================

[BITS 16]
[ORG 0x100]

; ============================================================================
; Constants
; ============================================================================

; --- Video Memory ---
VIDEO_SEG       equ 0xB800      ; 86Box standalone V6355D framebuffer

; --- Yamaha V6355D I/O Ports ---
; PC1 aliases: D8/D9/DD/DE and 3D8/3D9/3DD/3DE all reach the same V6355D
; registers on real PC1 hardware. This source deliberately uses the full
; 3D* ports so it is also safe for SerdaVision on AT-class 286/386/486
; machines, where the short D8/D9/DD/DE addresses overlap the second DMA
; controller's port range. Full ports work fine on the real PC1 too, since
; they are aliases there.
PORT_REG_ADDR   equ 0x3DD       ; Register Bank Address Port (select register 0x00-0x7F)
PORT_REG_DATA   equ 0x3DE       ; Register Bank Data Port (read/write selected register)
PORT_MODE       equ 0x3D8       ; Mode Control Register (CGA compatible + extensions)
PORT_COLOR      equ 0x3D9       ; Color Select Register (border color, palette index 0-15)

; ============================================================================
; V6355_OUT - write AL to a full V6355D port (>0xFF) through DX
; An x86 immediate-port OUT only encodes an 8-bit port number, so ports above
; 0xFF must go through DX. This macro preserves DX around the write.
; ============================================================================
%macro V6355_OUT 1
    push dx
    mov dx, %1
    out dx, al
    pop dx
%endmacro

; --- Screen Dimensions (160x200x16 hidden mode) ---
SCREEN_WIDTH    equ 160         ; Horizontal resolution in pixels
SCREEN_HEIGHT   equ 200         ; Vertical resolution in pixels
BYTES_PER_ROW   equ 80          ; 160 pixels / 2 pixels per byte (packed nibbles)

; --- Keyboard ASCII Codes ---
KEY_ESC         equ 0x1B        ; Escape key (exit program)
KEY_SPACE       equ 0x20        ; Space bar (randomize palette)

; ============================================================================
; Main Program Entry Point
; ============================================================================
main:
    ; Check for /? or /h command line argument
    call check_help_arg
    jc .show_help               ; CF set = show help and exit
    jmp .start_program

.show_help:
    call print_help
    mov ax, 0x4C00              ; Exit to DOS
    int 0x21

.start_program:
    ; Save original video mode
    mov ah, 0x0F
    int 0x10                    ; Get current video mode
    mov [orig_video_mode], al   ; Save mode in AL

    ; Save original text attribute (read from screen position 0,0)
    mov ah, 0x08
    mov bh, 0                   ; Page 0
    int 0x10                    ; Get char+attr at cursor
    mov [orig_text_attr], ah    ; Save attribute in AH

    ; Initialize random seed from timer
    call init_random

    ; Enable the hidden 160x200x16 graphics mode
    call enable_graphics_mode

    ; Initialize screen with CGA colors and 16 bars
    call reset_screen

.main_loop:
    ; Wait for keypress (AH = scan code, AL = ASCII)
    call wait_key

    ; Convert lowercase to uppercase for easier comparison
    cmp al, 'a'
    jb .check_keys
    cmp al, 'z'
    ja .check_keys
    sub al, 32              ; Convert to uppercase

.check_keys:
    ; ESC - Exit program
    cmp al, KEY_ESC
    je .exit_program

    ; SPACE - Randomize palette
    cmp al, KEY_SPACE
    jne .not_space
    call generate_random_palette
    call set_palette
    jmp .main_loop
.not_space:

    ; W - Reset to startup screen
    cmp al, 'W'
    jne .not_w
    call reset_screen
    jmp .main_loop
.not_w:

    ; A - Cycle border color
    cmp al, 'A'
    jne .not_a
    call cycle_border
    jmp .main_loop
.not_a:

    ; Q - Draw random circle
    cmp al, 'Q'
    jne .not_q
    call draw_circle
    jmp .main_loop
.not_q:

    ; T - Draw test pattern
    cmp al, 'T'
    jne .not_t
    call draw_test_pattern
    jmp .main_loop
.not_t:

    ; D - Gradient dither demo (cycles color on each press)
    cmp al, 'D'
    jne .not_d
    call draw_gradient
    jmp .main_loop
.not_d:

    ; 0 - Bar width 10 (fills screen)
    cmp al, '0'
    jne .not_zero
    mov byte [bar_width], 10
    call draw_color_bars
    jmp .main_loop
.not_zero:

    ; 1-9 - Bar width 1-9 pixels
    cmp al, '1'
    jb .main_loop
    cmp al, '9'
    ja .main_loop
    sub al, '0'             ; Convert ASCII to number
    mov [bar_width], al
    call draw_color_bars
    jmp .main_loop

.exit_program:
    ; Reset palette to CGA defaults before exiting
    call set_cga_palette
    call set_palette

    ; Disable graphics mode (return to text mode)
    call disable_graphics_mode

    ; Restore original video mode
    mov ah, 0x00
    mov al, [orig_video_mode]
    int 0x10

    ; Clear screen with original text attribute
    mov ah, 0x06                ; Scroll up function
    mov al, 0                   ; Clear entire window
    mov bh, [orig_text_attr]    ; Use original attribute
    xor cx, cx                  ; Upper left (0,0)
    mov dx, 0x184F              ; Lower right (24,79)
    int 0x10

    ; Set cursor to top-left
    mov ah, 0x02
    xor bh, bh                  ; Page 0
    xor dx, dx                  ; Row 0, Col 0
    int 0x10

    ; Exit to DOS
    mov ax, 0x4C00
    int 0x21

; ============================================================================
; enable_graphics_mode - Olivetti Prodest PC1 hidden 160x200x16 graphics mode
; Configures Yamaha V6355D for hidden 160x200x16 graphics mode:
; - Sets 8-bit bus mode (PC1 has 8-bit bus, NOT 16-bit!)
; - Sets PAL timing (50Hz, 200 lines)
; - Enables 16-color mode (planar logic, custom palette)
; - Sets border color to black
; - Ensures safe defaults for PC1 hardware (no page mode, CRT timing)
; ---------------------------------------------------------------------------
enable_graphics_mode:
    push ax
    push dx

    ; BIOS Mode 4: CGA 320x200 graphics, sets CRTC for 15.7kHz sync
    mov ax, 0x0004
    int 0x10

    ; --- CONFIGURATION MODE REGISTER (Register 0x67) ---
    ; Not necessary for video initialization but kept for documentation purpose.
    ; Sets V6355D register 0x67 to 0x18:
    ; Bit 7: [0] 16-bit bus mode OFF - MUST be 0 on PC1's 8-bit bus!
    ;            If set on 8-bit bus, controller can only access odd bytes of VRAM.
    ; Bit 6: [0] 4-page video RAM OFF (PC1's only have 16KB DRAM)
    ; Bit 5: [0] LCD control period (CRT timing)
    ; Bit 4: [1] Display timing/centering (see datasheet)
    ; Bit 3: [1] Display timing/centering (see datasheet)
    ; Bits 0-2: [000] Horizontal centering offset (default) Range: 0-31 (5 bits total)
    ; Binary: 00011000b (0x18)
    mov al, 0x67
    mov dx, PORT_REG_ADDR
    out dx, al
    jmp short $+2
    mov al, 0x18            ; 8-bit bus, no paging, h-position=24
    mov dx, PORT_REG_DATA
    out dx, al
    jmp short $+2

    ; --- SET MONITOR CONTROL REGISTER (Register 0x65) FIRST ---
    ; Not necessary for video initialization but kept for documentation purpose.
    ; This register sets operational requirements for the video interface.
    ; Per 6355 LCDC manual Table 14-28 and Table 14-21:
    ; Bit 0-1: [01] Vertical line count = 200 lines (01b not 00b which equals 192 lines)
    ; Bit 2: [0] Horizontal pixel width = 320 or 640 pixels (standard)
    ; Bit 3: [1] TV Standard = PAL/SECAM (Norway/EU)
    ; Bit 4: [0] Color/Monochrome = IBM PC-compatible color mode
    ; Bit 5: [0] CRT vs LCD = Raster-scan CRT (SCART monitor)
    ; Bit 6: [0] RAM type = Dynamic RAM
    ; Bit 7: [0] Input device = Light-pen
    ;
    ; Binary: 0 0 0 0 1 0 0 1
    ;         │ │ │ │ │ │ │ └─ Bit 0: Vertical height of screen: 0 => 192, 1 => 200; 2 => 204
    ;         │ │ │ │ │ │ └─── Bit 1: Vertical height of screen: 0 => 192, 1 => 200; 2 => 204
    ;         │ │ │ │ │ └───── Bit 2: Width of screen: 0 => 640 / 320, 1 => 512 / 256
    ;         │ │ │ │ └─────── Bit 3: Vertical refresh: Set for 50Hz, clear for 60Hz
    ;         │ │ │ └───────── Bit 4: Monitor type: Set for MDA, clear for CGA
    ;         │ │ └─────────── Bit 5: CRT (SCART) mode
    ;         │ └───────────── Bit 6: Dynamic RAM
    ;         └─────────────── Bit 7: Light-pen
    ;
    ; Value: 0x09 (00001001b) = 200 lines, PAL, color, CRT
    ; Access via Register Bank: PORT_REG_ADDR (0xDD) / PORT_REG_DATA (0xDE)
    mov al, 0x65
    mov dx, PORT_REG_ADDR
    out dx, al
    jmp short $+2
    mov al, 0x09
    mov dx, PORT_REG_DATA
    out dx, al
    jmp short $+2

    ; --- MODE TEST (Port 0x3D8, V6355_MODE = 0x4A or 0x0A) ---
    ; This is the CGA Mode Control Register, but the PC1's Yamaha V6355D
    ; repurposes several bits for extended functionality.
    ;
    ; Standard CGA bits (IBM PC/XT compatible):
    ; Bit 0: [0] Text mode column width (0 = 40×25, 1 = 80×25)
    ; Bit 1: [1] Graphics mode enable (0 = text, 1 = graphics)
    ; Bit 2: [0] Video signal type (0 = color burst, 1 = mono)
    ; Bit 3: [1] Video enable (0 = blank, 1 = display)
    ; Bit 4: [0] High-res graphics (0 = 320x200, 1 = 640x200)
    ;
    ; Extended PC1/Yamaha V6355D bits:
    ; Bit 5: [0] Blink/Background (text mode only)
    ; Bit 6: [1 in CB86H, 0 in CB86C] MODE UNLOCK (Yamaha extension)
    ;         1 = Enable 16-color planar logic (160x200)
    ;         0 = Standard 4-color CGA mode
    ; Bit 7: [0] STANDBY MODE (V6355D Datasheet)
    ;         0 = Normal operation
    ;         1 = Power save mode (display blank)
    ;
    ; Values: 0x4A = hidden-mode request; 0x0A = CGA control.
    ;   Bit 6 differs between the two builds.
    ;   Bit 3 = 1 (Video enable)
    ;   Bit 1 = 1 (Graphics mode)
    ;   All other bits = 0
    mov al, V6355_MODE
    mov dx, PORT_MODE
    out dx, al
    jmp short $+2
    jmp short $+2

    ; Port 0x3D9: 0x00 = black border
    mov byte [border_color], 0
    xor al, al
    mov dx, PORT_COLOR
    out dx, al
    jmp short $+2
    jmp short $+2

    pop dx
    pop ax
    ret

; ============================================================================
; disable_graphics_mode - Disable the hidden graphics mode
; Must reset V6355 registers before BIOS mode switch
; ============================================================================
disable_graphics_mode:
    push ax
    push dx

    ; --- RESET CONFIGURATION MODE REGISTER (Register 0x67) ---
    ; Sets V6355D register 0x67 to 0x00:
    ; Bit 7: [0] 16-bit bus mode OFF (8-bit bus for PC1)
    ; Bit 6: [0] 4-page video RAM OFF
    ; Bit 5: [0] LCD control period (CRT timing)
    ; Bits 0-4: [00000] Horizontal position (default)
    ; Binary: 00000000b
    mov al, 0x67            ; Select register 0x67
    mov dx, PORT_REG_ADDR
    out dx, al              ; Register Bank Address Port
    jmp short $+2           ; I/O delay
    mov al, 0x00            ; Reset to defaults
    mov dx, PORT_REG_DATA
    out dx, al              ; Register Bank Data Port
    jmp short $+2           ; I/O delay

    ; --- RESET MONITOR CONTROL REGISTER (Register 0x65) ---
    ; Value: 09h (00001001b) - CORRECTED for 200 lines (bits 0-1 = 01b, not 00b)
    ; This sets: 200 lines, standard pixels, PAL, color, CRT, dynamic RAM
    ;
    ; Access via Register Bank: Port 0x3DD (address) / Port 0x3DE (data)
    ; Per 6355 LCDC port map: 0x3DD = Register Bank Address, 0x3DE = Register Bank Data
    ; Note: On PC1, 0xDD/0xDE and 0x3DD/0x3DE are aliases and function identically.
    mov al, 0x65            ; Select register 0x65
    mov dx, PORT_REG_ADDR
    out dx, al              ; Register Bank Address Port
    jmp short $+2           ; I/O delay
    mov al, 0x09            ; Keep 200 lines, PAL (safe default)
    mov dx, PORT_REG_DATA
    out dx, al              ; Register Bank Data Port
    jmp short $+2           ; I/O delay

    ; --- RESET 16-COLOR MODE (Port 0x3D8, value 0x28) ---
    ; Reset mode control port to standard CGA mode
    ; 0x28 = text mode (bit 5=1 blink, bit 3=1 video on)
    mov al, 0x28
    mov dx, PORT_MODE
    out dx, al
    jmp short $+2

    pop dx
    pop ax
    ret

; ============================================================================
; clear_screen - Clear video memory to black (color 0)
; ============================================================================
clear_screen:
    push ax
    push cx
    push di
    push es

    mov ax, VIDEO_SEG
    mov es, ax
    xor di, di
    mov cx, 8192            ; 16KB = 8192 words (0x4000 bytes)
    xor ax, ax              ; Fill with 0x0000
    cld
    rep stosw

    pop es
    pop di
    pop cx
    pop ax
    ret

; ============================================================================
; set_palette - Write the 16-color palette to the 6355 chip
;   MOV DX,3DDh / MOV AL,0x40 / OUT DX,AL  ; Enable palette write
;   Loop with OUT DX,AL to port 0x3DE      ; Output 32 bytes with I/O delays
;   MOV DX,3DDh / MOV AL,0x80 / OUT DX,AL  ; Disable palette write
;
; Palette format: 32 bytes (16 colors × 2 bytes each)
;   Byte 1: Red intensity (bits 0-2, values 0-7)
;   Byte 2: Green (bits 4-6) + Blue (bits 0-2)
; ============================================================================
set_palette:
    push ax
    push cx
    push si
    push dx

    cli                     ; Disable interrupts during palette write

    ; Enable palette write mode (write 0x40 to full port 0x3DD)
    mov dx, PORT_REG_ADDR
    mov al, 0x40
    out dx, al
    jmp short $+2           ; I/O delay
    jmp short $+2

    ; Write 32 bytes of palette data with I/O delays (PC1 hardware needs this!)
    mov si, palette
    mov cx, 32              ; 16 colors × 2 bytes
    mov dx, PORT_REG_DATA   ; DX stays on the data port for the whole loop

.pal_write_loop:
    lodsb                   ; Load byte from DS:SI into AL, inc SI
    out dx, al              ; Write to full port 0x3DE
    jmp short $+2           ; I/O delay
    loop .pal_write_loop

    ; Disable palette write mode (write 0x80 to full port 0x3DD)
    jmp short $+2           ; Extra delay before mode change
    mov dx, PORT_REG_ADDR
    mov al, 0x80
    out dx, al
    jmp short $+2           ; I/O delay

    sti                     ; Re-enable interrupts

    pop dx
    pop si
    pop cx
    pop ax
    ret

; ============================================================================
; draw_color_bars - Draw 16 vertical color bars on screen
; Uses [bar_width] to set pixel width of each bar (1-10 pixels)
; Always draws exactly 16 bars, starting from left edge
; Color 0 = black (matches border)
; Remaining pixels after 16 bars stay black
; ============================================================================
draw_color_bars:
    push ax
    push bx
    push cx
    push dx
    push di
    push si
    push es

    ; First clear the screen (fills with black/color 0)
    call clear_screen

    mov ax, VIDEO_SEG
    mov es, ax

    ; Calculate total width of all 16 bars
    mov al, [bar_width]
    xor ah, ah
    shl ax, 4               ; AX = bar_width * 16 = total pixels for all bars
    cmp ax, 160
    jbe .width_ok
    mov ax, 160             ; Cap at screen width
.width_ok:
    mov [bars_total_width], ax

    ; Draw all 200 rows using fast byte writes
    xor si, si              ; SI = row counter (0-199)

.row_loop:
    ; Calculate base offset for this row
    ; Even rows: offset = (row/2) * 80
    ; Odd rows:  offset = 0x2000 + (row/2) * 80
    mov ax, si
    shr ax, 1               ; AX = row / 2
    mov bx, 80
    mul bx                  ; AX = (row/2) * 80
    mov di, ax
    test si, 1              ; Check if odd row
    jz .even_row
    add di, 0x2000          ; Odd rows start at 0x2000
.even_row:

    ; For each row, write bytes for the bar area only
    xor bx, bx              ; BX = pixel position (0-159)

.pixel_loop:
    ; Check if we're past all 16 bars
    cmp bx, [bars_total_width]
    jae .row_done           ; Past bar area, rest stays black

    ; Calculate which color this pixel belongs to
    mov ax, bx
    mov cl, [bar_width]
    xor ch, ch
    div cl                  ; AL = pixel / bar_width = color index (0-15)
    mov dl, al              ; DL = left pixel color

    ; Get right pixel color (pixel + 1)
    mov ax, bx
    inc ax
    cmp ax, [bars_total_width]
    jae .right_black        ; Right pixel is past bar area
    div cl                  ; AL = (pixel+1) / bar_width
    jmp .combine

.right_black:
    xor al, al              ; Right pixel is black (color 0)

.combine:
    ; DL = left color, AL = right color
    ; Combine: byte = (left << 4) | right
    shl dl, 4
    or dl, al

    ; Write byte to video memory
    mov [es:di], dl
    inc di

    ; Advance by 2 pixels
    add bx, 2
    cmp bx, 160
    jb .pixel_loop

.row_done:
    ; Next row
    inc si
    cmp si, 200
    jb .row_loop

    pop es
    pop si
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

bars_total_width: dw 160    ; Total width of all 16 bars in pixels

; ============================================================================
; cycle_border - Cycle the border color 0-15
; ============================================================================
cycle_border:
    push ax
    push dx

    mov al, [border_color]
    inc al
    and al, 0x0F            ; Keep in range 0-15
    mov [border_color], al

    ; Output to border color port
    mov dx, PORT_COLOR
    out dx, al

    pop dx
    pop ax
    ret

; ============================================================================
; draw_test_pattern - Draw test pattern with grid, color boxes, and gradient
; - 10x10 white grid (16x20 pixel cells)
; - 8 bright CGA color boxes (10x40 pixels each, centered)
; - Black-to-white dither gradient (80x21 pixels, below color boxes)
;   Uses 8 true grey levels from 512-color palette (R=G=B, 0-7)
; ============================================================================
draw_test_pattern:
    push ax
    push bx
    push cx
    push dx
    push di
    push si
    push es

    ; Set up palette with 8 grey levels (0-7) + 8 CGA bright colors (8-15)
    call setup_test_palette
    call set_palette

    mov ax, VIDEO_SEG
    mov es, ax

    ; Clear screen first (black background)
    xor di, di
    mov cx, 8192            ; 16KB = 8192 words
    xor ax, ax
    rep stosw

    ; --- Draw 10x10 grid (white lines) ---
    mov byte [circle_color], 15     ; White (CGA color 15)

    ; Draw 11 horizontal lines at Y = 0, 20, 40, ... 180, 199 (last at bottom edge)
    xor bx, bx              ; BX = Y position
.hgrid_loop:
    mov word [circle_x1], 0
    mov word [circle_x2], 159
    mov ax, bx
    call draw_hline_packed
    add bx, 20              ; Next grid line
    cmp bx, 200
    jb .hgrid_loop
    ; Draw final line at Y=199 (bottom of screen)
    mov ax, 199
    call draw_hline_packed

    ; Draw 11 vertical lines at X = 0, 16, 32, ... 144, 159 (last at right edge)
    xor bx, bx              ; BX = X position
.vgrid_loop:
    ; Draw vertical line at X = BX
    xor dx, dx              ; DX = Y counter
.vline_y:
    cmp dx, 200
    jae .vline_next

    mov [circle_x1], bx
    mov [circle_x2], bx
    mov ax, dx
    push bx
    push dx
    call draw_hline_packed
    pop dx
    pop bx
    inc dx
    jmp .vline_y

.vline_next:
    add bx, 16              ; Next grid line
    cmp bx, 160
    jb .vgrid_loop
    ; Draw final line at X=159 (right edge)
    mov bx, 159
    xor dx, dx
.vline_final:
    cmp dx, 200
    jae .vgrid_done
    mov word [circle_x1], 159
    mov word [circle_x2], 159
    mov ax, dx
    push dx
    call draw_hline_packed
    pop dx
    inc dx
    jmp .vline_final
.vgrid_done:

    ; --- Draw 8 color boxes (bright CGA colors 8-15) ---
    ; Each box: 10 pixels wide, 40 pixels tall
    ; Total width: 80 pixels, centered at X=80 → X = 40 to 119
    ; Centered at Y=100 → Y = 80 to 119

    mov cl, 8               ; Start with color 8 (Dark Gray)
    mov bx, 40              ; Start X position

.colorbox_loop:
    cmp cl, 16
    jae .colorbox_done

    mov [circle_color], cl

    ; Draw box from Y=80 to Y=119 (40 rows)
    mov dx, 80              ; Start Y
.colorbox_row:
    cmp dx, 120
    jae .colorbox_next

    mov [circle_x1], bx
    mov ax, bx
    add ax, 9               ; 10 pixels wide (0-9)
    mov [circle_x2], ax
    mov ax, dx
    push bx
    push cx
    push dx
    call draw_hline_packed
    pop dx
    pop cx
    pop bx
    inc dx
    jmp .colorbox_row

.colorbox_next:
    add bx, 10              ; Next box
    inc cl                  ; Next color
    jmp .colorbox_loop
.colorbox_done:

    ; --- Draw dither gradient (black to white) ---
    ; Width = 80 pixels (X = 40 to 119), Height = 21 pixels
    ; Position: Y = 120 to 140 (directly below color boxes)
    ; 8 bands × 10 pixels = 80 pixels (solid grey levels 0-7)

    mov cl, 0               ; Start with grey 0 (black)
    mov bx, 40              ; Start X position

.gradbox_loop:
    cmp cl, 8
    jae .grad_done

    mov [circle_color], cl

    ; Draw box from Y=120 to Y=140 (21 rows)
    mov dx, 120             ; Start Y
.gradbox_row:
    cmp dx, 141
    jae .gradbox_next

    mov [circle_x1], bx
    mov ax, bx
    add ax, 9               ; 10 pixels wide (0-9)
    mov [circle_x2], ax
    mov ax, dx
    push bx
    push cx
    push dx
    call draw_hline_packed
    pop dx
    pop cx
    pop bx
    inc dx
    jmp .gradbox_row

.gradbox_next:
    add bx, 10              ; Next box
    inc cl                  ; Next grey level
    jmp .gradbox_loop

.grad_done:
    pop es
    pop si
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ============================================================================
; draw_circle - Draw a filled circle with RANDOM color
; Center: (80, 100), Radius: 80 pixels vertically
; Uses pre-calculated lookup table with aspect ratio correction (1.667:1)
; for 160x200 resolution on 4:3 display
; ============================================================================
draw_circle:
    ; Pick random color for circle (1-15, not 0 which is black)
    call random_byte
    and al, 0x0F
    jnz .color_ok
    inc al                  ; Avoid color 0 (black)
.color_ok:
    mov [circle_color], al
    ; Fall through to draw_circle_color

; ============================================================================
; draw_circle_color - Draw a filled circle with color in [circle_color]
; Center: (80, 100), Radius: 80 pixels vertically
; Set [circle_color] before calling this routine
; ============================================================================
draw_circle_color:
    push ax
    push bx
    push cx
    push dx
    push di
    push si
    push es

    mov ax, VIDEO_SEG
    mov es, ax

    ; Draw circle using lookup table
    ; Table has 81 entries for dy = 0 to 80
    ; We draw from Y=20 to Y=180 (center at 100)

    mov si, circle_lut      ; SI points to lookup table
    mov cx, 81              ; 81 scanlines (dy = 0 to 80)
    mov bx, 0               ; BX = dy offset (0 to 80)

.draw_loop:
    ; Get dx from lookup table
    mov al, [si]
    xor ah, ah              ; AX = dx (horizontal extent)

    ; Calculate X1 = 80 - dx (clamp to 0)
    mov dx, 80
    sub dx, ax
    cmp dx, 0
    jge .x1_ok
    xor dx, dx
.x1_ok:
    mov [circle_x1], dx

    ; Calculate X2 = 80 + dx (clamp to 159)
    mov dx, 80
    add dx, ax
    cmp dx, 159
    jle .x2_ok
    mov dx, 159
.x2_ok:
    mov [circle_x2], dx

    ; Draw top half: Y = 100 - dy
    mov ax, 100
    sub ax, bx              ; AX = 100 - dy
    cmp ax, 0
    jl .skip_top
    call draw_hline_packed
.skip_top:

    ; Draw bottom half: Y = 100 + dy (skip dy=0 to avoid double draw)
    cmp bx, 0
    je .next_line
    mov ax, 100
    add ax, bx              ; AX = 100 + dy
    cmp ax, 199
    jg .next_line
    call draw_hline_packed

.next_line:
    inc si                  ; Next lookup table entry
    inc bx                  ; Next dy
    loop .draw_loop

.done:
    pop es
    pop si
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ============================================================================
; Circle lookup table - Pre-calculated dx values for radius 80 circle
; Aspect ratio corrected for 160x200 on 4:3 display (factor ~0.833)
; Index = dy (0 to 80), Value = dx (horizontal half-width)
; Formula: dx = sqrt(80² - dy²) * 0.833
; ============================================================================
circle_lut:
    db 67, 67, 67, 67, 67   ; dy = 0-4
    db 66, 66, 66, 66, 66   ; dy = 5-9
    db 66, 66, 65, 65, 65   ; dy = 10-14
    db 65, 64, 64, 64, 63   ; dy = 15-19
    db 63, 62, 62, 61, 61   ; dy = 20-24
    db 60, 60, 59, 58, 58   ; dy = 25-29
    db 57, 56, 55, 55, 54   ; dy = 30-34
    db 53, 52, 51, 50, 49   ; dy = 35-39
    db 48, 47, 46, 45, 44   ; dy = 40-44
    db 43, 41, 40, 39, 37   ; dy = 45-49
    db 36, 34, 33, 31, 29   ; dy = 50-54
    db 28, 26, 24, 22, 20   ; dy = 55-59
    db 18, 16, 14, 12, 10   ; dy = 60-64
    db  8,  7,  6,  5,  5   ; dy = 65-69
    db  4,  4,  3,  3,  2   ; dy = 70-74
    db  2,  1,  1,  1,  0   ; dy = 75-79
    db  0                   ; dy = 80

; ============================================================================
; draw_hline_packed - Draw horizontal line using packed nibbles
; Input: AX = Y, [circle_x1] = start X, [circle_x2] = end X
; Format: 2 pixels per byte, even/odd banks
; ============================================================================
draw_hline_packed:
    push ax
    push bx
    push cx
    push dx
    push di
    push si
    push es

    ; Set ES to video segment
    mov bx, VIDEO_SEG
    mov es, bx

    mov si, ax              ; SI = Y

    ; Clamp X (0-159)
    mov bx, [circle_x1]
    cmp bx, 0
    jge .x1ok
    xor bx, bx
.x1ok:
    cmp bx, 159
    jle .x1ok2
    mov bx, 159
.x1ok2:
    mov [circle_x1], bx

    mov bx, [circle_x2]
    cmp bx, 0
    jge .x2ok
    xor bx, bx
.x2ok:
    cmp bx, 159
    jle .x2ok2
    mov bx, 159
.x2ok2:
    mov [circle_x2], bx

    ; Calculate bank and offset
    mov ax, si
    test ax, 1
    jz .even

    ; Odd: offset = 0x2000 + (Y/2)*80
    shr ax, 1
    mov bx, 80
    mul bx
    add ax, 0x2000
    jmp .gotbase

.even:
    ; Even: offset = (Y/2)*80
    shr ax, 1
    mov bx, 80
    mul bx

.gotbase:
    mov di, ax              ; DI = row base

    ; Draw pixels X1 to X2
    mov cx, [circle_x1]

.ploop:
    cmp cx, [circle_x2]
    ja .done

    ; Byte offset = X/2
    mov ax, cx
    shr ax, 1
    push di
    add di, ax

    ; Read byte
    mov bl, [es:di]

    ; Check even/odd pixel
    test cl, 1
    jnz .oddpix

    ; Even pixel (high nibble)
    and bl, 0x0F
    mov al, [circle_color]
    shl al, 4
    or bl, al
    jmp .write

.oddpix:
    ; Odd pixel (low nibble)
    and bl, 0xF0
    or bl, [circle_color]

.write:
    mov [es:di], bl
    pop di
    inc cx
    jmp .ploop

.done:
    pop es
    pop si
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ============================================================================
; generate_random_palette - Generate 16 TRUE RANDOM colors
; Each color is encoded as 2 bytes for the 6355 chip palette format
; Hardware supports 512 colors (3 bits per channel = 8 levels each)
; Format: Byte 1 = Red (bits 0-2), Byte 2 = Green (bits 4-6) | Blue (bits 0-2)
; FIXED: Color 0 is always BLACK (for border), colors 1-15 are random
; ============================================================================
generate_random_palette:
    push ax
    push bx
    push cx
    push di

    mov di, palette

    ; Color 0 = BLACK (for border)
    mov byte [di], 0x00     ; Red = 0
    inc di
    mov byte [di], 0x00     ; Green = 0, Blue = 0
    inc di

    ; Randomize colors 1-15
    mov cx, 15

.gen_loop:
    ; Generate random Red (0-7, stored in bits 0-2)
    call random_byte
    and al, 0x07            ; 3 bits = 0-7
    mov [di], al            ; Store Red byte
    inc di

    ; Generate random Green (0-7) and Blue (0-7)
    call random_byte
    mov bl, al
    and bl, 0x07            ; Blue in bits 0-2

    call random_byte
    and al, 0x07            ; Green 0-7
    shl al, 4               ; Shift to bits 4-6
    or al, bl               ; Combine: Green (high nibble) | Blue (low nibble)
    mov [di], al            ; Store GB byte
    inc di

    loop .gen_loop

    pop di
    pop cx
    pop bx
    pop ax
    ret

; ============================================================================
; draw_gradient - Show 16 dithered shades of a single color
; Uses 8 palette entries with dithering to simulate 16 shades
; Press D repeatedly to cycle: Red → Green → Blue → Gray → Red...
;
; Shades 0,2,4,6,8,10,12,14 = solid colors (palette 0-7)
; Shades 1,3,5,7,9,11,13,15 = dithered between adjacent palette colors
; ============================================================================
draw_gradient:
    push ax
    push bx
    push cx
    push dx
    push di
    push si
    push es

    ; Set up palette based on current mode
    call setup_gradient_palette
    call set_palette

    ; Clear and draw 16 bands with dithering
    call clear_screen

    mov ax, VIDEO_SEG
    mov es, ax

    ; Each band is 12 rows tall (16 * 12 = 192 rows, 8 rows black at bottom)
    xor si, si              ; SI = row counter (0-199)

.row_loop:
    ; Calculate base offset for this row
    mov ax, si
    shr ax, 1               ; AX = row / 2
    mov bx, 80
    mul bx                  ; AX = (row/2) * 80
    mov di, ax
    test si, 1
    jz .even_row
    add di, 0x2000
.even_row:

    ; Calculate shade = row / 12 (gives 0-15)
    mov ax, si
    mov bl, 12
    div bl                  ; AL = shade (0-15)
    cmp al, 15
    jbe .shade_ok
    mov al, 15
.shade_ok:
    mov bl, al              ; BL = shade (0-15)

    ; Determine if solid or dithered
    ; Even shades (0,2,4,...) = solid palette color (shade/2)
    ; Odd shades (1,3,5,...) = dither between (shade/2) and (shade/2 + 1)
    test bl, 1
    jnz .dithered_row

    ; Solid row: color = shade / 2
    mov al, bl
    shr al, 1               ; AL = palette index (0-7)
    mov ah, al
    shl ah, 4
    or al, ah               ; AL = packed solid color

    ; Fill row with solid color
    mov cx, 80
    cld
    rep stosb
    jmp .next_row

.dithered_row:
    ; Dithered row: alternate between color1 and color2
    ; color1 = shade / 2, color2 = shade / 2 + 1 (clamped to 7)
    mov al, bl
    shr al, 1               ; AL = color1 (0-7)
    mov cl, al              ; CL = color1
    inc al
    cmp al, 7
    jbe .col2_ok
    mov al, 7
.col2_ok:
    mov ch, al              ; CH = color2

    ; 1-pixel checkerboard dithering:
    ; Pattern A: (color1 << 4) | color2 = pixel0=c1, pixel1=c2
    ; Pattern B: (color2 << 4) | color1 = pixel0=c2, pixel1=c1
    ; Use same pattern for entire row, swap on alternate rows
    mov al, cl
    shl al, 4
    or al, ch               ; AL = pattern A
    mov bl, al              ; BL = pattern A

    ; Choose pattern based on row number for vertical dithering
    test si, 1
    jz .use_pattern_a
    ; Odd row: use pattern B (swapped nibbles)
    mov al, ch
    shl al, 4
    or al, cl               ; AL = pattern B
    mov bl, al
.use_pattern_a:

    ; Fill entire row with same pattern (creates 1-pixel checkerboard)
    mov al, bl
    mov cx, 80
    cld
    rep stosb

.next_row:
    inc si
    cmp si, 192             ; Only fill 192 rows (16 bands × 12)
    jb .row_loop

    ; Cycle to next mode for next D press: 0=Red, 1=Green, 2=Blue, 3=Gray
    inc byte [gradient_mode]
    cmp byte [gradient_mode], 4
    jb .mode_ok
    mov byte [gradient_mode], 0  ; Wrap back to red
.mode_ok:

    pop es
    pop si
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ============================================================================
; setup_test_palette - Set palette for test pattern
; Colors 0-7: 8 true grey levels (R=G=B, from 0 to 7)
; Colors 8-15: CGA bright colors (for color boxes)
; ============================================================================
setup_test_palette:
    push ax
    push bx
    push cx
    push di

    mov di, palette

    ; Colors 0-7: Grey levels (R=G=B from 0 to 7)
    xor bx, bx              ; BX = intensity 0-7
.grey_loop:
    mov [di], bl            ; R = intensity
    inc di
    mov al, bl
    shl al, 4               ; G in bits 4-6
    or al, bl               ; B in bits 0-2
    mov [di], al            ; G=B=intensity
    inc di
    inc bx
    cmp bx, 8
    jb .grey_loop

    ; Colors 8-15: Copy CGA bright colors (from cga_colors offset 16)
    mov si, cga_colors + 16 ; Start at color 8 in CGA palette
    mov cx, 16              ; 8 colors × 2 bytes
.bright_loop:
    mov al, [si]
    mov [di], al
    inc si
    inc di
    loop .bright_loop

    pop di
    pop cx
    pop bx
    pop ax
    ret

; ============================================================================
; setup_gradient_palette - Set palette for current gradient mode
; Mode 0: Red (R=0-7, G=0, B=0)
; Mode 1: Blue (R=0, G=0, B=0-7)
; Mode 2: Green (R=0, G=0-7, B=0)
; Mode 3: Gray (R=G=B=0-7)
; ============================================================================
setup_gradient_palette:
    push ax
    push bx
    push cx
    push di

    mov di, palette
    xor bx, bx              ; BX = intensity 0-7
    mov cl, [gradient_mode]

.pal_loop:
    ; Based on mode, set R and GB bytes
    cmp cl, 0
    je .mode_red
    cmp cl, 1
    je .mode_blue
    cmp cl, 2
    je .mode_green
    jmp .mode_gray

.mode_red:
    mov [di], bl            ; R = intensity
    inc di
    mov byte [di], 0        ; G=0, B=0
    inc di
    jmp .next_color

.mode_blue:
    mov byte [di], 0        ; R=0
    inc di
    mov [di], bl            ; G=0, B=intensity
    inc di
    jmp .next_color

.mode_green:
    mov byte [di], 0        ; R=0
    inc di
    mov al, bl
    shl al, 4               ; G in bits 4-6
    mov [di], al            ; G=intensity, B=0
    inc di
    jmp .next_color

.mode_gray:
    mov [di], bl            ; R = intensity
    inc di
    mov al, bl
    shl al, 4               ; G in bits 4-6
    or al, bl               ; B in bits 0-2
    mov [di], al            ; G=B=intensity
    inc di

.next_color:
    inc bx
    cmp bx, 8
    jb .pal_loop

    ; Fill remaining palette entries (8-15) with black
    mov cx, 16              ; 8 colors × 2 bytes
    xor al, al
.fill_rest:
    mov [di], al
    inc di
    loop .fill_rest

    pop di
    pop cx
    pop bx
    pop ax
    ret

; ============================================================================
; reset_screen - Reset to startup state (CGA palette, black border, 16 bars)
; ============================================================================
reset_screen:
    call clear_screen
    call set_cga_palette
    call set_palette
    mov byte [bar_width], 10
    mov byte [border_color], 0
    xor al, al
    V6355_OUT PORT_COLOR    ; Reset border to black
    call draw_color_bars
    ret

; ============================================================================
; set_cga_palette - Set palette to standard CGA text mode colors
; Copies the 16 CGA colors to the palette buffer
; ============================================================================
set_cga_palette:
    push cx
    push si
    push di

    mov si, cga_colors
    mov di, palette
    mov cx, 32              ; 16 colors × 2 bytes
    cld
    rep movsb

    pop di
    pop si
    pop cx
    ret

; ============================================================================
; Standard CGA text mode palette (16 colors)
; Format: Byte 1 = Red (bits 0-2), Byte 2 = Green (bits 4-6) | Blue (bits 0-2)
; ============================================================================
cga_colors:
    db 0x00, 0x00    ; 0:  Black
    db 0x00, 0x05    ; 1:  Blue
    db 0x00, 0x50    ; 2:  Green
    db 0x00, 0x55    ; 3:  Cyan
    db 0x05, 0x00    ; 4:  Red
    db 0x05, 0x05    ; 5:  Magenta
    db 0x05, 0x20    ; 6:  Brown (dark yellow-orange)
    db 0x05, 0x55    ; 7:  Light Gray
    db 0x02, 0x22    ; 8:  Dark Gray
    db 0x02, 0x27    ; 9:  Light Blue
    db 0x02, 0x72    ; 10: Light Green
    db 0x02, 0x77    ; 11: Light Cyan
    db 0x07, 0x22    ; 12: Light Red
    db 0x07, 0x27    ; 13: Light Magenta
    db 0x07, 0x70    ; 14: Yellow
    db 0x07, 0x77    ; 15: White

; ============================================================================
; init_random - Initialize random number generator from timer
; ============================================================================
init_random:
    push ax
    push dx

    ; Read timer tick count
    xor ax, ax
    int 0x1A                    ; Get timer ticks in CX:DX

    ; Use DX as initial seed
    mov [rand_seed], dx

    pop dx
    pop ax
    ret

; ============================================================================
; random_byte - Generate a pseudo-random byte
; Output: AL = random byte
; Uses linear congruential generator: seed = seed * 25173 + 13849
; ============================================================================
random_byte:
    push bx
    push dx

    mov ax, [rand_seed]
    mov bx, 25173
    mul bx
    add ax, 13849
    mov [rand_seed], ax

    ; Use high byte for better randomness
    mov al, ah

    pop dx
    pop bx
    ret

; ============================================================================
; wait_key - Wait for a key press
; Output: AL = ASCII code of key pressed
; ============================================================================
wait_key:
    mov ah, 0x00
    int 0x16                    ; BIOS keyboard read
    ret

; ============================================================================
; check_help_arg - Check if /? or /h was passed on command line
; Output: CF set if help requested, CF clear otherwise
; ============================================================================
check_help_arg:
    push si

    ; PSP command line: byte at 0x80 = length, 0x81+ = command tail
    mov si, 0x81

.skip_spaces:
    lodsb
    cmp al, ' '
    je .skip_spaces
    cmp al, 0x0D                ; End of command line
    je .no_help

    ; Check for / or -
    cmp al, '/'
    je .check_char
    cmp al, '-'
    je .check_char
    jmp .no_help

.check_char:
    lodsb
    ; Check for ? or h or H
    cmp al, '?'
    je .help_found
    cmp al, 'h'
    je .help_found
    cmp al, 'H'
    je .help_found

.no_help:
    clc                         ; Clear carry = no help
    pop si
    ret

.help_found:
    stc                         ; Set carry = help requested
    pop si
    ret

; ============================================================================
; print_help - Print help screen to console
; ============================================================================
print_help:
    push ax
    push dx

    mov dx, help_text
    mov ah, 0x09                ; DOS print string
    int 0x21

    pop dx
    pop ax
    ret

; ============================================================================
; Data Section
; ============================================================================

; Help text ($ terminated for DOS function 09h)
help_text:
    db 'COLORBARS.COM - Hidden graphics mode demo for Olivetti Prodest PC1', 13, 10
    db 'Hidden 160x200x16 Graphics Mode', 13, 10
    db 'Written for NASM - NEC V40 (80186 compatible)', 13, 10
    db 'By Retro Erik - 2026', 13, 10
    db 13, 10
    db 'Controls:', 13, 10
    db '  SPACE - Cycle palette colors (random from 512-color palette)', 13, 10
    db '  W     - Reset to startup screen (CGA palette, 16 bars)', 13, 10
    db '  A     - Cycle border color (0-15)', 13, 10
    db '  Q     - Draw random colored circle(ish)', 13, 10
    db '  D     - Gradient dither demo (cycles Red->Green->Blue->Gray)', 13, 10
    db '  T     - Draw test pattern (10x10 grid, 8 color boxes, gradient)', 13, 10
    db '  0     - Set bar width to 10 pixels (fills entire screen width)', 13, 10
    db '  1-9   - Set bar width to 1-9 pixels (16 bars from left edge)', 13, 10
    db '  ESC   - Exit to DOS in text mode', 13, 10
    db '$'

rand_seed:      dw 0            ; Random number seed
bar_width:      db 10           ; Bar width in pixels (1-10)
border_color:   db 0            ; Current border color (0-15)
gradient_mode:  db 0            ; Gradient color mode: 0=Red, 1=Green, 2=Blue, 3=Gray
orig_video_mode: db 0           ; Original video mode before program start
orig_text_attr: db 0x07         ; Original text attribute (default: light gray on black)

; Drawing variables (shared by circle and hline routines)
circle_color:   db 0            ; Current drawing color (0-15)
circle_x1:      dw 0            ; Line start X coordinate
circle_x2:      dw 0            ; Line end X coordinate

; Palette buffer - 32 bytes (16 colors × 2 bytes each)
; Will be filled with random values
palette:
    times 32 db 0

; ============================================================================
; End of program
; ============================================================================
