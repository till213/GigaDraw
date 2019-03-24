MODULE PacCmd;
(* Systemsoftware WS 98/99, Oliver Knoll, Raphael Huber *)

(* implementiert die Kommandos fuer den PacMan *)

IMPORT OliObjects, FortiFrames, Viewers, Display, Input, Files, PacMan, Random;

CONST
	UP = 193;
	DOWN = 194;
	RIGHT = 195;
	LEFT = 196;
	ESC = 27;

	SPEED = 2;	(* PacMans Geschwindigkeit *)
	
	(* PacAttack Parameters: *)
	N = 31;	(* # PacMen bei Attacke *)
	AREA= 128;	(* in diesem Gebiet werden die PacMen ausgesetzt *)
	RANGE = 8;	(* Max. Distanz, die ein PacMan laufen kann, bevor er den naechsten Entscheid trifft *)

TYPE
	Decision = RECORD
		dir: INTEGER;	(* Richtung, in die PacMan kriecht *)
		cnt: SHORTINT	(* solange cnt > 0, kriecht PacMan in selbe Richtung *)
	END;

VAR	(* global *)
	id: SHORTINT;	(* der zu steuernde PacMan *)

PROCEDURE Start*();
VAR
	ch: CHAR;
	fpmMsg: FortiFrames.FPacMoveMsg;

BEGIN
	WHILE TRUE DO
		Input.Read(ch);
		CASE ORD(ch) OF
			UP:		fpmMsg.dx:= 0;
						fpmMsg.dy:= SPEED;
						fpmMsg.id:= id;
						Viewers.Broadcast(fpmMsg)
		| DOWN:	fpmMsg.dx:= 0;
						fpmMsg.dy:= -SPEED;
						fpmMsg.id:= id;
						Viewers.Broadcast(fpmMsg)
		| RIGHT:	fpmMsg.dx:= SPEED;
						fpmMsg.dy:= 0;
						fpmMsg.id:= id;
						Viewers.Broadcast(fpmMsg)
		| LEFT:		fpmMsg.dx:= -SPEED;
						fpmMsg.dy:= 0;
						fpmMsg.id:= id;
						Viewers.Broadcast(fpmMsg)
		| ESC:		RETURN
		ELSE
				(* tue nichts *)
		END
	END
END Start;

PROCEDURE PacAttack*();
VAR
	pacmen: ARRAY N OF OliObjects.Object;
	decision: ARRAY N OF Decision;
	j: INTEGER;
	i, id: SHORTINT;
	rnd: INTEGER;
	fpmMsg: FortiFrames.FPacMoveMsg;
	ch: CHAR;
	choice: REAL;
	
BEGIN
	IF ~(FortiFrames.mark0.set) THEN
		(* eventuell noch eine Fehlermeldung ausgeben *)
		RETURN
	END;
	rnd:= 1;	(* seed *)
	FOR i:= 0 TO N-1 DO
		pacmen[i]:= PacMan.NewPacMan();
		FOR j:= 0 TO PacMan.pdata.n-1 DO
			pacmen[i](PacMan.PacMan).pat[j]:= Display.NewPattern(PacMan.pdata.anim[j], PacMan.PACWIDTH, PacMan.PACHEIGHT);
		END;
		pacmen[i].col:= SHORT(SHORT(ENTIER(Random.rndn(rnd) * 14 + 2)));
		pacmen[i].selected:= FALSE;
		pacmen[i].x:= SHORT(ENTIER(Random.rndn(rnd) *  2*AREA)) - AREA + FortiFrames.mark0.x;
		pacmen[i].y:= SHORT(ENTIER(Random.rndn(rnd) * 2*AREA)) - AREA + FortiFrames.mark0.y;
		pacmen[i].w:= PacMan.PACWIDTH;
		pacmen[i].h:= PacMan.PACHEIGHT;
		pacmen[i](PacMan.PacMan).cur:= 0;
		pacmen[i](PacMan.PacMan).id:= i;
		pacmen[i](PacMan.PacMan).n:= PacMan.pdata.n;
		FortiFrames.InsertObject(FortiFrames.markedG, pacmen[i])
	END;
	WHILE TRUE DO
		IF Input.Available() > 0 THEN
			Input.Read(ch);
			IF ORD(ch) = ESC THEN
				RETURN
			END	
		END;
		FOR i:= 0 TO N-1 DO
			fpmMsg.id:= i;
			IF decision[i].cnt > 0 THEN
				CASE decision[i].dir OF
				UP:			fpmMsg.dx:= 0;
								fpmMsg.dy:= SPEED;
				| DOWN:	fpmMsg.dx:= 0;
								fpmMsg.dy:= -SPEED;
				| RIGHT:	fpmMsg.dx:= SPEED;
								fpmMsg.dy:= 0;
				| LEFT:		fpmMsg.dx:= -SPEED;
								fpmMsg.dy:= 0;
				END;
				DEC(decision[i].cnt);
				Viewers.Broadcast(fpmMsg);
			ELSE	(* decision[i].cnt = 0 *)
			decision[i].cnt:= SHORT(SHORT(ENTIER(Random.rndn(rnd) * RANGE)));	(* Bestimme neuen Counter *)
				choice:= Random.rndn(rnd) * 4;
				IF choice <= 1.0 THEN
					decision[i].dir:= RIGHT;
					fpmMsg.dx:= SPEED;
					fpmMsg.dy:= 0
				ELSIF choice <= 2.0 THEN
					decision[i].dir:= LEFT;
					fpmMsg.dx:= -SPEED;
					fpmMsg.dy:= 0
				ELSIF choice <= 3.0 THEN
					decision[i].dir:= UP;
					fpmMsg.dx:= 0;
					fpmMsg.dy:= SPEED
				ELSE
					decision[i].dir:= DOWN;
					fpmMsg.dx:= 0;
					fpmMsg.dy:= -SPEED
				END;
				DEC(decision[i].cnt);
				Viewers.Broadcast(fpmMsg)
			END
		END
	END
END PacAttack;

PROCEDURE WritePacFile*();
VAR
	F: Files.File;
	R: Files.Rider;
	n: SHORTINT;	(* # Animationsframes *)
	w: SHORTINT;
	h: SHORTINT;
	dummy1: LONGINT;
	dummy2: LONGINT;
	data1: LONGINT;
	data2: LONGINT;
	data3: LONGINT;
	data4: LONGINT;
	data5: LONGINT;
	data6: LONGINT;
	data7: LONGINT;
	data8: LONGINT;
	data9: LONGINT;
	data10: LONGINT;
	data11: LONGINT;
	data12: LONGINT;
	data13: LONGINT;
	data14: LONGINT;
	data15: LONGINT;
	data16: LONGINT;

BEGIN
	n:= 2;
	w:= 16;
	h:= 16;
	dummy1:= -1;
	dummy2:= 0;
	data1:= 0C003H;
	data2:= 0F00FH;	
	data3:= 0F81FH;
	data4:= 0FC3FH;
	data5:= 09E7FH;
	data6:= 09E7FH;
	data7:= 0FFFFH;
	data8:= 0FFFFH;
	data9:= 0FFFFH;
	data10:= 0FFFFH;
	data11:= 0FE7FH;
	data12:= 0FE7FH;
	data13:= 0FC3FH;
	data14:= 0F81FH;
	data15:= 0F00FH;
	data16:= 0C003H;

	F:= Files.New("pacman.res");
	Files.Set(R, F, 0);
	Files.Write(R, n);
	Files.Write(R, w);
	Files.Write(R, h);

	Files.WriteLInt(R, dummy1);
	Files.WriteLInt(R, data1);
	Files.WriteLInt(R, data2);
	Files.WriteLInt(R, data3);
	Files.WriteLInt(R, data4);
	Files.WriteLInt(R, data5);
	Files.WriteLInt(R, data6);
	Files.WriteLInt(R, data7);
	Files.WriteLInt(R, data8);
	Files.WriteLInt(R, data9);
	Files.WriteLInt(R, data10);
	Files.WriteLInt(R, data11);
	Files.WriteLInt(R, data12);
	Files.WriteLInt(R, data13);
	Files.WriteLInt(R, data14);
	Files.WriteLInt(R, data15);
	Files.WriteLInt(R, data16);
	

	Files.WriteLInt(R, dummy2);
	Files.WriteLInt(R, dummy1);
	Files.WriteLInt(R, dummy2);
	Files.WriteLInt(R, dummy1);
	Files.WriteLInt(R, dummy2);
	Files.WriteLInt(R, dummy1);
	Files.WriteLInt(R, dummy2);
	Files.WriteLInt(R, dummy1);
	Files.WriteLInt(R, dummy2);
	Files.WriteLInt(R, dummy1);
	Files.WriteLInt(R, dummy2);
	Files.WriteLInt(R, dummy1);
	Files.WriteLInt(R, dummy2);
	Files.WriteLInt(R, dummy1);
	Files.WriteLInt(R, dummy2);
	Files.WriteLInt(R, dummy1);
	Files.WriteLInt(R, dummy2);
	Files.WriteLInt(R, dummy1);
	Files.WriteLInt(R, dummy2);
	Files.WriteLInt(R, dummy1);

	Files.Register(F);
	Files.Close(F);
END WritePacFile;

BEGIN
	id:= 0;
END PacCmd.

PacCmd.WritePacFile
PacCmd.Start
System.Free PacCmd~
System.Directory *.res
