#!/usr/bin/env node
/**
 * 本地百炼 TTS 代理：浏览器直连 dashscope 常被 CORS 拦截，可用本脚本把 Key 留在服务端。
 *
 * 用法：
 *   export DASHSCOPE_API_KEY="sk-你的百炼Key"
 *   node scripts/dashscope-tts-proxy.mjs
 *
 * 然后在 NPC.html 右下角「百炼 TTS 代理 URL」填：http://127.0.0.1:8788/tts
 * （百炼 API Key 输入框可留空）
 *
 * 若 API Key 在新加坡等地域创建（与北京地域 Key 不互通），任选其一：
 *   export DASHSCOPE_REGION=intl
 * 或显式上游（与文档 base_http_api_url 一致）：
 *   export DASHSCOPE_TTS_UPSTREAM='https://dashscope-intl.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation'
 */
import http from 'node:http';
import https from 'node:https';

const PORT = Number(process.env.DASHSCOPE_TTS_PROXY_PORT || 8788);
function defaultTtsUpstream() {
  if (process.env.DASHSCOPE_TTS_UPSTREAM && String(process.env.DASHSCOPE_TTS_UPSTREAM).trim()) {
    return String(process.env.DASHSCOPE_TTS_UPSTREAM).trim();
  }
  const intl = process.env.DASHSCOPE_REGION === 'intl';
  const host = intl ? 'https://dashscope-intl.aliyuncs.com' : 'https://dashscope.aliyuncs.com';
  return host + '/api/v1/services/aigc/multimodal-generation/generation';
}
const UPSTREAM = defaultTtsUpstream();
const API_KEY = process.env.DASHSCOPE_API_KEY || '';

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Access-Control-Max-Age': '86400',
};

function json(res, status, obj) {
  const body = JSON.stringify(obj);
  res.writeHead(status, {
    ...CORS,
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(body),
  });
  res.end(body);
}

function forwardToDashscope(payload, onResult) {
  const u = new URL(UPSTREAM);
  const data = JSON.stringify(payload);
  const opts = {
    hostname: u.hostname,
    port: u.port || 443,
    path: u.pathname + u.search,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: 'Bearer ' + API_KEY,
      'Content-Length': Buffer.byteLength(data),
    },
  };
  const req = https.request(opts, function (proxRes) {
    var chunks = [];
    proxRes.on('data', function (c) {
      chunks.push(c);
    });
    proxRes.on('end', function () {
      var raw = Buffer.concat(chunks).toString('utf8');
      onResult(proxRes.statusCode || 502, raw);
    });
  });
  req.on('error', function (e) {
    onResult(502, JSON.stringify({ message: String(e && e.message ? e.message : e) }));
  });
  req.write(data);
  req.end();
}

const server = http.createServer(function (req, res) {
  if (req.method === 'OPTIONS') {
    res.writeHead(204, CORS);
    res.end();
    return;
  }
  if (req.url !== '/tts' || req.method !== 'POST') {
    json(res, 404, { message: 'Use POST /tts with JSON { "text": "..." }' });
    return;
  }
  if (!API_KEY) {
    json(res, 500, { message: 'Missing env DASHSCOPE_API_KEY' });
    return;
  }
  var body = '';
  req.on('data', function (c) {
    body += c;
    if (body.length > 2e6) {
      req.destroy();
    }
  });
  req.on('end', function () {
    var parsed;
    try {
      parsed = JSON.parse(body || '{}');
    } catch (e) {
      json(res, 400, { message: 'Invalid JSON body' });
      return;
    }
    var text = String(parsed.text || '').replace(/\s+/g, ' ').trim().slice(0, 600);
    if (!text) {
      json(res, 400, { message: 'Missing text' });
      return;
    }
    var model = parsed.model || 'qwen3-tts-flash';
    var voice = parsed.voice || 'Arthur';
    var language_type = parsed.language_type || 'Chinese';
    var payload = {
      model: model,
      input: { text: text, voice: voice, language_type: language_type },
    };
    if (parsed.stream === true) {
      payload.stream = true;
    }
    forwardToDashscope(
      payload,
      function (status, raw) {
        res.writeHead(status, { ...CORS, 'Content-Type': 'application/json; charset=utf-8' });
        res.end(raw);
      }
    );
  });
});

server.listen(PORT, '127.0.0.1', function () {
  console.error(
    '[dashscope-tts-proxy] listening http://127.0.0.1:' + PORT + '/tts (DASHSCOPE_API_KEY set: ' + !!API_KEY + ')'
  );
});
