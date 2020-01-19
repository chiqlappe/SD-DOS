
KANJI:			EQU	TRUE	;�t�@�C���X�V�����Ɋ������g�p����ꍇ��TRUE
SECONDS:		EQU	FALSE	;�t�@�C���X�V������"�b"���o�͂���ꍇ��TRUE

;=================================================
;�t�@�C���̓��t�������݂̈ʒu�ɏo�͂���
;IN  DE=�G���R�[�h���ꂽ���t
;OUT 
;=================================================
PRT_FDATE:
	PUSH	DE
	EXX
	POP	HL
	CALL	GET_FDATE	;

	LD	A,D		;=YEAR
	CALL	PRT_WDEC	;
IF KANJI
	LD	A,0F2H		;="�N"
ELSE
	LD	A,"/"
ENDIF
	RST	18H		;
	LD	A,E		;=MONTH
	CALL	PRT_WDEC	;
IF KANJI
	LD	A,0F3H		;="��"
ELSE
	LD	A,"/"
ENDIF
	RST	18H		;
	LD	A,C		;=DAY
	CALL	PRT_WDEC	;
IF KANJI
	LD	A,0F4H		;="��"
	RST	18H		;
ENDIF

	EXX
	RET

;=================================================
;�t�@�C���̎����������݂̈ʒu�ɏo�͂���
;IN  DE=�G���R�[�h���ꂽ����
;OUT 
;=================================================
PRT_FTIME:
	PUSH	DE
	EXX
	POP	HL
	CALL	GET_FTIME	;D=HOUR,E=MIN,C=SEC

	LD	A,D		;=HOUR
	CALL	PRT_WDEC		;
IF KANJI
	LD	A,0F5H		;"��"
ELSE
	LD	A,":"
ENDIF
	RST	18H		;
	LD	A,E		;=MIN
	CALL	PRT_WDEC	;
IF KANJI
	LD	A,0F6H		;"��"
	RST	18H		;
ENDIF

IF SECONDS
 IF !KANJI
	LD	A,":"
	RST	18H
 ENDIF

	RST	18H		;
	LD	A,C		;=SEC
	CALL	PRT_WDEC	;
 IF KANJI
	LD	A,0F7H		;"�b"
	RST	18H		;
 ENDIF
ENDIF

	EXX
	RET

;=================================================
;[DATE]�t�@�C���̓��t�������W�X�^�Ɏ擾����
;IN  HL=�G���R�[�h���ꂽ���t
;OUT D=YEAR,E=MONTH,C=DAY
;=================================================
GET_FDATE:
				;L=MMMDDDDd
				;H=YYYYYYYm
	LD	A,L		;A=MMMDDDDd
	SRL	H		;H=0YYYYYYY CY=m H=YEAR
	RRA			;A=mMMMDDDD CY=d
	SRL	A		;
	SRL	A		;
	SRL	A		;
	SRL	A		;A=0000mMMM
	LD	E,A		;B=MONTH
	LD	A,00011111B	;
	AND	L		;
	LD	C,A		;C=DAY
	LD	A,80		;=1980�̉���
	ADD	A,H		;=YEAR+80
.L2:	CP	100		;YEAR��100�����ɂ���
	JR	C,.L1		;
	SUB	100		;
	JR	.L2		;
.L1:	LD	D,A		;D=YEAR

	RET

;=================================================
;[DATE]�t�@�C���̎����������W�X�^�Ɏ擾����
;IN  HL=�G���R�[�h���ꂽ����
;OUT D=HOUR,E=MIN,C=SEC
;=================================================
GET_FTIME:
				;L=MMMSSSSS
				;H=HHHHHMMM
	LD	A,00011111B	;�b�̃r�b�g�}�X�N
	AND	L		;A=000SSSSS
	RLA			;A=00SSSSS0 Ax2
	LD	C,A		;C=00SSSSS0=SEC
	LD	A,L		;A=MMMSSSSS
	SRL	H		;H=0HHHHHMM CY=M
	RRA			;A=MMMMSSSS CY=S
	SRL	H		;H=00HHHHHM CY=M
	RRA			;A=MMMMMSSS
	SRL	H		;H=000HHHHH=HOUR
	LD	D,H		;D=HOUR

	RRA			;A=MMMMMMSS
	SRL	A		;A=0MMMMMMS
	SRL	A		;A=00MMMMMM
	LD	E,A		;E=00MMMMMM=MIN
				;D=HOUR,E=MIN
	RET

;=================================================
;[DATE]������FAT�t�H�[�}�b�g�ɃG���R�[�h����
;IN  D=000HHHHH=0~31,E=00MMMMMM=0~63,C=00SSSSSS=0~63
;OUT HL=HHHHHMMM.MMMSSSSS
;=================================================
ENC_TIME:
	SET	0,C				;C=00SSSSS0 SEC��1/2�ɂ���
	SLA	C				;C=0SSSSS00
	SLA	C				;C=SSSSS000
	LD	A,C				;A=SSSSS000
	SRL	E				;E=000MMMMM CY=M
	RRA					;A=MSSSSS00 CY=0
	SRL	E				;E=0000MMMM CY=M
	RRA					;A=MMSSSSS0 CY=0
	SRL	E				;E=00000MMM CY=M
	RRA					;A=MMMSSSSS CY=0
	LD	L,A				;L=MMMSSSSS CY=0
	LD	A,D				;A=000HHHHH CY=0
	RLCA					;A=00HHHHH0 CY=0
	RLCA					;A=0HHHHH00 CY=0
	RLCA					;A=HHHHH000 CY=0
	OR	E				;A=HHHHHMMM
	LD	H,A				;H=HHHHHMMM
	RET					;

;=================================================
;[DATE]���t��FAT�t�H�[�}�b�g�ɃG���R�[�h����
;IN  D=0YYYYYYY=0~127,E=0000MMMM=0~15,C=000DDDDD=0~31
;OUT HL=YYYYYYYM.MMMDDDDD
;=================================================
ENC_DATE:
	SLA	C				;C=00DDDDD0
	SLA	C				;C=0DDDDD00
	SLA	C				;C=DDDDD000
	LD	A,C				;A=DDDDD000
	SRL	E				;L=00000MMM CY=M
	RRA					;A=MDDDDD00 CY=0
	SRL	E				;L=000000MM CY=M
	RRA					;A=MMDDDDD0 CY=0
	SRL	E				;L=0000000M CY=M
	RRA					;A=MMMDDDDD CY=0
	LD	L,A				;L=MMMDDDDD
	LD	A,D				;A=0YYYYYYY
	RLCA					;A=YYYYYYY0
	OR	E				;A=YYYYYYYM
	LD	H,A				;H=YYYYYYYM
	RET					;

;=================================================
;2����10�i�������݂̈ʒu�ɏo�͂���
;IN  A
;OUT -
;=================================================
PRT_WDEC:
	PUSH	BC				;
.L4:	CP	100				;���炩���ߒl��100�����ɏC������
	JR	C,.L3				;
	SUB	100				;
	JR	.L4				;
.L3:	LD	B,0				;
	LD	C,10				;
.L2:	SUB	C				;
	JR	C,.L1				;
	INC	B				;
	JR	.L2				;
.L1:	ADD	A,10				;
	LD	C,A				;
	LD	A,"0"				;
	ADD	A,B				;
	RST	18H				;
	LD	A,"0"				;
	ADD	A,C				;
	RST	18H				;
	POP	BC				;
	RET					;

