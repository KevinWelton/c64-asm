; This program implements a long division algorithm which is more efficient in many cases than division by repeated subtraction.
;   This implementation will use the long division algorithm described in.
; Limitation: Divisor / denominator must fit in 1 byte.

*=$0801
!byte $0c,$08,$b5,$07,$9e,$20,$32,$30,$36,$32,$00,$00,$00
jmp main

    ; Use zero page addressing when available since it's faster
    !set Q = $FB ; 2 bytes. On c64, $FB/$FC aren't used.
    !set N = $FD ; 2 bytes. On c64, $FD/$FE aren't used.
    !set D = $02 ; On c64, $02 isn't used
    ;!set R = $26 ; On c64, $26 is part of the floating point working memory for BASIC. Safe to use.
    !set NB = 16 ; Number of bits in the numerator / dividend
main
    ; Push our dividend / numerator.
    ; It's base 10 value is 20,000 (0x4e20)
    lda #$20
    pha
    lda #$4e
    pha
    ; Push or divisor / denominator
    ; It's base 10 value is 12 (0x0c)
    lda #$0c
    jmp div_start

div
    lda #0
    sta Q      ; Set quotient to 0
    sta Q+1
    pla        ; Pull divisor / denominator
    sta D
    pla        ; Pull dividend / numerator. Store big-endian in memory.
    sta N
    pla N+1
    ldy #0     ; Y will index our number of iterations


div_iter











store_digit
    txa
    sta OUTPUT_BASE, y ; Write the remainder into the first memory slot
    iny
    lda Q
    beq print         ; Was Q == 0? We're done. Go to printing our result.
    jmp div

    ; Print the results of our division
print
    ldx 0              ; Use x to index screen memory

printchar
    dey                ; We predecrement since we incremented after writing the value
    lda OUTPUT_BASE, y ; Load the most significant digit (values were written in reverse order)
    adc #"0"           ; Make sure we are printing a character, not a number
    sta $3D1, x        ; Write the value to screen memory
    lda #1             ; Make the text color white
    sta $d7D1, x
    tya                ; Transfer y to a so we get the zero bit set if we're done
    beq done           ; If y was 0 this iteration, we're done.
    inx
    jmp printchar

done
    rts
