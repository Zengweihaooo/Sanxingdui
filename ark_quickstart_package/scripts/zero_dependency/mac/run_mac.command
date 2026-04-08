#!/bin/bash

# 方舟平台 (Ark) 快速入门启动脚本 (Mac/Linux)
# 
# 这是一个零依赖的启动脚本，无需安装 Python。
# 
# 首次运行说明：
# 如果双击运行时提示「无法验证是否包含恶意软件」，请右键点击本文件 → 选择「打开」，然后在弹出的确认框中再次点击「打开」即可。
# 或者也可以直接在终端执行 ./quickstart.sh 运行。

# 切换到脚本所在目录
cd "$(dirname "$0")"

# 赋予脚本执行权限
chmod +x quickstart.sh

# 运行脚本
./quickstart.sh

echo ""
read -p "按回车键退出..."
