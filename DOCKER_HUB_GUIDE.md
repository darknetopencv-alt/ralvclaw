# Docker Hub 推送指南

## 方法一：本地构建推送（需要 Docker 环境）

### 1. 登录 Docker Hub

```bash
docker login -u your-dockerhub-username
# 输入密码或访问令牌
```

### 2. 构建镜像

```bash
cd /workspace/projects/ralvclaw

# 构建镜像
docker build -t ralvclaw:latest .

# 查看构建好的镜像
docker images | grep ralvclaw
```

### 3. 标记镜像

```bash
# 格式：docker.io/username/ralvclaw:tag
docker tag ralvclaw:latest docker.io/your-username/ralvclaw:latest
docker tag ralvclaw:latest docker.io/your-username/ralvclaw:v1.0.0
```

### 4. 推送到 Docker Hub

```bash
# 推送 latest 标签
docker push docker.io/your-username/ralvclaw:latest

# 推送版本标签
docker push docker.io/your-username/ralvclaw:v1.0.0
```

### 5. 验证推送

```bash
# 拉取测试
docker pull your-username/ralvclaw:latest

# 运行测试
docker run -d --name ralvclaw-test -p 18789:18789 your-username/ralvclaw:latest
```

---

## 方法二：GitHub Actions 自动推送（推荐）

已配置 `.github/workflows/docker-build.yml`，支持自动构建和推送。

### 配置步骤

1. **Fork 或上传代码到 GitHub 仓库**

2. **配置 Docker Hub 密钥**

   在 GitHub 仓库 → Settings → Secrets and variables → Actions → New repository secret

   添加以下 secrets：
   - `DOCKERHUB_USERNAME`: 你的 Docker Hub 用户名
   - `DOCKERHUB_TOKEN`: Docker Hub 访问令牌（从 Docker Hub → Account Settings → Security → New Access Token 获取）

3. **触发构建**

   - 推送到 `main` 分支：自动构建并推送 `latest` 标签
   - 推送标签 `v*`: 自动构建并推送版本标签
   - 手动触发：Actions → Build and Push Docker Image → Run workflow

### 构建平台

GitHub Actions 工作流支持多平台构建：
- `linux/amd64` (x86_64)
- `linux/arm64` (ARM64，如 Apple Silicon、ARM 服务器)

---

## Docker Hub 使用镜像

推送成功后，任何人都可以使用你的镜像：

```bash
# 拉取镜像
docker pull your-username/ralvclaw:latest

# 运行容器
docker run -d --name ralvclaw \
  -p 18789:18789 \
  -v ~/.openclaw:/root/.openclaw \
  your-username/ralvclaw:latest
```

---

## 镜像标签策略

| 标签 | 说明 |
|------|------|
| `latest` | 最新版本（主分支最新提交） |
| `v1.0.0` | 特定版本 |
| `v1.0` | 次要版本 |

---

## 常见问题

### Q: Docker Hub 访问令牌如何获取？

1. 登录 https://hub.docker.com
2. 点击右上角头像 → Account Settings
3. 选择 Security → New Access Token
4. 输入描述，选择权限（Read/Write），生成令牌
5. **复制并保存令牌**（只显示一次）

### Q: 构建失败怎么办？

1. 检查 Docker 是否运行：`docker info`
2. 检查网络连接（需要访问 GitHub 克隆源码）
3. 查看构建日志：`docker build --progress=plain -t ralvclaw:latest .`

### Q: 推送被拒绝？

1. 检查是否登录：`docker login`
2. 检查用户名和令牌是否正确
3. 检查镜像标签格式：`docker.io/username/ralvclaw:tag`
