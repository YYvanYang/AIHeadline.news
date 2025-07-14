---
title: "{{YEAR}}-{{MONTH}}"
weight: {{WEIGHT}}
breadcrumbs: false
sidebar:
  open: true
---

<div class="newspaper-month-header border-b-4 border-double border-gray-900 dark:border-gray-100 pb-6 mb-8">
  <div class="text-center">
    <h1 class="text-4xl md:text-5xl font-bold font-serif mb-2 text-gray-900 dark:text-gray-100">
      {{YEAR}}年{{MONTH}}月
    </h1>
    <div class="text-lg md:text-xl text-gray-600 dark:text-gray-400 italic mb-4">
      AI DAILY BRIEFING ARCHIVE
    </div>
    <div class="text-gray-600 dark:text-gray-400">
      本月收录 AI 行业重要动态，按日期归档整理
    </div>
  </div>
</div>

<div class="newspaper-daily-list hx-mt-12">
  <h2 class="text-2xl font-bold mb-6 font-serif flex items-center">
    <span class="mr-3">📰</span>
    本月日报
    <span class="ml-auto text-sm font-normal text-gray-500">
      Daily AI Briefings
    </span>
  </h2>
  
  <div class="newspaper-articles-grid">
    {{CONTENT}}
  </div>
</div>

<style>
/* 模板特定样式 - 主要样式在 custom.css 中定义 */

/* 添加期刊样式的编号 */
.newspaper-articles-grid > div {
  counter-increment: article-counter;
}

.newspaper-articles-grid::before {
  counter-reset: article-counter;
  content: "";
}

.newspaper-articles-grid > div::after {
  content: "第 " counter(article-counter) " 期";
  @apply absolute right-4 top-4 text-xs text-gray-400 dark:text-gray-500 font-mono;
  background: rgba(255, 255, 255, 0.8);
  padding: 2px 6px;
  border-radius: 3px;
  border: 1px solid rgba(0, 0, 0, 0.1);
}

.dark .newspaper-articles-grid > div::after {
  background: rgba(0, 0, 0, 0.6);
  border-color: rgba(255, 255, 255, 0.1);
}

/* 分隔线效果 */
.newspaper-articles-grid > div:not(:last-child) {
  border-bottom: 1px dashed rgba(0, 0, 0, 0.1);
  padding-bottom: 1rem;
  margin-bottom: 1rem;
}

.dark .newspaper-articles-grid > div:not(:last-child) {
  border-bottom-color: rgba(255, 255, 255, 0.1);
}

/* 响应式调整 */
@media (max-width: 768px) {
  .newspaper-month-header h1 {
    @apply text-3xl;
  }
  
  .newspaper-articles-grid > div {
    @apply pl-4;
  }
  
  .newspaper-articles-grid > div:hover {
    @apply pl-6;
    transform: translateX(2px);
  }
  
  .newspaper-articles-grid a {
    @apply text-base;
  }
}

/* 加载动画 */
.newspaper-articles-grid > div {
  opacity: 0;
  animation: fadeInUp 0.6s ease forwards;
}

.newspaper-articles-grid > div:nth-child(1) { animation-delay: 0.1s; }
.newspaper-articles-grid > div:nth-child(2) { animation-delay: 0.2s; }
.newspaper-articles-grid > div:nth-child(3) { animation-delay: 0.3s; }
.newspaper-articles-grid > div:nth-child(4) { animation-delay: 0.4s; }
.newspaper-articles-grid > div:nth-child(5) { animation-delay: 0.5s; }

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
