#!/bin/bash
# Copyright 2016 The Tulsi Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#
# Bridge between Xcode and Bazel for the "clean" action.
#
# Usage: bazel_clean.sh <bazel_binary_path> <bazel_binary_output_path> <bazel startup options>
# Note that the ACTION environment variable is expected to be set to "clean".

set -eu

readonly bazel_executable="$1"; shift
readonly target="$1"; shift
readonly config="$1"; shift
readonly symbol_graph_dir=/var/tmp/swift-symbol-graph
readonly symbol_graph_arch_dir=${symbol_graph_dir}/arm64-apple-ios-simulator
readonly output=/var/tmp

# make sure directory exist
mkdir -p ${symbol_graph_arch_dir}
  
(
  set -x

  "${bazel_executable}" clean && "${bazel_executable}" build ${target} ${config} --swiftcopt='-Xfrontend' --swiftcopt='-emit-symbol-graph' --swiftcopt='-emit-symbol-graph-dir' --swiftcopt="${symbol_graph_arch_dir}" --nouse_action_cache --remote_upload_local_results=false
)

docc_exec=$(xcode-select -p)/Toolchains/XcodeDefault.xctoolchain/usr/bin/docc
(
  set -x

  ${docc_exec} convert \
  --index \
  --fallback-display-name DocC \
  --fallback-bundle-identifier com.example.DocC \
  --fallback-bundle-version 1 \
  --output-dir ${output}/tulsi.doccarchive \
  --additional-symbol-graph-dir ${symbol_graph_dir}
)

# clean up
rm -rf ${symbol_graph_dir}
