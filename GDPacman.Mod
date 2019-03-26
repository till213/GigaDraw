MODULE PacMan;
(* Systemsoftware WS 98/99, Oliver Knoll, Raphael Huber *)

(* implementiert PacMan - die PacMan-koordinaten sind "Weltkoordinaten", bei einer DrawMsg rechnet der PacMan *)
(* diese Koordinaten selbstaendig in Screenkoordinaten um *)


IMPORT Display, Viewers, Files, Oberon, SYSTEM, OliObjects, FortiFrames;

CONST
	tol = 2;	(* Toleranz: 2 Pixel darf man danebenklicken *)
	N = 8;	(* Max. 8 Animationsframes fuer PacMan -> Oberon-2: ev. dynamisch allozieren *)
	PACWIDTH* = 16;	(* Dimensionen des PacMans *)
	PACHEIGHT* = 16;

TYPE
	(*AFrame = ARRAY PACHEIGHT+1 OF SET;*)
    (*AFrame = ARRAY 2 + 16 * 2 OF BYTE;*) (* Pattern: First 2 bytes: width and height; then pattern data *)
	PData* = RECORD
		anim*: ARRAY N OF INTEGER;	(* die Animationssequenz *)
		w*, h*, n*: BYTE	(* Breite, Hoehe, # AnimationsFrames *)
	END; 

	PacMan* = POINTER TO PacManDesc;
	PacManDesc* = RECORD(OliObjects.ObjectDesc)
		(*pat*: ARRAY N OF INTEGER; *)	(* die "Pointers" auf die Patterns *)
		id*: INTEGER;	(* bis zu 256 PacMen koennen rumwuseln :) *)
		n*: INTEGER;	(* Anzahl Animationsframes *)
		cur*: INTEGER	(* momentanes Animationsframe *)
	END;
	
	PacManMethod = OliObjects.Method;

VAR
	pacmanmethod: PacManMethod;	(* globale Variable, da Methoden fix sind *)
	id: INTEGER;	(* global: naechste zu vergebene PacMan-ID *)
	pdata*: PData;
	F: Files.File;
	R: Files.Rider;
	i, j: INTEGER;

PROCEDURE CopyPacMan(from, to: OliObjects.Object);
(* kopiert einen PacMan: from ist der OriginalPacMan MyPacMan, to ist ein vorgaengig mit MyPacMan.do.new() erschaffener PacMan *)
VAR
	
BEGIN
	to(PacMan)^:= from(PacMan)^
END CopyPacMan;

PROCEDURE SelectablePacMan(pacman: OliObjects.Object; x, y: INTEGER): BOOLEAN;
(* entscheidet, ob ein Mausklick mit Toleranz tol den PacMan selektiert *)
VAR
BEGIN
	RETURN (x >= pacman.x - tol) & (x <= pacman.x + pacman.w + tol) & (y >= pacman.y - tol) & (y <= pacman.y + pacman.h + tol) 
END SelectablePacMan;

PROCEDURE HandlePacMan(pm: OliObjects.Object; VAR msg: OliObjects.Message);
(* interpretiert die Messages, welche von FortiFrames  aus kommen *)
(* im Moment wird nur die DrawMsg und OPacMoveMsg interpretiert *)
VAR
	u, v, w, h: INTEGER;	(* Screen-Koordinaten *)
BEGIN

	CASE msg OF FortiFrames.DrawMsg:
		CASE pm OF PacMan:
			u:= pm.x + msg.f.x;	(* Screenkoordinaten berechnen *)
			v:= pm.y + msg.f.y;
			w:= pm.w;
			h:= pm.h;
			
			IF msg.mode = OliObjects.Draw THEN
				IF pm.selected THEN
					Display.CopyPattern(pm.col, pdata.anim[pm.cur], u, v, Display.paint);
					Display.ReplConst(Display.white, u, v, w, h, Display.invert)
				ELSE
					Display.CopyPattern(pm.col, pdata.anim[pm.cur], u, v, Display.paint);
				END;
			ELSIF msg.mode = OliObjects.Select THEN 
				Display.ReplConst(Display.white, u, v, w, h, Display.invert)
			ELSIF msg.mode = OliObjects.Normal THEN 
				Display.ReplConst(Display.white, u, v, w, h, Display.invert)
			ELSIF msg.mode = OliObjects.Erase THEN 
				Display.ReplConst(Display.black, u, v, w, h, Display.paint)
			END
		END
	| FortiFrames.OPacMoveMsg:
		CASE pm OF PacMan:
			IF pm.id = msg.id THEN	(* dieser PacMan ist gemeint: bewege ihn *)
				u:= pm.x + msg.f.x;	(* Screenkoordinaten berechnen *)
				v:= pm.y + msg.f.y;
				w:= pm.w;
				h:= pm.h;

				(* loesche alte Position: *)
				(*Display.CopyPatternC(msg.f, Display.black, pm.pat[pm.cur], u, v, Display.paint); *)
				(*Display.CopyPattern(Display.black, pm.pat[pm.cur], u, v, Display.paint);*)
				Display.CopyPattern(Display.black, pdata.anim[pm.cur], u, v, Display.paint);
				INC(pm.x, (msg.dx));	(* Koordinaten updaten *)
				INC(pm.y, (msg.dy));
				INC(u, (msg.dx));
				INC(v,  (msg.dy));
				pm.cur:= (pm.cur + 1) MOD pm.n;	(* Animationsframe um 1 weiterschalten *)
				
				(* neue Position malen: *)
				(* Display.CopyPatternC(msg.f, pm.col, pm.pat[pm.cur], u, v, Display.paint) *)
				(*Display.CopyPattern(pm.col, pm.pat[pm.cur], u, v, Display.paint)*)
				Display.CopyPattern(pm.col, pdata.anim[pm.cur], u, v, Display.paint)
			END	(* dieser PacMan *)
		END
	END	(* Ignoriere andere Messages *)
END HandlePacMan;
					
PROCEDURE NewPacMan*(): OliObjects.Object;
(* retourniert einen neuen PacMan und initialisiert Methoden-Rekord *)
VAR
	pacman: PacMan;
BEGIN
	NEW(pacman);
	pacman.do := pacmanmethod;
	RETURN pacman
END NewPacMan;

(* --- User Prozeduren ----------------------------------------------- *)

PROCEDURE MakePacMan*();
(* Ruft einen PacMan ins Leben *)
(* Format von pacman.res: *)
(*
	# Animationsframes
	Breite
	Hoehe
	Daten
*)
VAR
	pacman: PacMan;
	rmMsg: FortiFrames.RestoreMarksMsg;
	i: INTEGER;
BEGIN
	IF FortiFrames.mark0.set  THEN
		
		NEW(pacman);
		pacman.col:= OliObjects.color;
		pacman.selected:= FALSE;	(* PacMan soll nicht selektiert werden *)
		pacman.x:= FortiFrames.mark0.x;
		pacman.y:= FortiFrames.mark0.y;
		pacman.w:= PACWIDTH;
		pacman.h:= PACHEIGHT;
		pacman.do:= pacmanmethod;
		pacman.cur:= 0;
		pacman.id:= id;
		pacman.n:= pdata.n;
		INC(id);	(* naechste zu vergebene ID aktualisieren *)
		
		Viewers.Broadcast(rmMsg);	(* alte Markierungen werden geloescht *)
		FortiFrames.SetMarkEnabled(0, FALSE);
			
		(* die folgene Prozedur kuemmert sich um das Einfuegen und Benachrichtigen aller Frames *)
		(* ausserdem werden dort alle anderen Objekte vorher deselektiert *)
		FortiFrames.InsertObject(FortiFrames.markedG, pacman)

	END
END MakePacMan;

BEGIN
	(* der Methodenrekord wird einmal initialisiert und ist somit fix *)
	NEW(pacmanmethod);
	pacmanmethod.new:= NewPacMan;
	pacmanmethod.copy:= CopyPacMan;
	pacmanmethod.selectable:= SelectablePacMan;
	pacmanmethod.handle:= HandlePacMan;
	id := 0;

	(* pixmap data *)
	(*
	pdata.anim[0][2] := 0CH;
	pdata.anim[0][3] := 00H;
	pdata.anim[0][4] := 00H;
	pdata.anim[0][5] := 03H;

	pdata.anim[0][6] := 0FH;
	pdata.anim[0][7] := 00H;
	pdata.anim[0][8] := 00H;
	pdata.anim[0][9] := 0FH;

	pdata.anim[0][10] := 0FH;
	pdata.anim[0][11] := 08H;
	pdata.anim[0][12] := 01H;
	pdata.anim[0][13] := 0FH;

	pdata.anim[0][14] := 0FH;
	pdata.anim[0][15] := 0CH;
	pdata.anim[0][16] := 03H;
	pdata.anim[0][17] := 0FH;

	pdata.anim[0][18] := 09H;
	pdata.anim[0][19] := 0EH;
	pdata.anim[0][20] := 07H;
	pdata.anim[0][21] := 0FH;

	pdata.anim[0][22] := 09H;
	pdata.anim[0][23] := 0EH;
	pdata.anim[0][24] := 07H;
	pdata.anim[0][25] := 0FH;

	pdata.anim[0][26] := 0FH;
	pdata.anim[0][27] := 0FH;
	pdata.anim[0][28] := 0FH;
	pdata.anim[0][29] := 0FH;

	pdata.anim[0][30] := 0FH;
	pdata.anim[0][31] := 0FH;
	pdata.anim[0][32] := 0FH;
	pdata.anim[0][33] := 0FH;
	*)
	
	pdata.anim[0] := SYSTEM.ADR($0F0F 0A0FE01F F03FF87F FCE7FEE7 FEFFFEFF FEFFFEFF FEFFFE7F FC3FF81F F00FE000 00$);
	pdata.anim[1] := SYSTEM.ADR($0F0F 8000 8220 8410 8808 9004 A002 C001 7F7F C001 A002 9004 8808 8410 8220 8000$);
	
	pdata.w := 16;
	pdata.h := 16;
	pdata.n := 2;

END PacMan.
