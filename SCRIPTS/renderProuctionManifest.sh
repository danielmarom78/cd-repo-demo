#!/bin/bash

export PROJ=proj1
export APP=app1

export PROJ=proj1
export APP=app1

export TEMP_DIR=tmp/RENREDER

export SOURCE_GIT_REPO=https://github.com/danielmarom78/cd-repo-demo.git
export SOURCE_GIT_BRANCH=main
export SOURCE_GIT_BASE_PATH=Application/
export SOURCE_TEMP_DIR=$TEMP_DIR/source
export SOURCE_PATH=$PROJ/$APP/prod
export SOURCE_YAML_SERVICE_NAME_PATH=.global.serviceName
export SOURCE_YAML_APP_NAME_PATH=.global.nameOverride

export TARGET_GIT_REPO=https://github.com/danielmarom78/cd-repo-demo.git
export TARGET_GIT_BRANCH=Production
export TARGET_GIT_BASE_PATH= 
export TARGET_TEMP_DIR=$TEMP_DIR/target
export TARGET_GIT_PATH=$TARGET_GIT_BASE_PATH$PROJ/$APP

export RENDERED_TEMP_DIR=$TEMP_DIR/rendered


#Checking out source
rm -rf $SOURCE_TEMP_DIR
mkdir -p $SOURCE_TEMP_DIR
cd $SOURCE_TEMP_DIR
git init
git remote add origin $SOURCE_GIT_REPO
git config core.sparseCheckout true
echo $SOURCE_GIT_BASE_PATH >> .git/info/sparse-checkout
git pull origin $SOURCE_GIT_BRANCH


cd $SOURCE_GIT_BASE_PATH
helm dependency build


#Rendering
rm -rf $RENDERED_TEMP_DIR

for VAL_FILE in $(find "$SOURCE_PATH" -type f); do

    echo $VAL_FILE

    export APP_NAME=$PROJ-$APP
    export SERV_NAME=$(yq e $SOURCE_YAML_SERVICE_NAME_PATH "$VAL_FILE")
    export RENDER_FULL_PATH=$RENDERED_TEMP_DIR/$SERV_NAME
  
    echo $APP_NAME
    echo $SERV_NAME


    mkdir -p $RENDER_FULL_PATH

    helm template . -f "$VAL_FILE" --set "$SOURCE_YAML_SERVICE_NAME_PATH=$SERV_NAME" | awk '/^---$/{filename=sprintf("%s/k8s-object-%05d.yaml", dir, ++count); next} {print > filename}' dir="$RENDER_FULL_PATH" count=0
  done




# #Checking out target
# rm -rf $TARGET_TEMP_DIR
# mkdir -p $TARGET_TEMP_DIR
# cd $TARGET_TEMP_DIR
# git init
# git remote add origin $TARGET_GIT_REPO
# git config core.sparseCheckout true
# echo $TARGET_GIT_PATH >> .git/info/sparse-checkout
# git pull origin $TARGET_GIT_BRANCH