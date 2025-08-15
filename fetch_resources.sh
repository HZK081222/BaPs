#!/bin/bash

# 克隆依赖仓库
git clone https://github.com/asfu222/BlueArchiveLocalizationTools

# 安装Python依赖
pip3 install -r BlueArchiveLocalizationTools/requirements.txt

# 更新URL配置
python3 BlueArchiveLocalizationTools/update_urls.py ba.env ./data/ServerInfo.json

# 导出环境变量
export $(grep -v '^#' ba.env | xargs)

# 显示Catalog URL
echo Using catalog url: $ADDRESSABLE_CATALOG_URL

# 创建资源目录并下载表格文件
mkdir -p resources/TableBundles
curl "${ADDRESSABLE_CATALOG_URL}/TableBundles/Excel.zip" -o resources/TableBundles/Excel.zip
curl "${ADDRESSABLE_CATALOG_URL}/TableBundles/ExcelDB.db" -o resources/TableBundles/ExcelDB.db

# 新增：处理Il2CppInspector（解决核心报错）
echo "Downloading Il2CppInspector..."
mkdir -p Temp
IL2CPP_URL="https://github.com/djkaty/Il2CppInspector/releases/latest/download/Il2CppInspectorRedux.CLI.zip"
# 下载Il2CppInspector到Temp目录
curl -L "$IL2CPP_URL" -o Temp/Il2CppInspectorRedux.CLI.zip

# 解压到Temp/Il2CppInspector目录
mkdir -p Temp/Il2CppInspector
unzip -o Temp/Il2CppInspectorRedux.CLI.zip -d Temp/Il2CppInspector

# 查找可执行文件（处理可能的子目录结构）
IL2CPP_EXE=$(find Temp/Il2CppInspector -name "Il2CppInspector" -type f | head -n 1)

if [ -z "$IL2CPP_EXE" ]; then
  echo "Error: Il2CppInspector executable not found!"
  exit 1
fi

# 赋予执行权限
chmod +x "$IL2CPP_EXE"

# 创建软链接到预期路径（确保脚本能找到）
ln -s "$IL2CPP_EXE" Temp/Il2CppInspector/Il2CppInspector

# 执行主脚本
python3 fetch_resources.py
