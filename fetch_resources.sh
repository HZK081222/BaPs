#!/bin/bash
set -e  # 任何命令失败立即退出，避免后续无效执行

# ==============================================
# 步骤0：安装Wine依赖（用于运行Windows版本Il2CppInspector）
# ==============================================
echo "=== 0. Install Wine (for Windows Il2CppInspector) ==="
sudo dpkg --add-architecture i386  # 启用32位架构支持
sudo apt-get update
sudo apt-get install -y wine64 wine32  # 安装Wine（64位+32位支持）

# 验证Wine安装
echo "Testing Wine installation..."
if ! wine --version &> /dev/null; then
  echo "Error: Wine installation failed!"
  exit 1
fi

# ==============================================
# 步骤1：准备Il2CppInspector（使用Windows版本+Wine运行）
# ==============================================
echo -e "\n=== 1. Prepare Il2CppInspector ==="
# 1.1 创建临时目录
mkdir -p Temp/Il2CppInspector
# 1.2 下载Windows版本的Il2CppInspector（使用有效链接）
IL2CPP_ZIP_URL="https://github.com/djkaty/Il2CppInspector/releases/download/2021.1/Il2CppInspector-2021.1.zip"
IL2CPP_ZIP_PATH="Temp/Il2CppInspectorRedux.CLI.zip"

# 优化curl参数：跟随重定向、指定User-Agent、失败重试、显示进度
echo "Downloading Il2CppInspector from $IL2CPP_ZIP_URL..."
curl -L -f -A "Mozilla/5.0 (Linux; Ubuntu 22.04; x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
  -o "$IL2CPP_ZIP_PATH" \
  --retry 3 \
  --progress-bar "$IL2CPP_ZIP_URL"

# 1.3 校验ZIP包是否有效
echo "Checking if Il2CppInspector ZIP is valid..."
if ! unzip -t "$IL2CPP_ZIP_PATH" > /dev/null 2>&1; then
  echo "Error: Invalid Il2CppInspector ZIP file! Download failed."
  rm -f "$IL2CPP_ZIP_PATH"
  exit 1
fi

# 1.4 解压ZIP包（覆盖已有文件）
echo "Unzipping Il2CppInspector..."
unzip -o "$IL2CPP_ZIP_PATH" -d Temp/Il2CppInspector

# 1.5 查找Windows版本的可执行文件（.exe）
IL2CPP_EXE=$(find Temp/Il2CppInspector -name "Il2CppInspector-cli.exe" -type f | head -n 1)
if [ -z "$IL2CPP_EXE" ]; then
  # 备选：查找主程序exe
  IL2CPP_EXE=$(find Temp/Il2CppInspector -name "Il2CppInspector.exe" -type f | head -n 1)
fi

if [ -z "$IL2CPP_EXE" ]; then
  echo "Error: Il2CppInspector .exe file not found after unzip!"
  exit 1
fi

# 创建软链接方便后续调用（通过Wine运行）
ln -sf "$IL2CPP_EXE" Temp/Il2CppInspector/Il2CppInspector.exe
echo "Il2CppInspector (Windows) prepared at: $(readlink -f Temp/Il2CppInspector/Il2CppInspector.exe)"


# ==============================================
# 步骤2：原有的依赖安装和资源下载（保持不变）
# ==============================================
echo -e "\n=== 2. Install Dependencies ==="
git clone https://github.com/asfu222/BlueArchiveLocalizationTools
pip3 install --user -r BlueArchiveLocalizationTools/requirements.txt  # --user避免权限问题

echo -e "\n=== 3. Update URLs and Download Excel Resources ==="
python3 BlueArchiveLocalizationTools/update_urls.py ba.env ./data/ServerInfo.json
export $(grep -v '^#' ba.env | xargs)
echo "Using catalog url: $ADDRESSABLE_CATALOG_URL"

mkdir -p resources/TableBundles
# 下载Excel资源（保持curl优化参数）
curl -L -f -A "Mozilla/5.0 (Linux; Ubuntu 22.04; x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
  -o resources/TableBundles/Excel.zip \
  --retry 3 \
  --progress-bar "${ADDRESSABLE_CATALOG_URL}/TableBundles/Excel.zip"

curl -L -f -A "Mozilla/5.0 (Linux; Ubuntu 22.04; x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
  -o resources/TableBundles/ExcelDB.db \
  --retry 3 \
  --progress-bar "${ADDRESSABLE_CATALOG_URL}/TableBundles/ExcelDB.db"


# ==============================================
# 步骤3：执行Python脚本（若需调用Il2CppInspector，需用wine前缀）
# ==============================================
echo -e "\n=== 4. Run fetch_resources.py ==="
python3 fetch_resources.py
