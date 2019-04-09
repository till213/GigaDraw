GigaDraw.Tool
_________________________

# GigaDraw base modules
ORP.Compile OliObjects.Mod/s FortiFrames.Mod/s GigaDraw.Mod/s 
Random.Mod/s~

# GigaDraw objects
ORP.Compile GDLines.Mod GDCaptions.Mod GDPacMan.Mod/s
GDPacCmd.Mod/s GDCircles.Mod GDgLines.Mod/s~

# System
System.Free Circles gLines PacCmd PacMan Random
Lines Captions GigaDraw FortiFrames OliObjects~

# Source editing
Edit.Open OliObjects.Mod    Edit.Open GDCaptions.Mod
Edit.Open FortiFrames.Mod   Edit.Open GDPacMan.Mod
Edit.Open Random.Mod        Edit.Open GDPacCmd.Mod
Edit.Open GigaDraw.Mod     Edit.Open GDgLines.Mod			
Edit.Open GDLines.Mod        Edit.Open GDCircles.Mod
   
# Create new drawing, change colour (where available)
GigaDraw.Open GigaDemo
GigaDraw.ChangeColor ^ 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15

# Draw commands
Lines.MakeLine
gLines.MakegLine
Captions.MakeCaption
Circles.MakeCircle

PacMan.MakePacMan
PacCmd.Start
PacCmd.PacAttack

