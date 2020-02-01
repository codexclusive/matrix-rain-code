Matrix Rain Code

by Gabor Kotik
GitHub: codexclusive


The program recreates the digital rain effect from the movie The Matrix.

To see how it works, click the following link:

https://youtu.be/_VsX-c4JppE


You can assemble and link the source code by using Turbo Assembler & Turbo Linker:

tasm matrix.asm
tlink /t matrix.obj


General information
===================

The code uses 16-bit assembly. All the data are stored in the video memory.
In the 80x25 text mode, the screen occupies only 4000 bytes in memory, the
remaining seven pages are free to use. The first page at 0B800H:0000h is occupied
by the visible screen. The second page is invisible to the user. This holds
information about the cycle length of each character on the screen (i. e. how long
each character is displayed). The third page in video memory contains information 
about the vertically moving beams: each beam has a position denoted by an integer.
Timing is achieved by the vertical blank technique, which was commonly used with
CRT monitors.

Feel free to contact me for more details.
