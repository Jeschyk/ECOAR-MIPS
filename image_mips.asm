	.data
fname:	.asciiz	"blank.bmp"	 # input file name
outfn:	.asciiz	"result.bmp"	
imgInf:	.word	512, 512, pImg, 0, 0, 0  #when changing width + height remember to provide proper source file
handle: .word	0
fsize:	.word	0
half: 	.float	0.5
zero: 	.float	0
one:	 	.float	1
# to avoid memory allocation image buffer is defined
# big enough to store 512x512 black&white image
# note that we know exactly the size of the header
# pImage is the first byte of image itself
pFile:	.space	62
pImg:	.space	36000

	.text
main:	
	# open input file for reading
	# the file has to be in current working directory
	# (as recognized by mars simulator)
	la	$a0, fname
	li	$a1, 0
	li	$a2, 0
	li	$v0, 13
	syscall
	# read the whole file at once into pFile buffer
	# (note	the effective size of this buffer)
	move	$a0, $v0
	sw	$a0, handle
	la	$a1, pFile
	la	$a2, 36062
	li	$v0, 14
	syscall
	# store	file size for further use and print it
	move	$a0, $v0
	sw	$a0, fsize
	li	$v0, 1
	syscall
	# close	file
	li	$v0, 16
	syscall

mainLoop:	
	ori	$a0, $zero, 0 #will extend to a full word
	jal	setColor
	#upper left 
	ori	$a0, $zero, 128
	ori	$a1, $zero, 284
	jal	moveTo
	
	ori	$a0, $zero, 33
	ori	$a1, $zero, 353
	jal	lineTo
	 
	ori	$a0, $zero, 128
	ori	$a1, $zero, 480
	jal	lineTo
 	
 	ori	$a0, $zero, 230
	ori	$a1, $zero, 400 
	jal	lineTo
	
	ori	$a0, $zero, 128
	ori	$a1, $zero, 284
	jal	lineTo

	#upper right
	ori	$a0, $zero, 1 
	jal	setColor
	
	ori	$a0, $zero, 384
	ori	$a1, $zero, 284
	jal	moveTo
	
	ori	$a0, $zero, 289
	ori	$a1, $zero, 353
	jal	lineTo
	
	ori	$a0, $zero, 384
	ori	$a1, $zero, 480
	jal	lineTo
	
	ori	$a0, $zero, 486
	ori	$a1, $zero, 400 
	jal	lineTo
	
	ori	$a0, $zero, 384
	ori	$a1, $zero, 284
	jal	lineTo
	
	#lower right
	ori	$a0, $zero, 0 
	jal	setColor
	
	ori	$a0, $zero, 384
	ori	$a1, $zero, 28
	jal	moveTo
	
	ori	$a0, $zero, 289
	ori	$a1, $zero, 97
	jal	lineTo
	
	ori	$a0, $zero, 384
	ori	$a1, $zero, 224
	jal	lineTo
	
	ori	$a0, $zero, 486
	ori	$a1, $zero, 144
	jal	lineTo
	
	ori	$a0, $zero, 384
	ori	$a1, $zero, 28
	jal	lineTo
	
	#lower left
	ori	$a0, $zero, 1 
	jal	setColor
	
	ori	$a0, $zero, 128
	ori	$a1, $zero, 28
	jal	moveTo
	
	ori	$a0, $zero, 33
	ori	$a1, $zero, 97
	jal	lineTo
	
	ori	$a0, $zero, 128
	ori	$a1, $zero, 224
	jal	lineTo
	
	ori	$a0, $zero, 230
	ori	$a1, $zero, 144
	jal	lineTo
	
	ori	$a0, $zero, 128
	ori	$a1, $zero, 28
	jal	lineTo
######################################

closeProgram:
	# open	the result file for writing
	la	$a0, outfn
	li	$a1, 1
	li	$a2, 0
	li	$v0, 13
	syscall
	# print	handle of the file 
	move	$a0, $v0
	sw	$a0, handle
	li	$v0, 1
	syscall
	# save	the file (file size is restored from fsize)
	la	$a1, pFile
	lw	$a2, fsize
	li	$v0, 15
	syscall
	# close	file
	li	$v0, 16
	syscall
		
	li	$v0, 10
	syscall

####################################
# procedures defined here ##########
####################################

#SetColor procedure - sets currently drawn color
# a0 - color
setColor:
	move	$t0, $a0
	sw	$t0, imgInf + 20
	jr	$ra
	
#Move to procedure - sets current x and y drawing coords in ImgInfo structure
# a0 - x
#a1 - y
moveTo:
	move	$t0, $a0
	move	$t1, $a1
	sw	$t0, imgInf + 12
	sw	$t1, imgInf + 16
	jr	$ra

#coordinates are in 1st Cartesian quadrant


### for x86 use differnet bresenham, no flops
#push registers only before loop
# restore at the end
# in x86 can use registers not to impelemnt the additional assembly call for color point
# in x86 implement two funcitons for drawing horizontal and vertical lines and implement drawing diagonal all 3 in probably one asm (differentiate between them)
# in x86 do NOT USE FPU, use normal registers and integer bresenham algorithm


#moved calculating offset to this method so that we save cycles
#pass precalculated offset to colorPoint
#update	x offset when updating x
#update	y offset when updating y
#obtain	new offset before returning to beginning of the loop

#Line	to procedure - draws a line from (cx,cy) to (dx,dy) using Bresenham's algorithm (cur, cur) -> (dest, dest)
# a0, t0- dx
# a1, t1- dy
# t2 - abs(delx)
# t3 - abs(dely)
# t4 - current drawing color
# s0 - cx
# s1 - cy
# s2 - width
# s3 - height
# f0 - abs(delx) in fp0
# f1 - abs(dely) in fp1
# f4 - deltaerror
# f5 - temporary
# t5 - temporary
# t6 - temporary /quotient
# t7 - offset in bytes to add to pImg
# t9 - remainder of division of x/8

lineTo:
	move	$t0, $a0 #dx
	move	$t1, $a1  #dy
	lw	$s2, imgInf # width 
	lw	$s3, imgInf + 4# height 
	lw	$s0, imgInf +12 #cx 
	lw	$s1, imgInf +16 #cy
	lw	$t4, imgInf + 20  #store curent drawing color  
	sub	$t0, $t0, $s0 #store delx = dx - cx (signed)
	sub	$t1, $t1, $s1 #store dely = dy - cy (signed)
	abs	$t2, $t0
	abs	$t3, $t1
	mtc1	$t2, $f0
	mtc1	$t3, $f1
	div.s	$f4, $f1, $f0 #f4 holds result of  division - deltaerror
	l.s	$f5, zero #starting error
	#precalculate base image offset
	addi	$t5, $s2, 7 # s2 not used
	srl	$t5, $t5, 3
	addi	$t5, $t5, 3
	srl	$t5, $t5, 2
	sll	$t5, $t5, 2 #t5 holds how many bytes  to increment  our pImg each time we increase y coord
	#then multiply by our y to get y offset in bytes from pImg
	mul	$t6, $t5, $s1 #bytesPerLine*y
	mfhi	$t7
	add	$t7, $t7, $t6 # t7 holds y offset to add
	#calculate byte offset for x + remainder (x/8 + x%8)
	li	$s2, 8
	div	$s0, $s2 #t2 not used
	mflo	$t6 #quotient
	mfhi	$t9 #remainder
	#set	bitmask for calculated byte
	add	$t7, $t7, $t6 #t7 is our offset from pImg to load from y*h+x/8 #t6 not used
	
	li	$s2, 0 #loop iterator being compared to delx
	# iterate while t2 not equal to abs(delx) = t2
plotLoop:
	bgt	$s2, $t2, plotEnd #if we iterated delx+1  times jump to end
	#calculate current img data offset to be colored
	addiu	$sp, $sp, -24 #preserve old ra and t0-t4
	sw	$ra, 4($sp)
	sw	$t0, 8($sp)
	sw	$t1, 12($sp)
	sw	$t2, 16($sp)
	sw	$t3, 20($sp)
	sw	$t4, 24($sp)
	move	$a0, $t9 #remainder from division by 8
	move	$a1, $t7 # pImg + offset
	move 	$a2, $t4 # current drawing color
	jal	colorPoint 	#call colorPoint(x,y) #with passed precalculated offset in bytes
	lw	$t4, 24($sp)
	lw	$t3, 20($sp)
	lw	$t2, 16($sp)
	lw	$t1, 12($sp)
	lw	$t0, 8($sp)
	lw	$ra, 4($sp)
	addiu	$sp ,$sp, 24 #restore old ra
	
	add.s	$f5, $f5, $f4 # error += deltaerr
	lwc1	$f6, half #load value 0.5 in single precision //mars does not support loading immediate floats
	c.lt.s	$f5, $f6 # will set flag if it is less
	bc1t	updateX #will updateX later anyway
	#either	add or sub to y dependent on deltay sign 
	bltz	$t1,  negativeY #if positive dely then stay here
	add	$t7, $t7, $t5 #add one bytesperline to pImg offset
	addi	$s1, $s1, 1 #add one to ycoord
correctError:
	l.s	$f7, one
	sub.s	$f5, $f5, $f7 # error -= 1
updateX:	
	#updateX dependent on sign
	bltz	$t0, negativeX #if delx negative then go to negativeX
	addi	$t9, $t9, 1  #add one to reminder
	addi	$s0, $s0, 1 #add one to xcoord
	#when updating left/right, substract or add from reminder, if reminder < 0 then substract one from precomputed offset and set reminder to 7, if = 8 then add one to precomp offest and set reminder to 0
	#when updating up/down, add or substract precomputed bytes per line and always update respective registers holding actual x,y values
update:	
	bltz	$t9, backOneByte
	beq	$t9, 0x8, forwardOneByte
updateEnd:
	addi	$s2, $s2, 1	
	j	plotLoop	
	
negativeY:
	sub	$t7, $t7, $t5 #substract one bytesperline from pImg offset
	subi	$s1, $s1, 1 #substract one from ycoord
	j	correctError
negativeX:
	subi	$t9, $t9, 1 #substract one from reminder
	subi	$s0, $s0, 1 #substract one from ycoord
	j	update
backOneByte:
	subi	$t7, $t7, 1
	li	$t9, 7
	j	updateEnd
forwardOneByte:
	addi	$t7, $t7, 1
	li	$t9, 0
	j	updateEnd
	
plotEnd:	#set new coords to memory
 	sw	$s0, imgInf + 12
 	sw	$s1, imgInf + 16
	jr	$ra
	
#implement drawing with different color -> other masking and we are done
# 0 is black, 1 is white
#colorPoint - colors points at coordinates x,y
# a0, t0 - remainder of x%8
# a1, t1 - pImg
# a2, t2 - current color to be painted
# t3 - current byte of pImg +offset
# t4 - mask for shifting
colorPoint:
	move	$t0, $a0 # remainder of x%8
	move	$t1, $a1 # pImg+current offset  in bytes to paint
	move 	$t2, $a2 # current color of painting (black/white)
	lb	$t3, pImg($t1) #load pImg + t9
#always colour currently offset byte, prepare a mask dependent on current color and then reset(set with 0 for black and with 1 for white) the bits we need
	li	$t4, 0x80 # t4 holds mask for shifting 1000 0000 (byte) - black 
	srlv 	$t4, $t4, $t0  #shift right mask remainder times (128 srl rem times) 
	bnez 	$t2,  maskWhite #if quotient == 0 then  it will set it to be 0111 1111
	not	$t4, $t4 #logical NOT
	and	$t3, $t3, $t4 #'set' only that bit in original mask
maskEnd:
	sb	$t3, pImg($t1)
	jr	$ra
	
maskWhite:
	xor 	$t3, $t3, $t4	# only bytes not equal will produce 1 on output, so all set to '0' will be kept
	j 	maskEnd

