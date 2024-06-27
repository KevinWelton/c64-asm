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
    ; We will subtract: 10010100 11110101 - 10000100 11110111

    ; Set carry bit for subtraction operations
    ; Subtraction subtracts the NOT of the carry bit! This allows us to do multi-byte math.
    sec

    ; subtract low byte. Will clear carry bit since we have to borrow.
    lda #%11110101
    sbc #%11110111

    ; Remember, we borrowed in the low byte. So we will subtract an extra 1 since we subtract the NOT of the carry bit.
    lda #%10010100 
    sbc #%10000100

    bcs op1_carryset   ; In this op, subtraction should succeeded since carry bit is set after subtracting high byte.
    jsr subtract_bad
    jmp secondop
op1_carryset
    jsr subtract_ok

secondop
    ; We will subtract: 10010100 11110101 - 11000100 11110111

    ; Set carry bit for subtraction operations
    ; Subtraction subtracts the NOT of the carry bit! This allows us to do multi-byte math.
    sec

    ; Subtract low byte. Will clear carry bit since we have to borrow.
    lda #%11110101
    sbc #%11110111

    ; Remember, we borrowed in the low byte. So we will subtract an extra 1 since we subtract the NOT of the carry bit.
    lda #%10010100 
    sbc #%11000100

    bcs op2carry_set     ; In this op, subtraction should fail since carry bit is clear after subtracting high byte.
    jsr subtract_bad
    jmp done
op2carry_set
    jsr subtract_ok

done
    rts

subtract_ok
    txa
    pha
    ldy #0
ok_iter
    lda yestext, y
    beq print_done
    sta $400, x           ; Write the value to screen memory (PAL)
    lda #1
    sta $d800, X
    iny
    inx
    jmp ok_iter

subtract_bad
    txa
    pha
    ldy #0
bad_iter
    lda notext, y
    beq print_done
    sta $400, x           ; Write the value to screen memory (PAL)
    lda #1
    sta $d800, x
    iny
    inx
    jmp bad_iter

print_done
    clc                   ; Pop x from the stack and increment it by one line position. If there was a carry bit, we don't want it!
    pla
    adc #LINE
    tax
    rts

