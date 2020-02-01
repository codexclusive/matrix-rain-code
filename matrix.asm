
;              Matrix Rain Code              ; 
;                                            ;
;              by Gabor Kotik                ;
;              GitHub: codexclusive          ;
;                                            ;
;              Recreates the digital rain    ;
;              effect from the movie         ;
;              The Matrix, using 16-bit      ;
;              assembly and the ASCII        ;
;              character set.                ;
;                                            ; 
                                             ;
MATRIX         SEGMENT                       ;
               ASSUME CS:MATRIX              ;
               ORG   100H                    ;


; ------------ Initialize the 80x25 character screen and the random seed


START:         MOV   AX,0003H                ; set video mode 
               INT   10H                     ; 
               MOV   AH,01H                  ; disable cursor
               MOV   CX,2000H                ;
               INT   10H                     ;       
               MOV   AH,2CH                  ; get system time
               INT   21H                     ;
               ROR   DX,1                    ; fill two highest bits
               ROR   DX,1                    ;
               MOV   BX,DX                   ; initialize random seed (BX)
               MOV   AX,0B800H               ;  
               MOV   DS,AX                   ; set DS,ES to video memory 
               MOV   ES,AX                   ; 
               XOR   DI,DI                   ; set DI to top-left corner
               CLD                           ; of screen
 
            
; ------------ Fill the visible screen with pseudo-random characters

                          
               MOV   CX,07D0H                ; repeat 2000x
@01:           MOV   AX,41A7H                ; 
               MUL   BX                      ;
               MOV   BX,AX                   ; BX=new pseudo-random number
               MOV   AL,AH                   ;
               XOR   AH,AH                   ; AL=character, AH=color code
               STOSW                         ;
               LOOP  @01                     ; after loop, DI=0FA0H
          
          
; ------------ Initialize second page of video memory. A counter and a 
;              cycle length is assigned to each character.

               
               MOV   CX,07D0H                ; repeat 2000x
@02:           MOV   AX,41A7H                ; 
               MUL   BX                      ;
               MOV   BX,AX                   ; values between 01H-0FFH
               OR    AH,01H                  ; 
               MOV   AL,AH                   ; AL=counter, AH=cycle length
               STOSW                         ;
               LOOP  @02                     ; after loop, DI=1F40H
               
               
; ------------ Initialize beam positions

               
               MOV   CX,0050H                ; repeat 80x
@03:           MOV   AX,41A7H                ; 
               MUL   BX                      ; 
               MOV   BX,AX                   ; 
               XCHG  AL,AH                   ; rotate AH to highest bits
               ROL   AX,1                    ; of beam position
               ROL   AX,1                    ;
               AND   AH,03H                  ; beam position between 0-03FFH
               STOSW                         ; 
               LOOP  @03                     ; after loop, DI=1FE0H
                                             
                                             
;------------- Main cycle                    


; ------------ Decrease counter and change character if counter=0

               
               XOR   BP,BP                   ; BP=virtual screen size
MAIN:          XOR   DI,DI                   ; 
@04:           MOV   SI,0FA0H                ; SI points to page 2
               ADD   SI,DI                   ; 
               DEC   BYTE PTR [SI]           ; decrease counter
               JNZ   @06                     ;
               MOV   AX,41A7H                ; get new pseudo-random number
               MUL   BX                      ;
               MOV   BX,AX                   ;
               MOV   [DI],AH                 ; change character on screen
               TEST  AH,2AH                  ;
               JZ    @05                     ;
               
               
; ------------ Reset counter and change speed if necessary

               
               MOV   AX,[SI]                 ; do not change speed
@05:           MOV   AL,AH                   ; change speed   
               MOV   [SI],AX                 ; reset counter
@06:           INC   DI                      ;
               INC   DI                      ; move to next character
               CMP   DI,0FA0H                ;
               JNZ   @04                     ; after loop, DI=0FA0H 
               
               
; ------------ Vertical blank timing               
               
               
               MOV   DX,03DAH                ; 
@07:           IN    AL,DX                   ; 
               TEST  AL,08H                  ;
               JNZ   @07                     ; jump if VB in progress
@08:           IN    AL,DX                   ;
               TEST  AL,08H                  ;
               JZ    @08                     ; jump if no VB in progress
               
              
; ------------ Update virtual screen size & beam position               
               
               
               SHL   DI,1                    ; move to page 3
               CMP   BP,0100H                ; check if virtual screen has
               JNC   @09                     ; reached its full size
               INC   BP                      ;
@09:           MOV   AX,[DI]                 ;
               INC   AX                      ;
               CMP   AX,0400H                ; if beam position=0400H then
               JNZ   @10                     ; set beam position to 0
               CBW                           ; 
@10:           STOSW                         ; update beam position

               
; ------------ Check where the beam is located on the screen              
               
               
               CMP   AX,BP                   ; beam vs. virtual screen size
               JNC   @12                     ;
               MOV   CX,00A0H                ; CL=row size, CH=color code
               MOV   DX,00E4H                ; DL=offset, DH=head+body status
               CMP   AL,DL                   ; 
               JNC   @11                     ; take action according to
               CMP   AL,1CH                  ; beam position
               JNC   @12                     ; 
               MOV   CH,0FH                  ;
               XOR   DL,DL                   ;
               CMP   AL,03H                  ;
               JC    @11                     ;
               MOV   CH,0AH                  ;
               MOV   DL,03H                  ;
               CMP   AL,19H                  ;
               RCL   DH,1                    ; set DH=1 if 02H<AL<19H
               
               
; ------------ Update colors on visible screen               
               
               
@11:           SUB   AL,DL                   ; calculate memory address
               MUL   CL                      ; of color code
               MOV   SI,AX                   ;
               ADD   SI,DI                   ;
               SUB   SI,1F41H                ;
               MOV   [SI],CH                 ; update color on screen
               OR    DH,DH                   ; 
               JZ    @12                     ; if 02H<AL<19H then
               ADD   SI,01E0H                ; update color 3 rows below
               MOV   CH,0FH                  ; 
               MOV   [SI],CH                 ; 


; ------------ Loop through all the beams and check if the user has 
;              pressed a key


@12:           CMP   DI,1FE0H                ; go to next beam
               JNZ   @09                     ; 
               MOV   AH,01H                  ; get keyboard status
               INT   16H                     ;
               JNZ   EXIT                    ; exit if a key is pressed
               JMP   MAIN                    ; if not, continue main cycle
               
               
; ------------ Reset screen and exit to system

               
EXIT:          XOR   AX,AX                   ; read character from buffer
               INT   16H                     ;
               MOV   AX,0003H                ; clear screen
               INT   10H                     ;
               MOV   AH,01H                  ; enable cursor
               MOV   CX,0607H                ;
               MOV   AX,4C00H                ; exit to system
               INT   21H                     ;
                                             ;
MATRIX         ENDS                          ;
               END   START                   ;
               
