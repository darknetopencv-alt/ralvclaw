# RalvClaw

基于 OpenClaw 的中文版个人 AI 助手镜像。

## 项目结构

```
ralvclaw/
├── cli/
│   ├── apply.mjs                 # 汉化应用脚本
│   └── utils/
│       └── i18n-engine.mjs       # 翻译引擎
├── translations/                 # 翻译数据
│   ├── cli/                      # CLI 界面翻译
│   ├── dashboard/                # Dashboard 翻译
│   ├── commands/                 # 命令翻译
│   ├── wizard/                   # 向导翻译
│   └── gateway/                  # 网关翻译
├── Dockerfile                    # 多阶段构建文件
└── package.json
```

## 构建镜像

```bash
# 构建镜像
docker build -t ralvclaw:latest .

# 运行容器
docker run -d --name ralvclaw \
  -p 18789:18789 \
  -v ~/.openclaw:/root/.openclaw \
  ralvclaw:latest

# 查看日志
docker logs -f ralvclaw
```

## 推送到 Docker Hub

### 快速构建推送

```bash
# 使用脚本一键构建推送
./build-and-push.sh

# 或手动操作
docker build -t ralvclaw:latest .
docker tag ralvclaw:latest docker.io/knetdar/ralvclaw:latest
docker push docker.io/knetdar/ralvclaw:latest
```

### GitHub Actions 自动推送

1. Fork 本仓库到 GitHub
2. 配置 Secrets: `DOCKERHUB_USERNAME` 和 `DOCKERHUB_TOKEN`
3. 推送到 main 分支自动构建并推送 `latest` 标签

详细说明见 [DOCKER_HUB_GUIDE.md](DOCKER_HUB_GUIDE.md)

## 从 Docker Hub 使用

```bash
# 拉取镜像
docker pull knetdar/ralvclaw:latest

# 运行
docker run -d --name ralvclaw \
  -p 18789:18789 \
  -v ~/.openclaw:/root/.openclaw \
  knetdar/ralvclaw:latest
```

## 翻译机制

翻译引擎基于**字符串替换**实现：

1. **翻译配置**：JSON 文件定义原文到译文的映射
2. **应用补丁**：遍历翻译配置，使用 `replaceAll` 替换目标文件中的原文
3. **构建流程**：多阶段 Dockerfile 先克隆源码、应用翻译、然后构建

### 添加新翻译

在 `translations/` 目录下创建 JSON 文件：

```json
{
  "file": "目标文件路径（相对于源码根目录）",
  "description": "翻译描述",
  "replacements": {
    "原文": "译文",
    "English text": "中文文本"
  }
}
```

## 上游源码

- OpenClaw: https://github.com/openclaw/openclaw.git

## License

MIT
