; This is program converts a number from binary and prints it as text. It is pretty inefficient because it
;   does basic division by repeated subtraction (https://en.wikipedia.org/wiki/Division_algorithm).
; The final step will print "231" to the top left of the screen.

*=$0801
!byte $0c,$08,$b5,$07,$9e,$20,$32,$30,$36,$32,$00,$00,$00
jmp main

    !set Q = $FB ; Use zero page addressing for quotient. On c64, $FB isn't used.
    !set OUTPUT_BASE = $9002

    ; Remainder will be calculated in the accumulator
    !set D = 10  ; Denominator / divisor. This should be in the base you want to convert to. If it is >10 like hex, you will need to do a bit of extra work.
    !set N = 231 ; Numerator / dividend

main
    ldy #0     ; Y will track our index for the output register
    lda #N

div
    ldx #0            ; Set (or reset) quotient to 0
    stx Q
    sec

div_iter
    tax               ; Move accumulator to x register in case we finish and need the remainder
    sbc #D            ; Subtract denominator from numerator
    bcc store_digit   ; Is the carry flag no longer set? We couldn't subtract. We need to store the remainder.
    inc Q             ; Increment the quotient
    jmp div_iter      ; Keep going since the carry bit wasn't unset.

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
