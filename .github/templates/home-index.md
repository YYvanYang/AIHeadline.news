---
title: AI每日简报 - 您的人工智能情报站
linkTitle: AI每日简报
breadcrumbs: false
description: "每日精选AI行业要闻、开源热点、学术前沿及大V观点。AI资讯；AI日报；AI知识库；AI教程；AI资讯日报；AI工具；AI Daily News"
cascade:
  type: docs
---

<div class="newspaper-masthead border-b-4 border-double border-gray-900 dark:border-gray-100 pb-8 mb-12">
  <div class="text-center">
    <h1 class="text-5xl md:text-6xl font-bold mb-4 font-serif text-gray-900 dark:text-gray-100">
      AI每日简报
    </h1>
    <div class="text-lg md:text-xl text-gray-600 dark:text-gray-400 italic mb-4">
      ARTIFICIAL INTELLIGENCE DAILY BRIEFING
    </div>
    <div class="max-w-4xl mx-auto">
      <div class="grid md:grid-cols-2 gap-4 text-sm text-gray-600 dark:text-gray-400">
        <div class="flex items-center justify-center">
          <span class="mr-2">🎯</span>
          精选全球AI突破性进展：大模型发布、技术突破、产业应用、投融资事件、学术前沿
        </div>
        <div class="flex items-center justify-center">
          <span class="mr-2">📊</span>
          智能聚类算法，相关事件自动归组，条理清晰
        </div>
        <div class="flex items-center justify-center">
          <span class="mr-2">⚡</span>
          每日定时更新，3分钟速览AI界大事
        </div>
        <div class="flex items-center justify-center">
          <span class="mr-2">🔗</span>
          原始链接+专业解读，信息可追溯
        </div>
      </div>
    </div>
  </div>
</div>

<div class="newspaper-archive hx-mt-12">
  <h2 class="text-3xl font-bold mb-8 text-center font-serif border-b-2 border-gray-900 dark:border-gray-100 pb-4">
    📅 历史日报档案
  </h2>
  
  <div class="newspaper-grid grid gap-6 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
    {{MONTH_CARDS}}
  </div>
</div>

<style>
/* 报纸风格卡片样式 */
.newspaper-grid > div {
  @apply border-2 border-gray-900 dark:border-gray-100 p-6 bg-white dark:bg-gray-900;
  box-shadow: 4px 4px 0 rgb(17 24 39);
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
}

.newspaper-grid > div:hover {
  transform: translate(-2px, -2px);
  box-shadow: 6px 6px 0 rgb(17 24 39);
}

.dark .newspaper-grid > div {
  box-shadow: 4px 4px 0 rgb(243 244 246);
}

.dark .newspaper-grid > div:hover {
  box-shadow: 6px 6px 0 rgb(243 244 246);
}

/* 卡片内容样式 */
.newspaper-grid h3 {
  @apply text-xl font-bold mb-3 font-serif text-gray-900 dark:text-gray-100;
}

.newspaper-grid a {
  @apply text-gray-900 dark:text-gray-100 no-underline;
  transition: color 0.2s ease;
}

.newspaper-grid a:hover {
  @apply text-blue-600 dark:text-blue-400;
}

.newspaper-grid p {
  @apply text-gray-600 dark:text-gray-400 text-sm leading-relaxed;
}

/* 添加报纸日期标记 */
.newspaper-grid > div::before {
  content: "📰";
  @apply absolute -top-2 -right-2 text-2xl;
}

/* 响应式调整 */
@media (max-width: 768px) {
  .newspaper-masthead h1 {
    @apply text-4xl;
  }
  
  .newspaper-masthead .grid {
    @apply grid-cols-1 gap-2;
  }
  
  .newspaper-grid {
    @apply grid-cols-1;
  }
}
</style>
