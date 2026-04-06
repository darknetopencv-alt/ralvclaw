#!/bin/bash
# RalvClaw Docker 镜像构建和推送脚本

set -e

# 配置
IMAGE_NAME="ralvclaw"
DOCKERHUB_USERNAME="${DOCKERHUB_USERNAME:-knetdar}"
VERSION="${VERSION:-latest}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}  RalvClaw Docker 构建脚本${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: Docker 未安装或未添加到 PATH${NC}"
    exit 1
fi

# 检查是否登录 Docker Hub
echo -e "${YELLOW}检查 Docker Hub 登录状态...${NC}"
if ! docker info 2>/dev/null | grep -q "Username"; then
    echo -e "${YELLOW}未登录 Docker Hub，尝试登录...${NC}"
    if [ -z "$DOCKERHUB_USERNAME" ]; then
        read -p "请输入 Docker Hub 用户名: " DOCKERHUB_USERNAME
    fi
    docker login -u "$DOCKERHUB_USERNAME"
else
    echo -e "${GREEN}已登录 Docker Hub${NC}"
fi

# 如果没有设置用户名，尝试从 docker info 获取
if [ -z "$DOCKERHUB_USERNAME" ]; then
    DOCKERHUB_USERNAME=$(docker info 2>/dev/null | grep "Username" | awk '{print $2}')
fi

if [ -z "$DOCKERHUB_USERNAME" ]; then
    echo -e "${RED}错误: 无法获取 Docker Hub 用户名${NC}"
    exit 1
fi

echo -e "${GREEN}Docker Hub 用户名: $DOCKERHUB_USERNAME${NC}"
echo ""

# 构建镜像
echo -e "${YELLOW}开始构建镜像: $IMAGE_NAME:$VERSION${NC}"
docker build -t $IMAGE_NAME:$VERSION .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}构建成功!${NC}"
else
    echo -e "${RED}构建失败!${NC}"
    exit 1
fi

echo ""

# 标记镜像
echo -e "${YELLOW}标记镜像...${NC}"
docker tag $IMAGE_NAME:$VERSION docker.io/$DOCKERHUB_USERNAME/$IMAGE_NAME:$VERSION
docker tag $IMAGE_NAME:$VERSION docker.io/$DOCKERHUB_USERNAME/$IMAGE_NAME:latest

echo -e "${GREEN}镜像标记:${NC}"
echo -e "  - docker.io/$DOCKERHUB_USERNAME/$IMAGE_NAME:$VERSION"
echo -e "  - docker.io/$DOCKERHUB_USERNAME/$IMAGE_NAME:latest"
echo ""

# 推送到 Docker Hub
read -p "是否推送到 Docker Hub? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}推送镜像到 Docker Hub...${NC}"
    docker push docker.io/$DOCKERHUB_USERNAME/$IMAGE_NAME:$VERSION
    docker push docker.io/$DOCKERHUB_USERNAME/$IMAGE_NAME:latest
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}================================${NC}"
        echo -e "${GREEN}  推送成功!${NC}"
        echo -e "${GREEN}================================${NC}"
        echo ""
        echo -e "拉取命令:"
        echo -e "  docker pull $DOCKERHUB_USERNAME/$IMAGE_NAME:latest"
        echo ""
        echo -e "运行命令:"
        echo -e "  docker run -d --name ralvclaw -p 18789:18789 $DOCKERHUB_USERNAME/$IMAGE_NAME:latest"
    else
        echo -e "${RED}推送失败!${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}跳过推送${NC}"
fi

echo ""
echo -e "${GREEN}完成!${NC}"
