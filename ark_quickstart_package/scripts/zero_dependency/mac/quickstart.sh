#!/bin/bash

# 方舟平台 (Ark) 快速入门脚本 (Bash + Curl 版)
# 
# 这是一个零依赖的 API 调用脚本，无需安装 Python。
# 适用于 macOS 和 Linux。

set -e

# API Key 格式校验函数
validate_api_key() {
    local api_key=$1
    # 匹配 UUID v4 格式：36位，带分隔符
    if echo "$api_key" | grep -E '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$' > /dev/null; then
        return 0
    else
        return 1
    fi
}

echo "--------------------------------------------------"
echo "   方舟平台 (Ark) 快速入门自动化脚本 (macOS/Linux)   "
echo "--------------------------------------------------"
echo ""

# 最大重试次数
MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    # 1. 获取 API Key
    API_KEY=$ARK_API_KEY
    USE_ENV_KEY=false

    if [ -n "$API_KEY" ]; then
        # 脱敏展示：前4位 + **** + 后4位
        MASKED_KEY="${API_KEY:0:4}****${API_KEY: -4}"
        echo "检测到环境变量中的 API Key: $MASKED_KEY"
        read -p "是否使用该 API Key？[Y/n]，直接回车默认使用: " CONFIRM
        # 兼容 Bash 3.2（macOS 默认版本）的小写转换
        CONFIRM_LOWER=$(echo "$CONFIRM" | tr '[:upper:]' '[:lower:]')
        if [ -z "$CONFIRM" ] || [ "$CONFIRM_LOWER" = "y" ]; then
            USE_ENV_KEY=true
        else
            API_KEY=""
        fi
    fi

    if [ "$USE_ENV_KEY" = false ] || [ -z "$API_KEY" ]; then
        echo "欢迎使用！我们需要您的 API Key 来调用模型服务。"
        echo "如果您还没有 API Key，请访问控制台获取：https://console.volcengine.com/ark/region:ark+cn-beijing/apikey"
        echo ""
        read -p "请输入您的 API Key (回车确认): " API_KEY
        if [ -z "$API_KEY" ]; then
            echo "API Key 不能为空！"
            continue
        fi
    fi

    # 2. 格式校验
    if ! validate_api_key "$API_KEY"; then
        echo "API Key 格式不正确！应为 36 位 UUID 格式（如：047a86f2-fd21-4171-aa2f-2e0ca2f12345）"
        continue
    fi

    # 3. 构造请求
    URL="https://ark.cn-beijing.volces.com/api/v3/chat/completions"

    # ------------------------------------------------------------
    # 注意：请使用具体的 Model ID，不要使用 Endpoint ID (ep-xxxx)
    # ------------------------------------------------------------
    MODEL="doubao-seed-2-0-lite-260215"

    CONTENT="请用简洁的语言解释什么是人工智能。"

    # 构造 JSON Body
    BODY=$(cat <<EOF
{
    "model": "$MODEL",
    "messages": [
        {"role": "system", "content": "你是一个乐于助人的 AI 助手。"},
        {"role": "user", "content": "$CONTENT"}
    ]
}
EOF
)

    echo ""
    echo "问题：$CONTENT"
    echo "正在调用豆包模型 ($MODEL)..."

    # 4. 发送请求
    # -s: Silent mode
    # -w: Write out HTTP code
    # -o: Write response body to file
    HTTP_CODE=$(curl -s -w "%{http_code}" -o response.json \
        -X POST "$URL" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        -d "$BODY")

    # 5. 处理结果
    if [ "$HTTP_CODE" -eq 200 ]; then
        echo ""
        echo "调用成功！模型回复："
        echo "--------------------------------------------------"
        
        # 尝试解析 JSON
        if command -v jq &> /dev/null; then
            # 如果有 jq，用 jq 解析
            cat response.json | jq -r '.choices[0].message.content'
        elif command -v osascript &> /dev/null; then
            # 如果是 macOS，用 osascript (JavaScript) 解析
            # 读取文件内容并转义单引号，防止 JS 注入
            JSON_CONTENT=$(cat response.json | sed "s/'/\\\\'/g")
            osascript -l JavaScript -e "var json = JSON.parse('$JSON_CONTENT'); console.log(json.choices[0].message.content);"
        elif command -v python3 &> /dev/null; then
            # 如果有 python3，用 python3 解析
            python3 -c "import sys, json; print(json.load(sys.stdin)['choices'][0]['message']['content'])" < response.json
        else
            # 如果都没有，只能简单打印整个 JSON 或者尝试 grep
            echo "未检测到 JSON 解析工具 (jq/python3/osascript)。"
            echo "以下是原始响应："
            cat response.json
        fi
        
        echo "--------------------------------------------------"
        echo ""
        rm -f response.json
        exit 0

    elif [ "$HTTP_CODE" -eq 401 ] || [ "$HTTP_CODE" -eq 403 ]; then
        RETRY_COUNT=$((RETRY_COUNT + 1))
        REMAINING=$((MAX_RETRIES - RETRY_COUNT))
        echo ""
        echo "API Key 无效或权限不足！剩余重试次数：$REMAINING"
        echo "请检查您的 API Key 是否正确，或者重新输入。"
        # 清空环境变量，强制下次重新输入
        unset ARK_API_KEY
        rm -f response.json
        continue

    else
        echo ""
        echo "调用失败 (HTTP $HTTP_CODE):"
        cat response.json
        rm -f response.json
        echo ""
        echo "可能的原因："
        echo "1. API Key 无效或过期"
        echo "2. 模型 ID 不存在或无权限调用"
        echo "3. 网络连接问题"
        exit 1
    fi
done

# 重试次数耗尽
echo ""
echo "重试次数已达上限！请确认您的 API Key 正确无误后重新运行脚本。"
rm -f response.json
exit 1
