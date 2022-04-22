#!/bin/bash
# Copyright 2022 Wendy Liga. All rights reserved.
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

# script helper to generate docc
# example: bazel_docc.sh /usr/bin/bazel //:MyApp "--cpu=ios_x86_64"
set -eu

readonly bazel_executable="$1"; shift
readonly target="$1"; shift
readonly config="$1"; shift
readonly target_name="$1"; shift
readonly docc_bundle="$1"; shift
readonly symbol_graph_dir=/var/tmp/swift-symbol-graph
readonly symbol_graph_arch_dir=${symbol_graph_dir}/arm64-apple-ios
readonly output=/var/tmp

# make sure directory exist
mkdir -p ${symbol_graph_arch_dir}
  
(
  set -x

  "${bazel_executable}" clean && "${bazel_executable}" build ${target} ${config} --nouse_action_cache --remote_upload_local_results=false
)

docc_exec=$(xcode-select -p)/Toolchains/XcodeDefault.xctoolchain/usr/bin/docc
docc_output=${output}/${target_name}.doccarchive

(
  set -x

  ${docc_exec} convert \
  --index \
  --fallback-display-name DocC \
  --fallback-bundle-identifier com.example.DocC \
  --fallback-bundle-version 1 \
  --output-dir ${docc_output} \
  --additional-symbol-graph-dir ${symbol_graph_dir} \
  ${docc_bundle}
)

# make sure exist
mkdir -p "${BUILT_PRODUCTS_DIR}"
(
  set -x
  # copy to derivedData
  cp -r "${docc_output}" "${BUILT_PRODUCTS_DIR}/${target_name}.doccarchive"
)

# looks like ~/Library/Developer/Xcode/DerivedData/Meijer-bendrqyqislprqgnunzxygajcfho/Build/Intermediates.noindex/meijer.build/Debug-iphonesimulator/meijer.build/
intermediates_dir=$(dirname "${CLASS_FILE_DIR}") 
# make sure exist
mkdir -p "${intermediates_dir}"

(
  set -x
  cp -r "${symbol_graph_dir}" "${intermediates_dir}/swift-symbol-graph"
)


# clean up
rm -rf "${symbol_graph_dir}"

# open docc
open "${BUILT_PRODUCTS_DIR}/${target_name}.doccarchive"
 
echo ✅ Grab docc at "${BUILT_PRODUCTS_DIR}/${target_name}.doccarchive"
