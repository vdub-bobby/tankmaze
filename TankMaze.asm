/*************************************************************************
-------------------------------------------------------------------------
---------Tank Battalion Atari 2600 port----------------------------------
-------------------------------------------------------------------------
	Bob Montgomery
	(c) 2012-2023

	VERY loose port of Tank Battalion
		objective: destroy enemy tanks while protecting base in a destroyable maze
		arcade game - play for high score
			earn points by destroying tanks and advancing levels
		have finite # of tanks to destroy each level 
		once destroyed, level is won and advance to new level
		destroy walls by shooting them
		enemy tanks also shoot and also can destroy walls
		enemy tanks shoot you, when you are shot, lose one life
		if enemy tanks shoot base, game over (or?)
		open question: what about tank:tank collisions?
  

    Overall program structure:
    Bank 1:
        startup routine
        main game loop
        VBLANK routine
            if game over: checks trigger to see if we should start a new game
            move enemy tanks
            move bullets (bank 2)
            kernel setup (moved to beginning of kernel (in bank 2))
        Overscan routine
            checks collisions (bank 2)
            move player tank
            if game not playing: draw title screen or draw maze for next level
        various subroutines: 
            ReadConsoleSwitchesSubroutine
            InitialSetupSubroutine
            ChooseTankDirectionSubroutine
            FireEnemyBulletRoutine
            SetInitialEnemyTankSpeedRoutine
            MoveEnemyTanksSubroutine
            SoundSubroutine
            PositionASpriteSubroutine (no longer needed)
            PositionASpriteNoHMOVESubroutine (no longer needed)
            DivideByTwoSubroutine (no longer needed)
            UpdateRandomNumber
            EliminateDiagonalSubroutine
            TankFractionalAddition
            ReadControllersSubroutine
            IsBlockAtPosition
            StartSoundSubroutine
            CheckForEnemyTankSubroutine
            CheckForWallSubroutine
            KernelSetupSubroutine
        data
        bank switching logic
    Bank 2:
        kernel routine
        various subroutines:
            DrawTitleScreenSubroutine
            MoveBulletSubroutine
            GenerateMazeSubroutine
            UpdateRandomNumberBank2
            MoveEnemyTanksOffScreen
            MoveBulletsOffScreen
            IncreaseScoreSubroutine
            IsTankOnScreen
            CollisionsSubroutine
            BulletHitBrickSubroutine
            BulletHitTank / PlayerHitTank
            StartSoundSubroutineBank2
            PositionASpriteSubroutineBank2
        data
        bank switching logic

    Note:
        I used the bankswitching schema I came up with many moons ago, which uses the BRK vector and is super easy to use and allows 
        subroutines to be moved from one bank to another without having to go fiddle with jump tables or whatever.  ON THE OTHER HAND
        it is extremely slow:  it uses 65 cycles to jump to a routine in another bank and then it takes 28 cycles to return.
        It also trashes the X and A registers.


	To do:
	Difficulty ramping.  Two things:
	    1. Increase initial difficulty - potentially increase firing rate for level 1
	    2. Tweak difficulty ramping.  Currently -
	        tanks reach max speed at level 32 (and 1 or 2 tanks are faster every 4 levels)
                could we increase the maximum tank speed?  We can't move tanks more than once every 4 frames, but could we move >1 pixel at a time?
                    could be possible except that we have to make sure they don't overrun intersections.  Which is an issue since bricks are 7 lines tall.
                        what if we made them 8 lines tall
	        tanks reach maximum fire rate at level 21
	DONE Add explosion graphics  or ????.  STILL TO DO: Player tank also should explode.  And make it so explosion graphic doesn't kill other tanks.
    Respawn routine needs work.  I am wondering if should use location of other tanks rather than player tank to determine where to respawn.
	IN PROGRESS Power-Ups - ???
		keep this simple: 
			DONE speed
			NIX - extra life
			DONE "bomb" that destroys all tanks on screen (and all walls?)
			??? something that slows all enemies down?
			??? other?
			thinking about using a "combo" mechanism, that can be displayed easily and when full.... tank speeds up?
			    would need a byte of RAM (or nibble?) for this
	Adjust scoring:
	    50 points for each tank killed plus combo system: for each tank killed before dying in the level, add 25 points.  So first tank is 50, second is 75, third is 100, etc.
	        Killing all tanks without dying means last tank is worth 525 points.
	    DONE Powerup that kills all tanks on screen - give 1000 points per tank killed 
	        STILL CONSIDERING (plus 500?)
	    DONE Bricks are worth 5 points during level, all remaining bricks are worth 10 pts each at end of level
	    DONE Level end worth 100xlevel
    fix scanline count
	Logic for when levels wrap .... not worried about this.
    MOSTLY DONE Tank shooting algorithm needs to be improved drastically, especially obvious at higher levels.
    DONE Tank movement algorithm could use tweaking, tanks still run into each other too often.
	DONE: Music?  Have a free channel but basically zero RAM left.  Could probably squeeze one byte of RAM out.
	DONE: Probably need to go to 8K.  Have about 1/2 a page left of ROM, and
		could free up some space by going through things with a fine-toothed comb, but ...
		it would be a big stretch even to get the bare minimum for a game in there.
		anything extra, like music, or a fancier title screen, or a more-complicated enemy-tank AI routine
		is going to require more space.  
	DONE BUT NEEDS TO BE FINE-TUNED Biggest thing at this point is figure out ramping difficulty
		IDEAS:
			DONE faster tanks at higher levels
			IN PROGRESS more frequent shooting by enemy tanks.  Possibly too frequent at higher levels.  Look at this.
			DONE more aggressive tank movement routines 
			MOSTLY DONE smarter shooting by enemy tanks 
    DONE: Have player tank use different graphic.  This is done but not sure how I feel about the actual graphic.
	DONE: Figure out better AI for tank movement/firing routines 
        Stole routines from Pac-Man.  Seems to work pretty well, want to make the player respawn delay longer, but counter bits are already maxed so may need to fiddle with code.
        Reason I have this here is because when player is dead the enemy tanks head for the base.  Maybe it's ok, at higher levels maybe they move fast enough that it will make a difference?
	DONE Title/splash screen?  
	DONE: tank:tank collisions	
	DECISION TO NOT DO THIS: OR NOT?  display player lives remaining
	DONE: don't give points for enemy tank actions
	DONE replace placeholder font
	IN PROGRESS: Graphics/colors (including changing colors (of tanks?  walls?) for different levels)
	PAL60 version
	2-player?  (unlikely but...)
	Other...?
	sound tweaking/improvements
	DONE: Game Over logic of some kind
	
	BUG KILLING!
	    FIXED: Game Over routine gets stuck and never finishes.... ???  Was due to pressing trigger (or RESET/SELECT) during game over routine,
	        which tried to sort of start a new game.  Fix is to not read trigger/console switches during game over routine
	    FIXED: Bullets are getting stuck off screen but not in BALLOFFSCREEN location and so enemy tanks stop shooting mid level.
	        seems to happen at higher levels, not sure of cause.  Think cause is when bullets are travelling down and hit BulletY==0 and 
	        BulletX is not set to zero also.
        Occasionally (cause?) a tank respawns when it shouldn't.  Haven't seen this in a while, need to confirm this is an issue still.
        Tanks kill each other often when entering the screen.  Need to see if this can be fixed.  More urgent now that dead tank graphic stays on screen and will kill the entering tank.
		scanline count is wonky, need to tighten up various subroutines that take too long
	    FIXED: remove bullets from screen during level transitions
        FIXED: Tanks still firing when offscreen.  
            UPDATE: I think this is when tank 3 shoots downward a "ghost" shot occurs from offscreen. 
            UPDATE UPDATE: that was incorrect, it was due to out-of-bounds conditions not being checked properly when bullets move downward
        FIXED FOR REALS NOW I THINK.  !!NOT FIXED!! FIXED AGAIN I THINK: FIXED I THINK: Tanks can reverse before fully entering the maze and go back out (this happens at AISWITCH reversals)
            Final fix 11.8.2023 - had branch with opposite condition, oops - so tanks ONLY reversed if they were offscreen.
        
        FIXED I THINK: Also not exactly a bug (??) but tanks still run into each other a lot.  This is fixed EXCEPT for when tanks enter the screen.
        FIXED: Also not exactly a bug (??) but tank shooting needs to be improved.
        FIXED: Tanks get "stuck" for too long - appears to happen when tank movement is not allowed (correctly) due to presence of other tanks,
            but when other tank dies, movement doesn't happen as quickly as it seems like it should.
        MAYBE FIXED: Possible for tanks to get stuck in this situation: (W=wall, T=tank):
            WW W
            WT W
            WWTW
            WWWW
            and neither tank can move because a tank is in the way.
                preferred solution: force tanks that don't move for more than 1/2 second to shoot (in a random direction?) to blast out a wall.
                alternative solution: have tanks that don't move for more than 1/2 second to die.
                problem is that either of those solutions require some kind of counter for "tank stuck"  
                I do have probably one free byte of RAM I could use but ... 
                IMPLEMENTED THIS: Actually, it probably wouldn't be too difficult to fire a bullet from a tank that isn't moving.  They fire immediately,
                    and just whichever direction they are facing.  Depending, this may not suffice to free them.  
	
  Notes from ZeroPage livestream on 9/1:
      FIXED KINDA: screen rolls are way more frequent than I thought, ugh.  Need to work on that.  Note: Seem to have stabilized it at 272 scanlines by increasing Overscan timer setting
      if possible would like to speed up game play.
      FIXED: update spawn points to force player to move from bottom of screen ...
      FIXED: found bug that you can shoot tanks before they are on the screen (!)
      need to make AI more aggressively chasing "base"
      DONE: probably need to finally implement the "game over" logic for when a tank gets the base	

*/


/*

        rando notes:
        if tank not at intersection, and bullet not on the screen, entire vblank takes 10 scanlines (before we jump to "kernel", which 
        has a bunch of stuff before it actually starts drawing the screen)
        
        takes ... 6 scanlines to get through "rotation" loop ... which is varying.
        
        another 2 scanlines to set up graphics pointers for tanks
        another 2 scanlines to set up score pointers
        
        and then that's the end of the actual vblank.  seems like approx best case scenario is we have something like 15 extra scanlines.
        
        
        next frame, tank is at intersection -
         9 scanlines to check for wall (!!!!)  this is probably the biggest thing
         5 scanlines to check for enemy tank (this has been reduced to 1-3 I think)
         1 scanline for "ChooseTankDirection"
         1 scanline for "EliminateDiagonal..."
        
        we are at scanline 20 (almost) when we get to TankMovementSubroutine
        
        at scanline #21 when we reach the end (currently drops through to see if player wants to shoot)
        
        finally done with enemy tank movement at scanline #22 (halfway through)
        
        bullet is onscreen this time ...so takes 4 scanlines to move bullet
        
        
        SoundSubroutine - 3 scanlines
        ReadConsoleSwitch... - if nothing pressed, back in half a scanline
        
        so tank is at intersection, bullet on screen means vblank  takes 29 scanlines (before we jump to kernel)
        


*/

DEBUGNOENEMYBULLETS = 0 ;enemies cannot shoot
DEBUGMAZE = 0           ;makes entire top row blank and 2nd row solid so tanks are confined up there.
DEBUGPFPRIORITY = 0     ;leaves objects with priority over the playfield so can see where enemies respawn
DEBUGTANKAICOUNTER = 0  ;if this is set, the top 4 bits of TankMovementCounter are set to the brightness of the maze walls

	processor 6502
	include vcs.h
	include macro.h

;-----------------------MY MACROS-----------------------------------------


;--this macro aligns at page boundary (only if needed) and echoes the bytes used
    MAC PAGEALIGN
        if <* != 0
        	echo "---Page aligned -", ((* & $FF00) + $100) - *, "bytes left at PAGEALIGN", [{1}]d, "at location", *
    	    align 256
    	else
    	    echo "---Page aligned - 0$ bytes left at PAGEALIGN", [{1}]d, "at location", *
        endif
    ENDM
	
    SUBROUTINE
    MAC ALIGNGFXDATA
.marker set *
        ds DATASPACEBEFOREGFX - (* & $FF)
        ECHO "---Aligned graphics data.", (*-.marker), "bytes left at ALIGNGFXDATA", [{1}]d, "at location", .marker
    ENDM
        
;-------------------------Constants Below---------------------------------


VBLANK_TIMER = 44       ;--this jitters a bit at times.
OVERSCAN_TIMER = 31     ;--this seems to be fine 


TANKHEIGHT	=	7
BLOCKHEIGHT = 	7
ROWHEIGHT = 7
COLUMNWIDTH = 8
MAZEROWS	=	11
TANKAREAHEIGHT	=	BLOCKHEIGHT * MAZEROWS
MAZEAREAHEIGHT 	= 	TANKAREAHEIGHT
DATASPACEBEFOREGFX	=	MAZEAREAHEIGHT

;--MazeGenerationPass bits during a level (used to count player deaths and track powerups)
PLAYERDEATHCOUNTBITS        =   %00000111
PLAYERDEATHCOUNTMAX         =   7
POWERUPACTIVATEDBITS        =   %11000000       ;4 possible powerups?
POWERUPCOUNTDOWNBITS        =   %00111000       ;number of enemies to be killed without any deaths to activate a powerup

;--TankStatus bits
TANKDIRECTION   =   %11110000       ;these 4 bits are used similarly to the joystick bits from INPT4
TANKSPEED       =   %00001110       ;ASL ASL ASL ASL ORA #$1F and then added to TankFractional
TANKRESPAWNWAIT =   %00001110       ;shares bits with speed
TANKINPLAY      =   %00000001       ;this is set when tank has respawned and is coming on screen or fully on screen.  cleared when tank is dead and/or still waiting to be respawned.


    ;--TANKINPLAY cleared and direction = TANKUP means explosion graphic
    ;--TANKINPLAY cleared and direction != TANKUP means offscreen waiting to respawn
     

TANKRIGHT		=	J0RIGHT         ;%10000000
TANKLEFT		=	J0LEFT          ;%01000000
TANKDOWN		=	J0DOWN          ;%00100000
TANKUP			=	J0UP            ;%00010000


;

    ;delay uses TANKRESPAWNWAIT bits (%00001110) so these values have to be even numbers between 2 and 14
ENEMYTANK1DELAY	=	6       ;# of frames of delay is x 4
ENEMYTANK2DELAY	=	10
ENEMYTANK3DELAY	=	14

TANKDEADWAIT   =   2
TANKDEADWAITPLAYER  =   8

PLAYERRESPAWNDELAY = 14
PLAYERINITIALDELAY  =   0

; STARTINGENEMYTANKCOUNT	=	 20 ;--no longer used


LEVELENDTANKSPEEDBOOST  =   4   ;when <= 3 tanks remaining, all on-screen tanks have speed boost applied immediately.

TANKONSCREENLEFT    =   16
TANKONSCREENRIGHT   =   136
TANKONSCREENTOP     =   MAZEAREAHEIGHT

FIRSTCOLUMNX    =   16

POWERUPSCOREBONUS   =   $1000

;--constants for game over routine
;--TankMovementCounter is reused for this routine
WALLDONEFLASHING = %10000000
GAMEOVERWAITBITS = %01111111

GAMEOVERWAIT    =   65 ;number of frames/4, can only use bottom 7 bits (0-127)
GAMEOVERSOUND   =   BUZZSOUND
GAMEOVERVOLUME  =   7
GAMEOVERSTARTFREQ   =   5
    
;--some constants used by the tank AI routine
TANKAISWITCH	=	64              ;--when TankMovementCounter (updated every 4 frames) is less than this number, the enemy tanks go into "scatter" mode and head for static locations
                                    ;set to zero for no scatter mode (tanks will still reverse direction when TankMovementCounter hits zero)
CLYDEDISTANCE   =   30              ;8 tiles in Pac-Man, equivalent in Minotaur is 4 tiles.  In pixels (with tile-width approx 7.5 pixels) is 30
PINKYADJUSTMENTX    =   16          ;4 tiles in Pac-Man, equivalent in Minotaur is 2 tiles... I think.  In pixels X = 16.
PINKYADJUSTMENTY    =   14          ; in pixels Y = 14


;--tank starting locations
PLAYERSTARTINGX	=	8
PLAYERSTARTINGY =   TANKHEIGHT+1

ENEMY01STARTINGX	=	24
ENEMY02STARTINGX	=	112
ENEMY11STARTINGX	=	64
ENEMY12STARTINGX	=	88
ENEMY21STARTINGX	=	128
ENEMY22STARTINGX	=	40

ENEMY0STARTINGX2	=	144
ENEMY1STARTINGX2	=	144
ENEMY2STARTINGX2	=	144
ENEMY0STARTINGX3	=	8
ENEMY1STARTINGX3	=	8
ENEMY2STARTINGX3	=	8

TANKOFFSCREEN	=	127

ENEMYSTARTINGYTOP = MAZEAREAHEIGHT+TANKHEIGHT
ENEMYSTARTINGYHIGHROW = 9
ENEMYSTARTINGYHIGH = (BLOCKHEIGHT * ENEMYSTARTINGYHIGHROW) + 1
ENEMYSTARTINGYHIGHMIDROW = 8
ENEMYSTARTINGYHIGHMID = (BLOCKHEIGHT * ENEMYSTARTINGYHIGHMIDROW) + 1
ENEMYSTARTINGYMIDHIGHROW = 7
ENEMYSTARTINGYMIDHIGH = (BLOCKHEIGHT * ENEMYSTARTINGYMIDHIGHROW) + 1
ENEMYSTARTINGYMIDROW = 5
ENEMYSTARTINGYMID = (BLOCKHEIGHT * ENEMYSTARTINGYMIDROW) + 1
ENEMYSTARTINGYMIDLOWROW = 4
ENEMYSTARTINGYMIDLOW = (BLOCKHEIGHT * ENEMYSTARTINGYMIDLOWROW) + 1
ENEMYSTARTINGYLOWROW = 3
ENEMYSTARTINGYLOW	=	(BLOCKHEIGHT * ENEMYSTARTINGYLOWROW) + 1



MAZEGENERATIONPASSES = MAZEROWS/2-1


;--tank speed constants
;--the way these are used:
;   tank speed is in lower nibble (these bits: %00001110)
;   the speed is shifted into the upper nibble (<<<<), ORAd with %00011111,
;   and then added to TankFractional,X.  When TankFractional,X wraps, Tank 
;   position (TankX,X or TankY,X) is updated.
;   So, speed of 14 (%00001110) which is the highest, will *almost* wrap every time
;   and the Tank will basically move 1 pixel per update.  Which brings us to...
;   Player tank is moved every frame, but enemy tanks are moved every four frames.
;   Which means approximate speed ranges are as follows:
;               Player tank         Enemy tanks
;   TANKSPEED0  1 px / 8 frames     1 px / 32 frames
;   TANKSPEED2  1 px / 4 frames     1 px / 16 frames
;   TANKSPEED4  1 px / 2.7 frames   1 px / 10.7 frames
;   TANKSPEED6  1 px / 2 frames     1 px / 8 frames
;   TANKSPEED8  1 px / 1.6 frames   1 px / 6.4 frames
;   TANKSPEED14 1 px / 1 frame      1 px / 4 frames
PLAYERTANKSPEED	    =   TANKSPEED2|1     
ENEMYTANKBASESPEED0 =   TANKSPEED8
ENEMYTANKBASESPEED1 = 	TANKSPEED8
ENEMYTANKBASESPEED2 =   TANKSPEED8
SPEEDBONUS          =   2
;--SOUND CONSTANTS
;   indexes into lookup table for sound effects
BRICKSOUND              =   0
BULLETSOUND             =   1
ENEMYTANKSOUND          =   2
SHORTBRICKSOUND         =   3
LONGEXPLOSIONSOUND      =   4
ENEMYBULLETSOUND        =   5
WALLSOUND               =   6
PLAYERTANKENGINESOUND   =   7
SCORESOUND              =   8

PLAYERTANKVOLUME	=	8


PLAYERTANKENGINEFREQ	=	8;31
PLAYERTANKENGINETONE	=	2;ENGINESOUND
PLAYERTANKENGINEVOLUME	=	3
PLAYERTANKENGINELENGTH  =   3

BULLETSOUNDTONE		=	ENGINESOUND
BULLETSOUNDFREQ		=	13
BULLETSOUNDLENGTH	=	12
ENEMYBULLETSOUNDTONE    =   BULLETSOUNDTONE
ENEMYBULLETSOUNDFREQ    =   17
ENEMYBULLETSOUNDLENGTH  =   BULLETSOUNDLENGTH
BRICKSOUNDTONE		=	NOISESOUND
BRICKSOUNDFREQ		=	20
BRICKSOUNDLENGTH	=	25
ENEMYTANKSOUNDTONE	=	NOISESOUND
ENEMYTANKSOUNDFREQ	=	30
ENEMYTANKSOUNDLENGTH	=	50
SHORTBRICKSOUNDTONE	=	BRICKSOUNDTONE
SHORTBRICKSOUNDFREQ	=	BRICKSOUNDFREQ
SHORTBRICKSOUNDLENGTH	=	7
LONGEXPLOSIONTONE	=	ENEMYTANKSOUNDTONE
LONGEXPLOSIONFREQ	=	18
LONGEXPLOSIONLENGTH	=	200
WALLSOUNDTONE       =   BUZZSOUND;SQUARESOUND
WALLSOUNDFREQ       =   10;8
WALLSOUNDLENGTH     =   8
SCORESOUNDTONE      =   SQUARESOUND
SCORESOUNDFREQ      =   20
SCORESOUNDLENGTH    =   4

;--music constants

;-note bits:
ARTICULATION_BIT	=	%00000001
VOLUME_BITS         =   %00001110
FREQUENCY_BITS      =   %11110000       ;--lookup into a table, probably.

VOLUME0     =   0
VOLUME2     =   2
VOLUME4     =   4
VOLUME6     =   6
VOLUME8     =   8
VOLUME10    =   10
VOLUME12    =   12
VOLUME14    =   14

SQUARE_19   =   $00
SQUARE_20   =   $10
SQUARE_23   =   $20
SQUARE_26   =   $30
SQUARE_31   =   $40

PATTERNEND  =   255

PERCUSSIONCUTOFF    =   3
PERCUSSIONVOLUME    =   VOLUME4

ARTICULATE      =   ARTICULATION_BIT

SNARESOUND	=	NOISESOUND
KICKSOUND	=	BUZZSOUND
HIHATSOUND	=	NOISESOUND
SNARE2SOUND	=	NOISESOUND

SNAREPITCH	=	6
KICKPITCH	=	30
HIHATPITCH	=	1
SNARE2PITCH	=	12



;--end SOUND CONSTANTS

WALLDESTRUCTIONSCORE    =   $0005
KILLTANKSCORE           =   $0050
LEVELENDBRICKSCORE      =   $0010

;--GameStatus flags

GAMEOFF			=	%10000000
GENERATINGMAZE	=	%01000000
LEVELCOMPLETE	=	%00100000
TITLESCREEN		=	%00010000
GAMEOVER		=	%00001000
DRAWBASE        =   %00000100

LEVELCOMPLETETIMER	=	$03


;--end GameStatus flags

BALLOFFSCREEN	=	0


BULLETRIGHT		=	0
BULLETLEFT		=	1
BULLETDOWN		=	2
BULLETUP		=	3
BULLETCLEAR		=	3

TRIGGERDEBOUNCEVALUE = 15
TRIGGERDEBOUNCEFLAG =   %10000000
CONSOLEDEBOUNCEFLAG	=	%01000000
ENEMYDEBOUNCEBITS =     %00011111


BULLETSPEEDHOR		=		1
BULLETSPEEDVER		=		1
BULLETFRACTIONALPERCENT =   87
BULLETFRACTIONALSPEED   =   256/100*BULLETFRACTIONALPERCENT  ;slowing bullets down slightly so the collision detection works better

BASECOLOR		    =		GOLD
SCORECOLOR          =       GRAY|$C
WALLCOLOR			=		RED|$6
TANKSREMAININGCOLOR =   TURQUOISE|$A

;--old colors: GOLD|A and BLUE2|C

TANKCOLOR1          =    GOLD|$6
TANKCOLOR2          =    BLUE2|$C
TANKCOLOR3          =    RED|$4
TANKCOLOR4          =    BROWN|$4

;--used by maze generation algorithm
MAZEPATHCUTOFF	=	100

TANKSPEED0  =   0
TANKSPEED1	=	1
TANKSPEED2	=	2
TANKSPEED3	=	3
TANKSPEED4	=	4
TANKSPEED5	=	5
TANKSPEED6	=	6
TANKSPEED7	=	7
TANKSPEED8	=	8
TANKSPEED9	=	9
TANKSPEED10	=	10
TANKSPEED11	=	11
TANKSPEED12	=	12
TANKSPEED13	=	13
TANKSPEED14	=	14
TANKSPEED15	=	15
;-------------------------COLOR CONSTANTS (NTSC)--------------------------

GRAY		=	$00
GOLD		=	$10
ORANGE		=	$20
BURNTORANGE	=	$30
RED		=	$40
PURPLE		=	$50
PURPLEBLUE	=	$60
BLUE		=	$70
BLUE2		=	$80
LIGHTBLUE	=	$90
TURQUOISE	=	$A0
GREEN		=	$B0
BROWNGREEN	=	$C0
TANGREEN	=	$D0
TAN		=	$E0
BROWN		=	$F0

;--------------------------TIA CONSTANTS----------------------------------

	;--NUSIZx CONSTANTS
	;	player:
ONECOPYNORMAL		=	$00
TWOCOPIESCLOSE		=	$01
TWOCOPIESMED		=	$02
THREECOPIESCLOSE	=	$03
TWOCOPIESWIDE		=	$04
ONECOPYDOUBLE		=	$05
THREECOPIESMED		=	$06
ONECOPYQUAD		=	$07
	;	missile:
SINGLEWIDTHMISSILE	=	$00
DOUBLEWIDTHMISSILE	=	$10
QUADWIDTHMISSILE	=	$20
OCTWIDTHMISSILE		=	$30

	;---CTRLPF CONSTANTS
	;	playfield:
REFLECTEDPF		=	%00000001
SCOREPF			=	%00000010
PRIORITYPF		=	%00000100
	;	ball:
SINGLEWIDTHBALL		=	SINGLEWIDTHMISSILE
DOUBLEWIDTHBALL		=	DOUBLEWIDTHMISSILE
QUADWIDTHBALL		=	QUADWIDTHMISSILE
OCTWIDTHBALL		=	OCTWIDTHMISSILE

	;---HMxx CONSTANTS
LEFTSEVEN		=	$70
LEFTSIX			=	$60
LEFTFIVE		=	$50
LEFTFOUR		=	$40
LEFTTHREE		=	$30
LEFTTWO			=	$20
LEFTONE			=	$10
NOMOVEMENT		=	$00
RIGHTONE		=	$F0
RIGHTTWO		=	$E0
RIGHTTHREE		=	$D0
RIGHTFOUR		=	$C0
RIGHTFIVE		=	$B0
RIGHTSIX		=	$A0
RIGHTSEVEN		=	$90
RIGHTEIGHT		=	$80

	;---AUDCx CONSTANTS (P Slocum's naming convention)
SAWSOUND		=	1
ENGINESOUND		=	3
SQUARESOUND		=	4
BASSSOUND		=	6
PITFALLSOUND		=	7
NOISESOUND		=	8
LEADSOUND		=	12
BUZZSOUND		=	15

	;---SWCHA CONSTANTS (JOYSTICK)
J0RIGHT		=	%10000000
J0LEFT		=	%01000000
J0DOWN		=	%00100000
J0UP		=	%00010000
J1RIGHT		=	%00001000
J1LEFT		=	%00000100
J1DOWN		=	%00000010
J1UP		=	%00000001

	;---SWCHB CONSTANTS (CONSOLE SWITCHES)
P1DIFF		=	%10000000
P0DIFF		=	%01000000
BWCOLOR		=	%00001000
SELECT		=	%00000010
RESET		=	%00000001




;-------------------------End Constants-----------------------------------

;---Macros

	MAC FILLER
		REPEAT {1}
		.byte {2}
		REPEND
	ENDM
	
	

;--------Variables To Follow-------------

	SEG.U Variables
   	org $80

FrameCounter ds 1
TankMovementCounter ds 1
RandomNumber ds 1
RandomNumberSaved ds 1  ;used to save the random number for more than one frame

MazeNumber ds 1
MazeGenerationPass ds 1
GameStatus ds 1
Score ds 3
TanksRemaining ds 1

Channel1Decay ds 1

Debounce ds 1


TankX ds 4
TankY ds 4
TankStatus ds 4

TankFractional ds 4

BulletX ds 4
BulletY ds 4
BulletDirection ds 1
BulletFractional ds 1

PlayerX ds 2
MissileX ds 2
BallX ds 1

PlayerY ds 2
MissileY ds 2
BallY ds 1   	

MissileHeight ds 2
BallHeight ds 1
Player0Bottom ds 1
PlayerYTemp ds 1
MissileYTemp ds 2
BallYTemp ds 1
Player0Top ds 1


Player0Ptr ds 4
Player1Ptr ds 4


PF1Left ds MAZEROWS-1
PF2Left ds MAZEROWS-1
PF2Right ds MAZEROWS-1
PF1Right ds MAZEROWS-1
LastRowL ds 1
LastRowR ds 1

SongIndex ds 1

Temp ds 4
MiscPtr 
ScorePtr ds 12


   ; Display Remaining RAM
   echo "----",($100 - *) , "bytes left (ZP RAM)"
;---End Variables

	seg Bank0

	org $1000
	rorg $1000

Start
;	sta $1FF8
    nop
    nop
    nop
    CLEAN_START

;--Some Initial Setup


	jsr InitialSetupSubroutine

		
	
;	lda #BASECOLOR
;	sta BaseColor

;----------------------------------------------------------------------------
;--------------------GAME MAIN LOOP------------------------------------------
;----------------------------------------------------------------------------
; MainGameLoop
; 
; 	jsr VBLANKRoutine
; 	brk
; 	.word KernelRoutineGame
; 	jsr OverscanRoutine
; 	jmp MainGameLoop



	


;----------------------------------------------------------------------------
;-------------------VBLANK Routine-------------------------------------------
;----------------------------------------------------------------------------
VBLANKRoutine
    lda #%00001111
VSYNCWaitLoop2
    sta WSYNC
    sta VSYNC
    lsr
    bne VSYNCWaitLoop2      ;different version of this loop
    
    

	lda #VBLANK_TIMER
	sta TIM64T
	

	
	
	dec FrameCounter
	
	lda GameStatus
	and #GAMEOFF|LEVELCOMPLETE|GAMEOVER
	beq GameOnVBLANK	
	and #GAMEOFF
	beq InBetweenLevels
	lda GameStatus
	and #GENERATINGMAZE|GAMEOVER
	bne GameAlreadyStarted
	;--if game not on and NOT generating a level and NOT in game over routine already read joystick button to start game
	lda INPT4
	bmi NoTriggerToStartGameClearTriggerDebounce
	;--trigger IS pressed, now check debounce
	lda Debounce
	and #TRIGGERDEBOUNCEFLAG
	bne TriggerNotDebouncedYet
    ;--set trigger debounce and then start new game
    lda Debounce
    ora #TRIGGERDEBOUNCEFLAG
    sta Debounce
	
	lda #0
	sta MazeNumber
	jsr StartNewGame
	jmp DoneStartingNewGameWithTrigger
NoTriggerToStartGameClearTriggerDebounce
    lda Debounce
    and #~TRIGGERDEBOUNCEFLAG
    sta Debounce
TriggerNotDebouncedYet
DoneStartingNewGameWithTrigger

	jmp GameNotOnVBLANK
GameOnVBLANK
	jsr MoveEnemyTanksSubroutine
	brk
	.word MoveBulletSubroutine
GameAlreadyStarted
GameNotOnVBLANK
InBetweenLevels
; 	;--keep playing sound even when game not on
; 	jsr SoundSubroutine
; 	
; 	jsr UpdateRandomNumber  ;--once per frame

    lda GameStatus
    and #GENERATINGMAZE|GAMEOVER
    bne DoNotReadConsoleSwitchesWhileGeneratingMaze ;also not while game over routine is running
	jsr ReadConsoleSwitchesSubroutine
DoNotReadConsoleSwitchesWhileGeneratingMaze





	brk
	.word KernelRoutineGame
	
	
;----------------------------------------------------------------------------
;------------------------Overscan Routine------------------------------------
;----------------------------------------------------------------------------
OverscanRoutine

	ldy #2
	sty WSYNC
	sty VBLANK
	lda #OVERSCAN_TIMER
	sta TIM64T
	
	;--keep playing sound even when game not on
	jsr SoundSubroutine
	
	jsr UpdateRandomNumber  ;--once per frame

	lda GameStatus
	and #GAMEOVER
	beq GameNotOver
	;--if game is over, do some stuff
	lda TankMovementCounter
	and #WALLDONEFLASHING
	bne DoneMakingWallsFlash
	;--play some sound?
	lda TankMovementCounter
	lsr
	lsr
; 	sta Temp
; 	lda #31
; 	sec
; 	sbc Temp
	sta AUDF1
	lda #GAMEOVERSOUND
	sta AUDC1
	lda #GAMEOVERVOLUME
	sta AUDV1
	inc TankMovementCounter ;used to make walls flash
	;--now need to see if we have just finished flashing
	lda TankMovementCounter
	and #WALLDONEFLASHING
	beq WallsStillFlashing  ;branch always
    ;--walls done flashing:
    ;   remove tanks from screen
    ;   wait a bit, and then go back to title screen routine
	jsr MoveAllTanksOffScreenSubroutine
    ldx #3
    lda #0
RemoveBulletsFromScreenGameOverLoop
	sta BulletX,X
	sta BulletY,X
	dex
	bpl RemoveBulletsFromScreenGameOverLoop
	;   reuse TankMovementCounter as a wait counter
	lda #WALLDONEFLASHING|GAMEOVERWAIT
	sta TankMovementCounter
	lda #30
	sta AUDF1   ;--set freq back to 30 not 31
DoneMakingWallsFlash
    lda FrameCounter
    and #3
    bne GameOverRoutineStillGoing
    dec TankMovementCounter ;--decrement wait
	lda TankMovementCounter
	and #GAMEOVERWAITBITS
	beq GameOverRoutineDone
	;--still ongoing, so a little fiddling with the sound
	cmp #(GAMEOVERWAIT/4)*3
	bcs NoChangeToGameOverSound
	ldx #31
	stx AUDF1
	cmp #32
	bcs NoChangeToGameOverVolume
	cmp #24
	bcc NoChangeToGameOverVolume
	and #7
	sta AUDV1
	
	bcs GameOverRoutineStillGoing   ;branch always
	
GameOverRoutineDone
    ;to go back to title screen routine, need to:
    ;   update GameStatus bits
    ;   set MazeGenerationPass appropriately
    ;   clear the screen
	lda GameStatus
	and #~(GAMEOVER|DRAWBASE)      ;clear game over and draw base bits
	ora #TITLESCREEN    ;set title screen bit
	sta GameStatus
	lda #TitleGraphicsEnd-TitleGraphics-1
	sta MazeGenerationPass
	ldx #MAZEROWS-2
	lda #0
ClearMazeLoop
	sta PF1Left,X
	sta PF2Left,X
	sta PF2Right,X
	sta PF1Right,X
	dex 
	bpl ClearMazeLoop
	sta LastRowL
	sta LastRowR
	;--also turn off sound
; 	sta AUDV0
	sta TanksRemaining
	sta MazeNumber
GameOverRoutineStillGoing
NoChangeToGameOverVolume
NoChangeToGameOverSound
WallsStillFlashing
GameNotOver
	
	lda GameStatus
	and #GAMEOFF|LEVELCOMPLETE|GENERATINGMAZE
	bne GameNotOn	
	brk
	.word CollisionsSubroutine
	;--need to recheck, since a collision could have modified these flags
	lda GameStatus
	and #GAMEOFF|LEVELCOMPLETE|GENERATINGMAZE
	bne GameNotOn	
	jsr PlayerTankMovementRoutine
; 	brk
; 	.word MoveBulletSubroutine
	
	jsr PowerUpBonusRoutine

	
	
	
	jmp WaitForOverscanEnd
GameNotOn
	;--A still holds GameStatus AND #GAMEOFF|LEVELCOMPLETE|GENERATINGMAZE
	and #LEVELCOMPLETE
	bne .LevelComplete
	jmp .LevelNotComplete
.LevelComplete
	;--level complete
	;--wait until level-ending explosion sound is mostly died down
	lda Channel1Decay
	cmp #SCORESOUNDLENGTH
	bcc .LevelExplosionComplete
	jmp .LevelNotComplete
.LevelExplosionComplete
	;--move all tanks (and explosiong gfx) offscreen
	;--move tanks offscreen
	ldx #3
	ldy #0
	lda #ENEMYSTARTINGYTOP
MoveTanksOffScreenLoop
	sta TankX,X
	sty TankY,X
	dex
	bpl MoveTanksOffScreenLoop
    ;--and then remove one brick every 4 frames and give points for it, while playing a "bling" sound
	lda FrameCounter
	and #$3
	beq .RemoveBrick 
	jmp .LevelNotComplete
.RemoveBrick
	lda GameStatus
	and #LEVELCOMPLETETIMER
	cmp #LEVELCOMPLETETIMER
	bne ShortWaitUntilNextLevel
	;--but first!  give points for all bricks remaining.
	;--use RandomNumberSaved as counter.
	ldx RandomNumberSaved
	lda FrameCounter
	and #$30
	lsr
	lsr
	lsr
	lsr
	tay
FindPFWithBricks
	lda PF1Left,X
	bne FoundPFWithBricks
	inx
	cpx #(MAZEROWS-1)*4+2
	beq FoundAllBricks
	bne FindPFWithBricks    ;branch always
FoundPFWithBricks
	and PFMaskLookup,Y
	bne FoundBrick
	dey
	bpl FindPFWithBricks
	ldy #3
	bne FindPFWithBricks    ;branch always
FoundBrick
	;--clear the brick we just got points for
	lda PFMaskLookup,Y
	eor #$FF
	and PF1Left,X
	sta PF1Left,X
	;--play bling sound
    ldy #SCORESOUND
	jsr StartSoundSubroutine
	;--and get points
	lda #>LEVELENDBRICKSCORE
	sta Temp
	lda #<LEVELENDBRICKSCORE
	jsr IncreaseScoreSubroutineBank0
	jmp .LevelNotComplete
FoundAllBricks
    ;--remove base and give score for level
	;--play bling sound
    ldy #SCORESOUND
	jsr StartSoundSubroutine
	;--add levelx100 to score
	lda MazeNumber
	sta Temp
	lda #0
	jsr IncreaseScoreSubroutineBank0 

	;--remove base
    lda GameStatus
    and #~DRAWBASE
    sta GameStatus
	and #LEVELCOMPLETETIMER
ShortWaitUntilNextLevel
	tax
	dex
	bmi LevelCompleteNow
	lda GameStatus
	and #~LEVELCOMPLETETIMER
	sta GameStatus
	txa
	ora GameStatus
	sta GameStatus
	bne .LevelNotComplete
	
LevelCompleteNow
	lda GameStatus
	and #~(LEVELCOMPLETE|LEVELCOMPLETETIMER)
	sta GameStatus
	jsr StartNewLevel
.LevelNotComplete
	


	lda GameStatus
	and #GENERATINGMAZE
	beq NotGeneratingMaze
	lda FrameCounter
	and #7
	cmp #1
	bne NotGeneratingMaze
	brk
	.word GenerateMazeSubroutine
	ldy #SHORTBRICKSOUND
	jsr StartSoundSubroutine
NotGeneratingMaze
	lda GameStatus
	and #TITLESCREEN
	beq NotOnTitleScreen
	;--on title screen
	lda MazeGenerationPass
	bmi GameNotOnOverscan
	lda FrameCounter
	and #$7
	cmp #1
	bne WaitToDrawTitleScreen
	brk
	.word DrawTitleScreenSubroutine       ;moved this to bank 2
WaitToDrawTitleScreen
NotOnTitleScreen
GameNotOnOverscan

WaitForOverscanEnd
	lda INTIM
; 	bpl WaitForOverscanEnd
	bmi OverTimeOverscan
	cmp #1
	bne WaitForOverscanEnd
	beq EndOverscan
OverTimeOverscan
	nop
EndOverscan	
	
; 	sta WSYNC		;last line...I think?

; 	rts
	jmp VBLANKRoutine
	
;----------------------------------------------------------------------------
;----------------------------End Main Routines-------------------------------
;----------------------------------------------------------------------------

;****************************************************************************

;----------------------------------------------------------------------------
;----------------------Begin Functions---------------------------------------
;----------------------------------------------------------------------------



UpdateRandomNumber
    lda RandomNumber
    lsr
    bcc SkipEOR
    eor #$B2
SkipEOR
    sta RandomNumber
    rts
	
	
	
;----------------------------------------------------------------------------


ReadConsoleSwitchesSubroutine

	lda SWCHB
	lsr				;get RESET into carry
	bcc RESETPressed
	lsr
	bcc SELECTPressed
	;--switch not pressed, so reset debounce flag
	lda Debounce
	and #~CONSOLEDEBOUNCEFLAG
	sta Debounce
RESETNotReleased
DoneWithConsoleSwitches
	rts

 
	
RESETPressed
	lda Debounce
	and #CONSOLEDEBOUNCEFLAG
	bne RESETNotReleased
    lda #0
    sta MazeNumber
SELECTPressed
	lda Debounce
	and #CONSOLEDEBOUNCEFLAG
	bne RESETNotReleased
	lda Debounce
	ora #CONSOLEDEBOUNCEFLAG
	sta Debounce
	
StartNewGame	
	;--reset score here 
	lda #0
	ldx #3
	bne NewGameZeroLoopEntryPoint
NewGameZeroLoop
	sta Score,X
NewGameZeroLoopEntryPoint
    sta BulletX,X
    sta BulletY,X
    dex
    bpl NewGameZeroLoop
	
StartNewLevel
	;--start game
	lda GameStatus
	and #GENERATINGMAZE
	bne AlreadyStartingNewLevel
	lda GameStatus
	ora #GENERATINGMAZE	;--start generating maze
	and #~TITLESCREEN	;--turn off title screen
	sta GameStatus
	
MoveAllTanksOffScreenSubroutine     ;called from gameover routine
	;--move tanks off screen, immobilize 
	ldx #3
	ldy #0  ;no direction, no speed, and TANKINPLAY = 0
	lda #TANKOFFSCREEN
MoveTanksOffscreenLoop
	sta TankX,X
	sta TankY,X
 	sty TankStatus,X   
	dex
	bpl MoveTanksOffscreenLoop
	
	stx MazeGenerationPass
AlreadyStartingNewLevel	
	;--finally, cycle the random number
	jmp UpdateRandomNumber				;--return from subroutine there
	


	
;*******************************************************************

InitialSetupSubroutine

	lda #TANKOFFSCREEN
	ldx #3
SetUpTankInitialValues
	sta TankX,X
	sta TankY,X
	dex
	bpl SetUpTankInitialValues
	
	stx SongIndex       ;just need to set top bit here so music starts OFF
	
	sta RandomNumber        ;seed with non-zero number, using 127 (TANKOFFSCREEN) for now
	
	lda #GAMEOFF|TITLESCREEN
	sta GameStatus

	if DEBUGPFPRIORITY = 1
	    lda #REFLECTEDPF|DOUBLEWIDTHBALL
	else
	    lda #REFLECTEDPF|DOUBLEWIDTHBALL|PRIORITYPF
	endif    
	
	sta CTRLPF
	
	lda #TitleGraphicsEnd-TitleGraphics-1
	sta MazeGenerationPass
	
	
	rts
	
;****************************************************************************

;--X is index into which tank
;--X, Y position the tank is going to move towards is pushed on stack 
ChooseTankDirectionSubroutine
	lda #0
	pha						;we will save new direction on stack
	txa
	tay						;get tank index into Y so we can use X for stack ptr
	tsx
	lda $05,X				;X position we are aiming for
	cmp TankX,Y
	beq MoveTankOnYAxis		;if equal don't move tank horizontally
	lda #0
	rol						;get carry into A (carry set=tank is to the left of target, carry clear=tank to the right)
	tax
	lda TankDirection,X
	tsx
	sta $01,X				;save new horizontal direction
MoveTankOnYAxis
	lda $04,X				;Y position we are aiming for
	cmp TankY,Y
	beq NoVerticalTankMovement
	lda #0
	rol						;similar to horizontal movement, use carry as index into offset table
	tax
	lda TankDirection+2,X
	tsx
	ora $01,X				;ORA vertical direction into direction variable on stack
	sta $01,X
NoVerticalTankMovement
	tya
	tax						;get tank index back into X
	pla						;pull new tank direction off stack into A
	
	rts

;****************************************************************************	

FireEnemyBulletRoutine

    if DEBUGNOENEMYBULLETS = 1

        rts ;eliminate enemy firing for now

    endif    
    
; 	;--- only every ... variable # of frames
	lda Debounce    ;was EnemyDebounce
	and #ENEMYDEBOUNCEBITS
	beq FireEnemyBullet
	dec Debounce    ;was EnemyDebounce
	
	rts					;--and we're done
FireEnemyBullet
	ldx #1
FindAvailableEnemyBallLoop
	lda BulletX+2,X             ;enemy bullets are indexed at 2 & 3 (player bullets are indexed at 0 and 1)
; 	cmp #BALLOFFSCREEN          ;<--as of 9/27 this value is zero so we can skip the comparison
	beq FoundAvailableEnemyBall
	dex
	bpl FindAvailableEnemyBallLoop
	;bmi NoAvailableEnemyBalls  ;<--remove since we just exit immediately.  save 3 cycles (and 1 byte)
	rts
FoundAvailableEnemyBall
    ;fix X index (enemy bullets indexed at 2 & 3)
	inx
	inx
	;--shoot more often as levels increase
	ldy MazeNumber
    cpy #(EnemyBulletDebounceEnd-EnemyBulletDebounce)
    bcc MazeNumberLessThanBulletDebounceLimit
    ldy #(EnemyBulletDebounceEnd-EnemyBulletDebounce)
MazeNumberLessThanBulletDebounceLimit    
	lda Debounce    ;was EnemyDebounce
	and #~ENEMYDEBOUNCEBITS ;this probably isn't necessary, but being safe for now
    ora EnemyBulletDebounce-1,Y ;minus one because maze number starts at 1 (not zero)
	sta Debounce    ;was EnemyDebounce
	
	;--first, look for tank that is stuck (i.e., in play but not moving)
	ldy #3
FindStuckTank
    lda TankStatus,Y
    and #TANKSPEED|TANKINPLAY
    cmp #TANKINPLAY|TANKSPEED0
    beq FireEnemyBulletNow
    dey
    bne FindStuckTank
    ;--if no stuck tank, find random tank 
	lda RandomNumber
	and #3
	tay
    beq DoNotShoot  ;change so evenly random between tanks, fire less often (by 25%)
; 	bne ShootFromTank   ;zero is player, so if non-zero we are fine, otherwise shoot from tank 1
; 	iny				;this routine shoots from tank 1 half the time and tanks 2 and 3 a quarter of the time each
ShootFromTank
    ;--if tank is not in play, don't shoot from it
    lda TankStatus,Y
    and #TANKINPLAY
    beq TankNotInPlayCannotShoot
    ;--if tank offscreen, don't shoot from it
    lda TankX,Y
    cmp #16
    bcc TankOffscreenCannotShoot
    cmp #137
    bcs TankOffscreenCannotShoot
    lda TankY,Y
    cmp #MAZEAREAHEIGHT+2
    bcs TankOffscreenCannotShoot

    
    ;--what kind of logic can we use for shooting?
    ;-- how about - only allow horizontal firing if on bottom row (at base) or if player tank is within ... 3 rows?
    ;               and only allow vertical firing if in center two columns (at base) or if player tank is within ...3 columns?
    lda TankStatus,Y
    asl
    bcs EnemyShootingHorizontal
    asl
    bcs EnemyShootingHorizontal
    ;--else shooting vertical
    ;--is tank in center two columns? (X between 72 and 80)
TankShootingVertically
    lda TankX,Y
    cmp #72
    bcc EnemyNotInCenterColumns    
    cmp #80
    bcc FireEnemyBulletNow
EnemyNotInCenterColumns
    ;--now see if close to player tank
    clc
    adc #COLUMNWIDTH*3
    sec
    sbc TankX
    cmp #(COLUMNWIDTH*6)+1
    bcc FireEnemyBulletNow
    bcs EnemyNotAllowedToShootVertically    ;branch always
EnemyShootingHorizontal    
    lda TankY,Y
    cmp #ROWHEIGHT+1
    beq FireEnemyBulletNow
    clc
    adc #ROWHEIGHT*3
    sec
    sbc TankY
    cmp #(ROWHEIGHT*6)+1
    bcs EnemyNotAllowedToShootHorizontally

    ;%
;     lda TankStatus,Y
;     lsr     ;--get TANKINPLAY flag into carry
;     bcc TankOffscreenCannotShoot
FireEnemyBulletNow
	jsr FireBulletRoutine
	;--start enemy bullet sound
	ldy #ENEMYBULLETSOUND
	jsr StartSoundSubroutine
TankNotInPlayCannotShoot
TankOffscreenCannotShoot
NoAvailableEnemyBalls
EnemyNotAllowedToShootVertically
EnemyNotAllowedToShootHorizontally
DoNotShoot
	;--then we're done
	rts	
	
;****************************************************************************

    	
SetInitialEnemyTankSpeedRoutine
    ;--come in here with X pointing to tank # (1-3)
    ;--and A holding new direction (in upper four bits)
	sta TankStatus,X	;--first write new direction
	;--tank starting speed and add level, add speed boost based on how many tanks are left, then subtract tank number (0-2).  Whole thing is capped at 14
	;--first, convert level (MazeNumber) from BCD to binary so we can add it below
	lda MazeNumber
	and #$F0
	lsr
	lsr
	lsr
	lsr
	sta Temp
	asl
	asl
	adc Temp
	sta Temp
	lda MazeNumber
	and #$0F
	adc Temp    ;now A holds binary conversion of MazeNumber
	lsr
	lsr         ;divide by four for slower ramping of enemy tank speed (maximum speed for all four tanks not reached until level 32)
	clc
	adc NewTankSpeed,X
	;--increase speed depending on tanks remaining
    ldy TanksRemaining
    adc TanksRemainingSpeedBoost,Y
	cmp #15
	bcc NewSpeedNotTooHigh
	lda #TANKSPEED14
	bne SetNewEnemyTankSpeed
	
NewSpeedNotTooHigh
	sta Temp
	;convert X's range (1-3) to (0-2)
	txa
	sec
	sbc #1
	;make X negative
	eor #$FF
	clc
	adc #1
	;add -(X-1) to the new speed and set.
	clc
	adc Temp
SetNewEnemyTankSpeed
    and #TANKSPEED      ;make sure only the bits we want
    ora #TANKINPLAY     ;tank in action now so set bit
	ora TankStatus,X
	sta TankStatus,X
	
	rts
	
	
;****************************************************************************
	
	


	
;****************************************************************************

MoveEnemyTanksSubroutine

	;	can't move all 3 enemies every frame, takes too long.
	;	So instead move one per frame (moving none every 4th frame - this is when we fire a bullet)
	;	Works well enough for now, work on optimizing this routine later

	lda FrameCounter
	and #3
	bne MoveAnEnemyTank
	inc TankMovementCounter     ;tank movement counter incremented every four frames
	;--if we ain't moving a tank, let's shoot a bullet
	jmp FireEnemyBulletRoutine

MoveAnEnemyTank
	tax ;index into which tank

	lda TankStatus,X
	and #TANKINPLAY	
	beq TankNotInPlay
	jmp TankOnscreenMoveIt 
TankNotInPlay
	;--first - is the tank dead and onscreen?  if so, check it's wait and move it offscreen
	lda TankStatus,X
	and #TANKDIRECTION  ;--if pointing UP, then it is still onscreen
	cmp #TANKUP|TANKDOWN    ;tank up AND tank down means powerup displaying on screen
	beq TankIsActuallyPowerup   ;--actually, any direction means still onscreen
	cmp #TANKUP             ;tank up only means explosion displaying on screen
	bne  TankOffScreen

	;--tank is onscreen but dead and sitting there.
	;   Decrement the wait, once it is done then move it offscreen
	lda TankMovementCounter         ;tank movement counter .... this has effect of multiplying the delay (ranging from 4-60 frames) by 8
	and #$07
	bne DoNotMoveTankOffscreenYet
	lda TankStatus,X
	and #$0F
; 	sec         ;I think this is set already after CMP and failed BNE branch above above
	sbc #2
	ora #TANKUP
	sta TankStatus,X
	bpl DoNotMoveTankOffscreenYet	
	;--move tank offscreen
	brk 
	.word TankRespawnRoutineWrapperEnemy
DoNotMoveTankOffscreenYet
TankIsActuallyPowerup       ;if tank is powerup, we don't do anything.  nothing happens until it is gathered or shot.  (at least for now, maybe later we wait and then remove)
    rts
TankOffScreen
	;tank offscreen
	;--only bring tank onscreen if there are enemy tanks remaining
	;--how many tanks onscreen?
	lda #0  ;---A is zero already following BNE above
	sta Temp    ;using this to count how many tanks onscreen
	ldy #3
CountTanksOnScreenLoop
	lda TankStatus,Y
	and #TANKINPLAY    ;--if tank has no direction set, it is offscreen and waiting to be respawned, and lower 4 bits hold wait counter until it is brought back onscreen
	beq TankNotOnscreen
	inc Temp
TankNotOnscreen
	dey
	bne CountTanksOnScreenLoop
	;--now compare with tanks remaining	
	lda Temp
	cmp TanksRemaining
	bcs DoNotBringTankOnscreenYet
	lda TankMovementCounter         ;tank movement counter .... this has effect of multiplying the delay (ranging from 4-60 frames) by 8
	and #7;
	bne DoNotBringTankOnscreenYet
	lda TankStatus,X
; 	sec             ;carry clear after not-taken BCS branch above
	sbc #1          ;so we are actually subtracting 2 here
	sta TankStatus,X
; 	dec TankStatus,X
	bpl DoNotBringTankOnscreenYet
	;--wait counter has expired, so bring this tank on screen
	; if tank off left edge of screen, move right.  if off right edge of screen, move left.  otherwise, move down
	lda TankX,X
	cmp #16
	bpl TankNotOffLeftEdge
	lda #J0RIGHT
	bne SetInitialEnemyTankSpeed
TankNotOffLeftEdge
	cmp #140
	bmi TankNotOffRightEdge
	lda #J0LEFT
	bne SetInitialEnemyTankSpeed	;branch always
TankNotOffRightEdge
	lda #J0DOWN

SetInitialEnemyTankSpeed
	jsr SetInitialEnemyTankSpeedRoutine     ;this also sets TANKINPLAY bit
	
	;--set tank fractional so it moves immediately and doesn't turn before it gets onscreen
 	lda #255
 	sta TankFractional,X
DoNotBringTankOnscreenYet
	rts

PlayerTankMovementRoutine
    ;--first, if TANKINPLAY is cleared, we wait
    lda TankStatus
    and #TANKINPLAY
    beq WaitForPlayerExplosion
	;--if tank off left edge of screen, we don't read joystick, we just wait (??) and then move it on to the maze from the left
	lda TankX
	cmp #16
	bcs PlayerTankOnscreenMoveIt
	;--wait only if TankX == 8
	cmp #8
	bne DoneWaitingBringPlayerTankOnScreen
WaitForPlayerExplosion
	lda TankStatus
	and #TANKRESPAWNWAIT
	beq FinishedWaitingPlayerDelay
	;--else still waiting
	;--update counter every 8 frames
	lda FrameCounter
	and #31         ;--make wait longer for tank to respawn
	bne WaitToUpdateRespawnCounter
	lda TankStatus
	sec
	sbc #2
	sta TankStatus
WaitToUpdateRespawnCounter
	rts
FinishedWaitingPlayerDelay
    ;--now figure out what we are waiting for.  if explosion, call respawn routine.
    ;   if not, we start moving tank.
    lda TankStatus
    and #TANKUP ;if tank is facing up, then is explosion and still onscreen
    beq DoneWaitingBringPlayerTankOnScreen
	brk 
	.word TankRespawnRoutineWrapperPlayer
	rts
	;--set player to move immediately 
	lda #255
	sta TankFractional
DoneWaitingBringPlayerTankOnScreen
 	lda #0		
	pha			;movement flag
	lda #~J0RIGHT
	jmp SkipReadingControllers
PlayerTankOnscreenMoveIt
    ldx #0	
TankOnscreenMoveIt
	;--plan for now:  every time enemy tank hits intersection, change direction
	;push X, Y target for tank onto stack and then call ChooseTankDirectionSubroutine
	;--intersection means X mod 8 = 0 and Y mod 7 = 0
	lda TankX,X
	and #$07
	beq AtIntersectionX
	cpx #0      ;check if enemy tank
	beq PlayerTankDoesNotReverse
EnemyTankPossibleReversal
	;--new thing.  when TankMovementCounter = 0 (i.e., switching from regular to "scatter" mode) make tanks switch direction if they are NOT at an intersection ONLY
	lda TankMovementCounter
	bne NoTankReversal
TankReverseDirection
    ;--only reverse if tank is fully on screen
    jsr IsTankOnScreenBank0
    beq NoTankReversal
	lda TankStatus,X
	lsr
	lsr
	lsr
	lsr
	tay
	lda PreventReverses,Y
	eor #$FF
	sta Temp
	lda TankStatus,X
	and #~TANKDIRECTION
	ora Temp
	sta TankStatus,X
PlayerTankDoesNotReverse
NoTankReversal	
	jmp NotAtIntersection
AtIntersectionX
	lda TankY,X
	sec
	sbc #1
	
	
	;--could use giant table instead.... 
	;got this here: https://forums.nesdev.org/viewtopic.php?f=2&t=11336
	;	post gives credit to December '84 Apple Assembly Line
	;--constant cycle count divide by 7 !!!!
	;	if BLOCKHEIGHT is changed from 7, this routine will need to be updated
; 	sta Temp+1 ;save for below --- necessary?  yes.
; 	sta Temp
; 	lsr
; 	lsr
; 	lsr
; 	adc Temp
; 	ror
; 	lsr
; 	lsr
; 	adc Temp
; 	ror
; 	lsr
; 	lsr         ;+30
; 	
; 	;--need modulo BLOCKHEIGHT (=7)
; 	;	so now multiply by 7 
;     ;       new routine x * 7 = x * 4 + x + x + x
;     sta Temp
;     asl
;     asl
;     adc Temp
;     adc Temp
;     adc Temp
;     sta Temp    ;+19 uses one byte RAM
; 	;--now subtract from original number (all we care is if modulo = 0 or not)
; 	sec
; 	sbc Temp+1  ;+5

    ;--old routine (above) takes a flat 54 cycles.  
       ;    30 cycles to divide by 7 (throwing away remainder)
       ;    19 cycles to multiply by 7, 
       ;     5 cycles to subtract the original number, then test for zero (=evenly divisible by seven)
    ;--new routine is varying but worst case for the range we have (1-84) is 52 (when Tank Y = 81).  And mostly is much less.
    ;---if enter this with A = 0 it will get stuck in an endless loop
    ;   created this routine myself based on the top answer here: https://math.stackexchange.com/questions/2228122/general-rule-to-determine-if-a-binary-number-is-divisible-by-a-generic-number 
    ;       basic outline is:
    ;       say our starting number is n
    ;       write n as 2k + j (where j is the final binary digit), so n=2k+j
    ;       subtract 7j from both sides: n-7j=2k-6j  
    ;       if we assume n is divisible by 7, and obviously 7j is divisible by 7, then the right side is also divisible by 7, or
    ;       2k-6j is divisible by seven
    ;       this simplifies to 2(k-3j), since 2 and 7 are relative primes, we now know that k-3j is divisible by seven IF n is divisible by seven.
    ;       so test this repeatedly:
    ;           k = n>>1 and 3j = 0 (if n is even) or 3 (if n is odd)

; EvenlyDivisibleBySevenLoop
;     lsr                             ;k=n>>1
;     bcc EvenlyDivisibleBySevenLoop  ;if n was odd (carry clear) we subtract zero
;     sbc #3                          ;if n was even (carry set) we subtract three
;     bcc NotEvenlyDivisibleBySeven   ;if we end up with a negative number, then it is not evenly divisible by 7
;     bne EvenlyDivisibleBySevenLoop  ;if we end up with a positive non-zero number, then repeat
; 	beq AtIntersectionY             ;if we end up with zero, then it is evenly divisible by 7
; NotEvenlyDivisibleBySeven

    ;--new new routine is a binary search.  Worst case is 27 cycles, best is 5.
    cmp #ROWHEIGHT*6        ;middle value
    beq AtIntersectionY     ;                   best case, 5 cycles
    bcc Lower1
    cmp #ROWHEIGHT*9
    beq AtIntersectionY
    bcc Lower2
    cmp #ROWHEIGHT*11
    beq AtIntersectionY
    cmp #ROWHEIGHT*10
    beq AtIntersectionY
    cmp #ROWHEIGHT*12
    beq AtIntersectionY
    bne NotAtIntersectionY      ;branch always 
Lower2
    cmp #ROWHEIGHT*8
    beq AtIntersectionY
    cmp #ROWHEIGHT*7
    beq AtIntersectionY
    bne NotAtIntersectionY      ;branch always  worst case, 27 cycles
Lower1
    cmp #ROWHEIGHT*3
    beq AtIntersectionY
    bcc Lower3
    cmp #ROWHEIGHT*5
    beq AtIntersectionY
    cmp #ROWHEIGHT*4    
    beq AtIntersectionY
    bne NotAtIntersectionY      ;branch always
Lower3
    cmp #ROWHEIGHT*2
    beq AtIntersectionY
    cmp #ROWHEIGHT*1
    beq AtIntersectionY
    ;--else not at an intersection
NotAtIntersectionY
   	jmp NotAtIntersection
AtIntersectionY	
	;--here is where we choose which way each tank will go

	;--if player tank, read joystick
	txa             ;quick test to see if X = 0 (i.e., player tank we are moving)
	bne EnemyTankDirectionRoutine
	jmp ReadControllersSubroutine
EnemyTankDirectionRoutine
	;--new thought.  if tank is turning, wait until it is actually going to move (fractional overflow) before calculating new direction.
	;--should fix reversals and also should prevent tanks from turning through solid barriers (oops)
	lda TankStatus,X
	asl
	asl
	asl
	asl
	ora #$1F
	clc
	adc TankFractional,X
;     jsr TankFractionalAddition	
	bcs TimeForEnemyTankToTurn
	sta TankFractional,X
	rts
TimeForEnemyTankToTurn
	
	;--check if tank is offscreen (respawned and waiting to move)
	lda TankY,X
	cmp #MAZEAREAHEIGHT+2
	bcc TankNotAboveMaze
	lda #J0DOWN
	bne SetNewTankDirection	;branch always
TankNotAboveMaze	
	lda TankX,X
	cmp #FIRSTCOLUMNX
	bcs TankNotLeftOfMaze
	lda #J0RIGHT
	bne SetNewTankDirection	;branch always
TankNotLeftOfMaze
	cmp #ENEMY2STARTINGX2-1
	bcc TankInMaze
	lda #J0LEFT
	bne SetNewTankDirection
TankInMaze


    ;--overall routine:
    ;   get allowable directions.
    ;       if there is only one, turn in that direction.
    ;       if there is more than one allowable direction:
    ;           save those directions, then push a target (X and Y) onto the stack, and then turn towards the direction that best goes to the target.
	lda #0      ;#(J0LEFT|J0RIGHT|J0UP|J0DOWN)  = all directions
	jsr CheckForWallSubroutine	;--returns with allowable directions in A
AboutToCheckForEnemyTank
	jsr CheckForEnemyTankSubroutine ;--returns with allowable directions in A
	
	and #$F0	;clear bottom nibble
	eor #$F0
	
	;--if single direction, then move that direction
	pha			;--save direction
	bne ThereAreSomeAllowedDirections ;if no allowed directions, skip all the nonsense below
	jmp NoAllowedDirections
  	
ThereAreSomeAllowedDirections
	lsr
	lsr
	lsr
	lsr			;--get in bottom nibble
	tay
	lda NumberOfBitsSet,Y   ;+14 cycles
	;--if can only move a single direction, go that direction
	cmp #1
	bne MoreThanOneAllowedDirection
	pla			;get direction back off stack
SetNewTankDirection
	sta Temp
	lda TankStatus,X
	and #~TANKDIRECTION
	ora Temp
	sta TankStatus,X
	jmp DirectionChosen
MoreThanOneAllowedDirection
;----cannot use this any longer, since directions can be eliminated by the presence of another tank, so the two directions may *not* include reversing back where the tank came from
; 	;--if can only move in two directions, go whichever ISN'T back the way we came from
; 	cmp #2
; 	bne MoreThanTwoAllowedDirections
; 	;--find current direction, clear it's opposite, and then move the one remaining direction
; 	lda TankStatus,X
; 	lsr
; 	lsr
; 	lsr
; 	lsr			;index into table with opposite directions
; 	tay
; 	pla
; 	and PreventReverses,Y
; 	sta Temp
; 	lda TankStatus,X
; 	and #~(J0UP|J0DOWN|J0LEFT|J0RIGHT)
; 	ora Temp
; 	sta TankStatus,X
; 	jmp DirectionChosen

			
	
MoreThanTwoAllowedDirections	
	;--find current direction, clear it's opposite, and then save the remaining allowable directions
	lda TankStatus,X
	lsr
	lsr
	lsr
	lsr			;index into table with opposite directions
	tay
	pla
	and PreventReverses,Y
	pha                         ;25-25 cycles


	
	;--TANK AI ROUTINE ... such as it is
	;--if TankMovementCounter < TANKAISWITCH, then move tanks towards static location(s), otherwise, follow regular pattern
	;--TankMovementCounter updates every 4 frames, so goes from 0 to 255 every ... 16-ish seconds (1024 frames)
	;--at fastest tank speed it is moving ....a pixel every 4 frames.  At slowest tank speed a pixel every 32 frames.
	;--and each block is approx 8x8, so - at fastest speed, tanks will choose a new direction every 32 frames, at slowest speed will
	;       choose a new direction every 256 frames
	lda TankMovementCounter
	cmp #TANKAISWITCH
	bcs RegularMovement
	; move to static location
	lda SwitchMovementX,X
	pha
	lda SwitchMovementY,X
	pha
	bcc ChooseTankDirection ;branch always
RegularMovement
	;routine: 
	; pick two targets, then take the midpoint between them.
	;   each target is a ZP variable.  Have to update random number in between in case both targets are random numbers (like in the case of tank 3)
	;---revamp this with three separate routines, "borrowing" from Pac-Man routines (steal from the best, I guess)
	;       Tank 1 uses the Blinky chase routine (always aiming at player position)
	;       Tank 2 uses the Pinky chase routine (always aiming X` "tiles" in front of player)
	;       Tank 3 uses the Clyde chase routine (aiming for player if X tiles away or more, but when close aiming for base)
	;--if player is dead, aim for base.
	lda TankX
	cmp #16
	bcs PlayerOnScreen
	bcc AimForBase  ;branch always
	
PlayerOnScreen
	cpx #1
	beq EnemyTank1Routine
	cpx #2
	beq EnemyTank2Routine
EnemyTank3Routine
    ;--if further than N tank-lengths from player (using Manhattan distance formula)
    ;   then aim for player
    ;   else aim for base
    lda TankX
    sec
    sbc TankX,X
    bcs FoundAbsoluteXDifference
    ;--negative, so multiply by -1
    eor #$FF
    adc #1
FoundAbsoluteXDifference
    sta Temp
    lda TankY
    sec
    sbc TankY,X
    bcs FoundAbsoluteYDifference
    ;--negative, so multiply by -1
    eor #$FF
    adc #1    
FoundAbsoluteYDifference
    clc
    adc Temp
    cmp #CLYDEDISTANCE ;tanks are 8 pixels wide by 7-pixels tall (sort of).  7-tank lengths, using 7.5 pixels as a tank length = 53 pixels
    bcs EnemyTankIsFarAimForPlayer
    ;--else aim for base
AimForBase
    lda #80
    pha
    lda #0
    pha
    beq ChooseTankDirection ;branch always
EnemyTank2Routine
    ;--aims for spot three tank-lengths in front of player tank
    lda TankStatus
    lsr
    lsr
    lsr
    lsr
    tay
    lda TankX
    clc
    adc TankTargetAdjustmentX,Y
    pha
    lda TankY
    clc
    adc TankTargetAdjustmentY,Y
    pha
    jmp ChooseTankDirection
    
    
EnemyTankIsFarAimForPlayer
EnemyTank1Routine
    ;tank 1 aims for player tank
    lda TankX
    pha
    lda TankY
    pha
ChooseTankDirection
    ;have allowable directions in stack and target X and Y values in stack
	jsr ChooseTankDirectionSubroutine	;returns with new direction in accumulator
	;takes desired direction and sticks it in TankStatus
	sta Temp
	pla
	pla									;pull target for tank off stack and discard

	;--now compare to allowable directions
	;   if desired direction is one of the allowable directions, then go that way.
	;       if not, pick random direction from allowable and move that way.
	pla	;	--get allowable directions off stack
	pha	;	but leave on stack
; 	and TankStatus,X
    and Temp
    beq DesiredDirectionsNotAllowed
    ;--we may have more than one allowed direction, and both may be allowed.
	eor #$FF	;flip bits
	jsr EliminateDiagonalSubroutine
	eor #$FF
	;--now stick single direction in TankStatus
	sta Temp
	lda TankStatus,X
	and #~TANKDIRECTION
	ora Temp
	sta TankStatus,X					
	bne DirectionIsFine     ;branch always
DesiredDirectionsNotAllowed
	;--direction is not ok
	;	for now, randomly pick one of the allowed directions
	lda RandomNumber
	and #3
	tay
TryAnotherDirection
	pla	;--get allowed directions
	pha	;--but leave on stack
	and MovementMask,Y
	bne FoundGoodDirection
	dey
	bpl TryAnotherDirection
	ldy #3					;loop around
	bne TryAnotherDirection	;branch always -- this assumes we will always find a good direction
FoundGoodDirection
NoAllowedDirections
	sta Temp
	lda TankStatus,X
	and #~TANKDIRECTION
	ora Temp
	sta TankStatus,X
		
DirectionIsFine
	pla
DirectionChosen
NotAtIntersection



	;push return address onto stack
; 	lda #>(ReturnFromTankMovementSubroutine-1)
; 	pha
; 	lda #<(ReturnFromTankMovementSubroutine-1)
; 	pha
	;push movementflag (zero) onto stack
	lda #0
	pha
	
	lda TankStatus,X			;this holds new, desired direction for tank.
	eor #$FF					;flip all bits so that is interchangeable with reading from joystick
								;and can use same routine for both.
	jmp TankMovementSubroutine
	

;****************************************************************************

SoundSubroutine
	;--no sound for enemy tanks; too annoying
	
	;  tentative:
	;	channel 0 = player tank movement
	;	channel 1 = all other sound effects (no shot sound when an explosion is happening)
	
	;--the way this works:
	;   all sound effects have a duration (1-255)
	;   this duration (stored in Channel1Decay) decrements every frame
	;       while Channel1Decay >= 7, the volume for the sound is 7
	;       when Channel1Decay < 7, the volume for the sound = Channel1Decay
	;   in other words, all sounds effects have a static volume (=7) until the last 7 frames (approx 1/10 of a second)
	;       at which point the sound volume linearly fades out to zero
	
	;--skip this if game over
	lda GameStatus
	and #GAMEOVER
	beq PlaySoundGameNotOver
	rts
	
PlaySoundGameNotOver
	lda Channel1Decay
 	cmp #$07
 	bcc SetChannel1Volume
 	lda #$07
SetChannel1Volume
	sta AUDV1
	lda Channel1Decay
	beq DoNotUpdateChannel1Decay
	dec Channel1Decay
DoNotUpdateChannel1Decay	
ReturnFromTankMovementSubroutine       
    


    ;--now play music.  
MusicRoutine  
    ;--no music while maze is generating.  which besides being aesthetically what I want, also keeps the 
    ;   maze-generation routine from being screwed up, since it uses RandomNumberSaved, which is also used by
    ;   maze-generation routine, to save the random seed *across frames*
    ;--save RandomNumber every measure
    lda GameStatus
    and #GENERATINGMAZE|LEVELCOMPLETE
    beq MusicIsPlaying
MusicIsNotPlaying
    lda #0
    sta AUDV0
    rts
MusicIsPlaying
    ;First, determine which song
    ;if on title screen play title screen song
    lda GameStatus
    and #TITLESCREEN
    cmp #TITLESCREEN
    bne NotOnTitleScreenAtAll
    ;--else on title screen, but start playing drum beat once base shows
    lda GameStatus
    and #DRAWBASE
    beq MusicIsNotPlaying
    lda #<TitleScreenSong
    sta MiscPtr+2
    lda #>TitleScreenSong
    sta MiscPtr+3
    bne PlayMusic
NotOnTitleScreenAtAll
    ;--during level start?
    lda GameStatus
    and #GENERATINGMAZE|GAMEOFF|DRAWBASE|LEVELCOMPLETE
    cmp #DRAWBASE       ;not generating maze, game is on, base is drawn, and level is not complete
    bne DoNotPlayLevelStartMusic
    lda #<LevelStartSong
    sta MiscPtr+2
    lda #>LevelStartSong
    sta MiscPtr+3
    bne PlayMusic   ;branch always
DoNotPlayLevelStartMusic
    ;--this is default and is incorrect, need additional logic or different default here.
    lda #<TitleScreenSong
    sta MiscPtr+2
    lda #>TitleScreenSong
    sta MiscPtr+3


PlayMusic
    lda FrameCounter
    and #7                  ;tempo = 112.5 BPM, 16th note every seven frames
    beq GetNewNote          
    and #3
    bne NoPercussionDownBeat    ;percussion is all 32nds
    jmp GetNewPercussion
NoPercussionDownBeat
    ;--not on 32nd-note beat, so need to determine if we are playing percussion or playing note
    cmp #PERCUSSIONCUTOFF
    bcc PlayRegularNote
    ;--otherwise, first see if percussion is playing
;     rts ;--if above percussion cutoff, keep playing whatever we were playing
;     ;--see if percussion should be playing
;     jsr GetPercussionSound
;     beq PlayRegularNote
;     ;--else keep playing percussion
    
PlayRegularNote    
    ;--else play regular tone
    lda SongIndex
    and #$F0
    lsr
    lsr
    lsr
    tay
    lda (MiscPtr+2),Y
    sta MiscPtr+4
    iny
    lda (MiscPtr+2),Y
    sta MiscPtr+5
    lda SongIndex
    and #$0F
    tay
    lda (MiscPtr+4),Y
    and #VOLUME_BITS
    sta Temp
    lda (MiscPtr+4),Y
    lsr
    bcc NoArticulation
    lda FrameCounter
    and #7
    tax
    lda Temp
    sec
    sbc ArticulationTable,X
    .byte $2C   ;skip next two bytes
NoArticulation
    lda Temp
    sta Temp+1
    lda (MiscPtr+4),Y
    lsr
    lsr
    lsr
    lsr
    tay
    lda DistortionTable,Y
    sta Temp+2
    lda FrequencyTable,Y
    sta Temp+3
    jmp PlayMusicSound
GetNewNote
    inc SongIndex
BackToBeginningOfSong
    lda SongIndex
    and #$F0
    lsr
    lsr
    lsr
    tay
    lda (MiscPtr+2),Y
    cmp #255
    bne NotEndOfSong
    iny
    cmp #255
    bne NotEndOfSong
    ;--change.  If 255, next byte tells us what to change songindex to.
    iny
    lda (MiscPtr+2),Y
    sta SongIndex
    tay
    jmp BackToBeginningOfSong
NotEndOfSong
    ;--when getting new note, save new random number at beginning of every measure (i.e., when SongIndex & $F = 0)
    lda SongIndex
    and #$F
    bne NoChangeToSavedRandomNumber
    lda RandomNumber
    sta RandomNumberSaved
NoChangeToSavedRandomNumber
       ;have to reload, kind of inefficient
    lda SongIndex
    and #$F0
    lsr
    lsr
    lsr
    tay
    lda (MiscPtr+2),Y
    sta MiscPtr+4
    iny
    lda (MiscPtr+2),Y
    sta MiscPtr+5
    lda SongIndex
    and #$0F
    tay
    lda (MiscPtr+4),Y    
    and #VOLUME_BITS
    sta Temp+1
    lda (MiscPtr+4),Y
    lsr
    lsr
    lsr
    lsr
    tay
    lda DistortionTable,Y
    sta Temp+2
    lda FrequencyTable,Y
    sta Temp+3
GetNewPercussion
    jsr GetPercussionSound  ;returns with A holding percussion value *AND* flags set based on what that value is
    beq NoPercussion
    tay
    lda PercussionVolumeTable,Y
    sta Temp+1
    lda PercussionDistortionTable,Y
    sta Temp+2
    lda PercussionFrequencyTable,Y
    sta Temp+3


NotDownBeat


PlayMusicSound
    lda Temp+1
    sta AUDV0
    lda Temp+2
    sta AUDC0
    lda Temp+3
    sta AUDF0
DoNotEndPercussion
NoPercussion
	rts

	
;****************************************************************************
    SUBROUTINE
GetPercussionSound  ;trashes Y, A.  Returns with percussion value (0-3) in A
                    ;uses Temp, MiscPtr, MiscPtr+1
                    ;depends on MiscPtr+2 pointing at melody data
    lda SongIndex
    and #$F0
    lsr
    lsr
    lsr
    tay
    lda (MiscPtr+2),Y
    sta MiscPtr+4
    iny
    lda (MiscPtr+2),Y
    sta MiscPtr+5
    lda SongIndex
    and #$0F
    tay
    lda (MiscPtr+4),Y
    ;--if non-zero value (i.e., a note), play beat with kick
    ;   if zero (i.e., no melody), play beat without kick
    beq SnareBeatsOnly
    lda #2
SnareBeatsOnly
    sta Temp
    ;now pick randomly from various related drum beats
;     lda RandomNumber
    lda RandomNumberSaved
    and #3
    tay
    lda Temp
    clc
.loop
    dey
    bmi .loopdone
    adc #4
    bne .loop
.loopdone
    tay    
    lda SongIndex
    and #$0F
    cmp #12
    bcc BeatPattern
    ;--else fill
    lda FillPatternTable,Y
    sta MiscPtr
    lda FillPatternTable+1,Y
    sta MiscPtr+1
    bne LoadDrumPattern ;branch always
BeatPattern
    lda BeatPatternTable,Y
    sta MiscPtr
    lda BeatPatternTable+1,Y
    sta MiscPtr+1
LoadDrumPattern 
    lda SongIndex   
    and #3
    lsr         ;divide SongIndex by 2, but we will use the carry bit below!
    tay
    lda (MiscPtr),Y
    bcs NoShiftToRhythmPattern  ;if SongIndex & 1 == 1 then we want right nibble, else we want left nibble
    lsr
    lsr
    lsr
    lsr
NoShiftToRhythmPattern
    sta Temp
    lda FrameCounter
    and #%00000100
    bne SixteenthUpBeat
    lsr Temp
    lsr Temp
SixteenthUpBeat
    lda #%00000011
    and Temp
    
    rts
    
    /*

    ;--this is to make sure the "DivideLoop" doesn't cross a page boundary.
    if ((* + 5) & $FF00) != ((* + 9) & $FF00)
        echo "---Aligned PositionASpriteSubroutine -", $FF - ((* + 4) & $FF), "bytes left at location", *
        ds $FF - ((* + 4) & $FF)
    else
        echo "---Aligned PositionASpriteSubroutine not necessary"
    endif

PositionASpriteSubroutine
    sec
	sta HMCLR
	sta WSYNC
DivideLoop			;				this loop can't cross a page boundary!!!
	sbc #15
	bcs DivideLoop	;+4		 4
	eor #7
	asl
	asl
	asl
	asl				;+10	14
	sta.wx HMP0,X	;+5		19
	sta RESP0,X		;+4		23
	sta WSYNC
	sta HMOVE
Return					;label for cycle-burning code   
	rts                 ;+9      9
*/
	
/*	
PositionASpriteNoHMOVESubroutine
	sta HMCLR
PositionASpriteNoHMOVEOrHMCLRSubroutine
    sec
	sta WSYNC
DivideLoop2			;				this loop can't cross a page boundary!!!
	sbc #15
	bcs DivideLoop2	;+4		 4
	eor #7
	asl
	asl
	asl
	asl				;+10	14
	sta.wx HMP0,X	;+5		19
	sta RESP0,X		;+4		23
; 	sta WSYNC
; 	sta HMOVE
	rts
*/	
;****************************************************************************




; DivideByTwoSubroutine		;come in with number in accumlator
; 	and #$FF		;set flags
; 	clc
; 	bpl DivideByTwoPositive
; 	;--else negative
; 	sec
; DivideByTwoPositive
; 	ror
; 	rts
	
	
;****************************************************************************

    
;****************************************************************************

EliminateDiagonalSubroutine
	;--trashes Y.
	;--X is index into which tank
	;--A holds direction of joystick (filtered to allowed directions)
	;--now get directions down to a single direction (i.e., no diagonals)
	;--first, determine if trying to move diagonally:
	;	need to count cleared bits in the top nibble
	ldy #0					;will count bits set with Y
	pha						;save allowed directions on stack
	txa
	pha						;save X index on stack
	tsx
	lda $02,X				;get allowed directions off of stack
	
	lsr
	lsr
	lsr
	lsr
	eor #$0F
	tay
	lda NumberOfBitsSet,Y
	tay
	

	pla
	tax						;restore X
	pla						;restore directions
	
	cpy #2
	bcc DirectionsFine
	;--too many directions - must narrow down to 1
	;  assumption is that an actual diagnonal is here -
	;	  i.e., L+U, or R+D, but NOT L+R or U+D nor three or four directions

	pha	;save desired directions on the stack
	; for Enemy Tanks=randomly eliminate either horizontal or vertical movement
	; for Player Tank=do previous routine which allowed tank to slide along
	txa ;set zero flag based on value in X (zero = player tank, non-zero = enemy tanks)
	bne EnemyTankEliminateDiagonal
    ;--player tank.  routine here basically tries to pick which direction to move in.
    ;   routine is basically, if we were moving horizontally, have tank move vertically, and vice versa.	
CompleteChangeOfDirection
; 	ldx #0      ;X is already zero
	lda TankStatus
	and #J0LEFT|J0RIGHT
	beq EliminateUpDown
	;--else eliminate left and right
	pla
	ora #J0LEFT|J0RIGHT
; 	bne DirectionsFine
	rts
EliminateUpDown
	pla						;restore directions 
	ora #J0UP|J0DOWN		;eliminate up and down
; 	bne DirectionsFine		;branch always
    rts
EnemyTankEliminateDiagonal
	lda RandomNumber
	lsr				;random bit
	pla ;get desired directions back into accumulator
	bcs EliminateHorizontal
	;--else eliminate vertial
	ora #J0RIGHT|J0LEFT
; 	bne DirectionsFine
    rts
EliminateHorizontal
	ora #J0UP|J0DOWN
DirectionsFine

	rts

	
	
;****************************************************************************

ReadControllersSubroutine

	lda #0
	pha			;movement flag onto stack
	
	lda SWCHA	;A holds joystick
	and #$F0	;clear bottom nibble
	cmp #$F0
    bne TryingToMove
    ;--not trying to move, so just ... exit?  no!  have to go check if we are trying to shoot!
    ;--also clear speed bits in TankStatus so we know it isn't trying to move.
    lda TankStatus
    and #~TANKSPEED
    sta TankStatus
    ;--stop engine sound
    pla ;--pop movement flag (=0) off stack
;     sta AUDV0
    jmp PlayerTankBulletFiring
TryingToMove
SkipReadingControllers
; 	ldx #PLAYERTANKENGINEVOLUME
; NotTryingToMove
; 	stx AUDV0	
;     tax ;save joystick directions
;     ldy #PLAYERTANKENGINESOUND
;     jsr StartSoundSubroutine
;     txa ;restore joystick directions


	sta Temp			;--save original desired direction of tank
    ;--and set player speed which we set to zero when he stopped
    ;--set tank speed lower if player off left edge of screen
    lda TankStatus
    and #TANKDIRECTION
    ora #PLAYERTANKSPEED
    ldx TankX
    cpx #16
    bcs RegularPlayerTankSpeed
    ;and #$F1          ;change from TANKSPEED3 to TANKSPEED1
RegularPlayerTankSpeed    
    sta TankStatus 

	ldx #0		;index into which tank	

        
	lda Temp
	pha         ;push desired directions onto stack (player tank)
	
	jsr CheckForWallSubroutine		;--returns with allowed directions, of the desired directions, in A
	.byte $24	;--skip next byte
TankMovementSubroutine				;jump here when moving enemy tanks, with movement flag already on top of stack)
	pha			;--save desired direction of tank (enemy tank - skipped when player tank)
	
	;--if no directions are allowed, but tank is trying to move, turn tank but do not move.
	and #$F0	;clear bottom nibble
	cmp #$F0	;no movement = $F0
	bne MovementAllowed
	txa
	pha		;save index into which tank
	tsx
	lda #$FF
	sta $03,X	;update movementflag
	pla
	tax			;restore tank index
	jmp ProcessDirections
MovementAllowed
	pha		;save allowed directions (stack holds [top down]: allowed directions, desired directions, movement flag, return address)
	
	
	txa
	pha		;save index into which tank
	tsx
	lda $02,X	;load allowed directions (see above)
	sta $03,X	;overwrite desired directions (either joystick (if player) or calc direction if enemy)
	pla			;pull tank index off stack
	tax			;restore tank index
	pla			;pulls allowed directions off as it is duplicative
ProcessDirections
	pla			;pulls final directions off stack (directions that are both allowed and desired) 
	            ;stack at this point holds (top down): movement flag, return address

	tay	;--save direction in Y
	
	;--if tank is turning, set fractional variable so tank moves immediately
	and #TANKDIRECTION
	eor #$F0        ;flip bits
	sta Temp
	lda TankStatus,X
	and #TANKDIRECTION
	cmp Temp
	beq TankNotTurning
	;tank turning
	lda #$FF
	sta TankFractional,X
TankNotTurning
    pla             ;get movement flag into accumulator
    sta Temp
    bit Temp        ;movement flag in overflow
	tya
	pha             ;push Y (direction(s) tank wants to go) onto stack
	cpx #0
	bne NoTankSoundForEnemyTanks
	lda Channel1Decay
	cmp #PLAYERTANKENGINEVOLUME
	bcs DoNotStartPlayerTankSound
	ldy #PLAYERTANKENGINESOUND
	jsr StartSoundSubroutine
DoNotStartPlayerTankSound
	
NoTankSoundForEnemyTanks
	
	pla						;get saved directions back in A	
	asl
	bcs NoRight
	bvs TurnRightward		;overflow holds movement flag (clear=no movement)
	jsr TankFractionalAddition
	lda TankX,X
	adc #0
	sta TankX,X
TurnRightward	
	lda TankStatus,X
	and #~TANKDIRECTION
	ora #TANKRIGHT
	sta TankStatus,X
	bne DoneMoving  ;branch always 
NoRight
	asl
	bcs NoLeft
	bvs TurnLeftward		;overflow holds movement flag (clear=no movement)
	jsr TankFractionalAddition
	bcc TurnLeftward	;but don't move -- since TankFractional always adds, we can't then SBC #0 and use the carry flag here
	dec TankX,X
TurnLeftward
	lda TankStatus,X
	and #~TANKDIRECTION
	ora #TANKLEFT
	sta TankStatus,X
	bne DoneMoving  ;branch always 
NoLeft
    asl
    bcs NoDown
	bvs TurnDownward		;overflow holds movement flag (clear=no movement)
	jsr TankFractionalAddition
	bcc TurnDownward	;but don't move down
	dec TankY,X
TurnDownward
	lda TankStatus,X
	and #~TANKDIRECTION
	ora #TANKDOWN
	sta TankStatus,X
	bne DoneMoving  ;branch always
NoDown
    asl
    bcs NoUp
	bvs TurnUpward			;overflow holds movement flag (clear=no movement)
	jsr TankFractionalAddition
	lda TankY,X
	adc #0
	sta TankY,X
TurnUpward
	lda TankStatus,X
	and #~TANKDIRECTION
	ora #TANKUP
	sta TankStatus,X
NoUp
DoneMoving
    ;--if enemy tank we exit now... I think.  right?  this bullet-firing routine is specific to the player, enemy bullets are fired elsewhere
    txa ;set flags based on X
    beq PlayerTankBulletFiring
    rts
PlayerTankBulletFiring    
    
    
	;--don't allow player to fire when offscreen or when not in play (i.e., when an explosion lol)
	lda TankStatus
	and #TANKINPLAY
	beq PlayerExplodingCannotShoot
	lda TankX
	cmp #16
	bcs PlayerOnScreenCanShoot
PlayerExplodingCannotShoot	
	jmp NotFiring
PlayerOnScreenCanShoot
	;are any balls available for firing
	ldx #1
FindAvailableBallLoop
	lda BulletX,X
	;cmp #BALLOFFSCREEN ;<--this value is zero
	beq FoundAvailableBall
	dex
	bpl FindAvailableBallLoop
	jmp NoAvailableBalls
FoundAvailableBall	
	;--now read joystick trigger if debounce is zero:
	lda INPT4
	bpl TriggerHit
	;--if trigger not hit, set debounce to zero
	lda Debounce
	and #~TRIGGERDEBOUNCEFLAG
	sta Debounce
	jmp NotFiring
TriggerHit
	lda Debounce
	and #TRIGGERDEBOUNCEFLAG
	beq TriggerDebounced
	jmp TriggerNotDebounced
	
TriggerDebounced
	;--bullet is fired!

	;--bullet sound
	;--if explosion sound in early stages, do not make bullet sound
	lda Channel1Decay
	and #$F8
	bne NoBulletSound
	ldy #BULLETSOUND
	jsr StartSoundSubroutine
	
NoBulletSound
	
	;set trigger debounce
	lda Debounce
	ora #TRIGGERDEBOUNCEFLAG
	sta Debounce
	
	ldy #0		;set index into which tank 
				;X holds index into which bullet
FireBulletRoutine
	
	
	;--set initial position at approx center of tank (will be adjusted below depending on which way the tank is facing)
	lda TankX,Y
	clc
	adc #4
	sta Temp
	lda TankY,Y
	sec
	sbc #3
	sta Temp+1
	
	;--clear old direction
	lda BulletDirectionClear,X
	eor #$FF
	and BulletDirection
	sta BulletDirection 

	
	;--then set new direction:
	lda TankStatus,Y
	asl ;--get J0RIGHT into carry
	bcc NotFiringRight
	;--shooting right
	;--shooting right
	lda BulletDirection
	ora BulletRight,X
	sta BulletDirection
	lda Temp
	clc
	adc #5
	sta Temp
    jmp DoneFiring
NotFiringRight
    asl ;--get J0LEFT into carry
    bcc NotFiringLeft
	;--shooting left
	lda BulletDirection
	ora BulletLeft,X
	sta BulletDirection
	lda Temp
	sec
	sbc #6
	sta Temp
	jmp DoneFiring
NotFiringLeft
    asl ;--get J0DOWN into carry
    bcc NotFiringDown
	;--shooting down
	lda BulletDirection
	ora BulletDown,X
	sta BulletDirection
	lda Temp+1
	sec
	sbc #4
	sta Temp+1
	jmp DoneFiring
NotFiringDown
    asl ;--get J0UP into carry
    bcc NoDirectionNotFiringAtAll   ;is this necessary?  
	;--shooting up
	lda BulletDirection
	ora BulletUp,X
	sta BulletDirection
	lda Temp+1
	clc
	adc #4
	sta Temp+1
	jmp DoneFiring
DoneFiring
	lda Temp
	sta BulletX,X
	lda Temp+1
	sta BulletY,X
NoDirectionNotFiringAtAll
NotFiring
NoAvailableBalls	
TriggerNotDebounced

	rts
	

	

;****************************************************************************

    SUBROUTINE
    
IsTankOnScreenBank0
    ;--X holds tank number to check
    ;--return in accumulator:  0 if offscreen, 1 if onscreen
    lda TankX,X
    cmp #TANKONSCREENLEFT
    bcc .TankOffScreen
    cmp #TANKONSCREENRIGHT+1
    bcs .TankOffScreen
    lda TankY,X
    cmp #TANKONSCREENTOP+2
    bcc .TankOnScreen    
.TankOffScreen
    lda #0
    rts
.TankOnScreen
    lda #1
    rts
;****************************************************************************


    SUBROUTINE
    
IsTankPartiallyOnScreenBank0
    ;--X holds tank number to check
    ;--return in accumulator:  0 if offscreen, 1 if onscreen
    lda TankX,X
    cmp #TANKONSCREENLEFT-7
    bcc .TankOffScreen
    cmp #TANKONSCREENRIGHT+1+7
    bcs .TankOffScreen
    lda TankY,X
    cmp #TANKONSCREENTOP+2+TANKHEIGHT
    bcc .TankOnScreen    
.TankOffScreen
    lda #0
    rts
.TankOnScreen
    lda #1
    rts
;****************************************************************************


IsBlockAtPosition		;position in Temp (x), Temp+1 (y)
	;--returns result in Temp
	;--special case for first row which is mostly open (except for the base, but we'll deal with that later)
	;--except now first row has walls at two positions (maybe!) only
	;   this routine can't overwrite Y
		
	txa                     ;+2
	pha			            ;+3      5  save X on stack
	lda Temp                ;+3      8
	sec
	sbc #16
	lsr
	lsr
	lsr
	tax                     ;+12    20
	lda PFRegisterLookup,X
; 	pha                     ;+7     27
    sta Temp+3          
	lda PFMaskLookup,X
; 	pha                     ;+7     34
    sta Temp+2
	lda Temp+1              ;+3     37
	;--special case: if Temp+1 < BLOCKHEIGHT then check in a different way
	sec
	sbc #BLOCKHEIGHT
	bcs NotOnBottomRow      ;6/7    43/44
OnBottomRow                 ;       43
	;--on bottom row
	;--only two blocks on bottom row
	;	at X positions (LastRowL) 64-71 and (LastRowR) 88-95
	lda LastRowL
	beq LastRowNoWallOnLeft     ;+4/5   47/48
	lda Temp                
	cmp #72                     ;+5     52
	bcs LastRowCheckRightBlock  ;+2/3   54/55
	cmp #64
	bcs FoundWhetherBlockExists ;+4/5   58/59
LastRowNoWallOnLeft             ;       48/58    
LastRowCheckRightBlock          ;            /55
	lda LastRowR
	beq FoundWhetherBlockExists ;+4/5   branch: 53/60/63 ...drop through: 52/59/62
	lda Temp
	cmp #96
	bcs LastRowNoHit            ;+7/8   61/68/71 (branch) or 60/67/70 (drop through)
	cmp #88
	bcs FoundWhetherBlockExists ;+4/5   65/72/75 (branch) or 64/71/74 (drop through)
LastRowNoHit                    ;                                                    or 61/68/71 (from branch above)
	lda #0
	beq FoundWhetherBlockExists ;+5     66/69/73/76/79 
	;--in conclusion, we end this path by jumping below to the routine exit after this many cycles:
	;           53/59/60/63/65/66/69/72/73/75/76/79 (one of these!)
	;
NotOnBottomRow	                ;       44
	;--divide by blockheight

	;got this here: https://forums.nesdev.org/viewtopic.php?f=2&t=11336
	;	post gives credit to December '84 Apple Assembly Line
	;--constant cycle count divide by 7 !!!!
	;	if BLOCKHEIGHT is changed from 7, this routine will need to be updated
	sta Temp
	lsr
	lsr
	lsr
	adc Temp
	ror
	lsr
	lsr
	adc Temp
	ror
	lsr
	lsr                         ;+27    71 
	
	tax                         ;+2     73

	;--now add X to 2nd element on stack
	;txa
; 	tsx
	clc
; 	adc $00+2,X
    adc Temp+3
	tax                         ;+12    85
	
	lda PF1Left,X
; 	tsx
; 	and $00+1,X                 ;+10    95
    and Temp+2
FoundWhetherBlockExists         ;end up here somewhere between 53 and 95 cycles after beginning of subroutine
	;--result is now in A --nonzero means a block is there, zero means no
	sta Temp		;result goes into Temp
; 	pla
; 	pla		;get intermediate results off of stack
	pla
	tax		;restore X from stack
	rts                         ;+23    76-118  (which changes from using stack to using temp vars, we subtract 22 cycles for new totals: 54-96)

	
	
	
;****************************************************************************
	

StartSoundSubroutine
	
	lda Channel1Decay
	and #$F0
	bne DoNotStartSound
	lda Tone,Y
	sta AUDC1
	lda Frequency,Y
	sta AUDF1
	lda SoundLength,Y
	sta Channel1Decay
	
DoNotStartSound
	rts

	
;****************************************************************************

    SUBROUTINE

CheckForEnemyTankSubroutine
    ;--come in with X pointing at current tank
    ;   and A holds direction (mask against joystick constants)
    ;   return A holding allowed directions
    
    ;--possible optimization: 
    ;   right now, it checks the same directions for all on-screen tanks.
    ;   could short-circuit that, e.g., if tank 3 is preventing upward movement, skip upward check for tank 2.
    ;   if cleverly coded, could shave some cycles off the routine in certain cases, 
    ;   at the expense of additional code length, and likely making it take longer in other cases
    ;   If timing gets really tight could investigate.

    stx Temp+1  ;--save index into current tank
    sta Temp ;save directions
    ;--moving left.
    ldy #3
.CheckForEnemyTankLoop
    cpy Temp+1  ;--don't bother comparing tank to itself
    bne .NotComparingTankToItself
    jmp .NoCompareTankToItself
.NotComparingTankToItself
    ;--see if enemy tank is offscreen
    lda TankStatus,Y
    lsr                 ;get TANKINPLAY bit into carry
    bcs .TankOnScreenComparePositions
    jmp .TankOffScreenIgnore
.TankOnScreenComparePositions 
    lda Temp
    and #J0LEFT
    bne .NotMovingLeft
   
    ;see if an enemy tank within 1.5 blocks (12 pix) to the left
    lda TankX,X
;     sec       ;carry set following not-taken BCC branch above
    sbc #1      ;--have to subtract one so equal values are ignored
    sbc TankX,Y
    cmp #14
    bcs .ThisTankNotToLeft
    ;if so, see if that tank is between 1.5 blocks up and 1.5 blocks down 
    lda TankY,X
;     clc       ;carry clear following not-taken BCS branch above
    adc #11     ;actual value is +10 but carry-subtraction below subtracts one more than the TankY
;     sec       ;skip because we adjust above
    sbc TankY,Y
    cmp #20
    bcs .ThisTankNotToLeft
    ;--there is a tank there!  can't move left!
    lda Temp
    ora #J0LEFT
    sta Temp
.ThisTankNotToLeft    
.NotMovingLeft
    lda Temp
    and #J0RIGHT
    bne .NotMovingRight
    ;--moving right.
    lda TankX,Y
    sec     
    sbc #1      ;--have to add one so equal values are ignored
    sbc TankX,X
    cmp #14
    bcs .ThisTankNotToRight
    lda TankY,X
;     clc       ;carry clear following not-taken BCS branch above
    adc #11     ;actual value is +10 but carry-subtraction below subtracts one more than the TankY
;     sec       ;skip because we adjust above
    sbc TankY,Y
    cmp #20
    bcs .ThisTankNotToRight
    ;--there is a tank there!  can't move right!
    lda Temp
    ora #J0RIGHT
    sta Temp
.ThisTankNotToRight    
.NotMovingRight
    lda Temp
    and #J0UP
    bne .NotMovingUp
    ;--moving up.
    ;see if an enemy tank is above
    lda TankY,Y
    sec       
    sbc #1      ;--have to add one so equal values are ignored
    sbc TankY,X
    cmp #12
    bcs .ThisTankNotToUp
    lda TankX,X
;     clc       ;carry clear following not-taken BCS branch above
    adc #13     ;actual value is +12 but carry-subtraction below subtracts one more than the TankY
;     sec       ;skip because we adjust above
    sbc TankX,Y
    cmp #24
    bcs .ThisTankNotToUp
    ;--there is a tank there!  can't move up!
    lda Temp
    ora #J0UP
    sta Temp
.ThisTankNotToUp    
.NotMovingUp

.CheckMovingDown
    lda Temp
    and #J0DOWN
    bne .NotMovingDown
    ;--moving down.
    ;see if an enemy tank is below
    lda TankY,X
    sec       
    sbc #1      ;--have to add one so equal values are ignored
    sbc TankY,Y
    cmp #12
    bcs .ThisTankNotToDown
    lda TankX,X
;     clc       ;carry clear following not-taken BCS branch above
    adc #13     ;actual value is +12 but carry-subtraction below subtracts one more than the TankY
;     sec       ;skip because we adjust above
    sbc TankX,Y
    cmp #24
    bcs .ThisTankNotToDown
    ;--there is a tank there!  can't move up!
    lda Temp
    ora #J0DOWN
    sta Temp
.ThisTankNotToDown    
.NoCompareTankToItself
.TankOffScreenIgnore
    dey
    beq .DoneWithEnemyTankChecks
    jmp .CheckForEnemyTankLoop
.NotMovingDown
.DoneWithEnemyTankChecks

    lda Temp    ;restore allowed directions to Accumulator

    rts


;****************************************************************************

CheckForWallSubroutine
				;--X holds index into which tank, A holds direction (mask against joystick constants)
				;return A holding allowed directions
	tay			;save direction
	and #J0LEFT
	bne NotMovingLeft
	;--moving left.
	;--first, if at left edge, don't allow left movement
	lda TankX,X
	cmp #16
	beq CannotMoveLeft
	;--check for wall immediately to the left of upper left corner
	lda TankX,X
	sec
	sbc #1
	sta Temp
	lda TankY,X
	sec
	sbc #2
	sta Temp+1
	jsr IsBlockAtPosition
	;result is in Temp
	lda Temp
 	beq NoWallL
CannotMoveLeft
	tya
	ora #J0LEFT
	tay
	;jmp CheckVerticalMovement
NoWallL
NotMovingLeft
	tya
	and #J0RIGHT
	bne NotMovingRight
	;--moving right
	;--first, if at right edge, don't allow rightward movement
	lda TankX,X
	cmp #136
	beq CannotMoveRight
	;--check for wall immediately to the right
	lda TankX,X
	clc
	adc #8
	sta Temp
	lda TankY,X
	sec
	sbc #2
	sta Temp+1
	jsr IsBlockAtPosition
	;result is in Temp
	lda Temp
 	beq NoWallR
	
CannotMoveRight
	tya
	ora #J0RIGHT
	tay
NoWallR	
NotMovingRight
CheckVerticalMovement
	tya
	and #J0UP
	bne NotMovingUp
	;--moving up
	;--first, if at top edge, don't allow upward movement
	lda TankY,X
	cmp #TANKAREAHEIGHT+1
	beq CannotMoveUp
	;--check wall above
	lda TankX,X
	sta Temp
	lda TankY,X
; 	sec
; 	sbc #1
	sta Temp+1
	jsr IsBlockAtPosition
	;result is in Temp
	lda Temp
 	beq NoWallU
CannotMoveUp
	tya
	ora #J0UP
	tay
	;jmp DoneWithMovementChecks
NotAtTopEdge
NoWallU	
NotMovingUp	
	tya
	and #J0DOWN
	bne NotMovingDown
	;--moving down
	;--first, if at bottom edge, don't allow downward movement
	lda TankY,X
	cmp #8
	beq CannotMoveDown
	;--check wall below
	lda TankX,X
	sta Temp
	lda TankY,X
	sec
	sbc #9
	sta Temp+1
	jsr IsBlockAtPosition
	;result is in Temp
	lda Temp
 	beq NoWallD
CannotMoveDown
	tya
	ora #J0DOWN
	tay
	;jmp DoneWithMovementChecks
NotAtBottomEdge	
NoWallD	
NotMovingDown

DoneWithMovementChecks
	tya		;get allowed directions back into A

	rts


;****************************************************************************

	;come in with amount to increase in A (units and tens) and Temp (100s and 1000s)
IncreaseScoreSubroutineBank0
	clc
	sed
	adc Score+2
	sta Score+2
	lda Score+1
	adc Temp
	sta Score+1
	lda Score
	adc #0
	sta Score
	cld
	rts

;****************************************************************************
	SUBROUTINE
PowerUpBonusRoutine

    ;--if player tank not in play, immediately return
    lda TankStatus
    lsr
    bcc .PlayerNotInPlayNoBonus

    ;--routine for now - if player kills half the tanks on the level (or the tanks die) without dying, player gets speed boost.
    ;--new routine: if powerup activated, player gets speed boost AS long as he hasn't died!
;     lda MazeGenerationPass
;     and #PLAYERDEATHCOUNTBITS
;     bne .PlayerHasDiedNoBonus    
    lda MazeGenerationPass
    and #POWERUPACTIVATEDBITS
    beq .PowerUpNotActivated
    cmp #%10000000
    bne .OnlySpeedBonus
    
    ;--kill all tanks (also gives score bonus there)
    brk
    .word KillAllTanksBonus
    ;--also play some kind of sound effect
    
    
    lda MazeGenerationPass
    and #~POWERUPACTIVATEDBITS
    ora #%01000000
    sta MazeGenerationPass
.OnlySpeedBonus    
    ;--get starting tank amount
    lda TankStatus
    and #~TANKSPEED
    ora #PLAYERTANKSPEED+SPEEDBONUS
    sta TankStatus
.PlayerHasDiedNoBonus    
.PowerUpNotActivated
.PlayerNotInPlayNoBonus
    rts

;----------------------------------------------------------------------------
;-------------------------Data Below-----------------------------------------
;----------------------------------------------------------------------------
	

	
	
	




	
	
;DigitA
;       .byte #%01000011;--
;       .byte #%01000011;--
;       .byte #%01000011;--
;       .byte #%01111111;--
;       .byte #%01000010;--
;       .byte #%01000010;--
;       .byte #%01111110;--
;DigitB
;       .byte #%01111111;--
;       .byte #%01000011;--
;       .byte #%01000011;--
;       .byte #%01111111;--
;       .byte #%01000010;--
;       .byte #%01000010;--
;       .byte #%01111110;--
;DigitC
;       .byte #%01111111;--
;       .byte #%01100000;--
;       .byte #%01100000;--
;       .byte #%01100000;--
;       .byte #%00100000;--
;       .byte #%00100000;--
;       .byte #%00111100;--
;DigitD
;       .byte #%01111111;--
;       .byte #%01000011;--
;       .byte #%01000011;--
;       .byte #%01000011;--
;       .byte #%01000010;--
;       .byte #%01000010;--
;       .byte #%01111110;--
;DigitE
;       .byte #%01111111;--
;       .byte #%01100000;--
;       .byte #%01100000;--
;       .byte #%01111100;--
;       .byte #%01100000;--
;       .byte #%00100000;--
;       .byte #%00111110;--
;DigitF
;       .byte #%01100000;--
;       .byte #%01100000;--
;       .byte #%01100000;--
;       .byte #%01111100;--
;       .byte #%01100000;--
;       .byte #%00100000;--
;       .byte #%00111110;--
	


	


	


	

	
	PAGEALIGN 1
	
	
    


PFRegisterLookup
	.byte 0, 0, 0, 0
	.byte MAZEROWS-1, MAZEROWS-1, MAZEROWS-1, MAZEROWS-1
	.byte (MAZEROWS-1)*2, (MAZEROWS-1)*2, (MAZEROWS-1)*2, (MAZEROWS-1)*2
	.byte (MAZEROWS-1)*3, (MAZEROWS-1)*3, (MAZEROWS-1)*3, (MAZEROWS-1)*3

Tone
	.byte BRICKSOUNDTONE, BULLETSOUNDTONE, ENEMYTANKSOUNDTONE, SHORTBRICKSOUNDTONE
	.byte LONGEXPLOSIONTONE, ENEMYBULLETSOUNDTONE, WALLSOUNDTONE, PLAYERTANKENGINETONE
	.byte SCORESOUNDTONE

Frequency
	.byte BRICKSOUNDFREQ, BULLETSOUNDFREQ, ENEMYTANKSOUNDFREQ, SHORTBRICKSOUNDFREQ
	.byte LONGEXPLOSIONFREQ, ENEMYBULLETSOUNDFREQ, WALLSOUNDFREQ, PLAYERTANKENGINEFREQ
	.byte SCORESOUNDFREQ

SoundLength
	.byte BRICKSOUNDLENGTH, BULLETSOUNDLENGTH, ENEMYTANKSOUNDLENGTH, SHORTBRICKSOUNDLENGTH
	.byte LONGEXPLOSIONLENGTH, ENEMYBULLETSOUNDLENGTH, WALLSOUNDLENGTH, PLAYERTANKENGINELENGTH
	.byte SCORESOUNDLENGTH

	
;****************************************************************************

TankFractionalAddition	
	lda TankStatus,X
	asl
	asl
	asl
	asl
	ora #$1F
    clc
    adc TankFractional,X
	sta TankFractional,X
    rts

;****************************************************************************
	


	
;--can combine these two tables, and probably otherwise make this much smaller.  left for later lol :)
TankTargetAdjustmentX 
    .byte 0, 0, 0, 0
    .byte -PINKYADJUSTMENTX, 0, 0, 0
    .byte PINKYADJUSTMENTX
TankTargetAdjustmentY 
    .byte 0, PINKYADJUSTMENTY, -PINKYADJUSTMENTY, 0
    .byte 0, 0, 0, 0
    .byte 0
	
BulletDirectionClear
BulletUp
	.byte	BULLETUP, BULLETUP<<2, BULLETUP<<4, BULLETUP<<6
BulletDown
	.byte	BULLETDOWN, BULLETDOWN<<2, BULLETDOWN<<4, BULLETDOWN<<6
BulletLeft
	.byte	BULLETLEFT, BULLETLEFT<<2, BULLETLEFT<<4, BULLETLEFT<<6
BulletRight
	.byte	BULLETRIGHT, BULLETRIGHT<<2, BULLETRIGHT<<4, BULLETRIGHT<<6

	
	
PFMaskLookup
	.byte $C0, $30, $0C, $03
	.byte $03, $0C, $30, $C0
	.byte $C0, $30, $0C, $03
	.byte $03, $0C, $30, $C0

	

		
EnemyBulletDebounce ;these values * 4 is number of frames between enemy bullet firing
    .byte 30, 20, 19, 18
    .byte 17, 16, 15, 14
    .byte 13, 12, 11, 10
    .byte 9, 8, 7, 6
    .byte 5, 4, 3, 2
    .byte 1	
EnemyBulletDebounceEnd
    

TanksRemainingSpeedBoost = * - 3 
                        ;--just realized the first three values in this table have no effect.  not sure
                        ;   yet if I want to shift the values or not.
;     .byte 15, 10, 8
    .byte 6, 4, 2, 2, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0    
	


TankDirection
	.byte TANKLEFT, TANKRIGHT, TANKDOWN, TANKUP

	
NewTankSpeed = *-1	;--don't use this for player tank, so don't need initial byte
	.byte ENEMYTANKBASESPEED0, ENEMYTANKBASESPEED1, ENEMYTANKBASESPEED2
	
	
PreventReverses = *-1	;--the FF are wasted bytes
	.byte 	~J0DOWN, ~J0UP, $FF, ~J0RIGHT, $FF, $FF, $FF, ~J0LEFT
	
	;tank 0 = player, so don't need initial byte
	;tank 1 target = upper left corner
	;tank 2 target = base (bottom center)
	;tank 3 target = upper right corner
SwitchMovementX = *-1
	.byte 0, 80, 255
SwitchMovementY = *-1
	.byte 255, 0, 255
	
	
NumberOfBitsSet
	.byte 0, 1, 1, 2
	.byte 1, 2, 2, 3
	.byte 1, 2, 2, 3
	.byte 2, 3, 3, 4
MovementMask
	.byte J0UP, J0DOWN, J0LEFT, J0RIGHT
	
; RotationTablesBank1
; 	.word RotationEvenBank1, RotationOddBank1	
; 	
; RotationOddBank1
; 	.byte 0	;and first 3 bytes of next table
; RotationEvenBank1
; 	.byte 2, 1, 3, 0
; 
    

TitleScreenSong
    .word SilencePattern
    .word SilencePattern
    .word SilencePattern
    .word SilencePattern
    .word Fanfare1Pattern
    .word Fanfare2Pattern
    .word Fanfare1Pattern
    .word Fanfare3Pattern
    .word $FFFF
    .byte 2<<4


FanfarePattern
SilencePattern
    .byte VOLUME0, VOLUME0, VOLUME0, VOLUME0
    .byte VOLUME0, VOLUME0, VOLUME0, VOLUME0
    .byte VOLUME0, VOLUME0, VOLUME0, VOLUME0
    .byte VOLUME0, VOLUME0, VOLUME0, VOLUME0
 
    
Fanfare1Pattern
    .byte VOLUME6|SQUARE_23
    .byte VOLUME6|SQUARE_23|ARTICULATE
    .byte VOLUME6|SQUARE_23|ARTICULATE
    .byte VOLUME6|SQUARE_23|ARTICULATE
    .byte VOLUME6|SQUARE_23
    .byte VOLUME6|SQUARE_23|ARTICULATE
    .byte VOLUME6|SQUARE_26
    .byte VOLUME6|SQUARE_26|ARTICULATE
    .byte VOLUME6|SQUARE_23
    .byte VOLUME6|SQUARE_23
    .byte VOLUME6|SQUARE_23
    .byte VOLUME6|SQUARE_23
    .byte VOLUME6|SQUARE_23
    .byte VOLUME6|SQUARE_23
    .byte VOLUME6|SQUARE_23
    .byte VOLUME6|SQUARE_23|ARTICULATE
Fanfare2Pattern
    .byte VOLUME6|SQUARE_23
    .byte VOLUME6|SQUARE_23|ARTICULATE
    .byte VOLUME6|SQUARE_23|ARTICULATE
    .byte VOLUME6|SQUARE_23|ARTICULATE
    .byte VOLUME6|SQUARE_23
    .byte VOLUME6|SQUARE_23|ARTICULATE
    .byte VOLUME6|SQUARE_26
    .byte VOLUME6|SQUARE_26|ARTICULATE
    .byte VOLUME6|SQUARE_19
    .byte VOLUME6|SQUARE_19
    .byte VOLUME6|SQUARE_19
    .byte VOLUME6|SQUARE_19|ARTICULATE
    .byte VOLUME6|SQUARE_20
    .byte VOLUME6|SQUARE_20
    .byte VOLUME6|SQUARE_20
    .byte VOLUME6|SQUARE_20|ARTICULATE

Fanfare3Pattern
    .byte VOLUME6|SQUARE_23
    .byte VOLUME6|SQUARE_23|ARTICULATE
    .byte VOLUME6|SQUARE_23|ARTICULATE
    .byte VOLUME6|SQUARE_23|ARTICULATE
    .byte VOLUME6|SQUARE_23
    .byte VOLUME6|SQUARE_23|ARTICULATE
    .byte VOLUME6|SQUARE_26
    .byte VOLUME6|SQUARE_26|ARTICULATE
    .byte VOLUME6|SQUARE_31
    .byte VOLUME6|SQUARE_31
    .byte VOLUME6|SQUARE_31
    .byte VOLUME6|SQUARE_31|ARTICULATE
    .byte VOLUME6|SQUARE_26
    .byte VOLUME6|SQUARE_26
    .byte VOLUME6|SQUARE_26
    .byte VOLUME6|SQUARE_26|ARTICULATE
    
    
LevelStartSong
    .word Fanfare1Pattern
    .word SilencePattern
    .word $FFFF
    .byte 1<<4
    
    
LevelStartFanfarePattern
    .byte VOLUME6|SQUARE_23
    .byte VOLUME6|SQUARE_23|ARTICULATE
    .byte VOLUME6|SQUARE_23|ARTICULATE
    .byte VOLUME6|SQUARE_23|ARTICULATE
    .byte VOLUME6|SQUARE_23
    .byte VOLUME6|SQUARE_23|ARTICULATE
    .byte VOLUME6|SQUARE_26
    .byte VOLUME6|SQUARE_26|ARTICULATE
    .byte VOLUME6|SQUARE_23
    .byte VOLUME6|SQUARE_23
    .byte VOLUME6|SQUARE_23
    .byte VOLUME6|SQUARE_23
    .byte VOLUME6|SQUARE_23
    .byte VOLUME6|SQUARE_23
    .byte VOLUME6|SQUARE_23
    .byte VOLUME6|SQUARE_23|ARTICULATE

    
    
     
FillPatternTable
    .word DrumFillSnaresOnly1, DrumFillWithKick1
    .word DrumFillSnaresOnly2, DrumFillWithKick2
    .word DrumFillSnaresOnly3, DrumFillWithKick3
    .word DrumFillSnaresOnly1, DrumFillWithKick1
BeatPatternTable
    .word DrumBeatSnaresOnly1, DrumBeatWithKick1
    .word DrumBeatSnaresOnly1, DrumBeatWithKick1
    .word DrumBeatSnaresOnly1, DrumBeatWithKick1
    .word DrumBeatSnaresOnly1, DrumBeatWithKick1

 ;bits: each byte is four 32nds, reading left to right, 2-bit groups.
 ;  two-byte groups are each one beat
    ;00 = no percussion
    ;01 = snare 1
    ;02 = snare 2
    ;03 = kick
DrumBeatSnaresOnly1 
    .byte %10000000, %10000100

DrumFillSnaresOnly1
    .byte %10000100, %10000100
DrumFillSnaresOnly2
    .byte %10001001, %10000100
DrumFillSnaresOnly3
    .byte %10011001, %10000100

DrumBeatWithKick1 
    .byte %11000000, %10000100
DrumFillWithKick1
    .byte %11000100, %10000100
DrumFillWithKick2
    .byte %11001001, %10000100
DrumFillWithKick3
    .byte %11011001, %10000100
    

    ;for the following three tables, zero is not used as in index into them
PercussionVolumeTable = * - 1
    .byte PERCUSSIONVOLUME, PERCUSSIONVOLUME, PERCUSSIONVOLUME
PercussionDistortionTable = * - 1
    .byte SNARESOUND, SNARE2SOUND, KICKSOUND
PercussionFrequencyTable = * - 1
    .byte SNAREPITCH, SNARE2PITCH, KICKPITCH
    
ArticulationTable   ;--routine as currently written will never read the first and fourth values
	.byte 0,4, 2, 0
	.byte 0,0,0,0
    
DistortionTable
    .byte SQUARESOUND, SQUARESOUND, SQUARESOUND, SQUARESOUND
    .byte SQUARESOUND

FrequencyTable
    .byte 19, 20, 23, 26
    .byte 31

    
TankDeadStatusBank0
    .byte TANKUP|TANKDEADWAITPLAYER, TANKUP|TANKDEADWAIT, TANKUP|TANKDEADWAIT, TANKUP|TANKDEADWAIT
    
;------------------------------------------------------------------------------------------
	
    echo "----", ($1FD5-*), " bytes left (ROM) at end of Bank 1"

	org $1FD1
	rorg $1FD1
	
	;BRK vector comes here, call with:
	;   BRK
	;   .word AddressOfRoutine
	;routines can be moved to any bank (even the same bank as the calling routine) 
	;without changing how they are called.  
	;Banks must be RORGed to different (odd-numbered) banks ($1000, $3000, $5000, etc)
	;and first bank must be at $1000, second at $3000, etc.
	;Routines must return with:
	;   JMP ReturnFromBSSubroutine1 ;see below
	;Advantages:
	;   no jump tables to maintain
	;   routines can be moved from one bank to another with changing bank switching code
	;   bank switching code is fairly compact, approx 38 bytes.
	;   code to call a routine that may (or may not!) be in another bank is extemely compact,
	;       takes no more room than a regular JSR
	;   code to call a routine that may be in another bank is very readable, almost as readable
	;       as a regular JSR
	;   uses no RAM
	;Disadvantages
	;   38 bytes per bank can add up, hand-coded bank switching logic could potentially be more compact, at the expense of some clarity/flexibility
	;   bank switch code uses (briefly) 3 bytes of stack space, more than a JSR call, and trashes accumulator and X register.
	;   very slow:
	;       regular subroutine call: 6 cycles for JSR, 6 cycles for RTS for 12 total to call and return
	;       this bank-switching code:   65 cycles for call (BRK + code below), 29 to return for 94 cycles total
	;       admittedly, the proper comparison isn't to a JSR/RTS combination, but rather to some other bank-switching code, and
	;           there the comparison isn't quite as awful.  But still, the flexibility and clarity comes with a price.
BankSwitchSubroutine1 
	plp             ;+4         BRK pushed flags onto stack, pull off and discard
	tsx             ;+2     6
	dec $01,X       ;+6    
	lda ($01,X)     ;+6         low byte of routine we are jumping to
	sta MiscPtr     ;+3     21
	inc $01,X       ;+6
	lda ($01,X)     ;+6         high byte of routine we are jumping to
	sta MiscPtr+1   ;+3     36
   	lsr
	lsr
	lsr
	lsr
	lsr
	tax             ;+12    48
	nop $1FF8,X     ;+5     53  uses top 3 bits of address to determine which bank to switch to

	jmp (MiscPtr)   ;+5     58
	
ReturnFromBSSubroutine1
	tsx             ;+2
	lda $02,X       ;+4      6  get high byte of return address
	lsr
	lsr
	lsr
	lsr
	lsr
	tax             ;+12    18
	nop $1FF8,X     ;+5     23  uses top 3 bits of address to determine which bank to switch to
	rts             ;+6     29
EndBankSwitchRoutine1


	;--reserve space for hot spots

    org $1FF8
    rorg $1FF8
    
    ds 2


	org $1FFC
    rorg $1FFC
    
	.word Start+3
	.word BankSwitchSubroutine1

;----------------------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------------------
;---------------------------------        BANK TWO           ----------------------------------------
;----------------------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------------------


	org $2000
	rorg $3000

Start2
	sta $1FF8

	

;----------------------------------------------------------------------------
;----------------------Kernel Routine----------------------------------------
;----------------------------------------------------------------------------
	
KernelRoutineGame

; KernelSetupSubroutine


	;rotate Tanks through Players and Missiles
	
	lda FrameCounter
	and #1
	asl
	tax
	lda RotationTables,X  
	sta MiscPtr
	lda RotationTables+1,X
	sta MiscPtr+1
	ldy #3
RotationLoop
	lax (MiscPtr),Y
	lda TankX,Y
	sta PlayerX,X
	lda TankY,Y
	sta PlayerY,X
	txa
	lsr		;--only setup gfx pointer when the tank is displayed with the player (i.e., X = 0 or 1)
	beq PlayerNotMissile
    jmp MissileNotPlayer	
	
PlayerNotMissile
	;--get correct tank gfx ptr set up
	txa
	asl
	asl
; 	tax		;we need X * 4
	sta Temp		;save X index
	;--if Y = 0 then we are doing player tank.  Check if not moving.
	tya ;set flags based on Y
	bne NotPlayerTankSkipNotMovingCheck
	;--how do we know if tank is not moving?  
	lda TankStatus
	and #TANKSPEED
	bne PlayerTankMovingSetRegularGraphicsPointers
	lda #8
    bne TankGfxIndexSet ;branch always
	;--end
PlayerTankMovingSetRegularGraphicsPointers
    lda FrameCounter
    and #%00001100
    lsr
    adc #8
    bne TankGfxIndexSet ;branch always

NotPlayerTankSkipNotMovingCheck
	;--get index into tank graphics image
	lda FrameCounter
	lsr
	and #%00000110      ;0, 2, 4, 6
TankGfxIndexSet
	tax

	
	;--if tank is dead, use one specific gfx
	lda TankStatus,Y
	;and #TANKINPLAY
; 	bne TankInPlayUsualGraphics
	lsr     ;get TANKINPLAY bit into carry
	bcs TankInPlayUsualGraphics
	;--if direction = TANKDOWN use power up symbol
	and #TANKDOWN>>1        ;shifted over since we LSR above
	bne UsePowerUpGraphic
	;--else use explosion graphic
	lda #<(TankKilledImage+TANKHEIGHT)
	pha
	lda #>(TankKilledImage+TANKHEIGHT)
    bne SetTankGfxPtr   ;branch always
UsePowerUpGraphic
	lda #<(PowerUpImage1+TANKHEIGHT)
	pha
	lda #>(PowerUpImage1+TANKHEIGHT)
    bne SetTankGfxPtr   ;branch always

	
TankInPlayUsualGraphics
	lda TankStatus,Y
	and #TANKUP
	beq TankNotFacingUp
	
	lda TankUpFrame,X
	pha
	lda TankUpFrame+1,X
	bne SetTankGfxPtr   ;branch always
TankNotFacingUp
	lda TankStatus,Y
	and #TANKDOWN
	beq TankNotFacingDown
	lda TankDownFrame,X
	pha
	lda TankDownFrame+1,X
	bne SetTankGfxPtr   ;branch always
TankNotFacingDown
	lda TankStatus,Y
	and #TANKRIGHT
	beq TankNotFacingRight
	lda TankRightFrame,X
	pha
	lda TankRightFrame+1,X
	bne SetTankGfxPtr   ;branch always
TankNotFacingRight
	lda TankRightFrame,X
	pha
	lda TankRightFrame+1,X
SetTankGfxPtr
    ldx Temp
	sta Player0Ptr+1,X
	sta Player0Ptr+3,X
	pla
	sec
	sbc TankY,Y
	sta Player0Ptr,X
	clc
	adc #TANKHEIGHT
	sta Player0Ptr+2,X
	jmp EndRotationLoop
MissileNotPlayer
    	
	;--adjust missile width and position
	txa
	and #1
	tax		;get correct index
    ;--if tank not in play, don't display missile
    lda TankStatus,Y
    and #TANKINPLAY
    bne MissileOnScreen
    lda #TANKAREAHEIGHT+20
    sta MissileY,X
MissileOnScreen
  	lda MissileX,X
	sec
	sbc #2
	sta MissileX,X
	lda #OCTWIDTHMISSILE
	sta NUSIZ0,X
	lda #TANKHEIGHT-2
	sta MissileHeight,X
EndRotationLoop
	dey
	bmi DoneWithRotationLoop
	jmp RotationLoop
DoneWithRotationLoop
	
	
	lda #TANKAREAHEIGHT
	sec
	sbc PlayerY+1
	adc #TANKHEIGHT
	asl
	sta PlayerYTemp

	lda PlayerY
	sta Player0Top
	sec
	sbc #TANKHEIGHT	
	ora #$80
	sta Player0Bottom
	lda PlayerY
	cmp #TANKAREAHEIGHT
	bcc NoSpecialAdjustmentToPlayer0Top
	lda Player0Bottom
	sta Player0Top	

NoSpecialAdjustmentToPlayer0Top



	ldx #1
PreKernelSetupLoop2
	lda #TANKAREAHEIGHT+1
	sec
	sbc MissileY,X
	adc MissileHeight,X
	sta MissileYTemp,X
	
	lda MissileX,X
	clc
	adc #3
	sta MissileX,X
	dex
	bpl PreKernelSetupLoop2
	
	
	;--if missile Y is above the playable area, need to adjust down by ... 1 line?
	ldx #1
AdjustMissileYLoop
	lda MissileYTemp,X
	cmp #TANKHEIGHT-2
	bcs NoAdjustMissileY 
	adc #1
	sta MissileYTemp,X
NoAdjustMissileY
	dex
	bpl AdjustMissileYLoop
	
	;--cycle BaseColor
	lda #(BASECOLOR)&($F0)
    sta Temp+1
	
	lda FrameCounter
	and #$0F
	ora Temp+1
	sta Temp+1

	;bullet flicker rotation:
	and #3
	tax
	lda BulletX,X
	sta BallX
	lda BulletY,X
	sta BallY

	
	;--set up score pointers
	
	ldx #10
	txa
SetupScorePtrsLoop
	lsr
	lsr
	tay
	lda Score,Y
	pha
	and #$0F
	tay
	lda DigitDataLo,Y
	sta ScorePtr,X
	pla
	lsr
	lsr
	lsr
	lsr
	tay
	lda DigitDataLo,Y
	sta ScorePtr-2,X
	lda #>DigitData
	sta ScorePtr+1,X
	sta ScorePtr-1,X
    txa
    sec
    sbc #4
    tax
	bpl SetupScorePtrsLoop
	;--room for score up here?

; 	lda #RIGHTEIGHT
; 	sta HMM1            ;what is this for?

	SUBROUTINE
	if DEBUGTANKAICOUNTER = 1
        lda TankMovementCounter
        cmp #TANKAISWITCH
        bcs .tankaidebug
        lda #BLUE|$4
        bcc .tankaidebugend
.tankaidebug
    	lsr
    	lsr
    	lsr
    	lsr
    	ora #WALLCOLOR&$F0
.tankaidebugend
    ELSE
        lda GameStatus
        and #GAMEOVER
        beq RegularWallColor
        lda TankMovementCounter
        asl ;--get WALLDONEFLASHING bit into carry
        bcc WallFlashingColor
        lda #0
WallFlashingColor
        lsr
        and #$0F
        ora #(WALLCOLOR&$F0)
        bne SetWallColor
RegularWallColor
        lda #WALLCOLOR
SetWallColor        
    ENDIF

    sta Temp+3


WaitForVblankEnd
	lda INTIM
; 	bpl WaitForVblankEnd
	bmi OverTimeVBLANK
	cmp #1
	bne WaitForVblankEnd
	beq EndVBLANK
OverTimeVBLANK				;this nonsense is here just so I can trap an overtime condition in an emulator, if needed
	nop
EndVBLANK	

	
	
	ldy #0
	sta WSYNC
	sta VBLANK
	lda #SCORECOLOR
	sta COLUP0
	sta COLUP1						;+11    11
		
	

	
	;--display score
	lda #THREECOPIESCLOSE|LEFTONE
	sta VDELP0
	sta VDELP1						;+8		19		turn on VDELPx (bit0==1)

	sta NUSIZ0
	sta NUSIZ1						;+6		25

	SLEEP 4                         ;+4     29
	
	sta HMP0						  ;					 LEFTONE
	asl
	sta HMP1						 ;+8		37		LEFTTWO

	sta RESP0						 ;+8		40		positioned at 57 (move left 1)
	sta RESP1						 ;+3		43		positioned at 66 (move left 2)

	sty GRP1
	sty GRP0
	sty ENAM0						 ;+7		50


	sta WSYNC
	sta HMOVE	
	;--waste time efficiently:
	SUBROUTINE
	ldy #10		; 2
.wait
	dey			 ; 2
	bne .wait	 ; 3

	SLEEP 3
	
	ldy #6+1
ScoreKernelLoop				 ;		  59		this loop can't cross a page boundary!
									 ;				(or - if it does, adjust the timing!)
	SLEEP 3
	dey							 ;+5		64
	sty Temp					;+3		67
	lda (ScorePtr),Y
	sta GRP0					  ;+8		75
	lda (ScorePtr+2),Y
	sta GRP1					  ;+8		 7
	lda (ScorePtr+4),Y
	sta GRP0					  ;+8		15
	lda (ScorePtr+6),Y
	tax							 ;+7		22
	lda (ScorePtr+8),Y
	pha							 ;+8		30
	lda (ScorePtr+10),Y
	tay							 ;+7		37
	pla							 ;+4		41
	stx GRP1					  ;+3		44
	sta GRP0
	sty GRP1
	sty GRP0					  ;+9		53
	ldy Temp					;+3		56
	bne ScoreKernelLoop		;+3		59
									 ;		  58
	sty GRP0
	sty GRP1
	sty GRP0					  ;+9		67	
	
	
	lda #ONECOPYNORMAL|OCTWIDTHMISSILE
	sta NUSIZ0
	sta NUSIZ1                  ;+8     75
	
	;--tank colors
SetTankColors	
	lda FrameCounter
	and #1
    tax
    lda P0M0Color,X
    sta COLUP0
    lda P1M1Color,X
    sta COLUP1	                ;+21    20
	

	
	;--reflect P0 or P1 as necessary.   prep for flip loop below
    txa
	asl
	tax
	lda RotationTables,X        ;RotationTablesBank1 if moved back to bank 1
	sta MiscPtr
	lda RotationTables+1,X
	sta MiscPtr+1               ;+20    40
	
    
    lda Temp+3
	sta COLUPF                  ;+6     46
	;--do this above...the rest we do during the wall below.  

	;---reflect P0/P1
	;--this loop is garbage, need to rewrite so it is faster.... though not sure how, actually.
	ldy #3              ;+2     24
SetREFPLoop
	lax (MiscPtr),Y		;+5      5      get X index into graphics registers
	lda TankStatus,Y    ;+4      9
	and #TANKLEFT       ;+2     11
	beq EndREFPLoop     ;+2/3   13/14    only if facing left do we reflect
	cpx #2              ;+2     15
	bcs EndREFPLoop     ;+2/3   17/18
	lda #$FF            ;+2     19      1 or 0 (players) get reflected, 2 and 3 (missiles) do not
	sta REFP0,X	        ;+4     23
EndREFPLoop             ;       14/18/23
	dey                 
	bpl SetREFPLoop     ;+5     19/23/28
    ;loop minimum time is 76 cycles.  maximum is 101
    ;                   ;+76    98  (or 22)
    ;                   ;+101   135 (or 59)

	
	
    sta WSYNC
	
	ldx #$C0
	lda #$FF                        ;+4     13
; 	sta WSYNC
; 	sta HMCLR
	stx PF0
	sta PF1
	sta PF2                         ;+9     22
	
	ldx #4
; PositioningLoopVBLANK	;--excluding players (and M1)
	lda PlayerX+4;,X
	jsr PositionASpriteSubroutineBank2   ;        9
; 	dex
; 	cpx #3
; 	bne PositioningLoopVBLANK
	
    ldy #255
	sty VDELP0  
	sty VDELBL          ;+6

	iny                 ;Y = 0
	sty VDELP1          ;+5     11
	;save stack pointer
	tsx
	stx Temp           ;+5      16

	ldx #3
PositioningLoop	;--just players
	lda PlayerX,X
	jsr PositionASpriteSubroutineBank2  ;this needs 14 cycles before end of scanline or it will wrap around and give an extra scanline
	dex
	bpl PositioningLoop     ;       13 cycles last time through
    
	sty PF1                 ; Y is zero
	sty PF2					;
	sta CXCLR               ;+9     22

	;--use stack pointer to hit ENABL
	ldx #<ENABL
	txs						;+4		26
	
	nop
    nop
    
	ldy #TANKAREAHEIGHT		;+2		30

		
	jmp BeginMainMazeKernel ;+3     33

	
    PAGEALIGN 2
	
Switch0
	lda Player0Bottom
	sta Player0Top
	bne BackFromSwitch0

Wait0
	nop
	nop
	bpl BackFromSwitch0
	
Switch1
	lda Player0Bottom
	sta Player0Top
	bne BackFromSwitch1

Wait1
	nop
	nop
	bpl BackFromSwitch1
	
	
	
BeginMainMazeKernel


	

	
KernelLoop
	;draw player 0
	cpy Player0Top				
	beq Switch0
	bpl Wait0
	lda (Player0Ptr),Y
	sta GRP0				;+15	50
BackFromSwitch0	
	

	ldx BlockRowTable-BLOCKHEIGHT-1,Y	;+4		54

	;draw player 1
	lda #TANKHEIGHT*2-1
	dcp PlayerYTemp
	bcs DoDraw10
	lda #0
	.byte $2C
DoDraw10
	lda (Player1Ptr),Y
	sta GRP1				;+18	72



	;draw missile 0
	lda #TANKHEIGHT-2
	dcp MissileYTemp
	sbc #TANKHEIGHT-4
	sta ENAM0				;+12	 8
	
	
	lda #TANKHEIGHT-2
	dcp MissileYTemp+1
	sbc #TANKHEIGHT-4
	sta ENAM1				;+12	20
	

	
	
	lda PF1Left,X
	sta PF1				;+7		27
	lda PF2Left,X
	sta PF2				;+7		34
	
	lda PF1Right,X
	sta PF1				;+7		41
	lda PF2Right,X
	sta PF2				;+7		48

	tsx					;+2		50
	cpy BallY
	php
	txs					;+8		58
	
	
	cpy Player0Top				
	beq Switch1
	bpl Wait1
	lda (Player0Ptr+2),Y		
	sta GRP0			;+15	73
BackFromSwitch1
	
	
	;draw player 1
	lda #TANKHEIGHT*2-1
	dcp PlayerYTemp
	bcs DoDraw11
	lda #0
	.byte $2C
DoDraw11
	lda (Player1Ptr+2),Y
	sta GRP1			;+18	15
	
	lda #0
	sta PF1
	sta PF2				;+8		23
	
	
	dey
	cpy #BLOCKHEIGHT
	beq KernelLastRow	;+6		29
	SLEEP 3
	bne KernelLoop		;+6		35

	
Switch0b
	lda Player0Bottom
	sta Player0Top
	bne BackFromSwitch0b

Wait0b
	nop
	nop
	bpl BackFromSwitch0b
	
Switch1b
	lda Player0Bottom
	sta Player0Top
	bne BackFromSwitch1b

Wait1b
	nop
	nop
	bpl BackFromSwitch1b
	
KernelLastRow				;		31		branch here crosses page boundary
	;lda #$80
	;sta PF2
	SLEEP 5
	;line 1 of last row, this row has BASE (not wall)
KernelLastRowLoop			;		36
	lda Temp+1
	sta COLUPF				;+6		42
	;draw player 0
	cpy Player0Top				
	beq Switch0b
	bpl Wait0b
	lda (Player0Ptr),Y
	sta GRP0				;+15	57
BackFromSwitch0b
	
	lda Temp+3;#WALLCOLOR
	sta COLUPF				;+5		62
	

	;draw player 1
	lda #TANKHEIGHT*2-1
	dcp PlayerYTemp
	bcs DoDraw10b
	lda #0
	.byte $2C
DoDraw10b
	lda (Player1Ptr),Y
	sta GRP1				;+18	 4


	;line 2 of last row, has WALL (not base)
	;draw missile 0
	lda #TANKHEIGHT-2
	dcp MissileYTemp
	sbc #TANKHEIGHT-4
	sta ENAM0				;+12	16
	
	
	lda #TANKHEIGHT-2
	dcp MissileYTemp+1
	sbc #TANKHEIGHT-4
	sta ENAM1				;+12	28
	
	
	lda LastRowL
	sta PF2					;+6		34
	
	SLEEP 5					;		40

	
	lda LastRowR
	sta PF2					;+6		46
	
	tsx
	cpy BallY
	php
	txs						;+10	56
	
	
	
	cpy Player0Top				
	beq Switch1b
	bpl Wait1b
	lda (Player0Ptr+2),Y		
	sta GRP0				;+15	71
BackFromSwitch1b
	
	
	;draw player 1
	lda #TANKHEIGHT*2-1
	dcp PlayerYTemp
	bcs DoDraw11b
	lda #0
	.byte $2C
DoDraw11b
	lda (Player1Ptr+2),Y
	sta GRP1			;+18	13
	
	lda LastRowL
	sta PF2				;+6		19

    ;--don't draw base sometimes	
    lda GameStatus
    and #DRAWBASE
    beq DoNotDrawBase   ;7 if branch not taken.  8 if taken.
	
	lda #$80
	sta PF2				;+5		31
	dey
	bne KernelLastRowLoop		;+5		36
	beq DoneWithKernelLastRowLoop   ;is this necessary?
DoNotDrawBase
    sta.w PF2           ;+4
    dey
    bne KernelLastRowLoop
DoneWithKernelLastRowLoop
	sty PF2		;AKSHUALLY don't display base on last row
	ldx Temp
	txs			;+8		44

	sty ENABL	;+3		47
	sty GRP0	;+3		50
	ldy #$FF	;+2		52
	ldx #0		;+2		54
	sta WSYNC
	sty PF2		;+3		57
	sty PF1		;+3		60
	stx GRP1	
	stx ENAM0
	stx ENAM1
;	sta PF0
	
;     sta HMCLR
	lda #104
; 	jsr PositionASpriteNoHMOVESubroutine
    jsr PositionASpriteSubroutineBank2	

	lda #112
	inx
; 	jsr PositionASpriteNoHMOVEOrHMCLRSubroutine
    jsr PositionASpriteSubroutineBank2	
    
	lda #60
	inx
; 	jsr PositionASpriteNoHMOVEOrHMCLRSubroutine
    jsr PositionASpriteSubroutineBank2	

	lda #66
	inx
; 	jsr PositionASpriteNoHMOVEOrHMCLRSubroutine
    jsr PositionASpriteSubroutineBank2	    ;returns at cycle 9

	
	;--done displaying maze
	;--set up score, tanks remaining, lives remaining etc

 	sta WSYNC
; 	sta HMOVE
	ldy #0                  ;+2
	sty PF0                 
	sty PF1
	sty PF2
	sty COLUPF
	sty REFP0
	sty REFP1
	sty VDELP0
	sty VDELBL              ;+24    26
	lda #THREECOPIESCLOSE
	sta NUSIZ0
	lda #TWOCOPIESCLOSE
	sta NUSIZ1              ;+10    36
	
	lda #TANKSREMAININGCOLOR
	sta COLUP0
	sta COLUP1
	sta HMCLR               ;+11    47
	

	lda #>DigitDataMissile
	sta Player0Ptr+3
	sta Player1Ptr+1        ;+8     55
	lda MazeNumber
	lsr
	lsr
	lsr
	lsr
	tay
	lda DigitDataMissileLo,Y
	sta Player0Ptr+2
	lda MazeNumber
	and #$0F
	tay
	lda DigitDataMissileLo,Y
	sta Player1Ptr

	
    ;this masks the missiles before we want them to show
    ;we will use the actual mask inside the loop below	
	lda #$FF
	sta PF0
	sta PF2                     
	
	sta WSYNC                   ;
	SLEEP 8                     ;+8      8

	
	lda TanksRemaining
	lsr
	tax                         ;+7     15

	lda TanksRemainingPF1Mask,X
	sta PF1                     ;+7     22
	
	lda #2
	sta ENAM0
	sta ENAM1                   ;+8     30
	ldy #8
	bne BottomKernelLoopInner	;+5     35	branch always
	
BottomKernelLoopMiddle			;		18
	dey							;+2		20
	
	lda TanksRemaining
	lsr
	adc #0						;+7		27
	
	tax							;+2		29
	lda TanksRemainingPF1Mask,X
	sta PF1
	lda TanksRemainingPF2Mask,X
	sta PF2						;14		43
	
	lda (Player0Ptr+2),Y		;+5
	sta HMM0					;+3
	asl							;+2
	asl							;+2
	ora #3						;+2
	sta NUSIZ0					;+3		60

	lda (Player1Ptr),Y			;+5		65
	sta HMM1					;+3		68	
	asl							;+2		70
	asl							;+2		72
	ora #3						;+2		74
	sta NUSIZ1					;+3		 1

	sta HMOVE					;+3		 4

	lda TanksRemainingGfx,Y		;+4	     8
	sta GRP0			
	sta GRP1					;+6		14

	bne BottomKernelLoopInnerMiddle	;+3	17		branch always
	
BottomKernelLoopInner			;		35   
    SLEEP 4                     ;+4     39   
	lda (Player0Ptr+2),Y		;+5
	sta HMM0					;+3
	asl							;+2
	asl							;+2
	ora #3						;+2
	sta NUSIZ0					;+3		56      ;this is too early sometimes and causes errant collisions

	lda (Player1Ptr),Y			;+5		
	sta HMM1					;+3			
	asl							;+2
	asl							;+2		
	ora #3						;+2
	sta NUSIZ1					;+3		73      

	sta WSYNC                   ;+3     76      
	
	sta HMOVE					;+3		 3

	lda TanksRemainingGfx,Y		;+4	            
	sta GRP0			
	sta GRP1					;+6		13      
	
	cpy #4						
	beq BottomKernelLoopMiddle	;+5		18     
BottomKernelLoopInnerMiddle     ;       17
	;--PF1 is set once per half loop, this is set here because we enter the loop with PF2=$FF
	;	which is necessary to mask the missiles before we are ready to display them
	lda TanksRemainingPF2Mask,X
	sta PF2
	SLEEP 6						;+13	30		MUST be 10 here so that we don't run over the scanline (>12) or change NUSIZ0 too early (<10)--- OR?????
	dey
	bpl BottomKernelLoopInner	;+5		35      

	
BottomKernelLoopDone
	sta WSYNC
	iny
	sty ENAM0
	sty ENAM1
	sty GRP0
	sty GRP1
	sty GRP0
	sty PF0
	sty PF1
	sty PF2

	jmp ReturnFromBSSubroutine2
	



	
;****************************************************************************	



	
	
;****************************************************************************


	
MoveBulletSubroutine
    ;--if used only hardware collision registers, could just move one bullet every 4 frames.
    ;   but would probably need to redesign tank graphic for that to work.

;     lda #BULLETFRACTIONALSPEED
;     clc
;     adc BulletFractional
;     sta BulletFractional
;     bcs MoveBulletsThisFrame
;     jmp ReturnFromBSSubroutine2
; MoveBulletsThisFrame    
; 	ldx #3
    lda FrameCounter
    and #3
    tax
MoveBulletsLoop
    lda #0
    sta Temp
;     lda BulletFractional
;     clc
    ;--apply update four times (because only once every four frames)
;     adc #BULLETFRACTIONALSPEED
;     rol Temp    ;get carry into Temp  +7
;     adc #BULLETFRACTIONALSPEED
;     rol Temp    ;get carry into Temp  +7
;     adc #BULLETFRACTIONALSPEED
;     rol Temp    ;get carry into Temp  +7
;     adc #BULLETFRACTIONALSPEED
;     rol Temp    ;get carry into Temp  +7      28
;     ;--only actually save this change every four frames.
;     cpx #0
;     bne NoUpdateBulletFractionalThisFrame
;     sta BulletFractional
; NoUpdateBulletFractionalThisFrame
;     ldy Temp
;     lda NumberOfBitsSetBank2,Y       ;+42 (max) this is how many pixels to move

    ;--try diff routine
    lda BulletFractional
    clc
    adc #BULLETFRACTIONALSPEED
    sta Temp+1
    lda #3
    adc #0
    sta Temp
    cpx #0
    bne NoUpdateBulletFractionalThisFrame
    lda Temp+1
    sta BulletFractional
NoUpdateBulletFractionalThisFrame    

    
    

	lda BulletX,X
	;cmp #BALLOFFSCREEN     == 0
	beq NoBulletMovement;BulletOffScreen;
	lda BulletDirection
	and BulletDirectionMask,X
	tay							;save value
	cmp BulletUpBank2,X
	bne BulletNotUp
	;--move bullet up
	lda BulletY,X
	clc
	adc Temp    ;was #BULLETSPEEDVER
	sta BulletY,X
	bcc CheckBulletIsOffScreenVertical      ;branch always
BulletNotUp
	tya
	cmp BulletDownBank2,X
	bne BulletNotDown
	;--move bullet down
	lda BulletY,X
	sec
	sbc Temp    ;was #BULLETSPEEDVER
	sta BulletY,X
	bcc BulletOffScreen                     ;if we are less than zero, then bullet is offscreen
	beq BulletOffScreen                     ;if Y value is zero, then bullet is also offscreen
    bne BulletOnScreen                      ;branch always
BulletNotDown
	tya	
	cmp BulletRightBank2,X
	bne BulletNotRight
	;--move bullet right
	lda BulletX,X
	clc
	adc Temp    ;was #BULLETSPEEDHOR
	sta BulletX,X
	bcc CheckBulletIsOffScreenHorizontal    ;branch always
BulletNotRight	
	tya
	cmp BulletLeftBank2,X
	bne NoBulletMovement
	;--move bullet left
	lda BulletX,X
	sec
	sbc Temp    ;was #BULLETSPEEDHOR
	sta BulletX,X

	;--check for off screen:
CheckBulletIsOffScreenHorizontal
	lda BulletX,X
	cmp #17
	bcc BulletOffScreen
	cmp #144
	bcs BulletOffScreen
	bcc BulletOnScreen
CheckBulletIsOffScreenVertical
	lda BulletY,X
	cmp #(MAZEAREAHEIGHT)+4
	bcc BulletOnScreen	
BulletOffScreen
	lda #BALLOFFSCREEN
	sta BulletX,X       ;<--is this necessary?
	sta BulletY,X	
	;--make noise for when bullet hits outer wall
	ldy #WALLSOUND
	jsr StartSoundSubroutineBank2
NoBulletMovement
BulletOnScreen
; 	dex
; 	bpl MoveBulletsLoop

	jmp ReturnFromBSSubroutine2

	
	
	
	
;****************************************************************************
	
GenerateMazeSubroutine

	;--first, save RandomNumber
	lda RandomNumber
	pha
	
	;--let's try splitting it 
	ldy MazeGenerationPass
	bpl NotFirstPass
	ldy #MAZEGENERATIONPASSES+1+1
	sty MazeGenerationPass
	;--on first pass, make base disappear and fill all with walls
	lda GameStatus
	and #~DRAWBASE
	sta GameStatus
	
	ldx #MAZEROWS-2
	lda #$FF
FillMazeLoop
	sta PF1Left,X
	sta PF2Left,X
	sta PF2Right,X
	sta PF1Right,X
	dex 
	bpl FillMazeLoop
	

	
	
	;--update maze number on first pass also
	sed
	lda MazeNumber
UpdateMazeNumber
	clc
	adc #$01
	sta MazeNumber
	beq UpdateMazeNumber
	cld
    adc #99  ;--don't like the initial maze, too hard with long vertical corridor from the top to the base
	;and set seed for maze
	sta RandomNumber	
	
	;--and that's it for the first pass
	jmp DoneWithFirstPass
	
NotFirstPass
	lda RandomNumberSaved
	sta RandomNumber


	lda #>PF1Left
	sta MiscPtr+1

	;--now what we are doing is going through every other row
	;	starting at a random block on the right, and carving out a random-length
	;	horizontal path to the left.
	;	when we finish that, we pick a random spot to carve a block out of the row below
	;	and then we move two blocks to the left (if there is room), and repeat for another 
	;	random-length horizontal path
	;	once done with a row, we move two rows down and repeat the whole process
	;	Y holds row, X holds block within the row
	dey
	bpl GenerateMazePasses
	jmp LastPassThroughMazeGeneration
GenerateMazePasses
	tya
	asl
	clc
	adc #1
	tay

	jsr UpdateRandomNumberBank2
	and #1
	eor #15
	;--start on random number between 14 and 15
	tax
	dex ;--now start on random number between 13 and 14 
	
	;--if on first pass (top row), always start with X=15
; 	lda MazeGenerationPass
; 	eor #MAZEGENERATIONPASSES+1
; 	sta Temp+2                      ;holds zero if on first pass, non-zero otherwise
; 	bne MakeMazeLoopOuter
; 	ldx #15
	
MakeMazeLoopOuter	
	stx Temp
	stx Temp+1
MakeMazeLoopInner
	lda #<PF1Left
	sta MiscPtr
	
	;--clear block
	lda PFMaskLookupBank2,X
	eor #$FF
	pha
	lda PFRegisterLookupBank2,X
	clc
	adc MiscPtr
	sta MiscPtr
	pla
	and (MiscPtr),Y	
	sta (MiscPtr),Y

	;--are we at the end of our horizontal path?  compare random number to constant
	jsr UpdateRandomNumberBank2 ;returns with RandomNumber in A
	cmp #MAZEPATHCUTOFF
	bcc EndOfRun
	;--not at the end of the run, so loop around
	dec Temp+1
	dex
; 	bmi EndOfRun
;     lda Temp+2  ;holds zero if first pass
;     bne DoNotCarveAllTheWayToLeftInner
;     ;--top row, carve all the way to the left
;     beq MakeMazeLoopInner ;branch always
; DoNotCarveAllTheWayToLeftInner
;     txa
; ; 	bpl MakeMazeLoopInner
    bne MakeMazeLoopInner  ;<--don't go all the way to the left edge (again, unless we are on the first row)
	
    

	;--need to carve a passage downward if we reach this spot:
EndOfRun
	;--don't carve passage downward if we're on the bottom row
	tya
	beq EndRunBeginNextRun
	;--otherwise, find a random passage to carve
	;--Temp holds starting block number (X)
	;--Temp+1 holds ending block number
	lda Temp
	sec
	sbc Temp+1
	sta Temp+1		;now Temp+1 holds length of horizontal passage (minus 1)
 	beq OnlyOnePlaceToCarve
	;--this routine tries to find a random place in our new passage to carve downwards
;  	jsr UpdateRandomNumberBank2
	;--new routine:
	;	decrease length by 1, then remove random bits.  
;	dec Temp+1      ;this is unnecessary, so removed.
	lda Temp+1
	and RandomNumber
	sta Temp+1
OnlyOnePlaceToCarve
	lda Temp
	sec
	sbc Temp+1
	sta Temp+1      ;now Temp+1 holds column to carve down in
	txa
	pha             ;save X index
	ldx Temp+1
	lda AllowCarveDownTable,X
	beq NoCarveDownInThisColumn
	lda PFMaskLookupBank2,X
	eor #$FF
	pha
	lda #<PF1Left
	sta MiscPtr
	lda PFRegisterLookupBank2,X
	clc
	adc MiscPtr
	sta MiscPtr
	pla
	pha
	dey
	and (MiscPtr),Y
	sta (MiscPtr),Y
	pla
	dey
	bmi AtBottomRow
	and (MiscPtr),Y
	sta (MiscPtr),Y
AtBottomRow
	iny	
	iny		;restore Y to current row index
NoCarveDownInThisColumn
	pla		;get block index back into X
	tax
	dex
	dex
	bmi DoneWithRow

;     lda Temp+2  ;holds zero if first pass
;     bne DoNotCarveAllTheWayToLeft
;     ;--top row, carve all the way to the left
;     beq MakeMazeLoopOuter ;branch always
; ;     txa
; ;     bpl MakeMazeLoopOuter
; DoNotCarveAllTheWayToLeft
;     txa
    bne MakeMazeLoopOuter ;<--don't carve all the way to the left edge
EndRunBeginNextRun

	
DoneWithRow
DoneWithFirstPass
	dec MazeGenerationPass

; 	bpl NotCompletelyDoneWithMaze
    jmp NotCompletelyDoneWithMaze
LastPassThroughMazeGeneration

	;--final touchup:
	;	open up area directly above base:
	;--- change to CLOSE up area directly above base, not sure about this.
	lda PF2Left
	ora #$F0
	sta PF2Left
	lda PF2Right
	ora #$F0
	sta PF2Right

	;--add walls on bottom row surrounding base
	lda #$30
	sta LastRowL
	sta LastRowR
	
	;	leave room for enemy tanks to enter:
	IF DEBUGMAZE = 1
	
    	ldx #0
    	stx PF1Left+MAZEROWS-2
    	stx PF1Right+MAZEROWS-2
    	stx PF2Left+MAZEROWS-2
    	stx PF2Right+MAZEROWS-2
    	ldx #$FF
    	stx PF1Left+MAZEROWS-3
    	stx PF1Right+MAZEROWS-3
    	stx PF2Left+MAZEROWS-3
    	stx PF2Right+MAZEROWS-3

   	ELSE
	    
    	ldx #$0C
    	txa
    	;clear blocks in top row that are entry points
    	and PF1Left+MAZEROWS-2
    	sta PF1Left+MAZEROWS-2
    	
    	;clear upper R corner
    	txa
    	and PF1Right+MAZEROWS-2
    	sta PF1Right+MAZEROWS-2
	
;     	ldx #$0C
    	txa
    	and PF2Left+MAZEROWS-2
    	sta PF2Left+MAZEROWS-2
    	txa
    	and PF2Right+MAZEROWS-2
    	sta PF2Right+MAZEROWS-2
	
    ENDIF

	;--clear left and right blocks on the rows where tanks enter when player is near top of screen
	ldy #5
ClearSideEntryPointsLoop
    lda EntryPointRowOffsetTable,Y
    tax
    lda #$3F
    and PF1Left,X
    sta PF1Left,X
    lda #$3F
    and PF1Right,X
    sta PF1Right,X
	dey
	bpl ClearSideEntryPointsLoop

	
	;--if top corner entry points are enclosed, add escape routes downward
	lda PF1Left+MAZEROWS-2 ;top left
	and #%00001100
	beq TopLeftCornerNotEnclosed
	lda PF1Left+MAZEROWS-3
	and #%11001111
	sta PF1Left+MAZEROWS-3
	lda PF1Left+MAZEROWS-4
	and #%11001111
	sta PF1Left+MAZEROWS-4
TopLeftCornerNotEnclosed
	lda PF1Right+MAZEROWS-2 ;top right
	and #%00001100
	beq TopRightCornerNotEnclosed
	lda PF1Right+MAZEROWS-3
	and #%11001111
	sta PF1Right+MAZEROWS-3
	lda PF1Right+MAZEROWS-4
	and #%11001111
	sta PF1Right+MAZEROWS-4
TopRightCornerNotEnclosed

    
    ;--more escape routes, this time for the right side
    lda PF1Right+MAZEROWS-6
    and #%11001111
    sta PF1Right+MAZEROWS-6
    lda PF1Right+MAZEROWS-8
    and #%11001111
    sta PF1Right+MAZEROWS-8
    lda PF1Right+MAZEROWS-7
    and #%00001100
    beq SkipCreatingConnectingPassageRight
    lda PF1Right+MAZEROWS-7
    and #%11001111
    sta PF1Right+MAZEROWS-7
SkipCreatingConnectingPassageRight
    ;--more escape routes, this time for the left side
    lda PF1Left+MAZEROWS-6
    and #%11001111
    sta PF1Left+MAZEROWS-6
    lda PF1Left+MAZEROWS-8
    and #%11001111
    sta PF1Left+MAZEROWS-8
    lda PF1Left+MAZEROWS-7
    and #%00001100
    beq SkipCreatingConnectingPassageLeft
    lda PF1Left+MAZEROWS-7
    and #%11001111
    sta PF1Left+MAZEROWS-7
SkipCreatingConnectingPassageLeft
    
    

	
	
	
	;--and clear GAMEOFF flag and turn off maze generation flag, and make base reappear
	lda GameStatus
	and #~(GENERATINGMAZE|GAMEOFF)
	ora #DRAWBASE
	sta GameStatus
	
	;--set music to correct starting location
    lda #255
    sta SongIndex

	;--set starting tank position
	
	;--move tanks and bullets off screen
	lda #255		;--loop until X = 255 (-1)
	jsr MoveEnemyTanksOffScreen	
	
	lda #TANKAISWITCH+1
	sta TankMovementCounter ;enemy tanks start in regular movement mode at beginning of every level....maybe?  
	
	
	;--does this nonsense below work?  Isn't MazeNumber a BCD value?  I think it still does work, but this is sloppy and probably should be fixed at some point.
	lda MazeNumber
	asl
	clc
	adc #6
	;lda #STARTINGENEMYTANKCOUNT
	cmp #20
	bcc SetInitialTanksRemaining
    lda #20
SetInitialTanksRemaining
	sta TanksRemaining
	
	;--starting timers for when tanks enter the maze
	;--rewrite this:
	ldx #3
SetNewLevelTankDelay
    lda StartingTankStatus,X
    sta TankStatus,X
    dex
    bpl SetNewLevelTankDelay
    
    ;--cheap hack to make player show up faster
    and #~TANKRESPAWNWAIT  ;clear the wait
    ora #PLAYERINITIALDELAY
    sta TankStatus
    
    ;--and finally, set MazeGenerationPass to zero because we'll use that for powerups/bonuses during the level
    ;--set number of tanks to kill before power up appears randomly
    pla
    pha     ;get actual random number but leave on stack
    and #POWERUPCOUNTDOWNBITS
    bne SetPowerUpCountdownValue
    lda #POWERUPCOUNTDOWNBITS   ;make sure it doesn't start at zero
SetPowerUpCountdownValue   
    sta MazeGenerationPass
	
NotCompletelyDoneWithMaze
	;--restore original random number
	lda RandomNumber
	sta RandomNumberSaved          ;save current random number in maze generation (this means maze generation starts random but each seed is consistent)
	pla
	sta RandomNumber
	
	jmp ReturnFromBSSubroutine2
	

;****************************************************************************

UpdateRandomNumberBank2
    lda RandomNumber
    lsr
    bcc .SkipEOR
    eor #$B2
.SkipEOR
    sta RandomNumber
    rts

;****************************************************************************


	
	
MoveEnemyTanksOffScreen
	sta Temp
	ldx #3
	ldy #6
SetStartingEnemyTankLocationsLoop
	lda StartingTankXPosition,Y
	sta TankX,X
	lda StartingTankYPosition,Y
	sta TankY,X
	dey
	dey
	dex
	cpx Temp                ;6, 4, 2, 0, 254
	bne SetStartingEnemyTankLocationsLoop
	
	rts	

	
;****************************************************************************
	
MoveBulletsOffScreen
	ldx #3
	lda #BALLOFFSCREEN
RemoveBulletsFromScreenLoop
	sta BulletX,X
	sta BulletY,X
	dex
	bpl RemoveBulletsFromScreenLoop
	rts

;****************************************************************************

	;come in with amount to increase in A (units and tens) and Temp (100s and 1000s)
IncreaseScoreSubroutine
	clc
	sed
	adc Score+2
	sta Score+2
	lda Score+1
	adc Temp
	sta Score+1
	lda Score
	adc #0
	sta Score
	cld
	rts

;****************************************************************************
    SUBROUTINE
IsTankOnScreen
    ;--X holds tank number to check
    ;--return in accumulator:  0 if offscreen, 1 if onscreen
    lda TankX,X
    cmp #TANKONSCREENLEFT
    bcc .TankOffScreen
    cmp #TANKONSCREENRIGHT+1
    bcs .TankOffScreen
    lda TankY,X
    cmp #TANKONSCREENTOP+2
    bcc .TankOnScreen    
.TankOffScreen
    lda #0
    rts
.TankOnScreen
    lda #1
    rts

;****************************************************************************
	
	
;byte holds
;           CXM0P   CXM1P   CXPPMM	
;           7  6    7  6    7  6
;frame odd  12 1P   3P 32   2P 31
;frame even P1 P3   23 21   13 2P

TankCollisionRotationTables
    .word TankCollisionBitsEven, TankCollisionBitsOdd

TankCollisionBitsOdd
    .byte %01101000 ;M0 to P1, M1 to P1, and P0 to P1   -player tank
    .byte %11000100 ;M0 to P0, M0 to P1, and M0 to M1   -enemy tank 1
    .byte %10011000 ;M0 to P0, M1 to P0, and P0 to P1   -enemy tank 2
    .byte %00110100 ;M1 to P1, M1 to P0, and M0 to M1   -enemy tank 3
TankCollisionBitsEven
    .byte %11000100, %10011000, %00110100, %01101000
	
	;Rotation:		Frame odd		Frame even
	;Framecounter = xxxxxxx1        xxxxxxx0
	;		P0		player			tank 3
	;		P1		tank 2			tank 1
	;		M0		tank 1			player
	;		M1		tank 3			tank 2

	;player to tank collisions:
	
	;Tank 1			M0 to P0		P1 to M0
	;Tank 2			P1 to P0		M1 to M0
	;Tank 3			M1 to P0		P0 to M0
	
P0CollisionTable
	.byte 3, 0
P1CollisionTable
	.byte 1, 2
M0CollisionTable
	.byte 0, 1
M1CollisionTable
	.byte 2, 3	
;****************************************************************************

CollisionsSubroutine


    ;--first and most important collision check: has anything at all touched the base?
    ;-check bullets first (and only)
    
    bit CXBLPF
    bpl NoBulletToBaseCollision
    ;--hit PF, now let's see if it is in the middle on the bottom row
    lda FrameCounter
    and #3
    tax
    lda BulletY,X
    cmp #BLOCKHEIGHT+2
    bcs NoBulletToBaseCollision
    lda BulletX,X
    cmp #76
    bcc NoBulletToBaseCollision
    cmp #85
    bcs NoBulletToBaseCollision
    
    ;--collision!  Game Over, man, Game Over.
    lda GameStatus
    ora #GAMEOVER|GAMEOFF
    sta GameStatus
    ;--reset TankMovementCounter, (re)used to make walls flash
    lda #GAMEOVERSTARTFREQ
    sta TankMovementCounter
    ;--kill sounds just for my own sanity -this may no longer be necessary
;     lda #0
;     sta AUDV0
;     sta AUDV1
    ;--kill music (AUDV0) and sound effects (Channel1Decay variable)
    lda #0
    sta AUDV0
    sta Channel1Decay
    ;and return, so player doesn't get 5 points for shooting his own base lol
	jmp ReturnFromBSSubroutine2
NoBulletToBaseCollision
    
    

	;--can use hardware collisions for tank to tank
	;tentative plan: use movement routine to prevent enemy tanks from colliding
	;                if enemy tank crashes into player tank, then both die
	;Rotation:		Frame odd		Frame even
	;Framecounter = xxxxxxx1        xxxxxxx0
	;		P0		player			tank 3
	;		P1		tank 2			tank 1
	;		M0		tank 1			player
	;		M1		tank 3			tank 2

	;player to tank collisions:
	
	;Tank 1			M0 to P0		P1 to M0
	;Tank 2			P1 to P0		M1 to M0
	;Tank 3			M1 to P0		P0 to M0
	
    lda CXM0P
    and #$C0
    sta Temp+1
    lda CXM1P
    and #$C0
    lsr
    lsr
    ora Temp+1
    sta Temp+1
    lda CXPPMM
    and #$C0
    lsr
    lsr
    lsr
    lsr
    ora Temp+1
    sta Temp+1	
    
    lda FrameCounter
    and #1
    asl
    tax
    lda TankCollisionRotationTables,X
    sta MiscPtr
    lda TankCollisionRotationTables+1,X
    sta MiscPtr+1
	

    ldy #3
TankCollisionLoop
    lda Temp+1    ;get all collision registers
;     beq NoTankCollisionsAtAll
; YesTankCollisions
    and (MiscPtr),Y
    beq NoTankCollision
; YesTankCollision   
    ;--check to see if what we are colliding into is already dead:
    sta Temp
    sty Temp+2
    jmp CheckForExplosionCollisionLoopEntry
CheckForExplosionCollisionLoop
    
    lda Temp
    and (MiscPtr),Y
    beq NoCollisionWithThisTank
    ;--now check if tank is dead
    lda TankStatus,Y
;     and #TANKINPLAY
;     bne TankHitLiveTank
    lsr     ;get TANKINPLAY bit into carry
    bcs TankHitLiveTank
    ;--now see if explosion or powerup
;     and #TANKDOWN>>1        ;shifted over following LSR above
;     beq NoCollisionWithThisTank
;     ;--else we hit a powerup
;     ;--so we change to explosion?
;     lda #0
;     sta TankStatus,Y
NoCollisionWithThisTank    
CheckForExplosionCollisionLoopEntry
    dey
    bpl CheckForExplosionCollisionCheckEnd
    ldy #3
CheckForExplosionCollisionCheckEnd
    cpy Temp+2
    beq DidNotHitAnythingLive
    bne CheckForExplosionCollisionLoop ;branch always
    
TankHitLiveTank
    ;--if Y = 0 then tank run into by player
    sty Temp+3  ;save this we will check below
    ;--restore Y
    ldy Temp+2
    ;--now what?
    ;--remove tank only if fully onscreen
    tya
    tax ;
    ;--check if tank in play (can be on screen but not in play, if dead)
    lda TankStatus,X        
;     and #TANKINPLAY
;     beq TankAlreadyDeadCannotDie
    lsr     ;get TANKINPLAY bit into carry
    bcs TankNotDeadYetKillIt
    ;--tank is not in play, is it an explosion or a powerup?
    and #TANKDOWN>>1    ;shifted due to LSR above
    beq TankAlreadyDeadCannotDie
    ;--else tank is powerup.  what to do exactly?
    ;--if hit by non-player tank, ignore:
    lda Temp+3  ;--this holds zero if player tank is what hit it
    bne NonPlayerTankHitPowerUp

    ;--first respawn tank to get powerup off the screen
    tya
    pha     ;save Y
    jsr TankRespawnRoutine
    pla
    tay
    ;--second actually activate powerup
    lda MazeGenerationPass  ;used for powerups during levels
    and #POWERUPACTIVATEDBITS
    asl
    rol
    rol     ;get top two bits into lower two bits
    tax
    lda MazeGenerationPass
    and #~POWERUPACTIVATEDBITS
    ora NextPowerUpActivation,X
    sta MazeGenerationPass
    ;--third play powerup sound (only if player hit it!)
   ; sta TankX,X
    jmp TankAlreadyDeadCannotDie        ;branch always 


    
TankNotDeadYetKillIt    
    jsr IsTankOnScreen  ;returns 1 in A if onscreen, 0 in A if not
    and #$FF    ;--sets flags
    beq TankNotOnScreenCannotDie
    ;--tank is onscreen
    tya ;--set flags based on which tank
    bne EnemyTankDied   ;only get points if player runs into tank, not if tanks run into each other.
 	;--score for killing enemy tank
 	jsr ScoreForKillingTank
	;--turn off player movement sound
; 	lda #0
; 	sta AUDV0
;     beq PlayerTankDead
EnemyTankDied
    tya
    tax
    jsr PlayerHitTank   ;this routine uses X to index into which tank got hit.
TankAlreadyDeadCannotDie
TankNotOnScreenCannotDie    
NoTankCollision
PlayerTankDead
DidNotHitAnythingLive
NonPlayerTankHitPowerUp
    dey
    bpl TankCollisionLoop  
NoTankCollisionsAtAll


    ;--alternate collision routine for bullet-to-wall using collision registers
    
    bit CXBLPF
    bpl BallHasNotHitBlock
    ;--bullet hit the wall, now identify which bullet.
    lda FrameCounter
    and #3
    tax
    jsr BulletHitBrickSubroutine

BallHasNotHitBlock
	;--now check if bullet has hit an enemy tank
	;--new routine using collision registers instead of loop.  <--actually, reject this because occasionally bullets pass through tanks
	;   works better with redesigned tank graphics but shots occasionally miss still when on the edge of the tank.  not sure if acceptable or not.
	
	lda FrameCounter
	and #1
	tay
	
	bit CXP0FB
	bvs BulletCollisionP0
	bit CXP1FB
	bvs BulletCollisionP1
	bit CXM0FB
	bvs BulletCollisionM0
	bit CXM1FB
	bvs BulletCollisionM1
	bvc NoBulletToTankCollision
	
BulletCollisionP0
    lda P0CollisionTable,Y
    tax ;index into which tank is hit
    bvs FoundDeadTankNowKill    ;branch always following bvs branch above
BulletCollisionP1
    lda P1CollisionTable,Y
    tax
    bvs FoundDeadTankNowKill
BulletCollisionM0
    lda M0CollisionTable,Y
    tax
    bvs FoundDeadTankNowKill
BulletCollisionM1
    lda M1CollisionTable,Y
    tax
FoundDeadTankNowKill
    ;--check if tank is already dead (but still on screen)
    lda TankStatus,X
    and #TANKINPLAY
    beq TankAlreadyDeadCannotBeShot

	;--add KILLTANKSCORE to score if X > 0 (enemy tank) and Y >= 2 (player bullets)
	lda FrameCounter
	and #3
	tay ;get bullet # into Y so it will be removed appropriately below
	cmp #2
	bcs NoPointsForEnemyOwnGoals
	txa ;set flags based on X
	beq NoPointsForGettingShot	
	jsr ScoreForKillingTank
	
; 	lda #>KILLTANKSCORE ;%%%%
; 	sta Temp
; 	lda #<KILLTANKSCORE
; 	jsr IncreaseScoreSubroutine

NoPointsForGettingShot		
NoPointsForEnemyOwnGoals
	jsr BulletHitTank
TankAlreadyDeadCannotBeShot
TankOffScreenCannotBeKilled
NoBulletToTankCollision	


    ;if a tank was killed immediately above, we cleared all bits except for TANKINPLAY
    ;   so that we could correctly tell if tanks if collided with it
    ;   and so now look for those tanks and set the rest of the bits correctly
    ldy #3
SetTankStatusForDeadTanks
    lda TankStatus,Y
    cmp #TANKINPLAY
    bne TankNotNewlyDead
    ;--check to see if it should be a powerup
    ;   only a powerup if:
    ;       player deaths in this level = 0
    ;       powerup countdown is zero
    lda MazeGenerationPass
    and #PLAYERDEATHCOUNTBITS
    bne NoPowerUp
    lda MazeGenerationPass
    and #POWERUPCOUNTDOWNBITS
    bne NoPowerUp
    ;--else it's a powerup!
    lda TankDeadStatus,Y
    ora #TANKDOWN
    sta TankStatus,Y
    lda MazeGenerationPass
    ora #POWERUPCOUNTDOWNBITS
    sta MazeGenerationPass  ;reset counter to the max (7)
    bne CheckNextTankForNewDeath
NoPowerUp
    lda TankDeadStatus,Y
    sta TankStatus,Y
TankNotNewlyDead
CheckNextTankForNewDeath
    dey
    bpl SetTankStatusForDeadTanks       


	;--OLD ROUTINE that uses software collision detection (checks every bullet every frame)
; 	;   X is index into tank (outer loop)
; 	;   Y is index into bullet (inner loop)
; 	ldx #3
; CheckBulletTankCollisionOuterLoop
; 	;first check if tank is offscreen
; 	jsr IsTankOnScreen
; 	and #$FF
; 	bne EnemyTankOnScreen
; 	jmp EnemyTankOffscreen
; EnemyTankOnScreen
; 	;now compare ball location to tank location
; 	ldy #3
; CheckBulletTankCollisionInnerLoop
; 	lda BulletX,Y
; 	cmp #BALLOFFSCREEN
; ; 	bne BulletOnScreen2
; 	beq BulletOffScreen2    
; BulletOnScreen2
; 	;--compare X position
; 	clc
; 	adc #1
; 	cmp TankX,X
; 	bcc BulletDidNotHitTank 
; 	sbc #1
; 	sta Temp
; 	lda TankX,X
; 	clc
; 	adc #8
; 	cmp Temp
; 	bcc BulletDidNotHitTank
; 	;--compare Y position
; 	lda BulletY,Y
; 	sec
; 	sbc #1
; 	cmp TankY,X
; 	bcs BulletDidNotHitTank
; 	adc #1
; 	sta Temp
; 	lda TankY,X
; 	sec
; 	sbc #TANKHEIGHT
; 	cmp Temp
; 	bcs BulletDidNotHitTank
; 
; 	;--add KILLTANKSCORE to score if X > 0 (enemy tank) and Y >= 2 (player bullets)
; 	txa ;set flags based on X
; 	beq NoPointsForGettingShot
; 	cpy #2
; 	bcs NoPointsForEnemyOwnGoals
; 	lda #>KILLTANKSCORE
; 	sta Temp
; 	lda #<KILLTANKSCORE
; 	jsr IncreaseScoreSubroutine
; 
; NoPointsForGettingShot		
; NoPointsForEnemyOwnGoals
; 	jsr BulletHitTank
; 
; BulletDidNotHitTank
; BulletOffScreen2
; 	dey
; 	bmi EnemyTankOffscreen
; 	jmp CheckBulletTankCollisionInnerLoop
; 	
; EnemyTankOffscreen
;     
; 	dex
; 	bmi DoneWithCheckBulletTankCollisionOuterLoop
; 	jmp CheckBulletTankCollisionOuterLoop
; DoneWithCheckBulletTankCollisionOuterLoop
	
	jmp ReturnFromBSSubroutine2

;****************************************************************************


    SUBROUTINE    
ScoreForKillingTank
    txa
    pha ;save X
    lda MazeGenerationPass      ;used for powerups and etc during level
    and #PLAYERDEATHCOUNTBITS
    bne .PlayerDiedNoExtraScore
    ;--else, give number of tanks killed so far (minus 1) x 25
    lda MazeNumber
    asl
    clc
    adc #6
    cmp #20
    bcc .FoundInitialTankCount
    lda #20
.FoundInitialTankCount
    sec
    sbc TanksRemaining
    tax
    sed
    lda #0
    sta Temp
    sta Temp+1
.TankScoreMultiplierLoop
    dex
    bmi .DoneTankScoreMultiplierLoop
    lda Temp+1
    clc
    adc #$25
    sta Temp+1
    lda Temp
    adc #0
    sta Temp
    jmp .TankScoreMultiplierLoop        ;can probably make this a BCC 
.DoneTankScoreMultiplierLoop
    cld                                 ;probably not necessary, the subroutine below just sets it again
    lda Temp+1
    jsr IncreaseScoreSubroutine
.PlayerDiedNoExtraScore
	lda #>KILLTANKSCORE
	sta Temp
	lda #<KILLTANKSCORE
	jsr IncreaseScoreSubroutine
	pla
	tax ;--restore X
    rts        

    
;****************************************************************************
    
    
NextPowerUpActivation
    .byte %01000000, %10000000, %11000000, %11000000    


;****************************************************************************


BulletHitBrickSubroutine
	;--first, add to score ONLY if player bullet
	cpx #2
	bcs NoScoreForWallDestructionByEnemies
	lda #>WALLDESTRUCTIONSCORE
	sta Temp
	lda #<WALLDESTRUCTIONSCORE
	jsr IncreaseScoreSubroutine
NoScoreForWallDestructionByEnemies	
	;--get row of block into Y and column into Temp+1

	lda BulletY,X
	ldy #0
	sec
	sbc #2
GetRowBulletIsInLoop
	sbc #BLOCKHEIGHT
	bcc FoundWhichRowBulletIsIn
	iny
	jmp GetRowBulletIsInLoop
FoundWhichRowBulletIsIn
	;--special check for row = 0
	tya
	bne BulletNotOnBottomRow
	;--all we care is left or right of center
	lda BulletX,X
	cmp #80
	bcc BulletOnLeftLastRow
	lda #0
	sta LastRowR
	beq RemovedWallBlock
BulletOnLeftLastRow
	lda #0
	sta LastRowL
	beq RemovedWallBlock
BulletNotOnBottomRow
    lda BulletDirection
    and BulletDirectionMask,X
    cmp BulletLeftBank2,X
    beq BulletMovingLeft
    lda #-16
    .byte $2C   ;skip two bytes
BulletMovingLeft
    lda #-17
    clc            
    adc BulletX,X
	lsr
	lsr
	lsr
	sta Temp+1
	txa
	pha
		
	lda #<PF1Left
	sta MiscPtr
	lda #>PF1Left
	sta MiscPtr+1
	ldx Temp+1
	lda PFMaskLookupBank2,X
	eor #$FF
	pha
	lda PFRegisterLookupBank2,X
	clc
	adc MiscPtr
	sta MiscPtr
	pla
	dey
	and (MiscPtr),Y
	sta (MiscPtr),Y	
	pla
	tax
RemovedWallBlock
	;--bullet has hit block, remove bullet from screen:
	lda #BALLOFFSCREEN
	sta BulletX,X
	sta BulletY,X
	
	;--play brick explosion sound
	;--only start if longer explosion not happening
	ldy #BRICKSOUND
	jsr StartSoundSubroutineBank2
	
NoSoundForBrickExplosion

    rts
    
;****************************************************************************

; TankRespawnRoutineWrapper
;     tsx
;     lda $03,X
;     tax
;     jsr TankRespawnRoutine
;     jmp ReturnFromBSSubroutine2
    
TankRespawnRoutineWrapperPlayer
    ldx #0    
    jsr TankRespawnRoutine
    jmp ReturnFromBSSubroutine2

TankRespawnRoutineWrapperEnemy
    lda FrameCounter
    and #3
    tax
    jsr TankRespawnRoutine
    jmp ReturnFromBSSubroutine2
    
PlayerStartingStatus
    .byte TANKRIGHT|0, TANKRIGHT|2, TANKRIGHT|4, TANKRIGHT|6
    .byte TANKRIGHT|8, TANKRIGHT|10, TANKRIGHT|12, TANKRIGHT|14

TankRespawnRoutine  ;come in with X holding tank number (0 = player, 1-3 = enemy tanks)
	txa
	bne EnemyTankRespawnRoutine
    ;--increase counter of number of deaths (in MazeGenerationPass) then increase respawn wait
    lda MazeGenerationPass
    and #PLAYERDEATHCOUNTBITS
    cmp #PLAYERDEATHCOUNTMAX
    beq PlayerHasDiedSevenTimes
PlayerHasNotDiedSevenTimes    
    inc MazeGenerationPass
    lda MazeGenerationPass
    and #PLAYERDEATHCOUNTMAX
PlayerHasDiedSevenTimes    
    tay
	lda PlayerStartingStatus,Y
	sta TankStatus,X
    bne UsePlayerRespawnPosition    ;branch always
EnemyTankRespawnRoutine
	lda StartingTankStatus,X  
	sta TankStatus,X

	;--new respawn routine: randomly pick between 2 respawn spots for each tank
	;   formula is tank # times 2 + rand(0, 1)
	lda RandomNumber
	lsr
	txa
	rol
	tay	
	bne FoundRespawnPosition    ;branch always, since enemy tank = 1, 2, or 3.  so Y holds either 2, 3, 4, 5, 6, 7 (but not 0 or 1)

; ; UseRegularRespawnPosition
UsePlayerRespawnPosition
    txa
    tay    
FoundRespawnPosition

	;--if player tank is in top part of screen, use different starting positions
	lda TankY
	cmp #BLOCKHEIGHT*7
	bcc TopRowEnemyTankRespawn
	;--use alternate positions
	;--if player is on left part of screen, use right respawn locations
	lda TankX
	cmp #80
	bcc RightSideEnemyTankRespawn
    ;--else left side
    tya
    clc
    adc #8
    tay
RightSideEnemyTankRespawn
    tya
;     clc   ;not needed since carry clear after addition above and BCC branch that took us directly here
    adc #8
    tay
TopRowEnemyTankRespawn
    lda StartingTankYPosition,Y
	sta TankY,X
	lda StartingTankXPosition,Y
	sta TankX,X

    rts

;****************************************************************************

TankDeadStatus
    .byte TANKUP|TANKDEADWAITPLAYER, TANKUP|TANKDEADWAIT, TANKUP|TANKDEADWAIT, TANKUP|TANKDEADWAIT
    
    SUBROUTINE   
KillAllTanksBonus
    ldx #3
.KillAllTanksLoop
    lda TankStatus,X
    lsr
    bcc .TankAlreadyDeadCannotKillAgain
    jsr PlayerHitTank
    ;--also give score bonus (of 1000?)
    lda #>POWERUPSCOREBONUS
    sta Temp
    lda #<POWERUPSCOREBONUS
    jsr IncreaseScoreSubroutine
.TankAlreadyDeadCannotKillAgain
    dex
    bne .KillAllTanksLoop
    jmp ReturnFromBSSubroutine2    
        
;****************************************************************************

BulletHitTank
	;--bullet did hit tank.
	;	remove bullet and tank from screen
	lda #BALLOFFSCREEN
	sta BulletX,Y
	sta BulletY,Y
PlayerHitTank
	;--save and restore Y in this routine
	tya
	pha

; 	txa
; 	bne EnemyTanksNotMovedOffScreen
; 	jsr TankRespawnRoutine
EnemyTanksNotMovedOffScreen

	ldy #ENEMYTANKSOUND
	jsr StartSoundSubroutineBank2
	
	;--clear "in play" flag, set wait counter, and set direction
;     lda TankDeadStatus,X
    lda #TANKINPLAY ;--clear all bits except tank in play so we don't screw up subsequently-processed collisions
    sta TankStatus,X

    txa
	bne EnemyTankHit
	;--if player hit, remove all powerups
	lda MazeGenerationPass
	and #~POWERUPACTIVATEDBITS
	sta MazeGenerationPass
	
	
	jmp PlayerTankHit
EnemyTankHit
    ;--decrease tanks remaining ONLY if enemy tank hit
	dec TanksRemaining
	bne LevelNotComplete
	;--killed last tank, level is complete:
	;--set levelcomplete flag
	lda GameStatus
	ora #LEVELCOMPLETE|LEVELCOMPLETETIMER
	sta GameStatus
	;--set RandomNumberSaved to zero (this is used for the points-for-bricks routine)
	lda #0
	sta RandomNumberSaved
	;--stop player tank from moving
	lda TankStatus
	and #~TANKSPEED
	sta TankStatus
	;--kill 
; 	lda #0		
; 	sta AUDV1
    txa
    pha
	jsr MoveBulletsOffScreen	;--returns with X=255
	pla
	tax	
	
LevelNotComplete
    ;--first, reduce powerup tank kill countdown
    lda MazeGenerationPass  ;used for powerup stuff during levels
    and #POWERUPCOUNTDOWNBITS
    beq NoUpdateToPowerUpCountdown
    sec
    sbc #8
    sta Temp
    lda MazeGenerationPass
    and #~POWERUPCOUNTDOWNBITS
    ora Temp
    sta MazeGenerationPass
NoUpdateToPowerUpCountdown    
    ;--what I want to do here is IF the # of tanks remaining <= 3, 
    ;   increase all enemy tank speeds by .... 4?  constant value.
    lda TanksRemaining
    cmp #4
    bcs MoreThanFourTanksRemainingStill
    ;--loop through tanks and increase speed?
    ;--use Y variable... or save X and restore?
;     txa
;     pha     ;save X
;     ldx #3
; IncreaseEnemyTankSpeedLoop
;     lda TankStatus,X
;     lsr     ;get TANKINPLAY flag into carry
;     bcc TankNotOnScreenDoNotIncreaseSpeed
;     rol     ;get TANKINPLAY flag back into lower bit
;     and #TANKSPEED
;     clc
;     adc #LEVELENDTANKSPEEDBOOST
;     cmp #TANKSPEED14+1
;     bcc NewEnemyTankSpeedNotTooHigh
;     lda #TANKSPEED14    
; NewEnemyTankSpeedNotTooHigh
;     sta Temp
;     lda TankStatus,X
;     and #TANKDIRECTION|TANKINPLAY  ;clears tank speed AND tank-in-play bits
;     ora Temp
;     sta TankStatus,X
; TankNotOnScreenDoNotIncreaseSpeed
;     dex
;     bne IncreaseEnemyTankSpeedLoop
;     pla
;     tax     ;restore X
PlayerTankHit	
MoreThanFourTanksRemainingStill    
	;--save and restore Y in this routine
	pla
	tay

	rts

;****************************************************************************
    SUBROUTINE
StartSoundSubroutineBank2
	
	lda Channel1Decay
	and #$F0
	bne .DoNotStartSound
	lda ToneBank2,Y
	sta AUDC1
	lda FrequencyBank2,Y
	sta AUDF1
	lda SoundLengthBank2,Y
	sta Channel1Decay
.DoNotStartSound
	rts

	
;****************************************************************************

DrawTitleScreenSubroutine

	;--TODO: interleave the gfx data so this loop can be cleaned up.... maybe.
	ldx MazeGenerationPass
PutTitleGraphicsInPlayfieldLoop
	txa
	and #3
	asl
	tay
	lda PFPointer,Y
	sta MiscPtr
	lda PFPointer+1,Y
	sta MiscPtr+1
	
	txa
	cmp #((TitleGraphicsEnd-TitleGraphics-1)/2)+(TitleGraphicsEnd-TitleGraphics-1)/4)-1
	bcc DrawTitleScreenModerately
	;--else slower
	lda FrameCounter
	and #$18
	bne SkipDrawingTitleScreenThisFrame
DrawTitleScreenModerately	
	cmp #((TitleGraphicsEnd-TitleGraphics-1)/2)-1
	bcc DrawTitleScreenFast
	lda FrameCounter
	and #$8
	bne SkipDrawingTitleScreenThisFrame
DrawTitleScreenFast
	txa
	lsr
	lsr
	tay
	lda TitleGraphics,X
	
	sta (MiscPtr),Y

	
	dex
	stx MazeGenerationPass
	bmi DoneDrawingTitleScreen
	tay	;set flags based on what we wrote
	beq PutTitleGraphicsInPlayfieldLoop	;--this only works if last value is NOT zero
DoneDrawingTitleScreen
	;--play sound
	txa	;reset flags
	bmi PlayLongSound
	ldy #SHORTBRICKSOUND
	bne PlayShortSound      ;branch always
PlayLongSound
	lda #%11111100
	sta LastRowL
	sta LastRowR	
	lda GameStatus
	ora #DRAWBASE
	sta GameStatus
    lda #255;(FanfarePatternEnd-FanfarePattern-1)       ;need to start on last note so we can immediately wrap to first note.
    sta SongIndex
	ldy #LONGEXPLOSIONSOUND
PlayShortSound
	jsr StartSoundSubroutineBank2

SkipDrawingTitleScreenThisFrame	
	
; 	rts
    jmp ReturnFromBSSubroutine2

;****************************************************************************


	
;****************************************************************************

    ;--this is to make sure the "DivideLoop" doesn't cross a page boundary.
    if ((* + 5) & $FF00) != ((* + 9) & $FF00)
        echo "---Aligned PositionASpriteSubroutineBank2 -", $FF - ((* + 4) & $FF), "bytes left at location", *
        ds $FF - ((* + 4) & $FF)
    else
        echo "---Aligned PositionASpriteSubroutineBank2 not necessary"
    endif
    SUBROUTINE
PositionASpriteSubroutineBank2
    sec
	sta HMCLR
	sta WSYNC
.DivideLoop			;				this loop can't cross a page boundary!!!
	sbc #15
	bcs .DivideLoop	;+4		 4
	eor #7
	asl
	asl
	asl
	asl				;+10	14
	sta.wx HMP0,X	;+5		19
	sta RESP0,X		;+4		23
	sta WSYNC
	sta HMOVE
	rts                 ;+9      9
	
;------------------------------------------------------
;---------------------DATA-----------------------------
;------------------------------------------------------


AllowCarveDownTable ;can't carve downward in the outer two columns
    .byte 0, 0, 1, 1
    .byte 1, 1, 1, 1
    .byte 1, 1, 1, 1
    .byte 1, 1, 0, 0		

    
EntryPointRowOffsetTable
    .byte ENEMYSTARTINGYHIGHROW - 2, ENEMYSTARTINGYHIGHMIDROW - 2, ENEMYSTARTINGYMIDHIGHROW - 2
    .byte ENEMYSTARTINGYMIDROW - 2, ENEMYSTARTINGYMIDLOWROW - 2, ENEMYSTARTINGYLOWROW - 2


DigitDataMissileLo
	.byte <MissileZero, <MissileOne, <MissileTwo, <MissileThree
	
	.byte <MissileFour, <MissileFive, <MissileSix, <MissileSeven
	.byte <MissileEight, <MissileNine
		
TanksRemainingPF1Mask
	.byte $FF,$7F,$3F,$1F,$0F,$07,$03,$01,$00,$00,$00

TanksRemainingPF2Mask		
	.byte $3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3E,$3C
		

RotationTables
	.word RotationEven, RotationOdd	

RotationOdd
	.byte 0	;and first 3 bytes of next table
RotationEven
	.byte 2, 1, 3, 0
	
P0M0Color
    .byte TANKCOLOR1, TANKCOLOR3

P1M1Color
    .byte TANKCOLOR2, TANKCOLOR4
	
BulletDirectionMask
	.byte %11, %11<<2, %11<<4, %11<<6

BulletDirectionClearBank2
BulletUpBank2
	.byte	BULLETUP, BULLETUP<<2, BULLETUP<<4, BULLETUP<<6
BulletDownBank2
	.byte	BULLETDOWN, BULLETDOWN<<2, BULLETDOWN<<4, BULLETDOWN<<6
BulletLeftBank2
	.byte	BULLETLEFT, BULLETLEFT<<2, BULLETLEFT<<4, BULLETLEFT<<6
BulletRightBank2
	.byte	BULLETRIGHT, BULLETRIGHT<<2, BULLETRIGHT<<4, BULLETRIGHT<<6
	
	
	
StartingTankXPosition
	.byte PLAYERSTARTINGX, PLAYERSTARTINGX, ENEMY01STARTINGX, ENEMY02STARTINGX, ENEMY11STARTINGX, ENEMY12STARTINGX, ENEMY21STARTINGX, ENEMY22STARTINGX
	.byte PLAYERSTARTINGX, PLAYERSTARTINGX, ENEMY0STARTINGX2, ENEMY0STARTINGX2, ENEMY1STARTINGX2, ENEMY1STARTINGX2, ENEMY2STARTINGX2, ENEMY2STARTINGX2
	.byte PLAYERSTARTINGX, PLAYERSTARTINGX, ENEMY0STARTINGX3, ENEMY0STARTINGX3, ENEMY1STARTINGX3, ENEMY1STARTINGX3, ENEMY2STARTINGX3, ENEMY2STARTINGX3

StartingTankYPosition 
	.byte PLAYERSTARTINGY, PLAYERSTARTINGY, ENEMYSTARTINGYTOP, ENEMYSTARTINGYTOP, ENEMYSTARTINGYTOP, ENEMYSTARTINGYTOP, ENEMYSTARTINGYTOP, ENEMYSTARTINGYTOP 
	.byte PLAYERSTARTINGY, PLAYERSTARTINGY, ENEMYSTARTINGYLOW, ENEMYSTARTINGYMIDHIGH, ENEMYSTARTINGYMIDLOW, ENEMYSTARTINGYHIGHMID, ENEMYSTARTINGYMID, ENEMYSTARTINGYHIGH ;removed "+4" from enemy tank #s 1-3 starting Y 
	.byte PLAYERSTARTINGY, PLAYERSTARTINGY, ENEMYSTARTINGYLOW, ENEMYSTARTINGYMIDHIGH, ENEMYSTARTINGYMIDLOW, ENEMYSTARTINGYHIGHMID, ENEMYSTARTINGYMID, ENEMYSTARTINGYHIGH ;removed "+4" from enemy tank #s 1-3 starting Y 
	
StartingTankStatus
	.byte TANKRIGHT|PLAYERRESPAWNDELAY, ENEMYTANK1DELAY, ENEMYTANK2DELAY, ENEMYTANK3DELAY

	
	
ToneBank2
	.byte BRICKSOUNDTONE, BULLETSOUNDTONE, ENEMYTANKSOUNDTONE, SHORTBRICKSOUNDTONE, LONGEXPLOSIONTONE, ENEMYBULLETSOUNDTONE, WALLSOUNDTONE

FrequencyBank2
	.byte BRICKSOUNDFREQ, BULLETSOUNDFREQ, ENEMYTANKSOUNDFREQ, SHORTBRICKSOUNDFREQ, LONGEXPLOSIONFREQ, ENEMYBULLETSOUNDFREQ, WALLSOUNDFREQ
SoundLengthBank2
	.byte BRICKSOUNDLENGTH, BULLETSOUNDLENGTH, ENEMYTANKSOUNDLENGTH, SHORTBRICKSOUNDLENGTH, LONGEXPLOSIONLENGTH, ENEMYBULLETSOUNDLENGTH, WALLSOUNDLENGTH
	
NumberOfBitsSetBank2
	.byte 0, 1, 1, 2
	.byte 1, 2, 2, 3
	.byte 1, 2, 2, 3
	.byte 2, 3, 3, 4

	
PFPointer
	.word PF1Left, PF2Left, PF2Right, PF1Right


TankUpFrame
	.word TankUpAnimated4+TANKHEIGHT, TankUpAnimated3+TANKHEIGHT, TankUpAnimated2+TANKHEIGHT, TankUpAnimated1+TANKHEIGHT
PlayerTankUpFrame
	.word PlayerTankUp4+TANKHEIGHT, PlayerTankUp3+TANKHEIGHT, PlayerTankUp2+TANKHEIGHT, PlayerTankUp1+TANKHEIGHT

TankDownFrame
	.word TankDownAnimated4+TANKHEIGHT, TankDownAnimated3+TANKHEIGHT, TankDownAnimated2+TANKHEIGHT, TankDownAnimated1+TANKHEIGHT
PlayerTankDownFrame
	.word PlayerTankDown4+TANKHEIGHT, PlayerTankDown3+TANKHEIGHT, PlayerTankDown2+TANKHEIGHT, PlayerTankDown1+TANKHEIGHT
TankRightFrame
	.word TankRightAnimated4+TANKHEIGHT, TankRightAnimated3+TANKHEIGHT, TankRightAnimated2+TANKHEIGHT, TankRightAnimated1+TANKHEIGHT
PlayerTankRightFrame
	.word PlayerTankRight4+TANKHEIGHT, PlayerTankRight3+TANKHEIGHT, PlayerTankRight2+TANKHEIGHT, PlayerTankRight1+TANKHEIGHT
	
DigitDataLo
	.byte <Zero,<One,<Two,<Three,<Four,<Five,<Six,<Seven,<Eight,<Nine
	;.byte <DigitA, <DigitB, <DigitC, <DigitD, <DigitE, <DigitF

	
	
    PAGEALIGN 3
    
DigitDataMissile
MissileOne
	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte LEFTTWO|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte RIGHTONE|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte LEFTONE|(DOUBLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)				
	.byte RIGHTTWO|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
MissileThree
	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte LEFTTHREE|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte RIGHTONE|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte LEFTONE|(DOUBLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte RIGHTTHREE|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
MissileFour
	.byte NOMOVEMENT|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte RIGHTTWO|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte LEFTONE|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte LEFTONE|(DOUBLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte RIGHTTWO|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
MissileFive
	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte LEFTTHREE|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte RIGHTTHREE|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
MissileSeven
	.byte NOMOVEMENT|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte LEFTONE|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte LEFTONE|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte LEFTONE|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte RIGHTTHREE|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
; 	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
MissileSix
	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
;	.byte NOMOVEMENT|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
;	.byte NOMOVEMENT|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
;	.byte NOMOVEMENT|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
MissileNine    
	.byte NOMOVEMENT|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
    .byte RIGHTTHREE|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
;	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
;  	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
;	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
;	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)

MissileEight
	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte LEFTONE|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte RIGHTONE|(DOUBLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
;	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
;	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
;	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)

MissileZero
	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
;	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
;	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
;	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
;	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
MissileTwo
	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte LEFTTHREE|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte RIGHTTHREE|(SINGLEWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)
	.byte NOMOVEMENT|(QUADWIDTHMISSILE>>2)|(THREECOPIESCLOSE>>2)

    ALIGNGFXDATA 1
	
TankGfxVertical
     ;--animation for upward facing tank:   
TankUpAnimated1
		.byte 0
        .byte #%11011011;--
        .byte #%00111100;--
        .byte #%11111111;--
        .byte #%00011000;--
        .byte #%11011011;--
        .byte #%00011000;--
TankUpAnimated1b
		.byte 0
        .byte #%00000011;--
        .byte #%11111100;--
        .byte #%00111111;--
        .byte #%11111100;--
        .byte #%00011011;--
        .byte #%11011000;--
        .byte 0
TankUpAnimated2 = * - 1
; 		.byte 0
		.byte #%11011000;--
		.byte #%00111111;--
		.byte #%11111100;--
		.byte #%00011011;--
		.byte #%11011000;--
		.byte #%00011011;--
TankUpAnimated2b
		.byte 0
        .byte #%11000011;--
        .byte #%00111100;--
        .byte #%11111111;--
        .byte #%00011000;--
        .byte #%11011011;--
        .byte #%00011000;--
		.byte 0
TankUpAnimated3 = * - 1
; 		.byte 0
		.byte #%00011000;--
		.byte #%11111111;--
		.byte #%00111100;--
		.byte #%11011011;--
		.byte #%00011000;--
		.byte #%11011011;--
TankUpAnimated3b
		.byte 0
        .byte #%11000000;--
        .byte #%00111111;--
        .byte #%11111100;--
        .byte #%00011011;--
        .byte #%11011000;--
        .byte #%00011011;--
		.byte 0
TankUpAnimated4 = * - 1
; 		.byte 0
		.byte #%00011011;--
		.byte #%11111100;--
		.byte #%00111111;--
		.byte #%11011000;--
		.byte #%00011011;--
		.byte #%11011000;--
TankUpAnimated4b
		.byte 0
        .byte #%00000000;--
        .byte #%11111111;--
        .byte #%00111100;--
        .byte #%11011011;--
        .byte #%00011000;--
        .byte #%11011011;--
		.byte 0
TankDownAnimated1 = * - 1
;         .byte 0
        .byte #%11011000;--
        .byte #%00011011;--
        .byte #%11011000;--
        .byte #%00111111;--
        .byte #%11111100;--
        .byte #%00000011;--
TankDownAnimated1b
		.byte 0
		.byte #%00011000;--
		.byte #%11011011;--
		.byte #%00011000;--
		.byte #%11111111;--
		.byte #%00111100;--
		.byte #%11011011;--
		.byte 0
TankDownAnimated2 = * - 1
;         .byte 0
        .byte #%00011000;--
        .byte #%11011011;--
        .byte #%00011000;--
        .byte #%11111111;--
        .byte #%00111100;--
        .byte #%11000011;--
TankDownAnimated2b
		.byte 0
		.byte #%00011011;--
		.byte #%11011000;--
		.byte #%00011011;--
		.byte #%11111100;--
		.byte #%00111111;--
		.byte #%11011000;--
		.byte 0
TankDownAnimated3 = * - 1
;         .byte 0
        .byte #%00011011;--
        .byte #%11011000;--
        .byte #%00011011;--
        .byte #%11111100;--
        .byte #%00111111;--
        .byte #%11000000;--
TankDownAnimated3b
		.byte 0
		.byte #%11011011;--
		.byte #%00011000;--
		.byte #%11011011;--
		.byte #%00111100;--
		.byte #%11111111;--
		.byte #%00011000;--
		.byte 0
TankDownAnimated4 = * - 1
;         .byte 0
        .byte #%11011011;--
        .byte #%00011000;--
        .byte #%11011011;--
        .byte #%00111100;--
        .byte #%11111111;--
        .byte #%00000000;--       	
TankDownAnimated4b
		.byte 0
		.byte #%11011000;--
		.byte #%00011011;--
		.byte #%11011000;--
		.byte #%00111111;--
		.byte #%11111100;--
		.byte #%00011011;--
		.byte 0
PlayerTankUp1   = * - 1
        .byte #%11011011;--2
        .byte #%10111101;--4
        .byte #%10111101;--6
        .byte #%11011011;--8
        .byte #%11011011;--0
        .byte #%11011011;--2

PlayerTankUp1b
        .byte 0
        .byte #%11000000;--1
        .byte #%00111101;--3
        .byte #%10111100;--5
        .byte #%00011011;--7
        .byte #%11011000;--9
        .byte #%00011011;--1
        .byte 0        
PlayerTankUp2   = * - 1
        .byte #%00011011;--2
        .byte #%10111100;--4
        .byte #%00111101;--6
        .byte #%11011000;--8
        .byte #%00011011;--0
        .byte #%11011000;--2
PlayerTankUp2b
        .byte 0
        .byte #%11000011;--1
        .byte #%10111101;--3
        .byte #%10111101;--5
        .byte #%11011011;--7
        .byte #%11011011;--9
        .byte #%11011011;--1
        .byte 0
PlayerTankUp3   = * - 1
        .byte #%11011011;--2
        .byte #%10111101;--4
        .byte #%10111101;--6
        .byte #%11011011;--8
        .byte #%11011011;--0
        .byte #%11011011;--2
PlayerTankUp3b
        .byte 0
        .byte #%00000011;--1
        .byte #%10111100;--3
        .byte #%00111101;--5
        .byte #%11011000;--7
        .byte #%00011011;--9
        .byte #%11011000;--1
        .byte 0
PlayerTankUp4   = * - 1
        .byte #%11011000;--2
        .byte #%00111101;--4
        .byte #%10111100;--6
        .byte #%00011011;--8
        .byte #%11011000;--0
        .byte #%00011011;--2
PlayerTankUp4b
        .byte 0
        .byte #%11000011;--1
        .byte #%10111101;--3
        .byte #%10111101;--5
        .byte #%11011011;--7
        .byte #%11011011;--9
        .byte #%11011011;--1
        .byte 0			
		
		PAGEALIGN 4
	
DigitData
Zero
        .byte #%01101100;--
        .byte #%11000110;--
        .byte #%11000110;--
        .byte #%11000110;--
        .byte #%11000110;--
        .byte #%11000110;--
        .byte #%01101100;--
One
        .byte #%00011000;--
        .byte #%00011000;--
        .byte #%00011000;--
        .byte #%00011000;--
        .byte #%00011000;--
        .byte #%00111000;--
        .byte #%00011000;--
Two
        .byte #%11111110;--
        .byte #%11000000;--
        .byte #%01111000;--
        .byte #%00011110;--
        .byte #%00000110;--
        .byte #%11000110;--
        .byte #%01111100;--
Three
        .byte #%01111100;--
        .byte #%11000110;--
        .byte #%00000110;--
        .byte #%00001100;--
        .byte #%00000110;--
        .byte #%11000110;--
        .byte #%01111100;--
Four
        .byte #%00001100;--
        .byte #%00001100;--
        .byte #%11101110;--
        .byte #%11001100;--
        .byte #%01101100;--
        .byte #%00101100;--
        .byte #%00001100;--
Five
        .byte #%01111100;--
        .byte #%11000110;--
        .byte #%00000110;--
        .byte #%00000110;--
        .byte #%11111100;--
        .byte #%11000000;--
        .byte #%11111110;--
Six
        .byte #%01101100;--
        .byte #%11000110;--
        .byte #%11000110;--
        .byte #%11101100;--
        .byte #%11000000;--
        .byte #%11000000;--
        .byte #%01101100;--
Seven
        .byte #%00110000;--
        .byte #%00110000;--
        .byte #%00011000;--
        .byte #%00001100;--
        .byte #%00000110;--
        .byte #%00000110;--
        .byte #%11111110;--
Eight
        .byte #%01101100;--
        .byte #%11000110;--
        .byte #%11000110;--
        .byte #%01101100;--
        .byte #%11000110;--
        .byte #%11000110;--
        .byte #%01101100;--
Nine
        .byte #%01101100;--
        .byte #%00000110;--
        .byte #%00000110;--
        .byte #%01101110;--
        .byte #%11000110;--
        .byte #%11000110;--
        .byte #%01101100;--

	

    ALIGNGFXDATA 2
		
TankGfxHorizontal
TankRightAnimated1
        .byte 0
        .byte #%01100110;--
        .byte #%00110000;--
        .byte #%01111111;--
        .byte #%01111000;--
        .byte #%11001100;--
        .byte #%11001100;--
TankRightAnimated1b
		.byte 0
		.byte #%01100110;--
		.byte #%01100110;--
		.byte #%01111000;--
		.byte #%01111111;--
		.byte #%00110000;--
		.byte #%11001100;--
		.byte 0
TankRightAnimated2 = * - 1
;         .byte 0
        .byte #%11001100;--
        .byte #%00110000;--
        .byte #%01111111;--
        .byte #%01111000;--
        .byte #%10011001;--
        .byte #%10011001;--
TankRightAnimated2b
		.byte 0
		.byte #%11001100;--
		.byte #%11001100;--
		.byte #%01111000;--
		.byte #%01111111;--
		.byte #%00110000;--
		.byte #%10011001;--
		.byte 0
TankRightAnimated3 = * - 1
;         .byte 0
        .byte #%10011001;--
        .byte #%00110000;--
        .byte #%01111111;--
        .byte #%01111000;--
        .byte #%00110011;--
        .byte #%00110011;--
TankRightAnimated3b
		.byte 0
		.byte #%10011001;--
		.byte #%10011001;--
		.byte #%01111000;--
		.byte #%01111111;--
		.byte #%00110000;--
		.byte #%00110011;--
		.byte 0
TankRightAnimated4 = * - 1
;        	.byte 0
        .byte #%00110011;--
        .byte #%00110000;--
        .byte #%01111111;--
        .byte #%01111000;--
        .byte #%01100110;--
        .byte #%01100110;--
TankRightAnimated4b
		.byte 0
		.byte #%00110011;--
		.byte #%00110011;--
		.byte #%01111000;--
		.byte #%01111111;--
		.byte #%00110000;--
		.byte #%01100110;--
		.byte 0

PlayerTankRight1 = * - 1
;         .byte 0
        .byte #%11011101;--       
        .byte #%00110000;--        
        .byte #%01111111;--
        .byte #%01111000;--
        .byte #%00000011;--        
        .byte #%01110111;--        
PlayerTankRight1b
        .byte 0
        .byte #%11011101;--
        .byte #%10000101;--
        .byte #%01111000;--
        .byte #%01111111;--
        .byte #%00110000;--
        .byte #%01110111;--
        .byte 0
PlayerTankRight2    = *-1
;         .byte 0
        .byte #%10111011;--
        .byte #%00110000;--
        .byte #%01111111;--
        .byte #%01111000;--
        .byte #%10000110;--
        .byte #%11101110;--
PlayerTankRight2b
        .byte 0
        .byte #%10111011;--      
        .byte #%10000011;--
        .byte #%01111000;--
        .byte #%01111111;--        
        .byte #%00110000;--        
        .byte #%11101110;--
        .byte 0
PlayerTankRight3    = *-1
      ;  .byte 0
        .byte #%01110111;--2
        .byte #%00110000;--4
        .byte #%01111111;--6
        .byte #%01111000;--8
        .byte #%10000101;--10
        .byte #%11011101;--12
PlayerTankRight3b
        .byte 0
        .byte #%01110111;--1
        .byte #%00000111;--3
        .byte #%01111000;--5
        .byte #%01111111;--7
        .byte #%00110000;--9
        .byte #%11011101;--11
        .byte 0        
PlayerTankRight4    = *-1
        .byte #%11101110;--2
        .byte #%00110000;--4
        .byte #%01111111;--6
        .byte #%01111000;--8
        .byte #%10000011;--0
        .byte #%10111011;--2

PlayerTankRight4b
        .byte 0
        .byte #%11101110;--1
        .byte #%10000110;--3
        .byte #%01111000;--5
        .byte #%01111111;--7
        .byte #%00110000;--9
        .byte #%10111011;--1
        .byte 0        
		
PlayerTankDown1 = * - 1       ;uses .byte 0 from previous table and the 0 in the following byte
        .byte #%00011011;--2
        .byte #%11011000;--4
        .byte #%00011011;--6
        .byte #%10111100;--8
        .byte #%00111101;--0
        .byte #%11000000;--2
PlayerTankDown1b
        .byte 0
        .byte #%11011011;--1
        .byte #%11011011;--3
        .byte #%11011011;--5
        .byte #%10111101;--7
        .byte #%10111101;-9
        .byte #%11011011;--1
        .byte 0        
PlayerTankDown2 =   * - 1
        .byte #%11011011;--2
        .byte #%11011011;--4
        .byte #%11011011;--6
        .byte #%10111101;--8
        .byte #%10111101;--0
        .byte #%11000011;--2
PlayerTankDown2b
        .byte 0
        .byte #%11011000;--1
        .byte #%00011011;--3
        .byte #%11011000;--5
        .byte #%00111101;--7
        .byte #%10111100;--9
        .byte #%00011011;--1
        .byte 0        
		
TankKilledImage = * - 1
        .byte #%01010100;--2
        .byte #%00111011;--4
        .byte #%01000100;--6
        .byte #%01100101;--8
        .byte #%01011100;--10
        .byte #%10010001;--12
        
TankKilledImageb     
        .byte 0   
        .byte #%10010010;--1
        .byte #%01001000;--3
        .byte #%10100100;--5
        .byte #%00000010;--7
        .byte #%00100100;--9
        .byte #%01001010;--11
        .byte 0
        
PowerUpImage1 = * - 1
        .byte #%00111100;--2
        .byte #%00111100;--4
        .byte #%01011010;--6
        .byte #%11111111;--8
        .byte #%10000001;--10
        .byte #%00000000;--12
PowerUpImage1b
        .byte 0
        .byte #%00111100;--1
        .byte #%00111100;--3
        .byte #%01111110;--5
        .byte #%11111111;--7
        .byte #%10000001;--9
        .byte #%11000011;--11
        .byte 0
        
        
        
        
        
TanksRemainingGfx
;	.byte 0
	.byte %11101110
	.byte %11101110
	.byte %11101110
	.byte %01000100		
	.byte 0
	.byte %11101110
	.byte %11101110
	.byte %11101110
	.byte %01000100		
	
	
	PAGEALIGN 5
	
	;%%% put crap here
TitleGraphics
    ;-----PF1--------PF2--------PF2--------PF1------
    .byte %00001000, %11111100, %11111100, %00001000
    .byte %00001000, %10001100, %10001100, %00001000
    .byte %00001111, %11101111, %11101111, %00001111
    .byte %00000111, %11111111, %11111111, %00000111
    .byte %00000000, %00000000, %00000000, %00000000
    .byte %10101010, %01110101, %01001010, %01010111
    .byte %10101010, %01010101, %01001110, %00110101
    .byte %10101010, %01010101, %01001010, %01010101
    .byte %11111010, %01110111, %11101110, %01110101
    .byte %11011010, %01110111, %11101110, %01110101
TitleGraphicsEnd				
	

PFRegisterLookupBank2
	.byte 0, 0, 0, 0
	.byte MAZEROWS-1, MAZEROWS-1, MAZEROWS-1, MAZEROWS-1
	.byte (MAZEROWS-1)*2, (MAZEROWS-1)*2, (MAZEROWS-1)*2, (MAZEROWS-1)*2
	.byte (MAZEROWS-1)*3, (MAZEROWS-1)*3, (MAZEROWS-1)*3, (MAZEROWS-1)*3

	
	
PFMaskLookupBank2
	.byte $C0, $30, $0C, $03
	.byte $03, $0C, $30, $C0
	.byte $C0, $30, $0C, $03
	.byte $03, $0C, $30, $C0



    ALIGNGFXDATA 3
       
        
        
PlayerTankDown3 ;= * - 1
        .byte 0
        .byte #%11011000;--2
        .byte #%00011011;--4
        .byte #%11011000;--6
        .byte #%00111101;--8
        .byte #%10111100;--0
        .byte #%00000011;--2
PlayerTankDown3b
        .byte 0
        .byte #%11011011;--1
        .byte #%11011011;--3
        .byte #%11011011;--5
        .byte #%10111101;--7
        .byte #%10111101;--9
        .byte #%11011011;--1
        .byte 0
PlayerTankDown4 = * - 1
        .byte #%11011011;--2
        .byte #%11011011;--4
        .byte #%11011011;--6
        .byte #%10111101;--8
        .byte #%10111101;--0
        .byte #%11000011;--2
PlayerTankDown4b
        .byte 0
        .byte #%00011011;--1
        .byte #%11011000;--3
        .byte #%00011011;--5
        .byte #%10111100;--7
        .byte #%00111101;--9
        .byte #%11011000;--1
        .byte 0

PowerUpImage2
        .byte #%00000000;--
        .byte #%00000110;--
        .byte #%00011110;--
        .byte #%00111110;--
        .byte #%01111110;--
        .byte #%01111100;--
        .byte #%01110100;--
        .byte #%01111100;--
        .byte #%01111000;--
        .byte #%01100000;--
        .byte #%00110000;--
        .byte #%00011100;--
PowerUpImage3
        .byte #%00000000;--
        .byte #%00111100;--
        .byte #%00111100;--
        .byte #%00111100;--
        .byte #%00111100;--
        .byte #%01111110;--
        .byte #%01111110;--
        .byte #%01111110;--
        .byte #%11111111;--
        .byte #%10000001;--
        .byte #%10000001;--
        .byte #%11000011;--
PowerUpImage4
        .byte #%00000000;--
        .byte #%01100000;--
        .byte #%01111000;--
        .byte #%01111100;--
        .byte #%01111110;--
        .byte #%00111110;--
        .byte #%00101110;--
        .byte #%00111110;--
        .byte #%00011110;--
        .byte #%00000110;--
        .byte #%00001100;--
        .byte #%00111000;--
        
        
        
    ;--have a lot of space left here. (currently $72 bytes)
	
        
    PAGEALIGN 6




	
	ds BLOCKHEIGHT+1 - (* & $FF)
BlockRowTable
DigitBlank
	ds BLOCKHEIGHT, 0
	ds BLOCKHEIGHT, 1
	ds BLOCKHEIGHT, 2
	ds BLOCKHEIGHT, 3
	ds BLOCKHEIGHT, 4
	ds BLOCKHEIGHT, 5
	ds BLOCKHEIGHT, 6
	ds BLOCKHEIGHT, 7
	ds BLOCKHEIGHT, 8
	ds BLOCKHEIGHT, 9
	ds BLOCKHEIGHT, 10
	ds BLOCKHEIGHT, 11
	ds BLOCKHEIGHT, 12
	ds BLOCKHEIGHT, 13
	ds BLOCKHEIGHT, 14
	ds BLOCKHEIGHT, 15
	ds BLOCKHEIGHT, 16
	ds BLOCKHEIGHT, 17
	



	
	

	
	

;****************************************************************************	

    echo "----", ($3FD5-*), " bytes left (ROM) at end of Bank 2"

   	org $2FD1
	rorg $3FD1
	
BankSwitchSubroutine2 
	plp             ;+4
	tsx             ;+2
	dec $01,X       ;+6
	lda ($01,X)     ;+6
	sta MiscPtr     ;+3
	inc $01,X       ;+6
	lda ($01,X)     ;+6
	sta MiscPtr+1   ;+3
	lsr             
	lsr
	lsr
	lsr
	lsr             ;+10
	tax             ;+2
	nop $1FF8,X     ;+4
;     nop $1FF8

	jmp (MiscPtr)   ;+5     57
	
ReturnFromBSSubroutine2
	tsx             ;+2
	lda $02,X       ;+4     get high byte of return address
	lsr
	lsr
	lsr
	lsr
	lsr             ;+10
	tax             ;+2
	nop $1FF8,X     ;+4
;     nop $1FF8

	rts             ;+6     28

	;--reserve space for hot spots
    org $2FF8
    rorg $3FF8
    
    ds 2
	
	
;****************************************************************************	


	org $2FFC
	rorg $3FFC
	.word (Start2 & $1FFF)|$1000
	.word BankSwitchSubroutine2
