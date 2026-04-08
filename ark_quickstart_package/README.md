# 方舟平台快速入门（零依赖版）

欢迎使用方舟平台！本教程专为**零基础用户**设计，无需安装任何编程环境（如 Python），直接使用操作系统内置工具即可体验方舟大模型服务。

## 1. 准备工作

在开始之前，请确保您已经完成以下准备：

1.  **注册账号**：确保您拥有火山引擎账号并已登录。
2.  **获取 API Key**：
    *   访问 [API Key 管理页面](https://console.volcengine.com/ark/region:ark+cn-beijing/apikey)。
    *   点击“创建 API Key”，并复制保存您的 Key（以 `ark-` 开头的字符串）。
    *   *注意：请妥善保管您的 API Key，不要泄露给他人。*
3.  **开通模型**：
    *   确保您已开通 `doubao-seed-2-0-lite` 或类似的豆包模型。
    *   如果没有，请访问 [模型广场](https://console.volcengine.com/ark/region:ark+cn-beijing/model) 申请开通。
    *   **注意**：调用时请使用具体的 Model ID（例如 `doubao-seed-2-0-lite-260215`），**不要**使用 Endpoint ID（以 `ep-` 开头的 ID）。

---

## 2. 阶段一：一键体验（零门槛）

我们为您准备了无需安装任何软件的自动化脚本。请根据您的操作系统选择对应的操作。

### Windows 用户

**适用系统**：Windows 7 SP1 及以上（推荐 Windows 10/11）

1.  找到项目文件夹中的 `scripts/zero_dependency/windows` 目录。
2.  双击运行 **`run_windows.bat`** 文件。
    *   *提示：如果这是您第一次运行，可能会弹出权限询问窗口，请输入 `Y` 或允许运行。*
3.  脚本会自动启动 PowerShell 环境。
4.  根据提示输入您的 **API Key** 并回车。
5.  稍等片刻，您将看到 AI 的回复内容。

### macOS 用户

**适用系统**：所有 macOS 版本

1.  找到项目文件夹中的 `scripts/zero_dependency/mac` 目录。
2.  双击运行 **`run_mac.command`** 文件。
    *   *提示：如果系统提示“无法打开，因为它来自未验证的开发者”，请按住 `Control` 键点击文件，选择“打开”，然后在弹出的对话框中再次点击“打开”。*
3.  终端窗口会自动打开。
4.  根据提示输入您的 **API Key** 并回车。
5.  等待片刻，您将看到 AI 的回复内容。

---

## 3. 阶段二：进阶（一键搭建专业开发环境）

如果您已经成功体验了 API 调用，并希望开始真正的 Python 编程开发，但又不想被复杂的环境配置（Python 版本、pip、虚拟环境）所困扰，请尝试我们的**自动化环境构建工具**。

我们将使用现代化的 Python 包管理器 `uv`，为您在项目内部自动下载并配置一个**隔离的、纯净的、标准的** Python 开发环境。

### Windows 用户

1.  进入 `scripts/init_dev_env` 目录。
2.  双击运行 **`setup_windows.bat`**。
3.  脚本会自动执行以下操作：
    *   下载 `uv` 工具。
    *   自动下载 Python 3.12（如果不干扰您的系统 Python）。
    *   创建虚拟环境 `.venv`。
    *   安装方舟 SDK。
4.  完成后，在项目根目录会生成一个 **`run_demo.bat`**。
5.  双击 `run_demo.bat`，即可运行标准的 Python SDK 示例代码 (`python/demo_standard.py`)。

### macOS 用户

1.  打开终端，进入 `scripts/init_dev_env` 目录。
2.  运行构建脚本：
    ```bash
    ./setup_mac.sh
    ```
3.  脚本会自动配置好所有环境。
4.  完成后，在项目根目录会生成一个 **`run_demo.sh`**。
5.  运行 `./run_demo.sh` 即可体验标准开发流程。

---

## 4. 技术原理解析

### 阶段一（零依赖脚本）
当您看到“调用成功”时，说明您已经完成了第一次 API 调用。
脚本自动完成了以下步骤：
1.  **构造请求**：按照方舟平台的规范，打包了一段问候语：“你好！请用一句话介绍一下你自己。”
2.  **发送请求**：使用系统自带的网络工具（Windows 的 PowerShell 或 Mac 的 Curl）向方舟服务器发送消息。
3.  **解析回复**：自动处理服务器返回的数据，并提取出 AI 生成的文本展示给您。

### 阶段二（专业开发环境）
当您运行 `setup_windows.bat` 或 `setup_mac.sh` 后，您的项目文件夹中多了一个 `.venv` 文件夹。
这是一个**虚拟环境 (Virtual Environment)**。它包含了 Python 解释器和方舟 SDK。
*   **优势**：无论您系统里安装了何种 Python 版本，该目录下的环境始终是纯净、稳定、可用的。
*   **后续建议**：您可以下载 [VS Code](https://code.visualstudio.com/)，打开本项目文件夹，VS Code 会自动识别到该虚拟环境，您即可像专业工程师一样开始编写代码。

---

## 5. 常见问题

**Q: 双击 `run_windows.bat` 后窗口一闪而过怎么办？**
A: 请尝试右键点击 `run_windows.bat`，选择“以管理员身份运行”。或者先打开 CMD 命令行，拖入 `run_windows.bat` 文件运行，查看具体报错信息。

**Q: Mac 提示“Permission denied”？**
A: 请打开终端，输入 `chmod +x `（注意最后有个空格），然后将 `run_mac.command` 文件拖入终端，按回车。这会赋予文件运行权限。

**Q: 报错“API Key 无效”？**
A: 请检查您输入的 Key 是否完整，是否包含多余的空格。建议直接从控制台复制粘贴。

---

## 6. 下一步

您已经成功迈出了第一步！接下来，您可以：

*   **修改对话内容**：
    *   **Windows**: 右键点击 `quickstart.ps1`，选择“编辑”，修改 `$body` 部分的 `"content"` 内容。
    *   **Mac**: 右键点击 `quickstart.sh`，选择“打开方式 -> 文本编辑”，修改 `CONTENT` 变量的内容。
*   **学习更多**：查看 [标准版快速入门](../md/quickstart.md) 了解更多代码细节和进阶用法。
*   **浏览模型**：访问 [模型广场](https://console.volcengine.com/ark/region:ark+cn-beijing/model) 查看更多可用的强大模型。
