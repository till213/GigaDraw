MODULE gLines;
(* Systemsoftware WS 98/99, Oliver Knoll, Raphael Huber *)

(* implementiert schraege Linien - die Koordinaten sind "Weltkoordinaten", bei einer DrawMsg rechnen die Linien *)
(* diese Koordinaten selbstaendig in Screenkoordinaten um *)

IMPORT Display, Viewers, Oberon, OliObjects, FortiFrames;

CONST
	tol = 2;	(* Toleranz: 2 Pixel darf man danebenklicken *)
	SAW = 8;	(* Sensitive Area Breite *)
	SAH = 8;	(* Sensitive Area Hoehe *)

TYPE
	gLine = POINTER TO gLineDesc;
	gLineDesc = RECORD(OliObjects.ObjectDesc)
	END;
	
	gLineMethod = OliObjects.Method;

 VAR
	glinemethod: gLineMethod;	(* globale Variable, da Methoden fix sind *)

PROCEDURE BresenhamLine(x0, y0, x1, y1, col: INTEGER; F: FortiFrames.Frame);
VAR
	dx, dy, incE, incNE, d, x, y: INTEGER;
	incX, incY: INTEGER;
	tmp: INTEGER;
	
BEGIN
	dx:= ABS(x1 - x0);
	dy:= ABS(y1 - y0);
	IF dx >= dy THEN	(* Steigung kleiner 1 *)
		IF x1 < x0 THEN
			tmp:= x1;
			x1:= x0;
			x0:= tmp;
			tmp:= y1;
			y1:= y0;
			y0:= tmp;
		END;
		IF y1 > y0 THEN
			incY:= 1;
		ELSE
			incY:= -1;
		END;
		incE:= 2 * dy;
		incNE:= 2 * (dy - dx);
		x:= x0;
		y:= y0;
		Display.Dot(col, x, y, Display.replace);
		WHILE (x < x1) DO
			IF (d <= 0) THEN
				INC(d, incE)
			ELSE
				INC(d, incNE);
				INC(y, incY);
			END;
			INC(x);
			Display.Dot(col, x, y, Display.replace)
		END
	ELSE	(* Steigung > 1 *)
		IF y1 < y0 THEN
			tmp:= x1;
			x1:= x0;
			x0:= tmp;
			tmp:= y1;
			y1:= y0;
			y0:= tmp;
		END;
		IF x1 > x0 THEN
			incX:= 1;
		ELSE
			incX:= -1;
		END;
		incE:= 2 * dx;
		incNE:= 2 * (dx - dy);
		x:= x0;
		y:= y0;
		(*Display.DotC(F, col, x, y, Display.replace);*)
		Display.Dot(col, x, y, Display.replace);
		WHILE (y < y1) DO
			IF (d <= 0) THEN
				INC(d, incE)
			ELSE
				INC(d, incNE);
				INC(x, incX);
			END;
			INC(y);
			(* Display.DotC(F, col, x, y, Display.replace)*)
			Display.Dot(col, x, y, Display.replace)
		END
	END
END BresenhamLine;
	
PROCEDURE CopygLine(from, to: OliObjects.Object);
(* kopiert eine gLinie: from ist die Originallinie MygLine, to ist eine vorgaengig mit MygLine.do.new() erschaffene gLinie *)

VAR

BEGIN
	to(gLine)^:= from(gLine)^
END CopygLine;

PROCEDURE SelectablegLine(gline: OliObjects.Object; x, y: INTEGER): BOOLEAN;
(* entscheidet, ob ein Mausklick mit Toleranz tol die Linie selektiert *)
(* sensitiver Punkt ist Start und Endpunkt *)

VAR
	sel: BOOLEAN;
BEGIN
	CASE gline OF gLine:
		sel := ((x >= gline.x - tol) & (x <= gline.x + SAW + tol) & (y >= gline.y - tol) & (y <= gline.y + SAH + tol)) OR
			((x >= gline.x + gline.w - tol) & (x <= gline.x + gline.w + SAW + tol) & (y >= gline.y + gline.h - tol) & (y <= gline.y + gline.h + SAH + tol))
	END
	RETURN sel
END SelectablegLine;

PROCEDURE HandlegLine(gline: OliObjects.Object; VAR msg: OliObjects.Message);
(* interpretiert die Messages, welche von FortiFrames aus kommen *)
(* im Moment wird nur die DrawMsg interpretiert *)

VAR
	u, v: INTEGER;	(* Screen-Koordinaten *)
	
BEGIN
	CASE msg OF FortiFrames.DrawMsg:
		CASE gline OF gLine:
			u:= gline.x + msg.f.x;	(* Screenkoordinaten berechnen *)
			v:= gline.y + msg.f.y;
		
		    (* Numerical case not implemented *)
			(*
			CASE msg.mode OF
				OliObjects.draw:	IF gline.selected THEN
												BresenhamLine(u, v, u + gline.w, v + gline.h, gline.col, msg.f);
												Display.ReplConstC(msg.f, Display.white, u, v, SAW, SAH, Display.invert);
												Display.ReplConstC(msg.f, Display.white, u + gline.w, v + gline.h, SAW, SAH, Display.invert);
											ELSE
												BresenhamLine(u, v, u + gline.w, v + gline.h, gline.col, msg.f);
											END;
				|	OliObjects.select:	Display.ReplConstC(msg.f, Display.white, u, v, SAW, SAH, Display.invert);
												Display.ReplConstC(msg.f, Display.white, u + gline.w, v + gline.h, SAW, SAH, Display.invert)
				|	OliObjects.normal:	Display.ReplConstC(msg.f, Display.white, u, v, SAW, SAH, Display.invert);
												Display.ReplConstC(msg.f, Display.white, u + gline.w, v + gline.h, SAW, SAH, Display.invert)
				|	OliObjects.erase:	Display.ReplConstC(msg.f, Display.white, u, v, SAW, SAH, Display.invert);
												Display.ReplConstC(msg.f, Display.white, u + gline.w, v + gline.h, SAW, SAH, Display.invert);
												BresenhamLine(u, v, u + gline.w, v + gline.h, Display.black, msg.f);
												
			END
			*)
			IF msg.mode = OliObjects.draw THEN	
				IF gline.selected THEN
					BresenhamLine(u, v, u + gline.w, v + gline.h, gline.col, msg.f);
					Display.ReplConst(Display.white, u, v, SAW, SAH, Display.invert);
					Display.ReplConst(Display.white, u + gline.w, v + gline.h, SAW, SAH, Display.invert);
				ELSE
					BresenhamLine(u, v, u + gline.w, v + gline.h, gline.col, msg.f);
				END;
			ELSIF msg.mode = OliObjects.select THEN
				Display.ReplConst(Display.white, u, v, SAW, SAH, Display.invert);
				Display.ReplConst(Display.white, u + gline.w, v + gline.h, SAW, SAH, Display.invert)
			ELSIF msg.mode = OliObjects.normal THEN	
				Display.ReplConst(Display.white, u, v, SAW, SAH, Display.invert);
				Display.ReplConst(Display.white, u + gline.w, v + gline.h, SAW, SAH, Display.invert)
			ELSIF msg.mode = OliObjects.erase THEN
				Display.ReplConst(Display.white, u, v, SAW, SAH, Display.invert);
				Display.ReplConst(Display.white, u + gline.w, v + gline.h, SAW, SAH, Display.invert);
				BresenhamLine(u, v, u + gline.w, v + gline.h, Display.black, msg.f)								
			END
		END
	END	(* Ignoriere andere Messages *)
END HandlegLine;
					
PROCEDURE NewgLine(): OliObjects.Object;
(* retourniert eine neue gLinie und initialisiert Methoden-Rekord *)

VAR
	gline: gLine;
	
BEGIN
	NEW(gline);
	gline.do:= glinemethod;
	RETURN gline
END NewgLine;

(* --- User Prozeduren ----------------------------------------------- *)

PROCEDURE MakegLine*();
(* Zeichnet gLinie im mit dem Stern markierten Frame. Diese ist anschliessend selektiert *)
(* eine Linie wird von mark0 nach mark1 gemalt, wobei mark0 anschliessend Position *)
(* von mark1 einnimmt und mark1 verschwindet. *)

VAR
	gline: gLine;
	
rmMsg: FortiFrames.RestoreMarksMsg;
	
BEGIN
	IF ((FortiFrames.mark0.set) & (FortiFrames.mark1.set)) THEN

		NEW(gline);
		gline.w:= FortiFrames.mark1.x - FortiFrames.mark0.x;
		gline.h:= FortiFrames.mark1.y - FortiFrames.mark0.y;
		gline.x:= FortiFrames.mark0.x;
		gline.y:= FortiFrames.mark0.y;
		
		gline.col:= OliObjects.color;
		gline.selected:= TRUE;	(* Linie soll selektiert gemalt werden *)
		gline.do:= glinemethod;

		Viewers.Broadcast(rmMsg);	(* alte Markierungen werden geloescht *)
		
		FortiFrames.SetMarkX(0, FortiFrames.mark1.x);
		FortiFrames.SetMarkY(0, FortiFrames.mark1.y);
		(*FortiFrames.mark0.x:= FortiFrames.mark1.x;	(* mark0 geht erst jetzt an Pos. von mark1 *)
		FortiFrames.mark0.y:= FortiFrames.mark1.y; *)
		FortiFrames.SetMarkEnabled(1, FALSE);
		(*FortiFrames.mark1.set:= FALSE;*)	(* mark1 soll verschwinden *)
		
		(* die folgene Prozedur kuemmert sich um das Einfuegen und Benachrichtigen aller Frames *)
		(* ausserdem werden dort alle anderen Objekte vorher deselektiert *)
		FortiFrames.InsertObject(FortiFrames.markedG, gline)

	END

END MakegLine;

BEGIN
	
	(* der Methodenrekord wird einmal initialisiert und ist somit fix *)
	NEW(glinemethod);
	glinemethod.new:= NewgLine;
	glinemethod.copy:= CopygLine;
	glinemethod.selectable:= SelectablegLine;
	glinemethod.handle:= HandlegLine;
END gLines.


ORP.Compile GDgLines.Mod~
