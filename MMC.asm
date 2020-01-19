
;MMCドライバ
;・出典 http://w01.tp1.jp/~a571632211/pc8001/index.html

HI		EQU	1

PA_IN		EQU	00010000B
PB_IN		EQU	00000010B
PCL_IN		EQU	00000001B
PCH_IN		EQU	00001000B

A8255		EQU 	0FCH		;8255 ポートアドレス
PPI_A		EQU	A8255		;
PPI_B		EQU	A8255+1		;
PPI_C		EQU	A8255+2		;
PPI_CTL		EQU	A8255+3		;

PPI_MMC		EQU	10000000B + PCH_IN	;MMCドライバで使用する8255のポート設定

VLED_POS:	EQU	VRAM+78			;仮想LEDの位置

;MMCADR0:	DS	1	;MMC 物理アドレス L   MMCのアドレスは32ビット長
;MMCADR1:	DS	1	;MMC 物理アドレス H
;MMCADR2:	DS	1	;MMC 物理アドレス HH
;MMCADR3:	DS	1	;MMC 物理アドレス HHH

;=================================================
;[MMC]8255モードセット
;=================================================
INIT_8255:
	PUSH	HL

	LD	A,PPI_MMC		;MODE=0,A=IN,B=OUT,CH=IN,CL=OUT
	OUT	(PPI_CTL),A
	LD	A,0F7H
	OUT	(PPI_B),A
	IN	A,(PPI_B)
	CP	0F7H
	JR	Z,.L1

	LD	HL,MSG_NOT_FOUND
	CALL	PRINT
	CALL	KEYWAIT

.L1:	LD	A,0FFH
	OUT	(PPI_B),A

	POP	HL
	RET

;=================================================
;[MMC]MMCに1バイト送る
;IN  C=送信データ
;OUT -
;=================================================
MMC_1WR:
	PUSH	BC
	LD	B,8
.L1:	IN	A,(PPI_B)
	AND	0FEH
	OUT	(PPI_B),A
	CALL	MMC_WAIT
	IN	A,(PPI_B)
	AND	0FDH
	RL	C
	JR	NC,.L2
	OR	02H
.L2:	OUT	(PPI_B),A
	CALL	MMC_WAIT
	IN	A,(PPI_B)
	OR	01H
	OUT	(PPI_B),A
	CALL	MMC_WAIT
	DJNZ	.L1
	POP	BC
	IN	A,(PPI_B)
	OR	02H
	OUT	(PPI_B),A
	RET

;=================================================
;[MMC]MMCから1バイト受け取る
;IN  -
;OUT C=受信データ
;=================================================
MMC_1RD:
	LD	B,8
.LOOP:	IN	A,(PPI_B)
	AND	0FEH
	OUT	(PPI_B),A
        OR	001H
	OUT	(PPI_B),A
	XOR	A
	RL	C
	IN	A,(PPI_C)
	AND	010H
	JR	Z,.L1
	INC	C
.L1:	DJNZ	.LOOP
	RET

;=================================================
;[MMC]MMCから1バイトレスポンスを受け取る
;IN  -
;OUT C=レスポンス
;=================================================
MMC_RES:
	XOR	A				;タイムアウト用カウンタリセット
	LD	(TIMEOUT),A

.LOOP:	PUSH	HL
	LD	HL,TIMEOUT
	INC	(HL)
	LD	A,(HL)
	POP	HL
	OR	A
	JR	Z,MMC_TIMEOUT

	LD	B,1
	CALL	MMC_CLK

	IN	A,(PPI_C)
	AND	010H
	JR	NZ,.LOOP

	LD	BC,0700H			;B<-7
	JR	MMC_1RD.LOOP

;=================================================
;[MMC]タイムアウト処理
;=================================================
MMC_TIMEOUT:
	CALL	IPRINT
	DB	"Set SDC then ",DQUOTE,"MOUNT",DQUOTE,CR,LF,EOL
	LD	E,UNPRINTABLE
	JP	ERROR

;=================================================
;[MMC]MMCクロック
;IN  B=回数
;OUT 
;=================================================
MMC_CLK:
	IN	A,(PPI_B)
	AND	11111110B
	OUT	(PPI_B),A
	CALL	MMC_WAIT
	IN	A,(PPI_B)
	OR	00000001B
	OUT	(PPI_B),A
	CALL	MMC_WAIT
	DJNZ	MMC_CLK
	RET

;=================================================
;[MMC]CS=HにしてMMCクロックX8
;=================================================
MMC_CLK8:
	IN	A,(PPI_B)
	OR	00000100B
	OUT	(PPI_B),A  			;CS=H
	LD	B,8
	CALL	MMC_CLK   			;MMCクロック実行
	IN	A,(PPI_B)
	AND	11111011B
	OUT	(PPI_B),A  			;CS=L
	RET

;=================================================
;[MMC]MMCをSPIモードに初期化する
;=================================================
MMC_INIT:
	IN	A,(PPI_B)
	OR	00000100B
	OUT	(PPI_B),A
	LD	B,200
	CALL	MMC_CLK
	IN	A,(PPI_B)
	AND	11111011B
	OUT	(PPI_B),A
	LD	C,01000000B
	CALL	MMC_1WR
	LD	C,0
	CALL	MMC_1WR
	CALL	MMC_1WR
	CALL	MMC_1WR
	CALL	MMC_1WR
	LD	C,10010101B
	CALL	MMC_1WR
	CALL	MMC_RES
	LD	A,01H
	CP	C
	JR	NZ,MMC_INIT

.L1:	CALL	MMC_CLK8
	LD	C,01000001B
	CALL	MMC_1WR
	LD	C,0
	CALL	MMC_1WR
	CALL	MMC_1WR
	CALL	MMC_1WR
	CALL	MMC_1WR
	LD	C,11111001B
	CALL	MMC_1WR
	CALL	MMC_RES
	LD	A,0
	CP	C
	JR	NZ,.L1
	RET

;=================================================
;[MMC]ブロックREADコマンド
;=================================================
MMC_BRD_CMD:
	CALL	MMC_CLK8
	LD	C,01010001B
	CALL	MMC_1WR
	LD	A,(MMCADR3)
	LD	C,A
	CALL	MMC_1WR
	LD	A,(MMCADR2)
	LD	C,A
	CALL	MMC_1WR
	LD	A,(MMCADR1)
	LD	C,A
	CALL	MMC_1WR
	LD	A,(MMCADR0)
	LD	C,A
	CALL	MMC_1WR
	LD	C,00000001B
	CALL	MMC_1WR
	CALL	MMC_RES
	LD	A,0
	CP	C
	JR	NZ,MMC_BRD_CMD

.L1:	CALL	MMC_1RD
	LD	A,C
	AND	11100000B
	JR	Z,MMC_BRD_CMD
	LD	A,C
	CP	0FEH
	JR	NZ,.L1
	RET

;=================================================
;[MMC]ブロックREAD終了処理
;=================================================
MMC_BRD_END:
	CALL	MMC_1RD
	CALL	MMC_1RD
	RET

;=================================================
;[MMC]ブロックWRITEコマンド
;=================================================
MMC_BWR_CMD:
	CALL	MMC_CLK8
	LD	C,01011000B
	CALL	MMC_1WR
	LD	A,(MMCADR3)
	LD	C,A
	CALL	MMC_1WR
	LD	A,(MMCADR2)
	LD	C,A
	CALL	MMC_1WR
	LD	A,(MMCADR1)
	LD	C,A
	CALL	MMC_1WR
	LD	A,(MMCADR0)
	LD	C,A
	CALL	MMC_1WR
	LD	C,00000001B
	CALL	MMC_1WR
	CALL	MMC_RES
	LD	A,0
	CP	C
	JR	NZ,MMC_BWR_CMD

	LD	C,0FFH
	CALL	MMC_1WR
	LD	C,0FEH
	CALL	MMC_1WR
	RET

;=================================================
;[MMC]ブロックWRITE終了処理
;=================================================
MMC_BWR_END:
	LD	C,0
	CALL	MMC_1WR
	LD	C,0
	CALL	MMC_1WR
	CALL	MMC_RES

.L1:	IN	A,(PPI_B)
	AND	11111110B
	OUT	(PPI_B),A
	CALL	MMC_WAIT
	IN	A,(PPI_B)
	OR	00000001B
	OUT	(PPI_B),A
	CALL	MMC_WAIT
	IN	A,(PPI_C)
	AND	00010000B
	JR	Z,.L1
	RET

;=================================================
;[MMC]物理アドレスクリア
;=================================================
MMC_CLR_ADR:
	XOR	A
	LD	(MMCADR0),A
	LD	(MMCADR1),A
	LD	(MMCADR2),A
	LD	(MMCADR3),A
	RET

;=================================================
;[MMC]物理アドレスを1ブロック分進める
;=================================================
MMC_INC_ADR:
	LD	A,(MMCADR1)
	ADD	A,2
	LD	(MMCADR1),A
	LD	A,(MMCADR2)
	ADC	A,0
	LD	(MMCADR2),A
	LD	A,(MMCADR3)
	ADC	A,0
	LD	(MMCADR3),A
	RET

;=================================================
;[MMC]MMC読み込み
;IN  MMCADR0,1,2,3=MMCアドレス HL=メモリアドレス B=ブロック数
;OUT 
;=================================================
MMC_READ:
	PUSH	BC

	CALL	MMC_LED_ON

	CALL	MMC_BRD_CMD
	LD	B,2
.L1:	PUSH	BC
	LD	B,0				;256回ループ
.L2:	PUSH	BC
	CALL	MMC_1RD
	LD	(HL),C
	INC	HL
	POP 	BC
	DJNZ	.L2
	POP	BC
	DJNZ	.L1
	CALL	MMC_BRD_END
	CALL	MMC_INC_ADR
	POP	BC

	CALL	MMC_LED_OFF

	DJNZ	MMC_READ
	RET

;=================================================
;[MMC]MMC書き込み
;IN  MMCADR0,1,2,3=MMCアドレス HL=メモリアドレス B=ブロック数
;OUT 
;=================================================
MMC_WRITE:
	PUSH	BC

	CALL	MMC_LED_ON

	CALL	MMC_BWR_CMD
	LD	B,2
.L1:	PUSH	BC
	LD	B,0
.L2:	PUSH	BC
	LD	C,(HL)
	INC	HL
	CALL	MMC_1WR
	POP	BC
	DJNZ	.L2
	POP	BC
	DJNZ	.L1
	CALL	MMC_BWR_END
	CALL	MMC_INC_ADR
	POP	BC

	CALL	MMC_LED_OFF

	DJNZ	MMC_WRITE
	RET

;=================================================
;[MMC]MMC埋め尽くし
;IN  MMCADR0,1,2,3=MMCアドレス L=埋める値 B=ブロック数
;OUT -
;=================================================
MMC_FILLB:
	PUSH	BC

	CALL	MMC_LED_ON

	CALL	MMC_BWR_CMD
	LD	B,2
.L1:	PUSH	BC
	LD	B,0
.L2:	PUSH	BC
	LD	C,L
	CALL	MMC_1WR
	POP	BC
	DJNZ	.L2
	POP	BC
	DJNZ	.L1
	CALL	MMC_BWR_END
	CALL	MMC_INC_ADR
	POP	BC

	CALL	MMC_LED_OFF

	DJNZ	MMC_FILLB
	RET

;=================================================
;[MMC]12クロックのウェイト挿入
;=================================================
MMC_WAIT:
	NOP
	NOP
	NOP
	RET

;=================================================
;アクセスランプ点灯
;=================================================
MMC_LED_ON:
	IN	A,(PPI_B)
	AND	11110111B			;LED信号を立てる(負論理)
	OUT	(PPI_B),A

IF USE_VIRTUAL_SOUND
	CALL	MMC_SOUND
ENDIF

	LD	A,(INFO_SW)			;インフォメーションフラグが降りていたら戻る
	AND	A
	RET	Z

IF USE_VIRTUAL_LED
	LD	A,02AH				;="*"
	LD	(VLED_POS),A
ENDIF

	RET

;=================================================
;アクセスランプ消灯
;=================================================
MMC_LED_OFF:
	IN	A,(PPI_B)
	AND	11111110B			;PB0=CLK<-L microSDモジュールのLEDを消す
	OR	00001000B			;LED信号を降ろす(負論理)
	OUT	(PPI_B),A

	LD	A,(INFO_SW)
	AND	A
	RET	Z

IF USE_VIRTUAL_LED
	XOR	A				;=NULL文字
	LD	(VLED_POS),A
ENDIF
	RET

;=================================================
;疑似アクセス音
;=================================================
IF USE_VIRTUAL_SOUND
MMC_SOUND:
	PUSH	BC

	LD	B,20H
.L1:	LD	A,(0EA67H)
	OR	00100000B
	OUT	(40H),A
	AND	11011111B
	OUT	(40H),A
	DJNZ	.L1

	POP	BC
	RET
ENDIF

