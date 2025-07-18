# 🛠️ AI News Hugo 部署指南 - Cloudflare Workers + GitHub Pages

> 目标：**aiheadline.news**
>
> * 生产：Cloudflare Worker (Assets 模式)
> * 备份：GitHub Pages
> * 统计：GA4 累计访问量 + 实时在线人数（/stats API，使用自签名 JWT）
> * 单一 GitHub Actions 工作流

---

## 架构总览

```mermaid
graph LR
  A[git push / cron] --> B[build<br>Hugo → public/]
  B --> C[upload artifact]
  C --> D[deploy-gh-pages]
  C --> E[deploy-cf-worker<br>wrangler deploy]
  D --> F[(GitHub Pages<br>镜像)]
  E --> G[(Cloudflare Worker + Assets<br>aiheadline.news)]
```

---

## 1. Cloudflare 配置

### 1.1 创建 Worker
1. 登录 [Cloudflare Dashboard][cf-dashboard]
2. 进入 **Workers & Pages**
3. 点击 **Create** → **Workers** → **Create Worker**
4. 命名为 `aiheadline-news`
5. 点击 **Deploy**（空脚本即可）

### 1.2 配置域名路由
1. 在 Worker 页面，点击 **Settings** → **Triggers**
2. 点击 **Add Custom Domain**
3. 输入 `aiheadline.news`
4. 点击 **Add Custom Domain**

### 1.3 创建 API Token
1. 点击右上角头像 → **My Profile**
2. 选择 **API Tokens** 标签
3. 点击 **Create Token**
4. 使用 **Custom token** 模板
5. 设置权限：
   - **Account** → Workers Scripts: Edit
   - **Zone** → 选择你的域名 → Zone: Read
6. 点击 **Continue to summary** → **Create Token**
7. 复制生成的 Token

### 1.4 获取 Account ID
1. 返回 Cloudflare Dashboard 首页
2. 右侧边栏可以看到 **Account ID**
3. 复制这个 ID

---

## 2. 代码结构

```
/_worker.ts           # Worker 脚本（包含 JWT 自签名实现）
wrangler.jsonc        # Assets 绑定配置（推荐格式）
layouts/partials/custom/footer.html   # 包含统计显示
hugo.yaml             # GA4 Measurement ID, baseURL
.github/workflows/deploy.yml     # CI/CD 工作流
assets/css/custom.css            # 自定义样式
```

### 2.1 `wrangler.jsonc`

```json
{
  "name": "aiheadline-news",
  "main": "_worker.ts",
  "compatibility_date": "2025-07-13",
  "assets": {
    "directory": "./public",
    "binding": "ASSETS",
    "html_handling": "auto-trailing-slash",
    "not_found_handling": "404-page"
  },
  "observability": {
    "enabled": true,                      // 启用日志
    "head_sampling_rate": 1.0            // 记录所有请求（可调整为 0-1 之间的值）
  },
  "vars": {
    "GA4_PROPERTY_ID": "496539516",      // GA4 属性 ID（不需要在 Dashboard 中配置）
    "GA_START_DATE": "2025-07-12"        // 统计开始日期（站点上线日）
  }
}
```

**重要说明**：
- 使用 `wrangler.jsonc` 格式（Cloudflare 推荐）
- 项目采用 Web 标准 API 设计，无需 `nodejs_compat` 兼容性标志
- Worker 使用 WebCrypto API 自签名 JWT，无需外部 SDK（参考 [WebCrypto API 文档][cf-webcrypto]）
- 基于 Web 标准实现，bundle 更轻量，性能更优

### 2.2 Worker 实现技术说明

**JWT 自签名流程**：
1. 使用 Service Account 的私钥通过 WebCrypto API 生成 JWT
2. 用 JWT 向 Google OAuth2 端点交换 Access Token
3. 使用 Access Token 调用 GA4 Data API

**相关技术文档**：
- [Service Account JWT 认证][google-jwt] - 了解 JWT 结构和认证流程
- [GA4 Data API REST][ga4-api] - API 端点和请求格式
- [Workers WebCrypto][cf-webcrypto] - RSA 签名实现

### 2.3 GitHub Actions 配置

**重要更新（2025年1月）**：
- 所有 GitHub Actions 必须升级到 v4 版本
- Cloudflare Worker 部署采用独立构建方案

完整的 `deploy.yml` 工作流结构：

```yaml
jobs:
  # 1. 构建任务 - 为 GitHub Pages 准备
  build:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4              # 必须使用 v4
      - uses: actions/configure-pages@v5       # 最新版本
      - uses: actions/upload-pages-artifact@v3 # Pages 专用，保持 v3

  # 2. GitHub Pages 部署
  deploy-gh-pages:
    needs: build
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/deploy-pages@v4          # 必须使用 v4

  # 3. Cloudflare Worker 部署 - 独立构建
  deploy-cf-worker:
    runs-on: ubuntu-24.04
    if: github.ref == 'refs/heads/main'
    steps:
      # 重新构建站点
      - uses: actions/checkout@v4
      - name: Build with Hugo
        run: hugo --gc --minify
      
      # 部署到 Cloudflare
      - uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CF_API_TOKEN }}
          accountId: ${{ secrets.CF_ACCOUNT_ID }}
        env:
          CLOUDFLARE_API_TOKEN: ${{ secrets.CF_API_TOKEN }}
          CLOUDFLARE_ACCOUNT_ID: ${{ secrets.CF_ACCOUNT_ID }}
```

---

## 3. GitHub Secrets 配置

### 3.1 在 GitHub 配置 Secrets
1. 进入仓库：https://github.com/YYvanYang/AIHeadline.news
2. 点击 **Settings** → **Secrets and variables** → **Actions**
3. 点击 **New repository secret**
4. 依次添加以下 secrets：

| Secret                  | 说明                    | 获取方式 |
| ----------------------- | --------------------- | ------- |
| `CF_API_TOKEN`          | Cloudflare API Token  | 见 1.3 节 |
| `CF_ACCOUNT_ID`         | Cloudflare Account ID | 见 1.4 节 |
| `PERSONAL_ACCESS_TOKEN` | GitHub PAT（已有） | 用于访问私有 vault 仓库 |

### 3.2 Cloudflare Worker 环境变量

**重要说明**：
- `GA4_PROPERTY_ID` 已在 `wrangler.jsonc` 中配置为普通变量，无需在 Dashboard 中配置
- `GA4_SERVICE_KEY` 是敏感信息，必须通过 Dashboard 或 CLI 单独配置为加密变量

#### 配置 GA4_SERVICE_KEY Secret

**方法一：通过 Cloudflare Dashboard**
1. 进入 Worker 页面，**Settings** → **Variables**
2. 点击 **Add variable**
3. 配置以下内容：
   - 变量名：`GA4_SERVICE_KEY`
   - 类型：**Encrypt**（必须加密）
   - 值：完整的 Google Service Account JSON 内容

**方法二：通过 Wrangler CLI**
```bash
# 在项目根目录执行
wrangler secret put GA4_SERVICE_KEY
# 然后粘贴完整的 Service Account JSON
```

**Service Account JSON 格式示例**（详见 [Service Account 认证文档][google-jwt]）：
```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "...",
  "client_id": "...",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "...",
  "client_x509_cert_url": "..."
}
```

**注意事项**：
- Secret 只需配置一次，后续部署会自动保留
- 每次通过 Actions 部署不会覆盖已配置的 secrets
- 本地开发使用 `.dev.vars` 文件（参考 `.dev.vars.example`）

---

## 4. 验收步骤

1. **本地测试**
   ```bash
   # 首次设置：复制并配置本地环境变量
   cp .dev.vars.example .dev.vars
   # 编辑 .dev.vars 文件，填入实际的 GA4_SERVICE_KEY
   
   # 构建和测试
   hugo --gc --minify
   wrangler dev --assets ./public
   # 浏览 http://127.0.0.1:8787/
   ```

2. **推送验证**
   ```bash
   git push main
   ```
   Actions 完成后检查：
   - https://aiheadline.news 返回 Hugo 站点
   - 首页显示 PV / 在线人数
   - GA4 Realtime 面板可看到活跃用户

---

## 5. 关键文档

| 内容 | 链接 |
| ---- | ---- |
| Workers Static Assets | [官方文档][cf-static-assets] |
| Assets Binding | [配置指南][cf-assets-binding] |
| GA4 Data API | [实时数据 API][ga4-realtime] |
| Service Account JWT | [JWT 认证文档][google-jwt] |
| Workers WebCrypto | [WebCrypto API][cf-webcrypto] |
| Hugo 文档 | [快速开始][hugo-quickstart] |

---

## 6. 手动触发部署

如需手动触发部署：

1. 进入仓库的 **Actions** 页面
2. 选择 `Deploy AI News to GitHub Pages` 工作流
3. 点击 **Run workflow** 按钮
4. 选择 `main` 分支并运行

---

## 7. 故障排查

### 部署失败

1. **检查 Actions 日志**：
   - 查看具体错误信息
   - 特别注意 "Sync markdown files" 步骤

2. **常见错误**：
   - `set -euo pipefail` 相关错误：检查脚本中的管道命令
   - 权限错误：确认 `PERSONAL_ACCESS_TOKEN` 配置正确
   - Hugo 构建错误：检查模板语法和内容格式
   - Cloudflare 部署错误：
     - **"CLOUDFLARE_API_TOKEN environment variable" 错误**：检查 secrets 配置
     - **"Could not resolve" 错误**：检查网络连接和 API 端点
     - **"public directory does not exist" 错误**：使用独立构建方案

### Stats API 返回 500 错误

1. **检查错误日志**：
   - Cloudflare Dashboard → Workers → Logs
   - 查看具体错误信息（现在是结构化 JSON 日志）

2. **常见原因**：
   - **"Missing required environment variables"**：
     - 检查 `GA4_SERVICE_KEY` 是否已通过 Dashboard/CLI 配置
     - 确认 `wrangler.jsonc` 中有 `GA4_PROPERTY_ID` 和 `GA_START_DATE` 配置
   - **JWT 签名错误**：检查 Service Account JSON 格式（参考 [JWT 认证文档][google-jwt]）
   - **API 权限错误**：确认 Service Account 有 GA4 只读权限（参考 [GA4 Data API 文档][ga4-api]）
   - **配额耗尽（429 错误）**：
     - 检查响应头 `X-GA-Quota-Warning`
     - 查看日志中的 `tokensRemaining` 字段
     - 系统会自动延长缓存时间以减少 API 调用

### 内容未更新

1. **验证源数据**：
   - 确认源仓库有 `.md` 文件（不处理 HTML/PDF）
   - 检查文件命名格式是否正确
   - 确认文件在正确的年月目录下

2. **查看同步日志**：
   - Actions 中查看 "Sync markdown files" 输出
   - 确认找到并处理了预期的文件

### 页面 404 错误

1. 确认部署已完成
2. 检查 URL 是否正确（注意大小写）
3. 对于 Cloudflare Workers，检查路由配置
4. 对于 GitHub Pages，确认 `gh-pages` 分支存在

### 调试技巧

1. **本地测试同步**：
   ```bash
   # 使用 test-sync.sh 脚本测试内容同步
   ./.github/scripts/test-sync.sh
   ```

2. **本地预览**：
   ```bash
   hugo server
   # 访问 http://localhost:1313 查看效果
   ```

3. **测试 Worker**：
   ```bash
   wrangler dev --assets ./public
   # 访问 http://127.0.0.1:8787 测试 Worker
   ```

---

## 注意事项

1. **CSS 文件位置**：必须放在 `assets/css/` 目录，不是 `static/css/`
2. **页脚自定义**：使用 `layouts/partials/custom/footer.html`，并在 `hugo.yaml` 中禁用默认页脚
3. **内容管理**：永远不要手动编辑 `content/` 目录下的文件
4. **本地开发**：使用 `.github/scripts/test-sync.sh` 同步最新内容
5. **域名配置**：Cloudflare Workers 通过路由绑定域名，无需 CNAME 文件
6. **Wrangler 版本**：项目使用 Wrangler v4，确保 `package.json` 中版本正确
7. **Actions 版本**：2025 年 1 月 30 日后必须使用 v4 版本

---

## 更新日志

### 2025-07-18 代码质量优化
1. **Google Analytics API 优化**：
   - 修复 Realtime API 响应处理（只使用 rows，不使用 totals）
   - 添加配额监控（returnPropertyQuota: true）
   - 实现动态缓存策略（根据配额自动调整缓存时间）
   - 增强错误处理（QuotaExceededError 类）
   - 添加结构化日志和性能监控

2. **代码健壮性提升**：
   - 修复请求去重内存泄漏风险（添加时间戳和定期清理）
   - 添加请求超时控制（GA4 API 30秒，Token 交换 15秒）
   - 修复网络错误无限重试问题
   - 改进 GA4 响应验证（validateGA4Response）
   - 修复大型 ArrayBuffer 转换（分块处理避免栈溢出）

3. **TypeScript 最佳实践**：
   - 使用泛型替代 any（LogContext<T>）
   - 完善类型定义和类型守卫
   - 添加响应结构验证

### 2025-07-13 重要更新
1. **GitHub Actions 升级**：
   - 所有 actions 升级到 v4/v5 版本
   - Cloudflare Worker 部署改为独立构建方案
   - 修复了 artifact 解压和 public 目录问题

2. **Wrangler 配置**：
   - 从 `wrangler.toml` 迁移到 `wrangler.jsonc`
   - 添加 `nodejs_compat` 兼容性标志（可选）
   - 升级到 Wrangler v4.24.3

3. **Worker 实现优化**：
   - 使用 WebCrypto API 实现 JWT 自签名（[WebCrypto 文档][cf-webcrypto]）
   - 移除对 @google-analytics/data 包的依赖
   - 实现 Access Token 缓存机制
   - 改进 CORS 和错误处理
   - 完整实现参考：[Service Account JWT][google-jwt] 和 [GA4 API][ga4-api]

4. **认证修复**：
   - wrangler-action 需要同时在 `with` 和 `env` 中设置认证信息
   - 添加了详细的 Token 创建步骤

---

完整实施详情请参考项目中的各配置文件。

<!-- 链接引用定义 -->
[cf-dashboard]: https://dash.cloudflare.com/
[cf-webcrypto]: https://developers.cloudflare.com/workers/runtime-apis/web-crypto/
[cf-static-assets]: https://developers.cloudflare.com/workers/learning/how-the-cache-works/static-sites/
[cf-assets-binding]: https://developers.cloudflare.com/workers/configuration/variables/#assets
[google-jwt]: https://developers.google.com/identity/protocols/oauth2/service-account
[ga4-api]: https://developers.google.com/analytics/devguides/reporting/data/v1/rest
[ga4-realtime]: https://developers.google.com/analytics/devguides/reporting/data/v1/realtime-basics
[hugo-quickstart]: https://gohugo.io/getting-started/quick-start/