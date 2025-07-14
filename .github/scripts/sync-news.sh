#!/bin/bash
# 同步新闻文件的脚本 - 适配新报纸风格模板

set -euo pipefail

echo "Starting file synchronization..."
mkdir -p content

if [ -d "source-news/summaries" ]; then
    echo "Found source-news/summaries directory"
    
    # 遍历年份和月份目录
    for year_dir in source-news/summaries/*/; do
        if [ -d "$year_dir" ]; then
            year=$(basename "$year_dir")
            
            for month_dir in "$year_dir"*/; do
                if [ -d "$month_dir" ]; then
                    month=$(basename "$month_dir")
                    dest_dir="content/${year}-${month}"
                    
                    echo "Processing month: $year-$month"
                    
                    # 收集该月所有日期
                    all_dates=$(find "$month_dir" -name '*summary_*.md' -type f 2>/dev/null | { grep -oE '[0-9]{8}' || test $? = 1; } | sort -u)
                    
                    # 如果没有任何日报文件，跳过这个月份
                    if [ -z "$all_dates" ]; then
                        echo "No markdown files found for $year-$month, skipping..."
                        continue
                    fi
                    
                    # 有内容，创建目录
                    mkdir -p "$dest_dir"
                    
                    # 计算权重
                    year_num=$((10#$year))
                    month_num=$((10#$month))
                    weight=$((100000 - (year_num - 2000) * 1000 - month_num * 10))
                    
                    # 使用模板生成索引文件
                    template_file=".github/templates/month-index.md"
                    if [ -f "$template_file" ]; then
                        # 先复制模板并替换简单的占位符
                        cp "$template_file" "$dest_dir/_index.md.tmp"
                        sed -i "s/{{YEAR}}/$year/g" "$dest_dir/_index.md.tmp"
                        sed -i "s/{{MONTH}}/$month/g" "$dest_dir/_index.md.tmp"
                        sed -i "s/{{WEIGHT}}/$weight/g" "$dest_dir/_index.md.tmp"
                        
                        # 生成内容列表
                        {
                            # 读取到 {{CONTENT}} 之前的内容
                            sed '/{{CONTENT}}/q' "$dest_dir/_index.md.tmp" | sed '$d'
                            
                            # 插入日报链接 - 新格式
                            for date_str in $all_dates; do
                                if [ -n "$date_str" ]; then
                                    year_part="${date_str:0:4}"
                                    month_part="${date_str:4:2}"
                                    day_part="${date_str:6:2}"
                                    echo "<div class=\"daily-article\">"
                                    echo "  <a href=\"${year_part}-${month_part}-${day_part}\">${month_part}-${day_part} 日报</a>"
                                    echo "</div>"
                                fi
                            done
                            
                            # 读取 {{CONTENT}} 之后的内容
                            sed '1,/{{CONTENT}}/d' "$dest_dir/_index.md.tmp"
                        } > "$dest_dir/_index.md"
                        
                        # 清理临时文件
                        rm -f "$dest_dir/_index.md.tmp"
                    else
                        echo "Warning: Template file not found: $template_file"
                    fi
                    
                    # 处理每个日期的文件
                    dates=$(find "$month_dir" -name '*summary_*.md' -type f 2>/dev/null | { grep -oE '[0-9]{8}' || test $? = 1; } | sort -u)
                    if [ -n "$dates" ]; then
                        for date_str in $dates; do
                            if [ -n "$date_str" ]; then
                                year_part="${date_str:0:4}"
                                month_part="${date_str:4:2}"
                                day_part="${date_str:6:2}"
                                day_num=$((10#$day_part))
                                
                                # 创建合并后的文件
                                merged_filename="${year_part}-${month_part}-${day_part}.md"
                                merged_file="$dest_dir/$merged_filename"
                                
                                # 添加前置元数据
                                cat > "$merged_file" << EOF
---
title: "${month_part}-${day_part}-简报"
weight: $day_num
date: ${year_part}-${month_part}-${day_part}
---

EOF
                                
                                # 处理同一天的多个文件
                                file_count=$(find "$month_dir" -name "*summary_${date_str}_*.md" -type f 2>/dev/null | wc -l || echo 0)
                                if [ $file_count -eq 1 ]; then
                                    # 单个文件，直接追加
                                    find "$month_dir" -name "*summary_${date_str}_*.md" -type f -exec cat {} \; >> "$merged_file"
                                else
                                    # 多个文件，按时间戳合并
                                    for file in $(find "$month_dir" -name "*summary_${date_str}_*.md" -type f 2>/dev/null || true); do
                                        if [ -f "$file" ]; then
                                            filename=$(basename "$file")
                                            timestamp=$(echo "$filename" | { grep -oE '[0-9]{6}\.md' || test $? = 1; } | cut -d'.' -f1)
                                            if [ -n "$timestamp" ]; then
                                                hour="${timestamp:0:2}"
                                                minute="${timestamp:2:2}"
                                                echo "## ${hour}:${minute} 更新" >> "$merged_file"
                                                echo "" >> "$merged_file"
                                            fi
                                            cat "$file" >> "$merged_file"
                                            echo "" >> "$merged_file"
                                        fi
                                    done
                                fi
                                
                                echo "Created $merged_file"
                            fi
                        done
                    fi
                fi
            done
        fi
    done
    
    echo "File synchronization complete."
    
    # 生成首页
    echo "Generating home page..."
    
    # 收集所有有内容的月份
    month_cards=""
    for month_dir in content/20*/; do
        if [ -d "$month_dir" ] && [ -f "$month_dir/_index.md" ]; then
            # 从目录名提取年月
            dirname=$(basename "$month_dir")
            year="${dirname:0:4}"
            month="${dirname:5:2}"
            
            # 统计该月文章数量
            article_count=$(find "$month_dir" -name "*.md" -not -name "_index.md" | wc -l || echo 0)
            
            # 生成新格式的月份卡片
            month_cards="${month_cards}<div class=\"month-card\">\n"
            month_cards="${month_cards}  <h3><a href=\"${dirname}\">${year}年${month}月</a></h3>\n"
            month_cards="${month_cards}  <p>收录 ${article_count} 篇AI日报，涵盖技术突破、产业动态、投资并购等关键资讯</p>\n"
            month_cards="${month_cards}</div>\n"
        fi
    done
    
    # 如果没有任何月份数据，显示暂无数据提示
    if [ -z "$month_cards" ]; then
        month_cards="<div class=\"no-data-card\">\n"
        month_cards="${month_cards}  <h3>暂无日报数据</h3>\n"
        month_cards="${month_cards}  <p>AI每日简报正在筹备中，敬请期待...</p>\n"
        month_cards="${month_cards}</div>\n"
    fi
    
    # 使用模板生成首页
    home_template=".github/templates/home-index.md"
    if [ -f "$home_template" ]; then
        sed "s|{{MONTH_CARDS}}|$month_cards|g" "$home_template" | sed '/^$/N;/\n$/d' > "content/_index.md"
        echo "Generated home page with $(echo -e "$month_cards" | wc -l) month cards"
    else
        echo "Warning: Home template not found: $home_template"
    fi
    
    echo "Synced structure:"
    find content -name "*.md" -type f | sort
else
    echo "Warning: source-news/summaries directory not found"
fi

echo "Sync process finished"