include Irvine32.inc
main EQU start@0

ReadMapFile proto
DrawWall proto
KeyEvent proto, key: word
DrawPlayer proto, char: byte
ErasePlayer proto
TwoDToLine proto, x: byte, y: byte
PosIsWall proto, x: byte, y: byte
IsGameOver proto
Timer proto
IncreaseStep proto
PrintStep proto

.data
fileHandle dword ?
outputHandle dword ?
inputHandle dword ?
screenBufferSize COORD <256, 256>

mapFileName byte "map.txt", 0
readBuffer byte ?
bytesRead dword ?
mazeSize byte ?
edgeData byte 32768 DUP(4 DUP(0))
wallCharMap byte 32768 DUP(0)
wallCharacter byte 35 ; '35 -> #'
mazePosOffset byte 3

upperBorder byte ?
lowerBorder byte ?
leftBorder byte ?
rightBorder byte ?

playerCurCoord COORD <35, 10>
playerNextCoord COORD <35, 10>

currentStep dword ?
stepString byte "Steps: ", 0

timeString byte "Time: ", 0
initTime dword ?
currentTime dword ?

.data?

_st SYSTEMTIME <?>


.code
main proc

INITIAL:

	invoke GetStdHandle, STD_OUTPUT_HANDLE
	mov outputHandle, eax

	invoke GetStdHandle, STD_INPUT_HANDLE
	mov inputHandle, eax

	invoke SetConsoleScreenBufferSize,
		outputHandle,
		screenBufferSize

	invoke CreateFile,
		addr mapFileName,
		GENERIC_READ, ; access mode
		DO_NOT_SHARE, ; share mode
		NULL, ; ptr to security attributes
		OPEN_EXISTING, ; file creation options
		FILE_ATTRIBUTE_NORMAL, ; file attributes
		0 ; handle to template file
	mov fileHandle, eax

	invoke ReadMapFile
	invoke DrawWall

PLAYING:
	
	movzx ax, mazePosOffset
	inc ax
	mov playerCurCoord.x, ax
	mov playerCurCoord.y, ax
	mov playerNextCoord.x, ax
	mov playerNextCoord.y, ax
	invoke DrawPlayer, 'v'

	invoke GetSystemTime, addr _st
    mov edx, offset _st
    movzx ebx, word ptr SYSTEMTIME.wsecond[edx]
	mov initTime, ebx
	mov currentStep, 0
	mov currentTime, -1
	.while 1
		invoke Timer
		invoke PrintStep
		mov eax, 100
		call Delay
		call ReadKey
		invoke KeyEvent, ax
		invoke IsGameOver
		.break .if al
	.endw

EXIT_PROC:

	invoke CloseHandle, fileHandle
	exit

main endp


ReadMapFile proc
	
	; read size
	mov eax, 0
	.while 1
		push eax
		invoke ReadFile,
			fileHandle,
			addr readBuffer, 1,
			addr bytesRead, 0
		mov dl, readBuffer
		pop eax
		.break .if dl < 48
		sub dl, 48
		mov bl, 10
		mul bl
		add al, dl
	.endw
	
	mov mazeSize, al
	invoke ReadFile,
		fileHandle,
		addr readBuffer, 1,
		addr bytesRead, 0

	; read edges
	mov edi, offset edgeData
	push edi
	.while 1
		mov ecx, 0
		.while cl < 4
			mov eax, 0
			push ecx
			.while 1
				push eax
				invoke ReadFile,
					fileHandle,
					addr readBuffer, 1,
					addr bytesRead, 0
				mov dl, readBuffer
				pop eax
				.break .if dl < 48
				.if dl >= 58
					pop ecx
					pop edi
					mov al, 0ffh
					mov [edi], al
					ret
				.endif
				sub dl, 48
				mov bl, 10
				mul bl
				add al, dl
			.endw

			pop ecx
			inc cl

			pop edi
			mov [edi], al
			inc edi
			push edi
		.endw

		invoke ReadFile,
			fileHandle,
			addr readBuffer, 1,
			addr bytesRead, 0
	.endw
	ret

ReadMapFile endp


DrawWall proc

	call ClrScr

	mov esi, offset edgeData
	.while 1
		mov dl, [esi]
		.break .if dl == 0ffh
		mov dh, [esi + 1]

		.if dl == [esi + 2]
			mov bl, 0 ; increase Y
		.else
			mov bl, 1 ; increase X
		.endif

		shl dx, 1
		add dl, mazePosOffset
		add dh, mazePosOffset
		mov ecx, 3
		.while cl
			push ebx
			push ecx

			invoke TwoDToLine, dl, dh
			mov edi, offset wallCharMap
			add edi, eax
			mov [edi], byte ptr 1

			call Gotoxy
			movzx eax, wallCharacter
			call WriteChar
			
			pop ecx
			pop ebx
			.if bl
				inc dl
			.else
				inc dh
			.endif
			dec cl
		.endw

		add esi, 4
	.endw

	mov al, mazeSize
	shl al, 1
	add al, mazePosOffset
	mov lowerBorder, al
	mov rightBorder, al
	mov al, mazePosOffset
	sub al, 2
	mov upperBorder, al
	mov leftBorder, al

	mov dl, 0
	mov dh, 0
	call Gotoxy
	ret

DrawWall endp


KeyEvent proc, key: word
	
	push eax
	push edx
	mov ax, key
	.if ax == 1177h ; Up
		mov ax, playerCurCoord.y
		dec al
		push eax
		invoke PosIsWall,
			byte ptr playerCurCoord.x, al
		mov dl, al
		pop eax
		.if al > upperBorder && dl == 0
			mov playerNextCoord.y, ax
			call ErasePlayer
			invoke DrawPlayer, '^'
			mov playerCurCoord.y, ax
			invoke IncreaseStep
		.endif
	.endif

	.if ax == 1F73h ; Down
		mov ax, playerCurCoord.y
		inc al
		push eax
		invoke PosIsWall,
			byte ptr playerCurCoord.x, al
		mov dl, al
		pop eax
		.if al < lowerBorder && dl == 0
			mov playerNextCoord.y, ax
			call ErasePlayer
			invoke DrawPlayer, 'v'
			mov playerCurCoord.y, ax
			invoke IncreaseStep
		.endif
	.endif

	.if ax == 1E61h ; Left
		mov ax, playerCurCoord.x
		dec al
		push eax
		mov dl, al
		invoke PosIsWall,
			dl, byte ptr playerCurCoord.y
		mov dl, al
		pop eax
		.if al > leftBorder && dl == 0
			mov playerNextCoord.x, ax
			call ErasePlayer
			invoke DrawPlayer, '<'
			mov playerCurCoord.x, ax
			invoke IncreaseStep
		.endif
	.endif

	.if ax == 2064h ; Right
		mov ax, playerCurCoord.x
		inc al
		push eax
		mov dl, al
		invoke PosIsWall,
			dl, byte ptr playerCurCoord.y
		mov dl, al
		pop eax
		.if al < rightBorder && dl == 0
			mov playerNextCoord.x, ax
			call ErasePlayer
			invoke DrawPlayer, '>'
			mov playerCurCoord.x, ax
			invoke IncreaseStep
		.endif
	.endif

	.if ax == 1c0dh ; Enter
		invoke DrawWall
		invoke DrawPlayer, 'v'
	.endif

	pop edx
	pop eax
	ret

KeyEvent endp


DrawPlayer proc, char: byte

	push edx
	push eax
	mov dl, byte ptr playerNextCoord.x
	mov dh, byte ptr playerNextCoord.y
	call Gotoxy
	movzx eax, char
	call WriteChar
	mov dl, 0
	mov dh, 0
	call Gotoxy
	pop eax
	pop edx
	ret

DrawPlayer endp


ErasePlayer proc uses eax edx

	mov dl, byte ptr playerCurCoord.x
	mov dh, byte ptr playerCurCoord.y
	call Gotoxy
	mov eax, " "
	call WriteChar
	ret

ErasePlayer ENDP


TwoDToLine proc, x: byte, y: byte
	
	push ebx
	mov bl, mazeSize
	shl bl, 1
	dec bl
	add bl, mazePosOffset
	movzx eax, y
	mul bl
	add ax, word ptr x
	pop ebx
	ret

TwoDtoLine endp


PosIsWall proc, x: byte, y: byte
	
	push esi
	mov esi, offset wallCharMap
	invoke TwoDToLine, x, y
	add esi, eax
	mov al, [esi]
	pop esi
	ret

PosIsWall endp


IsGameOver proc
	
	mov ah, byte ptr playerCurCoord.x
	mov al, byte ptr playerCurCoord.y
	inc ah
	inc al
	.if al == lowerBorder || ah == rightBorder
		mov al, 1
	.else
		sub ah, 2
		sub al, 2
		.if	al == upperBorder || ah == leftBorder
			mov al, 1
		.else
			mov al, 0
		.endif
	.endif
	ret

IsGameOver endp

Timer proc uses eax ebx ecx edx

L1:
    invoke GetSystemTime,addr _st
    mov edx, offset _st
    movzx ecx, word ptr SYSTEMTIME.wsecond[edx]
	mov ebx, initTime
    cmp ebx, ecx
	je L3
    jmp L2
L2:
	mov dl, 0
	mov dh, 1
	call Gotoxy
	mov edx, offset timeString
	call WriteString
	mov eax, currentTime
    inc eax
	mov currentTime, eax
    call WriteDec
	mov initTime, ecx

L3:
	ret

Timer endp

IncreaseStep proc uses eax edx

	mov eax, currentStep
	inc eax
	mov currentStep, eax
	ret

IncreaseStep endp

PrintStep proc uses eax edx

	mov dx, 0
	call gotoxy
	mov edx, offset stepString
	call WriteString
	mov eax, currentStep
    call WriteDec
	ret

PrintStep endp

end main