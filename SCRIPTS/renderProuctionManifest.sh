#!/bin/bash

export PROJ=proj2
export APP=app2

export TEMP_DIR=/tmp/RENREDER

export RENDERED_TEMP_DIR=$TEMP_DIR/RENDERED

export SOURCE_REPO=https://github.com/danielmarom78/cd-repo-demo.git
export SOURCE_BRANCH=main
export SOURCE_TEMP_DIR=$TEMP_DIR/SOURCE
export SOURCE_CHART_PATH=Application
export SOURCE_VALUES_FILES_PATH=Application/$PROJ/$APP/prod

export TARGET_REPO=https://github.com/danielmarom78/cd-repo-demo.git
export TARGET_BRANCH=Production
export TARGET_TEMP_DIR=$TEMP_DIR/TARGET
export TARGET_ARTIFACT_PATH=$TARGET_TEMP_DIR/$PROJ/$APP

export YAML_PATH_SERVICE_NAME=global.serviceName
export YAML_PATH_APP_NAME=global.nameOverride
export YAML_PATH_NAMESPACE=global.namespace

set -e
rm -rf $TEMP_DIR

#Clone sparse source
mkdir -p $SOURCE_TEMP_DIR || exit
git -C "$SOURCE_TEMP_DIR" init
git -C "$SOURCE_TEMP_DIR" remote add -f origin "$SOURCE_REPO"
git -C "$SOURCE_TEMP_DIR" config core.sparseCheckout true
echo -e "$SOURCE_CHART_PATH\n$SOURCE_VALUES_FILES_PATH" >> "$SOURCE_TEMP_DIR/.git/info/sparse-checkout"
git -C "$SOURCE_TEMP_DIR" pull origin "$SOURCE_BRANCH"

#Clone target
mkdir -p $TARGET_TEMP_DIR || exit
git clone -b $TARGET_BRANCH $TARGET_REPO $TARGET_TEMP_DIR

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