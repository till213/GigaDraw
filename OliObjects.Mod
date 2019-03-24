(* Systemsoftware WS 98/99, Oliver Knoll, Raphael Huber *)
MODULE OliObjects;

(* in allen Objekten sind die "Welt" - Koordinaten gespeichert *)
(* "Welt" - Koordinaten: Koordinaten, die sich auf unser definiertes Koordinatensystem beziehen *)

	CONST
	draw* = 0;	(* malt ein Objekt gemaess seinem Status (normal/selektiert) *)
	select* = 1;	(* malt ein Objekt selektiert *)
	normal* = 2;	(* malt ein selektiertes Objekt normal *)
	erase* = 3;	(* loescht ein Objekt *)
	

TYPE
	Method* = POINTER TO MethodDesc;

	Object* = POINTER TO ObjectDesc;
	ObjectDesc* = RECORD
		x*, y*, w*, h*: INTEGER;	(* w, h koennen auch negativ sein *)
		col*: INTEGER; (* SHORTINT *)
		selected*: BOOLEAN;
		do*: Method;
		next: Object;
	END;
	
	Message* = RECORD END;

	(* Abstrakte Schnittstelle: das muessen alle Objekte mind. koennen *)
	MethodDesc* = RECORD
		new*: PROCEDURE (): Object;	(* wird vorgaengig zum Copy gebraucht *)
		copy*: PROCEDURE (from, to: Object);
		selectable*: PROCEDURE (obj: Object; x, y: INTEGER): BOOLEAN;
		handle*: PROCEDURE (obj: Object; VAR msg: Message);
	END;

	Graphic* = POINTER TO GraphicDesc;
	GraphicDesc* = RECORD
		root: Object;
	END;

VAR	(* global *)
	color*: INTEGER;	(* SHORTINT - mit dieser Farbe werden beim Einfuegen Objekte gemalt *)

PROCEDURE Max(a, b: LONGINT): LONGINT;
(* retourniert den groesseren Wert *)
VAR
	max: LONGINT;
BEGIN
  IF a >= b THEN
    max := a
  ELSE
    max := b
  END
  RETURN max
END Max;


PROCEDURE AddObject*(G: Graphic; obj: Object);
(* fuegt Objekt zu Graphic hinzu *)
VAR
	mass: LONGINT;	(* Flaeche eines Objektes als Mass: kleine Objekte zuerst in lin. Liste *)
	p, q: Object;

BEGIN
	mass:= Max(obj.w, obj.h);
	p:= G.root;
	q:= NIL;
	IF (p # NIL)  THEN	(* schon Objekte im Graphen  *)
		IF (Max(p.w, p.h) < mass) THEN	(* erstes Objekt ist kleiner als einzufuegendes *)
			WHILE (p # NIL) & (Max(p.w, p.h) < mass) DO
				q:= p;
				p:= p.next
			END;
			obj.next:= p;
			q.next:= obj
		ELSE	(* fuege an erste Stelle im Graphen ein *)
			obj.next:= G.root;
			G.root:= obj
		END
	ELSE	(* noch gar kein Objekt im Graphen *)
		G.root:= obj;
		obj.next:= NIL
	END
END AddObject;

PROCEDURE Move*(G: Graphic; dx, dy: INTEGER);
(* verschiebt die selektierten Objekte um dx, dy *)
VAR
	obj: Object;

BEGIN
	obj:= G.root;
	WHILE obj # NIL DO
		IF (obj.selected) THEN
			INC(obj.x, dx);
			INC(obj.y, dy);
		END;
		obj:= obj.next;
	END
END Move;

PROCEDURE Copy*(Gs, Gd: Graphic; dx, dy: INTEGER);
(* kopiert die selektierten Objekte, auch in andere Frames hinein! Kopien erhalten Offset dx, dy *)
(* das Original wird deselektiert, die Kopie behaelt Selektierung bei *)

VAR
	obj, newobj: Object;
	
BEGIN
	obj:= Gs.root;
	WHILE obj # NIL DO
		IF obj.selected THEN
			newobj:= obj.do.new();
			obj.do.copy(obj, newobj);
			INC(newobj.x, dx);
			INC(newobj.y, dy);
			obj.selected:= FALSE;
			AddObject(Gd, newobj);
		END;
		obj:= obj.next;
	END
END Copy;
			
PROCEDURE DeleteSelected*(G: Graphic);
(* loescht die selektierten Objekte *)
VAR
	obj, pred: Object;

BEGIN
	obj:= G.root;
	WHILE (obj # NIL) & obj.selected DO
		obj:= obj.next;
	END;
	G.root:= obj;
	IF obj # NIL THEN
		pred:= obj;
		obj:= obj.next;
		WHILE obj # NIL DO
			IF obj.selected THEN
				pred.next:= obj.next
			ELSE
				pred:= obj
			END;
			obj:= obj.next
		END
	END
END DeleteSelected;

PROCEDURE SelectObject*(obj: Object);
(* selektiert ein Objekt, welches zuvor mit ThisObject gepickt wurde *)
	
VAR
	
BEGIN
	IF obj # NIL THEN
		obj.selected:= TRUE
	END
END SelectObject;

PROCEDURE SelectArea*(G: Graphic; x0, y0, x1, y1: INTEGER);
(* selektiert alle Objekte ganz innerhalb aufgespanntem Rechteck, wobei Koordinaten "mathematisch" sind *)
(* x0, y0: erster Mausklick - x1, y1: zweiter Punkt (Maus losgelassen) *)
(* "normalisierte" Dimensionen: Koordinaten x, y sind links unten, w, h sind positiv *)

VAR
	obj: Object;
	tmp: INTEGER;
	xn, yn, wn, hn: INTEGER;	(* "normalisierte" Object-Dimensionen *)

BEGIN
	IF x1 < x0 THEN	(* x0 und x1 vertauschen *)
		tmp:= x0;
		x0:= x1;
		x1:= tmp;
	END;
	IF y1 < y0 THEN	(* y0 und y1 vertauschen *)
		tmp:= y0;
		y0:= y1;
		y1:= tmp;
	END;
	obj:= G.root;
	WHILE obj # NIL DO
		IF obj.w >= 0 THEN	(* normalisiere Dimensionen von Object: *)
			xn:= obj.x;
			wn:= obj.w;
		ELSE	(* w < 0 *)
			xn:= obj.x + obj.w;
			wn:= -obj.w;
		END;
		IF obj.h >= 0 THEN
			yn:= obj.y;
			hn:= obj.h;
		ELSE	(* w < 0 *)
			yn:= obj.y + obj.h;
			hn:= -obj.h;
		END;
		
		IF (xn >= x0) & (xn + wn < x1) & (yn >= y0) & (yn + hn < y1) THEN	(* ist im Rechteck ... *)
			obj.selected:= TRUE;
		END;
		obj:= obj.next;
	END
END SelectArea;

PROCEDURE DeselectAll*(G: Graphic);
(* Deselektiert alle Objekte im Graph G *)
VAR
	obj: Object;
BEGIN
	obj:= G.root;
	WHILE obj # NIL DO
		obj.selected:= FALSE;
		obj:= obj.next
	END
END DeselectAll;

PROCEDURE ThisObject*(G: Graphic; x, y: INTEGER): Object;
(* Retourniert ein  anhand der "mathematischen" Koordinaten angewaehltes Objekt *)
VAR
  obj: Object;
BEGIN
  obj:= G.root;
  WHILE (obj # NIL) & ~obj.do.selectable(obj, x, y) DO
    obj:= obj.next;
  END;
  RETURN obj
END ThisObject;

PROCEDURE BroadcastAll*(G: Graphic; VAR M: Message);
(* posted die Message an alle Objekte *)
VAR
	obj: Object;

BEGIN
	obj:= G.root;
	WHILE obj # NIL DO
		obj.do.handle(obj, M);
		obj:= obj.next
	END
END BroadcastAll;

PROCEDURE BroadcastSelected*(G: Graphic; VAR M: Message);
(* posted die Message nur an selektierte Objekte *)
VAR
	obj: Object;

BEGIN
	obj:= G.root;
	WHILE obj # NIL DO
		IF obj.selected THEN
			obj.do.handle(obj, M);
		END;
		obj:= obj.next
	END
END BroadcastSelected;

PROCEDURE NewGraphic*(): Graphic;
(* liefert eine leere Grahpik zurueck *)

VAR
	g: Graphic;

BEGIN
	NEW(g);
	g.root:= NIL;	(* noch keine Objekte darin *)
	RETURN g
END NewGraphic;

PROCEDURE ChangeColor*(newc: INTEGER);
VAR

BEGIN
	color:= newc;
END ChangeColor;

BEGIN
	color:= 15;
END OliObjects.