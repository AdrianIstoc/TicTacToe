include win64.inc	; biblioteca cu structuri si functii Win x64
option win64:7
option win64:0111b
option literals:on
option SWITCHSTYLE: ASMSTYLE

ENABLE_EXTENDED_FLAGS EQU 0x0080

PrintTable proto 
UpdateGame proto :BYTE, :BYTE, :BYTE
ResetGame proto :ptr BYTE, :ptr BYTE, :WORD
EndTurn proto 
MoveUp proto :ptr WORD, :ptr BYTE
MoveDown proto :ptr WORD, :ptr BYTE
MoveLeft proto :ptr WORD, :ptr BYTE
MoveRight proto :ptr WORD, :ptr BYTE
ActionUpdate proto :ptr WORD, :ptr BYTE, :ptr BYTE, :ptr BYTE, :ptr BYTE, :BYTE, :BYTE, :WORD, :BYTE, :WORD
GameWon proto :ptr WORD
ClearScreen proto :WORD
OpenGame proto :ptr BYTE, :BYTE, :WORD
StartMenu proto :ptr BYTE, :ptr BYTE, :ptr BYTE, :WORD, :WORD
OptionScreen proto :BYTE, :WORD
UpdateOption proto :ptr BYTE, :ptr BYTE, :WORD, :WORD
ThemeScreen proto :BYTE, :WORD
UpdateTheme proto :ptr BYTE, :ptr BYTE, :ptr WORD, :ptr WORD, :WORD
CustomScreen proto :ptr WORD, :BYTE, :WORD
UpdateCustom proto :ptr BYTE, :ptr BYTE, :ptr WORD, :ptr WORD, :WORD
PlayersScreen proto :ptr BYTE, :BYTE, :WORD
UpdatePlayers proto :ptr BYTE, :ptr BYTE, :ptr BYTE, :ptr BYTE, :ptr BYTE, :WORD, :WORD

.data	; segmentul de date (variabile)
	hStdOut HANDLE ?			; Standard Output Handle
	hStdIn HANDLE ?				; Standard Input Handle
	lpBuffer INPUT_RECORD <>
	lpRead DWORD ?
	lpMode DWORD ?
	lpCursor CONSOLE_CURSOR_INFO <>
	game BYTE 0 ;jocul a inceput deja
	chenar WORD "   ", 179, "   ", 179, "   ~", 196, 196, 196, 197, 196, 196, 196, 197, 196, 196, 196, "~   ", 179, "   ", 179, "   ~", 196, 196, 196, 197, 196, 196, 196, 197, 196, 196, 196, "~   ", 179, "   ", 179, "   ", 0
	poz BYTE 29 ;pozitia jucatorului
	turn BYTE 0 
	gg BYTE 0 ;jocul are o concluzie (win/draw)
	gamepage BYTE 0 ;pagina meniului
	ypoz BYTE 0 ;pozitia cursorului in meniu
	theme WORD 0x0FF0 
	pallet WORD 0x0FF0, 0xF00F, 0xECCE, 0xCEEC, 0x9BB9, 0xE00E, 0x4994, 0x7887, 0x4FF4, 0xF44F, 0x2CC2, 0xD44D, 0x0110, 0
	niu BYTE " = " ;caracterul nu se schimba
	players BYTE " X  O  !  ?  ", 173, "  ", 168, "  #  %  &  ", 36, "  ", 156, "  ", 157, "  @  A  S  S  7  ", 146, "  ", 153, "  ", 154, "  ", 176, "  ", 193, "  ", 224, "  ", 225, "  ", 227, "  ", 228, "  ", 232, "  ", 234, "  ", 236, "  ", 244, "  ", 245, "  ", 247, "  ", 251, "  ", 254, "  <3 :) :( :3 xo :P :></3>:(WTFLOL", 0
			BYTE 1, 4, 0
	player1 BYTE 1
	player2 BYTE 4
.code	; Sergmentul de cod (program)

  main proc uses rbx	; functia principala "main" 
	 mov hStdOut, GetStdHandle(STD_OUTPUT_HANDLE)
	.if (hStdOut == INVALID_HANDLE_VALUE)
		puts("Error reading Standard Output Handle")
		exit(-1)
	.endif
	mov hStdIn, GetStdHandle(STD_INPUT_HANDLE)
	.if (hStdIn == INVALID_HANDLE_VALUE)
		puts("Error reading Standard Input Handle")
		exit(-1)
	.endif

	; Pentru activare eveminentele mouse-ului pentru consola curenta
	GetConsoleMode(hStdIn, &lpMode)
	and lpMode, NOT ENABLE_QUICK_EDIT_MODE	; dezactivare Quick Edit Mode
	or  lpMode, ENABLE_EXTENDED_FLAGS
	or  lpMode, ENABLE_MOUSE_INPUT			; activare mouse mode
	SetConsoleMode(hStdIn, lpMode)


	GetConsoleCursorInfo(hStdOut, &lpCursor)
	and lpCursor.CONSOLE_CURSOR_INFO.bVisible, 0
	SetConsoleCursorInfo(hStdOut, &lpCursor)

	UpdateGame(poz, '~', 1)
	.repeat
		ReadConsoleInput(hStdIn, &lpBuffer, 1, &lpRead)
		.if lpBuffer.EventType == MOUSE_EVENT
			; lpBuffer.MouseEvent.dwButtonState returneaza starea butoanelor mouse-ului
			;    bitul 0 cel mai nesemnifivativ = starea (1/0 = apasat/neapasat) butonului stanga
			;    bitul 2 = starea butonului dreapta (1/0 = apasat/neapasat)
			;    bitul 1 = starea butonului din mijloc (rotita) (1/0 = apasat/neapasat)
 			.if lpBuffer.MouseEvent.dwEventFlags == MOUSE_MOVED ; ; Mouse Move Event
				; lpBuffer.MouseEvent.dwMousePosition = coordonata mouse (COORD)
				; lpBuffer.MouseEvent.dwMousePosition.X = coordonata X
				; lpBuffer.MouseEvent.dwMousePosition.Y = coordonata Y
			.endif
		.endif
		.if (lpBuffer.EventType == KEY_EVENT) && (lpBuffer.KeyEvent.bKeyDown == 1)
		;  lpBuffer.KeyEvent.bKeyDown == 1  => eveniment apsare tasta
		;  lpBuffer.KeyEvent.bKeyDown == 0  => eveniment eliberare tasta
				; lpBuffer.KeyEvent.uChar.AsciiChar		; cod ASCII (BYTE)
				; ppBuffer.KeyEvent.wVirtualKeyCode		; virtual key (WORD)

			mov bx, lpBuffer.KeyEvent.wVirtualKeyCode
			.if gamepage == 0
				StartMenu(addr ypoz, addr gamepage, addr game, bx, theme)
			.elseif gamepage == 1
				ActionUpdate(addr chenar, addr poz, addr turn, addr gamepage, addr players, player1, player2, bx, gg, theme)
			.elseif gamepage == 2
				UpdateOption(addr ypoz, addr gamepage, bx, theme)
			.elseif gamepage == 4
				UpdateTheme(addr ypoz, addr gamepage, addr theme, addr pallet, bx)
			.elseif gamepage == 5
				UpdateCustom(addr ypoz, addr gamepage, addr theme, addr pallet, bx)
			.elseif gamepage == 6
				UpdatePlayers(addr ypoz, addr gamepage, addr players, addr player1, addr player2, bx, theme)
			.endif

		.endif
		.if gamepage == 0
			OpenGame(addr game, ypoz, theme)
		.elseif gamepage == 1
			PrintTable()
			mov rax, GameWon(addr chenar)
			mov gg, al
		.elseif gamepage == 2
			OptionScreen(ypoz, theme)
		.elseif gamepage == 4
			ThemeScreen(ypoz, theme)
		.elseif gamepage == 5
			CustomScreen(addr pallet, ypoz, theme)
		.elseif gamepage == 6
			PlayersScreen(addr players, ypoz, theme)
		.endif
	.until gamepage == 3
	ClearScreen(0x0F)
	SetConsoleTextAttribute(hStdOut, 0x0F)

	exit(0)	; parasirea programului
	ret
  main endp	; sfarsitul functiei main

  PrintTable proc uses rbx r12 r13
	;afisam starea jocului
	xor rbx, rbx
	SetConsoleCursorPosition(hStdOut, 0x00000000)
	xor r12, r12
	mov r12d, 0x00010000
	xor r13, r13
	lea r13, chenar
	.while byte ptr [r13] != 0
		.if byte ptr [r13] == '~'
			SetConsoleCursorPosition(hStdOut, r12d)
			shr r12d, 16
			inc r12b
			shl r12d, 16
			inc r13
			inc r13
		.endif
		mov bx, word ptr [r13]
		mov ax, theme
		;verificam daca cursorul se afla la acest caracter
		.if bh == 1
			SetConsoleTextAttribute(hStdOut, al)
		.else
			SetConsoleTextAttribute(hStdOut, ah)
		.endif
		printf("%c", byte ptr [r13])
		inc r13
		inc r13
	.endw
	mov ax, theme
	SetConsoleTextAttribute(hStdOut, ah)

	;afisam tura
	SetConsoleCursorPosition(hStdOut, 0x00060000)
	lea rbx, players
	printf("Turn: ")
	.if turn == 0
		movzx r12, player1
		.if byte ptr [rbx+r12-1] != ' '
			putchar([rbx+r12-1])
		.endif
		putchar([rbx+r12])
		putchar([rbx+r12+1])
	.elseif turn == 1
		movzx r12, player2
		.if byte ptr [rbx+r12-1] != ' '
			putchar([rbx+r12-1])
		.endif
		putchar([rbx+r12])
		putchar([rbx+r12+1])
	.endif
	printf(" ")

	;afisam controalele
	SetConsoleCursorPosition(hStdOut, 0x00000020)
	printf("Move - Arrow Keys")
	SetConsoleCursorPosition(hStdOut, 0x00010020)
	movzx r12, player1
	.if byte ptr [rbx+r12-1] != ' '
		putchar([rbx+r12-1])
	.endif
	putchar([rbx+r12])
	.if byte ptr [rbx+r12-1] != ' '
		putchar([rbx+r12+1])
	.endif
	printf(" / ")
	movzx r12, player2
	.if byte ptr [rbx+r12-1] != ' '
		putchar([rbx+r12-1])
	.endif
	putchar([rbx+r12])
	.if byte ptr [rbx+r12-1] != ' '
		putchar([rbx+r12+1])
	.endif
	printf(" - SpaceBar")
	SetConsoleCursorPosition(hStdOut, 0x00020020)
	printf("Restart - BackSpace")
	SetConsoleCursorPosition(hStdOut, 0x00030020)
	printf("Menu - Escape")

 	ret
  PrintTable endp

  UpdateGame proc pos:BYTE, chr:BYTE, hl:BYTE
	lea rax, chenar
	xor rcx, rcx
	xor rdx, rdx
	mov dl, pos
	.while cl != dl ;ne pozitionam pe chenar la pozitia data
		inc rax
		inc rax
		inc rcx
	.endw
	mov cx, word ptr [rax]
	xor r8, r8
	mov r8b, chr
	.if r8b == '~' ;caracterul nu se schimba
		mov r8b, cl
		jmp continueUpdate
	.elseif r8b != ' ' && cl == ' ' 
		jmp continueUpdate
	.elseif r8b == ' '
		jmp continueUpdate
	.else 
		xor rax, rax ;daca 0 atucni nu schimbam tura
		jmp endUpdate
	.endif
 continueUpdate:
	mov cl, hl
	shl rcx, 8
	mov cl, r8b
	mov [rax], cx
	xor rax, rax
	inc rax
 endUpdate:

	ret
  UpdateGame endp

  ResetGame proc poss:ptr BYTE, trnn:ptr BYTE, th:WORD
	ClearScreen(th)
	xor rax, rax
	mov rax, trnn
	mov byte ptr [rax], 0
	mov rax, poss
	mov byte ptr [rax], 29
	UpdateGame(0, ' ', 0)
	UpdateGame(1, ' ', 0)
	UpdateGame(2, ' ', 0)

	UpdateGame(4, ' ', 0)
	UpdateGame(5, ' ', 0)
	UpdateGame(6, ' ', 0)

	UpdateGame(8, ' ', 0)
	UpdateGame(9, ' ', 0)
	UpdateGame(10, ' ', 0)

	UpdateGame(24, ' ', 0)
	UpdateGame(25, ' ', 0)
	UpdateGame(26, ' ', 0)

	UpdateGame(28, ' ', 0)
	UpdateGame(29, ' ', 1)
	UpdateGame(30, ' ', 0)

	UpdateGame(32, ' ', 0)
	UpdateGame(33, ' ', 0)
	UpdateGame(34, ' ', 0)

	UpdateGame(48, ' ', 0)
	UpdateGame(49, ' ', 0)
	UpdateGame(50, ' ', 0)

	UpdateGame(52, ' ', 0)
	UpdateGame(53, ' ', 0)
	UpdateGame(54, ' ', 0)

	UpdateGame(56, ' ', 0)
	UpdateGame(57, ' ', 0)
	UpdateGame(58, ' ', 0)

	ret
  ResetGame endp

  EndTurn proc uses rbx r12 r13
	lea rbx, players
	.switch turn
		.case 0
			movzx r12, player1
			mov rax, UpdateGame(poz, [rbx+r12], 1)
			.if rax == 1
				mov r13b, poz
				dec r13b
				.if [rbx+r12-1] != ' '
					UpdateGame(r13b, [rbx+r12-1], 1)
				.endif
				inc r13b
				inc r13b
				.if [rbx+r12+1] != ' '
					UpdateGame(r13b, [rbx+r12+1], 1)
				.endif
				mov turn, 1
			.endif
		.case 1
			movzx r12, player2
			mov rax, UpdateGame(poz, [rbx+r12], 1)
			.if rax == 1
				mov r13b, poz
				dec r13b
				.if [rbx+r12-1] != ' '
					UpdateGame(r13b, [rbx+r12-1], 1)
				.endif
				inc r13b
				inc r13b
				.if [rbx+r12-1] != ' '
					UpdateGame(r13b, [rbx+r12+1], 1)
				.endif
				mov turn, 0
			.endif
		.default
	.endsw
	
	ret
  EndTurn endp

  MoveUp proc tabb:ptr WORD, poss:ptr BYTE
	xor rax, rax
	mov rax, poss
	.if byte ptr [rax] > 24
		UpdateGame([rax], '~', 0)
		xor rax, rax
		mov rax, poss
		xor rcx, rcx
		mov cl, [rax]
		sub cl, 24
		mov [rax], cl
		UpdateGame([rax], '~', 1)
	.endif
	
	ret
  MoveUp endp

  MoveDown proc tabb:ptr WORD, poss:ptr BYTE
	xor rax, rax
	mov rax, poss
	.if byte ptr [rax] < 34
		UpdateGame([rax], '~', 0)
		xor rax, rax
		mov rax, poss
		xor rcx, rcx
		mov cl, [rax]
		add cl, 24
		mov [rax], cl
		UpdateGame([rax], '~', 1)
	.endif

	ret
  MoveDown endp

  MoveLeft proc tabb:ptr WORD, poss:ptr BYTE
	xor rax, rax
	mov rax, poss
	.if byte ptr [rax] > 4 && byte ptr [rax] < 10
		jmp continueMoveLeft
	.elseif byte ptr [rax] > 28 && byte ptr [rax] < 34
		jmp continueMoveLeft
	.elseif byte ptr [rax] > 52 && byte ptr [rax] < 58
		jmp continueMoveLeft
	.else
		jmp endMoveLeft
	.endif
 continueMoveLeft:
	UpdateGame([rax], '~', 0)
	xor rax, rax
	mov rax, poss
	xor rcx, rcx
	mov cl, [rax]
	sub cl, 4
	mov [rax], cl
	UpdateGame([rax], '~', 1)
 endMoveLeft:

	ret
  MoveLeft endp

  MoveRight proc tabb:ptr WORD, poss:ptr BYTE
  xor rax, rax
	mov rax, poss
	.if byte ptr [rax] > 48 && byte ptr [rax] < 54
		jmp continueMoveRight
	.elseif byte ptr [rax] > 24 && byte ptr [rax] < 30
		jmp continueMoveRight
	.elseif byte ptr [rax] > 0 && byte ptr [rax] < 6
		jmp continueMoveRight
	.else
		jmp endMoveRight
	.endif
 continueMoveRight:
	UpdateGame([rax], '~', 0)
	xor rax, rax
	mov rax, poss
	xor rcx, rcx
	mov cl, [rax]
	add cl, 4
	mov [rax], cl
	UpdateGame([rax], '~', 1)
 endMoveRight:

	ret
  MoveRight endp

  ActionUpdate proc tab:ptr WORD, pos:ptr BYTE, trn:ptr BYTE, gp:ptr BYTE, p0:ptr BYTE, p1:BYTE, p2:BYTE, op:WORD, _gg:BYTE, th:WORD
	.switch op
		.case VK_ESCAPE
			mov rax, gp
			mov byte ptr [rax], 0
			ClearScreen(th)
		.case VK_BACK
			ResetGame(pos, trn, th)
			;printf("back")
		.case VK_SPACE
			.if _gg == 0
				xor rax, rax
				mov rax, pos
				EndTurn()
			.endif
			;printf("space ")
		.case VK_UP
			.if _gg == 0
				MoveUp(tab, pos)
			.endif
			;printf("up ")
		.case VK_DOWN
			.if _gg == 0
				MoveDown(tab, pos)
			.endif
			;printf("down ")
		.case VK_LEFT
			.if _gg == 0
				MoveLeft(tab, pos)
			.endif
			;printf("left ")
		.case VK_RIGHT
			.if _gg == 0
				MoveRight(tab, pos)
			.endif
			;printf("right ")
		.default
			;printf("A! ")
	.endsw

	ret
  ActionUpdate endp

  GameWon proc tab:ptr WORD
	xor rax, rax
	mov rax, tab
	xor rcx, rcx
	mov cl, [rax+2]
	.if cl != ' '
		.if cl == [rax+10] && cl == [rax+18]
			jmp winGame
		.elseif cl == [rax+58] && cl == [rax+114]
			jmp winGame
		.elseif cl == [rax+50] && cl == [rax+98]
			jmp winGame
		.endif
	.endif
	mov cl, [rax+10]
	.if cl != ' '
		.if cl == [rax+58] && cl == [rax+106]
			jmp winGame
		.endif
	.endif
	mov cl, [rax+18]
	.if cl != ' '
		.if cl == [rax+66] && cl == [rax+114]
			jmp winGame
		.elseif cl == [rax+58] && cl == [rax+98]
			jmp winGame
		.endif
	.endif
	mov cl, [rax+50]
	.if cl != ' '
		.if cl == [rax+58] && cl == [rax+66]
			jmp winGame
		.endif
	.endif
	mov cl, [rax+98]
	.if cl != ' '
		.if cl == [rax+106] && cl == [rax+114]
			jmp winGame
		.endif
	.endif
	mov cl, [rax+2]
	.if cl != ' '
		mov cl, [rax+10]
		.if cl != ' '
			mov cl, [rax+18]
			.if cl != ' '
				mov cl, [rax+50]
				.if cl != ' '
					mov cl, [rax+58]
					.if cl != ' '
						mov cl, [rax+66]
						.if cl != ' '
							mov cl, [rax+98]
							.if cl != ' '
								mov cl, [rax+106]
								.if cl != ' '
									mov cl, [rax+114]
									.if cl != ' '
										jmp draw
									.endif
								.endif
							.endif
						.endif
					.endif
				.endif
			.endif
		.endif
	.endif
	mov rax, 0
	jmp endGame

 draw:
	SetConsoleCursorPosition(hStdOut, 0x00060000)
	printf("Remiza!")
	jmp endGame
 winGame:
	push rcx
	SetConsoleCursorPosition(hStdOut, 0x00060000)
	pop rcx
	printf("Jucatorul %c a castigat!", cl)
	mov rax, 1
 endGame:

	ret	
  GameWon endp

  ClearScreen proc uses rbx r12 thh:WORD
    LOCAL noCh:DWORD
    LOCAL sbi:CONSOLE_SCREEN_BUFFER_INFO
    GetConsoleScreenBufferInfo(hStdOut, &sbi)
    mov  ax, sbi.dwSize.X
    mov  cx, sbi.dwSize.Y
    mul  cx             ; DX:AX = AX*CX = sbi.dwSize.X * sbi.dwSize.Y
    cwde                ; EAX = DX:AX
	xor r12, r12
    mov r12d, eax        ; R12D (reg protejat) = EAX
	mov bx, thh
    FillConsoleOutputCharacter(hStdOut, ' ', r12d, NULL, &noCh)
    FillConsoleOutputAttribute(hStdOut, bh, r12d, NULL, &noCh)
    SetConsoleCursorPosition(hStdOut, NULL)
    SetConsoleTextAttribute(hStdOut, bh)

    ret
 ClearScreen endp

  OpenGame proc uses rbx r12 ga:ptr BYTE, pos:BYTE, th:WORD
	xor r12, r12
	mov bx, th
	SetConsoleTextAttribute(hStdOut, bh)
	SetConsoleCursorPosition(hStdOut, 0x00000000)
	putchar(201)
	.for (: r12 < 15 : r12++)
		putchar(205)
	.endf
	putchar(187)
	SetConsoleCursorPosition(hStdOut, 0x00010000)
	putchar(186)
	printf("               ")
	putchar(186)
	SetConsoleCursorPosition(hStdOut, 0x00020000)
	putchar(186)
	printf("  TIC TAC TOE  ")
	putchar(186)
	SetConsoleCursorPosition(hStdOut, 0x00030000)
	putchar(186)
	printf("               ")
	putchar(186)
	SetConsoleCursorPosition(hStdOut, 0x00040000)
	putchar(200)
	.for (r12 = 0 : r12 < 15 : r12++)
		putchar(205)
	.endf
	putchar(188)

	.if pos == 0
		SetConsoleTextAttribute(hStdOut, bl)
	.else
		SetConsoleTextAttribute(hStdOut, bh)
	.endif
	SetConsoleCursorPosition(hStdOut, 0x00060000)
	mov rax, ga
	.if byte ptr [rax] == 0
		printf("Sart Game")
	.else
		printf("Continue Game")
	.endif
	.if pos == 1
		SetConsoleTextAttribute(hStdOut, bl)
	.else
		SetConsoleTextAttribute(hStdOut, bh)
	.endif
	SetConsoleCursorPosition(hStdOut, 0x00080000)
	printf("Options")
	.if pos == 2
		SetConsoleTextAttribute(hStdOut, bl)
	.else
		SetConsoleTextAttribute(hStdOut, bh)
	.endif
	SetConsoleCursorPosition(hStdOut, 0x000A0000)
	printf("Exit")
	ret
 OpenGame endp

  StartMenu proc pos:ptr BYTE, gp:ptr BYTE, ga:ptr BYTE, op:WORD, th:WORD
	xor rax, rax
	mov rax, pos
	mov cl, byte ptr [rax]
	.switch op
		.case VK_UP
			mov rax, pos
			.if cl > 0
				dec byte ptr [rax]
			.else 
				mov byte ptr [rax], 2
			.endif
		.case VK_DOWN
			mov rax, pos
			.if cl < 2
				inc byte ptr [rax]
			.else
				mov byte ptr [rax], 0
			.endif
		.case VK_RETURN
			.if cl >= 0 && cl <= 2
				.if cl == 0
					mov rax, ga
					mov byte ptr [rax], 1
				.endif
				mov rax, gp
				inc cl
				mov byte ptr [rax], cl
				ClearScreen(th)
				mov rax, pos
				mov byte ptr [rax], 0
			.endif
		.default
	.endsw

	ret
 StartMenu endp

  OptionScreen proc uses rbx pos:BYTE, th:WORD
	mov bx, th
	SetConsoleTextAttribute(hStdOut, bh)
	SetConsoleCursorPosition(hStdOut, 0x00000000)
	printf(" ***Options***")

	.if pos == 0
		SetConsoleTextAttribute(hStdOut, bl)
	.else
		SetConsoleTextAttribute(hStdOut, bh)
	.endif
	SetConsoleCursorPosition(hStdOut, 0x00030000)
	printf("Theme")
	.if pos == 1
		SetConsoleTextAttribute(hStdOut, bl)
	.else
		SetConsoleTextAttribute(hStdOut, bh)
	.endif
	SetConsoleCursorPosition(hStdOut, 0x00050000)
	printf("Players")
	.if pos == 2
		SetConsoleTextAttribute(hStdOut, bl)
	.else
		SetConsoleTextAttribute(hStdOut, bh)
	.endif
	SetConsoleCursorPosition(hStdOut, 0x00070000)
	printf("Back")

	ret
 OptionScreen endp 

  UpdateOption proc pos:ptr BYTE, gp:ptr BYTE, op:WORD, th:WORD
	xor rax, rax
	mov rax, pos
	mov cl, byte ptr [rax]
	.switch op
		.case VK_UP
			mov rax, pos
			.if cl > 0
				dec byte ptr [rax]
			.else 
				mov byte ptr [rax], 2
			.endif
		.case VK_DOWN
			mov rax, pos
			.if cl < 2
				inc byte ptr [rax]
			.else 
				mov byte ptr [rax], 0
			.endif
		.case VK_RETURN
			.if cl == 0 
				mov rax, gp
				mov byte ptr [rax], 4
				ClearScreen(th)
				mov rax, pos
				mov byte ptr [rax], 0
			.elseif cl == 1
				mov rax, gp
				mov byte ptr [rax], 6
				ClearScreen(th)
				mov rax, pos
				mov byte ptr [rax], 0
			.elseif cl == 2
				mov rax, gp
				mov byte ptr [rax], 0
				ClearScreen(th)
				mov rax, pos
				mov byte ptr [rax], 0
			.endif
		.default
	.endsw

	ret
 UpdateOption endp

  ThemeScreen proc uses rbx pos:BYTE, th:WORD
	mov bx, th
	SetConsoleTextAttribute(hStdOut, bh)
	SetConsoleCursorPosition(hStdOut, 0x00000000)
	printf(" ***Theme***")

	.if pos == 0
		SetConsoleTextAttribute(hStdOut, bl)
	.else
		SetConsoleTextAttribute(hStdOut, bh)
	.endif
	SetConsoleCursorPosition(hStdOut, 0x00030000)
	printf("Classic")
	.if pos == 1
		SetConsoleTextAttribute(hStdOut, bl)
	.else
		SetConsoleTextAttribute(hStdOut, bh)
	.endif
	SetConsoleCursorPosition(hStdOut, 0x00050000)
	printf("Light Mode")
	.if pos == 2
		SetConsoleTextAttribute(hStdOut, bl)
	.else
		SetConsoleTextAttribute(hStdOut, bh)
	.endif
	SetConsoleCursorPosition(hStdOut, 0x00070000)
	printf("Warning")
	.if pos == 3
		SetConsoleTextAttribute(hStdOut, bl)
	.else
		SetConsoleTextAttribute(hStdOut, bh)
	.endif
	SetConsoleCursorPosition(hStdOut, 0x00090000)
	printf("Danger")
	.if pos == 4
		SetConsoleTextAttribute(hStdOut, bl)
	.else
		SetConsoleTextAttribute(hStdOut, bh)
	.endif
	SetConsoleCursorPosition(hStdOut, 0x000B0000)
	printf("Boot")
	.if pos == 5
		SetConsoleTextAttribute(hStdOut, bl)
	.else
		SetConsoleTextAttribute(hStdOut, bh)
	.endif
	SetConsoleCursorPosition(hStdOut, 0x000D0000)
	printf("Bumblebee")
	.if pos == 6
		SetConsoleTextAttribute(hStdOut, bl)
	.else
		SetConsoleTextAttribute(hStdOut, bh)
	.endif
	SetConsoleCursorPosition(hStdOut, 0x000F0000)
	printf("Optimus Prime")
	.if pos == 7
		SetConsoleTextAttribute(hStdOut, bl)
	.else
		SetConsoleTextAttribute(hStdOut, bh)
	.endif
	SetConsoleCursorPosition(hStdOut, 0x00110000)
	printf("Megatron")
	.if pos == 8
		SetConsoleTextAttribute(hStdOut, bl)
	.else
		SetConsoleTextAttribute(hStdOut, bh)
	.endif
	SetConsoleCursorPosition(hStdOut, 0x00130000)
	printf("Knockout")
	.if pos == 9
		SetConsoleTextAttribute(hStdOut, bl)
	.else
		SetConsoleTextAttribute(hStdOut, bh)
	.endif
	SetConsoleCursorPosition(hStdOut, 0x00150000)
	printf("Blood Ink")
	.if pos == 10
		SetConsoleTextAttribute(hStdOut, bl)
	.else
		SetConsoleTextAttribute(hStdOut, bh)
	.endif
	SetConsoleCursorPosition(hStdOut, 0x00170000)
	printf("Christmas")
	.if pos == 11
		SetConsoleTextAttribute(hStdOut, bl)
	.else
		SetConsoleTextAttribute(hStdOut, bh)
	.endif
	SetConsoleCursorPosition(hStdOut, 0x00190000)
	printf("Valentie's Day")
	.if pos == 12
		SetConsoleTextAttribute(hStdOut, bl)
	.else
		SetConsoleTextAttribute(hStdOut, bh)
	.endif
	SetConsoleCursorPosition(hStdOut, 0x001B0000)
	printf("Customize")
	
	.if pos == 13
		SetConsoleTextAttribute(hStdOut, bl)
	.else
		SetConsoleTextAttribute(hStdOut, bh)
	.endif
	SetConsoleCursorPosition(hStdOut, 0x001E0000)
	printf("Back")

	ret
 ThemeScreen endp
 
  UpdateTheme proc pos:ptr BYTE, gp:ptr BYTE, th:ptr WORD, pl:ptr WORD, op:WORD
	xor rax, rax
	mov rax, pos
	mov cl, byte ptr [rax]
	.switch op
		.case VK_UP
			mov rax, pos
			.if cl > 0
				dec byte ptr [rax]
			.else
				mov byte ptr [rax], 13
			.endif
		.case VK_DOWN
			mov rax, pos
			.if cl < 13
				inc byte ptr [rax]
			.else
				mov byte ptr [rax], 0
			.endif
		.case VK_RETURN
			.if cl >= 0 && cl < 12
				mov rax, th
				mov rdx, pl
				movzx rcx, cl
				mov dx, [rdx+rcx*2]
				mov [rax], dx
				ClearScreen([rax])
			.elseif cl == 12
				mov rax, gp
				mov byte ptr [rax], 5
				mov rax, th
				ClearScreen([rax])
				mov rax, pos
				mov byte ptr [rax], 0
			.elseif cl == 13
				mov rax, gp
				mov byte ptr [rax], 2
				mov rax, th
				ClearScreen([rax])
				mov rax, pos
				mov byte ptr [rax], 0
			.endif
		.default
	.endsw

	ret
UpdateTheme endp

  CustomScreen proc uses rbx r12 r13 pl:ptr WORD, pos:BYTE, th:WORD
	mov bx, th
	SetConsoleTextAttribute(hStdOut, bh)
	SetConsoleCursorPosition(hStdOut, 0x00000000)
	printf(" ***Customize***")

	mov r12, pl
	add r12, 24
	.if pos == 0
		SetConsoleTextAttribute(hStdOut, bl)
	.else
		SetConsoleTextAttribute(hStdOut, bh)
	.endif
	SetConsoleCursorPosition(hStdOut, 0x00030000)
	printf("Primary Background Color       <    >")
	SetConsoleCursorPosition(hStdOut, 0x00030021)
	mov r13b, byte ptr [r12+1]
	SetConsoleTextAttribute(hStdOut, r13b)
	printf("  ")
	.if pos == 1
		SetConsoleTextAttribute(hStdOut, bl)
	.else
		SetConsoleTextAttribute(hStdOut, bh)
	.endif
	SetConsoleCursorPosition(hStdOut, 0x00050000)
	printf("Primary Text Color             <    >")
	SetConsoleCursorPosition(hStdOut, 0x00050021)
	mov r13b, byte ptr [r12+1]
	shl r13b, 4
	SetConsoleTextAttribute(hStdOut, r13b)
	printf("  ")
	.if pos == 2
		SetConsoleTextAttribute(hStdOut, bl)
	.else
		SetConsoleTextAttribute(hStdOut, bh)
	.endif
	SetConsoleCursorPosition(hStdOut, 0x00070000)
	printf("Secondary Background Color     <    >")
	SetConsoleCursorPosition(hStdOut, 0x00070021)
	mov r13b, byte ptr [r12]
	SetConsoleTextAttribute(hStdOut, r13b)
	printf("  ")
	.if pos == 3
		SetConsoleTextAttribute(hStdOut, bl)
	.else
		SetConsoleTextAttribute(hStdOut, bh)
	.endif
	SetConsoleCursorPosition(hStdOut, 0x00090000)
	printf("Secondary Text Color           <    >")
	SetConsoleCursorPosition(hStdOut, 0x00090021)
	mov r13b, byte ptr [r12]
	shl r13b, 4
	SetConsoleTextAttribute(hStdOut, r13b)
	printf("  ")
	
	.if pos == 4
		SetConsoleTextAttribute(hStdOut, bl)
	.else
		SetConsoleTextAttribute(hStdOut, bh)
	.endif
	SetConsoleCursorPosition(hStdOut, 0x000C0000)
	printf("Apply")
	.if pos == 5
		SetConsoleTextAttribute(hStdOut, bl)
	.else
		SetConsoleTextAttribute(hStdOut, bh)
	.endif
	SetConsoleCursorPosition(hStdOut, 0x000E0000)
	printf("Back")

	ret
  CustomScreen endp

  UpdateCustom proc uses r12 r13 r14 r15 pos:ptr BYTE, gp:ptr BYTE, th:ptr WORD, pl:ptr WORD, op:WORD
	xor rax, rax
	mov rax, pos
	mov cl, byte ptr [rax]
	.switch op
		.case VK_UP
			mov rax, pos
			.if cl > 0
				dec byte ptr [rax]
			.else
				mov byte ptr [rax], 5
			.endif
		.case VK_DOWN
			mov rax, pos
			.if cl < 5
				inc byte ptr [rax]
			.else
				mov byte ptr [rax], 0
			.endif
		.case VK_LEFT
			.if cl == 0
				mov r12, pl
				add r12, 24
				mov r13b, byte ptr [r12+1] ;pb
				shr r13b, 4
				.if r13b == 0
					mov r13b, 15
				.else
					dec r13b
				.endif
				mov r14b, byte ptr [r12+1] ;pt
				shl r14b, 4
				shr r14b, 4
				mov r15b, byte ptr [r12] ;sb
				shr r15b, 4
				.if r13b == r14b || r13b == r15b
					dec r13b
					shl r13b, 4
					shr r13b, 4
					.if r13b == r14b || r13b == r15b
						dec r13b
					.endif
				.endif
				shl r13w, 8
				shl r14b, 4
				add r13w, r14w
				shr r13w, 4
				mov byte ptr [r12+1], r13b
			.elseif cl == 1
				mov r12, pl
				add r12, 24
				mov r13b, byte ptr [r12+1] ;pt
				shl r13b, 4
				shr r13b, 4
				.if r13b == 0
					mov r13b, 15
				.else
					dec r13b
				.endif
				mov r14b, byte ptr [r12+1] ;pb
				shr r14b, 4
				.if r13b == r14b
					dec r13b
				.endif
				shl r14w, 8
				shl r13b, 4
				add r14w, r13w
				shr r14w, 4
				mov byte ptr [r12+1], r14b
			.elseif cl == 2
				mov r12, pl
				add r12, 24
				mov r13b, byte ptr [r12] ;sb
				shr r13b, 4
				.if r13b == 0
					mov r13b, 15
				.else
					dec r13b
				.endif
				mov r14b, byte ptr [r12] ;st
				shl r14b, 4
				shr r14b, 4
				mov r15b, byte ptr [r12+1] ;pb
				shr r15b, 4
				.if r13b == r14b || r13b == r15b
					dec r13b
					shl r13b, 4
					shr r13b, 4
					.if r13b == r14b || r13b == r15b
						dec r13b
					.endif
				.endif
				shl r13w, 8
				shl r14b, 4
				add r13w, r14w
				shr r13w, 4
				mov byte ptr [r12], r13b
			.elseif cl == 3
				mov r12, pl
				add r12, 24
				mov r13b, byte ptr [r12] ;st
				shl r13b, 4
				shr r13b, 4
				.if r13b == 0
					mov r13b, 15
				.else
					dec r13b
				.endif
				mov r14b, byte ptr [r12] ;sb
				shr r14b, 4
				.if r13b == r14b
					dec r13b
				.endif
				shl r14w, 8
				shl r13b, 4
				add r14w, r13w
				shr r14w, 4
				mov byte ptr [r12], r14b
			.endif
		.case VK_RIGHT
				.if cl == 0
				mov r12, pl
				add r12, 24
				mov r13b, byte ptr [r12+1] ;pb
				shr r13b, 4
				.if r13b == 15
					mov r13b, 0
				.else
					inc r13b
				.endif
				mov r14b, byte ptr [r12+1] ;pt
				shl r14b, 4
				shr r14b, 4
				mov r15b, byte ptr [r12] ;sb
				shr r15b, 4
				.if r13b == r14b || r13b == r15b
					inc r13b
					shl r13b, 4
					shr r13b, 4
					.if r13b == r14b || r13b == r15b
						inc r13b
					.endif
				.endif
				shl r13w, 8
				shl r14b, 4
				add r13w, r14w
				shr r13w, 4
				mov byte ptr [r12+1], r13b
			.elseif cl == 1
				mov r12, pl
				add r12, 24
				mov r13b, byte ptr [r12+1] ;pt
				shl r13b, 4
				shr r13b, 4
				.if r13b == 15
					mov r13b, 0
				.else
					inc r13b
				.endif
				mov r14b, byte ptr [r12+1] ;pb
				shr r14b, 4
				.if r13b == r14b
					inc r13b
				.endif
				shl r14w, 8
				shl r13b, 4
				add r14w, r13w
				shr r14w, 4
				mov byte ptr [r12+1], r14b
			.elseif cl == 2
				mov r12, pl
				add r12, 24
				mov r13b, byte ptr [r12] ;sb
				shr r13b, 4
				.if r13b == 15
					mov r13b, 0
				.else
					inc r13b
				.endif
				mov r14b, byte ptr [r12] ;st
				shl r14b, 4
				shr r14b, 4
				mov r15b, byte ptr [r12+1] ;pb
				shr r15b, 4
				.if r13b == r14b || r13b == r15b
					inc r13b
					shl r13b, 4
					shr r13b, 4
					.if r13b == r14b || r13b == r15b
						inc r13b
					.endif
				.endif
				shl r13w, 8
				shl r14b, 4
				add r13w, r14w
				shr r13w, 4
				mov byte ptr [r12], r13b
			.elseif cl == 3
				mov r12, pl
				add r12, 24
				mov r13b, byte ptr [r12] ;st
				shl r13b, 4
				shr r13b, 4
				.if r13b == 15
					mov r13b, 0
				.else
					inc r13b
				.endif
				mov r14b, byte ptr [r12] ;sb
				shr r14b, 4
				.if r13b == r14b
					inc r13b
				.endif
				shl r14w, 8
				shl r13b, 4
				add r14w, r13w
				shr r14w, 4
				mov byte ptr [r12], r14b
			.endif
		.case VK_RETURN
			.if cl == 4
				mov rax, th
				mov rdx, pl
				mov dx, [rdx+24]
				mov [rax], dx
				ClearScreen([rax])
			.elseif cl == 5
				mov rax, gp
				mov byte ptr [rax], 4
				mov rax, th
				ClearScreen([rax])
				mov rax, pos
				mov byte ptr [rax], 0
			.endif
		.default
	.endsw

	ret
  UpdateCustom endp

  PlayersScreen proc uses rbx r12 r13 r14 p0:ptr BYTE, pos:BYTE, th:WORD
	mov bx, th
	SetConsoleTextAttribute(hStdOut, bh)
	SetConsoleCursorPosition(hStdOut, 0x00000000)
	printf(" ***Players***  ***WORK IN PROGRESS***")

	mov r12, p0
	movzx r13, byte ptr [r12+136]
	movzx r14, byte ptr [r12+137]
	.if pos == 0
		SetConsoleTextAttribute(hStdOut, bl)
	.else
		SetConsoleTextAttribute(hStdOut, bh)
	.endif
	SetConsoleCursorPosition(hStdOut, 0x00030000)
	printf("Player 1       <     >")
	SetConsoleCursorPosition(hStdOut, 0x00030011)
	putchar(byte ptr [r12+r13-1])
	putchar(byte ptr [r12+r13])
	putchar(byte ptr [r12+r13+1])
	.if pos == 1
		SetConsoleTextAttribute(hStdOut, bl)
	.else
		SetConsoleTextAttribute(hStdOut, bh)
	.endif
	SetConsoleCursorPosition(hStdOut, 0x00050000)
	printf("Player 2       <     >")
	SetConsoleCursorPosition(hStdOut, 0x00050011)
	putchar(byte ptr [r12+r14-1])
	putchar(byte ptr [r12+r14])
	putchar(byte ptr [r12+r14+1])

	.if pos == 2
		SetConsoleTextAttribute(hStdOut, bl)
	.else
		SetConsoleTextAttribute(hStdOut, bh)
	.endif
	SetConsoleCursorPosition(hStdOut, 0x00080000)
	printf("Apply")
	.if pos == 3
		SetConsoleTextAttribute(hStdOut, bl)
	.else
		SetConsoleTextAttribute(hStdOut, bh)
	.endif
	SetConsoleCursorPosition(hStdOut, 0x000A0000)
	printf("Back")

	ret
  PlayersScreen endp

  UpdatePlayers proc uses r12 r13 r14 pos:ptr BYTE, gp:ptr BYTE, p0:ptr BYTE, p1:ptr BYTE, p2:ptr BYTE, op:WORD, th:WORD
	xor rax, rax
	mov rax, pos
	mov cl, byte ptr [rax]
	.switch op
		.case VK_UP
			mov rax, pos
			.if cl > 0
				dec byte ptr [rax]
			.else
				mov byte ptr [rax], 3
			.endif
		.case VK_DOWN
			mov rax, pos
			.if cl < 3
				inc byte ptr [rax]
			.else
				mov byte ptr [rax], 0
			.endif
		.case VK_LEFT
			.if cl == 0
				mov r12, p0
				movzx r13, byte ptr [r12+136]
				movzx r14, byte ptr [r12+137]
				.if r13b == 1
					mov r13b, 133
				.else
					dec r13b
					dec r13b
					dec r13b
				.endif
				.if r13b == r14b
					.if r13b == 1
						mov r13b, 133
					.else
						dec r13b
						dec r13b
						dec r13b
					.endif
				.endif
				mov byte ptr [r12+136], r13b
			.elseif cl == 1
				mov r12, p0
				movzx r13, byte ptr [r12+136]
				movzx r14, byte ptr [r12+137]
				.if r14b == 1
					mov r14b, 133
				.else
					dec r14b
					dec r14b
					dec r14b
				.endif
				.if r13b == r14b
					.if r14b == 1
						mov r14b, 133
					.else
						dec r14b
						dec r14b
						dec r14b
					.endif
				.endif
				mov byte ptr [r12+137], r14b
			.endif
		.case VK_RIGHT
			.if cl == 0
				mov r12, p0
				movzx r13, byte ptr [r12+136]
				movzx r14, byte ptr [r12+137]
				.if r13b == 133
					mov r13b, 1
				.else
					inc r13b
					inc r13b
					inc r13b
				.endif
				.if r13b == r14b
					.if r13b == 133
						mov r13b, 1
					.else
						inc r13b
						inc r13b
						inc r13b
					.endif
				.endif
				mov byte ptr [r12+136], r13b
			.elseif cl == 1
				mov r12, p0
				movzx r13, byte ptr [r12+136]
				movzx r14, byte ptr [r12+137]
				.if r14b == 133
					mov r14b, 1
				.else
					inc r14b
					inc r14b
					inc r14b
				.endif
				.if r13b == r14b
					.if r14b == 133
						mov r14b, 1
					.else
						inc r14b
						inc r14b
						inc r14b
					.endif
				.endif
				mov byte ptr [r12+137], r14b
			.endif
		.case VK_RETURN
			.if cl == 2
				mov r12, p0
				movzx r13, byte ptr [r12+136]
				mov r14, p1
				mov [r14], r13b
				movzx r13, byte ptr [r12+137]
				mov r14, p2
				mov [r14], r13b
			.elseif cl == 3
				mov rax, gp
				mov byte ptr [rax], 2
				ClearScreen(th)
				mov rax, pos
				mov byte ptr [rax], 0
			.endif
		.default
	.endsw

	ret  
  UpdatePlayers endp

end ; starsitul codului sursa