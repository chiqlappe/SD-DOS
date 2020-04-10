# PC-8001 SD-DOS

## 目的
* PC-8001の拡張ポートに接続されたSDメモリカードドライブと拡張RAMを使って、SDメモリカードの読み書きを行う

## 特徴
 * FAT16とCMTファイルに対応

## アセンブルについて
 * PC-8001エミュレータj80付属のtools80でアセンブル可能です

`java -jar tools80.jar -tgt:z80 main.asm`

## リンク
* [PC-8001用 8KB拡張RAMボード](https://github.com/chiqlappe/ram8k)
* [PC-8001用 micorSDドライブ](https://github.com/chiqlappe/sdd)
