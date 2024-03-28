#!/bin/bash

export PROJ=proj1
export APP=app1

export PROJ=proj1
export APP=app1

export SOURCE_GIT_REPO=https://github.com/danielmarom78/cd-repo-demo.git
export SOURCE_GIT_BRANCH=main
export SOURCE_GIT_BASE_PATH=Application/
export SOURCE_TEMP_DIR=/tmp/render/source
export SOURCE_GIT_PATH=$SOURCE_GIT_BASE_PATH$PROJ/$APP/prod


export TARGET_GIT_REPO=https://github.com/danielmarom78/cd-repo-demo.git
export TARGET_GIT_BRANCH=Production
export TARGET_GIT_BASE_PATH= 
export TARGET_TEMP_DIR=/tmp/render/target
export TARGET_GIT_PATH=$TARGET_GIT_BASE_PATH$PROJ/$APP


rm -rf $SOURCE_TEMP_DIR
mkdir -p $SOURCE_TEMP_DIR
cd $SOURCE_TEMP_DIR
git init
git remote add origin $SOURCE_GIT_REPO
git config core.sparseCheckout true
echo $SOURCE_GIT_BASE_PATH >> .git/info/sparse-checkout
git pull origin $SOURCE_GIT_BRANCH


rm -rf $TARGET_TEMP_DIR
mkdir -p $TARGET_TEMP_DIR
cd $TARGET_TEMP_DIR
git init
git remote add origin $TARGET_GIT_REPO
git config core.sparseCheckout true
echo $TARGET_GIT_PATH >> .git/info/sparse-checkout
git pull origin $TARGET_GIT_BRANCH