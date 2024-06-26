; This program implements a long division algorithm which is more efficient in many cases than division by repeated subtraction.
;   This implementation will use the long division algorithm described in https://en.wikipedia.org/w/index.php?title=Division_algorithm&section=3#Integer_division_(unsigned)_with_remainder

; This version of division supports 16 bit numerators.
;   Limitation: denominator must fit in 1 byte.

*=$0801
!byte $0c,$08,$b5,$07,$9e,$20,$32,$30,$36,$32,$00,$00,$00
jmp main

    ; Use zero page addressing when available since it's faster
    !set Q = $FB ; 2 bytes. On c64, $FB/$FC aren't used (little endian.
    !set N = $FD ; 2 bytes. On c64, $FD/$FE aren't used (little endian.)
    !set D = $02 ; On c64, $02 isn't used
    !set R = $26 ; On c64, $26 is part of the floating point working memory for BASIC. Safe to use.
    
    !set NB = 16 ; Number of bits in the numerator / dividend

main
    ; Clear the screen using a KERNAL (yes, with an "a") routine
    lda #$93
    jsr $ffd2

    ; Push our numerator.
    ; It's base 10 value is 20000 (0x204e in little endian)
    lda #$4e
    pha
    lda #$20
    pha

    ; Push our denominator
    ; It's base 10 value is 12 (0x0c)
    lda #$0c
    pha
    jmp div

div
    pla        ; Pull denominator from stack and store it in memory
    sta D

    pla        ; Pull numerator from stack and store it in memory (little endian)
    sta N
    pla
    sta N+1

    ldy #0     ; Y will index our number of iterations

    lda #0
    sta Q      ; Set quotient to 0
    sta Q+1
    sta R      ; Set remainder to 0

div_iter
    clc
    rol N      ; Rotate first bit of the numerator. Do the low byte first. It will affect carry bit which will let us easily roll the high byte.
    rol N+1
    rol        ; Put carry bit from previous rol as bit 0 in accumulator (see http://www.6502.org/users/obelisk/6502/reference.html#ROL)
    tax        ; Put accumulator in X reg to save its state since we will be subtracting
    sec        ; Set carry bit so we know if subtraction was successful without borrowing from it
    sbc D      ; Subtract denominator from value in accumulator. Roll result carry bit into quotient.
    php
    rol Q      ; Roll the quotient using the same methodology as the numerator at the beginning of this section
    rol Q+1
    plp
    bcs subtract_ok ; If the subtraction worked, don't restore our saved value in x. 
    txa
subtract_ok
    iny        ; Increment x and see if we need to rotate any more bits. If not, we're done.
    cpy #NB
    bne div_iter
done
    sta R      ; Store the remainder
    rts
