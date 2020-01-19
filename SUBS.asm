;=================================================
;[SUB]�C���t�H���[�V�����X�C�b�`���I�����`�F�b�N����
;IN  -
;OUT Z=1:�I�t�i����\�����Ȃ����[�h�j
;=================================================
IS_INFO_ON:
	LD	A,(INFO_SW)
	AND	A
	RET

;=================================================
;[SUB]���t��79�N���`�F�b�N����
;IN  (DT_YEAR)
;OUT CF=1:79�N
;=================================================
IF FALSE
IS_YEAR79:
	LD	A,(DT_YEAR)			;
	CP	79H				;=79�N
	RET	NZ				;
	CALL	IPRINT				;
	DB	"SET",CR,LF			;
	DB	"DATE$=",DQUOTE,"00/00/00",DQUOTE
	DB	":TIME$=",DQUOTE,"00:00:00",DQUOTE,CR,LF,EOL
	RET
ENDIF

;=================================================
;[SUB]�ꎞ��~
;IN  
;OUT :Z=1:STOP�L�[�������ꂽ
;=================================================
PAUSE:
	IN	A,(09H)				;
	BIT	00H,A				;STOP�����Ȃ�Z=1
	RET	Z				;�������f��
	BIT	07H,A				;�G�X�P�[�v�����Ȃ�ꎞ��~
	RET	NZ				;
	CALL	KEYWAIT				;���^�[�����͂ōĊJ
	CP	03H				;STOP�����Ȃ�Z=1
	RET					;

;=================================================
;[SUB]�g���q�ʂɃT�u���[�`���փW�����v����
;IN  (TGT_CLSTR)=�t�@�C���̃N���X�^��,HL=�T�u���[�`���e�[�u���|�C���^
;OUT
;=================================================
EXT_TABLE_JUMP:
.L3:	PUSH	HL				;�e�[�u���|�C���^��ޔ�
	LD	DE,DIR_ENTRY+IDX_EXT		;DE<-�f�B���N�g���G���g���g���q��
	LD	B,03H				;B<-�g���q�̕�����
.L2:	LD	A,(DE)				;���͂��ꂽ�g���q�ƃe�[�u�����ƍ�����
	CP	(HL)				;(DE):(HL)
	JR	NZ,.L1				;�s��v������
	INC	DE				;���ꂼ��̃|�C���^��i�߂�
	INC	HL				;
	DJNZ	.L2				;�������������J��Ԃ�

	POP	DE				;�s�v�ɂȂ����e�[�u���|�C���^���̂Ă�
	LD	E,(HL)				;DE<-�g���q�ɑΉ������T�u���[�`���̃A�h���X
	INC	HL				;
	LD	D,(HL)				;
	EX	DE,HL				;HL<-DE
	JP	(HL)				;�T�u���[�`����

.L1:	POP	HL				;HL<-�s�̐擪�A�h���X
	LD	BC,0005H			;BC<-�e�[�u���P�s������̃o�C�g��
	ADD	HL,BC				;�e�[�u���̃|�C���^�����̍s�ɐi�߂�
	LD	A,(HL)				;�l��00H�ɂȂ�܂ŌJ��Ԃ�
	OR	A				;
	JR	NZ,.L3				;

	LD	HL,MSG_NOT_SUPPORTED_EXT 	;�s��v����
	JP	ERR				;

;=================================================
;[SUB]���͂��ꂽ���������[�N�ɃZ�b�g����
; "������",��1,��2 -> (ARG0),(ARG1),(ARG2),(ARG3)
; ��1,��2,��3�͏ȗ���
;IN  HL=TP
;OUT HL=TP,(ARG0)=������|�C���^,(ARG1~3)=WORD�^,(ARGNUM)=�L����WORD�^�p�����[�^�̐� 0~3
;=================================================
GET_ARGS:
	CALL	RESET_ARGS			;���̓p�����[�^�p���[�N��������
	CALL	STR2ARG0			;(ARG0)<-������|�C���^

	DEC	HL				;�I�d�v�I
	RST	10H				;BASIC���
	LD	A,(HL)				;�J���}��������ΏI������
	CP	","				;
	RET	NZ				;

	CALL	EXP2WORD			;(ARG1)<-���P�̕]������
	LD	(ARG1),DE			;
	CALL	.INC				;(ARGNUM)++
	LD	A,(HL)				;
	CP	","				;
	RET	NZ				;

	CALL	EXP2WORD			;(ARG2)<-���Q�̕]������
	LD	(ARG2),DE			;
	CALL	.INC				;(ARGNUM)++
	LD	A,(HL)				;
	CP	","				;
	RET	NZ				;

	CALL	EXP2WORD			;(ARG2)<-���R�̕]������
	LD	(ARG3),DE			;

.INC:	PUSH	HL				;�L���ȓ��̓p�����[�^�̐����{�P����
	LD	HL,ARGNUM			;
	INC	(HL)				;
	POP	HL				;
	RET					;

;=================================================
;[SUB]�����p���[�N�����Z�b�g����
;IN  -
;OUT (ARG0~ARG3)<-0000H,ARGNUM<-0
;=================================================
RESET_ARGS:
;	PUSH	HL				;
;	LD	HL,0000H			;
;	LD	(ARG0),HL			;
;	LD	(ARG1),HL			;
;	LD	(ARG2),HL			;
;	LD	(ARG3),HL			;
;	XOR	A				;
;	LD	(ARGNUM),A			;
;	POP	HL

	PUSH	HL				;
	LD	B,09H				;
	LD	HL,ARG0				;
	XOR	A				;
.L1:	LD	(HL),A				;
	INC	HL				;
	DJNZ	.L1				;
	POP	HL				;
	RET					;

;=================================================
;[SUB]16�i�����R�[�h�ƍ�
;IN  A=�����R�[�h
;OUT -
;=================================================
IS_HEX:
	PUSH	AF				;
	CALL	CAPITAL				;�啶����
	SUB	"0"				;"0"->0,"9"->9,"A"->17,"F"->22
	JR	C,.ERR				;00H~2FH�����O
	SUB	10				;"A"->7,"F"->12
	JR	C,.EXIT				;"0"~"9"�𒊏o
	SUB	7				;"A"->0,"F"->5
	JR	C,.ERR				;":"~"@"�����O
	SUB	6				;
	JR	C,.EXIT				;"A"~"F"�𒊏o

.ERR:	LD	E,ILLEGAL_FUNCTION_CALL		;
	JP	ERROR				;

.EXIT:	POP	AF				;
	RET					;

;=================================================
;[SUB]�G���[���b�Z�[�W�\��
;IN  HL=���b�Z�[�W�̃A�h���X
;OUT -
;=================================================
ERR:
	CALL	PRINT				;
	CALL	PUT_CR				;
	LD	E,UNPRINTABLE			;
	JP	ERROR				;

;=================================================
;[SUBS]YES / NO ���͑҂�
;IN  HL=���b�Z�[�W�p������̃A�h���X
;OUT Z=1:YES
;=================================================
YES_NO:
	CALL	PRINT				;
	CALL	IPRINT				;
	DB	"? (Y/N)",EOL			;
	CALL	KEYWAIT				;A<-���̓R�[�h
	CALL	CAPITAL				;�啶����
	PUSH	AF				;
	RST	18H				;�G�R�[�o�b�N
	CALL	PUT_CR				;���s
	POP	AF				;
	CP	"Y"				;"Y"�Ȃ�Z<-1
	RET	Z				;

	LD	HL,MSG_CANCELED			;
	CALL	PRINT				;
	OR	A				;Z<-0
	RET					;

;=================================================
;[SUBS]BCD���o�C�i���ɕϊ�����
;IN  A=BCD�l
;OUT A=�o�C�i���l
;=================================================
BCD2BIN:
	PUSH	BC				;A=59H�̏ꍇ
	LD	C,A				;0101.1001B=59H
	AND	11110000B			;0101.0000B=50H
	SRL	A				;0010.1000B=28H=40
	LD	B,A				;B<-40
	SRL	A				;0001.0100B
	SRL	A				;0000.1010B
	SRL	A				;0000.0101B=5
	ADD	A,A				;=10
	ADD	A,B				;A<-A+B=10+40=50
	LD	B,A				;B=50
	LD	A,C				;A=0101.1001B=59H
	AND	00001111B			;A=0000.1001B=09H
	ADD	A,B				;A=A+B=9+50=59
	POP	BC				;
	RET					;

;=================================================
;[SUB]�������\������
;IN  (SP)=������̐擪�A�h���X
;OUT -
;=================================================
IPRINT:
	EX	(SP),HL				;
	PUSH	AF				;
.L1:	LD	A,(HL)				;
	INC	HL				;
	OR	A				;
	JR	Z,.L2				;
	RST	18H				;
	JR	.L1				;
.L2:	POP	AF				;
	EX	(SP),HL				;
	RET					;

;=================================================
;[SUB]16�i����\������
;IN  A
;OUT -
;=================================================
PUTHEX:
	PUSH	DE				;
	CALL	CNVBYTEHEX			;D,E<-����
	LD	A,D				;
	RST	18H				;
	LD	A,E				;
	RST	18H				;
	POP	DE				;
	RET					;

;=================================================
;[SUB]�_�u�����[�h��16�i���ŕ\������
;IN  HL=�_�u�����[�h�̃|�C���^
;OUT 
;=================================================
PRT_DW_HEX:
	PUSH	BC				;
	PUSH	HL				;
	INC	HL				;
	INC	HL				;
	INC	HL				;
	LD	B,04H				;
.L1:	LD	A,(HL)				;
	CALL	PUTHEX				;
	DEC	HL				;
	DJNZ	.L1				;
	POP	HL				;
	POP	BC				;
	RET					;

