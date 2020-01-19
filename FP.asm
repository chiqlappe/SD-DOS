
;-------------------------------------------------
;ファイルポインタFPの構造
;-------------------------------------------------
;MSB                             LSB
;00000000 00000000 00000000 00000000
;                         1 11111111: 0~ 8  9bit オフセット値        0~511
;                   111111          : 9~14  6bit セクタシリアル＃    0~63       FP_SCTR_SN
;-1111111 11111111 1                :15~30 16bit クラスタシリアル＃  0~65535	FP_CLSTR_SN
;
;・オフセット値　　　…バッファ内での相対位置                 0~511
;・セクタシリアル＃　…クラスタを構成するセクタのシリアル＃   0~(BPB+2)-1
;・クラスタシリアル＃…ファイルを構成するクラスタのシリアル＃ 0~65535
;
;　※FPの最大値はファイルサイズ
;-------------------------------------------------

;=================================================
;[FP]FP関連のワークを初期化する（読み込み＆書き込み）
;IN  HL=ファイルの開始クラスタ＃
;OUT (FP),(FP_CLSTR),(FP_SCTR_SN)
;=================================================
INIT_FP:
	PUSH	HL				;
	LD	(FP_CLSTR),HL			;(FP_CLSTR)<-ファイルの開始クラスタ＃
	LD	HL,FP				;(FP)<-00.00.00.00H
	CALL	DW_CLR				;
	XOR	A				;(FP_SCTR_SN)<-00H
	LD	(FP_SCTR_SN),A			;
	LD	HL,0000H			;(FP_CLSTR_SN)<-0000H
	LD	(FP_CLSTR_SN),HL		;
	POP	HL				;
	RET					;

;=================================================
;[FP]オフセット値のゼロ判定
;IN  HL=FPのポインタ
;OUT Z=1:FPのオフセット値はゼロ
;=================================================
IS_FP_OFST_ZERO:
	LD	A,(HL)				;FPの下位９ビットをチェック
	OR	A				;
	RET	NZ				;
	INC	HL				;
	LD	A,(HL)				;
	SRL	A				;
	RET					;

;=================================================
;[FP]FP関連ワークからセクタ＃を求める
;IN (FP_CLSTR),(FP_CLSTR_SN),(FP_SCTR_SN)
;OUT (DW0)
;=================================================
FP2SCTR:
	CALL	GET_FP_CLSTR			;DE<-FPが存在するクラスタ＃
	EX	DE,HL				;HL<-FPが存在するクラスタ＃
	CALL	GET_FIRST_SCTR			;(DW0)<-FPが存在するクラスタの開始セクタ＃
	LD	HL,DW1				;(DW1)<-00000000H
	CALL	DW_CLR				;
	LD	A,(FP_SCTR_SN)			;(DW1)<-セクタシリアル＃
	LD	(DW1),A				;
	CALL	DW0_ADD				;(DW0)<-開始セクタ＃+セクタシリアル＃=目的のセクタ＃
	RET					;

;=================================================
;[FP]ファイルの(FP_CLSTR_SN)番目のクラスタ＃と、そのFATエントリを求める
;IN  (FP_CLSTR)=ファイルの先頭クラスタ＃,(FP_CLSTR_SN)=FPが示すアドレスが、先頭から何番目のクラスタに含まれるか
;OUT DE=クラスタ＃,HL=FATエントリ
;=================================================
GET_FP_CLSTR:
	LD	DE,(FP_CLSTR)			;DE<-ファイルの先頭クラスタ＃。デフォルトの返り値
	LD	A,(FP_CLSTR_SN)			;
	LD	B,A				;
	INC	B				;！重要！
	EX	DE,HL				;HL=ファイルの先頭クラスタ＃
.L1:	PUSH	BC				;最終クラスタサーチ
	CALL	READ_FAT_DATA			;DE<-クラスタ＃HLのFATエントリ
	EX	DE,HL				;HL=FATエントリ,DE=クラスタ＃
	POP	BC				;
	DJNZ	.L1				;
	RET					;

;=================================================
;[FP]FPが示すセクタをバッファに読み込む（読み込み）
;IN  (FP_CLSTR),(FP_SCTR_SN),IX=バッファ構造体のポインタ
;OUT (DW0),(DW1)
;=================================================
READ_FP_SCTR:
	CALL	FP2SCTR				;FP関連ワークからセクタ＃を求める
	CALL	LOAD_BFFR			;セクタ(DW0)をバッファ構造体IXに読み込む IXのセクタ＃も更新される
	RET					;

;=================================================
;[FP]FPが示すメモリの値を取得しFP++する（読み込み）
;！セクタがバッファに取り込まれていること！
;IN  FP,IX=バッファ構造体のポインタ
;OUT A=(FP)の値,FP
;=================================================
FETCH_1BYTE:
	EXX					;
	CALL	FP2BP				;A<-FPが示すメモリの値
	LD	A,(HL)				;
	CALL	INC_FP				;FP++
	EXX					;
	RET					;

;=================================================
;[FP]FPとバッファ構造体IXから、FPが示すバッファポインタを求める
;IN  FP,IX=バッファ構造体のポインタ
;OUT HL=バッファポインタ
;=================================================
FP2BP:
	LD	HL,(FP)				;HL<-FPの下位２バイト
	LD	A,H				;H<-上位７ビットをオフ
	AND	00000001B			;
	LD	H,A				;HL=オフセット値
	LD	E,(IX+IDX_BADR)			;HL<-バッファアドレス+オフセット値=バッファポインタ
	LD	D,(IX+IDX_BADR+1)		;
	ADD	HL,DE				;
	RET					;

;=================================================
;[FP]ファイルポインタを１進める（読み込み）
;IN  FP
;OUT FP
;=================================================
INC_FP:
	PUSH	AF				;！重要 ！
	LD	HL,FP				;(FP)++
	CALL	DW_INC				;
	LD	A,(HL)				;バッファポインタが 0.00000000B であれば
	OR	A				;新たにセクタを読み込む
	JR	NZ,.EXIT			;
	INC	HL				;
	LD	A,(HL)				;
	SRL	A				;
	JR	C,.EXIT				;
	PUSH	AF				;B<-(SCTRS_PER_CLSTR)=(BPB+2)
	LD	A,(SCTRS_PER_CLSTR)		;
	LD	B,A				;
	DEC	B				;=FPからセクタシリアル＃を求めるためのビットマスク
	POP	AF				;
	AND	B				;
	LD	(FP_SCTR_SN),A			;
	JR	NZ,.L1				;セクタシリアル＃が０なら
	CALL	NEXT_CLSTR			;次のクラスタ＃をFATから求める
	JR	NZ,.L1				;次のクラスタ＃が0FFFFHの場合は
	LD	HL,MSG_SCTR_OVERFLOW		;ファイル上限を超過したことになるのでエラー終了
	JP	ERR				;

.L1:	CALL	READ_FP_SCTR			;FPが示すセクタをバッファに読み込む
.EXIT:	POP	AF				;
	RET					;

;=================================================
;[FP]クラスタを１すすめる（読み込み）
;IN  (FP_CLSTR),(FP_CLSTR_SN)
;OUT (FP_CLSTR),(FP_CLSTR_SN),Z=1:EOF
;=================================================
NEXT_CLSTR:
	PUSH	DE				;
	PUSH	HL				;
	LD	HL,(FP_CLSTR_SN)		;(FP_CLSTR_SN)++
	INC	HL				;
	LD	(FP_CLSTR_SN),HL		;
	LD	HL,(FP_CLSTR)			;現在のクラスタ＃のFATデータを読み取る
	CALL	READ_FAT_DATA			;
	LD	(FP_CLSTR),DE			;次のクラスタ＃に更新する
	INC	DE				;FATの値がFFFFH（ファイルエンド）ならZ=1になる
	LD	A,D				;！INC命令ではフラグ変化しないので注意！
	OR	E				;
	POP	HL				;
	POP	DE				;
	RET					;

;=================================================
;[FP]FPからクラスタシリアル＃、セクタシリアル＃、オフセット値を求める
;IN  FP
;OUT (FP_CLSTR_SN),(FP_SCTR_SN),HL=オフセット値 0000H~01FFH
;=================================================
PARSE_FP:
	LD	HL,FP				;HL<-FP
	LD	E,(HL)				;E<-(FP)=オフセット値の下位バイト
	INC	HL				;HL=FP+1
	LD	A,(HL)				;A<-(FP+1)
	AND	00000001B			;=オフセット値を求めるためのビットマスク
	LD	D,A				;D<-オフセット値の上位バイト
	PUSH	DE				;<-FPの0~8BIT
	LD	A,(SCTRS_PER_CLSTR)		;A=0100.0000B=40H
	DEC	A				;A=0011.1111B=3FH
	PUSH	AF				;
	LD	D,(HL)				;D=XXXX.XXXoB=(FP+1)
	SRL	D				;D=0XXX.XXXXB 右シフトして、オフセット部分の１ビットを落とす
	AND	D				;A=00XX.XXXXB
	LD	(FP_SCTR_SN),A			;<-FPの9~14BIT
	POP	AF				;A=0011.1111B=3FH
	SLA	A				;A=0111.1110B=7EH オフセット部分の１ビット分を空ける
	INC	A				;A=0111.1111B=7FH このビットパターンを使って必要なビット数を抽出する
	LD	E,(HL)				;E=csss.sssoB=(FP+1) c=cluster,s=SCTR,o=offset bit
	INC	HL				;
	LD	C,(HL)				;C=(FP+2)
	INC	HL				;
	LD	B,(HL)				;B=(FP+3)
.L1:	SLA	A				;A=1111.1110B CY=0
	JR	C,.L2				;CY=1なら抜ける
	RL	E				;B,C,Eをキャリー付き左ローテート
	RL	C				;
	RL	B				;
	JR	.L1				;

.L2:	LD	(FP_CLSTR_SN),BC		;<-FPの15~30BIT
	POP	HL				;HL=オフセット値
	RET					;

;=================================================
;[FP]FPが示すファイルバッファのメモリに値をセットしFP++する（書き込み）
;IN  FP,IX=ファイルバッファ構造体のポインタ,A=(FP)に書き込む値
;OUT FP
;=================================================
POST_1BYTE:
	EXX					;
	PUSH	AF				;
	CALL	FP2BP				;FPとバッファ構造体IXからバッファポインタHLを求める
	POP	AF				;
	LD	(HL),A				;(バッファポインタ)<-A
	LD	A,TRUE				;
	LD	(FILE_BFFR_STRCT.FLG),A		;バッファの更新フラグを立てる
	CALL	INC_FP_W			;FP++
	EXX					;
	RET					;

;=================================================
;[FP]ファイルポインタを１進める（書き込み）
;IN  FP,IX=ファイルバッファ構造体のポインタ
;OUT FP
;=================================================
INC_FP_W:
	LD	HL,FP				;ファイルポインタを１進める
	CALL	DW_INC				;
	LD	A,(HL)				;バッファポインタ(FPの下位９ビット)が0.00000000Bになったら、セクタを次に進める
	OR	A				;それ以外は終了へ
	JR	NZ,.EXIT			;
	INC	HL				;
	LD	A,(HL)				;
	SRL	A				;
	JR	C,.EXIT				;
	PUSH	AF				;ここではAの下位６ビットがセクタシリアル＃になっている
	LD	A,(SCTRS_PER_CLSTR)		;
	LD	B,A				;B<-(SCTRS_PER_CLSTR)
	DEC	B				;=FPからセクタシリアル＃を求めるためのビットマスク
	POP	AF				;
	AND	B				;
	LD	(FP_SCTR_SN),A			;(FP_SCTR_SN)<-セクタシリアル＃
	JR	NZ,.NEW				;セクタシリアル＃が０でなければ
	LD	HL,(FP_CLSTR)			;HL<-現在のクラスタ＃
	CALL	READ_FAT_DATA			;DE<-クラスタHLのFATエントリ
	LD	A,D				;FATエントリがセットされていれば、それをそのまま使う
	OR	E				;
	JR	Z,.NULL				;
	LD	(FP_CLSTR),DE			;現在のクラスタ＃<-クラスタHLのFATエントリ
	JR	.NEW				;

.NULL:	CALL	FIND_NULL_CLSTR			;空きクラスタ＃HLをFATから求める OUT HL,CY=1:見つかった
	JR	C,.FOUND			;
	LD	HL,(FP_CLSTR)			;HL<-現在のクラスタ＃
	LD	DE,0FFFFH			;DE<-FATの終了コード
	CALL	WRITE_FAT_DATA			;現在のクラスタ＃のFATエントリに終了コードをセットする
	LD	HL,MSG_MEDIA_FULL		;エラー終了
	JP	ERR				;

.FOUND:	EX	DE,HL				;DE=空きクラスタ＃
	LD	HL,(FP_CLSTR)			;HL<-現在のクラスタ＃
	LD	(FP_CLSTR),DE			;現在のクラスタ＃<-空きクラスタ＃
	CALL	WRITE_FAT_DATA			;クラスタ＃HLのFATエントリに空きクラスタ＃DEをセットしリンクさせる
.NEW:	CALL	SAVE_BFFR			;現在のファイルバッファが更新されていればメディアに書き込む
	CALL	CLR_BFFR			;次のセクタ用にファイルバッファをクリアする
	CALL	FP2SCTR				;(DW0)<-FPのセクタ＃
	LD	HL,DW0				;バッファ構造体のセクタ＃<-(DW0)
	PUSH	IX				;
	POP	DE				;
	CALL	DW_COPY				;
.EXIT:	RET					;

;=================================================
;[FP]FPをファイル終端にセットし、ファイルバッファに最終セクタを読み込む
;IN  (DIR_ENTRY)
;OUT (FP),(FP_CLSTR),(FP_CLSTR_SN),(FP_SCTR_SN)
;=================================================
SET_FP_END:
	LD	HL,(DIR_ENTRY+IDX_FAT)		;HL<-ファイルのクラスタ＃
	LD	A,H				;
	OR	L				;
	JP	Z,ERR_EMPTY_FILE		;クラスタ＃が0000Hならエラー
	LD	(FP_CLSTR),HL			;(FP_CLSTR)<-ファイルの開始クラスタ＃
	LD	HL,DIR_ENTRY+IDX_SIZE		;HL<-ファイルサイズのポインタ
	LD	DE,FP				;DE<-ファイルポインタ
	CALL	DW_COPY				;FP<-(ファイルサイズ)=ファイルの終端位置
	CALL	PARSE_FP			;FPから(FP_CLSTR_SN),(FP_SCTR_SN)を求める
	CALL	GET_FP_CLSTR			;DE<-FPが存在するクラスタ＃,HL<-そのFATエントリ
	INC	HL				;FATの値がFFFFH（ファイル終端）ならZ=1になる！INC命令はフラグ変化しない！
	LD	A,H				;
	OR	L				;
	JR	Z,.L1				;ファイル終端でなければエラー
	LD	HL,MSG_BAD_FORMAT		;選択されたクラスタのFATが0FFFFHでない
	JP	ERR				;

.L1:	CALL	READ_FP_SCTR			;FPが示すセクタをバッファに読み込む
	RET					;

