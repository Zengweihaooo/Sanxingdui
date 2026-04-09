#!/usr/bin/env node
/**
 * 百炼「实时语音合成 Qwen-TTS-Realtime」WebSocket 代理。
 * 浏览器 WebSocket 无法携带 Authorization，故由本进程连接 wss://dashscope… 并双向转发文本帧。
 *
 * 用法：
 *   export DASHSCOPE_API_KEY="sk-你的百炼Key"
 *   cd scripts && npm install && node dashscope-tts-realtime-proxy.mjs
 *
 * NPC.html 朗读选「千问 TTS 实时」时，「实时 WS 代理」填：ws://127.0.0.1:8789/realtime
 *
 * 国际站 Key（新加坡等）可任选其一：
 *   export DASHSCOPE_REGION=intl
 * 或完整上游（可带或不带 ?model=，不带则自动追加）：
 *   export DASHSCOPE_REALTIME_WS_URL="wss://dashscope-intl.aliyuncs.com/api-ws/v1/realtime"
 *
 * @see https://help.aliyun.com/zh/model-studio/qwen-tts-realtime
 */
import http from 'node:http';
import { WebSocketServer, WebSocket } from 'ws';

const PORT = Number(process.env.DASHSCOPE_REALTIME_PROXY_PORT || 8789);
const PATH = process.env.DASHSCOPE_REALTIME_PROXY_PATH || '/realtime';
const API_KEY = process.env.DASHSCOPE_API_KEY || '';
const MODEL = process.env.DASHSCOPE_REALTIME_MODEL || 'qwen3-tts-flash-realtime';

function upstreamWsUrl() {
  const raw = process.env.DASHSCOPE_REALTIME_WS_URL;
  if (raw && String(raw).trim()) {
    const u = String(raw).trim();
    if (/[?&]model=/.test(u)) return u;
    const join = u.includes('?') ? '&' : '?';
    return `${u}${join}model=${encodeURIComponent(MODEL)}`;
  }
  const intl = process.env.DASHSCOPE_REGION === 'intl';
  const base = intl
    ? 'wss://dashscope-intl.aliyuncs.com/api-ws/v1/realtime'
    : 'wss://dashscope.aliyuncs.com/api-ws/v1/realtime';
  return `${base}?model=${encodeURIComponent(MODEL)}`;
}

function forwardToUpstream(upstreamWs, data, isBinary) {
  if (upstreamWs.readyState !== WebSocket.OPEN) return;
  if (isBinary) upstreamWs.send(data, { binary: true });
  else upstreamWs.send(typeof data === 'string' ? data : data.toString('utf8'));
}

const server = http.createServer((_req, res) => {
  res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
  res.end('WebSocket proxy: connect with WS to ' + PATH);
});

const wss = new WebSocketServer({ noServer: true });

server.on('upgrade', (req, socket, head) => {
  try {
    const u = new URL(req.url || '', 'http://localhost');
    if (u.pathname !== PATH) {
      socket.destroy();
      return;
    }
  } catch {
    socket.destroy();
    return;
  }

  if (!API_KEY) {
    socket.write(
      'HTTP/1.1 503 Service Unavailable\r\nConnection: close\r\n\r\nSet DASHSCOPE_API_KEY'
    );
    socket.destroy();
    return;
  }

  wss.handleUpgrade(req, socket, head, (clientWs) => {
    const target = upstreamWsUrl();
    const upstream = new WebSocket(target, {
      headers: {
        Authorization: 'Bearer ' + API_KEY,
        'User-Agent': 'sanxingdui-dashscope-tts-realtime-proxy/1.0',
      },
    });

    /** @type {Array<{data: import('ws').RawData, isBinary: boolean}>} */
    const pendingFromClient = [];

    const cleanup = () => {
      try {
        clientWs.close();
      } catch {
        /* ignore */
      }
      try {
        upstream.close();
      } catch {
        /* ignore */
      }
    };

    clientWs.on('message', (data, isBinary) => {
      if (upstream.readyState === WebSocket.OPEN) {
        forwardToUpstream(upstream, data, isBinary);
      } else {
        pendingFromClient.push({ data, isBinary: !!isBinary });
      }
    });

    upstream.on('open', () => {
      for (const p of pendingFromClient) {
        forwardToUpstream(upstream, p.data, p.isBinary);
      }
      pendingFromClient.length = 0;
    });

    upstream.on('message', (data, isBinary) => {
      if (clientWs.readyState !== WebSocket.OPEN) return;
      if (isBinary) clientWs.send(data, { binary: true });
      else clientWs.send(typeof data === 'string' ? data : data.toString('utf8'));
    });

    upstream.on('error', (err) => {
      console.error('[realtime-proxy] upstream error:', err && err.message ? err.message : err);
      cleanup();
    });
    clientWs.on('error', () => cleanup());

    upstream.on('close', () => {
      try {
        clientWs.close();
      } catch {
        /* ignore */
      }
    });
    clientWs.on('close', () => {
      try {
        upstream.close();
      } catch {
        /* ignore */
      }
    });
  });
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(
    'DashScope Qwen-TTS-Realtime WS proxy listening ws://127.0.0.1:' + PORT + PATH
  );
  console.log('Upstream:', upstreamWsUrl());
});
