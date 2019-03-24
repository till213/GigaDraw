MODULE Circles;
(* Systemsoftware WS 98/99, Oliver Knoll, Raphael Huber *)

(* implementiert Kreise - die Koordinaten sind "Weltkoordinaten", bei einer DrawMsg rechnen die Kreise *)
(* diese Koordinaten selbstaendig in Screenkoordinaten um *)

IMPORT OliObjects, FortiFrames, Display, Oberon, Viewers, Math, Out;

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

PROCEDURE BresenhamCircleC(xc, yc, r, col: INTEGER; F: FortiFrames.Frame);
(* Malt Kreise geclipped in xc, yc mit Radius r *)

VAR
	x, y, d, deltaE, deltaSE: INTEGER;

BEGIN
	x:= 0;
	y:= r;
	d:= 1 - r;
	deltaE:= 3;
	deltaSE:= -2 * r + 5;
	Display.DotC(F, col, x + xc, y + yc, Display.replace);
	Display.DotC(F, col, x + xc, -y + yc, Display.replace);
	Display.DotC(F, col, y + xc, x + yc, Display.replace);
	Display.DotC(F, col, -y + xc, x + yc, Display.replace);
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
		Display.DotC(F, col, x + xc, y + yc, Display.replace);
		Display.DotC(F, col, x + xc, -y + yc, Display.replace);
		Display.DotC(F, col, -x + xc, -y + yc, Display.replace);
		Display.DotC(F, col, -x + xc, y + yc, Display.replace);
		Display.DotC(F, col, y + xc, x + yc, Display.replace);
		Display.DotC(F, col, y + xc, -x + yc, Display.replace);
		Display.DotC(F, col, -y + xc, -x + yc, Display.replace);
		Display.DotC(F, col, -y + xc, x + yc, Display.replace);
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
BEGIN
	WITH circle: Circle DO
		dx:= x - (circle.x + circle.r);
		dy:= y - (circle.y + circle.r);
		RETURN (SHORT(ENTIER(Math.sqrt(dx*dx + dy*dy))) + TOL >= circle.r ) & (SHORT(ENTIER(Math.sqrt(dx*dx + dy*dy))) - TOL <= circle.r)
	END
END SelectableCircle;

PROCEDURE HandleCircle(circle: OliObjects.Object; VAR msg: OliObjects.Message);
(* interpretiert die Messages, welche von FortiFrames aus kommen *)
(* im Moment wird nur die DrawMsg interpretiert *)

VAR
	u, v: INTEGER;	(* Screen-Koordinaten *)
	
BEGIN
	IF msg IS FortiFrames.DrawMsg THEN
		WITH msg: FortiFrames.DrawMsg DO
			WITH circle: Circle DO
				u:= circle.x + circle.r + msg.f.x;	(* Screenkoordinaten berechnen *)
				v:= circle.y + circle.r + msg.f.y;
			
				CASE msg.mode OF
					OliObjects.draw:	IF circle.selected THEN
													BresenhamCircleC(u, v, circle.r, circle.col, msg.f);
													Display.ReplConstC(msg.f, Display.white, u, v - circle.r, SAW, SAH, Display.invert);
													
												ELSE
													BresenhamCircleC(u, v, circle.r, circle.col, msg.f);
												END;
					|	OliObjects.select:	Display.ReplConstC(msg.f, Display.white, u, v - circle.r, SAW, SAH, Display.invert);
					|	OliObjects.normal:	Display.ReplConstC(msg.f, Display.white, u, v - circle.r, SAW, SAH, Display.invert);
					|	OliObjects.erase:	Display.ReplConstC(msg.f, Display.white, u, v - circle.r, SAW, SAH, Display.invert);
														BresenhamCircleC(u, v, circle.r, Display.black, msg.f);
													
				END
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
	IF ~((FortiFrames.mark0.set) & (FortiFrames.mark1.set)) THEN
		(* eventuell hier noch Fehlermeldung ausgeben *)
		RETURN
	END;
	
	NEW(circle);
	dx:= FortiFrames.mark1.x - FortiFrames.mark0.x;
	dy:= FortiFrames.mark1.y - FortiFrames.mark0.y;
	circle.r:= SHORT(ENTIER(Math.sqrt(dx * dx + dy * dy)));
	Out.Int(dx, 5);
	Out.Int(dy, 5);
	Out.Int(circle.r, 5);
	circle.x:= FortiFrames.mark0.x - circle.r;
	circle.y:= FortiFrames.mark0.y - circle.r;
	circle.w:= 2 * circle.r;
	circle.h:= circle.w;
	circle.col:= OliObjects.color;
	circle.selected:= TRUE;	(* Kreis soll selektiert gemalt werden *)
	circle.do:= circlemethod;

	Viewers.Broadcast(rmMsg);	(* alte Markierungen werden geloescht *)
	FortiFrames.mark0.set:= FALSE;	(* mark0 soll verschwinden *)
	FortiFrames.mark1.set:= FALSE;	(* mark1 soll verschwinden *)

	(* die folgene Prozedur kuemmert sich um das Einfuegen und Benachrichtigen aller Frames *)
	(* ausserdem werden dort alle anderen Objekte vorher deselektiert *)
	FortiFrames.InsertObject(FortiFrames.markedG, circle)
END MakeCircle;

BEGIN
	(* der Methodenrekord wird einmal initialisiert und ist somit fix *)
	NEW(circlemethod);
	circlemethod.new:= NewCircle;
	circlemethod.copy:= CopyCircle;
	circlemethod.selectable:= SelectableCircle;
	circlemethod.handle:= HandleCircle;
END Circles.
