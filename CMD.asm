
;=================================================
;[CMD]CMD����
;=================================================
CMD:
	LD	C,00H				;�W�����v�p�C���f�b�N�X�̏����l
	LD	DE,CMD_TABLE			;�R�}���h�e�[�u���|�C���^(CP)�̏����l
	JP	WORD_JUMP			;

;=================================================
;[CMD]CMD V ���� "VALID" DOS�v���O�����̃`�F�b�N�T�����o�͂���
;=================================================
CMD_V:
	PUSH	HL
	OR	A				;
	LD	HL,WORK_AREA			;
	LD	DE,6000H			;
	PUSH	DE				;
	SBC	HL,DE				;
	LD	B,H				;
	LD	C,L				;BC<-DOS�v���O�����S�̂̃o�C�g��
	POP	HL				;HL<-6000H
	LD	DE,0000H			;=�`�F�b�N�T��
.L1:	LD	A,(HL)				;
	ADD	A,E				;
	LD	E,A				;
	LD	A,D				;
	ADC	A,00H				;DE+=(HL)
	LD	D,A				;
	INC	HL				;
	DEC	BC				;
	LD	A,B				;
	OR	C				;
	JR	NZ,.L1				;

	CALL	PUT_CR
	LD	H,D
	LD	L,E
	CALL	PRTHLHEX
	CALL	PUT_CR

	JP	CLOSE_CMD

;=================================================
;[CMD]CMD F ���� "FREE"	�t���[�G���A���g������
;=================================================
CMD_F:
	LD	HL,FREE_AREA
	JP	SETFREADR

;=================================================
;[CMD]CMD P ���� "PROPERTY"	�f�B���N�g���G���g���̃v���p�e�B�\��
;=================================================
CMD_P:
	CALL	STR2ARG0			;
	PUSH	HL				;
	CALL	IS_FAT16			;
	CALL	CHANGE_WDIR			;HL<-�G���g�����̐擪�A�h���X
	LD	C,00H				;=�S����
	CALL	GET_DENT			;
	JP	Z,ERR_NOT_FOUND			;
	CALL	DUMP_DENT			;���C�����[�`��
	CALL	RESTORE_WDIR			;
	JP	CLOSE_CMD

;=================================================
;[CMD]CMD ON ���� "INFO ON"	�C���t�H���[�V������\������
;=================================================
CMD_ON:
	LD	A,TRUE

INFO:	PUSH	HL
	LD	(INFO_SW),A
	INC	A
	JR	NZ,.L1
	CALL	IPRINT
	DB	"INFO ON",CR,LF,EOL
.L1:	JP	CLOSE_CMD


;=================================================
;[CMD]CMD OFF ���� "INFO OFF"
;=================================================
CMD_OFF:
	LD	A,FALSE
	JR	INFO

;=================================================
;[CMD]CMD R ���� "RUN" ���s�t���O�𗧂Ăă��[�h����
;=================================================
CMD_R:
	LD	A,TRUE				;���s�t���O�𗧂Ă�
	LD	(EXECFLG),A			;
	CALL	RESET_ARGS			;���̓p�����[�^�𖳌��ɂ���
	CALL	STR2ARG0			;
	CALL	LOAD.E1				;

	LD	A,(EXECFLG)
	AND	A
	RET	Z
	JP	RUN


;=================================================
;[CMD]RBYTE���� �C�ӂ̃o�C�i���t�@�C�����������ɓǂݍ���
;=================================================
RBYTE:
	CALL	GET_ARGS			;
	PUSH	HL				;
	CALL	IS_FAT16			;
	CALL	CHANGE_WDIR			;
	CALL	DNAME2CLSTR			;
	CALL	READ_RAW
	CALL	RESTORE_WDIR			;
	JP	CLOSE_CMD			;

;=================================================
;[CMD]LOAD���� �t�@�C�����������ɓǂݍ���
;=================================================
LOAD:
	XOR	A				;���s�t���O���~�낷
	LD	(EXECFLG),A			;
	CALL	GET_ARGS			;

.E1:	PUSH	HL				;CMD R�̃G���g���|�C���g
	CALL	IS_FAT16			;
	CALL	CHANGE_WDIR			;
	CALL	DNAME2CLSTR			;
	LD	HL,EXT_LOAD_TABLE		;
	CALL	EXT_TABLE_JUMP			;�g���q�ɑΉ��������[�h���[�`���փW�����v����
	CALL	RESTORE_WDIR			;
	JP	CLOSE_CMD			;

;=================================================
;[CMD]SAVE���� ���������e���t�@�C���ɏ�������
;=================================================
SAVE:
	CALL	GET_ARGS			;(ARG0)=�t�@�C���p�X�{�t�@�C�����̊i�[�A�h���X�A(ARG1)=�擪�A�h���X,(ARG2)=�I���A�h���X
	PUSH	HL				;
	CALL	IS_FAT16			;
	LD	C,ATRB_FILE			;
	CALL	PREP_DENT			;
	CALL	IS_READ_ONLY			;
	LD	HL,EXT_SAVE_TABLE		;
	CALL	EXT_TABLE_JUMP			;�g���q�ɑΉ������Z�[�u���[�`���փW�����v����
	CALL	WRITE_DENT			;
	CALL	RESTORE_WDIR			;
	JP	CLOSE_CMD			;

;=================================================
;[CMD] �t�@�C���p�X�Ŏw�肳�ꂽ�f�B���N�g���ɃG���g�����쐬����
;IN  (ARG0)=�t�@�C���p�X�{�G���g����,C=�쐬����G���g���̑���
;OUT (ARG0)=�G���g�����̐擪�A�h���X
;=================================================
PREP_DENT:
	PUSH	BC				;
	CALL	CHANGE_WDIR			;
	LD	(ARG0),HL			;
	POP	BC				;
	CALL 	TOUCH				;
	CALL	SET_DENT_FAT			;
	RET

;=================================================
;[CMD]POLL���� ���[�L���O�f�B���N�g����ύX����
;=================================================
POLL:
	CALL	STR2BUFF			;
	PUSH	HL				;
	CALL	IS_FAT16			;
	LD	HL,STR_BUFF			;
	CALL	TRACE_PATH			;
	JP	CLOSE_CMD			;

;=================================================
;[CMD]KILL���� �t�@�C�����폜����
;=================================================
KILL:
	CALL	STR2ARG0			;
	PUSH	HL				;
	CALL	IS_FAT16			;
	LD	HL,MSG_KILL_FILE		;
	CALL	YES_NO				;
	JR	NZ,.EXIT			;
	CALL	CHANGE_WDIR			;
.L1:	LD	C,ATRB_FILE			;
	CALL	GET_DENT			;
	JP	Z,ERR_NOT_FOUND
	CALL	IS_READ_ONLY			;
	LD	HL,(DIR_ENTRY+IDX_FAT)		;
	LD	A,H				;FAT�G���g����0000H�Ȃ�f�B���N�g���G���g���̂ݍ폜����
	OR	L				;����ȊO��
	CALL	NZ,ERASE_FAT_LINK		;FAT�����N������ׂď�������
.DIR:	LD	HL,DIR_ENTRY			;�f�B���N�g���G���g���o�b�t�@�̐擪��0E5H���Z�b�g����
	LD	(HL),ID_DISABLED		;����ɂ��f�B���N�g���G���g���������ɂȂ�
	CALL	WRITE_DENT			;�f�B���N�g���G���g���o�b�t�@���t�@�C���o�b�t�@�ɃR�s�[����
	CALL	FLUSH_BFFR			;�S�o�b�t�@��������
	CALL	RESTORE_WDIR			;
.EXIT:	JP	CLOSE_CMD

;=================================================
;[CMD]MOUNT���� SD�J�[�h�̃v���C�}���p�[�e�B�V�������}�E���g����
;=================================================
MOUNT:
	PUSH	HL
	CALL	INIT_8255			;PPI������
	CALL	MMC_INIT			;MMC������
	CALL	READ_MBR			;�p�[�e�B�V�����J�n�Z�N�^�����Z�b�g����
	CALL	READ_IPL			;FAT16�t�H�[�}�b�g�`�F�b�N
	CALL	READ_BPB			;BPB��񂩂瓱�����萔�����[�N�ɃZ�b�g����
	CALL	INIT_FAT16			;FAT16�֘A���[�N�������I�o�b�t�@�N���A�̂��ߕK���Ō�Ɏ��s����I
	CALL	PRT_VOLUME			;�{�����[�����\��
;	CALL	IS_YEAR79			;���t�������͂Ȃ烁�b�Z�[�W���o��
	POP	HL				;
	CALL	AUTOEXEC			;
	RET					;

;=================================================
;[CMD]FILES���� �w�肳�ꂽ�f�B���N�g���̃G���g���ꗗ��\������
;=================================================
FILES:
	CP	":"				;
	JR	Z,.L1				;
	OR	A				;
	JR	Z,.L1				;
	CALL	POLL				;
.L1:	PUSH	HL				;
	CALL	IS_FAT16			;
	LD	HL,(WDIR_CLSTR)			;
	LD	IY,PRT_DENT			;
	CALL	DIR_WALK			;
	POP	HL				;
	RET					;

;=================================================
;[CMD]MERGE���� �������̓��e��CMT�t�@�C���ɒǋL����
;=================================================
MERGE:
	CALL	GET_ARGS			;
	PUSH	HL				;
	CALL	IS_FAT16			;
	CALL	CHANGE_WDIR			;
	LD	C,ATRB_FILE			;
	CALL	GET_DENT			;
	JP	Z,ERR_NOT_FOUND			;
	CALL	IS_READ_ONLY			;
	CALL	SET_FP_END			;FP���t�@�C���I�[�ɃZ�b�g����
	CALL	WRITE_CMT.MERGE			;CMT�t�@�C���̒ǋL���s
	CALL	WRITE_DENT			;
	CALL	RESTORE_WDIR			;
	POP	HL				;
	RET					;

;=================================================
;[CMD]NAME���� �f�B���N�g���G���g������ύX����
;=================================================
NAME:
	CALL	GET_2STR_ARGS			;�Q�̕�����̐擪�A�h���X�������ɃZ�b�g����
	PUSH	HL				;
	CALL	IS_FAT16			;
	CALL	CHANGE_WDIR			;
	LD	(ARG0),HL			;
	LD	HL,(ARG1)			;
	PUSH	HL				;�V�����G���g������ޔ�
	LD	C,00H				;
	CALL	GET_DENT			;
	JP	NZ,ERR_EXISTS			;���݂��Ă���΃G���[
	LD	HL,(ARG0)			;HL<-���݂̃G���g�����̐擪�A�h���X
	LD	C,00H				;
	CALL	GET_DENT			;
	JP	Z,ERR_NOT_FOUND			;���݂��Ȃ���΃G���[
	CALL	IS_READ_ONLY			;
	POP	HL				;�V�����G���g�����𕜋A
	CALL	STR2SFN				;���݂̃f�B���N�g���G���g������V�����G���g�����ŏ㏑������
	LD	HL,DIR_ENTRY+IDX_TIME		;�f�B���N�g���G���g���o�b�t�@�́u�X�V�����v�Ɍ��ݓ������Z�b�g����
	CALL	SET_DATETIME			;
	CALL	WRITE_DENT			;
	CALL	RESTORE_WDIR			;
	JP	CLOSE_CMD			;

;=================================================
;[CMD]�Q�̕�����̐擪�A�h���X�������ɃZ�b�g����
;IN  HL=TP
;OUT HL=TP,(ARG0)=1�Ԗڂ̕�����,(ARG1)=2�Ԃ߂̕�����
;=================================================
GET_2STR_ARGS:
	CALL	OPEN_DQUOTE			;
	LD	(ARG0),HL			;
	CALL	CLOSE_DQUOTE			;
	DEC	HL				;�I�d�v�I
	RST	10H				;
	CALL	TPSEEK				;
	DB	","				;
	CALL	OPEN_DQUOTE			;
	LD	(ARG1),HL			;
	CALL	CLOSE_DQUOTE			;
	RET

;=================================================
;[CMD]�e�L�X�g�|�C���^��K�؂Ȉʒu�ɍ��킹��BASIC��͂����s����
;=================================================
CLOSE_CMD:
	POP	HL				;
	DEC	HL				;�I�d�v�I
	RST	10H				;
	RET					;

;=================================================
;[CMD]ARG0��ARG1����������
;=================================================
SWAP_ARGS:
	LD	HL,(ARG0)			;
	PUSH	HL				;
	LD	HL,(ARG1)			;
	LD	(ARG0),HL			;
	POP	HL				;
	LD	(ARG1),HL			;
	RET					;

;=================================================
;[CMD]�N���X�^���̑S�Z�N�^���[���N���A����
;IN  HL=�N���X�^��,IX=�o�b�t�@�\����
;OUT 
;=================================================
CLR_CLSTR:
	CALL	DW0_PUSH			;�Z�N�^����ޔ�
	CALL	GET_FIRST_SCTR			;
	CALL	CLR_BFFR			;�o�b�t�@IX���[���N���A����
	LD	A,(SCTRS_PER_CLSTR)		;
	LD	B,A				;B<-�P�N���X�^������̃Z�N�^��
.L1:	PUSH	BC				;
	LD	HL,DW0				;�o�b�t�@�\���̂̃Z�N�^�����X�V����
	PUSH	IX				;
	POP	DE				;
	CALL	DW_COPY				;(IX+0)<-(DW0)
	LD	(IX+IDX_BUPD),TRUE		;�o�b�t�@�̍X�V�t���O�𗧂Ă�
	CALL	SAVE_BFFR			;�o�b�t�@IX����������
	CALL	DW0_INC				;�Z�N�^��++
	POP	BC				;
	DJNZ	.L1				;
	CALL	DW0_POP				;�Z�N�^���𕜋A
	RET

;=================================================
;[CMD]�����񎮂̌��ʂ��i�[���ꂽ�A�h���X��(ARG0)�ɃZ�b�g����
;IN  
;OUT (ARG0),HL=TP
;=================================================
STR2ARG0:
	CALL	STR2BUFF			;
	LD	DE,STR_BUFF			;
	LD	(ARG0),DE			;
	RET					;

