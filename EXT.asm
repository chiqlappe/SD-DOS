
;=================================================
;拡張コマンド
;=================================================


	ORG	0C000H

INIT_EXT_CMD:
	LD	HL,CMD_D
	LD	(JT_D),HL
	LD	HL,CMD_S
	LD	(JT_S),HL
	LD	HL,CMD_CP
	LD	(JT_CP),HL
	LD	HL,CMD_MD
	LD	(JT_MD),HL
	LD	HL,CMD_EX
	LD	(JT_EX),HL

	CALL	IPRINT
	DB	"READY !",CR,LF,EOL

	JP	BASIC


;=================================================
;[CMD]CMD D命令 "DUMP"
;・セクタ＃は８桁の16進文字列で指定する
; CMD D			直前のセクタ＃をダンプ
; CMD D "00000008"	指定されたセクタ＃をダンプ
; CMD D SC$
;=================================================
CMD_D:
	DEC	HL				;テキストポインタを１つ戻す
	RST	10H				;
	OR	A				;
	JR	Z,.L2				;
	CALL	STR2BUFF			;
	PUSH	HL				;TP退避
	LD	HL,STR_BUFF			;
	LD	DE,DW0+03H			;DE<-ダブルワードのMSB
	LD	B,04H				;B<-8桁 / 2
.L1:	PUSH	DE				;
	LD	A,(HL)				;
	CALL	IS_HEX				;
	LD	D,A				;
	INC	HL				;
	LD	A,(HL)				;
	CALL	IS_HEX				;
	LD	E,A				;
	INC	HL				;
	CALL	CNVHEXBYTE			;A<-文字コードD,Eをバイナリ変換した値
	POP	DE				;
	LD	(DE),A				;ダブルワード(DW0)のMSB側から値をセットしていく
	DEC	DE				;
	DJNZ	.L1				;
	JR	.L3

.L2:	PUSH	HL				;
.L3:	CALL	IS_FAT16			;
	CALL	DUMP_SCTR			;メインルーチン
	JP	CLOSE_CMD			;

;=================================================
;[DUMP]セクタをダンプ出力する
;IN  (DW0)=セクタ＃
;=================================================
DUMP_SCTR:
	CALL	IS_FAT16			;
	LD	A,80				;WIDTH 80,??
	CALL	WIDTH_X				;
	LD	IX,FILE_BFFR_STRCT		;=ファイルバッファ構造体
.L4:	CALL	LOAD_BFFR			;(DW0)セクタをファイルバッファに読み込む
	LD	HL,(FILE_BFFR_STRCT.BP)		;HL<-ファイルバッファの先頭アドレス
	LD	C,02H				;１セクタは２ページ構成
	LD	D,00H				;オフセット値表示用カウンタ
.L3:	CALL	.HEADER				;画面消去とセクタ＃表示
	LD	B,10H				;=行数
.L2:	PUSH	BC				;行数を退避
	LD	A,D				;オフセット値を表示
	CALL	PRTAHEX				;
	CALL	IPRINT				;
	DB	"0 :",EOL			;
	INC	D				;カウンタ++
	LD	B,10H				;=列数
	PUSH	HL				;バッファのアドレスを退避
.L1:	PUSH	BC				;列数を退避
	LD	A,(HL)				;A<-(バッファ)
	CALL	PRTAHEX				;16進数で表示
	CALL	PUT_SPC				;空白
	INC	HL				;アドレス++
	POP	BC				;列数を復帰
	DJNZ	.L1				;B--
	CALL	PUT_SPC				;空白
	LD	B,10H				;=列数
	POP	HL				;バッファのアドレスを復帰
.L6:	PUSH	BC				;列数を退避
	LD	A,(HL)				;A<-(バッファ)
	CP	20H				;
	JR	NC,.L7				;
	LD	A,"."				;
.L7	RST	18H				;
	INC	HL				;
	POP	BC				;
	DJNZ	.L6				;B--
	CALL	PUT_CR				;改行
	POP	BC				;行数を復帰
	DJNZ	.L2				;B--
	CALL	KEYWAIT				;１文字入力待ち
	CP	03H				;STOP
	RET	Z				;終了
	CP	BS				;BACKSPACE
	JR	NZ,.L5				;
	DEC	C				;２ページ目なら１ページ目に戻す
	JR	Z,.L4				;
	CALL	DW0_DEC				;セクタ＃--
	JR	NC,.L4				;キャリーフラグが立てば00000000Hに戻す
	CALL	DW0_INC				;
	JR	.L4				;

.L5:	DEC	C				;ページ数--
	JR	NZ,.L3				;
	CALL	DW0_INC				;セクタ＃++
	JR	.L4				;

.HEADER:
	PUSH	BC				;
	PUSH	HL				;
	LD	A,0CH				;画面消去
	RST	18H				;
	CALL	IPRINT				;
	DB	"    :",EOL			;
	LD	BC,1000H			;B<-10H,C<-00H
.L10:	LD	A,"+"				;"+0 +1 ... +F "
	RST	18H				;
	LD	A,C				;
	CP	10				;
	JR	C,.L11				;
	ADD	A,07H				;
.L11:	ADD	A,"0"				;
	RST	18H				;
	CALL	PUT_SPC				;
	INC	C				;
	DJNZ	.L10				;
	CALL	IPRINT				;
	DB	" SECTOR=",EOL			;
	LD	HL,DW0				;セクタ＃を表示
	CALL	PRT_DW_HEX			;
	CALL	PUT_CR				;
	POP	HL				;
	POP	BC				;
	RET					;


;=================================================
;[CMD]CMD S 命令 "SOURCE"
; CMD S "FILE.EXT"	ファイルの開始セクタをダンプ
; CMD S "/"		ルートディレクトリの開始セクタをダンプ
; CMD S FN$
;=================================================
CMD_S:
	CALL	STR2ARG0			;
	PUSH	HL				;
	CALL	IS_FAT16			;
	CALL	CHANGE_WDIR			;
	LD	(ARG0),HL			;
	LD	A,(HL)				;
	CALL	IS_EOT				;エントリ名が空か？
	JR	NZ,.L1				;
	LD	HL,(WDIR_CLSTR)			;エントリ名が空ならワーキングディレクトリのクラスタ＃を使う
	CALL	GET_FIRST_SCTR			;
	JR	.L2				;

.L1:	LD	C,00H				;
	CALL	GET_DENT			;
	JP	Z,ERR_NOT_FOUND			;存在しなければエラー
	LD	HL,(DIR_ENTRY+IDX_FAT)		;=一致したファイルのFATエントリ
	LD	A,H				;FATエントリが0000Hなら空ファイルなのでエラーへ
	OR	L				;
	JP	Z,ERR_EMPTY_FILE		;
	CALL	GET_FIRST_SCTR			;
.L2:	CALL	DUMP_SCTR			;メインルーチン
	CALL	RESTORE_WDIR			;
	JP	CLOSE_CMD


;=================================================
;[CMD]CMD CP 命令 ファイルをコピーする
; CMD CP "/DIR/FROM.EXT","/DIR/TO.EXT"
;=================================================
CMD_CP:
	CALL	GET_2STR_ARGS			;(ARG0)=コピー元,(ARG1)=コピー先
	PUSH	HL				;
	CALL	IS_FAT16			;
	LD	HL,DWA				;(DWA)<-セクタサイズ
	LD	BC,0000H			;
	LD	DE,SCTR_SIZE			;
	CALL	DW_LD				;
	CALL	SWAP_ARGS			;(ARG0)<->(ARG1)
	LD	C,ATRB_FILE			;
	CALL	PREP_DENT			;
	CALL	IS_READ_ONLY			;
	LD	HL,DIR_ENTRY			;ディレクトリエントリバッファの内容をコピー用バッファに転送する
	LD	DE,CP_DENT			;
	LD	BC,DENT_SIZE+06H		;バッファポインタとセクタ＃も含める
	LDIR					;
	LD	HL,(TGT_CLSTR)			;HL<-コピー先ファイルの先頭クラスタ＃
	CALL	GET_FIRST_SCTR			;
	LD	HL,DW0				;
	LD	DE,CP_SCTR			;
	CALL	DW_COPY				;
	CALL	RESTORE_WDIR			;！重要！
	CALL	SWAP_ARGS			;(ARG0)<->(ARG1)
	CALL	CHANGE_WDIR			;
	LD	C,ATRB_FILE			;
	CALL	GET_DENT			;
	JP	Z,ERR_NOT_FOUND			;見つからなければエラー
	LD	HL,DIR_ENTRY+IDX_SIZE		;
	LD	DE,FP				;
	CALL	DW_COPY				;(FP)<-コピー元ファイルのファイルサイズ
	LD	HL,DIR_ENTRY+IDX_SIZE		;コピー元のファイルサイズをコピー先に転送する
	LD	DE,CP_DENT+IDX_SIZE		;
	CALL	DW_COPY				;
	LD	HL,(DIR_ENTRY+IDX_FAT)		;HL<-コピー元ファイルのクラスタ＃
	LD	IX,FILE_BFFR_STRCT		;

	;-----------------------------------------

.LOOP:	PUSH	HL				;クラスタ＃退避
	CALL	GET_FIRST_SCTR			;(DW0)<-クラスタHLのセクタ＃
	LD	A,(SCTRS_PER_CLSTR)		;
	LD	B,A				;１クラスタを構成するセクタ数だけループする
.L1:	PUSH	BC				;カウンタ退避
	CALL	COPY_SCTR			;セクタコピー処理
	CALL	DW0_INC				;コピー元のセクタ＃++
	LD	HL,CP_SCTR			;コピー先のセクタ＃++
	CALL	DW_INC				;
	LD	HL,FP				;(FP)<-(FP)-セクタサイズ
	LD	DE,DWA				;
	CALL	DW_SUB				;
	JR	C,.EXIT				;(FP) <  0 なら終了へ
	CALL	DW_DEC				;
	JR	C,.EXIT				;(FP) == 0 なら終了へ
	CALL	DW_INC				;
	POP	BC				;カウンタ復帰
	DJNZ	.L1				;

	;-----------------------------------------

	;コピー先 空きクラスタ検索処理
	LD	HL,(TGT_CLSTR)			;クラスタHL以外の空きクラスタを探す
	CALL	FIND_NULL_CLSTR			;HL<-空きクラスタ＃,CY=1:見つかった
	JR	C,.FOUND			;
	LD	HL,(TGT_CLSTR)			;空きが見つからなければエラー処理
	LD	DE,0FFFFH			;=FATの終了コード
	CALL	WRITE_FAT_DATA			;書き込み中のクラスタのFATエントリに終了コードをセットする
	LD	HL,MSG_MEDIA_FULL		;エラー終了
	JP	ERR				;

.FOUND:	LD	DE,(TGT_CLSTR)			;DE<-(TGT_CLSTR)=現在のクラスタ＃
	LD	(TGT_CLSTR),HL			;(TGT_CLSTR)<-HL=空きクラスタ＃
	EX	DE,HL				;HL=現在のクラスタ＃,DE=空きクラスタ＃
	CALL	WRITE_FAT_DATA			;クラスタHLのFATエントリに空きクラスタDEをセットしリンクさせる
	LD	HL,(TGT_CLSTR)			;HL<-空きクラスタ＃
	CALL	GET_FIRST_SCTR			;(DW0)<-空きクラスタの開始セクタ＃
	LD	HL,DW0				;(CP_SCTR)<-(DW0)
	LD	DE,CP_SCTR			;
	CALL	DW_COPY				;

	;-----------------------------------------

	;コピー元処理
	POP	HL				;クラスタ＃復帰
	CALL	READ_FAT_DATA			;DE<-クラスタHLの次のクラスタ＃
	PUSH	DE				;
	POP	HL				;HL<-次のクラスタ＃
	INC	HL				;判定のため、クラスタ＃に１を加える
	LD	A,H				;HLが0FFFFHの時、１加えると0000Hになることを利用している
	OR	L				;
	LD	E,BAD_FILE_DATA			;次のクラスタ＃が0FFFFHならエラー
	JP	Z,ERROR				;
	DEC	HL				;HLを元に戻す
	JR	.LOOP				;

	;-----------------------------------------

.EXIT:	POP	BC				;カウンタを捨てる
	POP	HL				;クラスタ＃を捨てる
	LD	HL,CP_DENT			;コピー用バッファの内容をディレクトリエントリバッファに転送する
	LD	DE,DIR_ENTRY			;
	LD	BC,DENT_SIZE+06H		;
	LDIR					;
	CALL	WRITE_DENT			;ディレクトリエントリバッファの内容をメディアに書き込む
	LD	HL,(TGT_CLSTR)			;HL<-最終クラスタ＃
	LD	DE,0FFFFH			;最終クラスタのFATエントリにFFFFHを書き込む
	CALL	WRITE_FAT_DATA			;
	CALL	FLUSH_BFFR			;
	CALL	RESTORE_WDIR			;
	JP	CLOSE_CMD			;

;=================================================
;[FS]セクタをコピーする
;IN  IX=バッファ構造体,(DW0)=セクタ＃,(CP_SCTR)=コピー先のセクタ＃
;OUT 
;=================================================
COPY_SCTR:
	CALL	LOAD_BFFR			;セクタ(DW0)をファイルバッファに読み込む
	PUSH	IX				;バッファのセクタ情報に、コピー先のセクタ＃をセットする
	POP	DE				;
	LD	HL,CP_SCTR			;
	CALL	DW_COPY				;
	LD	A,TRUE				;バッファの更新フラグを立てる
	LD	(IX+IDX_BUPD),A			;
	CALL	SAVE_BFFR			;バッファ書き込み
	RET					;



;=================================================
;[CMD]CMD MD命令 サブディレクトリ作成
; CMD MD "/DIR1/DIR2"
; CMD MD SD$
;=================================================
CMD_MD:
	CALL	STR2ARG0			;
	PUSH	HL				;
	CALL	IS_FAT16			;
	LD	IX,FILE_BFFR_STRCT		;
	CALL	CHANGE_WDIR			;
	LD	C,00H				;
	CALL	GET_DENT			;
	JP	NZ,ERR_EXISTS			;存在していればエラー
	LD	A,ATRB_DIR			;
	LD	(DIR_ENTRY+IDX_ATRB),A		;
	CALL 	TOUCH.NEW			;クラスタ＃と日時情報をセットする
	CALL	SET_DENT_FAT			;
	CALL	WRITE_DENT			;
	LD	HL,(TGT_CLSTR)			;HL<-新規作成されたサブディレクトリの開始クラスタ＃
	LD	DE,0FFFFH			;クラスタHLのFATエントリにFFFFHを書き込む
	CALL	WRITE_FAT_DATA			;
	CALL	FLUSH_BFFR			;全バッファをメディアに書き込む
	LD	HL,(TGT_CLSTR)			;
	CALL	GET_FIRST_SCTR			;
	CALL	CLR_CLSTR			;クラスタHLを初期化する
	LD	HL,DW0				;バッファ構造体のセクタ＃<-開始セクタ＃
	PUSH	IX				;
	POP	DE				;
	CALL	DW_COPY				;
	CALL	CLR_DENT_BFFR			;ディレクトリエントリバッファをクリアし、FATエントリ値とファイルサイズを0にする
	LD	A,ATRB_DIR			;
	LD	(DIR_ENTRY+IDX_ATRB),A		;
	LD	HL,DIR_ENTRY+IDX_CTIME		;「作成日時」をセットする
	CALL	SET_DATETIME			;
	LD	HL,DIR_ENTRY+IDX_TIME		;「更新日時」をセットする
	CALL	SET_DATETIME			;
	LD	HL,DNAME			;エントリ名を空白で埋める
	LD	C,SPC				;
	CALL	FILL_STR			;
	LD	A,"."				;エントリ名<-"."
	LD	(DIR_ENTRY+IDX_NAME),A		;
	LD	HL,(TGT_CLSTR)			;HL<-サブディレクトリ自身のクラスタ＃
	EX	DE,HL				;
	LD	HL,DIR_ENTRY+IDX_FAT		;ディレクトリエントリバッファのFATエントリ<-自身のクラスタ＃
	LD	(HL),E				;
	INC	HL				;
	LD	(HL),D				;
	PUSH	IX				;
	POP	HL				;
	LD	DE,IDX_BADR			;
	ADD	HL,DE				;
	LD	E,(HL)				;
	INC	HL				;
	LD	D,(HL)				;DE<-バッファ構造体のバッファポインタ
	PUSH	DE				;バッファ構造体のバッファポインタを退避
	LD	HL,DIR_ENTRY			;
	LD	BC,DENT_SIZE			;
	LDIR					;ディレクトリバッファの内容をファイルバッファにコピーする
	LD	A,"."				;エントリ名<-".."
	LD	(DIR_ENTRY+IDX_NAME+1),A	;
	LD	HL,(WDIR_CLSTR)			;HL<-ワーキングディレクトリのクラスタ＃
	EX	DE,HL				;
	LD	HL,DIR_ENTRY+IDX_FAT		;ディレクトリエントリバッファのFATエントリ<-親ディレクトリのクラスタ＃
	LD	(HL),E				;
	INC	HL				;
	LD	(HL),D				;
	POP	HL				;バッファ構造体のバッファポインタを復帰
	LD	DE,DENT_SIZE			;
	ADD	HL,DE				;
	EX	DE,HL				;DE<-次のエントリ位置
	LD	HL,DIR_ENTRY			;
	LD	BC,DENT_SIZE			;
	LDIR					;
	LD	(IX+IDX_BUPD),TRUE		;バッファの更新フラグを立てる
	CALL	FLUSH_BFFR			;FATとファイルバッファをメディアに書き込む
	CALL	RESTORE_WDIR			;
	JP	CLOSE_CMD			;


;=================================================
;[CMD]CMD EX命令 サブディレクトリ拡張
;・サブディレクトリに新しいクラスタを追加して、エントリ格納サイズを拡張する
; CMD EX "DIR"
; CMD EX SD$
;=================================================
CMD_EX:
	CALL	STR2ARG0			;
	PUSH	HL				;
	CALL	IS_FAT16			;
	CALL	CHANGE_WDIR			;
	LD	(ARG0),HL			;
	LD	C,ATRB_DIR			;
	CALL	GET_DENT			;
	JP	Z,ERR_NOT_FOUND			;
	LD	HL,MSG_EXPAND			;
	CALL	YES_NO				;
	JR	NZ,.EXIT			;
	LD	HL,(DIR_ENTRY+IDX_FAT)		;
	LD	A,H				;
	OR	L				;
	LD	E,ILLEGAL_FUNCTION_CALL		;
	JP	Z,ERROR				;FATエントリが未登録(0000H)ならエラー
.L2:	CALL	READ_FAT_DATA			;DE<-クラスタHLのリンク先クラスタ＃。HL保持
	INC	DE				;DE++
	LD	A,D				;
	OR	E				;
	JR	Z,.L1				;DE=0000H ?
	DEC	DE				;DE--
	EX	DE,HL				;HL<-リンク先クラスタ＃
	JR	.L2				;

.L1:	PUSH	HL				;最終クラスタ＃退避
	CALL	FIND_NULL_CLSTR			;HL<-空きクラスタ＃
	EX	DE,HL				;DE=空きクラスタ＃
	POP	HL				;HL<-最終クラスタ＃
	JR	C,.FOUND			;
	LD	HL,MSG_MEDIA_FULL		;空きクラスタが見つからなければエラー終了
	JP	ERR				;

.FOUND:	PUSH	DE				;空きクラスタ＃退避
	CALL	WRITE_FAT_DATA			;クラスタHLのFATデータとしてDEをセットする
	EX	DE,HL				;HL=最終クラスタ＃
	LD	DE,0FFFFH			;最終クラスタのFATエントリに終了コードをセットする
	CALL	WRITE_FAT_DATA			;
	CALL	FLUSH_BFFR			;FATをメディアに書き込む
	POP	HL				;空きクラスタ＃復帰
	LD	IX,FILE_BFFR_STRCT		;
	CALL	CLR_CLSTR			;クラスタ初期化
.EXIT:	CALL	RESTORE_WDIR			;
	JP	CLOSE_CMD			;


