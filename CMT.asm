
;CMT�t�@�C���t�H�[�}�b�g

BIN_MARK: 	EQU	03AH	;CMT�t�@�C���Ŏg�p�����}�V����p�}�[�J�[
BAS_MARK: 	EQU	0D3H	;CMT�t�@�C���Ŏg�p�����BASIC�p�}�[�J�[
BAS_MARK_LEN:	EQU	0AH	;CMT�t�@�C���Ŏg�p�����BASIC�p�}�[�J�[�̐�

;BAS_ZERO:	EQU	04H	;BASIC�t�@�C���̏I�[�𔻒肷�邽�߂�00H�̐�
BAS_ZERO:	EQU	0AH	;BASIC�t�@�C���̏I�[�𔻒肷�邽�߂�00H�̐�

CMT_STACK_LVL:	EQU	40H	;OUT OF MEMORY����p�̃X�^�b�N���x��=���������̒l
BFNAME_SIZE:	EQU	06H	;BASIC�t�@�C�����̒���
;CMT_ZERO:	EQU	10H	;CMT�t�@�C���̏I�[�𔻒肷�邽�߂�00H�̐�

;-------------------------------------------------
;BASIC�v���O�����t�@�C���\��
;-------------------------------------------------
;�w�b�_�[	10 �o�C�g D3 D3 D3 D3 D3 D3 D3 D3 D3 D3 
;�t�@�C����	 6 �o�C�g XX XX XX XX XX XX 
;�v���O�����{��	
;�G���h�}�[�N	 3 �o�C�g 00 00 00
;�t�b�^�[	 9 �o�C�g 00 00 00 00 00 00 00 00 00
;-------------------------------------------------

;-------------------------------------------------
;�}�V����v���O�����t�@�C���\��
;-------------------------------------------------
;�X�^�[�g�A�h���X��	3A hi lo cs
;�f�[�^��		3A nn XX ... XX cs
;�G���h�}�[�N		3A 00 00
;
;hi & lo:�A�h���X, nn:�T�C�Y, cs:�`�F�b�N�T��
;-------------------------------------------------

;=================================================
;[CMT]CMT�t�@�C���̓ǂݍ���
;IN  (TGT_CLSTR)
;OUT -
;=================================================
READ_CMT:
	LD	HL,FKEY_POINTER		;�t�@���N�V�����L�[�̃|�C���^�������� �I�I�[�g�X�^�[�g�΍�I
	LD	(ACTIVE_FKEY),HL	;
	CALL	PREP_READ		;
.LOOP:	CALL	FETCH_1BYTE		;A<-(FP),FP++
	CP	BAS_MARK		;BASIC�}�[�J�[���H
	JR	NZ,.L1			;
	CALL	READ_CMT_BASIC		;
	XOR	A			;A<-0
.L1:	CP	BIN_MARK		;�}�V����}�[�J�[���H
	JR	NZ,.L3			;
	CALL	READ_CMT_BINARY		;
	XOR	A			;A<-0
.L3:	AND	A			;00H�ƃ}�[�J�[�ȊO�̒l�Ȃ�X�L�b�v
	JR	NZ,.L4			;
.L5:	LD	HL,FKEY_FLAG		;�t�@���N�V�����L�[�����t���O�����Ă��Ă��邩
	LD	A,(HL)			;
	OR	A			;
	JR	Z,.L4			;
	CALL	PSEUDO_MON		;�L�[�o�b�t�@�̕������1�s�����^�����j�^���ŏ�������B�Ώۂ�"G"�R�}���h�̂�
.L4:	LD	HL,DIR_ENTRY+IDX_SIZE	;=�t�@�C���T�C�Y�̃|�C���^
	LD	DE,FP			;=FP
	CALL	DW_CP			;FP���t�@�C���T�C�Y�𒴂���܂ŌJ��Ԃ�
	JR	NC,.LOOP		;
	RET

;=================================================
;[CMT]BASIC�t�@�C���̓ǂݍ���
;�E�I������FP��BAS_ZERO�ڂ�00H���w���Ă���
;IN  FP=�t�@�C���|�C���^
;OUT FP
;=================================================
READ_CMT_BASIC:
	LD	B,BAS_MARK_LEN-1	;�w�b�_�[�̎c��X�o�C�g���`�F�b�N
.L4:	CALL	FETCH_1BYTE		;A<-(FP),FP++
	CP	BAS_MARK		;
	JP	NZ,READ_ERR		;
	DJNZ	.L4			;

	LD	HL,INFO_BUF		;
	PUSH	HL			;
	LD	B,BFNAME_SIZE		;=CSAVE���߂ł̃t�@�C�����T�C�Y
.L1:	CALL	FETCH_1BYTE		;A<-(FP),FP++
	LD	(HL),A			;
	INC	HL			;
	DJNZ	.L1			;
	XOR	A			;
	LD	(HL),A			;=EOL
	POP	HL			;
	CALL	IS_INFO_ON		;
	JR	Z,.L9			;

	CALL	IPRINT			;
	DB	"[BAS]",CR,LF		;
	DB	"NAME:",EOL		;
	CALL	PRINT			;
	CALL	PUT_CR			;

.L9:	LD	HL,(BASBEGIN)		;HL<-BASIC�擪�A�h���X
	CALL	GET_FIREWALL		;DE<-�X�^�b�N�G���A�ƃt���[�G���A�̋��E�l
.L2:	LD	B,BAS_ZERO		;=�t�@�C���I���Ɣ��f����00H�̐�(�[���J�E���^)
.L3:	PUSH	BC			;
	CALL	FETCH_1BYTE		;A<-(FP),FP++
	LD	(HL),A			;�������֓]��
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
;[CMT]�}�V����t�@�C���̓ǂݍ���
;IN  FP=�t�@�C���|�C���^
;OUT FP,Z=1:����I��
;=================================================
READ_CMT_BINARY:
	CALL	GET_FIREWALL		;�X�^�b�N�G���A�N���h�~�p�̋��E�l���Z�b�g����
	LD	(FIREWALL),DE		;

	CALL	FETCH_1BYTE		;A<-(FP),FP++
	LD	H,A			;HL<-�}�V����t�@�C���̐擪�A�h���X
	CALL	FETCH_1BYTE		;A<-(FP),FP++
	LD	L,A			;
	CALL	FETCH_1BYTE		;A<-(FP),FP++ �`�F�b�N�o�C�g���͎̂Ă�

	CALL	IS_INFO_ON		;
	JR	Z,.L1			;
	CALL	IPRINT			;
	DB	"[BIN]",CR,LF		;
	DB	"ADDRESS:",EOL		;
	CALL	PRTHLHEX		;�擪�A�h���X��\��

.L1:	CALL	FETCH_1BYTE		;A<-(FP),FP++
	CP	BIN_MARK		;�}�[�J�[�łȂ���΃G���[������
	JP	NZ,READ_ERR		;

	CALL	FETCH_1BYTE		;A<-(FP),FP++
	AND	A			;�f�[�^����0�Ȃ�I����
	JR	Z,.L3			;

	LD	B,A			;B=�f�[�^��
.L2:	PUSH	BC			;
	CALL	FETCH_1BYTE		;�f�[�^�]������
	LD	(HL),A			;
	INC	HL			;
	CALL	CHECK_STACK_AREA	;�X�^�b�N�G���A�ɐN�����Ă��邩�`�F�b�N����
	POP	BC			;
	DJNZ	.L2			;�f�[�^�������J��Ԃ�
	CALL	FETCH_1BYTE		;A<-(FP),FP++ �`�F�b�N�o�C�g���͎̂Ă�
	JR	.L1			;

.L3:	DEC	HL			;

	CALL	IS_INFO_ON		;
	JR	Z,.L5			;
	LD	A,"-"			;�I���A�h���X��\��
	RST	18H			;
	CALL	PRTHLHEX		;
	CALL	PUT_CR			;

.L5:	CALL	FETCH_1BYTE		;FP++
	RET				;

;=================================================
;[CMT]���[�h�G���[
;IN  HL=�A�h���X
;=================================================
READ_ERR:
	CALL	IPRINT			;
	DB	CR,LF,"ERROR IN ",EOL	;
	CALL	PRTHLHEX		;
	CALL	PUT_CR			;
	LD	E,BAD_FILE_DATA		;
	JP	ERROR			;

;=================================================
;[CMT]�X�^�b�N�G���A�N���`�F�b�N
;IN  HL=�Ώۂ̃A�h���X
;OUT 
;=================================================
CHECK_STACK_AREA:
	PUSH	DE
	PUSH	HL

	EX	DE,HL			;DE=�A�h���X
	LD	HL,(FREE_END)		;HL<-�t���[�G���A�̒�
	CALL	CPHLDE			;
	JR	C,.EXIT			;�X�^�b�N�G���A�̒� < �A�h���X

	LD	HL,(FIREWALL)		;HL<-�X�^�b�N�G���A�ƃt���[�G���A�̋��E�l
	CALL	CPHLDE			;
	JR	NC,.EXIT		;�X�^�b�N�G���A�ƃt���[�G���A�̋��E�l >= �A�h���X

.ERR:	XOR	A			;
	LD	(FKEY_FLAG),A		;�I�d�v�I�t�@���N�V�����L�[�����t���O���~�낷
	LD	HL,MSG_MEMORY_CONFLICT	;�X�^�b�N�G���A�N���G���[
	JP	ERR			;

.EXIT:	POP	HL
	POP	DE
	RET

;=================================================
;[CMT]�X�^�b�N�G���A�ƃt���[�G���A�̋��E�l�����߂�
;OUT DE=���E�l
;=================================================
GET_FIREWALL:
	PUSH	HL
	LD	HL,-32
	ADD	HL,SP
	EX	DE,HL
	POP	HL
	RET


;=================================================
;[CMT]�^�����j�^
;�E"G"�R�}���h�̂ݏ������A����ȊO�̃R�}���h�͖��������
;�E�v���O����������R�[�����ꂽ�ꍇ�͏������s��Ȃ��IF5�L�[�Ŏ��s�����ꍇ�A�K��F�L�[�����t���O�������Ă��܂����߁I
;=================================================
PSEUDO_MON:
	LD	HL,(EXECLINENUM)	;=���ݎ��s���̍s�ԍ�
	INC	HL			;��~����0FFFFH�Ȃ̂ŁA�P������Z�t���O�������Ŕ��ʂ��Ă���
	LD	A,H			;
	OR	L			;
	RET	NZ			;�v���O��������Ă΂ꂽ�ꍇ�͏������Ȃ��Ŗ߂�

.L1:	CALL	KEYWAIT			;A<-�L�[���͂��ꂽ����
	CALL	CAPITAL			;�啶����
	CP	CR			;
	JR	Z,.EXIT			;
	CP	"G"			;
	JR	NZ,.L1			;
	CALL	.SUB			;16�i�R�[�h DE��16�i A
	LD	H,A
	CALL	.SUB
	LD	L,A			;HL<-�W�����v�A�h���X
	CALL	KEYWAIT			;���s��ǂݎ̂Ă�

	POP	BC			;->READ_CMT	�߂�A�h���X���̂Ă�
	POP	BC			;->PUSH BC	�X�^�b�N���̂Ă�
	POP	BC			;->LOAD		�߂�A�h���X���̂Ă�
	JP	(HL)			;G�R�}���h���s

.EXIT:	RET

.SUB:	CALL	KEYWAIT			;
	LD	D,A			;
	CALL	KEYWAIT			;
	LD	E,A			;
	CALL	CNVHEXBYTE		;16�i�R�[�h DE��16�i A
	RET

;=================================================
;[CMT]CMT�t�@�C���̏�������
;IN  (TGT_CLSTR),(ARG0),(ARG1),(ARG2)
;OUT 
;=================================================
WRITE_CMT:
	CALL	PREP_WRITE

.MERGE:					;MERGE�̃G���g���|�C���g
	LD	HL,.RET			;�I�d�v�I�߂�A�h���X���X�^�b�N�ɃZ�b�g����
	PUSH	HL			;

	LD	A,(ARGNUM)		;A<-���̓p�����[�^��
	AND	A			;���̓p�����[�^����0�Ȃ�BASIC�Z�[�u��
	JR	Z,WRITE_CMT_BASIC	;

	DEC	A			;���̓p�����[�^����1�Ȃ�G���[��
	JR	Z,.ERR			;

;	LD	DE,(ARG1)		;=�J�n�A�h���X
;	LD	HL,(ARG2)		;=�I���A�h���X
;	CALL	CPHLDE			;�I���A�h���X-�J�n�A�h���X
;	JR	Z,.ERR			;�I���A�h���X=�J�n�A�h���X�H
;	JR	NC,WRITE_CMT_BINARY	;�I���A�h���X>�J�n�A�h���X�H

	LD	DE,(ARG1)		;=�J�n�A�h���X
	LD	HL,(ARG2)		;=�I���A�h���X
	CALL	CPHLDE			;�I���A�h���X-�J�n�A�h���X
	JR	NC,WRITE_CMT_BINARY	;�I���A�h���X���A�J�n�A�h���X��菬������΃G���[

.ERR:	LD	E,ILLEGAL_FUNCTION_CALL	;�������s��
	JP	ERROR

.RET:	JP	FIN_WRITE

;=================================================
;[CMT]��������BASIC�v���O���������݂��邩
;IN  -
;OUT Z=1:�v���O�����Ȃ�
;=================================================
IS_BASIC:
	PUSH	HL			;
	LD	HL,(BASBEGIN)		;�J�n�Q�o�C�g��00H�Ȃ��Ƃ݂Ȃ�
	LD	A,(HL)			;
	INC	HL			;
	OR	(HL)			;
	POP	HL			;
	RET

;=================================================
;[CMT]BASIC�t�@�C���̏�������
;=================================================
WRITE_CMT_BASIC:
	CALL	IS_BASIC		;
	JP	Z,ERR_EMPTY_FILE	;

	CALL	RAD2RNUM		;BASIC�̍s�A�h���X���s�ԍ��ɕϊ�����I�d�v�I
	CALL	IPRINT			;
	DB	"[BAS]",CR,LF,EOL	;

	LD	B,BAS_MARK_LEN		;�w�b�_
.HEADR:	LD	A,BAS_MARK		;
	CALL	POST_1BYTE		;
	DJNZ	.HEADR			;

	CALL	IPRINT			;�t�@�C����
	DB	"NAME:",EOL		;

	LD	HL,DIR_ENTRY		;
	LD	B,BFNAME_SIZE		;
.FNAME:	LD	A,(HL)			;
	RST	18H			;
	CP	SPC			;�t�@�C������20H��00H�ɕϊ�����
	JR	NZ,.L1			;
	XOR	A			;
.L1:	CALL	POST_1BYTE		;
	INC	HL			;
	DJNZ	.FNAME			;
	CALL	PUT_CR			;

	LD	DE,(BASBEGIN)		;=�擪�A�h���X
	LD	HL,(VARBEGIN)		;=�I���A�h���X
	PUSH	HL			;
	OR	A			;CY<-0
	SBC	HL,DE			;HL<-�I���A�h���X-�擪�A�h���X
	LD	B,H			;
	LD	C,L			;BC<-�v���O�����̃T�C�Y
	POP	HL			;
	EX	DE,HL			;HL=�擪�A�h���X,DE=�I���A�h���X

.DATA:	LD	A,(HL)			;�v���O�����f�[�^��
	CALL	POST_1BYTE		;
	INC	HL			;
	DEC	BC			;
	LD	A,B			;
	OR	C			;
	JR	NZ,.DATA		;

	LD	B,9			;�t�b�^��
.FOOTR:	XOR	A			;
	CALL	POST_1BYTE		;
	DJNZ	.FOOTR			;

	RET

;=================================================
;[CMT]�}�V����t�@�C���̏�������
;IN  DE=�擪�A�h���X,HL=�I���A�h���X
;OUT 
;=================================================
WRITE_CMT_BINARY:
	CALL	PRT_WRITE_BIN_INFO	;

	INC	HL			;�I�d�v�I�f�[�^���v�Z�̕֋X��A�I���A�h���X�ɂP�����Ă���
	LD	A,BIN_MARK		;�擪�}�[�J�[��
	CALL	POST_1BYTE		;

	LD	A,D			;�擪�A�h���X��
	CALL	POST_1BYTE		;
	LD	A,E			;
	CALL	POST_1BYTE		;

	LD	A,D			;�`�F�b�N�T���v�Z
	ADD	A,E			;
	CPL				;
	INC	A			;
	CALL	POST_1BYTE		;�`�F�b�N�T����

.L2:	LD	A,BIN_MARK		;�}�[�J�[��
	CALL	POST_1BYTE		;

	CALL	CPHLDE			;
	JR	Z,.EXIT			;�擪�A�h���X=(�I���A�h���X+1)�Ȃ�I��

	PUSH	HL			;�I���A�h���X�ޔ�
	LD	B,0FFH			;�u���b�N���f�[�^�̍ő�l 255
	OR	A			;CY<-0
	SBC	HL,DE			;HL<-�I���A�h���X-�擪�A�h���X
	LD	A,H			;H>0�Ȃ�B<-0FFH
	OR	A			;H=0�Ȃ�B<-L
	JR	NZ,.L3			;
	LD	B,L			;
.L3:	LD	A,B			;
	CALL	POST_1BYTE		;�u���b�N�T�C�Y��
	POP	HL			;�I���A�h���X���A

	EX	DE,HL			;HL=�擪�A�h���X,DE=�I���A�h���X
	LD	C,B			;C<-�T�C�Y �`�F�b�N�T���p

.L1:	LD	A,(HL)			;A<-(�擪�A�h���X)
	PUSH	AF			;
	CALL	POST_1BYTE		;�f�[�^��
	POP	AF			;

	ADD	A,C			;�f�[�^�u���b�N�̃`�F�b�N�T�����v�Z
	LD	C,A			;C<-C+A

	INC	HL			;�擪�A�h���X++
	DJNZ	.L1			;

	EX	DE,HL			;DE=�擪�A�h���X,HL=�I���A�h���X
	LD	A,C			;A<-�`�F�b�N�T��
	NEG				;�����𔽓]
	CALL	POST_1BYTE		;�`�F�b�N�T����
	JR	.L2			;

.EXIT:	XOR	A			;
	CALL	POST_1BYTE		;�I���}�[�J 00H,00H
	XOR	A			;
	CALL	POST_1BYTE		;

	RET

;=================================================
;�ǂݍ��݂̑O����
;=================================================
PREP_READ:
	XOR	A			;�R�[���o�b�N�t���O���~�낷
	LD	(IS_CALLBACK),A		;
	LD	HL,(TGT_CLSTR)		;HL<-�t�@�C���̊J�n�N���X�^��
	CALL	INIT_FP			;�t�@�C���|�C���^������
	LD	IX,FILE_BFFR_STRCT	;IX<-�t�@�C���o�b�t�@�\���̂̃|�C���^
	CALL	READ_FP_SCTR		;FP�������Z�N�^��IX�o�b�t�@�\���̂ɓǂݍ���
	RET

;=================================================
;BASIC�ǂݍ��݂̌㏈��
;=================================================
FIN_READ_BASIC:
	LD	(VARBEGIN),HL		;BASIC�I���A�h���X���Z�b�g
	LD	(ARRBEGIN),HL		;
	LD	(FREBEGIN),HL		;
	CALL	PRGFIT			;
	RET

;=================================================
;�������݂̑O����
;=================================================
PREP_WRITE:
	LD	HL,(TGT_CLSTR)		;
	CALL	INIT_FP			;
	CALL	ERASE_FAT_LINK		;
	LD	IX,FILE_BFFR_STRCT	;
	CALL	CLR_BFFR		;

	CALL	FP2SCTR			;(DW0)<-FP�̃Z�N�^��
	LD	HL,DW0			;�o�b�t�@�̃Z�N�^���<-(DW0)
	PUSH	IX			;
	POP	DE			;
	CALL	DW_COPY			;

	RET

;=================================================
;�������݂̌㏈��
;=================================================
FIN_WRITE:
	LD	HL,FP			;�t�@�C���T�C�Y���f�B���N�g���G���g���ɃZ�b�g����
	LD	DE,DIR_ENTRY+IDX_SIZE	;
	CALL	DW_COPY			;
	LD	HL,(FP_CLSTR)		;HL<-�ŏI�N���X�^��
	LD	DE,0FFFFH		;�ŏI�N���X�^��FAT�G���g����FFFFH����������
	CALL	WRITE_FAT_DATA		;
	CALL	FLUSH_BFFR		;�t�@�C���o�b�t�@��FAT1,2�o�b�t�@�����f�B�A�ɏ�������
	RET

;=================================================
;�@�B�ꏑ�����ݏ��\��
;IN  DE=�J�n�A�h���X,HL=�I���A�h���X
;=================================================
PRT_WRITE_BIN_INFO:
	CALL	IPRINT			;
	DB	"[BIN]",CR,LF		;
	DB	"ADDRESS:",EOL		;
	PUSH	DE			;
	PUSH	HL			;
	EX	DE,HL			;
	CALL	PRTHLHEX		;
	LD	A,"-"			;
	RST	18H			;

	EX	DE,HL			;
	CALL	PRTHLHEX		;
	CALL	PUT_CR			;
	POP	HL			;
	POP	DE			;
	RET





