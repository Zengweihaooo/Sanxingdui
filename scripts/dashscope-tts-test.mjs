#!/usr/bin/env node
/**
 * 用 Node 直连百炼「语音合成 Qwen-TTS」HTTP 接口（无浏览器 CORS），验证 API Key 与地域是否正确。
 *
 *   export DASHSCOPE_API_KEY="sk-你的百炼Key"
 *   node scripts/dashscope-tts-test.mjs
 *
 * 新加坡 Key（与北京 Key 不互通）任选其一：
 *   export DASHSCOPE_REGION=intl
 * 或：
 *   export DASHSCOPE_TTS_UPSTREAM="https://dashscope-intl.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation"
 *   node scripts/dashscope-tts-test.mjs
 */
import https from 'node:https';

const API_KEY = process.env.DASHSCOPE_API_KEY || '';
function defaultUpstream() {
  if (process.env.DASHSCOPE_TTS_UPSTREAM && String(process.env.DASHSCOPE_TTS_UPSTREAM).trim()) {
    return String(process.env.DASHSCOPE_TTS_UPSTREAM).trim();
  }
  const intl = process.env.DASHSCOPE_REGION === 'intl';
  const host = intl ? 'https://dashscope-intl.aliyuncs.com' : 'https://dashscope.aliyuncs.com';
  return host + '/api/v1/services/aigc/multimodal-generation/generation';
}
const UPSTREAM = defaultUpstream();

const body = JSON.stringify({
  model: 'qwen3-tts-flash',
  input: {
    text: '三星堆青铜面具，是古蜀文明的珍贵遗存。',
    voice: 'Arthur',
    language_type: 'Chinese',
  },
});

if (!API_KEY) {
  console.error('请设置环境变量 DASHSCOPE_API_KEY');
  process.exit(1);
}

const u = new URL(UPSTREAM);
const opts = {
  hostname: u.hostname,
  port: u.port || 443,
  path: u.pathname + u.search,
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    Authorization: 'Bearer ' + API_KEY,
    'Content-Length': Buffer.byteLength(body),
  },
};

const req = https.request(opts, function (res) {
  var chunks = [];
  res.on('data', function (c) {
    chunks.push(c);
  });
  res.on('end', function () {
    var raw = Buffer.concat(chunks).toString('utf8');
    var data;
    try {
      data = JSON.parse(raw);
    } catch (e) {
      console.error('非 JSON 响应 HTTP', res.statusCode, raw.slice(0, 500));
      process.exit(1);
      return;
    }
    if (data.status_code != null && Number(data.status_code) !== 200) {
      console.error('status_code', data.status_code, data.message || data.code || raw.slice(0, 400));
      process.exit(1);
      return;
    }
    if (data.code != null && String(data.code).trim() !== '') {
      console.error('业务错误', data.code, data.message || raw.slice(0, 400));
      process.exit(1);
      return;
    }
    var url = data.output && data.output.audio && data.output.audio.url;
    if (!url) {
      console.error('无 output.audio.url', JSON.stringify(data).slice(0, 600));
      process.exit(1);
      return;
    }
    console.error('OK，音频 URL（约 24h 有效）：');
    console.log(url);
    process.exit(0);
  });
});

req.on('error', function (e) {
  console.error('请求失败', e && e.message ? e.message : e);
  process.exit(1);
});

req.write(body);
req.end();
