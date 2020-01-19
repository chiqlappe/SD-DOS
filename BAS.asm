
;=================================================
;[BAS]BAS�t�@�C���̓ǂݍ���
;IN  (TGT_CLSTR)
;OUT -
;=================================================
READ_BAS:
	CALL	PREP_READ		;

	LD	A,(ARGNUM)		;���̓p�����[�^����0�łȂ���΃G���[��
	AND	A			;
	JR	Z,.L1			;

	LD	E,ILLEGAL_FUNCTION_CALL	;�������s��
	JP	ERROR

.L1:	CALL	IS_INFO_ON		;
	JR	Z,.L4			;
	CALL	IPRINT			;
	DB	"[BAS]",CR,LF,EOL	;

.L4:	LD	HL,(BASBEGIN)		;
	CALL	GET_FIREWALL		;
.L2:	LD	B,BAS_ZERO		;
.L3:	PUSH	BC			;
	CALL	FETCH_1BYTE		;
	LD	(HL),A			;
	POP	BC			;
	CALL	CPHLDE			;OUT OF MEMORY �`�F�b�N
	JR	C,.L5			; HL=�A�h���X
	LD	E,OUT_OF_MEMORY		; DE=���E�l
	JP	ERROR			; HL>=DE�ŃG���[
.L5:	INC	HL			;�]����A�h���X++
	OR	A			;�l��00H�łȂ���΃[���J�E���^�������l�ɖ߂�
	JR	NZ,.L2			;
	DJNZ	.L3			;�l��00H�Ȃ�B�̃J�E���g�_�E���𑱂���

	JP	FIN_READ_BASIC		;


;=================================================
;[BAS]BAS�t�@�C���̏�������
;IN  (TGT_CLSTR)
;OUT -
;=================================================
WRITE_BAS:
	CALL	IS_BASIC		;
	JP	Z,ERR_EMPTY_FILE	;

	CALL	PREP_WRITE		;
	CALL	RAD2RNUM		;BASIC�̍s�A�h���X���s�ԍ��ɕϊ�����I�d�v�I

	LD	A,(ARGNUM)		;���̓p�����[�^����0�łȂ���΃G���[��
	AND	A			;
	JR	Z,.L1			;

	LD	E,ILLEGAL_FUNCTION_CALL	;�������s��
	JP	ERROR

.L1:	CALL	IPRINT			;
	DB	"[BAS]",CR,LF,EOL	;

	LD	DE,(BASBEGIN)		;=�擪�A�h���X
	LD	HL,(VARBEGIN)		;=�I���A�h���X
	PUSH	HL			;
	OR	A			;CY<-0
	SBC	HL,DE			;HL<-�I���A�h���X-�擪�A�h���X
	LD	B,H			;
	LD	C,L			;BC<-�v���O�����̃T�C�Y
	POP	HL			;
	EX	DE,HL			;HL=�擪�A�h���X,DE=�I���A�h���X
.L2:	LD	A,(HL)			;
	CALL	POST_1BYTE		;
	INC	HL			;
	DEC	BC			;
	LD	A,B			;
	OR	C			;
	JR	NZ,.L2			;

	JP	FIN_WRITE		;

