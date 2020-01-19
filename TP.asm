
;=================================================
;[TP]�J���}�ŋ�؂�ꂽ�Q�̕����񎮂̃|�C���^���擾����
;IN  HL=TP
;OUT (ARG0)=�P�Ԗڂ̕����񎮂̃|�C���^,(ARG1)=�Q�Ԗڂ̕����񎮂̃|�C���^
;=================================================
GET_2STR_PTR:
	CALL	SKIP_SPC			;
	LD	(ARG0),HL			;
	LD	C,","				;
	CALL	SKIP_CHR			;
	LD	E,MISSING_OPERAND		;
	JP	NC,ERROR			;
	CALL	SKIP_SPC			;
	LD	(ARG1),HL			;
	LD	C,":"				;
	CALL	SKIP_CHR			;
	RET	NC				;
	DEC	HL				;
	RET					;

;=================================================
;[TP]�e�L�X�g�|�C���^�̎���]������16�r�b�g���W�X�^�Ɏ擾����
;�E�l=0000~FFFFH
;IN  HL=TP
;OUT HL=TP,DE=���̌���
;=================================================
EXP2WORD:
	RST	10H				;�I�d�v�I
.SKIP:	CALL	EVALEXP				;FAC<-���̌v�Z����
	PUSH	HL				;TP�ޔ�
	CALL	FAC2INT				;HL<-INT(FAC)
	EX	DE,HL				;
	POP	HL				;TP���A
	RET					;

;=================================================
;[TP]�e�L�X�g�|�C���^�̎���]�����ĂW�r�b�g���W�X�^�Ɏ擾����
;�E�l=00~FFH
;IN  HL=TP
;OUT HL=TP,A=���̌���
;=================================================
IF FALSE

EXP2BYTE:
	RST	10H				;�I�d�v�IBASIC��͖���
	CALL	BYTE_EVALEXP			;A<-���̌v�Z����(0~255)
	RET

ENDIF

;=================================================
;[TP]�e�L�X�g�|�C���^�ȍ~�̕�����ƃR�}���h�e�[�u�����r���āA��v����΃W�����v����
;IN  C=�W�����v�p�C���f�b�N�X�̏����l,DE=�R�}���h�e�[�u���|�C���^,HL=���݂̃e�L�X�g�|�C���^
;OUT HL=���̃e�L�X�g�|�C���^
;=================================================
WORD_JUMP:
	CALL	SKIP_SPC			;
.L1:	PUSH	HL				;TP��ޔ�
	LD	A,(DE)				;������DE�̓R�}���h������̐擪���w���Ă���
	OR	A				;���̒l��00H�Ȃ炷�ׂĕs��v���Ӗ�����̂�
	JR	NZ,.L3				;�G���[���o�͂��ďI��
	LD	E,SYNTAX_ERROR			;
	JP	ERROR				;
.L3:	CP	(HL)				;�R�}���h������TP�̓��e���r
	JR	Z,.EQUAL			;�������Ȃ���Ύ��̃R�}���h�������
.NEXT:	INC	DE				;�R�}���h������00H��������܂�CP��i�߂�
	LD	A,(DE)				;
	OR	A				;
	JR	NZ,.NEXT			;
	INC	DE				;00H�̎��̕����Ƀ|�C���^���Z�b�g����
	INC	C				;�W�����v�p�C���f�b�N�X�l++
	POP	HL				;TP�𕜋A
	JR	.L1				;
.EQUAL:	INC	DE				;�������當�����������ꍇ�̏���
	INC	HL				;TP��CP���P�i�߂�
	LD	A,(DE)				;CP���w�����e��������I�[�}�[�J�[�Ȃ炷�ׂĈ�v�������ƂɂȂ�̂�
	OR	A				;��v�����֐i��
	JR	NZ,.L3				;
	POP	DE				;���������v�����B�X�^�b�N�ɑޔ����Ă���TP���̂Ă�
	PUSH	HL				;���݂�TP��ޔ�
	LD	HL,JUMP_TABLE			;HL<-JUMP_TABLE+C*2=�W�����v��
	SLA	C				;
	LD	B,0				;
	ADD	HL,BC				;
	LD	A,(HL)				;HL<-(HL)=�W�����v��
	INC	HL				;
	LD	H,(HL)				;
	LD	L,A				;
	EX	(SP),HL				;(SP)<-�W�����v��,HL<-���݂�TP
	RET					;�����ŃX�^�b�N����W�����v�悪���o�����

;=================================================
;[TP]TP���J��d���p���̎��ɐi�߂�B���݂��Ȃ���΃G���[�ɂ���
;IN  HL=TP
;OUT HL=TP
;=================================================
OPEN_DQUOTE:
	CALL	SKIP_SPC			;
	LD	A,(HL)				;
	CP	DQUOTE				;
	LD	E,MISSING_OPERAND		;
	JP	NZ,ERROR			;
	INC	HL				;
	RET					;

;=================================================
;[TP]TP���d���p���̎��ɐi�߂�
;IN  HL=TP
;OUT HL=TP
;=================================================
CLOSE_DQUOTE:
	LD	C,DQUOTE			;
	CALL	SKIP_CHR			;
	RET					;

;=================================================
;[TP]�󔒈ȊO�̕����������܂�TP��i�߂�
;IN  HL=TP
;OUT HL=TP,Z<-1
;=================================================
SKIP_SPC:
.L1:	LD	A,(HL)				;
	CP	SPC				;
	RET	NZ				;
	INC	HL				;
	JR	.L1				;

;=================================================
;[TP]�w�肳�ꂽ�����̎��A�܂���00H�܂�TP��i�߂�
;IN  HL=TP,C=�X�L�b�v���镶��
;OUT HL=�V����TP,CY=1:�ړI�̕������������� 0:EOL����������
;=================================================
SKIP_CHR:
.L1:	LD	A,(HL)				;EOL�Ȃ�CY<-0�ŏI��
	OR	A				;
	RET	Z				;
	INC	HL				;TP��i�߂�
	CP	C				;�ړI�̕����Ȃ�CY<-1�ŏI��
	JR	NZ,.L1				;
	SCF					;
	RET					;

