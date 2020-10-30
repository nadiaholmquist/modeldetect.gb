include "hardware.inc"
include "charmap.inc"

MODEL_CGB EQU 0 ; set on both CGB and AGB
MODEL_SGB EQU 1
MODEL_SECOND EQU 2 ; set if "second" model: MGB, SGB2, AGB
MODEL_DMG_REV0 EQU 3 ; rare initial revision of DMG, boot ROM lacks ®
MODEL_CGB_MODE EQU 4

CGB_COMPATIBLE EQU $0143 ; CGB-compatible flag in ROM header

SECTION "RSTxx", ROM0 [$00]
	ds $40

SECTION "VBlank", ROM0 [$40]
	reti
SECTION "LCDC", ROM0 [$48]
	reti
SECTION "Timer",  ROM0 [$50]
	reti
SECTION "Serial", ROM0 [$58]
	reti
SECTION "Joypad", ROM0 [$60]
	reti
	ds $9E

section "Header", rom0[$100]
	nop
	jp start
	ds $4C

section "Start", rom0[$150]

start:
	ld [w_initial_sp], sp
	ld sp, $FFFE ; sp should already by $FFE, but let's set it just in case
	push hl
	push de
	push bc
	push af

	ld hl, w_model
	ld [hl], 0
	jr c, .dmg_mgb ; DMG and pocket (but not SGB) have carry set
	               ; DMG rev 0 does not, so handle that later
	jr z, .cgb ; GBC has zero flag set
	cp a, $11 ; GBA CGB mode has zero unset, same with SGB1/2, so compare A
	jr z, .agb
	bit 0, c ; SGB1/2 have bit 0 of c set, DMG rev0 doesn't
	jr nz, .dmg_rev0
	set MODEL_SGB, [hl]
	jr .dmg_mgb ; SGB1/2 are differentiated like DMG/MGB
.agb
	set MODEL_SECOND, [hl]
.cgb
	set MODEL_CGB, [hl]
	bit 0, d ; d is $FF in CGB mode, $00 in DMG mode
	jr nz, .done
	set MODEL_CGB_MODE, [hl]
	jr .done
.dmg_rev0
	set MODEL_DMG_REV0, [hl]
	jr .done
.dmg_mgb
	inc a ; zero set if pocket or SGB2
	jr nz, .done
	set MODEL_SECOND, [hl]
.done

	call disable_lcd

	ld a, $80
	ld [rBCPS], a
	ld a, $FF
rept 6
	ld [rBCPD], a
endr
	ld hl, CGB_COMPATIBLE
	xor a
	cp [hl]
	jr z, .incompatible

	xor a
	ld [rBCPD], a
	ld [rBCPD], a
	jr .colordone
	; put a red color on DMG, or CGB without CGB compat flag set
	; this will only be visible in emulators that do not properly
	; lock out access to the color palette memory
.incompatible
	ld a, $F7
	ld [rBCPD], a
	xor a
	ld [rBCPD], a
.colordone

	ld hl, _VRAM
	ld de, font
	ld c, 128
	call copy_1bpp
	call clear_screen0

	ld b, 0
	ld c, 30
	ld hl, _SCRN0
	ld de, reg_names
rept 5
rept 2 ; put two characters
	ld a, [de]
	inc de
	ld [hli], a
endr ; skip to next line
	add hl, bc
endr

	ld hl, _SCRN0 + 3
	pop bc
	call put_hex_word
	ld hl, _SCRN0 + 32 + 3
	pop bc
	call put_hex_word
	ld hl, _SCRN0 + 64 + 3
	pop bc
	call put_hex_word
	ld hl, _SCRN0 + 96 + 3
	pop bc
	call put_hex_word
	ld hl, _SCRN0 + 128 + 3
	ld a, [w_initial_sp + 1]
	ld b, a
	call put_hex
	ld a, [w_initial_sp]
	ld b, a
	call put_hex

	ld hl, _SCRN0 + 192
	ld de, model_str
	call put_text

	; lookup pointer to the string for the model name
	ld hl, model_table
	ld a, [w_model]
	res MODEL_CGB_MODE, a ; we don't care about this for model name
	rl a
	add l
	ld l, a
	ld a, [hli]
	ld e, a
	ld a, [hl]
	ld d, a
	ld hl, _SCRN0 + 192 + 32 + 2
	call put_text

	; if we are on CGB/AGB, display the mode we're running in
	ld a, [w_model]
	bit MODEL_CGB, a
	jr z, .cgb_mode_done

	ld hl, _SCRN0 + 256 + 2
	ld de, mode_str
	call put_text
	inc l
	ld a, [w_model]
	bit MODEL_CGB_MODE, a
	jr z, .cgb_mode
	ld de, no_str
	call put_text
	jr .cgb_mode_done
.cgb_mode
	ld de, yes_str
	call put_text
.cgb_mode_done

	call enable_lcd

.loop
	halt
	jr .loop

enable_lcd:
	ldh a, [rLCDC]
	set 7, a
	ldh [rLCDC], a
	ret

disable_lcd:
	ldh a, [rLY]
	cp 144
	jr nz, disable_lcd
	ldh a, [rLCDC]
	res 7, a
	ldh [rLCDC], a
	ret

; Copies 1bpp graphics from ROM
;
; de: Location of the graphics to copy
; hl: Destination
; c: Number of tiles
copy_1bpp:
rept 8
	ld a, [de]
	ld [hli], a
	ld [hli], a
	inc de
endr
	dec c
	jr nz, copy_1bpp
	ret

clear_screen0:
	ld hl, _SCRN0
.loop
	ld a, " "
	ld [hli], a
	ld a, h
	cp $9C
	jr nz, .loop
	ret

; print the content of b as hex
;
; b: The value to print
; hl: Location on screen
put_hex:
	ld de, hex_chars
	ld a, b
	swap a
	and a, $0F
	call .put_char ; print high nibble
	ld a, b
	and a, $0F
	call .put_char ; print low nibble
	ret
.put_char
	or a, low(hex_chars)
	ld e, a
	ld a, [de]
	ld [hli], a
	ret

; print word in bc as hex
;
; bc: word to print, big endian
; hl: Screen position
put_hex_word:
	call put_hex
	ld b, c
	call put_hex
	ret

; Place text terminated by $FF on the screen, 
;
; de: Location of the string
; hl: Screen position
put_text:
	ld a, [de]
	cp $FF
	ret z
	ld [hli], a
	inc de
	jr put_text
	
section "Strings", rom0, align[5]
hex_chars:
	db "0123456789ABCDEF"
reg_names:
	db "AFBCDEHLSP"
model_str:
	db "Model:", $FF
mode_str:
	db "CGB mode:", $FF
yes_str:
	db "Yes", $FF
no_str:
	db "No", $FF
model_dmg0:
	db "Game Boy (rev 0)", $FF
model_dmg:
	db "Game Boy", $FF
model_mgb:
	db "Game Boy Pocket", $FF
model_cgb:
	db "Game Boy Color", $FF
model_agb:
	db "Game Boy Advance", $FF
model_sgb1:
	db "Super Game Boy", $FF
model_sgb2:
	db "Super Game Boy 2", $FF

section "Data", rom0

model_table:
	dw model_dmg  ; 0000
	dw model_cgb  ; 0001
	dw model_sgb1 ; 0010
	dw $0000
	dw model_mgb  ; 0100
	dw model_agb  ; 0101
	dw model_sgb2 ; 0110
	dw $0000
	dw model_dmg0 ; 1000

font:
	incbin "font.1bpp"

section "WRAM", wram0
w_initial_sp:
	ds 2
w_model:
	ds 1
