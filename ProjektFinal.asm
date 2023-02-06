	.eqv	PRINT_INT, 1
	.eqv	SYS_PRINTSTR, 4
	.eqv	READ_STR, 8
	.eqv	EXIT, 10
	.eqv	PRINT_CHAR, 11
	.eqv	CLOSE_FILE, 57
	.eqv	READ_FILE, 63
	.eqv	OPEN_FILE, 1024
	.eqv	SYS_EXIT_ERR, 93
	
	.eqv	BUFSIZE, 512
	.eqv	ONECOMSIZE, 12
	.eqv	BUFCOMSIZE, 2844
	.eqv	COUNTCOMSIZE, 952
	.eqv	FILENAMESIZE, 40
		.data

oneCom:		.space	ONECOMSIZE
bufCom:		.space	BUFCOMSIZE
count:		.space	COUNTCOMSIZE
buf:		.space	BUFSIZE
prompt:		.asciz	"File name: "
fileName:	.space	FILENAMESIZE

	.text
main:
		la	a0, prompt		# prompt the user
		li	a7, SYS_PRINTSTR
		ecall
		
		la	a0, fileName		# load fileName buffer address
		li	a1, 39			# max number of chracters to read
		li	a7, READ_STR		# ecall for read_string
		ecall
		mv	t0, a0			# load fileName buffer address
clearNewline:
		mv 	t1, t0		
		mv	a0, t1
clearNewlineLoop:
		lbu	t2, (t0)		# load byte from file_name buffer
		addi	t0, t0, 1
		li	a6, '\n'		# increment fileName buffer pointer	
		beq	t2, a6, cleanup		# if char is new line, override it with 0
		sb	t2, (t1)		# return char to memory
		addi	t1, t1, 1		
		j 	clearNewlineLoop
cleanup:		
		sb 	zero, (t1)		# substitue byte with 0	
	
openFile:
#open the file
 	li 	a7, OPEN_FILE 	# system call for file_open
 	la 	a0, fileName 	# address of filename string
 	li 	a1, 0 		# flags: 0-read file
 	ecall 			# file descriptor of opened file in a0
 	
 	li	s1, -1
	beq	a0, s1, exit	
#save the file descriptor
 	mv 	s1, a0

loop:
	jal	getC
	beqz 	a0, fclose 	# branch if no data is read
	li	t4, '#'
	beq	t3, t4, loopSkipL

	li	t5, 11
	li	t4, ' '
	bgtu	t3, t4, checkCom

	j	loop

incres:
	la	t3, bufCom
	la	t1, oneCom
	la	t2, count
	mv	s0, t3
	mv	s8, t1

comp:
	lw	t6, (t2)	# load value of occurrences of the command
	beqz	t6, addCom
	lbu	t6, (t3)	# set t6 value of char from bufCom
	lbu	t5, (t1)	# set t5 value of char from command
	addi	t3, t3, 1
	addi	t1, t1, 1
	bne	t5, t6, nextCom
	beqz	t5, agree
	j	comp

nextCom:
	addi	s0, s0, 12	# move on next command
	addi	t2, t2, 4	# move on next command counter
	mv	t3, s0
	mv	t1, s8
	j	comp
	
addCom:
	lw	t4, 0(t1)	# load first 4 bytes from oneCom to t4
	sw	t4, 0(t3)	# save t4 to first 4 bytes of bufCom
	lw	t4, 4(t1)	# load second 4 bytes from oneCom to t4
	sw	t4, 4(t3)	# save t4 to second 4 bytes of bufCom
	lw	t4, 8(t1)	# load third 4 bytes from oneCom to t4
	sw	t4, 8(t3)	# save t4 to third 4 bytes of bufCom
	
agree:
	lw	t4, (t2)	# load value of occurrences of the command
	addi	t4, t4, 1	# increase value of occurrences of the command
	sw	t4, (t2)	# save value of occurrences of the command	
	
	j	skipL

#close the file
fclose:
	li 	a7, CLOSE_FILE 	# system call for file_close
 	mv 	a0, s1 		# move file descr from s1 to a0
 	ecall
 	
	la	t0, bufCom
	la	t1, count

finloop:
	lw	t5, (t1)
	beq	t5, zero, exit

print:
	mv	a0, t0
	li	a7, SYS_PRINTSTR
	ecall			# print command

	li	a0, ':'
	li	a7, PRINT_CHAR
	ecall			# print ':'

	lw	a0, (t1)
	li	a7, PRINT_INT
	ecall			# print int

	li	a0, '\n'
	li	a7, PRINT_CHAR
	ecall			# print end line

	addi	t0, t0, 12	# move on next command
	addi	t1, t1, 4	# move on next command counter
	
	j	finloop

exit:
	li	a7, EXIT
	ecall

# ============================================================================
load_to_buf:
#description: 
#	save BUFSIZE bytes to buf
#arguments:
#	none
#return value:
#	s2 - number of bytes read
#	t0 - buf pointer
#	t3 - contains letter
	#read data from file
 	li 	a7, READ_FILE 	# system call for file_read
 	mv 	a0, s1 		# move file descr from s1 to a0
 	la 	a1, buf 	# address of data buffer
 	li 	a2, BUFSIZE 	# amount to read (bytes)
 	ecall

 	la	t0, buf

#check how much data was actually read
	mv	s2, a0		# save amount of bytes to read
	addi	s2, s2, -1
	lbu	t3, (t0)
	jr	ra
# ============================================================================
getC:
#description:
#	sets t0 to the next character
#arguments:
#	none
#return value:
#	t0 - buf pointer
#	t3 - contains letter
	beq	s2, zero, load_to_buf	# load to buf if all has been used
	addi	t0, t0, 1		# pointer increment
	addi	s2, s2, -1		# decrementation value of char to get
	lbu	t3, (t0)		# save value of t0 pointer to t3
	jr	ra
# ============================================================================
skipL:
#description: 
#	skip line
#arguments:
#	none
#return value:
#	none
	mv	t3, s3
	li	t4, 0xa
	beq	t3, t4, loop

loopSkipL:
	jal	getC
	beqz 	a0, fclose 	# branch if no data is read
	li	t4, ' '
	bgeu	t3, t4, loopSkipL	# if char >= ' ' skip line
	li	t4, 9
	beq	t3, t4, loopSkipL	# if char = tab skip line
	j	loop

# ============================================================================
checkCom:
#description:
#	hides directives
#arguments:
#	t2 - pointer on first letter of string
#return value:
	la	a4, oneCom
	sw	zero, 0(a4)	# make oneCom empty
	sw	zero, 4(a4)	# make oneCom empty
	sw	zero, 8(a4)	# make oneCom empty

	la	a6, oneCom
checkloop:
	addi	t5, t5, -1
	
	li	t4, ':'
	beq	t3, t4, loop		# if char = : jump loop
	
	sb	t3, (a6)	# load char to oneCom buffer
	addi	a6, a6, 1	# increment oneCom pointer
	
	jal	getC
	beqz 	a0, incres 	# branch if no data is read
	mv	s3, t3
	li	t4, ' '
	bleu	t3, t4, incres		# if char <= ' ' it is command
	beqz	t5, skipL
	j	checkloop
# ============================================================================
