; This is program converts a number from binary and prints it as text. It is pretty inefficient because it
;   does basic division by repeated subtraction (https://en.wikipedia.org/wiki/Division_algorithm).
; The final step will print "231" to the top left of the screen.

*=$0801
!byte $0c,$08,$b5,$07,$9e,$20,$32,$30,$36,$32,$00,$00,$00
jmp main

    ; Use zero page addressing when available since it's faster
    !set NQ = $FB ; 2 bytes. On c64, $FB/$FC aren't used (little endian.
    !set RADIX = $FD ; On c64, $FD isn't used
    !set R = $FE ; On c64, $FE isn't used. Must have the same size as RADIX (1 byte in this case)
    
    !set OUTPUT_BASE = $9000

    !set NB = 16 ; Number of bits in the numerator / dividend

main
    ; numerator for this test is 1729 (0x06c1, 0xc106 in little endian)
    lda #$06
    pha
    lda #$c1
    pha

    lda #10
    pha

int2text
    ldx #0     ; X will index our character location in memory

    pla        ; Pull denominator from stack and store it in memory
    sta RADIX

    pla        ; Pull numerator from stack and store it in memory (little endian)
    sta NQ
    pla
    sta NQ+1

int2text_newdigit
    ldy #0     ; Y will index our number of iterations
    lda #0     ; Set remainder to 0
    sta R      

div_iter
    asl NQ      ; Rotate first bit of the numerator. Do the low byte first. It will affect carry bit which will let us easily roll the high byte.
    rol NQ+1
    rol R      ; Rotate the high-order bit into the remainder
    lda R
    sec        ; Set carry bit so we know if subtraction was successful without borrowing from it
    sbc RADIX  ; Subtract denominator from value in accumulator. Roll result carry bit into quotient.
    bcc div_continue ; branch if subtract failed
    sta R
    inc NQ

div_continue
    iny        ; Increment y and see if we need to rotate any more bits. If not, we're done.
    cpy #NB
    bne div_iter

store_digit
    lda R
    sta OUTPUT_BASE, x ; Write the remainder into the first memory slot
    inx
    lda NQ
    ora NQ+1
    beq print         ; Was Q == 0? We're done. Go to printing our result.
    jmp int2text_newdigit

    ; Print the results of our division
print
    ldy #0              ; Use Y to index screen memory
    clc                 ; Clear carry for the printing loop so we don't unintentionally get 1 added to any of our values

printchar
    dex                ; We predecrement since we incremented after writing the value
    lda OUTPUT_BASE, x ; Load the most significant digit (values were written in reverse order)
    adc #"0"           ; Make sure we are printing a character, not a number
    sta $400, y        ; Write the value to screen memory (PAL)
    lda #1             ; Make the text color white
    sta $d800, y
    txa                ; Transfer X to A so we get the zero bit set if we're done
    beq done           ; If X was 0 this iteration, we're done.
    iny
    jmp printchar

done
    rts