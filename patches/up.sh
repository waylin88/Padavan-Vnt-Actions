#!/bin/sh

# 定义变量
LOCAL_FILE=$1
REMOTE_USER="root"
REMOTE_HOST="103.236.64.164"
CONFIG_FILE="/opt/rt-n56u/trunk/user/vntc/start"
token=$(sed -n 's/^token: //p' "$CONFIG_FILE")
REMOTE_PATH="/www/wwwroot/vnt_http/firmware/$token/"

# 检查远程目录是否存在，如果不存在则创建
ssh "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $REMOTE_PATH"

# 登录远程服务器并上传文件
scp "$LOCAL_FILE" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH"

# 检查上传是否成功
if [ $? -eq 0 ]; then
    echo "组网Token:"$token
    echo "文件上传成功！"
else
    echo "文件上传失败。"
fi
