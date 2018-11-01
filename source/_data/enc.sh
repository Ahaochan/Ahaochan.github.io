#!/bin/bash
# next.yml配置文件加密
cd /opt/Ahaochan.github.io/source/_data/
travis encrypt-file next.yml

# next.yml配置文件解密
# before_install:
# - openssl aes-256-cbc -K $加密的key -iv $加密的iv -in source/_data/next.yml.enc -out source/_data/next.yml -d