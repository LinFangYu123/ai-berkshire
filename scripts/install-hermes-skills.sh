#!/usr/bin/env bash
# install-hermes-skills.sh — 将本仓库的 Hermes skills 安装到 ~/.hermes/skills/
#
# 用途：ai-berkshire 的 skills/*.md 是 Claude Code 的命令源，codex-skills/ 由
# scripts/sync-codex-skills.py 生成；hermes-skills/ 是同一套工作流的 Hermes 适配版
# （手写维护：工具名改为 Hermes 原生工具，路径改为绝对路径，frontmatter 按 Hermes
# 规范补 version / metadata.hermes）。本脚本负责把它安装到 Hermes 的 skills 目录。
#
# 用法：
#   ./install-hermes-skills.sh              # 符号链接安装（默认，随仓库更新自动生效）
#   ./install-hermes-skills.sh --copy       # 复制安装（每次执行都覆盖目标目录）
#   ./install-hermes-skills.sh --dry-run    # 只展示将要做什么
#   ./install-hermes-skills.sh --check      # 校验安装状态 + 与 skills/ 源的同步缺口
#   ./install-hermes-skills.sh --uninstall  # 移除本脚本创建的符号链接
#
# 环境变量：
#   HERMES_HOME   覆盖 Hermes 主目录（默认 $HOME/.hermes），测试时可用临时目录

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/hermes-skills"
SOURCE_SKILLS="$ROOT/skills"
DEST="${HERMES_HOME:-$HOME/.hermes}/skills"
MODE="symlink"
DRY_RUN=false
UNINSTALL=false
CHECK=false

for arg in "$@"; do
  case "$arg" in
    --copy) MODE="copy" ;;
    --dry-run) DRY_RUN=true ;;
    --uninstall) UNINSTALL=true ;;
    --check) CHECK=true ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "Unknown option: $arg"; exit 1 ;;
  esac
done

if [ ! -d "$SRC" ]; then
  echo "ERROR: $SRC not found. Run this script from ai-berkshire/scripts/ or ai-berkshire/ root."
  exit 1
fi

# 收集所有 Hermes skill 目录（必须含 SKILL.md）
SKILLS=()
for d in "$SRC"/*/; do
  [ -d "$d" ] || continue
  [ -f "$d/SKILL.md" ] && SKILLS+=("$(basename "$d")")
done
NUM=${#SKILLS[@]}

if [ "$NUM" -eq 0 ]; then
  echo "No Hermes skills found in $SRC (no */SKILL.md files)."
  exit 1
fi

# 与 skills/*.md 比对：源已新增/删除而 hermes-skills 未跟上的缺口
report_sync_gaps() {
  local missing=() orphan=()
  if [ -d "$SOURCE_SKILLS" ]; then
    for f in "$SOURCE_SKILLS"/*.md; do
      [ -e "$f" ] || continue
      local n; n="$(basename "$f" .md)"
      [ -f "$SRC/$n/SKILL.md" ] || missing+=("$n")
    done
    for s in "${SKILLS[@]}"; do
      [ -f "$SOURCE_SKILLS/$s.md" ] || orphan+=("$s")
    done
  fi
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "⚠️  skills/ 有源但 hermes-skills/ 缺适配版（需手工补齐 Hermes 版）："
    printf '    %s\n' "${missing[@]}"
  fi
  if [ "${#orphan[@]}" -gt 0 ]; then
    echo "ℹ️  hermes-skills/ 有版本但 skills/ 无同名源（Hermes/Codex 专属，属正常）："
    printf '    %s\n' "${orphan[@]}"
  fi
  if [ "${#missing[@]}" -eq 0 ] && [ "${#orphan[@]}" -eq 0 ]; then
    echo "✅ hermes-skills/ 与 skills/ 源一一对应，无缺口"
  fi
}

do_install() {
  local skill="$1"
  local src="$SRC/$skill"
  local dst="$DEST/$skill"

  if [ "$MODE" = "symlink" ]; then
    if [ -L "$dst" ]; then
      local link_target
      link_target="$(readlink "$dst")"
      if [ "$link_target" = "$src" ]; then
        echo "  OK       $skill (已链接到仓库)"
        return 0
      fi
      echo "  UPDATE   symlink: $skill ($link_target → $src)"
      rm "$dst"
    elif [ -e "$dst" ]; then
      echo "  SKIP     $skill: $dst 已存在且不是符号链接（检测到手工安装，请先手动处理）"
      return 0
    fi
    ln -s "$src" "$dst"
    echo "  INSTALL  symlink: $skill"
  else
    # 复制模式：先清空目标，避免上一版残留的文件（如已删除的 references/）
    if [ -L "$dst" ]; then
      rm "$dst"
      echo "  REPLACE  symlink → copy: $skill"
    elif [ -e "$dst" ]; then
      echo "  UPDATE   copy: $skill"
    else
      echo "  INSTALL  copy: $skill"
    fi
    rm -rf "$dst"
    mkdir -p "$dst"
    cp -R "$src"/. "$dst"/
  fi
}

do_uninstall() {
  local skill="$1"
  local dst="$DEST/$skill"

  if [ -L "$dst" ]; then
    rm "$dst"
    echo "  REMOVE   symlink: $skill"
  elif [ -e "$dst" ]; then
    echo "  SKIP     $skill: $dst 是真实目录（非本脚本创建的链接，需手工删除）"
  else
    echo "  SKIP     $skill: 未安装"
  fi
}

do_check() {
  local skill="$1"
  local src="$SRC/$skill"
  local dst="$DEST/$skill"

  if [ -L "$dst" ]; then
    local link_target
    link_target="$(readlink "$dst")"
    if [ "$link_target" = "$src" ]; then
      echo "  ✅ $skill → $dst (linked to repo)"
    else
      echo "  ⚠️  $skill → $dst (linked to $link_target, not $src)"
    fi
  elif [ -e "$dst" ]; then
    if diff -rq "$src" "$dst" >/dev/null 2>&1; then
      echo "  📁 $skill → $dst (real directory, 内容与仓库一致)"
    else
      echo "  ⚠️  $skill → $dst (real directory, 但内容与仓库不同步)"
    fi
  else
    echo "  ❌ $skill → not installed"
  fi
}

echo "AI Berkshire Hermes Skills — $NUM skills found in $SRC"
echo "Target:   $DEST"
echo "Mode:     $MODE"
echo ""

if $UNINSTALL; then
  for s in "${SKILLS[@]}"; do do_uninstall "$s"; done
  exit 0
fi

if $CHECK; then
  for s in "${SKILLS[@]}"; do do_check "$s"; done
  echo ""
  report_sync_gaps
  exit 0
fi

if $DRY_RUN; then
  report_sync_gaps
  echo ""
  echo "[DRY RUN] Would install to $DEST:"
  for s in "${SKILLS[@]}"; do echo "  $s"; done
  exit 0
fi

mkdir -p "$DEST"
report_sync_gaps
echo ""

for s in "${SKILLS[@]}"; do do_install "$s"; done

# 注：这里不像 install-codex-skills.sh 那样对 tools/*.py 做 chmod +x——
# 仓库里这些文件是 644，chmod 只会在 git status 里留下无意义的模式改动。

echo ""
echo "Installed Hermes skills to $DEST"
echo "重启 Hermes（或重新加载 skills）后生效；用 --check 校验状态，用 --uninstall 移除符号链接。"
