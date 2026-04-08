# 方舟平台 (Ark) 快速入门脚本 (PowerShell 版)
# 
# 这是一个零依赖的 API 调用脚本，无需安装 Python。
# 仅适用于 Windows 7 及以上系统。

$ErrorActionPreference = "Stop"

# API Key 格式校验函数
function Test-ApiKeyFormat {
    param([string]$ApiKey)
    # 匹配 UUID v4 格式：36位，带分隔符
    return $ApiKey -match '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
}

function Main {
    Write-Host "--------------------------------------------------" -ForegroundColor Cyan
    Write-Host "   方舟平台 (Ark) 快速入门自动化脚本 (Windows)   " -ForegroundColor Cyan
    Write-Host "--------------------------------------------------" -ForegroundColor Cyan
    Write-Host ""

    # 最大重试次数
    $maxRetries = 3
    $retryCount = 0

    # 重试循环
    while ($retryCount -lt $maxRetries) {
        # 1. 获取 API Key
        $apiKey = $env:ARK_API_KEY
        $useEnvKey = $false

        if (-not [string]::IsNullOrWhiteSpace($apiKey)) {
            # 脱敏展示
            $maskedKey = $apiKey.Substring(0, 4) + "****" + $apiKey.Substring($apiKey.Length - 4)
            Write-Host "检测到环境变量中的 API Key: $maskedKey"
            $confirm = Read-Host "是否使用该 API Key？[Y/n]，直接回车默认使用"
            if ($confirm -eq "" -or $confirm.ToLower() -eq "y") {
                $useEnvKey = $true
            } else {
                $apiKey = $null
            }
        }

        if (-not $useEnvKey -or [string]::IsNullOrWhiteSpace($apiKey)) {
            Write-Host "欢迎使用！我们需要您的 API Key 来调用模型服务。"
            Write-Host "如果您还没有 API Key，请访问控制台获取：https://console.volcengine.com/ark/region:ark+cn-beijing/apikey"
            Write-Host ""
            $apiKey = Read-Host "请输入您的 API Key (回车确认)"
            
            if ([string]::IsNullOrWhiteSpace($apiKey)) {
                Write-Host "API Key 不能为空！" -ForegroundColor Red
                continue
            }
        }

        # 2. 格式校验
        if (-not (Test-ApiKeyFormat $apiKey)) {
            Write-Host "API Key 格式不正确！应为 36 位 UUID 格式（如：047a86f2-fd21-4171-aa2f-2e0ca2f12345）" -ForegroundColor Red
            continue
        }

        # 3. 构造请求
        $url = "https://ark.cn-beijing.volces.com/api/v3/chat/completions"
        
        # ------------------------------------------------------------
        # 注意：请使用具体的 Model ID，不要使用 Endpoint ID (ep-xxxx)
        # ------------------------------------------------------------
        $modelId = "doubao-seed-2-0-lite-260215" 
        $userQuestion = "请用简洁的语言解释什么是人工智能。"

        $headers = @{
            "Authorization" = "Bearer $apiKey"
            "Content-Type" = "application/json; charset=utf-8"
        }
        
        $bodyPayload = @{
            model = $modelId
            messages = @(
                @{
                    role = "system"
                    content = "你是一个乐于助人的 AI 助手。"
                },
                @{
                    role = "user"
                    content = $userQuestion
                }
            )
        } | ConvertTo-Json -Depth 10

        # 强制使用 UTF-8 编码转换 Body，防止 Windows 默认编码 (GBK) 导致乱码
        $utf8Body = [System.Text.Encoding]::UTF8.GetBytes($bodyPayload)

        Write-Host ""
        Write-Host "问题：$userQuestion" -ForegroundColor Cyan
        Write-Host "正在调用豆包模型 ($modelId)..." -ForegroundColor Yellow

        # 4. 发送请求
        try {
            # Invoke-RestMethod 会自动解析 JSON 响应
            $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $utf8Body -ErrorAction Stop
            
            # 5. 展示结果
            $content = $response.choices[0].message.content
            
            Write-Host ""
            Write-Host "调用成功！模型回复：" -ForegroundColor Green
            Write-Host "--------------------------------------------------"
            Write-Host $content
            Write-Host "--------------------------------------------------"
            Write-Host ""
            return

        } catch {
            $statusCode = [int]$_.Exception.Response.StatusCode
            if ($statusCode -eq 401 -or $statusCode -eq 403) {
                $retryCount++
                $remaining = $maxRetries - $retryCount
                Write-Host ""
                Write-Host "API Key 无效或权限不足！剩余重试次数：$remaining" -ForegroundColor Red
                Write-Host "请检查您的 API Key 是否正确，或者重新输入。" -ForegroundColor Yellow
                # 清空环境变量检测状态，强制用户重新输入
                Remove-Item Env:ARK_API_KEY -ErrorAction SilentlyContinue
                continue
            } else {
                Write-Host ""
                Write-Host "调用失败: $($_.Exception.Message)" -ForegroundColor Red
                
                # 尝试读取详细错误信息
                if ($_.Exception.Response) {
                    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                    $errBody = $reader.ReadToEnd()
                    Write-Host "详细错误: $errBody" -ForegroundColor Red
                }

                Write-Host "可能的原因："
                Write-Host "1. API Key 无效或过期"
                Write-Host "2. 模型 ID 不存在或无权限调用"
                Write-Host "3. 网络连接问题"
                return
            }
        }
    }

    # 重试次数耗尽
    Write-Host ""
    Write-Host "重试次数已达上限！请确认您的 API Key 正确无误后重新运行脚本。" -ForegroundColor Red
}

Main
