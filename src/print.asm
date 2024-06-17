;
; Example
;

*=$0801
!byte $0c,$08,$b5,$07,$9e,$20,$32,$30,$36,$32,$00,$00,$00
jmp main

.hellotext
    !scr "hello, world!",0
    !set ofs = 14

main
    ldy #0           ; Initial string index is the first character
    ldx #1           ; Start with color 1 (white)

print
    lda .hellotext,y
    beq +           ; Null character? we are done.
    sta $400+ofs,y  ; Write character to screen memory
    txa             ; Copy x register to the accumulator
    sta $d800+ofs,y
    iny             ; Increment y index register for next character
    inx             ; Increment x index register for next color
    jmp print       ; Loop to print the next character until we've printed them all.
+
    rts             ; Done
