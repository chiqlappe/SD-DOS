
;=================================================
;�_�u�����[�h�p���[�N LSB<<<MSB
;=================================================
;DW0:		DB	00H,00H,00H,00H		;�ϐ�
;DW1:		DB	00H,00H,00H,00H		;�ϐ�
;DW_SP_ORG:	DB	00H,00H			;�X�^�b�N�|�C���^�̈ꎞ�ޔ��G���A
;DW_SP:		DB	00H,00H			;�_�u�����[�h�p�X�^�b�N�|�C���^
;		DB	00H,00H,00H,00H		;�_�u�����[�h�p�X�^�b�N�G���A
;		DB	00H,00H,00H,00H		;
;		DB	00H,00H,00H,00H		;
;		DB	00H,00H,00H,00H		;
;DW_STACK	EQU	$			;

;=================================================
;�_�u�����[�h�X�^�b�N������
;=================================================
INIT_DW:
	LD	HL,DW_STACK			;
	LD	(DW_SP),HL			;
	RET					;

;=================================================
;�_�u�����[�h�ϐ��Ƀ��W�X�^�̒l�����[�h����
;IN  HL=DW�ϐ��̃|�C���^,BCDE=MSB->LSB
;OUT (HL)<-BCDE
;=================================================
DW_LD:
	PUSH	HL				;
	LD	(HL),E				;
	INC	HL				;
	LD	(HL),D				;
	INC	HL				;
	LD	(HL),C				;
	INC	HL				;
	LD	(HL),B				;
	POP	HL				;
	RET					;

;=================================================
;�_�u�����[�h(DW0)(DW1)���r����
;IN  -
;OUT (DW0)<(DW1):CY=1 Z=?
;    (DW0)=(DW1):CY=0 Z=1
;    (DW0)>(DW1):CY=0 Z=0
;=================================================
DW0_CP:
	PUSH	BC				;
	PUSH	DE				;
	PUSH	HL				;
	LD	HL,DW0				;
	LD	DE,DW1				;
	JP	DW_CP.E1			;

;=================================================
;�_�u�����[�h(HHLL)(DDEE)���r����
;IN  HL,DE
;OUT (HHLL)<(DDEE):CY=1 Z=?
;    (HHLL)=(DDEE):CY=0 Z=1
;    (HHLL)>(DDEE):CY=0 Z=0
;=================================================
DW_CP:
	PUSH	BC				;
	PUSH	DE				;DW0_CP�Ɛ�������邽�߂ɓ���Ă���
	PUSH	HL				;
.E1:	PUSH	HL				;DW_POP�p�ɑޔ�
	CALL	DW_PUSH				;(HHLL)��ޔ�����
	CALL	DW_SUB				;(HHLL)<-(HHLL)-(DDEE)
	JR	C,.EXIT				;CY=1�Ȃ�(HHLL)<(DDEE) Z�͖������Ă悢
	XOR	A				;A<-0, CY<-0
	LD	BC,0004H			;=�o�C�g��
.L1:	CPI					;A-(HL) HL++ BC--
	JR	NZ,.EXIT			;���ʂ�0�ł͂Ȃ��̂�(HHLL)>(DDEE) CY=0, Z=0
	JP	PE,.L1				;���ʂ�0�Ȃ̂�(HHLL)=(DDEE) CY=0, Z=1
.EXIT:	POP	HL				;DW_POP�p�ɕ��A
	PUSH	AF				;�t���O��ޔ�
	CALL	DW_POP				;(HHLL)�𕜋�����
	POP	AF				;
	POP	HL				;
	POP	DE				;
	POP	BC				;
	RET					;

;=================================================
;�_�u�����[�h���R�s�[����
;(HL)->(DE)
;IN  HL=SOURCE,DE=DEST
;OUT 
;=================================================
DW_COPY:
	PUSH	BC				;
	PUSH	DE				;
	PUSH	HL				;
	LD	BC,0004H			;
	LDIR					;
	POP	HL				;
	POP	DE				;
	POP	BC				;
	RET					;

;=================================================
;�_�u�����[�h(DW0)���X�^�b�N�ɐς�
;IN  DW0
;OUT -
;=================================================
DW0_PUSH:
	PUSH	DE				;
	PUSH	HL				;
	LD	HL,DW0				;
	JP	DW_PUSH.E1			;

;=================================================
;�_�u�����[�h(HL)���X�^�b�N�ɐς�
;IN  HL
;OUT -
;=================================================
DW_PUSH:
	PUSH	DE				;
	PUSH	HL				;
.E1:	LD	(DW_SP_ORG),SP			;�V�X�e���̃X�^�b�N�|�C���^���ꎞ�G���A�ɑޔ�����
	LD	SP,(DW_SP)			;�X�^�b�N�|�C���^���_�u�����[�h�p�ɕύX����
	LD	E,(HL)				;<-�ŉ��ʃo�C�g
	INC	HL				;
	LD	D,(HL)				;<-��Q�ʃo�C�g
	INC	HL				;
	PUSH	DE				;
	LD	E,(HL)				;<-��R�ʃo�C�g
	INC	HL				;
	LD	D,(HL)				;<-�ŏ�ʃo�C�g
	PUSH	DE				;
	LD	(DW_SP),SP			;�_�u�����[�h�p�X�^�b�N�|�C���^��ۑ�����
	LD	SP,(DW_SP_ORG)			;�V�X�e���̃X�^�b�N�|�C���^�𕜋�����
	POP	HL				;
	POP	DE				;
	RET					;

;=================================================
;�_�u�����[�h(DW0)���X�^�b�N������o��
;IN  -
;OUT (DW0)
;=================================================
DW0_POP:
	PUSH	BC				;
	PUSH	DE				;
	PUSH	HL				;
	LD	HL,DW0				;
	JP	DW_POP.E1			;

;=================================================
;�_�u�����[�h(HL)���X�^�b�N������o��
;IN  HL
;OUT (HL)
;=================================================
DW_POP:
	PUSH	BC				;
	PUSH	DE				;
	PUSH	HL				;
.E1:	LD	(DW_SP_ORG),SP			;�V�X�e���̃X�^�b�N�|�C���^���ꎞ�G���A�ɑޔ�����
	LD	SP,(DW_SP)			;�X�^�b�N�|�C���^���_�u�����[�h�p�ɕύX����
	POP	DE				;
	POP	BC				;
	LD	(HL),C				;<-�ŉ��ʃo�C�g
	INC	HL				;
	LD	(HL),B				;<-��Q�ʃo�C�g
	INC	HL				;
	LD	(HL),E				;<-��R�ʃo�C�g
	INC	HL				;
	LD	(HL),D				;<-�ŏ�ʃo�C�g
	LD	(DW_SP),SP			;�_�u�����[�h�p�X�^�b�N�|�C���^��ۑ�����
	LD	SP,(DW_SP_ORG)			;�V�X�e���̃X�^�b�N�|�C���^�𕜋�����
	POP	HL				;
	POP	DE				;
	POP	BC				;
	RET					;

;=================================================
;�_�u�����[�h(DW0)�ɑ��l�����[�h����
;IN  (SP)
;BRK HL
;=================================================
DW0_ILD:
	EX	(SP),HL				;
	PUSH	DE				;
	PUSH	BC				;
	LD	DE,DW0				;
	LD	B,4				;
.L1:	LD	A,(HL)				;
	INC	HL				;
	LD	(DE),A				;
	INC	DE				;
	DJNZ	.L1				;
.L2:	POP	BC				;
	POP	DE				;
	EX	(SP),HL				;
	RET					;

;=================================================
;�_�u�����[�h(DW0)���O�ɂ���
;IN  -
;OUT (DW0)
;=================================================
DW0_CLR:
	PUSH	HL				;
	LD	HL,DW0				;
	JP	DW_CLR.E1			;

;=================================================
;�_�u�����[�h(HHLL)���O�ɂ���
;IN  HL
;OUT (HHLL)
;=================================================
DW_CLR:
	PUSH	HL				;
.E1:	XOR	A				;DW0_CLR�̃G���g���|�C���g
	LD	(HL),A				;
	INC	HL				;
	LD	(HL),A				;
	INC	HL				;
	LD	(HL),A				;
	INC	HL				;
	LD	(HL),A				;
	POP	HL				;
	RET					;

;=================================================
;�_�u�����[�h���� (DW0)<->(DW1)
;IN  -
;OUT (DW0),(DW1)
;=================================================
DW0_SWAP:
	PUSH	BC				;
	PUSH	DE				;
	PUSH	HL				;
	LD	DE,DW0				;
	LD	HL,DW1				;
	JP	DW_SWAP.E1			;

;=================================================
;�_�u�����[�h���� (DE)<->(HL)
;IN  DE,HL
;OUT (DE),(HL)
;=================================================
DW_SWAP:
	PUSH	BC				;
	PUSH	DE				;
	PUSH	HL				;
.E1:	LD	B,4				;DW0_SWAP�̃G���g���|�C���g
.L1:	LD	C,(HL)				;C<-(HL)
	LD	A,(DE)				;A<-(DE)
	EX	DE,HL				;
	LD	(HL),C				;(DE)<-C
	LD	(DE),A				;(HL)<-A
	EX	DE,HL				;���ʂƂ���(HL)��(DE)������ւ���Ă���
	INC	HL				;
	INC	DE				;
	DJNZ	.L1				;
	POP	HL				;
	POP	DE				;
	POP	BC				;
	RET					;

;=================================================
;�_�u�����[�h���Z (DW0)<-(DW0)+(DW1)
;IN  DW0=����Z���̃|�C���^,DW1=���Z���̃|�C���^
;OUT (DW0),CY
;=================================================
DW0_ADD:
	PUSH	BC				;
	PUSH	DE				;
	PUSH	HL				;
	LD	HL,DW0				;
	LD	DE,DW1				;
	JP	DW_ADD.E1			;

;=================================================
;�_�u�����[�h���Z (HL)<-(HL)+(DE)
;IN  HL=����Z���̃|�C���^,DE=���Z���̃|�C���^
;OUT (HL),CY
;=================================================
DW_ADD:
	PUSH	BC				;
	PUSH	DE				;
	PUSH	HL				;
.E1:	LD	B,4				;DW0_ADD�̃G���g���|�C���g
	OR	A				;CY<-0
.L1:	LD	A,(DE)				;(HL)<-(HL)+(DE) & CY
	ADC	A,(HL)				;
	LD	(HL),A				;
	INC	DE				;DE++
	INC	HL				;HL++
	DJNZ	.L1				;B--
	POP	HL				;
	POP	DE				;
	POP	BC				;
	RET					;

;=================================================
;�_�u�����[�h���Z (DW0)<-(DW0)-(DW1)
;IN  DW0=�팸�Z���̃|�C���^,DW1=���Z���̃|�C���^
;OUT (DW0),CY
;=================================================
DW0_SUB:
	PUSH	BC				;
	PUSH	DE				;
	PUSH	HL				;
	LD	HL,DW0				;
	LD	DE,DW1				;
	JP	DW_SUB.E1			;

;=================================================
;�_�u�����[�h���Z (HL)<-(HL)-(DE)
;IN  HL=�팸�Z���̃|�C���^,DE=���Z���̃|�C���^
;OUT (HL),CY
;=================================================
DW_SUB:
	PUSH	BC				;
	PUSH	DE				;
	PUSH	HL				;
.E1:	EX	DE,HL				;SBC���߂�DE���g���Ȃ����ߓ���ւ���
	LD	B,4				;=�o�C�g��
	OR	A				;CY<-0
.L1:	LD	A,(DE)				;������ (HL)<-(HL)-(DE)
	SBC	A,(HL)				;
	LD	(DE),A				;
	INC	DE				;
	INC	HL				;
	DJNZ	.L1				;
	POP	HL				;
	POP	DE				;
	POP	BC				;
	RET					;

;=================================================
;�_�u�����[�h(DW0)�ɂP���Z����
;IN  -
;OUT (DW0)
;=================================================
DW0_INC:
	PUSH	HL				;
	LD	HL,DW0				;
	JP	DW_INC.E1			;

;=================================================
;�_�u�����[�h(HHLL)�ɂP���Z����
;IN  HL=�_�u�����[�h�̃|�C���^
;OUT (HHLL)
;=================================================
DW_INC:
	PUSH	HL				;
.E1:	INC	(HL)				;�ŉ��ʃo�C�g�ɂP���Z���ĂO�ɂȂ�Ȃ����
	JR	NZ,.EXIT			;����肪�Ȃ��Ɣ��f���I����
	INC	HL				;��Q�o�C�g�ɂP���Z���ĂO�ɂȂ�Ȃ����
	INC	(HL)				;����肪�Ȃ��Ɣ��f���I����
	JR	NZ,.EXIT			;
	INC	HL				;��R�o�C�g�ɂP���Z���ĂO�ɂȂ�Ȃ����
	INC	(HL)				;����肪�Ȃ��Ɣ��f���I����
	JR	NZ,.EXIT			;
	INC	HL				;�ŏ�ʃo�C�g�ɂP���Z
	INC	(HL)				;
.EXIT:	POP	HL				;
	RET					;

;=================================================
;�_�u�����[�h(DW0)���P���Z����
;IN  -
;OUT (DW0),CY
;=================================================
DW0_DEC:
	PUSH	HL				;
	PUSH	BC				;
	LD	HL,DW0				;
	JP	DW_DEC.E1			;

;=================================================
;�_�u�����[�h(HL)���P���Z����
;IN  HL=�_�u�����[�h�̃|�C���^
;OUT (HL),CY
;=================================================
DW_DEC:
	PUSH	HL				;
	PUSH	BC				;
.E1:	LD	A,(HL)				;�ŉ��ʃo�C�g����P���Z����
	SUB	1				;���؂肪�����Ȃ���ΏI���� �IDEC��CY���ω����Ȃ��̂Ŏg�p�ł��Ȃ��I
	LD	(HL),A				;
	JR	NC,.EXIT			;
	INC	HL				;
	LD	BC,0300H			;B=���[�v��, C=0
.L1:	LD	A,(HL)				;��Q�o�C�g����ŏ�ʃo�C�g�܂�
	SBC	A,C				;�L�����[�t�����Z���J��Ԃ�
	LD	(HL),A				;
	JR	NC,.EXIT			;���؂肪�����Ȃ���ΏI����
	INC	HL				;
	DJNZ	.L1				;
.EXIT:	POP	BC				;
	POP	HL				;
	RET					;

;=================================================
;�_�u�����[�h(DW0)��2�{����
;IN  -
;OUT (DW0),CY<-BIT31
;=================================================
DW0_X2:
	PUSH	HL				;
	LD	HL,DW0				;
	JP	DW_X2.E1			;

;=================================================
;�_�u�����[�h(HL)��2�{����
;IN  HL
;OUT (HL),CY<-BIT31
;=================================================
DW_X2:
	PUSH	HL				;
.E1:	SLA	(HL)				;BIT0<-0,CY<-BIT7
	INC	HL				;+1 �t���O�͕ω����Ȃ�
	RL	(HL)				;BIT8<-CY,CY<-BIT15
	INC	HL				;+2
	RL	(HL)				;BIT16<-CY,CY<-BIT23
	INC	HL				;+3
	RL	(HL)				;BIT24<-CY,CY<-BIT31
	POP	HL				;
	RET					;

;=================================================
;DW0��256�{����
;IN  (DW0)
;OUT -
;=================================================
DW_X256:
	PUSH	AF				;
	PUSH	BC				;
	PUSH	DE				;
	PUSH	HL				;
	LD	HL,DW0+2			;�]���� 00 01 02 03
	LD	DE,DW0+3			;�]���� XX 00 01 02
	LD	BC,0003H			;�]����
	LDDR					;BC--,DE--,HL--
	XOR	A				;
	LD	(DE),A				;(DW0+0)<-0
	POP	HL				;
	POP	DE				;
	POP	BC				;
	POP	AF				;
	RET					;

;=================================================
;DW0��512�{����
;IN  (DW0)
;OUT CY
;=================================================
DW_X512:
	CALL	DW0_X2				;
	CALL	DW_X256				;
	RET					;

;=================================================
;���[�h�̏�Z (DW0)<-HLxDE ���ʂ̓_�u�����[�h
;HL X DE
;IN  HL=��搔,DE=�搔
;OUT (DW0)
;=================================================
HLXDE:
	PUSH	BC				;
	CALL	DW0_CLR				;DW0,DW1<-0
	CALL	DW0_SWAP			;
	CALL	DW0_CLR				;
	LD	A,L				;
	LD	(DW0+0),A			;(DW0)<-HL=��搔
	LD	A,H				;
	LD	(DW0+1),A			;
	LD	B,16				;���[�v��
.L2:	SRL	D				;�搔DE���E�V�t�g����
	RR	E				;CY<-BIT0
	JR	NC,.L1				;CY=1�Ȃ��搔�����ʂɉ��Z����
	CALL	DW0_SWAP			;(DW0)=����, (DW1)=��搔
	CALL	DW0_ADD				;(DW0)<-(DW0)+(DW1)
	CALL	DW0_SWAP			;(DW0)=��搔, (DW1)=����
.L1:	CALL	DW0_X2				;��搔�����V�t�g����2�{�ɂ���
	DJNZ	.L2				;
	CALL	DW0_SWAP			;(DW0)=����, (DW1)=��搔
	POP	BC				;
	RET					;

