MODULE Circles;
(* Systemsoftware WS 98/99, Oliver Knoll, Raphael Huber *)

(* implementiert Kreise - die Koordinaten sind "Weltkoordinaten", bei einer DrawMsg rechnen die Kreise *)
(* diese Koordinaten selbstaendig in Screenkoordinaten um *)

IMPORT Display, Viewers, Math, Oberon, OliObjects, FortiFrames;

CONST
	TOL = 2;	(* Toleranz: 2 Pixel darf man danebenklicken *)
	SAW = 8;	(* Sensitive Area Breite *)
	SAH = 8;	(* Sensitive Area Hoehe *)

TYPE
	Circle = POINTER TO CircleDesc;
	CircleDesc = RECORD(OliObjects.ObjectDesc)
		r: INTEGER;	(* Radius r *)
	END;
	
	CircleMethod = OliObjects.Method;

 VAR
	circlemethod: CircleMethod;	(* globale Variable, da Methoden fix sind *)

PROCEDURE BresenhamCircleC(xc, yc, r, col: INTEGER; F: FortiFrames.FortiFrame);
(* Malt Kreise geclipped in xc, yc mit Radius r *)

VAR
	x, y, d, deltaE, deltaSE: INTEGER;

BEGIN
	x:= 0;
	y:= r;
	d:= 1 - r;
	deltaE:= 3;
	deltaSE:= -2 * r + 5;
	Display.Dot(col, x + xc, y + yc, Display.replace);
	Display.Dot(col, x + xc, -y + yc, Display.replace);
	Display.Dot(col, y + xc, x + yc, Display.replace);
	Display.Dot(col, -y + xc, x + yc, Display.replace);
	WHILE y > x DO
		IF d < 0 THEN
			INC(d, deltaE);
			INC(deltaE, 2);
			INC(deltaSE, 2)
		ELSE
			INC(d, deltaSE);
			INC(deltaE, 2);
			INC(deltaSE, 4);
			DEC(y)
		END;
		INC(x);
		Display.Dot(col, x + xc, y + yc, Display.replace);
		Display.Dot(col, x + xc, -y + yc, Display.replace);
		Display.Dot(col, -x + xc, -y + yc, Display.replace);
		Display.Dot(col, -x + xc, y + yc, Display.replace);
		Display.Dot(col, y + xc, x + yc, Display.replace);
		Display.Dot(col, y + xc, -x + yc, Display.replace);
		Display.Dot(col, -y + xc, -x + yc, Display.replace);
		Display.Dot(col, -y + xc, x + yc, Display.replace);
	END	
END BresenhamCircleC;
	
PROCEDURE CopyCircle(from, to: OliObjects.Object);
(* kopiert einen Kreis: from ist der Originalkreis MyCircle, to ist ein vorgaengig mit MyCircle.do.new() erschaffener Kreis *)
VAR
BEGIN
	to(Circle)^:= from(Circle)^
END CopyCircle;

PROCEDURE SelectableCircle(circle: OliObjects.Object; x, y: INTEGER): BOOLEAN;
(* entscheidet, ob ein Mausklick mit Toleranz tol den Kreis selektiert *)
VAR
	dx, dy: LONGINT;
	selectable: BOOLEAN;
BEGIN
	CASE circle OF Circle:
		dx:= x - (circle.x + circle.r);
		dy:= y - (circle.y + circle.r);
		selectable := (FLOOR(Math.sqrt(FLT(dx*dx + dy*dy))) + TOL >= circle.r) & (FLOOR(Math.sqrt(FLT(dx*dx + dy*dy))) - TOL <= circle.r)
	END
	RETURN selectable
END SelectableCircle;

PROCEDURE HandleCircle(circle: OliObjects.Object; VAR msg: OliObjects.Message);
(* interpretiert die Messages, welche von FortiFrames aus kommen *)
(* im Moment wird nur die DrawMsg interpretiert *)

VAR
	u, v: INTEGER;	(* Screen-Koordinaten *)
	
BEGIN
	CASE msg OF FortiFrames.DrawMsg:
		CASE circle OF Circle:
			u:= circle.x + circle.r + msg.f.x;	(* Screenkoordinaten berechnen *)
			v:= circle.y + circle.r + msg.f.y;
		
			IF msg.mode = OliObjects.Draw THEN
				IF circle.selected THEN
					BresenhamCircleC(u, v, circle.r, circle.col, msg.f);
					Display.ReplConst(Display.white, u, v - circle.r, SAW, SAH, Display.invert);
					
				ELSE
					BresenhamCircleC(u, v, circle.r, circle.col, msg.f);
				END;
			ELSIF msg.mode = OliObjects.Select THEN
				Display.ReplConst(Display.white, u, v - circle.r, SAW, SAH, Display.invert);
			ELSIF msg.mode = OliObjects.Normal THEN
				Display.ReplConst(Display.white, u, v - circle.r, SAW, SAH, Display.invert);
			ELSIF msg.mode = OliObjects.Erase THEN
				Display.ReplConst(Display.white, u, v - circle.r, SAW, SAH, Display.invert);
				BresenhamCircleC(u, v, circle.r, Display.black, msg.f);			
			END
		END
	END	(* Ignoriere andere Messages *)
END HandleCircle;
					
PROCEDURE NewCircle(): OliObjects.Object;
(* retourniert einen neuen Kreis und initialisiert Methoden-Rekord *)

VAR
	circle: Circle;
	
BEGIN
	NEW(circle);
	circle.do:= circlemethod;
	RETURN circle
END NewCircle;

(* --- User Prozeduren ----------------------------------------------- *)

PROCEDURE MakeCircle*();
(* Zeichnet Kreis im mit dem Stern markierten Frame. Dieser ist anschliessend selektiert *)
(* mark0 bestimmt den Mittelpunkt, mark1 den Radius *)
(* Beide Markierungen verschwinden *)

VAR
	circle: Circle;
	
	rmMsg: FortiFrames.RestoreMarksMsg;
	dx, dy: LONGINT;
	
BEGIN
	IF ((FortiFrames.mark0.set) & (FortiFrames.mark1.set)) THEN
		
	
		NEW(circle);
		dx:= FortiFrames.mark1.x - FortiFrames.mark0.x;
		dy:= FortiFrames.mark1.y - FortiFrames.mark0.y;
		circle.r:= FLOOR(Math.sqrt(FLT(dx * dx + dy * dy)));
		
		circle.x:= FortiFrames.mark0.x - circle.r;
		circle.y:= FortiFrames.mark0.y - circle.r;
		circle.w:= 2 * circle.r;
		circle.h:= circle.w;
		circle.col:= OliObjects.color;
		circle.selected:= TRUE;	(* Kreis soll selektiert gemalt werden *)
		circle.do:= circlemethod;

		Viewers.Broadcast(rmMsg);	(* alte Markierungen werden geloescht *)
		FortiFrames.SetMarkEnabled(0, FALSE); (* mark0 soll verschwinden *)
		FortiFrames.SetMarkEnabled(1, FALSE); (* mark1 soll verschwinden *)

		(* die folgene Prozedur kuemmert sich um das Einfuegen und Benachrichtigen aller Frames *)
		(* ausserdem werden dort alle anderen Objekte vorher deselektiert *)
		FortiFrames.InsertObject(FortiFrames.markedG, circle)

	END
END MakeCircle;

BEGIN
	(* der Methodenrekord wird einmal initialisiert und ist somit fix *)
	NEW(circlemethod);
	circlemethod.new:= NewCircle;
	circlemethod.copy:= CopyCircle;
	circlemethod.selectable:= SelectableCircle;
	circlemethod.handle:= HandleCircle;
END Circles.

ORP.Compile GDCircles.Mod~