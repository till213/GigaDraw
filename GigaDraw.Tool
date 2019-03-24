GigaDraw
_______________________________________
Compiler.Compile OliObjects.Mod FortiFrames.Mod GigaDraw.Mod GDLines.Mod GDCaptions.Mod GDPacMan.Mod Random.Mod GDPacCmd.Mod GDgLines.Mod GDCircles.Mod~
System.Free Circles gLines PacCmd PacMan Random  Lines Captions GigaDraw FortiFrames OliObjects ~

Browser.ShowDef ^

Edit.Open OliObjects.Mod 				Edit.Open GDPacMan.Mod
Edit.Open FortiFrames.Mod				Edit.Open GDPacCmd.Mod
Edit.Open GigaDraw.Mod					 Edit.Open GDgLines.Mod			
Edit.Open GDLines.Mod						Edit.Open GDCircles.Mod
Edit.Open GDCaptions.Mod

GigaDraw.Open test3
GigaDraw.ChangeColor ^ 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15

Lines.MakeLine
gLines.MakegLine
Captions.MakeCaption
Circles.MakeCircle

PacMan.MakePacMan
PacCmd.Start
PacCmd.PacAttack
PacCmd.WritePacFile

DOSDisk Tool
_______________________

DosDisk.WriteFiles GigaDraw.Tool OliObjects.Mod FortiFrames.Mod GigaDraw.Mod GDLines.Mod GDCaptions.Mod GDPacMan.Mod GDPacCmd.Mod GDgLines.Mod Random.Mod~
DosDisk.ReadFiles ^ 
DosDisk.WriteFiles ^

Edit.Open ^
a:\OliObjects.Mod a:\FortiFrames.Mod a:\GigaDraw.Mod a:\GDLines.Mod a:\GDCaptions.Mod a:\GDPacMan.Mod a:\GDPacCmd.Mod a:\GDgLines.Mod a:\Random.Mod

FontTool
______________

Net.ReceiveFiles Pluto Syndor24b.Scn.Fnt~
Edit.ChangeFont ^

NetTool
______________
Net.ReceiveFiles Pluto OberonErrors.Text

DosDisk.ReadTextFiles pacman.res~