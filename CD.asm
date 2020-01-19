
;=================================================
;[CD]ディレクトリエントリバッファのエントリ名をゼロクリアする
;=================================================
CLR_DNAME:
	PUSH	HL				;
	LD	HL,DNAME			;
	CALL	NULL_STR			;
	POP	HL				;
	RET

;=================================================
;[CD]パス文字列で指定されたディレクトリに、ワーキングディレクトリを移動する
;IN  (ARG0)=パス文字列の先頭アドレス
;OUT HL=エントリ名の先頭アドレス,(WDIR_CLSTR)=新しいワーキングディレクトリのクラスタ＃,(WDIR_ORG)=実行前ワーキングディレクトリのクラスタ＃
;=================================================
CHANGE_WDIR:
	CALL	STORE_WDIR			;ワーキングディレクトリのクラスタ＃を退避する
	LD	HL,(ARG0)			;HL<-パス文字列の先頭アドレス
	CALL	SPLIT_FPATH			;パスとファイル名を00Hで分割する
	RET	NC				;CY=1ならパス部が存在するので、ディレクトリを移動する
	CALL	TRACE_PATH			;
	INC	HL				;HLは分割点を指しているので、１つ進めてファイル名の先頭に合わせる
	RET

;=================================================
;[CD]ワーキングディレクトリを、(DIR_ENTRY)に一致するサブディレクトリに移動する
;IN  (DIR_ENTRY+IDX_NAME),(DIR_ENTRY+IDX_ATRB)
;OUT (WDIR_CLSTR)
;=================================================
ENTER_SUBDIR:
	PUSH	HL				;
	LD	A,(DIR_ENTRY+IDX_NAME)		;文字列の先頭が00Hなら中身は空なので終了する
	OR	A				;
	JR	Z,.EXIT				;
	LD	HL,DNAME			;
	CALL	EOL2SPC				;エントリ名の00Hをすべて20Hに変換する
	LD	A,ATRB_DIR			;
	LD	(DIR_ENTRY+IDX_ATRB),A		;
	CALL	GET_DENT.MAIN			;
	JP	Z,ERR_NOT_FOUND			;
	LD	HL,(DIR_ENTRY+IDX_FAT)		;HL<-一致したディレクトリエントリのクラスタ＃
.E1:	LD	(WDIR_CLSTR),HL			;(WDIR_CLSTR)<-ディレクトリエントリのクラスタ＃
.EXIT:	POP	HL				;
	RET					;

;=================================================
;[CD]ワーキングディレクトリをルートディレクトリに移動する
;=================================================
ENTER_ROOT:
	PUSH	HL
	LD	HL,ROOT
	JR	ENTER_SUBDIR.E1

;=================================================
;[CD]パス付きファイル名を、パス部とファイル名部に分割する
;・例 "/DIR/DIR/FILE.EXT" -> "/DIR/DIR",00H,"FILE.EXT"
;IN  HL=文字列の先頭アドレス
;OUT HL=文字列の先頭アドレス,CY=1:パスとファイル名を分割した
;=================================================
SPLIT_FPATH:
	PUSH	HL				;
	PUSH	HL				;文字列の先頭アドレスを退避
.L1:	LD	A,(HL)				;HLを文字列の末尾+1まで進める
	INC	HL				;
	CALL	IS_EOT				;
	JR	NZ,.L1				;
	DEC	HL				;HL<-末尾アドレス
	POP	DE				;DE<-先頭アドレス
	CALL	CPHLDE				;末尾アドレス:先頭アドレス
	JR	Z,.EXIT				;文字列の先頭アドレスと末尾アドレスが同じなら戻る。CY<-0
	PUSH	HL				;文字列の末尾アドレスを退避
	OR	A				;
	SBC	HL,DE				;HL<-末尾アドレス-先頭アドレス=文字列の長さ-1
	INC	HL				;HL<-文字列の長さ
	LD	B,H				;BC<-文字列の長さ
	LD	C,L				;
	POP	HL				;HL<-文字列の末尾アドレス
	LD	A,"/"				;A<-検索する文字
	CPDR					;A:(HL),HL--,BC--
	JR	Z,.FOUND			;
	OR	A				;CY<-0
	JR	.EXIT				;

.FOUND:	XOR	A				;分割点に識別用コードを挿入する
	INC	HL				;
	LD	(HL),A				;
	SCF					;CY<-1
.EXIT:	POP	HL				;
	RET					;

;=================================================
;[CD]パス文字列の先頭から00Hまでの範囲を解析し、順次ワーキングディレクトリを移動する
;IN  HL=パス文字列の先頭アドレス
;OUT (WDIR_CLSTR)=パス文字列から求められたクラスタ＃,HL=エントリ名の開始アドレス-1
;=================================================
TRACE_PATH:
	LD	A,(HL)				;！重要！最初の文字が00Hなら「ルート」に移動して終了
	OR	A				;例えば"/FILE.EXT" は 00H,"FILE.EXT" と変換されるため
	JR	Z,ENTER_ROOT			;
	CP	"/"				;最初の文字が"/"なら「ルート」に移動
	JR	NZ,.L4				;
	CALL	ENTER_ROOT			;
	INC	HL				;
.L4:	CALL	CLR_DNAME			;バッファのエントリ名を00Hでクリア
.L1:	LD	A,(HL)				;Aが00Hまたは22Hなら
	CALL	IS_EOT				;
	JR	Z,ENTER_SUBDIR			;バッファに残っているディレクトリに移動して終了
	INC	HL				;区切り文字検出
	CP	"/"				;
	JR	NZ,.ADD				;
	CALL	ENTER_SUBDIR			;ディレクトリ移動実行
	JR	.L4				;

.ADD:	PUSH	HL				;
	CALL	FIX_CHR				;文字コードを修正
	CALL	IS_NGCHR			;使用できない文字を検出
	LD	HL,DNAME			;
	LD	C,A				;
	CALL	ADD_STR				;エントリ名に文字を追加する
	POP	HL				;
	JR	.L1				;

;=================================================
;[CD]ワーキングディレクトリのクラスタ＃を退避する
;IN  (WDIR_CLSTR)
;OUT (WDIR_ORG)
;=================================================
STORE_WDIR:
	LD	HL,(WDIR_CLSTR)			;
	LD	(WDIR_ORG),HL			;
	RET

;=================================================
;[CD]ワーキングディレクトリのクラスタ＃を復帰する
;IN  (WDIR_ORG)
;OUT (WDIR_CLSTR)
;=================================================
RESTORE_WDIR:
	LD	HL,(WDIR_ORG)			;
	LD	(WDIR_CLSTR),HL			;
	RET

;=================================================
;[STR]文字列の00Hを20Hに変換する
;IN  HL=文字列の先頭アドレス
;OUT 文字列(HL)
;=================================================
EOL2SPC:
	LD	B,(HL)				;B<-文字数
	INC	HL				;
.L1:	LD	A,(HL)				;
	OR	A				;
	JR	NZ,.L2				;
	LD	(HL),SPC			;
.L2:	INC	HL				;
	DJNZ	.L1				;
	RET

