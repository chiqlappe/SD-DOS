
;=================================================
;[BIN]�Z�[�t�]�[���`�F�b�N
;DE~HL�̃A�h���X�̈悪�X�^�b�N�̈��Ƃ��Ă��Ȃ����`�F�b�N����
;�t���[�G���A�̒ꁃ�J�n�A�h���X �܂��� �I���A�h���X�����E�l �ł���΃Z�[�t
;IN  DE=�J�n�A�h���X,HL=�I���A�h���X
;OUT -
;=================================================
IS_SAFE_ZONE:
	PUSH	HL
	LD	HL,(FREE_END)		;HL<-�t���[�G���A�̒�
	CALL	CPHLDE			;�t���[�G���A�̒�-�J�n�A�h���X
	POP	HL			;HL=�I���A�h���X
	RET	C			;�t���[�G���A�̒�<�J�n�A�h���X

	PUSH	DE			;
	LD	DE,(FIREWALL)		;DE<-�X�^�b�N�G���A�ƃt���[�G���A�̋��E�l
	CALL	CPHLDE			;�I���A�h���X-���E�l
	POP	DE			;DE=�J�n�A�h���X
	RET	C			;���E�l>�I���A�h���X

	JP	CHECK_STACK_AREA.ERR	;�G���[

;=================================================
;[BIN]�o�C�i���t�@�C���̓ǂݍ���
;IN  (TGT_CLSTR),(ARG0),(ARG1)=�V�����J�n�A�h���X<�ȗ���>
;OUT -
;=================================================
READ_BIN:
	CALL	PREP_READ		;
	CALL	GET_FIREWALL		;
	LD	(FIREWALL),DE		;

	CALL	FETCH_1BYTE		;
	LD	L,A			;HL<-�}�V����t�@�C���̊J�n�A�h���X
	CALL	FETCH_1BYTE		;
	LD	H,A			;
	CALL	FETCH_1BYTE		;
	LD	E,A			;DE<-�}�V����t�@�C���̏I���A�h���X
	CALL	FETCH_1BYTE		;
	LD	D,A			;
	CALL	FETCH_1BYTE		;
	LD	C,A			;BC<-�}�V����t�@�C���̎��s�A�h���X
	CALL	FETCH_1BYTE		;
	LD	B,A			;
	LD	(EXECADR),BC		;���s�A�h���X���Z�b�g

	CALL	IS_INFO_ON		;�t�@�C�������o��
	JR	Z,.L6			;
	PUSH	DE			;=�I���A�h���X
	PUSH	HL			;=�J�n�A�h���X
	CALL	IPRINT			;
	DB	"[BIN]",CR,LF		;
	DB	"ADDRESS:",EOL		;
	CALL	PRTHLHEX		;�J�n�A�h���X��\��
	LD	A,"-"			;
	RST	18H			;
	EX	DE,HL			;
	CALL	PRTHLHEX		;�I���A�h���X��\��
	LD	H,B			;
	LD	L,C			;
	LD	A,H			;
	OR	L			;
	JR	Z,.L10			;
	LD	A,":"			;���s�A�h���X���o��
	RST	18H			;
	CALL	PRTHLHEX		;
	CALL	PUT_CR			;
.L10:	POP	HL			;HL<-�J�n�A�h���X
	POP	DE			;DE<-�I���A�h���X

.L6:	EX	DE,HL			;DE=�J�n�A�h���X,HL=�I���A�h���X
	CALL	CPHLDE			;�I���A�h���X���A�J�n�A�h���X��菬������΃G���[
	JR	NC,.L5			;
	LD	E,BAD_FILE_DATA		;
	JP	ERROR			;

.L5:	CALL	IS_SAFE_ZONE		;�Z�[�t�]�[���`�F�b�N
	OR	A			;CY<-0
	SBC	HL,DE			;HL<-�I���A�h���X-�J�n�A�h���X
	LD	B,H			;
	LD	C,L			;
	INC	BC			;BC<-�t�@�C���T�C�Y
	LD	H,D			;HL<-DE=�J�n�A�h���X
	LD	L,E			;

	LD	A,(ARGNUM)		;A<-���̓p�����[�^��
	AND	A			;���̓p�����[�^����0�Ȃ�.L2��
	JR	Z,.L2

	LD	HL,(ARG1)		;HL<-�V�����J�n�A�h���X
	CP	1			;���̓p�����[�^����1�Ȃ�.L2��
	JR	Z,.L2

	INC	HL			;(ARG1)��0FFFFH���H
	LD	A,H			;
	OR	L			;
	JR	Z,.L9			;
	LD	E,ILLEGAL_FUNCTION_CALL	;�������s��
	JP	ERROR			;

.L9:	LD	H,D			;HL<-�J�n�A�h���X
	LD	L,E			;
	LD	A,TRUE			;�R�[���o�b�N�t���O�𗧂Ă�
	LD	(IS_CALLBACK),A		;
	LD	DE,(ARG2)		;�R�[���o�b�N�A�h���X���Z�b�g
	LD	(CALLBACK),DE		;

.L2:	LD	DE,CB_BYTES		;=�R�[���o�b�N�^�C�~���O�J�E���^

.LOOP:	CALL	FETCH_1BYTE		;�������ɏ�������
	LD	(HL),A			;
	INC	HL			;

.L1:	LD	A,(IS_CALLBACK)		;
	AND	A			;
	JR	Z,.L8			;

	DEC	DE			;�R�[���o�b�N�^�C�~���O�J�E���^�����炷
	LD	A,D			;
	OR	E			;
	JR	NZ,.L8			;
	PUSH	HL			;
	LD	HL,.RET			;�߂��A�h���X���X�^�b�N�ɐς�
	PUSH	HL			;
	LD	HL,(CALLBACK)		;
	JP	(HL)			;
.RET:	LD	DE,CB_BYTES		;�R�[���o�b�N�^�C�~���O�J�E���^�����Z�b�g����
	POP	HL			;

.L8:	DEC	BC			;�c��T�C�Y--
	LD	A,B			;
	OR	C			;
	JR	NZ,.LOOP		;

.L7:	LD	HL,(EXECADR)		;HL<-���s�A�h���X
	LD	A,L			;���s�A�h���X��0000H�Ȃ�I����
	OR	H			;
	JR	Z,.L3			;

	LD	A,(EXECFLG)		;�t���O�������Ă�����@�B��v���O���������s����
	AND	A			;
	JR	Z,.L3			;
	XOR	A			;�t���O���~�낷
	LD	(EXECFLG),A		;
	JR	EXECUTE			;���s

.L3:	RET				;

;=================================================
;�@�B��v���O���������s����
; IN	(EXECADR)
;=================================================
EXECUTE:
	CALL	CLS
	LD	DE,0FE40H	;VRAM
	LD	HL,.L1
	LD	BC,5
	LDIR			; VRAM <- FUNCTION KEY DATA
	PUSH	DE
	LD	A,(EXECADR+1)
	CALL	CNVBYTEHEX
	POP	HL
	LD	(HL),D
	INC	HL
	LD	(HL),E
	INC	HL
	LD	A,(EXECADR)
	CALL	CNVBYTEHEX
	LD	(HL),D
	INC	HL
	LD	(HL),E
	INC	HL
	LD	(HL),0DH
	INC	HL
	LD	(HL),0

	LD	A,1
	LD	(FKEY_FLAG),A
	LD	HL,0FE40H
	LD	(ACTIVE_FKEY),HL
	JP	BASIC

.L1:	DB	"MON",CR,"G"


;=================================================
;[BIN]�o�C�i���t�@�C���̏�������
;IN  (TGT_CLSTR),(ARG0),(ARG1)=�J�n�A�h���X,(ARG2)=�I���A�h���X,(ARG3)=���s�A�h���X<�ȗ���>
;OUT -
;=================================================
WRITE_BIN:
	CALL	PREP_WRITE		;

	LD	A,(ARGNUM)		;���̓p�����[�^����2�����Ȃ�G���[��
	CP	2			;
	JR	C,.ERR			;

	LD	DE,(ARG1)		;DE<-�J�n�A�h���X
	LD	HL,(ARG2)		;HL<-�I���A�h���X
	PUSH	HL			;
	INC	HL			;�T�C�Y�Z�o�p�ɂP�����Z
	OR	A			;
	SBC	HL,DE			;
	LD	B,H			;BC<-�T�C�Y
	LD	C,L			;
	POP	HL			;
	JR	Z,.ERR			;�T�C�Y���O�Ȃ�G���[
	JR	NC,.L1			;�T�C�Y�����̐��Ȃ�.L1��

.ERR:	LD	E,ILLEGAL_FUNCTION_CALL	;�������s��
	JP	ERROR			;

.L1:	PUSH	BC			;�T�C�Y��ޔ�

	CALL	PRT_WRITE_BIN_INFO	;
	EX	DE,HL			;HL=�J�n�A�h���X,DE=�I���A�h���X
	LD	A,L			;�J�n�A�h���X��
	CALL	POST_1BYTE		;
	LD	A,H			;
	CALL	POST_1BYTE		;

	LD	A,E			;�I���A�h���X��
	CALL	POST_1BYTE		;
	LD	A,D			;
	CALL	POST_1BYTE		;

	PUSH	HL			;
	LD	HL,(ARG3)		;
	LD	A,L			;���s�A�h���X��
	CALL	POST_1BYTE		;
	LD	A,H			;
	CALL	POST_1BYTE		;
	POP	HL			;

	POP	BC			;�T�C�Y�𕜋A
.L2:	LD	A,(HL)			;
	CALL	POST_1BYTE		;
	INC	HL			;
	DEC	BC			;
	LD	A,B			;
	OR	C			;
	JR	NZ,.L2			;

	JP	FIN_WRITE		;


