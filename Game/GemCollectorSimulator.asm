  .inesprg 1   ; 1x 16KB PRG code
  .ineschr 1   ; 1x  8KB CHR data
  .inesmap 0   ; mapper 0 = NROM, no bank swapping
  .inesmir 1   ; background mirroring
  

;;;;;;;;;;;;;;;
;; DECLARE SOME VARIABLES HERE
  .rsset $0000  ;;start variables at ram location 0
buttons1			.rs 1 ; player 1 gamepad buttons, one bit per button
enemyIsActive		.rs 1 ; is bullet active?
enemy1IsActive		.rs 1 ; is enemy 1 active?
fireIsActive		.rs 1 ; is fire active?
gemIsActive         .rs 1 ; is gem active?
timer				.rs 1 ; Stores a valuse for the Timer
timerEnemy          .rs 1 ; Stores a valuse for the enemy spawn Timer
gravity				.rs 1 ; Stores the value for Gravity
enemyX				.rs 1 ; Stores the enemies X position
enemyY				.rs 1 ; Stores the enemies Y position
randLocation        .rs 1 ; Stores a random number for gem locations
randLocation2       .rs 1 ; Stores a random number for gem locations


CONTROLLER_A      = %10000000
CONTROLLER_B      = %01000000
CONTROLLER_SELECT = %00100000
CONTROLLER_START  = %00010000
CONTROLLER_UP     = %00001000
CONTROLLER_DOWN   = %00000100
CONTROLLER_LEFT   = %00000010
CONTROLLER_RIGHT  = %00000001

RIGHTWALL      = $F4
TOPWALL        = $10
BOTTOMWALL     = $D4
LEFTWALL       = $03
    
  .bank 0
  .org $C000 
RESET:
  SEI          ; disable IRQs
  CLD          ; disable decimal mode
  LDX #$40
  STX $4017    ; disable APU frame IRQ
  LDX #$FF
  TXS          ; Set up stack
  INX          ; now X = 0
  STX $2000    ; disable NMI
  STX $2001    ; disable rendering
  STX $4010    ; disable DMC IRQs

vblankwait1:       ; First wait for vblank to make sure PPU is ready
  BIT $2002
  BPL vblankwait1

clrmem:
  LDA #$00
  STA $0000, x
  STA $0100, x
  STA $0200, x
  STA $0400, x
  STA $0500, x
  STA $0600, x
  STA $0700, x
  LDA #$FE
  STA $0300, x
  INX
  BNE clrmem
   
vblankwait2:      ; Second wait for vblank, PPU is ready after this
  BIT $2002
  BPL vblankwait2


LoadPalettes:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$3F
  STA $2006             ; write the high byte of $3F00 address
  LDA #$00
  STA $2006             ; write the low byte of $3F00 address
  LDX #$00              ; start out at 0
LoadPalettesLoop:
  LDA palette, x        ; load data from address (palette + the value in x)
                          ; 1st time through loop it will load palette+0
                          ; 2nd time through loop it will load palette+1
                          ; 3rd time through loop it will load palette+2
                          ; etc
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$20              ; Compare X to hex $10, decimal 16 - copying 16 bytes = 4 sprites
  BNE LoadPalettesLoop  ; Branch to LoadPalettesLoop if compare was Not Equal to zero
                        ; if compare was equal to 32, keep going down



LoadSprites:
  LDX #$00              ; start at 0
LoadSpritesLoop:
  LDA sprites, x        ; load data from address (sprites +  x)
  STA $0200, x          ; store into RAM address ($0200 + x)
  INX                   ; X = X + 1
  CPX #$32              ; Compare X to hex $20, decimal 32
  BNE LoadSpritesLoop   ; Branch to LoadSpritesLoop if compare was Not Equal to zero
                        ; if compare was equal to 32, keep going down
              
              

  LDA #%10000000   ; enable NMI, sprites from Pattern Table 1
  STA $2000

  LDA #%00010000   ; enable sprites
  STA $2001

Forever:
  JMP Forever     ;jump back to Forever, infinite loop



NMI:
  LDA #$00
  STA $2003       ; set the low byte (00) of the RAM address
  LDA #$02
  STA $4014       ; set the high byte (02) of the RAM address, start the transfer
  
EndGame:
  LDA $022D             ; Load Tile number
  CMP #$F9              ; Compare it to 10
  BNE .Done             ; Branch if not equal
   
  JMP Forever           ; End game 
.Done:
  

  ; Update fire X position
  LDA $0213             ; Load Fire X Location
  CLC                   ; Clear Carry flag
  ADC #1                ; Add one
  STA $0213             ; Increment the X location by 1
  LDA $0217             ; Load Fire X Location
  CLC					; Clear Carry flag
  ADC #1				; Add one
  STA $0217				; Increment the X location by 1


RadomNumber:
  LDA randLocation       ; Load randLoaction
  CLC                    ; Clear Carry flag
  ADC #1                 ; Add 1
  STA randLocation       ; Save to randLocation
  CMP #80               ; Do this 20 times then move on
  BNE .Done              ; Branch to done
.Done

RadomNumber1:
  LDA randLocation2       ; Load randLoaction
  CLC                    ; Clear Carry flag
  ADC #1                 ; Add 1
  STA randLocation2       ; Save to randLocation
  CMP #80               ; Do this 20 times then move on
  BNE .Done              ; Branch to done
.Done
 

 ; Used to drag player down 
Gravity:
  LDA buttons1        ; player 1
  AND #CONTROLLER_A   ; only look at bit 0
  BNE .Done           ; branch to ReadADone if button IS pressed (1)
  
  LDA $0200           ; Load Sprite Y Position
  CMP #BOTTOMWALL     ; Compare it to the Bottom wall position
  BEQ .Done           ; Branch to jump if the Y position and wall match

  LDX #$0
.Loop:
  LDA $0200, x        ; Load sprite Y position
  CLC                 ; Clear carry flag 
  ADC #$01            ; Add 1
  STA $0200, x        ; save sprite Y position
  INX                 ; Increment X 4 times to get the next sprite's Y
  INX
  INX
  INX
  CPX #$10            ; It must do this a number of times to move all 4 sprites
  BNE .Loop           ; Branch back to the loop
.Done:                ; handling this button is done


  ; Update enemies position
MoveEnemies:
  LDA enemyIsActive
  AND #1
  BNE .Done

.Loop:
  LDA $021B, x           ; load sprite X position
  SEC                    ; make sure the carry flag is clear
  SBC #$01               ; A = A + 1
  STA $021B, x           ; save sprite X position
  INX
  INX
  INX
  INX
  CPX #$10
  BNE .Loop

.Loop2:
  LDA $0218, x           ; load sprite Y position
  SEC                    ; make sure the carry flag is clear
  SBC #$01               ; A = A + 1
  STA $0218, x           ; save sprite Y position
  INX
  INX
  INX
  INX
  CPX #$10
  BNE .Loop2
.Done:


;Increments the timer value by 1 per frame
TimeCount:
  LDA timer              ; Load fire
  CLC                    ; Clear Carry flag
  ADC #1                 ; Add 1
  STA timer              ; Save to timer
  CMP #20                ; Do this 20 times then move on
  BNE .Done              ; Branch to done
						 
.Killfire:				 
  LDA #0                 ; Load a value of 0
  STA fireIsActive       ; kill the Fire
  STA $0210              ; Save the 0 value into the memory adresses of the fire
  STA $0211
  STA $0212
  STA $0213
  STA $0214
  STA $0215
  STA $0216
  STA $0217
.Done:

UpdateEnemy0:
  ; Check collision
  LDA $0214              ; Fire Y
  SEC					 ; Set carry flag
  SBC $0218 			 ; Enemy Y
  CLC					 ; Clear Carry flag
  ADC #8				 ; Add 8
  BMI .Done 			 ; Branch if FireY - EnemyY + 8 < 0
  SEC					 ; Set carry flag
  SBC #12				 ; Subtract 12
  BPL .Done 			 ; Branch if FireY - EnemyY - 8 > 0
  
  LDA $0217 			 ; Fire X
  SEC					 ; Set carry flag
  SBC $021B 			 ; Enemy X
  CLC					 ; Clear Carry flag
  ADC #8				 ; Add 8
  BMI .Done 			 ; Branch if FireX - EnemyX + 8 < 0
  SEC					 ; Set carry flag
  SBC #12				 ; Subtract 12
  BPL .Done 			 ; Branch if FireX - EnemyX - 8 > 0
  
  LDA randLocation		 ; Load random value
  STA $0218				 ; Save into the memory locations of the enemy to remove them from screen
  CLC
  LDA randLocation2		 ; Load random value
  STA $021B

.Done:


UpdateEnemy1:
  ; Check collision
  LDA $0214              ; Fire Y
  SEC					 ; Set carry flag
  SBC $021C 			 ; Enemy Y
  CLC					 ; Clear Carry flag
  ADC #8				 ; Add 8
  BMI .Done 			 ; Branch if FireY - EnemyY + 8 < 0
  SEC					 ; Set carry flag
  SBC #12				 ; Subtract 12
  BPL .Done 			 ; Branch if FireY - EnemyY - 8 > 0
  
  LDA $0217 			 ; Fire X
  SEC					 ; Set carry flag
  SBC $021F 			 ; Enemy X
  CLC					 ; Clear Carry flag
  ADC #8				 ; Add 8
  BMI .Done 			 ; Branch if FireX - EnemyX + 8 < 0
  SEC					 ; Set carry flag
  SBC #12				 ; Subtract 12
  BPL .Done 			 ; Branch if FireX - EnemyX - 8 > 0
  
  LDA randLocation	     ; Load random value
  STA $021C				 ; Save into the memory locations of the enemy to remove them from screen
  CLC
  LDA randLocation2		 ; Load random value
  STA $021F
.Done:


UpdateEnemy2:
  ; Check collision
  LDA $0214              ; Fire Y
  SEC					 ; Set carry flag
  SBC $0220 			 ; Enemy Y
  CLC					 ; Clear Carry flag
  ADC #8				 ; Add 8
  BMI .Done 			 ; Branch if FireY - EnemyY + 8 < 0
  SEC					 ; Set carry flag
  SBC #12				 ; Subtract 12
  BPL .Done 			 ; Branch if FireY - EnemyY - 8 > 0
  
  LDA $0217 			 ; Fire X
  SEC					 ; Set carry flag
  SBC $0223 			 ; Enemy X
  CLC					 ; Clear Carry flag
  ADC #8				 ; Add 8
  BMI .Done 			 ; Branch if FireX - EnemyX + 8 < 0
  SEC					 ; Set carry flag
  SBC #12				 ; Subtract 12
  BPL .Done 			 ; Branch if FireX - EnemyX - 8 > 0
  
  LDA randLocation		 ; Load random value
  STA $0220				 ; Save into the memory locations of the enemy to remove them from screen
  CLC
  LDA randLocation2		 ; Load random value
  STA $0223
.Done:


UpdateEnemy3:
  ; Check collision
  LDA $0214              ; Fire Y
  SEC					 ; Set carry flag
  SBC $0224 			 ; Enemy Y
  CLC					 ; Clear Carry flag
  ADC #8				 ; Add 8
  BMI .Done 			 ; Branch if FireY - EnemyY + 8 < 0
  SEC					 ; Set carry flag
  SBC #12				 ; Subtract 12
  BPL .Done 			 ; Branch if FireY - EnemyY - 8 > 0
  
  LDA $0217 			 ; Fire X
  SEC					 ; Set carry flag
  SBC $0227 			 ; Enemy X
  CLC					 ; Clear Carry flag
  ADC #8				 ; Add 8
  BMI .Done 			 ; Branch if FireX - EnemyX + 8 < 0
  SEC					 ; Set carry flag
  SBC #12				 ; Subtract 12
  BPL .Done 			 ; Branch if FireX - EnemyX - 8 > 0
  
  LDA randLocation		 ; Load random value
  STA $0224				 ; Save into the memory locations of the enemy to remove them from screen
  CLC
  LDA randLocation2		 ; Load random value
  STA $0227
.Done:

PlayerCollisionCheck0:
  ; Check collision
  LDA $0200              ; Fire Y
  SEC					 ; Set carry flag
  SBC $0218 			 ; Enemy Y
  CLC					 ; Clear Carry flag
  ADC #8				 ; Add 8
  BMI .Done 			 ; Branch if FireY - EnemyY + 8 < 0
  SEC					 ; Set carry flag
  SBC #12				 ; Subtract 12
  BPL .Done 			 ; Branch if FireY - EnemyY - 8 > 0
  
  LDA $0203 			 ; Fire X
  SEC					 ; Set carry flag
  SBC $021B 			 ; Enemy X
  CLC					 ; Clear Carry flag
  ADC #8				 ; Add 8
  BMI .Done 			 ; Branch if FireX - EnemyX + 8 < 0
  SEC					 ; Set carry flag
  SBC #12				 ; Subtract 12
  BPL .Done 			 ; Branch if FireX - EnemyX - 8 > 0
  
  LDA randLocation		 ; Load random value
  STA $0218				 ; Save into the memory locations of the enemy to remove them from screen
  CLC
  LDA randLocation2		 ; Load random value
  STA $021B

  LDA $022D              ; Load Number Tile
  CLC					 ; Clear Carry Flag
  ADC #9				 ; Add one
  STA $022D				 : Incremnt the Score by 1
.Done:


PlayerCollisionCheck1:
  ; Check collision
  LDA $0200              ; Fire Y
  SEC					 ; Set carry flag
  SBC $021C 			 ; Enemy Y
  CLC					 ; Clear Carry flag
  ADC #8				 ; Add 8
  BMI .Done 			 ; Branch if FireY - EnemyY + 8 < 0
  SEC					 ; Set carry flag
  SBC #12				 ; Subtract 12
  BPL .Done 			 ; Branch if FireY - EnemyY - 8 > 0
  
  LDA $0203 			 ; Fire X
  SEC					 ; Set carry flag
  SBC $021F 			 ; Enemy X
  CLC					 ; Clear Carry flag
  ADC #8				 ; Add 8
  BMI .Done 			 ; Branch if FireX - EnemyX + 8 < 0
  SEC					 ; Set carry flag
  SBC #12				 ; Subtract 12
  BPL .Done 			 ; Branch if FireX - EnemyX - 8 > 0
  
  LDA randLocation	     ; Load random value
  STA $021C				 ; Save into the memory locations of the enemy to remove them from screen
  CLC
  LDA randLocation2		 ; Load random value
  STA $021F

  LDA $022D              ; Load Number Tile
  CLC					 ; Clear Carry Flag
  ADC #9				 ; Add one
  STA $022D				 : Incremnt the Score by 1
.Done:


PlayerCollisionCheck2:
  ; Check collision
  LDA $0200              ; Fire Y
  SEC					 ; Set carry flag
  SBC $0220 			 ; Enemy Y
  CLC					 ; Clear Carry flag
  ADC #8				 ; Add 8
  BMI .Done 			 ; Branch if FireY - EnemyY + 8 < 0
  SEC					 ; Set carry flag
  SBC #12				 ; Subtract 12
  BPL .Done 			 ; Branch if FireY - EnemyY - 8 > 0
  
  LDA $0203 			 ; Fire X
  SEC					 ; Set carry flag
  SBC $0223 			 ; Enemy X
  CLC					 ; Clear Carry flag
  ADC #8				 ; Add 8
  BMI .Done 			 ; Branch if FireX - EnemyX + 8 < 0
  SEC					 ; Set carry flag
  SBC #12				 ; Subtract 12
  BPL .Done 			 ; Branch if FireX - EnemyX - 8 > 0
  
  LDA randLocation		 ; Load random value
  STA $0220				 ; Save into the memory locations of the enemy to remove them from screen
  CLC
  LDA randLocation2		 ; Load random value
  STA $0223

  LDA $022D              ; Load Number Tile
  CLC					 ; Clear Carry Flag
  ADC #9				 ; Add one
  STA $022D				 : Incremnt the Score by 1
.Done:


PlayerCollisionCheck3:
  ; Check collision
  LDA $0200              ; Fire Y
  SEC					 ; Set carry flag
  SBC $0224 			 ; Enemy Y
  CLC					 ; Clear Carry flag
  ADC #8				 ; Add 8
  BMI .Done 			 ; Branch if FireY - EnemyY + 8 < 0
  SEC					 ; Set carry flag
  SBC #12				 ; Subtract 12
  BPL .Done 			 ; Branch if FireY - EnemyY - 8 > 0
  
  LDA $0203 			 ; Fire X
  SEC					 ; Set carry flag
  SBC $0227 			 ; Enemy X
  CLC					 ; Clear Carry flag
  ADC #8				 ; Add 8
  BMI .Done 			 ; Branch if FireX - EnemyX + 8 < 0
  SEC					 ; Set carry flag
  SBC #12				 ; Subtract 12
  BPL .Done 			 ; Branch if FireX - EnemyX - 8 > 0
  
  LDA randLocation		 ; Load random value
  STA $0224				 ; Save into the memory locations of the enemy to remove them from screen
  CLC
  LDA randLocation2		 ; Load random value
  STA $0227

  LDA $022D              ; Load Number Tile
  CLC					 ; Clear Carry Flag
  ADC #9				 ; Add one
  STA $022D				 : Incremnt the Score by 1
.Done:

UpdateGem:
  ; Check collision
  LDA $0200              ; Player Y
  SEC		             ; Set carry flag
  SBC $0228              ; Gem Y
  CLC		             ; Clear Carry flag
  ADC #8	             ; Add 8
  BMI .Done              ; Branch if PlayerY - GemY + 8 < 0
  SEC		             ; Set carry flag
  SBC #12	             ; Subtract 12
  BPL .Done              ; Branch if PlayerY - GemY - 8 > 0
  			             
  LDA $0203              ; Player X
  SEC		             ; Set carry flag
  SBC $022B              ; Gem X
  CLC		             ; Clear Carry flag
  ADC #8	             ; Add 8
  BMI .Done              ; Branch if PlayerX - GemX + 8 < 0
  SEC					 ; Set carry flag
  SBC #12				 ; Subtract 12
  BPL .Done              ; Branch if PlayerX - GemX - 8 > 0
  
  LDA randLocation       ; Load random value
  STA $0228              ; Save into the memory locations of the gem to remove them from screen
  CLC
  LDA randLocation2		 ; Load random value
  STA $022B

  LDA $022D              ; Load Number Tile
  CLC                    ; Clear Carry Flag
  ADC #1                 ; Add one
  STA $022D              : Incremnt the Score by 1
 
.Done:


  JSR ReadController1


ReadLeft: 
  LDA buttons1           ; player 1
  AND #CONTROLLER_LEFT   ; only look at bit 0
  BEQ .Done              ; branch to ReadADone if button is NOT pressed (0)
				         
  LDA $0203              ; Load Sprite X Position
  CMP #LEFTWALL          ; Compare it to the Bottom wall position
  BEQ .Done              ; Branch to jump if the Y position and wall match
				         
  LDX #0		         
.Loop:			         
  LDA $0203, x           ; Load sprite X position
  SEC                    ; Set carry flag
  SBC #$01               ; Add 1
  STA $0203, x           ; save sprite X position
  INX			         ; Increment X 4 times to get the next sprite's X
  INX			         
  INX			         
  INX			         
  CPX #$10		         ; It must do this a number of times to move all 4 sprites
  BNE .Loop              ; Branch back to the loop
.Done:                   ; handling this button is done
  

ReadRight: 
  LDA buttons1           ; player 1
  AND #CONTROLLER_RIGHT  ; only look at bit 0
  BEQ .Done              ; branch to ReadBDone if button is NOT pressed (0)
  				         
  LDA $0203              ; Load Sprite X Position
  CMP #RIGHTWALL         ; Compare it to the Bottom wall position
  BEQ .Done              ; Branch to jump if the X position and wall match
				         
  LDX #0		         
.Loop:			         
  LDA $0203, x           ; Load sprite X position
  CLC                    ; Set carry flag
  ADC #$01               ; Add 1
  STA $0203, x           ; save sprite X position
  INX			         ; Increment X 4 times to get the next sprite's X
  INX			         
  INX			         
  INX			         
  CPX #$10               ; It must do this a number of times to move all 4 sprites
  BNE .Loop              ; Branch back to the loopp		  
.Done:                   ; handling this button is done        
		
		
ReadA:
  LDA buttons1           ; player 1
  AND #CONTROLLER_A      ; only look at bit 0
  BEQ .Done              ; branch to ReadADone if button is NOT pressed (0)
                         
					     
  LDA $0200              ; Load Sprite Y Position
  CMP #TOPWALL           ; Compare it to the Bottom wall position
  BEQ .Done              ; Branch to jump if the Y position and wall match
					     
  LDX #$0			     
.Loop:				     
  SEC				     ; Load sprite Y position
  LDA $0200, x		     ; Clear carry flag 
  SBC #$01			     ; Add 1
  STA $0200, x           ; save sprite Y position
  INX				     ; Increment X 4 times to get the next sprite's Y
  INX				     
  INX				     
  INX				     
  CPX #$10			     ; It must do this a number of times to move all 4 sprites
  BNE .Loop			     ; Branch back to the loop
.Done:                   ; handling this button is done
					     
					     
ReadB:				     
  LDA buttons1           ; player 1
  AND #CONTROLLER_B	     ; only look at bit 0
  BEQ .Done			     ; branch to ReadADone if button is NOT pressed (0)
  					     
  LDA fireIsActive       ; Check is fire is active(1)
  CMP #1                 ; Compare to 1
  BEQ .Done              ; Branch to Done if fire is active
  
  ; Fire Comes in two sprites
  LDA $0200              ; Load the Y Value of the player
  CLC                    ; Clear the carry flag
  ADC #$4                ; Add 4 to the Value
  STA $0210              ; Save the new Y value to the Y value of the Fire
  LDA #$02               ; The Tile for the sprites image
  STA $0211              ; Store the tile into memory
  LDA #0                 ; Attributes
  STA $0212              ; Save the attibutes
  LDA $0203              ; Load the players X Value
  CLC                    ; Clear the Carry FLag
  ADC #16                ; Add 16 to the X value
  STA $0213              ; Save the new X value to the X value of the Fire
					     
  LDA $0200              ; Load the Y Value of the player
  CLC				     ; Clear the carry flag
  ADC #$4			     ; Add 4 to the Value
  STA $0214			     ; Save the new Y value to the Y value of the Fire
  LDA #$03   		     ; The Tile for the sprites image
  STA $0215			     ; Store the tile into memory
  LDA $0     		     ; Attributes
  STA $0216			     ; Save the attibutes
  LDA $0213  		     ; Load the players X Value
  CLC				     ; Clear the Carry FLag
  ADC #8			     ; Add 16 to the X value
  STA $0217			     ; Save the new X value to the X value of the Fire  
					     
  LDA timer              ; Load the timer
  LDA #0                 ; Load a 0 value
  STA timer              ; Save to timer to reset its value to 0
 					     
.Done: 				     
  RTI                    ; return from interrupt
  JMP TimeCount          ; Jump to TimeCount to despawn the fire after the elapsed time

ReadController1:
  LDA #$01
  STA $4016
  LDA #$00
  STA $4016
  LDX #$08
ReadController1Loop:
  LDA $4016
  LSR A            ; bit0 -> Carry
  ROL buttons1     ; bit0 <- Carry
  DEX
  BNE ReadController1Loop
  RTS

;;;;;;;;;;;;;;  
  
  
  
  .bank 1
  .org $E000
palette:
  .db $0F,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3A,$3B,$3C,$3D,$3E,$0F
  .db $0F,$1C,$15,$14,$31,$02,$38,$3C,$0F,$1C,$15,$14,$31,$02,$38,$3C

sprites:
     ;vert tile attr horiz
  .db $80, $00, $00, $80   ;sprite 0
  .db $80, $01, $00, $88   ;sprite 1
  .db $88, $10, $00, $80   ;sprite 2
  .db $88, $11, $00, $88   ;sprite 3
  .db $00, $02, $00, $00   ;Fire 0
  .db $00, $03, $00, $08   ;Fire 1
  .db $20, $12, $00, $00   ;enemy0
  .db $80, $12, $00, $00   ;enemy2
  .db $50, $12, $00, $00   ;enemy3
  .db $90, $12, $00, $00   ;enemy4
  .db $40, $30, $00, $00   ;gem
  .db $10, $F0, $00, $10   ;One

  .org $FFFA     ;first of the three vectors starts here
  .dw NMI        ;when an NMI happens (once per frame if enabled) the 
                   ;processor will jump to the label NMI:
  .dw RESET      ;when the processor first turns on or is reset, it will jump
                   ;to the label RESET:
  .dw 0          ;external interrupt IRQ is not used in this tutorial
  
  
;;;;;;;;;;;;;;  
  
  
  .bank 2
  .org $0000
  .incbin "spyro.chr"   ;includes 8KB graphics file from SMB1