#!/bin/bash

export PROJ=proj2
export APP=app2

export TEMP_DIR=/tmp/RENREDER

export RENDERED_TEMP_DIR=$TEMP_DIR/RENDERED

export SOURCE_GIT_REPO=https://github.com/danielmarom78/cd-repo-demo.git
export SOURCE_GIT_BRANCH=main
export SOURCE_TEMP_DIR=$TEMP_DIR/SOURCE
export SOURCE_CHART_PATH=$SOURCE_TEMP_DIR/Application/
export SOURCE_VALUES_FILES_PATH=$SOURCE_TEMP_DIR/Application/$PROJ/$APP/prod

export TARGET_GIT_REPO=https://github.com/danielmarom78/cd-repo-demo.git
export TARGET_GIT_BRANCH=Production
export TARGET_TEMP_DIR=$TEMP_DIR/TARGET
export TARGET_ARTIFACT_PATH=$TARGET_TEMP_DIR/$PROJ/$APP

export YAML_PATH_SERVICE_NAME=global.serviceName
export YAML_PATH_APP_NAME=global.nameOverride
export YAML_PATH_NAMESPACE=global.namespace



set -e

rm -rf $TEMP_DIR

#Clone source
mkdir -p $SOURCE_TEMP_DIR || exit
git clone -b $SOURCE_GIT_BRANCH $SOURCE_GIT_REPO $SOURCE_TEMP_DIR

#Clone target
mkdir -p $TARGET_TEMP_DIR || exit
git clone -b $TARGET_GIT_BRANCH $TARGET_GIT_REPO $TARGET_TEMP_DIR

#Rendering
rm -rf $TARGET_ARTIFACT_PATH
mkdir -p $TARGET_ARTIFACT_PATH || exit

helm dependency build $SOURCE_CHART_PATH
for VAL_FILE in $(find "$SOURCE_VALUES_FILES_PATH" -type f); do

    export APP_NAME=$PROJ-$APP
    export SRV_NAME=$(yq e .$YAML_PATH_SERVICE_NAME "$VAL_FILE")
    export RENDER_FULL_PATH=$RENDERED_TEMP_DIR/$SRV_NAME
    export TERGET_FULL_PATH=$TARGET_TEMP_DIR/$TARGET_ARTIFACT_PATH/$SRV_NAME

    mkdir -p $RENDER_FULL_PATH
    helm template $SOURCE_CHART_PATH -f "$VAL_FILE" --set "$YAML_PATH_NAMESPACE=$SRV_NAME","$YAML_PATH_APP_NAME=$APP_NAME,$YAML_PATH_NAMESPACE=prod" --output-dir $RENDER_FULL_PATH

    rm -rf $TARGET_ARTIFACT_PATH
    mkdir -p $TARGET_ARTIFACT_PATH
    cp $RENDER_FULL_PATH/proxy-chart/charts/application/templates/* $TARGET_ARTIFACT_PATH
  done

#Commiting target
cd $TARGET_TEMP_DIR
git add .
git commit -m "commit by pipline for app=$APP project=$PROJ"
git push