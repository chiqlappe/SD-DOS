
;-----------------------------
;�o�b�t�@�\����
;-----------------------------
;+00 �Z�N�^�� LSB
;+01
;+02
;+03 �Z�N�^�� MSB
;+04 �o�b�t�@�|�C���^ L
;+05 �o�b�t�@�|�C���^ H
;+06 �X�V�t���O
;-----------------------------

;=================================================
;[BFFR]�o�b�t�@�\���̂�����������
;IN  -
;OUT -
;=================================================
INIT_BFFR:
	LD	HL,FAT1_BFFR_STRCT		;=FAT1�p
	LD	DE,FAT_BFFR			;�o�b�t�@�̐擪�A�h���X
	CALL	.SUB
	LD	HL,FAT2_BFFR_STRCT		;=FAT2�p
	LD	DE,FAT_BFFR			;�I�o�b�t�@�̈��FAT�Ƌ��ʂɂ��邱�Ƃŕ����ɂȂ�I
	CALL	.SUB
	LD	HL,FILE_BFFR_STRCT		;=�t�@�C���p
	LD	DE,FILE_BFFR			;
.SUB:	CALL	DW_CLR				;�o�b�t�@�\���̂̃Z�N�^����00000000H�ɃZ�b�g����
	PUSH	HL				;
	POP	IX				;
	LD	(IX+IDX_BADR),E			;�o�b�t�@�̐擪�A�h���X���Z�b�g����
	LD	(IX+IDX_BADR+1),D		;
	LD	(IX+IDX_BUPD),FALSE		;�o�b�t�@�̍X�V�t���O���~�낷
	CALL	CLR_BFFR			;�o�b�t�@�̓��e���[���N���A����
	RET					;

;=================================================
;[BFFR]�o�b�t�@�����f�B�A�ɏ�������
;�E�X�V�t���O�������Ă���ꍇ�̂ݏ������܂��
;=================================================
FLUSH_BFFR:
	PUSH	IX				;
	LD	IX,FILE_BFFR_STRCT		;
	CALL	SAVE_BFFR			;
	LD	IX,FAT1_BFFR_STRCT		;
	CALL	SAVE_BFFR			;
	LD	IX,FAT2_BFFR_STRCT		;
	CALL	SAVE_BFFR			;
	POP	IX				;
	RET					;

;=================================================
;[BFFR]�o�b�t�@�̓��e���[���N���A����
;IN  IX=�o�b�t�@�\���̂̃|�C���^
;=================================================
CLR_BFFR:
	LD	L,(IX+IDX_BADR)			;HL<-�o�b�t�@�̐擪�A�h���X
	LD	H,(IX+IDX_BADR+1)		;
	PUSH	HL				;
	POP	DE				;
	INC	DE				;
	LD	(HL),00H			;
	LD	BC,SCTR_SIZE-1			;
	LDIR					;
	RET					;

;=================================================
;[BFFR]�w�肳�ꂽ�o�b�t�@�ɃZ�N�^��ǂݍ���
;-------------------------------------------------
;IN  IX=�o�b�t�@�\���̂̃|�C���^,(DW0)=�ǂݍ��݂����Z�N�^��
;OUT (IX+0) ~ (IX+3)=�ǂݍ��܂ꂽ�Z�N�^��
;=================================================
LOAD_BFFR:
	PUSH	IX				;
	POP	HL				;
	LD	DE,DW0				;=�ǂݍ��݂����Z�N�^��
	CALL	DW_CP				;�ړI�̃Z�N�^���o�b�t�@����Ă���ΏI��
	JR	C,.L1				;����:CY=0,Z=1
	RET	Z				;
.L1:	CALL	SAVE_BFFR			;���݂̃o�b�t�@���e���X�V����Ă���΃��f�B�A�ɏ����߂�
	LD	L,(IX+IDX_BADR)			;HL<-�o�b�t�@�̐擪�A�h���X
	LD	H,(IX+IDX_BADR+1)		;
	CALL	READ_SCTR			;�Z�N�^(DW0)���o�b�t�@HL�ɓǂݍ��ށB�G���[�Ȃ�߂炸�ɏI������
	LD	HL,DW0				;�o�b�t�@�\���̂̃Z�N�^�����X�V����I�Ō�ɍs�����ƁI
	PUSH	IX				;
	POP	DE				;
	CALL	DW_COPY				;

IF DEBUG
	PUSH	HL
	PUSH	DE
	PUSH	BC

	CALL	IPRINT
	DB	"<R>",EOL
	LD	HL,DW0
	CALL	PRT_DW_HEX
	CALL	PUT_CR

	POP	BC
	POP	DE
	POP	HL
ENDIF
	RET


;=================================================
;[BFFR]�w�肳�ꂽ�o�b�t�@���Z�N�^�ɏ�������
;IN  IX=�o�b�t�@�\���̂̃|�C���^
;OUT 
;=================================================
SAVE_BFFR:
	LD	A,(IX+IDX_BUPD)			;�o�b�t�@�̍X�V�t���O���~��Ă���Ώ����߂��Ȃ�
	OR	A				;
	RET	Z				;
	CALL	DW0_PUSH			;�I�d�v�I
	LD	(IX+IDX_BUPD),FALSE		;�o�b�t�@�̍X�V�t���O���~�낷
	PUSH	IX				;(DW0)<-�o�b�t�@�ɓǂݍ��܂�Ă���Z�N�^��
	POP	HL				;
	LD	DE,DW0				;
	CALL	DW_COPY				;
	LD	L,(IX+IDX_BADR)			;HL<-�o�b�t�@�̐擪�A�h���X
	LD	H,(IX+IDX_BADR+1)		;
	CALL	WRITE_SCTR			;�Z�N�^(DW0)�Ƀo�b�t�@�̃f�[�^����������

IF DEBUG
	PUSH	HL
	PUSH	DE
	PUSH	BC

	CALL	IPRINT
	DB	"<W>",EOL
	LD	HL,DW0
	CALL	PRT_DW_HEX
	CALL	PUT_CR

	POP	BC
	POP	DE
	POP	HL
ENDIF

	CALL	DW0_POP				;�I�d�v�I
	RET


