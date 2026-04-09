#!/usr/bin/env bash
# 同时启动百炼 HTTP 同步 TTS 代理（8788）与 Qwen-TTS-Realtime WebSocket 代理（8789）。
# 与官方文档一致：在终端配置 API Key 到环境变量后再运行本脚本。
#
#   export DASHSCOPE_API_KEY="sk-你的百炼Key"
#   # 若 Key 在新加坡等国际站创建（与北京不互通）：
#   # export DASHSCOPE_REGION=intl
#   ./scripts/start-bailian-tts-proxies.sh
#
set -euo pipefail
cd "$(dirname "$0")"
if [[ -z "${DASHSCOPE_API_KEY:-}" ]]; then
  echo "请先执行: export DASHSCOPE_API_KEY=你的百炼APIKey（控制台「获取 API Key」）" >&2
  exit 1
fi
if [[ ! -d node_modules/ws ]]; then
  npm install
fi
node dashscope-tts-proxy.mjs &
pid_http=$!
node dashscope-tts-realtime-proxy.mjs &
pid_ws=$!
cleanup() {
  kill "$pid_http" "$pid_ws" 2>/dev/null || true
}
trap cleanup INT TERM EXIT
echo "HTTP TTS:  http://127.0.0.1:8788/tts"
echo "Realtime:  ws://127.0.0.1:8789/realtime"
echo "按 Ctrl+C 停止两个代理。"
wait
