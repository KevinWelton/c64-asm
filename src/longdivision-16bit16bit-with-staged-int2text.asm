; This program implements a long division algorithm which is more efficient in many cases than division by repeated subtraction.
;   This implementation will use the long division algorithm described in https://en.wikipedia.org/w/index.php?title=Division_algorithm&section=3#Integer_division_(unsigned)_with_remainder

; This version of division supports 16 bit numerators *and* 16 bit denominators

*=$0801

!byte $0c,$08,$b5,$07,$9e,$20,$32,$30,$36,$32,$00,$00,$00

; Use zero page addressing when available since it's faster
!set QUOTIENT = $61      ; 2 bytes. On c64, $61/$62 are used for BASIC floating point
!set NUMERATOR = $FB     ; 2 bytes. On c64, $FB/$FC aren't used
!set DIVISOR = $26       ; 2 bytes. On c64, $26/$27 are part of the floating point working memory for BASIC. Safe to use.
!set REMAINDER = $28     ; 2 bytes. On c64, $28/$29 are part of the floating point working memory for BASIC. Safe to use.
!set PHASE = $FD         ; On c64, $FD isn't used
!set OUTPUT_BASE = $9000 ; Our output buffer for the final print operation
!set BITWIDTH = 16       ; Number of bits in the numerator / dividend

main
    ;;;;;;;;;
    ; Perform initial (phase 0) division for calculation

    ; Push our numerator.
    ; SCENARIO 1: It's base 10 value is 20000 (0x204e in little endian)
    ; SCENARIO 2: It's base 10 value is 21232 (0xf052 in little endian)
    ; SCENARIO 3: It's base 10 value is 15676 (0x3c3d in little endian)
    lda #$f0
    sta NUMERATOR
    lda #$52
    sta NUMERATOR+1

    ; Push our denominator.
    ; SCENARIO 1: It's base 10 value is 15000 (0x983a in little endian)
    ; SCENARIO 2: It's base 10 value is 12 (0x0C00 in little endian)
    ; SCENARIO 3: It's base 10 value is 15678 (0x3e3d in little endian)
    lda #$0c
    sta DIVISOR
    lda #$00
    sta DIVISOR+1
    lda #255
    sta PHASE        ; Phase -1. No saving remainder data as characters because it is our main division pass.
    jsr div

    ;;;;;;;;;
    ; Perform int2text (phase 1) division to store base10 values
    lda QUOTIENT     ; Quotient from phase 0 becomes our new starting numerator
    sta NUMERATOR
    lda QUOTIENT+1
    sta NUMERATOR+1
    lda #10          ; We want base 10, so 10 is our new divisor
    sta DIVISOR
    lda #0
    sta DIVISOR+1
    lda #0
    sta PHASE        ; PHASE becomes our text buffer index
    jsr div

    ;;;;;;;;;
    ; Actually print the text, then we're done.
    jsr print
    rts

div
    ldy #0             ; Y register tracks how many bits we've processed in the current operation
    lda #0             ; Start by setting our remainder and quotient to 0
    sta REMAINDER
    sta REMAINDER+1
    sta QUOTIENT
    sta QUOTIENT+1
div_iter
    asl QUOTIENT       ; Rotate the quotient. Do the low byte first so the rol gets the cary bit.
    rol QUOTIENT+1
    asl NUMERATOR      ; Rotate first bit of the numerator. Do the low byte first. It will affect carry bit which will let us easily roll the high byte.
    rol NUMERATOR+1
    rol REMAINDER      ; Put carry bit from previous rol as bit 0 (see http://www.6502.org/users/obelisk/6502/reference.html#ROL)
    rol REMAINDER+1
    sec                ; Subtract low byte after setting carry bit
    lda REMAINDER
    sbc DIVISOR
    tax                ; Save result of low byte in case subtraction succeeds for high byte
    lda REMAINDER + 1  ; Subtract high byte
    sbc DIVISOR + 1
    bcc div_continue   ; Branch if substract failed
    stx REMAINDER      ; Subtract succeeded. Store result and change low order bit in NQ to 1 instead of 0.
    sta REMAINDER+1
    inc QUOTIENT
div_continue
    iny                ; Increment y and see if we need to rotate any more bits. If not, we're done.
    cpy #BITWIDTH
    bne div_iter
    lda PHASE
    cmp #-1
    beq div_finish
    lda REMAINDER      ; Put the low byte of R into accumulator. We are dividing by 10 if we get here so we don't need the high byte.
    ldx PHASE          ; Load our text buffer index
    sta OUTPUT_BASE, X            
    inc PHASE          ; Increment index for next time
    ; We have to do division again as long as the quotient is not 0 when doing int2text print portion
    lda QUOTIENT
    bne prep_next_int2txt_digit
    lda QUOTIENT + 1
    bne prep_next_int2txt_digit
div_finish
    rts

prep_next_int2txt_digit
    lda QUOTIENT
    sta NUMERATOR
    lda QUOTIENT+1
    sta NUMERATOR+1
    jmp div

print
    ; Our printable data should now be in OUTPUT_BASE with PHASE as the number of chars
    ldx PHASE
    ldy #0
print_char
    cpx #0
    beq print_finish
print_char_continue
    dex
    lda OUTPUT_BASE, x
    clc                 ; Clear carry so we don't get anything accidently added to our char values
    adc #"0"            ; Convert the int value to the char value
    sta $400, y
    lda #1              ; white text
    sta $d800, y
    iny
    jmp print_char
print_finish
    rts
