
;CMTファイルフォーマット

BIN_MARK: 	EQU	03AH	;CMTファイルで使用されるマシン語用マーカー
BAS_MARK: 	EQU	0D3H	;CMTファイルで使用されるBASIC用マーカー
BAS_MARK_LEN:	EQU	0AH	;CMTファイルで使用されるBASIC用マーカーの数

;BAS_ZERO:	EQU	04H	;BASICファイルの終端を判定するための00Hの数
BAS_ZERO:	EQU	0AH	;BASICファイルの終端を判定するための00Hの数

CMT_STACK_LVL:	EQU	40H	;OUT OF MEMORY判定用のスタックレベル=だいたいの値
BFNAME_SIZE:	EQU	06H	;BASICファイル名の長さ
;CMT_ZERO:	EQU	10H	;CMTファイルの終端を判定するための00Hの数

;-------------------------------------------------
;BASICプログラムファイル構造
;-------------------------------------------------
;ヘッダー	10 バイト D3 D3 D3 D3 D3 D3 D3 D3 D3 D3 
;ファイル名	 6 バイト XX XX XX XX XX XX 
;プログラム本体	
;エンドマーク	 3 バイト 00 00 00
;フッター	 9 バイト 00 00 00 00 00 00 00 00 00
;-------------------------------------------------

;-------------------------------------------------
;マシン語プログラムファイル構造
;-------------------------------------------------
;スタートアドレス部	3A hi lo cs
;データ部		3A nn XX ... XX cs
;エンドマーク		3A 00 00
;
;hi & lo:アドレス, nn:サイズ, cs:チェックサム
;-------------------------------------------------

;=================================================
;[CMT]CMTファイルの読み込み
;IN  (TGT_CLSTR)
;OUT -
;=================================================
READ_CMT:
	LD	HL,FKEY_POINTER		;ファンクションキーのポインタを初期化 ！オートスタート対策！
	LD	(ACTIVE_FKEY),HL	;
	CALL	PREP_READ		;
.LOOP:	CALL	FETCH_1BYTE		;A<-(FP),FP++
	CP	BAS_MARK		;BASICマーカーか？
	JR	NZ,.L1			;
	CALL	READ_CMT_BASIC		;
	XOR	A			;A<-0
.L1:	CP	BIN_MARK		;マシン語マーカーか？
	JR	NZ,.L3			;
	CALL	READ_CMT_BINARY		;
	XOR	A			;A<-0
.L3:	AND	A			;00Hとマーカー以外の値ならスキップ
	JR	NZ,.L4			;
.L5:	LD	HL,FKEY_FLAG		;ファンクションキー押下フラグが立てられているか
	LD	A,(HL)			;
	OR	A			;
	JR	Z,.L4			;
	CALL	PSEUDO_MON		;キーバッファの文字列を1行だけ疑似モニタ内で処理する。対象は"G"コマンドのみ
.L4:	LD	HL,DIR_ENTRY+IDX_SIZE	;=ファイルサイズのポインタ
	LD	DE,FP			;=FP
	CALL	DW_CP			;FPがファイルサイズを超えるまで繰り返す
	JR	NC,.LOOP		;
	RET

;=================================================
;[CMT]BASICファイルの読み込み
;・終了時にFPはBAS_ZERO個目の00Hを指している
;IN  FP=ファイルポインタ
;OUT FP
;=================================================
READ_CMT_BASIC:
	LD	B,BAS_MARK_LEN-1	;ヘッダーの残り９バイトをチェック
.L4:	CALL	FETCH_1BYTE		;A<-(FP),FP++
	CP	BAS_MARK		;
	JP	NZ,READ_ERR		;
	DJNZ	.L4			;

	LD	HL,INFO_BUF		;
	PUSH	HL			;
	LD	B,BFNAME_SIZE		;=CSAVE命令でのファイル名サイズ
.L1:	CALL	FETCH_1BYTE		;A<-(FP),FP++
	LD	(HL),A			;
	INC	HL			;
	DJNZ	.L1			;
	XOR	A			;
	LD	(HL),A			;=EOL
	POP	HL			;
	CALL	IS_INFO_ON		;
	JR	Z,.L9			;

	CALL	IPRINT			;
	DB	"[BAS]",CR,LF		;
	DB	"NAME:",EOL		;
	CALL	PRINT			;
	CALL	PUT_CR			;

.L9:	LD	HL,(BASBEGIN)		;HL<-BASIC先頭アドレス
	CALL	GET_FIREWALL		;DE<-スタックエリアとフリーエリアの境界値
.L2:	LD	B,BAS_ZERO		;=ファイル終了と判断する00Hの数(ゼロカウンタ)
.L3:	PUSH	BC			;
	CALL	FETCH_1BYTE		;A<-(FP),FP++
	LD	(HL),A			;メモリへ転送
	POP	BC			;
	CALL	CPHLDE			;OUT OF MEMORY チェック
	JR	C,.L5			; HL=アドレス
	LD	E,OUT_OF_MEMORY		; DE=境界値
	JP	ERROR			; HL>=DEでエラー
.L5:	INC	HL			;転送先アドレス++
	OR	A			;値が00Hでなければゼロカウンタを初期値に戻す
	JR	NZ,.L2			;
	DJNZ	.L3			;値が00HならBのカウントダウンを続ける

	JP	FIN_READ_BASIC		;


;=================================================
;[CMT]マシン語ファイルの読み込み
;IN  FP=ファイルポインタ
;OUT FP,Z=1:正常終了
;=================================================
READ_CMT_BINARY:
	CALL	GET_FIREWALL		;スタックエリア侵入防止用の境界値をセットする
	LD	(FIREWALL),DE		;

	CALL	FETCH_1BYTE		;A<-(FP),FP++
	LD	H,A			;HL<-マシン語ファイルの先頭アドレス
	CALL	FETCH_1BYTE		;A<-(FP),FP++
	LD	L,A			;
	CALL	FETCH_1BYTE		;A<-(FP),FP++ チェックバイト部は捨てる

	CALL	IS_INFO_ON		;
	JR	Z,.L1			;
	CALL	IPRINT			;
	DB	"[BIN]",CR,LF		;
	DB	"ADDRESS:",EOL		;
	CALL	PRTHLHEX		;先頭アドレスを表示

.L1:	CALL	FETCH_1BYTE		;A<-(FP),FP++
	CP	BIN_MARK		;マーカーでなければエラー処理へ
	JP	NZ,READ_ERR		;

	CALL	FETCH_1BYTE		;A<-(FP),FP++
	AND	A			;データ長が0なら終了へ
	JR	Z,.L3			;

	LD	B,A			;B=データ長
.L2:	PUSH	BC			;
	CALL	FETCH_1BYTE		;データ転送処理
	LD	(HL),A			;
	INC	HL			;
	CALL	CHECK_STACK_AREA	;スタックエリアに侵入しているかチェックする
	POP	BC			;
	DJNZ	.L2			;データ長だけ繰り返す
	CALL	FETCH_1BYTE		;A<-(FP),FP++ チェックバイト部は捨てる
	JR	.L1			;

.L3:	DEC	HL			;

	CALL	IS_INFO_ON		;
	JR	Z,.L5			;
	LD	A,"-"			;終了アドレスを表示
	RST	18H			;
	CALL	PRTHLHEX		;
	CALL	PUT_CR			;

.L5:	CALL	FETCH_1BYTE		;FP++
	RET				;

;=================================================
;[CMT]リードエラー
;IN  HL=アドレス
;=================================================
READ_ERR:
	CALL	IPRINT			;
	DB	CR,LF,"ERROR IN ",EOL	;
	CALL	PRTHLHEX		;
	CALL	PUT_CR			;
	LD	E,BAD_FILE_DATA		;
	JP	ERROR			;

;=================================================
;[CMT]スタックエリア侵入チェック
;IN  HL=対象のアドレス
;OUT 
;=================================================
CHECK_STACK_AREA:
	PUSH	DE
	PUSH	HL

	EX	DE,HL			;DE=アドレス
	LD	HL,(FREE_END)		;HL<-フリーエリアの底
	CALL	CPHLDE			;
	JR	C,.EXIT			;スタックエリアの底 < アドレス

	LD	HL,(FIREWALL)		;HL<-スタックエリアとフリーエリアの境界値
	CALL	CPHLDE			;
	JR	NC,.EXIT		;スタックエリアとフリーエリアの境界値 >= アドレス

.ERR:	XOR	A			;
	LD	(FKEY_FLAG),A		;！重要！ファンクションキー押下フラグを降ろす
	LD	HL,MSG_MEMORY_CONFLICT	;スタックエリア侵入エラー
	JP	ERR			;

.EXIT:	POP	HL
	POP	DE
	RET

;=================================================
;[CMT]スタックエリアとフリーエリアの境界値を求める
;OUT DE=境界値
;=================================================
GET_FIREWALL:
	PUSH	HL
	LD	HL,-32
	ADD	HL,SP
	EX	DE,HL
	POP	HL
	RET


;=================================================
;[CMT]疑似モニタ
;・"G"コマンドのみ処理し、それ以外のコマンドは無視される
;・プログラム中からコールされた場合は処理を行わない！F5キーで実行した場合、必ずFキー押下フラグが立ってしまうため！
;=================================================
PSEUDO_MON:
	LD	HL,(EXECLINENUM)	;=現在実行中の行番号
	INC	HL			;停止中は0FFFFHなので、１加えてZフラグが立つかで判別している
	LD	A,H			;
	OR	L			;
	RET	NZ			;プログラムから呼ばれた場合は処理しないで戻る

.L1:	CALL	KEYWAIT			;A<-キー入力された文字
	CALL	CAPITAL			;大文字化
	CP	CR			;
	JR	Z,.EXIT			;
	CP	"G"			;
	JR	NZ,.L1			;
	CALL	.SUB			;16進コード DE→16進 A
	LD	H,A
	CALL	.SUB
	LD	L,A			;HL<-ジャンプアドレス
	CALL	KEYWAIT			;改行を読み捨てる

	POP	BC			;->READ_CMT	戻りアドレスを捨てる
	POP	BC			;->PUSH BC	スタックを捨てる
	POP	BC			;->LOAD		戻りアドレスを捨てる
	JP	(HL)			;Gコマンド実行

.EXIT:	RET

.SUB:	CALL	KEYWAIT			;
	LD	D,A			;
	CALL	KEYWAIT			;
	LD	E,A			;
	CALL	CNVHEXBYTE		;16進コード DE→16進 A
	RET

;=================================================
;[CMT]CMTファイルの書き込み
;IN  (TGT_CLSTR),(ARG0),(ARG1),(ARG2)
;OUT 
;=================================================
WRITE_CMT:
	CALL	PREP_WRITE

.MERGE:					;MERGEのエントリポイント
	LD	HL,.RET			;！重要！戻りアドレスをスタックにセットする
	PUSH	HL			;

	LD	A,(ARGNUM)		;A<-入力パラメータ数
	AND	A			;入力パラメータ数が0ならBASICセーブへ
	JR	Z,WRITE_CMT_BASIC	;

	DEC	A			;入力パラメータ数が1ならエラーへ
	JR	Z,.ERR			;

;	LD	DE,(ARG1)		;=開始アドレス
;	LD	HL,(ARG2)		;=終了アドレス
;	CALL	CPHLDE			;終了アドレス-開始アドレス
;	JR	Z,.ERR			;終了アドレス=開始アドレス？
;	JR	NC,WRITE_CMT_BINARY	;終了アドレス>開始アドレス？

	LD	DE,(ARG1)		;=開始アドレス
	LD	HL,(ARG2)		;=終了アドレス
	CALL	CPHLDE			;終了アドレス-開始アドレス
	JR	NC,WRITE_CMT_BINARY	;終了アドレスが、開始アドレスより小さければエラー

.ERR:	LD	E,ILLEGAL_FUNCTION_CALL	;引数が不正
	JP	ERROR

.RET:	JP	FIN_WRITE

;=================================================
;[CMT]メモリにBASICプログラムが存在するか
;IN  -
;OUT Z=1:プログラムなし
;=================================================
IS_BASIC:
	PUSH	HL			;
	LD	HL,(BASBEGIN)		;開始２バイトが00Hなら空とみなす
	LD	A,(HL)			;
	INC	HL			;
	OR	(HL)			;
	POP	HL			;
	RET

;=================================================
;[CMT]BASICファイルの書き込み
;=================================================
WRITE_CMT_BASIC:
	CALL	IS_BASIC		;
	JP	Z,ERR_EMPTY_FILE	;

	CALL	RAD2RNUM		;BASICの行アドレスを行番号に変換する！重要！
	CALL	IPRINT			;
	DB	"[BAS]",CR,LF,EOL	;

	LD	B,BAS_MARK_LEN		;ヘッダ
.HEADR:	LD	A,BAS_MARK		;
	CALL	POST_1BYTE		;
	DJNZ	.HEADR			;

	CALL	IPRINT			;ファイル名
	DB	"NAME:",EOL		;

	LD	HL,DIR_ENTRY		;
	LD	B,BFNAME_SIZE		;
.FNAME:	LD	A,(HL)			;
	RST	18H			;
	CP	SPC			;ファイル名の20Hを00Hに変換する
	JR	NZ,.L1			;
	XOR	A			;
.L1:	CALL	POST_1BYTE		;
	INC	HL			;
	DJNZ	.FNAME			;
	CALL	PUT_CR			;

	LD	DE,(BASBEGIN)		;=先頭アドレス
	LD	HL,(VARBEGIN)		;=終了アドレス
	PUSH	HL			;
	OR	A			;CY<-0
	SBC	HL,DE			;HL<-終了アドレス-先頭アドレス
	LD	B,H			;
	LD	C,L			;BC<-プログラムのサイズ
	POP	HL			;
	EX	DE,HL			;HL=先頭アドレス,DE=終了アドレス

.DATA:	LD	A,(HL)			;プログラムデータ部
	CALL	POST_1BYTE		;
	INC	HL			;
	DEC	BC			;
	LD	A,B			;
	OR	C			;
	JR	NZ,.DATA		;

	LD	B,9			;フッタ部
.FOOTR:	XOR	A			;
	CALL	POST_1BYTE		;
	DJNZ	.FOOTR			;

	RET

;=================================================
;[CMT]マシン語ファイルの書き込み
;IN  DE=先頭アドレス,HL=終了アドレス
;OUT 
;=================================================
WRITE_CMT_BINARY:
	CALL	PRT_WRITE_BIN_INFO	;

	INC	HL			;！重要！データ長計算の便宜上、終了アドレスに１加えておく
	LD	A,BIN_MARK		;先頭マーカー部
	CALL	POST_1BYTE		;

	LD	A,D			;先頭アドレス部
	CALL	POST_1BYTE		;
	LD	A,E			;
	CALL	POST_1BYTE		;

	LD	A,D			;チェックサム計算
	ADD	A,E			;
	CPL				;
	INC	A			;
	CALL	POST_1BYTE		;チェックサム部

.L2:	LD	A,BIN_MARK		;マーカー部
	CALL	POST_1BYTE		;

	CALL	CPHLDE			;
	JR	Z,.EXIT			;先頭アドレス=(終了アドレス+1)なら終了

	PUSH	HL			;終了アドレス退避
	LD	B,0FFH			;ブロック内データの最大値 255
	OR	A			;CY<-0
	SBC	HL,DE			;HL<-終了アドレス-先頭アドレス
	LD	A,H			;H>0ならB<-0FFH
	OR	A			;H=0ならB<-L
	JR	NZ,.L3			;
	LD	B,L			;
.L3:	LD	A,B			;
	CALL	POST_1BYTE		;ブロックサイズ部
	POP	HL			;終了アドレス復帰

	EX	DE,HL			;HL=先頭アドレス,DE=終了アドレス
	LD	C,B			;C<-サイズ チェックサム用

.L1:	LD	A,(HL)			;A<-(先頭アドレス)
	PUSH	AF			;
	CALL	POST_1BYTE		;データ部
	POP	AF			;

	ADD	A,C			;データブロックのチェックサムを計算
	LD	C,A			;C<-C+A

	INC	HL			;先頭アドレス++
	DJNZ	.L1			;

	EX	DE,HL			;DE=先頭アドレス,HL=終了アドレス
	LD	A,C			;A<-チェックサム
	NEG				;符号を反転
	CALL	POST_1BYTE		;チェックサム部
	JR	.L2			;

.EXIT:	XOR	A			;
	CALL	POST_1BYTE		;終了マーカ 00H,00H
	XOR	A			;
	CALL	POST_1BYTE		;

	RET

;=================================================
;読み込みの前処理
;=================================================
PREP_READ:
	XOR	A			;コールバックフラグを降ろす
	LD	(IS_CALLBACK),A		;
	LD	HL,(TGT_CLSTR)		;HL<-ファイルの開始クラスタ＃
	CALL	INIT_FP			;ファイルポインタ初期化
	LD	IX,FILE_BFFR_STRCT	;IX<-ファイルバッファ構造体のポインタ
	CALL	READ_FP_SCTR		;FPが示すセクタをIXバッファ構造体に読み込む
	RET

;=================================================
;BASIC読み込みの後処理
;=================================================
FIN_READ_BASIC:
	LD	(VARBEGIN),HL		;BASIC終了アドレスをセット
	LD	(ARRBEGIN),HL		;
	LD	(FREBEGIN),HL		;
	CALL	PRGFIT			;
	RET

;=================================================
;書き込みの前処理
;=================================================
PREP_WRITE:
	LD	HL,(TGT_CLSTR)		;
	CALL	INIT_FP			;
	CALL	ERASE_FAT_LINK		;
	LD	IX,FILE_BFFR_STRCT	;
	CALL	CLR_BFFR		;

	CALL	FP2SCTR			;(DW0)<-FPのセクタ＃
	LD	HL,DW0			;バッファのセクタ情報<-(DW0)
	PUSH	IX			;
	POP	DE			;
	CALL	DW_COPY			;

	RET

;=================================================
;書き込みの後処理
;=================================================
FIN_WRITE:
	LD	HL,FP			;ファイルサイズをディレクトリエントリにセットする
	LD	DE,DIR_ENTRY+IDX_SIZE	;
	CALL	DW_COPY			;
	LD	HL,(FP_CLSTR)		;HL<-最終クラスタ＃
	LD	DE,0FFFFH		;最終クラスタのFATエントリにFFFFHを書き込む
	CALL	WRITE_FAT_DATA		;
	CALL	FLUSH_BFFR		;ファイルバッファとFAT1,2バッファをメディアに書き込む
	RET

;=================================================
;機械語書き込み情報表示
;IN  DE=開始アドレス,HL=終了アドレス
;=================================================
PRT_WRITE_BIN_INFO:
	CALL	IPRINT			;
	DB	"[BIN]",CR,LF		;
	DB	"ADDRESS:",EOL		;
	PUSH	DE			;
	PUSH	HL			;
	EX	DE,HL			;
	CALL	PRTHLHEX		;
	LD	A,"-"			;
	RST	18H			;

	EX	DE,HL			;
	CALL	PRTHLHEX		;
	CALL	PUT_CR			;
	POP	HL			;
	POP	DE			;
	RET





