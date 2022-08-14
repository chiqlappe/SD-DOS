# PC-8001 SD-DOS

## 64KB RAM環境での使用方法
* SD-DOSを64KB RAM環境で使用する場合は、64KRAM.hexをEPROMに書き込む(開始アドレスは6000Hなので、お使いのEPROMにあわせてオフセットして下さい）

## 目的
* PC-8001の拡張ポートに接続されたmicroSDドライブと拡張RAM(8KBバッテリバックアップRAMまたは64KB RAM)を使って、SDメモリカードの読み書きを行う

## 特徴
 * FAT16とCMTファイルに対応

## アセンブルについて
 * PC-8001エミュレータj80付属のtools80でアセンブル可能です

`java -jar tools80.jar -tgt:z80 main.asm`

## リンク
* [PC-8001用 8KB拡張RAMボード](https://github.com/chiqlappe/ram8k)
* [PC-8001用 micorSDドライブ](https://github.com/chiqlappe/sdd)
