; Stares
; F#READY, 2022

; v12 - 255 bytes
; - changed a little in the colors, much better now :)
; v11 - 256 bytes
; - new start intro, show squares for 1 jiffy
; v10 - 255 bytes
; - added start-up thing
; v9 - 222 bytes
; - finally fixed the nasty glitch bug :)
; - added color change
; - added direction change
; v8
; - different approach. only shift starting square.
; - has a bug/glitch in the animation
; v7
; - try animation with full drawing
; v6 : 121 bytes
; - optimisations by IvoP, thank you! :)
; v5 : 127 bytes
; - removed open_mode glitch, added bleep
; v4 : 128 bytes
; - brrr hack to switch colors for restart
; - generate all coordinates in $80, move code out of zeropage
; v3 : 112 bytes
; - moved to zeropage, optimised, 112 bytes 
; - changed hack, removed run address, 120 bytes
; v2 : 122 bytes
; - removed dead code, few optimisations, 122 bytes
; v1 : 129 bytes
; - working!

NR_OF_SQUARES   = 11  ; max. 15

ICAX1Z      = $2a       ; set to $20 to skip clear screen

SKIP_SIZE   = 10          ; 9, or 13
MAX_XPOS    = 87+8

ROWCRS      = $54       ; byte
y_position  = ROWCRS    ; alias

COLCRS      = $55       ; word
x_position  = COLCRS    ; alias

OLDROW      = $5a       ; byte
y_start     = OLDROW    ; alias

OLDCOL      = $5b       ; word
x_start     = OLDCOL    ; alias

MEMTOP      = $6a

open_mode   = $ef9c     ; A=mode
clear_scr   = $f420     ; zero screen memory
plot_pixel  = $f1d8

COUNTR      = $7e
FILFLG      = $2b7
FILDAT      = $2fd

ATACHR      = $2fb      ; drawing color
draw_color  = ATACHR    ; alias

real_draw   = $f9c2

draw_hack   = $09c2     ;$f9c2     ; $f9bf (stx FILFLG)
ssp7_hack   = $0a4d     ;$fa4d

jmp_my_hack = $0afe

line_number = $30

CDTMV3      = $021c

            org $0600

main            
            ldx #0
make_hack            
            lda real_draw,x
            sta draw_hack,x
            lda real_draw+$100,x
            sta draw_hack+$100,x
            inx
            bne make_hack

            lda #<my_hack
            sta jmp_my_hack+1
            lda #>my_hack
            sta jmp_my_hack+2

            inc draw_color
            
; draw in N screens

draw_loop

            lda #9
            sta START_ROTATE
            lda #$20

make_frames
            pha
            sta MEMTOP
            
            lda #7
            jsr open_mode
            
; -- draw all squares --

draw_squares            
            ldx #0
; don't show yet
            stx 559
            
START_ROTATE = *+1
            lda #9
            sta SKIP_SIZE_CMP

repeat
            lda xy_tab+6,x
            sta x_start
            lda xy_tab+7,x
            sta y_start

draw_square        
            stx line_number

            lda xy_tab,x
            sta x_position
            lda xy_tab+1,x
            sta y_position

            jsr draw_hack

            lda line_number
            clc
            adc #2
            tax

            cmp #8
            bne no_start
; after first square
            lda #SKIP_SIZE
            sta SKIP_SIZE_CMP
            bne repeat
no_start

            and #7
            bne draw_square

            lda $74
            cmp #$12            ; maybe have to fiddle with this for inner square
            bcs repeat

; -- end draw all squares

            jsr show_short

            dec START_ROTATE

dl_tab_index    = *+1
            ldx #0
            lda $231
            sta dl_tab,x        ; maybe push this to stack and use stack,x later ?

            inc dl_tab_index
            pla
            clc
            adc #$10
            cmp #(NR_OF_SQUARES*$10)+$10     ; max $d0 ?
            bne make_frames 

; frames in memory 
; plays forward/backward

            lda #6
            sta 19
movie
            lda 19
            and #2
            asl
            ora #$b9
            sta lda_patch

            lda 19
            asl
            asl
            asl
            asl
            ora #$04
            sta 708
            adc #$84
            sta 710

            ldx #0
            ldy #NR_OF_SQUARES-2
play

lda_patch
            lda dl_tab,x        ; ,x for the other direction ($b9 = Y, $bd = X)
            sta $231
sound_mask  = *+1
            ora #$90
            sta $d200            

            tya
            and 19
            ;lsr
            eor #$e0
            sta $d201

; was:            
;            tya
;            and #$0f
;            and 19
;            eor #$a0
;            sta $d201            
           
            jsr wait_frame

            inx
            dey

            bpl play
            bmi movie

show_short
            lda #4
            sta 708
            lda #6
            sta 710
            lda #34
            sta 559
wait_frame    
            lda 20
floep       cmp 20
            beq floep            
            rts
            
my_hack
            lda COUNTR
SKIP_SIZE_CMP   = *+1            
            cmp #SKIP_SIZE
            bne skip_special

            inc draw_color
            inc draw_color

            ldx line_number
            lda x_position            
            sta xy_tab+8,x
            lda y_position
            sta xy_tab+9,x

skip_special
            jmp ssp7_hack

dl_tab

; pairs of x,y
; 20 5f 80 5f 80 00 20 00

            org $80

xy_tab
            dta 32,95
            dta 128,95
            dta 128,0
            dta 32 ,0   ; could get rid of this 0 when we need one byte :)      
