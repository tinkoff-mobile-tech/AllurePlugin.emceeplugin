#!/bin/bash

set -e

pluginName="AllurePlugin.emceeplugin"
pluginPath=".build/debug/$pluginName/"
rm -rf "$pluginPath"
mkdir -p "$pluginPath"
cp .build/debug/Plugin "$pluginPath"

cd "$pluginPath/../"
rm -rf "$pluginName".zip
zip -r "$pluginName".zip "$pluginName"