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
	RETURN  (x >= pacman.x - tol) & (x <= pacman.x + pacman.w + tol) & (y >= pacman.y - tol) & (y <= pacman.y + pacman.h + tol) 
END SelectablePacMan;

PROCEDURE HandlePacMan(pm: OliObjects.Object; VAR msg: OliObjects.Message);
(* interpretiert die Messages, welche von FortiFrames  aus kommen *)
(* im Moment wird nur die DrawMsg und OPacMoveMsg interpretiert *)

VAR
	u, v, w, h: INTEGER;	(* Screen-Koordinaten *)
	
BEGIN
	CASE msg OF 
	FortiFrames.DrawMsg:
		CASE pm OF PacMan:
			u:= pm.x + msg.f.x;	(* Screenkoordinaten berechnen *)
			v:= pm.y + msg.f.y;
			w:= pm.w;
			h:= pm.h;
			(* Numeric case not implemented
			CASE msg.mode OF
				OliObjects.draw:	IF pm.selected THEN
												Display.CopyPatternC(msg.f, pm.col, pm.pat[pm.cur], u, v, Display.paint);
												Display.ReplConstC(msg.f, Display.white, u, v, w, h, Display.invert)
											ELSE
												Display.CopyPatternC(msg.f, pm.col, pm.pat[pm.cur], u, v, Display.paint);
											END;
				|	OliObjects.select:	Display.ReplConstC(msg.f, Display.white, u, v, w, h, Display.invert)
				|	OliObjects.normal:	Display.ReplConstC(msg.f, Display.white, u, v, w, h, Display.invert)
				|	OliObjects.erase:	Display.ReplConstC(msg.f, Display.black, u, v, w, h, Display.paint)
			END
			*)
			IF msg.mode = OliObjects.draw THEN
				IF pm.selected THEN
					(*Display.CopyPattern(pm.col, pm.pat[pm.cur], u, v, Display.paint); *)
					Display.CopyPattern(pm.col, pdata.anim[pm.cur], u, v, Display.paint);
					Display.ReplConst(Display.white, u, v, w, h, Display.invert)
				ELSE
					(*Display.CopyPattern(pm.col, pm.pat[pm.cur], u, v, Display.paint);*)
					Display.CopyPattern(pm.col, pdata.anim[pm.cur], u, v, Display.paint);
				END;
			ELSIF msg.mode = OliObjects.select THEN 
				Display.ReplConst(Display.white, u, v, w, h, Display.invert)
			ELSIF msg.mode = OliObjects.normal THEN 
				Display.ReplConst(Display.white, u, v, w, h, Display.invert)
			ELSIF msg.mode = OliObjects.erase THEN 
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
	pacman.do:= pacmanmethod;
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
         (*
		FOR i:= 0 TO pdata.n-1 DO
			(*pacman.pat[i]:= Display.NewPattern(pdata.anim[i], PACWIDTH, PACHEIGHT);*)
		END;
*)
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
		(*FortiFrames.mark0.set:= FALSE;	(* mark0 soll verschwinden *) *)
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
	
	(*
	F:= Files.Old("PacMan.Res");
	IF F # NIL THEN

		Files.Set(R, F, 0);
		Files.ReadByte(R, pdata.n);
		Files.ReadByte(R, pdata.w);	(* Breite und Hoehe wird noch nicht gebraucht (ist noch fix auf 16) *)
		Files.ReadByte(R, pdata.h);
		(*Out.Int(pdata.n, 5); *)
		FOR i:= 0 TO pdata.n-1 DO	(* lies die Animationsframes ein *)
			(*FOR j:= 0 TO PACHEIGHT DO *)	(* erstes SET wird anscheinend ignoriert (?) *)
				Files.ReadBytes(R, pdata.anim[i], 2 + 4 * 4); (* Width; Height; Pattern data *)
			(*END*)
		END;

	END;
	*)

    (* First animation frame *)
	(* width/height *)
	(*pdata.anim[0][0] := PACWIDTH;
	pdata.anim[0][1] := PACHEIGHT;

	(* pixmap data *)
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

	(* 5 *)
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
 
    (* Arrow and star *)
	(*pdata.anim[0] := SYSTEM.ADR($0F0F 0060 0070 0038 001C 000E 0007 8003 C101 E300 7700 3F00 1F00 3F00 7F00 FF00$);
	pdata.anim[1] := SYSTEM.ADR($0F0F 8000 8220 8410 8808 9004 A002 C001 7F7F C001 A002 9004 8808 8410 8220 8000$);
	*)

	(* Original upside down *)
	(*pdata.anim[0] := SYSTEM.ADR($0F0F C003 F00F F81F FC3F 9E7F 9E7F FFFF FFFF FFFF FFFF FE7F FC3F F81F F00F C003$); *)
	
	
	
	pdata.anim[0] := SYSTEM.ADR($0F0F 0A0FE01F F03FF87F FCE7FEE7 FEFFFEFF FEFFFEFF FEFFFE7F FC3FF81F F00FE000 00$);
	
	
	pdata.anim[1] := SYSTEM.ADR($0F0F 8000 8220 8410 8808 9004 A002 C001 7F7F C001 A002 9004 8808 8410 8220 8000$);
	pdata.w := 16;
	pdata.h := 16;
	pdata.n := 2;


(*
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
*)

END PacMan.
