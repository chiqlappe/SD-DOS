
;=================================================
;[FS]�������s
;�E"/HELLO.CMT"�����݂���΃��[�h����BASIC�����s����
;=================================================
AUTOEXEC:
	IN	A,(08H)				;
	AND	01000000B			;"SHIFT"�L�[��������Ă�����L�����Z������
	RET	Z				;

	PUSH	HL
	LD	HL,.NAME			;
	CALL	STR2BUFF			;
	LD	HL,STR_BUFF			;
	CALL	IS_FILE				;
	POP	HL				;
	RET	Z				;

	PUSH	HL
	LD	HL,.NAME			;
	CALL	STR2BUFF			;
	LD	HL,STR_BUFF			;
	LD	(ARG0),HL			;
	POP	HL				;
	CALL	LOAD.E1				;
	POP	HL				;�I�d�v�I
	JP	RUN

.NAME:	DB	DQUOTE,"/HELLO.CMT",EOL		;

;=================================================
;[FS]�t�@�C�������݂��邩�𒲂ׂ�
;IN  HL=�p�X������̐擪�A�h���X
;OUT Z=1:���݂��Ȃ�
;=================================================
IS_FILE:
	LD	(ARG0),HL			;
	CALL	CHANGE_WDIR			;
	LD	C,ATRB_FILE			;
	CALL	GET_DENT			;
	CALL	RESTORE_WDIR			;
	RET					;

;=================================================
;[FS]�����񎮂�]�����ĕ�����o�b�t�@�Ɋi�[����
;=================================================
STR2BUFF:
	CALL	EVALEXP				;����]��
	PUSH	HL				;TP�ޔ�
	CALL	549CH				;DE<-���ʂ̕�����̐擪�A�h���X
	DEC	HL				;
	DEC	HL				;
	LD	B,(HL)				;B<-���ʂ̕�����S�̂̒���
	LD	C,STR_BUFF_SIZE-1		;C<-������o�b�t�@�̒����B�I�[���ʃR�[�h�p�ɂP���������炷
	LD	HL,STR_BUFF			;HL<-������o�b�t�@�̐擪�A�h���X
.L2:	LD	A,(DE)				;
	LD	(HL),A				;
	INC	HL				;
	INC	DE				;
	DEC	C				;
	JR	Z,.L3				;
	DJNZ	.L2				;
.L3:	LD	(HL),EOL			;�I�[�R�[�h���Z�b�g����
	POP	HL				;
	RET					;

;=================================================
;[FS]FAT16�֘A���[�N������
;=================================================
INIT_FAT16:
	LD	HL,ROOT				;
	LD	(WDIR_CLSTR),HL			;���[�L���O�f�B���N�g���̃N���X�^��<-���[�g�f�B���N�g��
	LD	HL,MIN_CLSTR			;
	LD	(TGT_CLSTR),HL			;�^�[�Q�b�g�N���X�^��<-�ŏ��N���X�^��
	CALL	INIT_BFFR			;�o�b�t�@�֘A���[�N������
	LD	HL,DNAME			;�f�B���N�g���G���g��������̕�����
	LD	(HL),DNAME_SIZE			;
	LD	HL,ATRB				;�t�@�C������������̕�����
	LD	(HL),ATRB_SIZE			;
	RET					;

;=================================================
;[FS]�{�����[������\������
;=================================================
PRT_VOLUME:
	LD	HL,ROOT_SCTR			;(DW0)<-���[�g�f�B���N�g���̊J�n�Z�N�^��
	LD	DE,DW0				;
	CALL	DW_COPY				;
	LD	IX,FILE_BFFR_STRCT		;
	CALL	LOAD_BFFR			;���[�g�f�B���N�g���̊J�n�Z�N�^���o�b�t�@IX�ɓǂݍ���
	LD	L,(IX+IDX_BADR)			;HL<-�f�[�^�|�C���^=�o�b�t�@�̐擪�A�h���X
	LD	H,(IX+IDX_BADR+1)		;
	CALL	IPRINT				;
	DB	"Vol:",EOL			;
	LD	B,DNAME_SIZE			;
.L1:	LD	A,(HL)				;
	INC	HL				;
	RST	18H				;
	DJNZ	.L1				;
	CALL	PUT_CR				;
	RET					;

;=================================================
;[FS]�t�@�C���T�C�Y��16�i���Ō��݈ʒu�ɏo�͂���
;IN  IX=�f�B���N�g���|�C���^
;OUT -
;=================================================
PRT_FSIZE:
	PUSH	HL				;
	LD	A,(IX+1EH)			;
	OR	(IX+1FH)			;
	LD	A," "				;
	JR	Z,.L1				;
	LD	A,"+"				;FFFFH���傫���ꍇ��"+"��t����
.L1:	RST	18H				;
	LD	L,(IX+1CH)			;
	LD	H,(IX+1DH)			;
	CALL	PRTHLHEX			;
	POP	HL				;
	RET					;

;=================================================
;[FS]FAT16��SD���}�E���g����Ă��邩���`�F�b�N����
;=================================================
IS_FAT16:
	PUSH	HL				;
	CALL	MMC_INIT			;MMC��SPI���[�h�ɏ���������B�I�����C���łȂ���΃^�C���A�E�g�ɂȂ�͂��H
	POP	HL				;
	LD	A,(SCTRS_PER_CLSTR)		;
	OR	A				;
	RET	NZ				;
	LD	HL,MSG_NOT_FAT16		;
	JP	ERR				;

;=================================================
;[FS]MBR�̓ǂݍ���
;IN  
;OUT (PP_SCTR)
;=================================================
READ_MBR:
	LD	HL,MMCADR0			;MMC�A�h���X��00000000H�ɃZ�b�g
	CALL	DW_CLR				;
	LD	HL,PP_SCTR			;�v���C�}���p�[�e�B�V�����̊J�n�Z�N�^����00000000H�ɃZ�b�g
	CALL	DW_CLR				;
	LD	HL,FILE_BFFR			;MBR���o�b�t�@�ɓǂݍ���
	LD	B,01H				;
	PUSH	HL				;
	CALL	MMC_READ			;
	POP	HL				;�Z�N�^��0�̍ŏ��̃o�C�g��00H�Ȃ�p�[�e�B�V�������؂��Ă���Ƃ���
	LD	A,(HL)				;
	OR	A				;
	RET	NZ				;
	LD	DE,IDX_PP_SCTR			;�u�v���C�}���p�[�e�B�V�����̊J�n�Z�N�^���v�����[�N�ɕۑ�����
	ADD	HL,DE				;
	LD	DE,PP_SCTR			;
	CALL	DW_COPY				;
	RET					;

;=================================================
;[FS]IPL�̓ǂݍ���
;IN  
;OUT (BPB)
;=================================================
READ_IPL:
	LD	HL,BPB				;BPB�p���[�N���N���A����
	LD	DE,BPB+1			;
	LD	(HL),00H			;
	LD	BC,0013H-1			;
	LDIR					;
	CALL	DW0_CLR				;(DW0)<-00000000H
	LD	HL,FILE_BFFR			;
	PUSH	HL				;
	CALL	READ_SCTR			;IPL�̈���o�b�t�@�ɓǂݍ���
	POP	HL				;
	PUSH	HL				;�o�b�t�@�A�h���X�ޔ�
	LD	DE,0036H			;HL<-�uFAT�^�C�v������v�̐擪�A�h���X
	ADD	HL,DE				;
	LD	DE,FAT_CODE			;�R�[�h�Əƍ�����
	LD	BC,0008H			;=������
.L1:	LD	A,(DE)				;
	CPI					;HL++,BC--
	JR	Z,.L2				;
	LD	HL,MSG_NOT_FAT16		;
	JP	ERR				;
.L2:	INC	DE				;
	JP	PE,.L1				;
	POP	HL				;�o�b�t�@�A�h���X���A
	LD	DE,IDX_BPB			;HL<-BPB�̈�̐擪�A�h���X
	ADD	HL,DE				;
	LD	DE,BPB				;BPB�����[�N�ɕۑ�����
	LD	BC,0013H			;
	LDIR					;
	RET					;

;=================================================
;[FS]BPB����K�v�Ȓ萔�����߂�
;�E(ROOT_SCTR)<-FAT�J�n�Z�N�^��+FAT�P�ʂɕK�v�ȃZ�N�^��*2
;�E(DATA_SCTR)<-���[�g�f�B���N�g���̃Z�N�^��+(�����[�g�f�B���N�g����*�f�B���N�g���T�C�Y)/�Z�N�^�T�C�Y
;=================================================
READ_BPB:
	LD	HL,FAT_SCTR			;(FAT_SCTR)<-FAT�J�n�Z�N�^��
	CALL	DW_CLR				;
	LD	DE,(FAT_START)			;
	LD	(HL),E				;
	INC	HL				;
	LD	(HL),D				;
	LD	HL,DW0				;HL<-DW0
	PUSH	HL				;
	CALL	DW0_CLR				;(DW0)<-00000000H
	EX	DE,HL				;DE=DW0
	LD	HL,(FAT_SIZE)			;HL<-(BPB+11)=FAT�P�ʂɕK�v�ȃZ�N�^��
	ADD	HL,HL				;HL<-(BPB+11)*2
	EX	DE,HL				;DE=(BPB+11)*2,HL=DW0
	LD	(HL),E				;(DW0)<-(BPB+11)*2
	INC	HL				;HL++
	LD	(HL),D				;
	POP	HL				;HL=DW0
	LD	DE,FAT_SCTR			;DE<-FAT_SCTR
	CALL	DW_ADD				;(DW0)<-(FAT_SCTR)+(BPB+11)*2
	LD	DE,ROOT_SCTR			;
	CALL	DW_COPY				;(ROOT_SCTR)<-(DW0)=(FAT_SCTR)+(BPB+11)*2
	LD	HL,(ROOT_SIZE)			;=�����[�g�f�B���N�g����
	ADD	HL,HL				;=X*2
	ADD	HL,HL				;=X*4
	ADD	HL,HL				;=X*8
	ADD	HL,HL				;=X*16
	ADD	HL,HL				;=X*32=�����[�g�f�B���N�g����*�f�B���N�g���̃T�C�Y
	OR	A				;CY<-0
	LD	C,00H				;���[�g�f�B���N�g���̑��Z�N�^�������߂�
	LD	DE,SCTR_SIZE			;=200H
.L1:	SBC	HL,DE				;HL<-HL-200H
	INC	C				;
	JR	NC,.L1				;
	DEC	C				;
	LD	HL,ROOT_SCTR_SIZE		;���[�g�f�B���N�g���̑��Z�N�^��<-C
	LD	(HL),C				;
	LD	HL,ROOT_SCTR			;
	LD	DE,DATA_SCTR			;
	PUSH	DE				;
	CALL	DW_COPY				;(DATA_SCTR)<-(ROOT_SCTR)
	POP	HL				;HL<-DATA_SCTR
	LD	A,(HL)				;(DATA_SCTR)<-(ROOT_SCTR)+C
	ADD	A,C				;
	LD	(HL),A				;
	INC	HL				;
	LD	A,(HL)				;
	ADC	A,0				;
	LD	(HL),A				;
	RET					;

;=================================================
;[FS]�Z�N�^�����畨���A�h���X�����߂�
;IN  (DW0)=�Z�N�^��
;OUT (MMCADR0)=�����A�h���X
;=================================================
GET_PHYSICAL_ADRS:
	PUSH	DE				;
	PUSH	HL				;
	CALL	DW0_PUSH			;(DW0)��ޔ�
	LD	HL,PP_SCTR			;(DW0)<-�Z�N�^��+�v���C�}���p�[�e�B�V�����̊J�n�Z�N�^��
	LD	DE,DW1				;
	CALL	DW_COPY				;
	CALL	DW0_ADD				;
	CALL	DW_X512				;(MMCADR0)<-�Z�N�^��*�Z�N�^�T�C�Y=�����A�h���X
	LD	HL,DW0				;
	LD	DE,MMCADR0			;
	CALL	DW_COPY				;
	CALL	DW0_POP				;(DW0)�𕜋�
	POP	HL				;
	POP	DE				;
	RET					;

;=================================================
;[FS]�Z�N�^���w��̈�ɓǂݍ���
;IN  (DW0)=�ǂݍ��݂����Z�N�^��,HL=�������̈�̐擪�A�h���X
;OUT (MMCADR0~3)
;=================================================
READ_SCTR:
	CALL	GET_PHYSICAL_ADRS		;(MMCADR0)<-�Z�N�^��(DW0)�̕����A�h���X
	LD	B,01H				;=MMC�u���b�N��
	CALL	MMC_READ			;������<-�Z�N�^�f�[�^200H�o�C�g
	RET					;

;=================================================
;[FS]�w��̈���Z�N�^�ɏ�������
;IN  (DW0)=�������݂����Z�N�^��,HL=�������̈�̐擪�A�h���X
;OUT (MMCADR0~3)
;=================================================
WRITE_SCTR:
	CALL	GET_PHYSICAL_ADRS		;(MMCADR0)<-�Z�N�^��(DW0)�̕����A�h���X
	LD	B,01H				;=MMC�u���b�N��
	CALL	MMC_WRITE			;�Z�N�^<-�������f�[�^200H�o�C�g
	RET					;

;=================================================
;[FS]�N���X�^�̊J�n�Z�N�^�������߂�
;IN  HL=�N���X�^��
;OUT (DW0)=�Z�N�^��
;=================================================
GET_FIRST_SCTR:
	PUSH	BC				;
	PUSH	DE				;
	PUSH	HL				;
	LD	A,H				;HL=0000H ?
	OR	L				;
	JR	NZ,.L1				;
	LD	HL,ROOT_SCTR			;(DW0)<-���[�g�f�B���N�g���̊J�n�Z�N�^��
	LD	DE,DW0				;
	CALL	DW_COPY				;
	JR	.EXIT				;
.L1:	DEC	HL				;HL<-HL-2
	DEC	HL				;
	LD	A,(SCTRS_PER_CLSTR)		;=�P�N���X�^������̃Z�N�^��
	LD	E,A				;
	LD	D,00H				;
	CALL	HLXDE				;(DW0)<-HL*DE
	LD	HL,DW0				;
	LD	DE,DATA_SCTR			;
	CALL	DW_ADD				;(DW0)<-�Z�N�^��
.EXIT:	POP	HL				;
	POP	DE				;
	POP	BC				;
	RET					;

;=================================================
;[FS]���[�L���O�f�B���N�g��������t�@�C����T���āA���̃N���X�^�������߂�
;IN  HL=�t�@�C�����̐擪�A�h���X
;OUT (TGT_CLSTR)=��v�����t�@�C���̃N���X�^��
;=================================================
DNAME2CLSTR:
	LD	C,ATRB_FILE			;
	CALL	GET_DENT			;
	JP	Z,ERR_NOT_FOUND			;
	LD	HL,(DIR_ENTRY+IDX_FAT)		;=��v�����t�@�C���̃N���X�^��
	LD	A,H				;�N���X�^����0000H�Ȃ��t�@�C���Ȃ̂ŃG���[��
	OR	L				;
	JP	Z,ERR_EMPTY_FILE		;
	LD	(TGT_CLSTR),HL			;��v�����t�@�C���̃N���X�^�����^�[�Q�b�g�N���X�^�ɃZ�b�g����
	RET					;

