
;              Matrix Rain Code              ; 
;                                            ;
;              by Gabor Kotik                ;
;              github: codexclusive          ;
;                                            ;
;              Recreates the digital rain    ;
;              effect from the movie         ;
;              The Matrix, using 16-bit      ;
;              assembly and the ascii        ;
;              character set.                ;
                                             ;
                                             ;
               org     0100h                 ;


; ------------ initialize the 80x25 character screen and the random seed


start:         mov     ax, 0003h             ; set video mode 
               int     10h                   ; 
               mov     ah, 01h               ; disable cursor
               mov     cx, 2000h             ;
               int     10h                   ;       
               mov     ah, 2ch               ; get system time
               int     21h                   ;
               ror     dx, 1                 ; fill two highest bits
               ror     dx, 1                 ;
               mov     bx, dx                ; initialize random seed (bx)
               mov     ax, 0b800h            ;  
               mov     ds, ax                ; set ds,es to video memory 
               mov     es, ax                ; 
               xor     di, di                ; set di to top-left corner
               cld                           ; of screen
 
            
; ------------ fill the visible screen with pseudo-random characters

                          
               mov     cx, 07d0h             ; repeat 2000x
@01:           mov     ax, 41a7h             ; 
               mul     bx                    ;
               mov     bx, ax                ; bx=new pseudo-random number
               mov     al, ah                ;
               xor     ah, ah                ; al=character, ah=color code
               stosw                         ;
               loop    @01                   ; after loop, di=0fa0h
          
          
; ------------ initialize second page of video memory. a counter and a 
;              cycle length is assigned to each character.

               
               mov     cx, 07d0h             ; repeat 2000x
@02:           mov     ax, 41a7h             ; 
               mul     bx                    ;
               mov     bx, ax                ; values between 01h-0ffh
               or      ah, 01h               ; 
               mov     al, ah                ; al=counter, ah=cycle length
               stosw                         ;
               loop    @02                   ; after loop, di=1f40h
               
               
; ------------ initialize beam positions

               
               mov     cx, 0050h             ; repeat 80x
@03:           mov     ax, 41a7h             ; 
               mul     bx                    ; 
               mov     bx, ax                ; 
               xchg    al, ah                ; rotate ah to highest bits
               rol     ax, 1                 ; of beam position
               rol     ax, 1                 ;
               and     ah, 03h               ; beam position between 0-03ffh
               stosw                         ; 
               loop    @03                   ; after loop, di=1fe0h
                                             
                                             
;------------- main cycle ------------------ ;                   


; ------------ decrease counter and change character if counter=0

               
               xor     bp, bp                ; bp=virtual screen size
main:          xor     di, di                ; 
@04:           mov     si, 0fa0h             ; si points to page 2
               add     si, di                ; 
               dec     byte [si]             ; decrease counter
               jnz     @06                   ;
               mov     ax, 41a7h             ; get new pseudo-random number
               mul     bx                    ;
               mov     bx, ax                ;
               mov     [di], ah              ; change character on screen
               test    ah, 2ah               ;
               jz      @05                   ;
               
               
; ------------ reset counter and change speed if necessary

               
               mov     ax, [si]              ; do not change speed
@05:           mov     al, ah                ; change speed   
               mov     [si], ax              ; reset counter
@06:           inc     di                    ;
               inc     di                    ; move to next character
               cmp     di, 0fa0h             ;
               jnz     @04                   ; after loop, di=0fa0h 
               
               
; ------------ vertical blank timing               
               
               
               mov     dx, 03dah             ; 
@07:           in      al, dx                ; 
               test    al, 08h               ;
               jnz     @07                   ; jump if vb in progress
@08:           in      al, dx                ;
               test    al, 08h               ;
               jz      @08                   ; jump if no vb in progress
               
              
; ------------ update virtual screen size & beam position               
               
               
               shl     di, 1                 ; move to page 3
               cmp     bp, 0100h             ; check if virtual screen has
               jnc     @09                   ; reached its full size
               inc     bp                    ;
@09:           mov     ax, [di]              ;
               inc     ax                    ;
               cmp     ax, 0400h             ; if beam position=0400h then
               jnz     @10                   ; set beam position to 0
               cbw                           ; 
@10:           stosw                         ; update beam position

               
; ------------ check where the beam is located on the screen              
               
               
               cmp     ax, bp                ; beam vs. virtual screen size
               jnc     @12                   ;
               mov     cx, 00a0h             ; cl=row size, ch=color code
               mov     dx, 00e4h             ; dl=offset, dh=head+body status
               cmp     al, dl                ; 
               jnc     @11                   ; take action according to
               cmp     al, 1ch               ; beam position
               jnc     @12                   ; 
               mov     ch, 0fh               ;
               xor     dl, dl                ;
               cmp     al, 03h               ;
               jc      @11                   ;
               mov     ch, 0ah               ;
               mov     dl, 03h               ;
               cmp     al, 19h               ;
               rcl     dh, 1                 ; set dh=1 if 02h<al<19h
               
               
; ------------ update colors on visible screen               
               
               
@11:           sub     al, dl                ; calculate memory address
               mul     cl                    ; of color code
               lea     si, [di-1f41h]        ;
               add     si, ax                ;
               mov     [si], ch              ; update color on screen
               or      dh, dh                ; 
               jz      @12                   ; if 02h<al<19h then
               add     si, 01e0h             ; update color 3 rows below
               mov     ch, 0fh               ; 
               mov     [si], ch              ; 


; ------------ loop through all the beams and check if the user has 
;              pressed a key


@12:           cmp     di, 1fe0h             ; go to next beam
               jnz     @09                   ; 
               mov     ah, 01h               ; get keyboard status
               int     16h                   ;
               jnz     exit                  ; exit if a key is pressed
               jmp     main                  ; if not, continue main cycle
               
               
; ------------ reset screen and exit to system

               
exit:          xor     ax, ax                ; read character from buffer
               int     16h                   ;
               mov     ax, 0003h             ; clear screen
               int     10h                   ;
               mov     ah, 01h               ; enable cursor
               mov     cx, 0607h             ;
               int     10h                   ;
               mov     ax, 4c00h             ; exit to system
               int     21h                   ;

