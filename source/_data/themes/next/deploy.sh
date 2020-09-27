#!/bin/bash
set -e
BLOG_USERNAME="用户名"
BLOG_REPOSITORY="${BLOG_USERNAME}.github.io"
THEME_USERNAME="theme-next"
THEME_NAME="next"
THEME_REPOSITORY="hexo-theme-next"

function pull() {
    cd /opt/${BLOG_REPOSITORY} && git checkout source && git pull && cd -
}
function initInstaller() {
    if [[ -n "$(command -v apt-get)" ]]; then
      echo "检测到apt命令, 开始初始化依赖"
      apt-get update
      apt-get install nodejs git -y
      rm -rf /var/lib/apt/lists/*
    fi
    if [[ -n "$(command -v yum)" ]]; then
      echo "检测到yum命令, 开始初始化依赖";
      yum remove nodejs -y
      yum clean all
      rm -rf /var/cache/yum/*
      rm -f /etc/yum.repos.d/nodesource-el.repo
      curl -sL https://rpm.nodesource.com/setup_10.x | bash -
      yum install nodejs git -y
    fi
}
function initGithub() {
    if [ ! -d "/opt/${BLOG_REPOSITORY}" ]; then
      echo "initGithub: 初始化${BLOG_REPOSITORY}"
      git clone https://github.com/${BLOG_USERNAME}/${BLOG_REPOSITORY}.git /opt/${BLOG_REPOSITORY}
    fi
    echo "initGithub: 切换到source分支"
    pull;

    if [ ! -d "/opt/${BLOG_REPOSITORY}/themes/${THEME_NAME}" ]; then
      echo "initGithub: 初始化${THEME_NAME}"
      git clone https://github.com/${THEME_USERNAME}/${THEME_REPOSITORY}.git /opt/${BLOG_REPOSITORY}/themes/${THEME_NAME}
    fi

    if [[ $THEME_NAME == "next" ]]; then
      echo "initGithub: 初始化${THEME_NAME}"
      cd /opt/${BLOG_REPOSITORY}/themes/${THEME_NAME} && git checkout v7.8.0 && cd -
      git clone https://github.com/theme-next/theme-next-pdf /opt/${BLOG_REPOSITORY}/themes/next/source/lib/pdf
      git clone https://github.com/theme-next/theme-next-pace /opt/${BLOG_REPOSITORY}/themes/next/source/lib/pace
    fi;
}
function initNpm() {
    cd /opt/${BLOG_REPOSITORY}

    NODE_VERSION=$(node -v);
    if [[ ! $NODE_VERSION =~ "v10" ]]; then
      echo "node verdion: $NODE_VERSION, 请升级到 10.x 以上";
      return;
    fi;
    npm install
    npm install -g hexo-cli
    npm install hexo-renderer-kramed
    npm install hexo-asset-image
    npm install hexo-generator-searchdb
    npm install hexo-generator-feed
    # npm install hexo-related-popular-posts
    npm install hexo-symbols-count-time
    npm install hexo-generator-sitemap
    npm install hexo-generator-baidu-sitemap
    npm install hexo-deployer-git
    # npm install hexo-leancloud-counter-security
    npm install hexo-helper-live2d

    if [[ $THEME_NAME == "next" ]]; then
      npm install theme-next/next-util
    fi;

    echo "npm初始化完毕, 请执行[sh deploy.sh run]命令"
    cd -
}
function init() {
    initInstaller;
    initGithub;
    initNpm;

    echo "初始化完毕, 请执行[sh deploy.sh run]命令"
}
function run() {
    cd /opt/${BLOG_REPOSITORY}

    if [ -f "/tmp/hexo.pid" ]; then
      PID="$(cat /tmp/hexo.pid)"
      if [ -n "$PID" -a -e /proc/$PID ]; then
        echo "结束进程 ${PID}"
        kill -9 "${PID}"
      fi
    fi
    hexo clean --config source/_data/next.yml
    hexo g --config source/_data/next.yml
    nohup hexo s -p 80 --config source/_data/next.yml > /tmp/hexo.log 2>&1 &
    echo $! > /tmp/hexo.pid

    cd -
}

case "$1" in
    init) init;;
    update) pull;;
    run) run;;
    *) echo "Error: unexpected option $1...";;
esac