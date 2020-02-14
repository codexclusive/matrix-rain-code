Matrix Rain Code

by Gabor Kotik
GitHub: codexclusive


The program recreates the digital rain effect from the movie The Matrix.

To see how it works, click the following link:

https://youtu.be/_VsX-c4JppE


You can assemble and link the source code by using the Netwide Assembler:

nasm -f bin matrix.asm -o matrix.com


General information
===================

The code uses 16-bit assembly. Under DOS, the programmer has direct access to
the video memory. The area starting at 0B800H:0000H contains eight pages, the
first of which is the actual visible screen. Our screen has 80x25 characters,
two bytes each, which takes up 4000 bytes in memory. The remaining pages are
invisible to the user.

In this program, the second page at 0B800H:0FA0H contains information about
how characters change on the screen. To each character, we assign a cycle length
and a counter. Cycle length indicates how long the character is displayed,
whereas the counter shows how much time is left before the character changes.

The third page in video memory at 0B800H:1F40H is used for keeping track of 
the vertically moving beams. Each beam has a position denoted by an integer.
Position 0 means that the beam has just entered the visible screen from the top.
Position 24 means that the beam is on the bottom of the screen. Beam length
is a contant value of 221 (E7 hex), which means that a beam at position 256
(100 hex) is not visible to the user.

Beam positions vary between 0 and 1023 (3FF hex). When a beam is at position
1024, the value will be reset to zero. Visually, the system can be described
as follows: There is a dynamically changing set of characters on the visible
screen. Characters become visible when a beam is above them, otherwise
their color attributes are 0. Beams move on a cylindrical surface, the size
of which is 1024. Beam sizes being 221, they are visible on the screen
approx. 21.5 % of the time.

