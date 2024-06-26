; Will clear the screen and print "Hello, world!" in different colors.

*=$0801
!byte $0c,$08,$b5,$07,$9e,$20,$32,$30,$36,$32,$00,$00,$00
jmp main

hellostr
    !scr "hello, world!" ; Declare our string and null terminate it
    !byte 0

main
    ; Clear the screen using a KERNAL (yes, with an "a") routine
    lda #$93
    jsr $ffd2

    ldx #0             ; Use X to index the string and screen memory

printstring
    lda hellostr, x    ; Load the most significant digit (values were written in reverse order)
    beq done           ; If X was 0 this iteration, we're done.
    sta $400, x        ; Write the value to screen memory (PAL)
    txa                ; Transfer X to A so we get the zero bit set if we're done
    sta $d800, x       ; Make the text different colors
    inx
    jmp printstring

done
    rts