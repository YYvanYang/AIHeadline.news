#!/bin/bash
# 本地测试脚本 - 从 ai-news-vault 获取数据并同步

echo "=== AI News Hugo 本地测试脚本 ==="

# 检查是否已经克隆了源仓库
if [ ! -d "source-news" ]; then
    echo "克隆 ai-news-vault 仓库..."
    git clone https://github.com/YYvanYang/ai-news-vault.git source-news
else
    echo "更新 ai-news-vault 仓库..."
    cd source-news && git pull && cd ..
fi

# 清理旧的测试内容
echo "清理旧的测试内容..."
rm -rf content/20*

# 使用同样的同步脚本
echo "开始同步新闻文件..."
./.github/scripts/sync-news.sh

echo ""
echo "运行 'hugo server' 启动本地服务器进行测试"