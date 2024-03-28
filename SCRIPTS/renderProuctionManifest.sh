#!/bin/bash

export PROJ=proj1
export APP=app1

export PROJ=proj1
export APP=app1

export TEMP_DIR=/tmp/RENREDER

export SOURCE_GIT_REPO=https://github.com/danielmarom78/cd-repo-demo.git
export SOURCE_GIT_BRANCH=main
export SOURCE_GIT_BASE_PATH=Application/
export SOURCE_TEMP_DIR=$TEMP_DIR/SOURCE
export SOURCE_PATH=$PROJ/$APP/prod
export SOURCE_YAML_SERVICE_NAME_PATH=global.serviceName
export SOURCE_YAML_APP_NAME_PATH=global.nameOverride
export SOURCE_YAML_NAMESPACE=global.namespace



export TARGET_GIT_REPO=https://github.com/danielmarom78/cd-repo-demo.git
export TARGET_GIT_BRANCH=Production
export TARGET_GIT_BASE_PATH= 
export TARGET_TEMP_DIR=$TEMP_DIR/TARGET
export TARGET_GIT_PATH=$TARGET_GIT_BASE_PATH$PROJ/$APP

export RENDERED_TEMP_DIR=$TEMP_DIR/RENDERED

rm -rf $TEMP_DIR

#Checking out source
mkdir -p $SOURCE_TEMP_DIR
cd $SOURCE_TEMP_DIR
git init
git remote add origin $SOURCE_GIT_REPO
git checkout -b $TARGET_GIT_BRANCH
git config core.sparseCheckout true
echo $SOURCE_GIT_BASE_PATH >> .git/info/sparse-checkout
git pull origin $SOURCE_GIT_BRANCH
cd ../

#Checking out target
mkdir -p $TARGET_TEMP_DIR
cd $TARGET_TEMP_DIR
git init
git remote add origin $TARGET_GIT_REPO
git checkout -b $TARGET_GIT_BRANCH
git config core.sparseCheckout true
echo $TARGET_GIT_PATH >> .git/info/sparse-checkout
git pull origin $TARGET_GIT_BRANCH
cd ../


#Rendering
rm -rf $TARGET_TEMP_DIR/$TARGET_GIT_PATH/*
cd $SOURCE_TEMP_DIR/$SOURCE_GIT_BASE_PATH
helm dependency build $SOURCE_TEMP_DIR/$SOURCE_GIT_BASE_PATH
for VAL_FILE in $(find "$SOURCE_PATH" -type f); do

    export APP_NAME=$PROJ-$APP
    export SRV_NAME=$(yq e .$SOURCE_YAML_SERVICE_NAME_PATH "$VAL_FILE")
    export RENDER_FULL_PATH=$RENDERED_TEMP_DIR/$SRV_NAME
    export TERGET_FULL_PATH=$TARGET_TEMP_DIR/$TARGET_GIT_PATH/$SRV_NAME

    mkdir -p $RENDER_FULL_PATH

    helm template . -f "$VAL_FILE" --set "$SOURCE_YAML_SERVICE_NAME_PATH=$SRV_NAME","$SOURCE_YAML_APP_NAME_PATH=$APP_NAME,$SOURCE_YAML_NAMESPACE=prod" --output-dir $RENDER_FULL_PATH

    rm -rf $TERGET_FULL_PATH
    mkdir -p $TERGET_FULL_PATH
    cp $RENDER_FULL_PATH/proxy-chart/charts/application/templates/* $TERGET_FULL_PATH
  done

#Commiting target
cd $TARGET_TEMP_DIR
git add .
git commit -m "commit by pipline for app=$APP project=$PROJ"
git push --set-upstream origin $TARGET_GIT_BRANCH