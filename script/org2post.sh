#!/usr/bin/env bash
# org2post.sh <org文件> <post名> [--no-deploy]
#
# org 笔记 -> hexo 文章，三件事各由各的工具做：
#   ① kw-imgpush  只推这篇笔记目录下的图（含 rclone check 闸门，失败即停）
#   ② pandoc -t markdown-simple_tables  转成真正的 Markdown（不加 -t 出来是 HTML）
#   ③ sed         把本地相对引用换成图床直链
#
# 契约：图放在 org 同目录的子目录里，引用写 ./images/x.png 或 images/x.png；
#       ../ 或带空格的图名不会被改写（当前库里没有）。
set -euo pipefail

KW=${KW_ROOT:-$HOME/workspace/knowledge-workspace}
BASE=${IMG_BASE:-https://img.19921514.xyz}
HEXO=${HEXO_ROOT:-$HOME/workspace/hexo}
NODE_VER=${NODE_VER:-}

die() { echo "[org2post] 错误: $*" >&2; exit 1; }
[ $# -ge 2 ] || die "用法: $(basename "$0") <org文件> <post名> [--no-deploy]"
org=$1
slug=${2%.md}
deploy=1
[ "${3:-}" = "--no-deploy" ] && deploy=0

[ -f "$org" ] || die "找不到 org 文件: $org"
orgdir=$(dirname "$(realpath "$org")")
case "$orgdir/" in
  "$(realpath "$KW")"/*) ;;
  *) die "org 不在知识库 $KW 内，图床 key 无法推导" ;;
esac
rel=${orgdir#"$(realpath "$KW")"/}
out="$HEXO/source/_posts/$slug.md"

# ① 只推这篇笔记目录下的图；上传/校验失败直接退出，不改写任何东西
kw-imgpush --only "$rel"

# ②③ 转 md + 拼直链（中文/空格目录必须百分号编码，safe='/' 保住分隔符）
#    -simple_tables: 默认的 markdown writer 会把表格退化成“只有横线”的 simple table,
#    关掉它才输出 pipe 表格; writer 仍用 markdown —— 图片依旧是 ![alt](path), 不会出 <img src>。
#    --wrap=none 防止图片语法被折行，sed 是按行改的
enc=$(python3 -c 'import sys,urllib.parse;print(urllib.parse.quote(sys.argv[1],safe="/"))' "$rel")
mkdir -p "$(dirname "$out")"
pandoc "$org" -t markdown-simple_tables --wrap=none \
  -L "$HEXO/script/org-metadata.lua" \
  --template "$HEXO/script/hexo-template.md" \
  | sed -E "s#\]\(\.?/?([^)]*\.(png|jpe?g|gif|webp|svg))\)#]($BASE/$enc/\1)#g" \
  | BASE="$BASE" python3 -c '
import os, re, sys, urllib.parse
base = os.environ["BASE"]
pat = re.compile(re.escape(base) + r"/[^\s)\]]+")
def enc(m):
    # 段落里的中文/空格图像路径统一百分号编码（与 kw-imgpush --rewrite 输出一致）
    return urllib.parse.quote(urllib.parse.unquote(m.group(0)),
                              safe="/:%@!$&()*+,;=~_-.")
sys.stdout.write(pat.sub(enc, sys.stdin.read()))
' \
  > "$out"

# 自检：还没改成外链的本地图引用，通常是 ../ 或文件名带空格
left=$(grep -cE '\]\(\.{0,2}/?[^):]*\.(png|jpe?g|gif|webp|svg)\)' "$out" || true)
left=${left:-0}
if [ "$left" -gt 0 ]; then
  echo "[org2post] → $out （警告: 仍有 $left 处本地图片引用未改写）" >&2
else
  echo "[org2post] → $out"
fi

[ "$deploy" = 1 ] || exit 0
export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
cd "$HEXO"
# hexo 8 要求 node >= 20.19；未显式给 NODE_VER 时按 .nvmrc 切
if [ -n "$NODE_VER" ]; then nvm use "$NODE_VER" >/dev/null; else nvm use >/dev/null; fi
hexo g && hexo d
