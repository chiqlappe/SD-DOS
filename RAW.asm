;=================================================
;[RAW]�C�ӂ̃t�@�C���ǂݍ���
;IN  (ARG1)=�J�n�A�h���X
;OUT -
;=================================================
READ_RAW:
	CALL	PREP_READ		;
	CALL	GET_FIREWALL		;
	LD	A,(ARGNUM)		;
	DEC	A			;
	LD	E,ILLEGAL_FUNCTION_CALL	;�������s��
	JP	NZ,ERROR		;

	LD	HL,DIR_ENTRY+IDX_SIZE	;
	LD	C,(HL)			;DE=�t�@�C���T�C�Y�̉��ʂQ�o�C�g
	INC	HL			;
	LD	B,(HL)			;
	INC	HL			;
	LD	E,(HL)			;BC=�t�@�C���T�C�Y�̏�ʂQ�o�C�g
	INC	HL			;
	LD	D,(HL)			;

	LD	A,E			;�t�@�C���T�C�Y��10000H�ȏ�Ȃ�G���[
	OR	D			;
	JR	Z,.L1			;
.ERR:	LD	E,OUT_OF_MEMORY		;
	JP	ERROR			;

.L1:	LD	HL,(ARG1)		;HL=�J�n�A�h���X
	PUSH	HL
	LD	E,C			;DE=�t�@�C���T�C�Y
	LD	D,B			;
	EX	DE,HL			;DE=�J�n�A�h���X
	ADD	HL,DE			;
	DEC	HL			;HL=�I���A�h���X

	CALL	IS_INFO_ON		;
	JR	Z,.L2			;

	CALL	IPRINT			;
	DB	"[RAW]",CR,LF,EOL	;
	EX	DE,HL
	CALL	PRTHLHEX		;�J�n�A�h���X��\��
	LD	A,"-"			;
	RST	18H			;
	EX	DE,HL			;
	CALL	PRTHLHEX		;�I���A�h���X��\��
	CALL	PUT_CR			;

.L2:	CALL	IS_SAFE_ZONE		;�Z�[�t�]�[���`�F�b�N
	POP	HL			;HL=�J�n�A�h���X

.LOOP:	CALL	FETCH_1BYTE		;�������ɏ�������
	LD	(HL),A			;
	INC	HL			;
	DEC	BC			;�c��T�C�Y--
	LD	A,B			;
	OR	C			;
	JR	NZ,.LOOP		;

	RET				;
