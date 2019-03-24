MODULE PacMan;
(* Systemsoftware WS 98/99, Oliver Knoll, Raphael Huber *)

(* implementiert PacMan - die PacMan-koordinaten sind "Weltkoordinaten", bei einer DrawMsg rechnet der PacMan *)
(* diese Koordinaten selbstaendig in Screenkoordinaten um *)


IMPORT OliObjects, FortiFrames, Display, Oberon, Viewers, Files, Out;

CONST
	tol = 2;	(* Toleranz: 2 Pixel darf man danebenklicken *)
	N = 8;	(* Max. 8 Animationsframes fuer PacMan -> Oberon-2: ev. dynamisch allozieren *)
	PACWIDTH* = 16;	(* Dimensionen des PacMans *)
	PACHEIGHT* = 16;

TYPE
	AFrame = ARRAY PACHEIGHT+1 OF SET;
	PData* = RECORD
		anim*: ARRAY N OF AFrame;	(* die Animationssequenz *)
		w*, h*, n*: SHORTINT	(* Breite, Hoehe, # AnimationsFrames *)
	END;

	PacMan* = POINTER TO PacManDesc;
	PacManDesc* = RECORD(OliObjects.ObjectDesc)
		pat*: ARRAY N OF LONGINT;	(* die "Pointers" auf die Patterns *)
		id*: SHORTINT;	(* bis zu 256 PacMen koennen rumwuseln :) *)
		n*: SHORTINT;	(* Anzahl Animationsframes *)
		cur*: SHORTINT;	(* momentanes Animationsframe *)
	END;
	
	PacManMethod = OliObjects.Method;

VAR
	pacmanmethod: PacManMethod;	(* globale Variable, da Methoden fix sind *)
	id: SHORTINT;	(* global: naechste zu vergebene PacMan-ID *)
	pdata*: PData;
	F: Files.File;
	R: Files.Rider;
	i, j: SHORTINT;

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
	IF msg IS FortiFrames.DrawMsg THEN
		WITH msg: FortiFrames.DrawMsg DO
			WITH pm: PacMan DO
				u:= pm.x + msg.f.x;	(* Screenkoordinaten berechnen *)
				v:= pm.y + msg.f.y;
				w:= pm.w;
				h:= pm.h;
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
			END
		END
	ELSIF msg IS FortiFrames.OPacMoveMsg THEN
		WITH msg: FortiFrames.OPacMoveMsg DO
			WITH pm: PacMan DO
				IF pm.id = msg.id THEN	(* dieser PacMan ist gemeint: bewege ihn *)
					u:= pm.x + msg.f.x;	(* Screenkoordinaten berechnen *)
					v:= pm.y + msg.f.y;
					w:= pm.w;
					h:= pm.h;

					(* loesche alte Position: *)
					Display.CopyPatternC(msg.f, Display.black, pm.pat[pm.cur], u, v, Display.paint);
					INC(pm.x, LONG(msg.dx));	(* Koordinaten updaten *)
					INC(pm.y, LONG(msg.dy));
					INC(u, LONG(msg.dx));
					INC(v,  LONG(msg.dy));
					pm.cur:= (pm.cur + 1) MOD pm.n;	(* Animationsframe um 1 weiterschalten *)
					
					(* neue Position malen: *)
					Display.CopyPatternC(msg.f, pm.col, pm.pat[pm.cur], u, v, Display.paint)
					END	(* dieser PacMan *)
			END
		END
	END	(* Ignoriere andere Messages *)
END HandlePacMan;


(*


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
	i: SHORTINT;
BEGIN
	IF ~FortiFrames.mark0.set  THEN
		(* eventuell hier noch Fehlermeldung ausgeben *)
		RETURN
	END;
		
	NEW(pacman);
	FOR i:= 0 TO pdata.n-1 DO
		pacman.pat[i]:= Display.NewPattern(pdata.anim[i], PACWIDTH, PACHEIGHT);
	END;
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
	FortiFrames.mark0.set:= FALSE;	(* mark0 soll verschwinden *)
		
	(* die folgene Prozedur kuemmert sich um das Einfuegen und Benachrichtigen aller Frames *)
	(* ausserdem werden dort alle anderen Objekte vorher deselektiert *)
	FortiFrames.InsertObject(FortiFrames.markedG, pacman)
END MakePacMan;

BEGIN
	(* der Methodenrekord wird einmal initialisiert und ist somit fix *)
	NEW(pacmanmethod);
	pacmanmethod.new:= NewPacMan;
	pacmanmethod.copy:= CopyPacMan;
	pacmanmethod.selectable:= SelectablePacMan;
	pacmanmethod.handle:= HandlePacMan;
	id:= 0;
	
	F:= Files.Old("pacman.res");
	IF F = NIL THEN
		RETURN
	END;
	Files.Set(R, F, 0);
	Files.Read(R, pdata.n);
	Files.Read(R, pdata.w);	(* Breite und Hoehe wird noch nicht gebraucht (ist noch fix auf 16) *)
	Files.Read(R, pdata.h);
	Out.Int(pdata.n, 5);
	FOR i:= 0 TO pdata.n-1 DO	(* lies die Animationsframes ein *)
		FOR j:= 0 TO PACHEIGHT DO	(* erstes SET wird anscheinend ignoriert (?) *)
			Files.ReadSet(R, pdata.anim[i][j])
		END
	END;

	*)
	
END PacMan.
