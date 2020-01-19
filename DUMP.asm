
;=================================================
;[DUMP]�f�B���N�g���G���g���̃v���p�e�B��\������
;IN  (DIR_ENTRY)
;OUT 
;=================================================
DUMP_DENT:
	PUSH	HL				;
	CALL	IS_FAT16			;
	LD	HL,DIR_ENTRY			;
	CALL	IPRINT				;
	DB	"NAME  :",EOL			;
	LD	B,DNAME_SIZE			;�t�@�C�����Ɗg���q
.L1:	LD	A,(HL)				;
	INC	HL				;
	RST	18H				;
	DJNZ	.L1				;
	CALL	PUT_CR				;
	CALL	IPRINT				;
	DB	"ATRB  :--",EOL			;
	LD	A,(HL)				;����
	INC	HL				;
	PUSH	HL				;
	PUSH	AF				;
	LD	DE,ATRB_BIT_SYMBL		;DE<-�����V���{��������ւ̃|�C���^
	LD	HL,ATRB				;HL<-�Œ蒷������ATRB�ւ̃|�C���^
	CALL	NULL_STR			;
	POP	AF				;
	SLA	A				;BIT7
	SLA	A				;BIT6
	LD	B,6				;
.L4:	EX	DE,HL				;
	LD	C,(HL)				;C<-(�����V���{��)
	SLA	A				;���V�t�g
	JR	C,.L3				;
.L2:	LD	C,"-"				;
.L3:	EX	DE,HL				;HL=�Œ蒷������ATRB�ւ̃|�C���^
	PUSH	AF				;
	CALL	ADD_STR				;(ATRB)�ɑ����V���{��C��������
	POP	AF				;
	INC	DE				;�����V���{��������ւ̃|�C���^++
	DJNZ	.L4				;
	LD	HL,ATRB				;
	LD	B,(HL)				;
.L5:	INC	HL				;
	LD	A,(HL)				;
	RST	18H				;
	DJNZ	.L5				;
	POP	HL				;
	CALL	PUT_CR				;
	INC	HL				;+0CH
	INC	HL				;+0DH
	CALL	IPRINT				;
	DB	"CREATE:",EOL			;
	LD	E,(HL)				;�쐬���� 0EH,0FH
	INC	HL				;
	LD	D,(HL)				;
	INC	HL				;
	CALL	PRT_FTIME			;
	CALL	PUT_SPC				;
	LD	E,(HL)				;�쐬�� 10H,11H
	INC	HL				;
	LD	D,(HL)				;
	INC	HL				;
	CALL	PRT_FDATE			;
	CALL	PUT_CR				;
	INC	HL				;+12H
	INC	HL				;+13H
	INC	HL				;+14H
	INC	HL				;+15H
	CALL	IPRINT				;
	DB	"UPDATE:",EOL			;
	LD	E,(HL)				;�X�V���� 16H,17H
	INC	HL				;
	LD	D,(HL)				;
	INC	HL				;
	CALL	PRT_FTIME			;
	CALL	PUT_SPC				;
	LD	E,(HL)				;�X�V�� 18H,19H
	INC	HL				;
	LD	D,(HL)				;
	INC	HL				;
	CALL	PRT_FDATE			;
	CALL	PUT_CR				;
	CALL	IPRINT				;
	DB	"FAT   :",EOL			;
	LD	E,(HL)				;FAT�G���g�� 1AH,1BH
	INC	HL				;
	LD	D,(HL)				;
	INC	HL				;
	EX	DE,HL				;
	LD	A,H				;
	OR	L				;
	JR	NZ,.L6				;
	CALL	IPRINT				;
	DB	"N/A",CR,LF,EOL			;
	JR	.L7				;

.L6:	CALL	PRTHLHEX			;
	PUSH	HL				;
	LD	A,"/"				;�Z�N�^��
	RST	18H				;
	CALL	GET_FIRST_SCTR			;(DW0)<-�N���X�^HL�̃Z�N�^��
	LD	HL,DW0				;
	CALL	PRT_DW_HEX			;
	CALL	PUT_CR				;
	POP	HL				;

.L7:	CALL	IPRINT				;
	DB	"DUMP  :",EOL			;
	CALL	DUMP8				;
	CALL	PUT_CR				;

	EX	DE,HL				;
	CALL	IPRINT				;
	DB	"SIZE  :",EOL			;
	CALL	PRT_DW_HEX			;�t�@�C���T�C�Y 1CH,1DH,1EH,1FH
	CALL	PUT_CR				;
	POP	HL				;
	RET					;

ATRB_BIT_SYMBL:					;
	DB	"A","D","V","S","H","R"		;


;=================================================
;[DUMP]�擪�̂W�o�C�g���_���v�o�͂���
;IN  HL=�N���X�^��
;OUT -
;=================================================
DUMP8:
	PUSH	DE				;
	LD	IX,FILE_BFFR_STRCT		;�t�@�C���o�b�t�@���g�p����
	CALL	GET_FIRST_SCTR			;(DW0)<-�N���X�^HL�̊J�n�Z�N�^��
	CALL	LOAD_BFFR			;�Z�N�^(DW0)���o�b�t�@IX�ɓǂݍ���
	LD	L,(IX+IDX_BADR)			;HL<-�o�b�t�@�|�C���^=�o�b�t�@�̐擪�A�h���X
	LD	H,(IX+IDX_BADR+1)		;

	LD	B,08H
.L1:	LD	A,(HL)
	INC	HL
	CALL	PRTAHEX
	LD	A,B
	DEC	A
	JR	Z,.L2
	LD	A,"."
	RST	18H
.L2:	DJNZ	.L1

	POP	DE
	RET

;=================================================
;[DUMP]�t�@�C���̎�ނ�\������
;IN  HL=�N���X�^��
;OUT -
;=================================================
IF FALSE
PRT_FTYPE:
	PUSH	DE				;
	LD	IX,FILE_BFFR_STRCT		;�t�@�C���o�b�t�@���g�p����
	CALL	GET_FIRST_SCTR			;(DW0)<-�N���X�^HL�̊J�n�Z�N�^��
	CALL	LOAD_BFFR			;�Z�N�^(DW0)���o�b�t�@IX�ɓǂݍ���
	LD	L,(IX+IDX_BADR)			;HL<-�o�b�t�@�|�C���^=�o�b�t�@�̐擪�A�h���X
	LD	H,(IX+IDX_BADR+1)		;
	LD	A,(HL)				;
	INC	HL				;
	CP	BAS_MARK			;BASIC�}�[�J�[���H
	JR	Z,.BAS				;
	CP	BIN_MARK			;
	JR	Z,.BIN				;
.UNK:	LD	HL,.MUNK			;
	JR	.L1				;

.BAS:	LD	B,09H				;�w�b�_�[�̎c��X�o�C�g���`�F�b�N
.L2:	LD	A,(HL)				;
	INC	HL				;
	CP	BAS_MARK			;
	JP	NZ,.UNK				;
	DJNZ	.L2				;
	LD	HL,.MBAS			;
.L1:	CALL	PRINT				;
	JR	.EXIT				;

.BIN:	PUSH	HL				;
	LD	HL,.MBIN			;
	CALL	PRINT				;
	POP	HL				;
	LD	D,(HL)				;
	INC	HL				;
	LD	E,(HL)				;
	EX	DE,HL				;
	CALL	PRTHLHEX			;
.EXIT:	POP	DE				;
	RET					;

.MUNK:	DB	"     ",EOL			;
.MBAS:	DB	"BASIC",EOL			;
.MBIN:	DB	"BINARY &H",EOL			;
ENDIF

