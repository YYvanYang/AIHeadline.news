#!/bin/bash
# AI每日简报内容同步脚本
# 
# 功能：从ai-news-vault仓库同步markdown文件并生成Hugo站点内容
# 作者：AI每日简报团队
# 版本：2.3 - 优化标题生成，避免重复

set -euo pipefail

# =============================================================================
# 配置常量
# =============================================================================
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly SOURCE_DIR="${PROJECT_ROOT}/source-news/summaries"
readonly CONTENT_DIR="${PROJECT_ROOT}/content"
readonly TEMPLATE_DIR="${PROJECT_ROOT}/.github/templates"

# =============================================================================
# 工具函数
# =============================================================================

# 日志输出函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

# 错误退出函数
die() {
    log "ERROR: $*"
    cleanup_temp_files
    exit 1
}

# 清理临时文件
cleanup_temp_files() {
    log "Cleaning up temporary files..."
    
    if [[ -d "$CONTENT_DIR" ]]; then
        find "$CONTENT_DIR" -name ".tmp_sync*" -type f -delete 2>/dev/null || true
        find "$CONTENT_DIR" -name ".*_tmp" -type f -delete 2>/dev/null || true
    fi
    
    log "Temporary files cleanup completed"
}

# 设置清理陷阱
trap cleanup_temp_files EXIT

# 验证日期格式 (YYYYMMDD)
validate_date() {
    local date_str="$1"
    [[ "$date_str" =~ ^[0-9]{8}$ ]] || return 1
    
    local year="${date_str:0:4}"
    local month="${date_str:4:2}"
    local day="${date_str:6:2}"
    
    # 基本范围检查
    [[ "$year" -ge 2020 && "$year" -le 2030 ]] || return 1
    [[ "$month" -ge 01 && "$month" -le 12 ]] || return 1
    [[ "$day" -ge 01 && "$day" -le 31 ]] || return 1
    
    return 0
}

# 解析日期字符串
parse_date() {
    local date_str="$1"
    validate_date "$date_str" || die "Invalid date format: $date_str"
    
    echo "year=${date_str:0:4}"
    echo "month=${date_str:4:2}"
    echo "day=${date_str:6:2}"
}

# 计算权重（用于排序）
calculate_weight() {
    local year="$1"
    local month="$2"
    local day="${3:-1}"
    
    local year_num=$((10#$year))
    local month_num=$((10#$month))
    local day_num=$((10#$day))
    
    echo $((100000 - (year_num - 2000) * 1000 - month_num * 10 - day_num))
}

# 收集月份的所有日期
collect_month_dates() {
    local month_dir="$1"
    
    find "$month_dir" -name '*summary_*.md' -type f 2>/dev/null | \
        grep -oE '[0-9]{8}' | \
        sort -u | \
        while IFS= read -r date_str; do
            if validate_date "$date_str"; then
                echo "$date_str"
            else
                log "WARN: Skipping invalid date: $date_str"
            fi
        done
}

# 生成日报页面 - 优化版本，避免标题重复
generate_daily_page() {
    local month_dir="$1"
    local dest_dir="$2"
    local date_str="$3"
    
    eval "$(parse_date "$date_str")"
    local day_weight
    day_weight=$(calculate_weight "$year" "$month" "$day")
    
    local merged_file="${dest_dir}/${year}-${month}-${day}.md"
    
    # 生成前置数据 - 添加自定义字段
    cat > "$merged_file" << FILE_EOF
---
title: "${month}-${day}-简报"
weight: $day_weight
date: ${year}-${month}-${day}
description: "AI每日简报 - ${year}年${month}月${day}日行业动态"
toc: true
---

FILE_EOF
    
    # 查找该日期的所有文件
    local files=()
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(find "$month_dir" -name "*summary_${date_str}_*.md" -type f -print0 2>/dev/null)
    
    if [[ ${#files[@]} -eq 0 ]]; then
        log "WARN: No files found for date $date_str"
        return 1
    elif [[ ${#files[@]} -eq 1 ]]; then
        # 单个文件，直接追加
        cat "${files[0]}" >> "$merged_file"
    else
        # 多个文件，按时间戳合并
        for file in "${files[@]}"; do
            local filename
            filename="$(basename "$file")"
            
            # 提取时间戳 (HHMMSS)
            if [[ "$filename" =~ summary_[0-9]{8}_([0-9]{6})\.md$ ]]; then
                local timestamp="${BASH_REMATCH[1]}"
                local hour="${timestamp:0:2}"
                local minute="${timestamp:2:2}"
                
                {
                    echo "### ${hour}:${minute} 更新"
                    echo ""
                    cat "$file"
                    echo ""
                } >> "$merged_file"
            else
                # 没有时间戳的文件
                cat "$file" >> "$merged_file"
                echo "" >> "$merged_file"
            fi
        done
    fi
    
    log "Generated: $merged_file"
}

# 生成月份索引页面
generate_month_index() {
    local dest_dir="$1"
    local year="$2"
    local month="$3"
    local dates=("${@:4}")
    
    local weight
    weight=$(calculate_weight "$year" "$month")
    
    local template_file="${TEMPLATE_DIR}/month-index.md"
    [[ -f "$template_file" ]] || die "Template not found: $template_file"
    
    local temp_file="${dest_dir}/.month_index_tmp"
    local content_file="${dest_dir}/.content_tmp"
    
    # 生成内容列表
    : > "$content_file"
    for date_str in "${dates[@]}"; do
        eval "$(parse_date "$date_str")"
        cat >> "$content_file" << CONTENT_EOF
<div class="daily-article">
  <a href="${year}-${month}-${day}">${month}-${day} 日报</a>
</div>
CONTENT_EOF
    done
    
    # 替换模板占位符
    sed "s/{{YEAR}}/$year/g; s/{{MONTH}}/$month/g; s/{{WEIGHT}}/$weight/g" \
        "$template_file" > "$temp_file"
    
    # 插入内容
    sed "/{{CONTENT}}/r $content_file" "$temp_file" | \
        sed '/{{CONTENT}}/d' > "${dest_dir}/_index.md"
    
    # 清理临时文件
    rm -f "$temp_file" "$content_file"
    
    log "Generated month index: ${dest_dir}/_index.md"
}

# 生成首页
generate_home_page() {
    log "Starting home page generation..."
    
    local template_file="${TEMPLATE_DIR}/home-index.md"
    [[ -f "$template_file" ]] || die "Home template not found: $template_file"
    
    local cards_file="${CONTENT_DIR}/.cards_tmp"
    
    # 收集月份卡片
    : > "$cards_file"
    
    local month_count=0
    for month_dir in "${CONTENT_DIR}"/20*/; do
        [[ -d "$month_dir" ]] || continue
        [[ -f "${month_dir}/_index.md" ]] || continue
        
        local dirname
        dirname="$(basename "$month_dir")"
        local year="${dirname:0:4}"
        local month="${dirname:5:2}"
        
        # 统计文章数量
        local article_count
        article_count=$(find "$month_dir" -name "*.md" -not -name "_index.md" -type f | wc -l)
        
        cat >> "$cards_file" << CARD_EOF
<div class="month-card">
  <h3><a href="${dirname}">${year}年${month}月</a></h3>
  <p>收录 ${article_count} 篇AI日报，涵盖技术突破、产业动态、投资并购等关键资讯</p>
</div>
CARD_EOF
        # 修复：使用安全的递增方式
        month_count=$((month_count + 1))
    done
    
    # 如果没有数据，显示提示
    if [[ $month_count -eq 0 ]]; then
        cat > "$cards_file" << NO_DATA_EOF
<div class="no-data-card">
  <h3>暂无日报数据</h3>
  <p>AI每日简报正在筹备中，敬请期待...</p>
</div>
NO_DATA_EOF
    fi
    
    # 生成首页
    if sed "/{{MONTH_CARDS}}/r $cards_file" "$template_file" | \
        sed '/{{MONTH_CARDS}}/d' > "${CONTENT_DIR}/_index.md"; then
        log "Generated home page with $month_count months"
    else
        die "Failed to generate home page"
    fi
    
    # 清理临时文件
    rm -f "$cards_file"
}

# =============================================================================
# 主要功能函数
# =============================================================================

# 处理单个月份
process_month() {
    local month_dir="$1"
    local year="$2"
    local month="$3"
    
    log "Processing month: $year-$month"
    
    # 收集该月所有有效日期
    local dates=()
    while IFS= read -r date_str; do
        [[ -n "$date_str" ]] && dates+=("$date_str")
    done < <(collect_month_dates "$month_dir")
    
    if [[ ${#dates[@]} -eq 0 ]]; then
        log "No valid dates found for $year-$month, skipping..."
        return 0
    fi
    
    local dest_dir="${CONTENT_DIR}/${year}-${month}"
    mkdir -p "$dest_dir"
    
    # 生成每日页面
    for date_str in "${dates[@]}"; do
        generate_daily_page "$month_dir" "$dest_dir" "$date_str" || log "WARN: Failed to generate page for $date_str"
    done
    
    # 生成月份索引
    generate_month_index "$dest_dir" "$year" "$month" "${dates[@]}"
    
    log "Completed month: $year-$month (${#dates[@]} days)"
}

# 主同步函数
sync_content() {
    log "Starting content synchronization..."
    
    # 验证源目录
    [[ -d "$SOURCE_DIR" ]] || die "Source directory not found: $SOURCE_DIR"
    
    # 创建内容目录
    mkdir -p "$CONTENT_DIR"
    
    # 清理旧的生成内容（保留手动文件）
    find "$CONTENT_DIR" -name "20*" -type d -exec rm -rf {} + 2>/dev/null || true
    rm -f "${CONTENT_DIR}/_index.md"
    
    # 遍历年份目录
    local total_months=0
    for year_dir in "$SOURCE_DIR"/*/; do
        [[ -d "$year_dir" ]] || continue
        
        local year
        year="$(basename "$year_dir")"
        [[ "$year" =~ ^20[0-9]{2}$ ]] || {
            log "WARN: Skipping invalid year directory: $year"
            continue
        }
        
        # 遍历月份目录
        for month_dir in "$year_dir"/*/; do
            [[ -d "$month_dir" ]] || continue
            
            local month
            month="$(basename "$month_dir")"
            [[ "$month" =~ ^(0[1-9]|1[0-2])$ ]] || {
                log "WARN: Skipping invalid month directory: $month"
                continue
            }
            
            process_month "$month_dir" "$year" "$month"
            # 修复：使用安全的递增方式，避免在set -e模式下退出
            total_months=$((total_months + 1))
        done
    done
    
    log "Processed $total_months months"
    
    # 生成首页
    generate_home_page
    
    # 显示同步结果
    local total_files
    total_files=$(find "$CONTENT_DIR" -name "*.md" -type f 2>/dev/null | wc -l)
    log "Synchronization complete: $total_files files generated"
    
    # 列出生成的文件（限制输出）
    if [[ $total_files -gt 0 ]]; then
        log "Generated files:"
        find "$CONTENT_DIR" -name "*.md" -type f | sort | head -10
        if [[ $total_files -gt 10 ]]; then
            log "... and $((total_files - 10)) more files"
        fi
    fi
}

# =============================================================================
# 主程序入口
# =============================================================================

main() {
    log "AI News Content Sync v2.3"
    log "Project root: $PROJECT_ROOT"
    log "Source directory: $SOURCE_DIR"
    log "Content directory: $CONTENT_DIR"
    
    sync_content
    
    log "Sync process completed successfully"
}

# 执行主程序
main "$@"