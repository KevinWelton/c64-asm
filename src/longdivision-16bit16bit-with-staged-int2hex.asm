; This program implements a long division algorithm which is more efficient in many cases than division by repeated subtraction.
;   This implementation will use the long division algorithm described in https://en.wikipedia.org/w/index.php?title=Division_algorithm&section=3#Integer_division_(unsigned)_with_remainder

; This version of division supports 16 bit numerators *and* 16 bit denominators

*=$0801
!byte $0c,$08,$b5,$07,$9e,$20,$32,$30,$36,$32,$00,$00,$00
jmp main

    ; Use zero page addressing when available since it's faster
    ;   All values will be store LITTLE ENDIAN.
    !set QUOTIENT = $61 ; 2 byte. On c64, $61/$62 are used for BASIC floating point (little endian.)
    !set NUMERATOR = $FB ; 2 bytes. On c64, $FB/$FC aren't used (little endian.)
    !set DIVISOR = $26 ; 2 bytes. On c64, $26/$27 are part of the floating point working memory for BASIC. Safe to use.
    !set REMAINDER = $28 ; 2 bytes. On c64, $28/$29 are part of the floating point working memory for BASIC. Safe to use.
    
    !set BITWIDTH = 16 ; Number of bits in the numerator / dividend

    !set PHASE = $FD ; On c64, $FD isn't used

    !set OUTPUT_BASE = $9000

main
    ; CHECK: Not sure I need this. Init our output to a default of 0
    lda #0
    sta OUTPUT_BASE

    ; Push our numerator.
    ;; It's base 10 value is 20000 (0x204e in little endian)
    ; It's base 10 value is 21232 (0xf052 in little endian)
    lda #$f0
    sta NUMERATOR
    lda #$52
    sta NUMERATOR+1

    ; Perform initial (phase 0) division for calculation
    ;; Push our denominator. It's base 10 value is 15000 (0x983a in little endian)
    ; Push our denominator. It's base 10 value is 12 (0x0C00 in little endian)
    lda #$0c
    sta DIVISOR
    lda #$00
    sta DIVISOR+1
    lda #255
    sta PHASE ; Phase -1. No saving remainder data as characters because it is our main division pass.
    jsr div

    ; Perform int2text (phase 1) division to store base10 values
    lda QUOTIENT
    sta NUMERATOR
    lda QUOTIENT+1
    sta NUMERATOR+1
    lda #10
    sta DIVISOR
    lda #0
    sta DIVISOR+1
    lda #0
    sta PHASE ; PHASE is now where we store our index
    jsr div

    jmp print

div
    ldy #0
    lda #0     ; Set remainder to 0
    sta REMAINDER
    sta REMAINDER+1
    sta QUOTIENT
    sta QUOTIENT+1

div_iter
    asl QUOTIENT      ; Rotate the quotient. Do the low byte first so the rol gets the cary bit.
    rol QUOTIENT+1
    asl NUMERATOR     ; Rotate first bit of the numerator. Do the low byte first. It will affect carry bit which will let us easily roll the high byte.
    rol NUMERATOR+1
    rol REMAINDER      ; Put carry bit from previous rol as bit 0 (see http://www.6502.org/users/obelisk/6502/reference.html#ROL)
    rol REMAINDER+1
    sec        ; Subtract low byte after setting carry bit
    lda REMAINDER
    sbc DIVISOR
    tax        ; Save result of low byte in case subtraction succeeds for high byte
    lda REMAINDER + 1  ; Subtract high byte
    sbc DIVISOR + 1
    bcc div_continue ; Branch if substract failed
    stx REMAINDER      ; Subtract succeeded. Store result and change low order bit in NQ to 1 instead of 0.
    sta REMAINDER+1
    inc QUOTIENT

div_continue
    iny        ; Increment y and see if we need to rotate any more bits. If not, we're done.
    cpy #BITWIDTH
    bne div_iter
    lda PHASE
    cmp #-1
    beq div_finish
    lda REMAINDER      ; Put the low byte of R into accumulator. We are dividing by 10 so we don't need the high byte.
    ldx PHASE  ; CHECK: I think I'm OK to use X here.
    sta OUTPUT_BASE, X
    inx        ; Increment index for next time
    stx PHASE
    ; Is NUMERATOR 0? If not, do division again.
    lda QUOTIENT
    bne prep_next_int2txt_digit
    lda QUOTIENT + 1
    bne prep_next_int2txt_digit
    jmp div_finish

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
    ldx PHASE ; CHECK: Will this ever be 0? I hope not. It shouldn't be if I read it right.
    ldy #0

print_char
    cpx #0
    beq done
    dex
    lda OUTPUT_BASE, x
    clc ; Clear carry so we don't get anything accidently added to our char values
    adc #"0"
    sta $400, y
    lda #1 ; white text
    sta $d800, y
    iny
    jmp print_char

done
    rts
