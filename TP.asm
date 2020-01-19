
;=================================================
;[TP]カンマで区切られた２つの文字列式のポインタを取得する
;IN  HL=TP
;OUT (ARG0)=１番目の文字列式のポインタ,(ARG1)=２番目の文字列式のポインタ
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
;[TP]テキストポインタの式を評価して16ビットレジスタに取得する
;・値=0000~FFFFH
;IN  HL=TP
;OUT HL=TP,DE=式の結果
;=================================================
EXP2WORD:
	RST	10H				;！重要！
.SKIP:	CALL	EVALEXP				;FAC<-式の計算結果
	PUSH	HL				;TP退避
	CALL	FAC2INT				;HL<-INT(FAC)
	EX	DE,HL				;
	POP	HL				;TP復帰
	RET					;

;=================================================
;[TP]テキストポインタの式を評価して８ビットレジスタに取得する
;・値=00~FFH
;IN  HL=TP
;OUT HL=TP,A=式の結果
;=================================================
IF FALSE

EXP2BYTE:
	RST	10H				;！重要！BASIC解析命令
	CALL	BYTE_EVALEXP			;A<-式の計算結果(0~255)
	RET

ENDIF

;=================================================
;[TP]テキストポインタ以降の文字列とコマンドテーブルを比較して、一致すればジャンプする
;IN  C=ジャンプ用インデックスの初期値,DE=コマンドテーブルポインタ,HL=現在のテキストポインタ
;OUT HL=次のテキストポインタ
;=================================================
WORD_JUMP:
	CALL	SKIP_SPC			;
.L1:	PUSH	HL				;TPを退避
	LD	A,(DE)				;ここでDEはコマンド文字列の先頭を指している
	OR	A				;その値が00Hならすべて不一致を意味するので
	JR	NZ,.L3				;エラーを出力して終了
	LD	E,SYNTAX_ERROR			;
	JP	ERROR				;
.L3:	CP	(HL)				;コマンド文字とTPの内容を比較
	JR	Z,.EQUAL			;等しくなければ次のコマンド文字列へ
.NEXT:	INC	DE				;コマンド文字に00Hが見つかるまでCPを進める
	LD	A,(DE)				;
	OR	A				;
	JR	NZ,.NEXT			;
	INC	DE				;00Hの次の文字にポインタをセットする
	INC	C				;ジャンプ用インデックス値++
	POP	HL				;TPを復帰
	JR	.L1				;
.EQUAL:	INC	DE				;ここから文字が等しい場合の処理
	INC	HL				;TPとCPを１進める
	LD	A,(DE)				;CPが指す内容が文字列終端マーカーならすべて一致したことになるので
	OR	A				;一致処理へ進む
	JR	NZ,.L3				;
	POP	DE				;ここから一致処理。スタックに退避していたTPを捨てる
	PUSH	HL				;現在のTPを退避
	LD	HL,JUMP_TABLE			;HL<-JUMP_TABLE+C*2=ジャンプ先
	SLA	C				;
	LD	B,0				;
	ADD	HL,BC				;
	LD	A,(HL)				;HL<-(HL)=ジャンプ先
	INC	HL				;
	LD	H,(HL)				;
	LD	L,A				;
	EX	(SP),HL				;(SP)<-ジャンプ先,HL<-現在のTP
	RET					;ここでスタックからジャンプ先が取り出される

;=================================================
;[TP]TPを開二重引用符の次に進める。存在しなければエラーにする
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
;[TP]TPを閉二重引用符の次に進める
;IN  HL=TP
;OUT HL=TP
;=================================================
CLOSE_DQUOTE:
	LD	C,DQUOTE			;
	CALL	SKIP_CHR			;
	RET					;

;=================================================
;[TP]空白以外の文字が現れるまでTPを進める
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
;[TP]指定された文字の次、または00HまでTPを進める
;IN  HL=TP,C=スキップする文字
;OUT HL=新しいTP,CY=1:目的の文字が見つかった 0:EOLが見つかった
;=================================================
SKIP_CHR:
.L1:	LD	A,(HL)				;EOLならCY<-0で終了
	OR	A				;
	RET	Z				;
	INC	HL				;TPを進める
	CP	C				;目的の文字ならCY<-1で終了
	JR	NZ,.L1				;
	SCF					;
	RET					;

