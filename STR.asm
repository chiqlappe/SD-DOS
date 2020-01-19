
;=================================================
;[STR]".",".."文字列の判別
;IN  HL=TP
;OUT (DIR_ENTRY)
;・文字列が"."あるいは".."の場合にのみ(DIR_ENTRY)にセットされる
;=================================================
IS_DOT:
	PUSH	HL				;TP退避
	LD	B,DNAME_SIZE			;B<-ファイル名全体の長さ
	LD	A,(HL)				;A<-先頭の文字
	CP	"."				;
	JR	NZ,.EXIT			;"."でなければ終了
	CALL	SFN_ADD_STR			;ディレクトリエントリバッファにセット
	DEC	B				;=残りの文字数
	LD	A,(HL)				;
	CP	"."				;
	JR	NZ,.L2				;"."
	CALL	SFN_ADD_STR			;".."
	DEC	B				;
	LD	A,(HL)				;
.L2:	CALL	IS_EOT				;"."の後に文字が続いたらエラー
	JR	Z,.L1				;
	LD	E,ILLEGAL_FUNCTION_CALL		;
	JP	ERROR				;

.L1:	CALL	SFN_ADD_SPC			;Bの数だけ出力先に空白を加える
	POP	BC				;退避していたTPを捨てる
	POP	BC				;CALLの戻り先を捨てる
	RET					;

.EXIT:	POP	HL				;TP復帰
	RET					;

;=================================================
;[STR]文字列を8.3形式ファイル名に変換する
;IN  HL=TP
;OUT (DNAME+1)=8.3形式ファイル名,HL=文字列のポインタ
;・最初に現れたピリオドは、(8-n)個の空白に置き換える
;・２番目以降のピリオドは無視
;=================================================
STR2SFN:
	LD	DE,DNAME			;DE<-文字列の出力先
	EX	DE,HL				;出力先の中身をNULLにする
	CALL	NULL_STR			;
	EX	DE,HL				;
	CALL	IS_DOT				;"..","."の判別
	XOR	A				;A'=文字数カウンタ
	EX	AF,AF'				;A'<-0
	LD	B,08H				;ここからファイル名部
.L1:	LD	A,(HL)				;A<-(TP)
	CALL	IS_EOT				;二重引用符か00Hなら
	JR	Z,.L7				;残りのファイル名部を20Hで埋める ！拡張子解析部でも利用するためHLは動かさない！
	CP	"."				;ピリオドなら！HLを進めて！残りのファイル名部を20Hで埋める
	JR	NZ,.L4				;それ以外なら文字列(DNAME)に文字Aを加える
	INC	HL				;TP++
.L7:	CALL	SFN_ADD_SPC			;Bの数だけ出力先に空白を加える
	JR	.L2				;

.L4:	CALL	SFN_ADD_STR			;(DNAME)に文字Aを加える
	CALL	.COUNT				;文字数A'++
	DJNZ	.L1				;
.L2:	LD	B,03H				;ここから拡張子部
.L3:	LD	A,(HL)				;A<-(TP)
	CALL	IS_EOT				;
	JR	NZ,.L5				;二重引用符か00Hなら
	CALL	SFN_ADD_SPC			;Bの数だけ出力先に空白を加える
	JR	.EXIT				;終了へ

.L5:	CP	"."				;！重要！拡張子部にピリオドがあれば全てスキップする
	JR	NZ,.L6				;
	INC	HL				;TP++
	JR	.L3				;
.L6:	CALL	SFN_ADD_STR			;(DNAME)に文字Aを加える
	CALL	.COUNT				;文字数A'++
	DJNZ	.L3				;
	LD	A,(HL)				;ファイル名の最大文字数を超えて入力していたらエラーにする
	CALL	IS_EOT				;
	JR	Z,.EXIT				;
	LD	E,ILLEGAL_FUNCTION_CALL		;
	JP	ERROR				;

.EXIT:	EX	AF,AF'				;A'=文字数カウンタ
	OR	A				;出力された文字列の文字数が０ならエラー
	RET	NZ				;
	LD	HL,MSG_NO_NAME			;
	JP	ERR				;

.COUNT:	EX	AF,AF'				;文字数カウンタ++
	INC	A				;
	EX	AF,AF'				;
	RET					;

;=================================================
;[STR]ファイル名用文字列に１文字追加する
;IN  A=文字コード,HL=TP,DE=出力先のポインタ
;=================================================
SFN_ADD_STR:
	CALL	FIX_CHR				;文字コードを修正
	CALL	IS_NGCHR			;使用できない文字を検出
	LD	C,A				;
	EX	DE,HL				;
	CALL	ADD_STR				;出力先に文字を加える
	EX	DE,HL				;
	INC	DE				;出力先のポインタを進める
	INC	HL				;テキストポインタを進める
	RET					;

;=================================================
;[STR]ファイル名用文字列に空白を指定数だけ追加する
;IN  B=追加する数,HL=TP,DE=出力先のポインタ
;=================================================
SFN_ADD_SPC:
	LD	C,SPC				;
	EX	DE,HL				;HL=出力先のポインタ,DE=TP
.L1:	CALL	ADD_STR				;(DEST)+=20H
	INC	HL				;出力先のポインタを進める
	DJNZ	.L1				;
	EX	DE,HL				;HL=TP,DE=出力先のポインタ
	RET					;

;=================================================
;[STR]大文字化と"^"->"~"の修正
;IN  A=文字コード
;OUT A=修正された文字コード
;=================================================
FIX_CHR:
	CALL	CAPITAL				;大文字化
	CP	"^"				;"^"を、キーボードから入力できない文字"~"に変換する
	RET	NZ				;
	LD	A,"~"				;
	RET					;

;=================================================
;[STR]エントリ名に使用できない文字チェック
;IN  A=対象の文字
;OUT Z=1:NG文字と一致した
;=================================================
IS_NGCHR:
	PUSH	BC				;
	PUSH	HL				;
	LD	HL,NG_CHR			;
	LD	BC,NG_CHR_END - NG_CHR		;BC<-NG_CHRの総文字数
	CPIR					;
	JR	Z,.ERR				;
	POP	HL				;
	POP	BC				;
	RET					;

.ERR:	LD	HL,MSG_NG_CHR			;
	JP	ERR				;

;=================================================
;[STR]二重引用符＆00Hのチェック 引数の文字列解析に使用される
;IN  A=文字コード
;OUT Z=1:文字列終了
;=================================================
IS_EOT:	CP	DQUOTE				;Aが二重引用符または0ならZ<-1
	RET	Z				;
	OR	A				;
	RET					;

;=================================================
;[STR]指定された固定長文字列全体を文字で埋める
;IN  HL=固定長文字列のポインタ,C=文字コード
;OUT
;=================================================
NULL_STR:
	LD	C,00H				;
FILL_STR:
	PUSH	BC				;
	PUSH	HL				;
	LD	B,(HL)				;
	INC	HL				;
.L1:	LD	(HL),C				;
	INC	HL				;
	DJNZ	.L1				;
	POP	HL				;
	POP	BC				;
	RET					;

;=================================================
;[STR]固定長文字列の最初のNULL部分を文字で置き換える
;NULL部分が無い場合は無視される
;IN  HL=文字変数のポインタ,C=追加する文字コード
;OUT　
;=================================================
ADD_STR:
	PUSH	BC				;
	PUSH	HL				;
	LD	B,(HL)				;B<-文字列長
.L2:	INC	HL				;
	LD	A,(HL)				;ポインタが示す値が00Hなら、その位置にCをセットする
	OR	A				;それ以外なら00Hが見つかるまで繰り返す
	JR	NZ,.L3				;
	LD	(HL),C				;
	JR	.EXIT				;
.L3:	DJNZ	.L2				;
.EXIT:	POP	HL				;
	POP	BC				;
	RET					;

