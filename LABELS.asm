
;=============================
;共通ラベル
;=============================

FALSE			EQU	00H
TRUE			EQU	!FALSE
EOL			EQU	00H

;=============================
;専用ラベル
;=============================

USE_VIRTUAL_LED		EQU	TRUE		;MMCドライバ用
USE_VIRTUAL_SOUND	EQU	TRUE		;
SHOW_DATE		EQU	FALSE		;FILESで日時を表示する

CLSTR_STACK_SIZE	EQU	10H		;[CD.ASM]クラスタスタックサイズ

IDX_PP_SCTR		EQU	01C6H		;[FS.ASM]プライマリパーティション開始セクタ＃へのインデックス値
IDX_BPB			EQU	000BH		;[FS.ASM]BPB領域へのインデックス値

SCTR_SIZE		EQU	200H		;セクタサイズ
DENT_PER_SCTR		EQU	10H		;１セクタ当たりのディレクトリエントリ数
MIN_CLSTR		EQU	 0002H		;クラスタ＃の最小値
MAX_CLSTR		EQU	0FFF6H		;クラスタ＃の最大値（理論値）

DNAME_SIZE		EQU	0BH		;ディレクトリエントリ名のサイズ 8+3=11
DENT_SIZE		EQU	20H		;ディレクトリエントリ全体のサイズ

ROOT			EQU	0000H		;ルートディレクトリのクラスタ＃ 実際のクラスタ＃ではなく単なる識別用ID

IDX_NAME		EQU	00H		;ディレクトリ情報のオフセット値 名前 １１バイト（拡張子部を含む）
IDX_EXT			EQU	08H		;ディレクトリ情報のオフセット値 拡張子 ３バイト
IDX_ATRB		EQU	0BH		;ディレクトリ情報のオフセット値 属性値 １バイト
IDX_CTIME		EQU	0EH		;ディレクトリ情報のオフセット値 作成時刻 ２バイト
IDX_CDATE		EQU	10H		;ディレクトリ情報のオフセット値 作成日   ２バイト
IDX_ADATE		EQU	12H		;ディレクトリ情報のオフセット値 アクセス日 ２バイト
IDX_TIME		EQU	16H		;ディレクトリ情報のオフセット値 更新時刻 ２バイト
IDX_DATE		EQU	18H		;ディレクトリ情報のオフセット値 更新日   ２バイト
IDX_FAT			EQU	1AH		;ディレクトリ情報のオフセット値 FATエントリ番号 ２バイト
IDX_SIZE		EQU	1CH		;ディレクトリ情報のオフセット値 ファイルサイズ  ４バイト

IDX_BADR		EQU	04H		;バッファ情報のオフセット値 バッファの先頭アドレス ２バイト
IDX_BUPD		EQU	06H		;バッファ情報のオフセット値 更新フラグ １バイト

SEPARATOR		EQU	"/"
ATRB_DIR		EQU	10H		;ディレクトリエントリの属性値
ATRB_FILE		EQU	20H		;
ID_DISABLED		EQU	0E5H		;無効化されたディレクトリエントリの認識コード

ATRB_SIZE		EQU	06H		;ファイル属性文字列のサイズ

;WORK_AREA		EQU	07B00H		;ワークエリア
STR_BUFF		EQU	0FF3DH		;文字列バッファ ~0FF9CH
STR_BUFF_SIZE		EQU	50H		;文字列バッファのサイズ（終了コード１文字分含む）

;STACK_AREA		EQU	0FFFFH
CB_BYTES		EQU	0200H		;コールバック間隔のバイト数 512バイト=1セクタサイズ