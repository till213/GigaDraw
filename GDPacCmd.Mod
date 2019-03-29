MODULE PacCmd;
(* Systemsoftware WS 98/99, Oliver Knoll, Raphael Huber *)

(* implementiert die Kommandos fuer den PacMan *)

IMPORT Display, Viewers, Input, Files, OliObjects, FortiFrames, GigaDraw, PacMan, Random;

CONST
	UP = 13X;
	DOWN = 14X;
	RIGHT = 12X;
	LEFT = 11X;
	ESC = 1BX;

	SPEED = 2;	(* PacMans Geschwindigkeit *)
	
	(* PacAttack Parameters: *)
	N = 31;	(* # PacMen bei Attacke *)
	AREA= 128;	(* in diesem Gebiet werden die PacMen ausgesetzt *)
	RANGE = 8;	(* Max. Distanz, die ein PacMan laufen kann, bevor er den naechsten Entscheid trifft *)

TYPE
	Decision = RECORD
		dir: CHAR;	(* Richtung, in die PacMan kriecht *)
		cnt: INTEGER	(* solange cnt > 0, kriecht PacMan in selbe Richtung *)
	END;

VAR	(* global *)
	id: INTEGER;	(* der zu steuernde PacMan *)

PROCEDURE Start*();
VAR
	ch: CHAR;
	fpmMsg: FortiFrames.FPacMoveMsg;
	run: BOOLEAN;
	key: CHAR;
BEGIN
	run := TRUE;
	WHILE run DO

		Input.Read(ch);
		
		key := ch;
		IF key = UP THEN
			fpmMsg.dx:= 0;
			fpmMsg.dy:= SPEED;
			fpmMsg.id:= id;
			Viewers.Broadcast(fpmMsg)
		ELSIF key = DOWN THEN
			fpmMsg.dx:= 0;
			fpmMsg.dy:= -SPEED;
			fpmMsg.id:= id;
			Viewers.Broadcast(fpmMsg)
		ELSIF key = RIGHT THEN
			fpmMsg.dx:= SPEED;
			fpmMsg.dy:= 0;
			fpmMsg.id:= id;
			Viewers.Broadcast(fpmMsg)
		ELSIF key = LEFT THEN
			fpmMsg.dx:= -SPEED;
			fpmMsg.dy:= 0;
			fpmMsg.id:= id;
			Viewers.Broadcast(fpmMsg)
		ELSIF key = ESC THEN
			run := FALSE
		END

	END

END Start;

PROCEDURE PacAttack*();
VAR
	pacmen: ARRAY N OF OliObjects.Object;
	decision: ARRAY N OF Decision;
	j: INTEGER;
	i, id: INTEGER;
	rnd: INTEGER;
	fpmMsg: FortiFrames.FPacMoveMsg;
	ch: CHAR;
	choice: REAL;
	run: BOOLEAN;
	dx, dy: INTEGER;
BEGIN
	IF FortiFrames.mark0.set THEN
		
		rnd := 1;	(* seed *)
		FOR i:= 0 TO N - 1 DO
			pacmen[i]:= PacMan.NewPacMan();
			pacmen[i].col := FLOOR(Random.rndn(rnd) * 14.0 + 2.0);
			pacmen[i].x:= FLOOR(Random.rndn(rnd) *  2.0 * FLT(AREA)) - AREA + FortiFrames.mark0.x;
			pacmen[i].y:= FLOOR(Random.rndn(rnd) * 2.0 * FLT(AREA)) - AREA + FortiFrames.mark0.y;
			pacmen[i].w:= PacMan.PacManWidth;
			pacmen[i].h:= PacMan.PacManHeight;
			pacmen[i](PacMan.PacMan).id:= i;
			FortiFrames.InsertObject(FortiFrames.markedG, pacmen[i]);

			decision[i].cnt := 0;
		END;
		run := TRUE;
		WHILE run DO
			IF Input.Available() > 0 THEN
				Input.Read(ch);
				IF ch = ESC THEN
					run := FALSE
				END	
			END;
			
			FOR i:= 0 TO N - 1 DO
				fpmMsg.id := i;
				
				IF decision[i].cnt > 0 THEN
			
			
					IF decision[i].dir = UP THEN
						fpmMsg.dx := 0;
						fpmMsg.dy := SPEED;
					ELSIF decision[i].dir = DOWN THEN
						fpmMsg.dx := 0;
						fpmMsg.dy := -SPEED;
					ELSIF decision[i].dir = RIGHT THEN
						fpmMsg.dx := SPEED;
						fpmMsg.dy := 0;
					ELSIF decision[i].dir = LEFT THEN
						fpmMsg.dx := -SPEED;
						fpmMsg.dy := 0;
					END;
					DEC(decision[i].cnt);
					Viewers.Broadcast(fpmMsg);
					

				ELSE	(* decision[i].cnt = 0 *)

					(*decision[i].cnt:= SHORT(SHORT(ENTIER(Random.rndn(rnd) * RANGE)));*)	(* Bestimme neuen Counter *)
					decision[i].cnt:= FLOOR(Random.rndn(rnd) * FLT(RANGE));
					choice := Random.rndn(rnd) * 4.0;
					IF choice <= 1.0 THEN
						decision[i].dir := RIGHT;
						fpmMsg.dx := SPEED;
						fpmMsg.dy := 0
					ELSIF choice <= 2.0 THEN
						decision[i].dir := LEFT;
						fpmMsg.dx := -SPEED;
						fpmMsg.dy := 0
					ELSIF choice <= 3.0 THEN
						decision[i].dir := UP;
						fpmMsg.dx := 0;
						fpmMsg.dy := SPEED
					ELSE
						decision[i].dir := DOWN;
						fpmMsg.dx := 0;
						fpmMsg.dy := -SPEED
					END;
					DEC(decision[i].cnt);
					Viewers.Broadcast(fpmMsg)
					
				END
			END
		END
	END
END PacAttack;

BEGIN
	id := 0
END PacCmd.


PacCmd.Start
System.Free PacCmd~
System.Directory *.Res