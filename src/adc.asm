; Will clear the screen and print "Hello, world!" in different colors.

*=$0801
!byte $0c,$08,$b5,$07,$9e,$20,$32,$30,$36,$32,$00,$00,$00
jmp main

    !set LINE=40 ; 40 column display

yestext
    !scr "carry set, minuend is >= subtrahend!", 0

notext
    !scr "carry not set, minuend is < subtrahend!", 0

main
    ; Clear the screen using a KERNAL (yes, with an "a") routine
    lda #$93
    jsr $ffd2

    ldx #120 ; Our offset for screen memory. Start at the 3rd line for this program. 40 col display.
    
firstop
    ; We will add: 10010100 11111100 + 00000100 00000011

    ; Clear the carry bit for add operations.
    ; Addition will add the second addend + the carry bit! This allows us to do multi-byte math.
    clc

    ; Add low byte. Will not set carry bit.
    lda #%11111100
    adc #%00000011

    ; Add the high byte. Since the low byte didn't set the carry bit, an extra 1 won't be added.
    lda #%10010100 
    adc #%00000100

secondop
    ; We will add: 10010100 11111100 + 00000100 00000111

    ; Clear carry bit for add operations
    ; Addition will add the second addend + the carry bit! This allows us to do multi-byte math.
    clc

    ; Add low byte. Will set the carry bit since it overflows
    lda #%11111100
    adc #%00000111

    ; Add the high byte. Since the low byte set the carry bit, an extra 1 will be added to reflect the low byte carry.
    ; Carry will be clear after this op since it didn't overflow.
    lda #%10010100 
    adc #%00000100

done
    rts

