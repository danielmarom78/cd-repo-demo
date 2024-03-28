#!/bin/bash

set -e

function check_commands() {
    for cmd in git helm yq; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Error: $cmd is not installed." >&2
            exit 1
        fi
    done
}

function setup_directory() {
    local dir=$1
    echo "Setting up directory $dir..."
    rm -rf "$dir"
    mkdir -p "$dir"
}

function sparse_checkout() {
    local repo=$1
    local branch=$2
    local path=$3
    local dir=$4

    echo "Cloning from $repo branch $branch path $path into $dir..."
    mkdir -p "$dir"
    cd "$dir" || exit
    git init
    git remote add origin "$repo"
    git config core.sparseCheckout true
    echo "$path" > .git/info/sparse-checkout
    git pull origin "$branch"
    cd - || exit
}

function render_helm_charts() {
    echo "Rendering Helm charts..."
    for val_file in $(find "$SOURCE_PATH" -type f); do
        local app_name="$PROJ-$APP"
        local srv_name
        srv_name=$(yq e ".$SOURCE_YAML_SERVICE_NAME_PATH" "$val_file")
        local render_full_path="$RENDERED_TEMP_DIR/$srv_name"
        local target_full_path="$TARGET_TEMP_DIR/$TARGET_GIT_PATH/$srv_name"

        mkdir -p "$render_full_path"

        helm template . -f "$val_file" --set "$SOURCE_YAML_SERVICE_NAME_PATH=$srv_name","$SOURCE_YAML_APP_NAME_PATH=$app_name","$SOURCE_YAML_NAMESPACE=prod" --output-dir "$render_full_path"

        rm -rf "$target_full_path"
        mkdir -p "$target_full_path"
        cp -r "$render_full_path"/proxy-chart/charts/application/templates/* "$target_full_path"
    done
}



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
export TARGET_GIT_PATH=
export TARGET_TEMP_DIR=$TEMP_DIR/TARGET
export RENDERED_TEMP_DIR=$TEMP_DIR/RENDERED

check_commands

# Setup environment
setup_directory "$TEMP_DIR"
setup_directory "$RENDERED_TEMP_DIR"

# Sparse checkouts
sparse_checkout "$SOURCE_GIT_REPO" "$SOURCE_GIT_BRANCH" "$SOURCE_GIT_BASE_PATH" "$SOURCE_TEMP_DIR"
sparse_checkout "$TARGET_GIT_REPO" "$TARGET_GIT_BRANCH" "$PROJ/$APP" "$TARGET_TEMP_DIR"

# Render Helm charts
render_helm_charts

# Commit and push changes
cd "$TARGET_TEMP_DIR" || exit
git add .
git commit -m "Automatic commit by pipeline for app=$APP project=$PROJ"
git push --set-upstream origin "$TARGET_GIT_BRANCH"

echo "Script completed successfully."