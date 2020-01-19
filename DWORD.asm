
;=================================================
;ダブルワード用ワーク LSB<<<MSB
;=================================================
;DW0:		DB	00H,00H,00H,00H		;変数
;DW1:		DB	00H,00H,00H,00H		;変数
;DW_SP_ORG:	DB	00H,00H			;スタックポインタの一時退避エリア
;DW_SP:		DB	00H,00H			;ダブルワード用スタックポインタ
;		DB	00H,00H,00H,00H		;ダブルワード用スタックエリア
;		DB	00H,00H,00H,00H		;
;		DB	00H,00H,00H,00H		;
;		DB	00H,00H,00H,00H		;
;DW_STACK	EQU	$			;

;=================================================
;ダブルワードスタック初期化
;=================================================
INIT_DW:
	LD	HL,DW_STACK			;
	LD	(DW_SP),HL			;
	RET					;

;=================================================
;ダブルワード変数にレジスタの値をロードする
;IN  HL=DW変数のポインタ,BCDE=MSB->LSB
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
;ダブルワード(DW0)(DW1)を比較する
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
;ダブルワード(HHLL)(DDEE)を比較する
;IN  HL,DE
;OUT (HHLL)<(DDEE):CY=1 Z=?
;    (HHLL)=(DDEE):CY=0 Z=1
;    (HHLL)>(DDEE):CY=0 Z=0
;=================================================
DW_CP:
	PUSH	BC				;
	PUSH	DE				;DW0_CPと整合を取るために入れている
	PUSH	HL				;
.E1:	PUSH	HL				;DW_POP用に退避
	CALL	DW_PUSH				;(HHLL)を退避する
	CALL	DW_SUB				;(HHLL)<-(HHLL)-(DDEE)
	JR	C,.EXIT				;CY=1なら(HHLL)<(DDEE) Zは無視してよい
	XOR	A				;A<-0, CY<-0
	LD	BC,0004H			;=バイト数
.L1:	CPI					;A-(HL) HL++ BC--
	JR	NZ,.EXIT			;結果が0ではないので(HHLL)>(DDEE) CY=0, Z=0
	JP	PE,.L1				;結果が0なので(HHLL)=(DDEE) CY=0, Z=1
.EXIT:	POP	HL				;DW_POP用に復帰
	PUSH	AF				;フラグを退避
	CALL	DW_POP				;(HHLL)を復旧する
	POP	AF				;
	POP	HL				;
	POP	DE				;
	POP	BC				;
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
;ダブルワード(DW0)に即値をロードする
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
;ダブルワード交換 (DW0)<->(DW1)
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
;ダブルワード交換 (DE)<->(HL)
;IN  DE,HL
;OUT (DE),(HL)
;=================================================
DW_SWAP:
	PUSH	BC				;
	PUSH	DE				;
	PUSH	HL				;
.E1:	LD	B,4				;DW0_SWAPのエントリポイント
.L1:	LD	C,(HL)				;C<-(HL)
	LD	A,(DE)				;A<-(DE)
	EX	DE,HL				;
	LD	(HL),C				;(DE)<-C
	LD	(DE),A				;(HL)<-A
	EX	DE,HL				;結果として(HL)と(DE)が入れ替わっている
	INC	HL				;
	INC	DE				;
	DJNZ	.L1				;
	POP	HL				;
	POP	DE				;
	POP	BC				;
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
;ダブルワード減算 (DW0)<-(DW0)-(DW1)
;IN  DW0=被減算数のポインタ,DW1=減算数のポインタ
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
;ダブルワード減算 (HL)<-(HL)-(DE)
;IN  HL=被減算数のポインタ,DE=減算数のポインタ
;OUT (HL),CY
;=================================================
DW_SUB:
	PUSH	BC				;
	PUSH	DE				;
	PUSH	HL				;
.E1:	EX	DE,HL				;SBC命令でDEが使えないため入れ替える
	LD	B,4				;=バイト数
	OR	A				;CY<-0
.L1:	LD	A,(DE)				;実質は (HL)<-(HL)-(DE)
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
;ダブルワード(DW0)に１加算する
;IN  -
;OUT (DW0)
;=================================================
DW0_INC:
	PUSH	HL				;
	LD	HL,DW0				;
	JP	DW_INC.E1			;

;=================================================
;ダブルワード(HHLL)に１加算する
;IN  HL=ダブルワードのポインタ
;OUT (HHLL)
;=================================================
DW_INC:
	PUSH	HL				;
.E1:	INC	(HL)				;最下位バイトに１加算して０にならなければ
	JR	NZ,.EXIT			;桁上りがないと判断し終了へ
	INC	HL				;第２バイトに１加算して０にならなければ
	INC	(HL)				;桁上りがないと判断し終了へ
	JR	NZ,.EXIT			;
	INC	HL				;第３バイトに１加算して０にならなければ
	INC	(HL)				;桁上りがないと判断し終了へ
	JR	NZ,.EXIT			;
	INC	HL				;最上位バイトに１加算
	INC	(HL)				;
.EXIT:	POP	HL				;
	RET					;

;=================================================
;ダブルワード(DW0)を１減算する
;IN  -
;OUT (DW0),CY
;=================================================
DW0_DEC:
	PUSH	HL				;
	PUSH	BC				;
	LD	HL,DW0				;
	JP	DW_DEC.E1			;

;=================================================
;ダブルワード(HL)を１減算する
;IN  HL=ダブルワードのポインタ
;OUT (HL),CY
;=================================================
DW_DEC:
	PUSH	HL				;
	PUSH	BC				;
.E1:	LD	A,(HL)				;最下位バイトから１減算して
	SUB	1				;桁借りが生じなければ終了へ ！DECはCYが変化しないので使用できない！
	LD	(HL),A				;
	JR	NC,.EXIT			;
	INC	HL				;
	LD	BC,0300H			;B=ループ数, C=0
.L1:	LD	A,(HL)				;第２バイトから最上位バイトまで
	SBC	A,C				;キャリー付き減算を繰り返す
	LD	(HL),A				;
	JR	NC,.EXIT			;桁借りが生じなければ終了へ
	INC	HL				;
	DJNZ	.L1				;
.EXIT:	POP	BC				;
	POP	HL				;
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
;ワードの乗算 (DW0)<-HLxDE 結果はダブルワード
;HL X DE
;IN  HL=被乗数,DE=乗数
;OUT (DW0)
;=================================================
HLXDE:
	PUSH	BC				;
	CALL	DW0_CLR				;DW0,DW1<-0
	CALL	DW0_SWAP			;
	CALL	DW0_CLR				;
	LD	A,L				;
	LD	(DW0+0),A			;(DW0)<-HL=被乗数
	LD	A,H				;
	LD	(DW0+1),A			;
	LD	B,16				;ループ数
.L2:	SRL	D				;乗数DEを右シフトする
	RR	E				;CY<-BIT0
	JR	NC,.L1				;CY=1なら被乗数を結果に加算する
	CALL	DW0_SWAP			;(DW0)=結果, (DW1)=被乗数
	CALL	DW0_ADD				;(DW0)<-(DW0)+(DW1)
	CALL	DW0_SWAP			;(DW0)=被乗数, (DW1)=結果
.L1:	CALL	DW0_X2				;被乗数を左シフトして2倍にする
	DJNZ	.L2				;
	CALL	DW0_SWAP			;(DW0)=結果, (DW1)=被乗数
	POP	BC				;
	RET					;

