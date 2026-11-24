################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Magical Drop.
#
# Student 1: Selim AFFES, 1011314436
# Student 2: Name, Student Number (if applicable)
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    256
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000
    
COLORS:
    # load red, green, blue, yellow in an array
    .word 0xff0000, 0x00ff00, 0x0000ff, 0xffff00
    
##############################################################################
# Mutable Data
##############################################################################
BOARD:
    .word 0:98  # An array of 98 bytes/integers to store the 7x14 board (initialized to 0/empty)
    
CHARA:
    .word 6 # The character/player's x position index
    
HELD:
    .word 0 0x000000 # The bubbles that the player holds: their number and color
    
BOX_OFFSET:
    .word 780 # The byte offset to access the game box (3*4+6*128)

##############################################################################
# Code
##############################################################################
	.text
	.globl main

    # Run the game.
main:
    # Initialize the game
    	# Draw the box rows
	li $t0, 0x808080  # set $t0 as the color grey for the map
	li $t4, 2 # set index for row
	li $t5, 5 # set column for the row
	lw $t2, ADDR_DSPL # load display address
	jal row   # Fill up top row
	li $t4, 2  # set index for row
	li $t5, 20 # set column for row
	jal row   # fill up bottom row
	
	# Draw the box columns
	li $t4, 2 # set row for col
	li $t5, 5 # set index for the col
	jal column  # draw left column
	li $t4, 10 # set row for col
	li $t5, 5 # set index for the col
	jal column  # draw right column
	
	la $t0, BOARD  # Load the board array
	li $t5, 0   # set column index
	# Draw 6 random rows
	jal random_rows
	jal draw_chara
	
	# After finishing setup, go to gameloop
	li $s0, 0 # Initialize the frame counter for time-based elements e.g. new rows
	j game_loop
	

func_return:
	jr $ra           # Returns a function
	

# Fill 6 rows with random bubbles	
random_rows:
	la $t0, BOARD # Load BOARD address just in case
	bgt $t5, 3, func_return # Return if all rows are done
	# otherwise store $ra in the stack & call random_row
	addi $sp, $sp, -4
	sw $ra, 0($sp) # Push the $ra onto the stack
	li $t4, 0   # set row index for random_row
	jal random_row
	lw $ra, 0($sp)
	addi $sp, $sp, 4 # Pop the $ra from the stack
	add $t5, $t5, 1  # increment column index
	j random_rows
	
# Fill a row with random bubbles
random_row:
	bgt $t4, 6, func_return   # Return if row is done (at index > 10)
	li $v0, 42  # Load random generation function
	li $a1, 4   # Load arg for random generation (4 colors)
	la $t7, COLORS # load colors to $t7
	li $a0, 0     # Set seed again (mem changed by result)
	syscall # call random
	mul $t8, $a0, 4 # get index to take the color from array
	add $t8, $t8, $t7 # get color address in $t8
	lw $t8, 0($t8)    # Load color from memory
	
	mul $t6, $t5, 28  # Row memory indexing in BOARD (index*7*4)
	mul $t9, $t4, 4   # column memory indexing in BOARD
	add $t6, $t6, $t9 # Add column indexing in BOARD
	add $t6, $t6, $t0 # Add BOARD address to get final address
	sw $t8, 0($t6)    # Write the cell's color in the board array
	
	add $t4, $t4, 1   # Increment the row index
	j random_row
	
row:
	bgt $t4, 10, func_return   # Return if row is done (at index > 10)
	# Compute the pixel to color in $t6
	mul $t6, $t5, 128   # column coord in $t6
	mul $t7, $t4, 4     # row coord in $t7
	add $t6, $t6, $t7   # add current row coord
	add $t6, $t6, $t2   # add display address
	sw $t0, 0($t6)    # Color in the pixel
	add $t4, $t4, 1   # Increment the row index
	j row


column:
	bgt $t5, 20, func_return   # Return if column is done (at index > 20)	
	# Compute the pixel to color in $t6
	mul $t6, $t5, 128  # column coord in $t6
	mul $t7, $t4, 4    # row coord in $t5
	add $t6, $t6, $t7   # add current row coord
	add $t6, $t6, $t2   # add display address
	
	sw $t0, 0($t6)   # Color in the pixel
	add $t5, $t5, 1   # Increment the row index
	j column
	


move_right:
	lw $t5, CHARA # Load character position
	bgt $t5, 8, game_loop # if character all the way right, don't go right
	jal undraw_chara # Remove character from old position
	lw $t5, CHARA # Load character position again ($t5 used by undraw)
	add $t5, $t5, 1 # Move character 1 unit to the right
	sw $t5, CHARA # Store new character position
	j game_loop # Restart game loop

move_left:
	lw $t5, CHARA
	blt $t5, 4, game_loop # if character all the way left, don't go left
	jal undraw_chara # Remove character from old position
	lw $t5, CHARA # Load character position again ($t5 used by undraw)
	sub $t5, $t5, 1 # Move character 1 unit to the left
	sw $t5, CHARA # Store new character position
	j game_loop # Restart game loop

# Draw the character
draw_chara:
	lw $t4, CHARA # Character x index position
	mul $t5, $t4, 4  # Get horizontal pixel position
	add $t5, $t5, 2688  # Add columns to the position
	lw $t2, ADDR_DSPL
	add $t5, $t5, $t2  # Add display address
	li $t6, 0xffffff # character color: white pixel
	
	sw $t6, 0($t5) # draw it
	jr $ra # return func
	

# Undraw the character (use old pos)
undraw_chara:
	lw $t4, CHARA # Character x index position
	mul $t5, $t4, 4  # Get horizontal pixel position
	add $t5, $t5, 2688  # Add columns to the position
	lw $t2, ADDR_DSPL
	add $t5, $t5, $t2  # Add display address
	li $t6, 0x000000 # background color: black pixel
	
	sw $t6, 0($t5) # draw it
	jr $ra # return func



grab_bubbles:
	la $t0, BOARD  # Load BOARD into $t0 just in case
	lw $t4, CHARA  # $t4 takes the character's position
	sub $t4,$t4, 3 # $t4 is now the column we look at (index in the BOARD)
	li $t5, 13     # $t5 is the row we look at (BOARD index). Starts at the bottom
	j grab_bubbles_loop # A loop to grab all the bottom bubbles (with same color)
	# This loop always goes back to the game loop upon ending


grab_bubbles_loop:
	blt $t5, 0, game_loop # If at the top, stop the loop
	mul $t6, $t5, 7 # Start finding index by multiplying rows
	add $t6, $t6, $t4 # Find index of this "bubble" (or empty spot)
	mul $t6, $t6, 4   # Find the offset by multiplying by 4 (memory of an integer)
	add $t6, $t6, $t0 # The address of the bubble (add BOARD address)
	lw $t6, 0($t6) # Get the actual value of the bubble
	beq $t6, 0x000000, grab_bubbles_loop_incr # If it's empty, increment & go back to start of loop
	jal grab_bubble # Otherwise try to grab the bubble


grab_bubbles_loop_incr:
	move $a0, $t4 # The row of the color as argument
	move $a1, $t5 # The column of the color as argument
	sub $t5, $t5, 1 # decrement the row index
	j grab_bubbles_loop # go back to start of loop


grab_bubble_diff_col:
	la $t9, HELD # Load into $t6 the address of the number of held bubbles
	lw $t9, 0($t9)   # Get the actual number of held bubbles
	bne $t9, 0, game_loop # If the colors are different, and a bubble is already held, end the loop
	li $t9, 1 # Else hold this one bubble
	sw $t9, HELD # And store the number of held bubbles
	sw $t6, HELD+4 # And store the new color of held bubbles
	move $a0, $t4 # The row of the color as argument
	move $a1, $t5 # The column of the color as argument
	
	j undraw_bubble # Undraw the bubble on the board

grab_bubble:
	lw $t7 HELD+4 # Load into $t7 the color of held bubbles
	bne $t7, $t6, grab_bubble_diff_col # If the bubble is a different color (can hold if 0 held)
	# Otherwise (if it's the same color), increment number of held bubbles and uncolor it
	la $t6, HELD # Load into $t6 the address of the number of held bubbles
	lw $t6, 0($t6)   # Get the actual number of held bubbles
	add $t6, $t6, 1  # Increment number of held bubbles
	sw $t6, HELD     # And store the number of held bubbles
	move $a0, $t4    # The column of the color as argument
	move $a1, $t5    # The row of the color as argument
	j undraw_bubble  # Undraw the bubble on the board
	
	
	
undraw_bubble:
	# Get the full screen column for the bubble into $t8
	add $t8, $a0, 3
	mul $t8, $t8, 4   # Multiply to get memory offset
	# Get the full screen row for the bubble into $t9
	add $t9, $a1, 6
	mul $t9, $t9, 128 # Multiply to get memory offset
	add $t8, $t8, $t9 # Get full offset in the screen
	add $t8, $t8, $t2 # Get full address
	li $t6, 0x000000 # background color: black pixel
	sw $t6, 0($t8)
	
	mul $t8, $a1, 28  # Get memory offset for row
	mul $t9, $a0, 4   # Get memory offset for column
	add $t8, $t8, $t9 # Add up the offsets
	add $t8, $t8, $t0 # Get full address
	li $t6, 0x000000  # Empty the slot
	sw $t6, 0($t8)    # Empty the slot
	
	j grab_bubbles_loop_incr
	
	

draw_board:
	la $t0, BOARD # load the board in $t0
	addi $sp, $sp, -4
	sw $ra, 0($sp) # Push the $ra onto the stack
	jal undraw_chara # Remove character from old position
	jal draw_chara
	lw $ra, 0($sp)
	addi $sp, $sp, 4 # Pop the $ra from the stack
	lw $t3, BOX_OFFSET # Load the box offset position
	li $t4, 0     # The row counter $t4 starts at 0
	li $t5, 0     # The column counter $t5 starts at 0
	j draw_board_loop
	
draw_board_loop:
	bgt $t4, 13, func_return # If arrived at board end, return to game loop
	bgt $t5, 6, incr_row     # If at end of a row, go to next row
	mul $t6, $t4, 7          # $t6 contains board index for this row
	add $t6, $t6, $t5        # Add the rows to get the index of this cell
	mul $t6, $t6, 4          # Multiply by 4 to account for the size of an integer
	add $t7, $t6, $t0        # $t7 contains the location of the cell's color
	lw $t7, 0($t7)           # $t7 contains the cell's color
	
	mul $t6, $t4, 32         # $t6 contains display index for this row
	add $t6, $t6, $t5        # Add column box index
	mul $t6, $t6, 4          # Multiply by 4 to account for the size of an integer
	add $t6, $t6, $t3        # Add the box offset to get the display index
	add $t6, $t6, $t2        # Add the DISPLAY ADDRESS memloc to get the display cell's memory address
	sw $t7, ($t6)            # Color the pixel
	add $t5, $t5, 1
	j draw_board_loop
	
	
incr_row:
	li $t5, 0        # Get back to start of row
	add $t4, $t4, 1  # Go to next row
	j draw_board_loop
	
	
add_row:
	la $t0, BOARD
	addi $sp, $sp, -4
	sw $ra, 0($sp) # Push the $ra onto the stack
	jal game_over_check # Check for game over by looking at last row
	lw $ra, 0($sp)
	addi $sp, $sp, 4 # Pop the $ra from the stack
	
	li $t4, 90 # The last cell of the second to last row
	j shift_loop
	
# This loop starts from bottom to top and shifts each cell 1 pixel down
shift_loop:
	blt $t4, 0, new_row # If we checked all the cells (bottom to top/last to first), add top row, 
	mul $t5, $t4, 4     # Get the memloc of the cell
	add $t5, $t5, $t0   # Add board address to get cell address
	lw $t6, ($t5)       # Get the contents of the cell
	add $t5, $t5, 28    # Get the memloc of the cell below
	sw $t6, ($t5)       # Put contents of the cell in the cell below
	sub $t4, $t4, 1     # Decrement the counter
	j shift_loop

new_row:
	li $t5, 0
	li $t4, 0
	addi $sp, $sp, -4
	sw $ra, 0($sp) # Push the $ra onto the stack
	jal random_row # Check for game over by looking at last row
	lw $ra, 0($sp)
	addi $sp, $sp, 4 # Pop the $ra from the stack
	jr $ra

throw_bubbles:
	la $t0, BOARD  # Load board
	lw $t3, CHARA  # Load character position
	lw $t4, HELD   # Load number of bubbles held
	lw $t5, HELD+4 # Load color of bubbles held
	beq $t4, 0, func_return # If no bubbles are held, don't throw anything, don't check for matches
	sw $zero, HELD
	# Setup the loop by finding the column in $t6 and starting at the bottom
	add $t6, $t3, 88 # Get the board index of the cell right above the character (91 for last row, -3 for character's visual offset)
	mul $t6, $t6, 4  # Take into account integer memsize
	add $t6, $t6, $t0 # Add board address to get full address
	j find_floor_loop
	

find_floor_loop:
	blt $t6, 0, place_bubbles # If you get to the top, place the bubbles
	lw $t7, ($t6) # Get the color of the bubble in this slot
	bne $t7, 0x000000, place_bubbles # If there is a bubble, place the bubbles under it
	sub $t6, $t6, 28 # Else go to the next row (above, so 7*4 indices less)
	j find_floor_loop # continue loop
	
	
place_bubbles:
	blt $t4, 1, check_match # If the player isn't holding any bubbles, go back to game loop
	add $t6, $t6, 28 # We enter this function when on a bubble, so go under it
	sw $t5, ($t6) # Add the bubble in that cell
	sub $t4, $t4, 1 # Subtract one bubble from the held ones
	j place_bubbles

# check if there is a match after throwing. Starts off with $t6 the memory address of the bottom-most bubble & $t5 the color
check_match:
	li $t7, 1 # Initialize the bubble counter, counting the bottom-most thrown bubble
	sub $t8, $t6, 28 # Go up one row. Use $t8 to preserve $t6 for later
	j check_match_loop # Go in a loop  checking whether there is a match
	
check_match_loop:
	blt $t8, $t0, func_return # If out of the board, there is no match. Return to game loop
	bgt $t7, 2, execute_match # If there are at least three bubbles aligned vertically, execute the match
	lw $t9, ($t8) # Get the color of currently checked cell
	bne $t9, $t5, func_return # If the color is different and we're not yet at 3 stacked bubbles, there is no match
	sub $t8, $t8, 28 # Otherwise, go to the bubble above to check it
	add $t7, $t7, 1  # And increment the bubble counter for this match
	j check_match_loop
	
# Draw the board and wait a bit to show the bubbles that will explode. This doesn't count for line advancement (don't penalize player for a line)
impact_frames:
	addi $sp, $sp, -4
	sw $ra, 0($sp) # Push the $ra onto the stack
	jal draw_board # Draw the board to show the recently thrown bubbles
	lw $ra, 0($sp)
	addi $sp, $sp, 4 # Pop the $ra from the stack
	# Wait 5 frames
	li $v0, 32
	li $a0, 180
	syscall
	jr $ra

# Having found a match whose bottom-most bubble is at $t6 with color $t5, remove all bubbles in the match (no flood fill or combos)
execute_match:
	addi $sp, $sp, -12
	sw $ra, 0($sp)   # save return address
	sw $t5, 4($sp)   # save match color
	sw $t6, 8($sp)   # save bottom-most bubble address
	jal impact_frames # Show impact frames, showing the bubbles before destroying them
	lw $ra, 0($sp)   # Restore return address
	lw $t5, 4($sp)   # restore match color
	lw $t6, 8($sp)   # restore bubble address
	addi $sp, $sp, 12
	j execute_match_loop
	
execute_match_loop:
	blt $t6, $t0, func_return # If out of the board, the match is finished. Return to game loop
	lw $t8, ($t6) # Get the color of currently checked cell
	bne $t8, $t5, func_return # If the color is different, the match is finished, return to game loop
	li $t9, 0x000000 # $t9 is the empty color
	sw $t9, ($t6)    # Empty the cell
	sub $t6, $t6, 28  # Go to the cell above (up one row)
	j execute_match_loop
	

#checks the keyboard input
keyboard_input:
	lw $a0, 4($t1)                  # Load second word from keyboard
	beq $a0, 0x71, quit             # Check if the key q was pressed (quit game)
    	beq $a0, 0x61, move_left        # Check if the key a was pressed (move left)
    	beq $a0, 0x64, move_right       # Check if the key d was pressed (move right)
    	beq $a0, 0x73, grab_bubbles     # Check if the key s was pressed (grab)
    	beq $a0, 0x77, throw_bubbles    # Check if the key w was pressed (throw)
    	j draw_screen
    	

game_loop:
	la $t0, BOARD
	lw $t1, ADDR_KBRD
	lw $t2, ADDR_DSPL
	
    # 1a. Check if key has been pressed
    	lw $t8, 0($t1)                  # Load first word from keyboard
    	beq $t8, 1, keyboard_input      # If first word 1, key is pressed (# 1b. Check which key has been pressed)
    
    # 2a. Check for collisions
    	jal game_over_check # Every frame, check for game over
	# 2b. Update locations (capsules)
	# 3. Draw the screen
draw_screen:
	jal draw_board
	
	# 4. Sleep
	addi $s0, $s0, 1              # count this frame
	blt  $s0, 75, no_advance
	li   $s0, 0                   # reset counter
	jal  add_row                  # push the lines down
	
no_advance:
	# Wait a frame
	li $v0, 32
	li $a0, 16
	syscall
	
    # 5. Go back to Step 1
    j game_loop


game_over_check:
	la $t0, BOARD
	li $t4, 91 # The first cell of the last row

game_over_check_loop:
	bgt $t4, 97, func_return # Look at the whole last row
	mul $t5, $t4, 4 # Get the BOARD index
	add $t5, $t5, $t0 # add BOARD address to get full cell address
	lw $t5, ($t5) # Get the actual value
	bne $t5, 0x000000, game_over # If the cell isn't empty, game over
	add $t4, $t4, 1 # Else increment index and continue check
	j game_over_check_loop
	

# Game over!!
game_over:
	j quit
	

quit:
	li $v0, 10                      # Quit gracefully
	syscall
