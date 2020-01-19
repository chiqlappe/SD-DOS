
;IPL

INCLUDE "LABELS.ASM"
INCLUDE	"N80.ASM"

A8255:		EQU 	0FCH			;8255 ポートアドレス

	ORG	0C000H

START:
	CALL	INIT_DW
	CALL	INIT_8255			;PPI初期化
	CALL	MMC_INIT			;MMC初期化
	CALL	READ_MBR			;パーティション開始セクタ＃をセットする

	LD	HL,DOS
	LD	DE,DW0
	CALL	DW_COPY
	CALL	GET_PHYSICAL_ADRS
	LD	HL,06000H-6
	LD	B,0FH
	CALL	MMC_READ
	JP	BASIC				;


DOS:	DB	41H,04H,00H,00H

;=================================================
;[FS]MBRの読み込み
;IN  
;OUT (PP_SCTR)
;=================================================
READ_MBR:
	LD	HL,MMCADR0			;MMCアドレスを00000000Hにセット
	CALL	DW_CLR				;
	LD	HL,PP_SCTR			;プライマリパーティションの開始セクタ＃を00000000Hにセット
	CALL	DW_CLR				;
	LD	HL,FILE_BFFR			;MBRをバッファに読み込む
	LD	B,01H				;
	PUSH	HL				;
	CALL	MMC_READ			;
	POP	HL				;セクタ＃0の最初のバイトが00Hならパーティションが切られているとする
	LD	A,(HL)				;
	OR	A				;
	RET	NZ				;
	LD	DE,IDX_PP_SCTR			;「プライマリパーティションの開始セクタ＃」をワークに保存する
	ADD	HL,DE				;
	LD	DE,PP_SCTR			;
	CALL	DW_COPY				;
	RET					;

;=================================================
;[FS]セクタ＃から物理アドレスを求める
;IN  (DW0)=セクタ＃
;OUT (MMCADR0)=物理アドレス
;=================================================
GET_PHYSICAL_ADRS:
	PUSH	DE				;
	PUSH	HL				;
	CALL	DW0_PUSH			;(DW0)を退避
	LD	HL,PP_SCTR			;(DW0)<-セクタ＃+プライマリパーティションの開始セクタ＃
	LD	DE,DW1				;
	CALL	DW_COPY				;
	CALL	DW0_ADD				;
	CALL	DW_X512				;(MMCADR0)<-セクタ＃*セクタサイズ=物理アドレス
	LD	HL,DW0				;
	LD	DE,MMCADR0			;
	CALL	DW_COPY				;
	CALL	DW0_POP				;(DW0)を復旧
	POP	HL				;
	POP	DE				;
	RET					;

;=================================================
;[FS]セクタを指定領域に読み込む
;IN  (DW0)=読み込みたいセクタ＃,HL=メモリ領域の先頭アドレス
;OUT (MMCADR0~3)
;=================================================
READ_SCTR:
	CALL	GET_PHYSICAL_ADRS		;(MMCADR0)<-セクタ＃(DW0)の物理アドレス
	LD	B,01H				;=MMCブロック数
	CALL	MMC_READ			;メモリ<-セクタデータ200Hバイト
	RET					;


;=================================================
;[SUB]エラーメッセージ表示
;IN  HL=メッセージのアドレス
;OUT -
;=================================================
ERR:
	CALL	PRINT				;
	CALL	PUT_CR				;
	LD	E,UNPRINTABLE			;
	JP	ERROR				;

;=================================================
;[SUB]文字列を表示する
;IN  (SP)=文字列の先頭アドレス
;OUT -
;=================================================
IPRINT:
	EX	(SP),HL				;
	PUSH	AF				;
.L1:	LD	A,(HL)				;
	INC	HL				;
	OR	A				;
	JR	Z,.L2				;
	RST	18H				;
	JR	.L1				;
.L2:	POP	AF				;
	EX	(SP),HL				;
	RET					;

;=================================================
;ダブルワードスタック初期化
;=================================================
INIT_DW:
	LD	HL,DW_STACK			;
	LD	(DW_SP),HL			;
	RET					;

;=================================================
;ダブルワードをコピーする
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
;ダブルワード(DW0)をスタックに積む
;IN  DW0
;OUT -
;=================================================
DW0_PUSH:
	PUSH	DE				;
	PUSH	HL				;
	LD	HL,DW0				;
	JP	DW_PUSH.E1			;

;=================================================
;ダブルワード(HL)をスタックに積む
;IN  HL
;OUT -
;=================================================
DW_PUSH:
	PUSH	DE				;
	PUSH	HL				;
.E1:	LD	(DW_SP_ORG),SP			;システムのスタックポインタを一時エリアに退避する
	LD	SP,(DW_SP)			;スタックポインタをダブルワード用に変更する
	LD	E,(HL)				;<-最下位バイト
	INC	HL				;
	LD	D,(HL)				;<-第２位バイト
	INC	HL				;
	PUSH	DE				;
	LD	E,(HL)				;<-第３位バイト
	INC	HL				;
	LD	D,(HL)				;<-最上位バイト
	PUSH	DE				;
	LD	(DW_SP),SP			;ダブルワード用スタックポインタを保存する
	LD	SP,(DW_SP_ORG)			;システムのスタックポインタを復旧する
	POP	HL				;
	POP	DE				;
	RET					;

;=================================================
;ダブルワード(DW0)をスタックから取り出す
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
;ダブルワード(HL)をスタックから取り出す
;IN  HL
;OUT (HL)
;=================================================
DW_POP:
	PUSH	BC				;
	PUSH	DE				;
	PUSH	HL				;
.E1:	LD	(DW_SP_ORG),SP			;システムのスタックポインタを一時エリアに退避する
	LD	SP,(DW_SP)			;スタックポインタをダブルワード用に変更する
	POP	DE				;
	POP	BC				;
	LD	(HL),C				;<-最下位バイト
	INC	HL				;
	LD	(HL),B				;<-第２位バイト
	INC	HL				;
	LD	(HL),E				;<-第３位バイト
	INC	HL				;
	LD	(HL),D				;<-最上位バイト
	LD	(DW_SP),SP			;ダブルワード用スタックポインタを保存する
	LD	SP,(DW_SP_ORG)			;システムのスタックポインタを復旧する
	POP	HL				;
	POP	DE				;
	POP	BC				;
	RET					;

;=================================================
;ダブルワード(DW0)を０にする
;IN  -
;OUT (DW0)
;=================================================
DW0_CLR:
	PUSH	HL				;
	LD	HL,DW0				;
	JP	DW_CLR.E1			;

;=================================================
;ダブルワード(HHLL)を０にする
;IN  HL
;OUT (HHLL)
;=================================================
DW_CLR:
	PUSH	HL				;
.E1:	XOR	A				;DW0_CLRのエントリポイント
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
;ダブルワード加算 (DW0)<-(DW0)+(DW1)
;IN  DW0=被加算数のポインタ,DW1=加算数のポインタ
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
;ダブルワード加算 (HL)<-(HL)+(DE)
;IN  HL=被加算数のポインタ,DE=加算数のポインタ
;OUT (HL),CY
;=================================================
DW_ADD:
	PUSH	BC				;
	PUSH	DE				;
	PUSH	HL				;
.E1:	LD	B,4				;DW0_ADDのエントリポイント
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
;ダブルワード(DW0)を2倍する
;IN  -
;OUT (DW0),CY<-BIT31
;=================================================
DW0_X2:
	PUSH	HL				;
	LD	HL,DW0				;
	JP	DW_X2.E1			;

;=================================================
;ダブルワード(HL)を2倍する
;IN  HL
;OUT (HL),CY<-BIT31
;=================================================
DW_X2:
	PUSH	HL				;
.E1:	SLA	(HL)				;BIT0<-0,CY<-BIT7
	INC	HL				;+1 フラグは変化しない
	RL	(HL)				;BIT8<-CY,CY<-BIT15
	INC	HL				;+2
	RL	(HL)				;BIT16<-CY,CY<-BIT23
	INC	HL				;+3
	RL	(HL)				;BIT24<-CY,CY<-BIT31
	POP	HL				;
	RET					;

;=================================================
;DW0を256倍する
;IN  (DW0)
;OUT -
;=================================================
DW_X256:
	PUSH	AF				;
	PUSH	BC				;
	PUSH	DE				;
	PUSH	HL				;
	LD	HL,DW0+2			;転送元 00 01 02 03
	LD	DE,DW0+3			;転送先 XX 00 01 02
	LD	BC,0003H			;転送回数
	LDDR					;BC--,DE--,HL--
	XOR	A				;
	LD	(DE),A				;(DW0+0)<-0
	POP	HL				;
	POP	DE				;
	POP	BC				;
	POP	AF				;
	RET					;

;=================================================
;DW0を512倍する
;IN  (DW0)
;OUT CY
;=================================================
DW_X512:
	CALL	DW0_X2				;
	CALL	DW_X256				;
	RET					;

;=================================================
;[MMC]8255モードセット
;=================================================
INIT_8255:
	PUSH	HL

	LD	A,099H
	OUT	(A8255+3),A
	LD	A,0F7H
	OUT	(A8255+1),A
	IN	A,(A8255+1)
	CP	0F7H
	JR	Z,.L1

	LD	HL,MSG_NOT_FOUND
	CALL	PRINT
	CALL	KEYWAIT

.L1:	LD	A,0FFH
	OUT	(A8255+1),A

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
.L1:	IN	A,(A8255+1)
	AND	0FEH
	OUT	(A8255+1),A
	CALL	MMC_WAIT
	IN	A,(A8255+1)
	AND	0FDH
	RL	C
	JR	NC,.L2
	OR	02H
.L2:	OUT	(A8255+1),A
	CALL	MMC_WAIT
	IN	A,(A8255+1)
	OR	01H
	OUT	(A8255+1),A
	CALL	MMC_WAIT
	DJNZ	.L1
	POP	BC
	IN	A,(A8255+1)
	OR	02H
	OUT	(A8255+1),A
	RET

;=================================================
;[MMC]MMCから1バイト受け取る
;IN  -
;OUT C=受信データ
;=================================================
MMC_1RD:
	LD	B,8
.LOOP:	IN	A,(A8255+1)
	AND	0FEH
	OUT	(A8255+1),A
        OR	001H
	OUT	(A8255+1),A
	XOR	A
	RL	C
	IN	A,(A8255+2)
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

	IN	A,(A8255+1)
	AND	0FEH
	OUT	(A8255+1),A
	CALL	MMC_WAIT
	IN	A,(A8255+1)
	OR	001H
	OUT	(A8255+1),A
	CALL	MMC_WAIT
	IN	A,(A8255+2)
	AND	010H
	JR	NZ,.LOOP

	LD	BC,0700H
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
	IN	A,(A8255+1)
	AND	11111110B
	OUT	(A8255+1),A
	CALL	MMC_WAIT
	IN	A,(A8255+1)
	OR	00000001B
	OUT	(A8255+1),A
	CALL	MMC_WAIT
	DJNZ	MMC_CLK
	RET

;=================================================
;[MMC]CS=HにしてMMCクロックX8
;=================================================
MMC_CLK8:
	IN	A,(A8255+1)
	OR	00000100B
	OUT	(A8255+1),A  			;CS=H
	LD	B,8
	CALL	MMC_CLK   			;MMCクロック実行
	IN	A,(A8255+1)
	AND	11111011B
	OUT	(A8255+1),A  			;CS=L
	RET

;=================================================
;[MMC]MMCをSPIモードに初期化する
;=================================================
MMC_INIT:
	IN	A,(A8255+1)
	OR	00000100B
	OUT	(A8255+1),A
	LD	B,200
	CALL	MMC_CLK
	IN	A,(A8255+1)
	AND	11111011B
	OUT	(A8255+1),A
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

	DJNZ	MMC_READ
	RET

;=================================================
;[MMC]12クロックのウェイト挿入
;=================================================
MMC_WAIT:
	NOP
	NOP
	NOP
	RET

MSG_NOT_FOUND:	DB	"NOT FOUND",CR,LF,EOL

FILE_BFFR:	DS	200H			;ファイルバッファ

TIMEOUT:	DS	01H			;MMCタイムアウトカウンタ
MMCADR0:	DS	01H			;MMCアドレス LSB
MMCADR1:	DS	01H			;
MMCADR2:	DS	01H			;
MMCADR3:	DS	01H			;MMCアドレス MSB

BPB:		DS	13H			;BPB保存エリア
PP_SCTR:	DS	04H			;プライマリパーティションの開始セクタ＃
ROOT_SCTR_SIZE:	DS	01H			;ルートディレクトリの総セクタ数
FAT_SCTR:	DS	04H			;FATの開始セクタ＃ BPB+3をコピーしてDWORD化する
ROOT_SCTR:	DS	04H			;ルートディレクトリの開始セクタ＃
DATA_SCTR:	DS	04H			;データエリアの開始セクタ＃

DWA:		DS	04H			;汎用ダブルワード変数
DW0:		DS	04H			;ダブルワード変数
DW1:		DS	04H			;ダブルワード変数
DW_SP_ORG:	DS	02H			;ダブルワード用スタックポインタの一時退避エリア
DW_SP:		DS	02H			;ダブルワード用スタックポインタ
		DS	10H			;ダブルワード用スタックエリア
DW_STACK	EQU	$			;
