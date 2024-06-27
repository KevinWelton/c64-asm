; This program implements a long division algorithm which is more efficient in many cases than division by repeated subtraction.
;   This implementation will use the long division algorithm described in https://en.wikipedia.org/w/index.php?title=Division_algorithm&section=3#Integer_division_(unsigned)_with_remainder

; This version of division supports 16 bit numerators *and* 16 bit denominators

*=$0801
!byte $0c,$08,$b5,$07,$9e,$20,$32,$30,$36,$32,$00,$00,$00
jmp main

    ; Use zero page addressing when available since it's faster
    ;   All values will be store LITTLE ENDIAN.
    !set NQ = $FB ; 2 bytes. On c64, $FB/$FC aren't used
    !set D = $26 ; 2 bytes. On c64, $26/$27 are part of the floating point working memory for BASIC. Safe to use.
    !set R = $28 ; 2 bytes. On c64, $28/$29 are part of the floating point working memory for BASIC. Safe to use.
    !set NQCPY = $FD ; 2 bytes. Stores a copy of the remainder. On c64, $FD/$FC aren't used.
    !set NB = 16 ; Number of bits in the numerator / dividend

    !set RADIX = 10 ; Convert to base10 when printing
    !set OUTPUT_BASE = $9000 ; Store our converted string here

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
    ; It's base 10 value is 15000 (0x983a in little endian)
    lda #$3a
    pha
    lda #$98
    pha

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
    sec        ; Subtract low byte after setting carry bit
    lda R
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

prepare_for_print
    lda NQ      ; We will reuse R for more division in int2text. So store the remainder of the actual division op so we can print it out later.
    sta NQCPY
    lda NQ+1
    sta NQCPY+1
    lda R       ; Load R into NQ since we will figure it's characters out first.
    sta NQ
    lda R+1
    sta NQ+1

    lda #0     ; Reuse D to store whether we have printed all parts of the result
    sta D

    ldx #0     ; X will index our character location in memory

int2text_newdigit
    ldy #0     ; Y will index our number of iterations
    lda #0     ; Set remainder to 0
    sta R

int2text_iter
    asl NQ      ; Rotate first bit of the numerator. Do the low byte first. It will affect carry bit which will let us easily roll the high byte.
    rol NQ+1
    rol R      ; Rotate the high-order bit into the remainder
    lda R
    sec        ; Set carry bit so we know if subtraction was successful without borrowing from it
    sbc #RADIX  ; Subtract denominator from value in accumulator. Roll result carry bit into quotient.
    bcc int2text_continue ; branch if subtract failed
    sta R
    inc NQ
int2text_continue
    iny        ; Increment y and see if we need to rotate any more bits. If not, we're done.
    cpy #NB
    bne int2text_iter

store_digit
    clc
    lda R
    adc #"0"
    sta OUTPUT_BASE, x    ; Write the remainder into the first memory slot
    inx
    lda NQ
    ora NQ+1
    beq store_quotient    ; Was Q == 0? We're done. Go to printing our result.
    jmp int2text_newdigit
store_quotient
    lda D                 ; Set D to 1 to show that we stored the quotient as well as the remainder so we don't do this again
    bne print
    inc D
    lda NQCPY
    sta NQ
    lda NQCPY+1
    sta NQ+1
    lda #1
    sta D
    lda #$12              ; Put "R" in buffer to specify that what follows it is the remainder
    sta OUTPUT_BASE, x
    inx
    jmp int2text_newdigit

    ; Print the results of our division
print
    ldy #0              ; Use Y to index screen memory
    clc                 ; Clear carry for the printing loop so we don't unintentionally get 1 added to any of our values

printchar
    dex                ; We predecrement since we incremented after writing the value
    lda OUTPUT_BASE, x ; Load the most significant digit (values were written in reverse order)
    sta $400, y        ; Write the value to screen memory (PAL)
    lda #1             ; Make the text color white
    sta $d800, y
    txa                ; Transfer X to A so we get the zero bit set if we're done
    beq done           ; If X was 0 this iteration, we're done.
    iny
    jmp printchar

done
    rts
