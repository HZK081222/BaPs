#!/bin/bash
set -e  # 任何命令失败立即退出，避免后续无效执行

# ==============================================
# 步骤1：提前处理Il2CppInspector（关键！确保Python脚本运行前准备好）
# ==============================================
echo "=== 1. Prepare Il2CppInspector ==="
# 1.1 创建临时目录
mkdir -p Temp/Il2CppInspector
# 1.2 使用【具体版本链接】下载（避免latest重定向问题，选择已知可用版本）
IL2CPP_ZIP_URL="https://github.com/djkaty/Il2CppInspector/releases/download/v2024.1.0/Il2CppInspectorRedux.CLI.zip"
IL2CPP_ZIP_PATH="Temp/Il2CppInspectorRedux.CLI.zip"

# 优化curl参数：跟随重定向、指定User-Agent、失败重试、显示进度
echo "Downloading Il2CppInspector from $IL2CPP_ZIP_URL..."
curl -L -f -A "Mozilla/5.0 (Linux; Ubuntu 22.04; x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
  -o "$IL2CPP_ZIP_PATH" \
  --retry 3 \
  --progress-bar "$IL2CPP_ZIP_URL"

# 1.3 校验ZIP包是否有效（避免下载损坏文件）
echo "Checking if Il2CppInspector ZIP is valid..."
if ! unzip -t "$IL2CPP_ZIP_PATH" > /dev/null 2>&1; then
  echo "Error: Invalid Il2CppInspector ZIP file! Download failed."
  rm -f "$IL2CPP_ZIP_PATH"  # 删除损坏文件
  exit 1
fi

# 1.4 解压ZIP包（覆盖已有文件）
echo "Unzipping Il2CppInspector..."
unzip -o "$IL2CPP_ZIP_PATH" -d Temp/Il2CppInspector

# 1.5 找到并配置可执行文件（处理可能的子目录，如linux-x64）
IL2CPP_EXE=$(find Temp/Il2CppInspector -name "Il2CppInspector" -type f | head -n 1)
if [ -z "$IL2CPP_EXE" ]; then
  echo "Error: Il2CppInspector executable not found after unzip!"
  exit 1
fi
# 赋予执行权限并创建软链接（确保Python脚本能在预期路径找到）
chmod +x "$IL2CPP_EXE"
ln -sf "$IL2CPP_EXE" Temp/Il2CppInspector/Il2CppInspector
echo "Il2CppInspector prepared at: $(readlink -f Temp/Il2CppInspector/Il2CppInspector)"


# ==============================================
# 步骤2：原有的依赖安装和资源下载（顺序不变）
# ==============================================
echo -e "\n=== 2. Install Dependencies ==="
git clone https://github.com/asfu222/BlueArchiveLocalizationTools
pip3 install --user -r BlueArchiveLocalizationTools/requirements.txt  # --user避免权限问题

echo -e "\n=== 3. Update URLs and Download Excel Resources ==="
python3 BlueArchiveLocalizationTools/update_urls.py ba.env ./data/ServerInfo.json
export $(grep -v '^#' ba.env | xargs)
echo "Using catalog url: $ADDRESSABLE_CATALOG_URL"

mkdir -p resources/TableBundles
# 下载Excel资源时也添加curl优化参数
curl -L -f -A "Mozilla/5.0 (Linux; Ubuntu 22.04; x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
  -o resources/TableBundles/Excel.zip \
  --retry 3 \
  --progress-bar "${ADDRESSABLE_CATALOG_URL}/TableBundles/Excel.zip"

curl -L -f -A "Mozilla/5.0 (Linux; Ubuntu 22.04; x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
  -o resources/TableBundles/ExcelDB.db \
  --retry 3 \
  --progress-bar "${ADDRESSABLE_CATALOG_URL}/TableBundles/ExcelDB.db"


# ==============================================
# 步骤3：最后执行Python脚本（此时Il2Cpp已准备好）
# ==============================================
echo -e "\n=== 4. Run fetch_resources.py ==="
python3 fetch_resources.py
