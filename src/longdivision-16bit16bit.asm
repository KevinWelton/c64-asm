; This program implements a long division algorithm which is more efficient in many cases than division by repeated subtraction.
;   This implementation will use the long division algorithm described in https://en.wikipedia.org/w/index.php?title=Division_algorithm&section=3#Integer_division_(unsigned)_with_remainder

; This version of division supports 16 bit numerators *and* 16 bit denominators

*=$0801
!byte $0c,$08,$b5,$07,$9e,$20,$32,$30,$36,$32,$00,$00,$00
jmp main

    ; Use zero page addressing when available since it's faster
    ;   All values will be store LITTLE ENDIAN.
    !set NQ = $FB ; 2 bytes. On c64, $FB/$FC aren't used (little endian.)
    !set D = $26 ; 2 bytes. On c64, $26/$27 are part of the floating point working memory for BASIC. Safe to use.
    !set R = $28 ; 2 bytes. On c64, $28/$29 are part of the floating point working memory for BASIC. Safe to use.
    
    !set NB = 16 ; Number of bits in the numerator / dividend

main
    ; Push our numerator.
    ; It's base 10 value is 20000 (0x204e in little endian)
    lda #$4e
    pha
    lda #$20
    pha

    ; Push our denominator
    ; It's base 10 value is 15000 (0x983a in little endian)
    lda #$3a
    pha
    lda #$98
    pha
    jmp div

div
    pla        ; Pull denominator from stack and store it in memory (little endian)
    sta D
    pla
    sta D+1

    pla        ; Pull numerator from stack and store it in memory (little endian)
    sta NQ
    pla
    sta NQ+1

    lda #0     ; Set remainder to 0
    sta R
    sta R+1

div_iter
    asl NQ     ; Rotate first bit of the numerator. Do the low byte first. It will affect carry bit which will let us easily roll the high byte.
    rol NQ+1
    rol R      ; Put carry bit from previous rol as bit 0 (see http://www.6502.org/users/obelisk/6502/reference.html#ROL)
    rol R+1
    lda R      ; Subtract low byte after setting carry bit
    sec
    sbc D
    tax        ; Save result of low byte in case subtraction succeeds for high byte
    lda R + 1  ; Subtract high byte
    sbc D + 1
    bcc div_continue ; Branch if substract failed
    stx R      ; Subtract succeeded. Store result and change low order bit in NQ to 1 instead of 0.
    sta R+1
    inc NQ

div_continue
    iny        ; Increment y and see if we need to rotate any more bits. If not, we're done.
    cpy #NB
    bne div_iter

done
    rts
