(* 
   The base object for all other draw objects.

   Systemsoftware WS 98/99, Oliver Knoll, Raphael Huber 
*)
MODULE OliObjects;

CONST
	draw* = 0;   (* draws the object according to its state: normal or selected *)
	select* = 1; (* draws an object as selected *)
	normal* = 2; (* draws an object as normal *)
	erase* = 3;  (* erases an object*)
	
TYPE
	Method* = POINTER TO MethodDesc;
	Object* = POINTER TO ObjectDesc;
	Graphic* = POINTER TO GraphicDesc;
	(* The base of all messages *)
	Message* = RECORD END;

	(* The interface - "methods" - that all objects are required to implement:
	   Each object is expected to at least be able to create a new instance,
	   create a copy and determine whether it is selectable at the given
	   coordinates. All object-specific methods are handled in 'handle', by
	   interpreting the given message.
	 *)
	MethodDesc* = RECORD
		new*: PROCEDURE (): Object;
		copy*: PROCEDURE (from, to: Object);
		selectable*: PROCEDURE (obj: Object; x, y: INTEGER): BOOLEAN;
		handle*: PROCEDURE (obj: Object; VAR msg: Message);
	END;

	ObjectDesc* = RECORD
	    (* World coordinates of the object; w and h may also be negative *)
		x*, y*, w*, h*: INTEGER;
		col*: INTEGER;
		selected*: BOOLEAN;
		do*: Method;
		next: Object;
	END;
	
	(* All draw objects are linked in a simple linked list *)
	GraphicDesc* = RECORD
		root: Object;
	END;

VAR
	(* The globally set colour which is assigned to newly created objects:
	   Valid values are usually between 0 .. 15 inclusive, but whether they
	   are supported at all depends on the Oberon implementation: the original
	   Oberon only supports Black and White ;)
	 *)
	color*: INTEGER;

(* Returns the greatest value of a and b *)
PROCEDURE Max(a, b: LONGINT): LONGINT;
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

(* Adds the object to the graphics tree *)
PROCEDURE AddObject*(graphic: Graphic; obj: Object);
VAR
	(* The maximum of width and height; smaller objects appear first in the object list *)
	maxSize: LONGINT;	
	p, q: Object;
BEGIN
	maxSize := Max(obj.w, obj.h);
	p := graphic.root;
	q := NIL;
	IF (p # NIL)  THEN
	    (* The first object is smaller than the one to be inserted *)
		IF (Max(p.w, p.h) < maxSize) THEN
			WHILE (p # NIL) & (Max(p.w, p.h) < maxSize) DO
				q := p;
				p := p.next
			END;
			obj.next := p;
			q.next:= obj
		ELSE	
			(* Insert object as first object *)
			obj.next := graphic.root;
			graphic.root:= obj
		END
	ELSE
		(* This is the first object *)
		graphic.root := obj;
		obj.next := NIL
	END
END AddObject;

(* Moves the selected objects by dx, dy *)
PROCEDURE Move*(graphic: Graphic; dx, dy: INTEGER);
VAR
	obj: Object;
BEGIN
	obj:= graphic.root;
	WHILE obj # NIL DO
		IF (obj.selected) THEN
			INC(obj.x, dx);
			INC(obj.y, dy);
		END;
		obj:= obj.next;
	END
END Move;

(* Copies the selected objects, which also works across Frames. The copied objects are offset
   by dx, dy. The original objects are deselected, the newly copied objects keep their selection state.
*)
PROCEDURE Copy*(sourceGraphic, destinationGraphic: Graphic; dx, dy: INTEGER);
VAR
	obj, newobj: Object;
BEGIN
	obj:= sourceGraphic.root;
	WHILE obj # NIL DO
		IF obj.selected THEN
			newobj:= obj.do.new();
			obj.do.copy(obj, newobj);
			INC(newobj.x, dx);
			INC(newobj.y, dy);
			obj.selected:= FALSE;
			AddObject(destinationGraphic, newobj);
		END;
		obj:= obj.next;
	END
END Copy;
			
(* Deletes all selected objects *)
PROCEDURE DeleteSelected*(graphic: Graphic);
VAR
	obj, pred: Object;
BEGIN
	obj := graphic.root;
	(* Unlink the first n selected objects *)
	WHILE (obj # NIL) & obj.selected DO
		obj := obj.next;
	END;
	graphic.root:= obj;
	(* Unlink all selected objects after the first non-selected object *)
	IF obj # NIL THEN
		pred := obj;
		obj := obj.next;
		WHILE obj # NIL DO
			IF obj.selected THEN
				pred.next := obj.next
			ELSE
				pred := obj
			END;
			obj := obj.next
		END
	END
END DeleteSelected;

(* Marks the given object as selected *)
PROCEDURE SelectObject*(obj: Object);
VAR
BEGIN
	IF obj # NIL THEN
		obj.selected := TRUE
	END
END SelectObject;

(* Selects all objects within the rectangle given by x0, y0, x1, y1. 
   The coordinates are screen coordinates. x0/y0 are the coordinates 
   from the first mouse click, x1/y1 the coordinates when the mouse button 
   is released.
*)
PROCEDURE SelectArea*(graphic: Graphic; x0, y0, x1, y1: INTEGER);
VAR
	obj: Object;
	tmp: INTEGER;
	(* normalised world coordinates *)
	xn, yn, wn, hn: INTEGER;
BEGIN

	IF x1 < x0 THEN
		tmp := x0;
		x0 := x1;
		x1 := tmp;
	END;
	IF y1 < y0 THEN
		tmp := y0;
		y0 := y1;
		y1 := tmp;
	END;

	obj:= graphic.root;
	(* Normalise the size of the object *)
	WHILE obj # NIL DO
		IF obj.w >= 0 THEN
			xn := obj.x;
			wn := obj.w;
		ELSE	
			(* w < 0 *)
			xn := obj.x + obj.w;
			wn := -obj.w;
		END;
		IF obj.h >= 0 THEN
			yn := obj.y;
			hn := obj.h;
		ELSE	
			(* w < 0 *)
			yn := obj.y + obj.h;
			hn := -obj.h;
		END;
		
		(* Inside rectangle? *)
		(* Note: we seem to be mixing world- with screen coordinates here.
		   This probably works because our world coordinates are always congruent
		   with screen coordinates, unless of course we'd start to support
		   transformations such as scaling.
		 *)
		IF (xn >= x0) & (xn + wn < x1) & (yn >= y0) & (yn + hn < y1) THEN
			obj.selected := TRUE;
		END;
		obj := obj.next;
	END
END SelectArea;

(* Deselects all objects in the given graphic. *)
PROCEDURE DeselectAll*(graphic: Graphic);
VAR
	obj: Object;
BEGIN
	obj := graphic.root;
	WHILE obj # NIL DO
		obj.selected := FALSE;
		obj := obj.next
	END
END DeselectAll;

(* Returns the selectable object at screen coordinates x, y. *)
PROCEDURE ThisObject*(graphic: Graphic; x, y: INTEGER): Object;
VAR
  obj: Object;
BEGIN
  obj:= graphic.root;
  WHILE (obj # NIL) & ~obj.do.selectable(obj, x, y) DO
    obj:= obj.next;
  END;
  RETURN obj
END ThisObject;

(* Broadcasts the given message to all objects in the graphic,
   by calling their message handler.
 *)
PROCEDURE BroadcastAll*(graphic: Graphic; VAR message: Message);
VAR
	obj: Object;
BEGIN
	obj := graphic.root;
	WHILE obj # NIL DO
		obj.do.handle(obj, message);
		obj := obj.next
	END
END BroadcastAll;

(* Broadcasts the given message to al selected objects in the graphic,
   by calling their message handler.
 *)
PROCEDURE BroadcastSelected*(graphic: Graphic; VAR message: Message);
VAR
	obj: Object;
BEGIN
	obj := graphic.root;
	WHILE obj # NIL DO
		IF obj.selected THEN
			obj.do.handle(obj, message);
		END;
		obj:= obj.next
	END
END BroadcastSelected;

(* Creates a new, empty graphic *)
PROCEDURE NewGraphic*(): Graphic;
VAR
	g: Graphic;
BEGIN
	NEW(g);
	(* empty *)
	g.root := NIL;
	RETURN g
END NewGraphic;

(* Sets the global colour which is assigned to newly created objects *)
PROCEDURE ChangeColor*(newColor: INTEGER);
VAR
BEGIN
	color:= newColor;
END ChangeColor;

BEGIN
	color := 15;
END OliObjects.
