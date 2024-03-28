#!/bin/bash

helm package _global_chart/
helm registry login ghcr.io/danielmarom78 --username danielmarom78 --password $GIT_PASS
helm push global-chart-1.0.0.tgz oci://ghcr.io/danielmarom78
