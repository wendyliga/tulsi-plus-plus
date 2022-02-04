
# default
default_xcode_version=13.0.0
default_unzip_dir=${HOME}/Applications
default_bazel_path=bazel

# configuration
_unzip_dir=$(if $(install_path),$(install_path),$(default_unzip_dir))
_bazel_path=$(if $(bazel_path),$(bazel_path),$(default_bazel_path))
_xcode_version:= $(if $(xcode),$(xcode),$(default_xcode_version))
_workspace_path:=$(shell ${_bazel_path} info workspace)
_bazel_bin=${_workspace_path}/bazel-bin
_bazel_out=${_workspace_path}/bazel-out
_is_ci=${is_ci}
_version=${version}

define build_script_intel
	$(if $(filter $(1),is_ci), \
		@$(_bazel_path) build //:tulsi \
			--config=ci \
			--config=intel \
			-s \
			--verbose_failures \
			--use_top_level_targets_for_symlinks \
			--xcode_version=${_xcode_version}, \
		@$(_bazel_path) build //:tulsi \
			--config=intel \
			--verbose_failures \
			--use_top_level_targets_for_symlinks \
			--xcode_version=${_xcode_version} \
	)
endef

define build_script_apple_silicon
	$(if $(filter $(1),is_ci), \
		@$(_bazel_path) build //:tulsi \
			--config=ci \
			--config=apple_silicon \
			-s \
			--verbose_failures \
			--use_top_level_targets_for_symlinks \
			--xcode_version=${_xcode_version}, \
		@$(_bazel_path) build //:tulsi \
			--verbose_failures \
			--config=apple_silicon \
			--use_top_level_targets_for_symlinks \
			--xcode_version=${_xcode_version} \
	)
endef

define processing_binary
	@# remove all frameworks, for some reason, dylib like `foundation` is included which should not.
	@rm -rf $(_bazel_bin)/Tulsi++.app/Contents/Frameworks/*

	@# for development, we use Sparkle framework which all symblink is replaced with copy of the original file
	@# this is needed, to solve error when building tulsi on xcode
	@# this sparkle framework version is default sparkle with symlink
	@unzip -oq ${_workspace_path}/src/Sparkle/Sparkle.framework.zip -d $(_bazel_bin)/Tulsi++.app/Contents/Frameworks
	
	@# remove bazel's codesign, it's invalid codesign, apple notorization server unable to read the codesign
	@codesign --remove-signature --deep $(_bazel_bin)/Tulsi++.app
	@codesign --remove-signature --deep $(_bazel_bin)/Tulsi++.app/Contents/Frameworks/Sparkle.framework
endef

define install
	@echo "===================================="
	@echo "|           INSTALLING              |"
	@echo "===================================="
	@echo install_path=$(_unzip_dir)
	@echo ====================================	
	
	@rm -rf ${_unzip_dir}/Tulsi++.app
	@cp -R $(_bazel_bin)/Tulsi++.app ${_unzip_dir}/Tulsi++.app
	@open "${_unzip_dir}/Tulsi++.app"
endef

clean:
	@# remove previous
	@rm -rf $(_bazel_bin)
	@rm -rf $(_bazel_out)
	@rm -rf ${_workspace_path}/.build

build: clean
	@echo "===================================="
	@echo "|           BUILDING               |"
	@echo "===================================="
	@echo xcode=$(_xcode_version)
	@echo workspace_path=$(_workspace_path)
	@echo bazel_path=$(_bazel_path)
	@echo is_ci=$(if $(_is_ci),true,false)
	@echo ====================================

	@# build for intel
	$(if $(_is_ci),$(call build_script_intel, is_ci),$(call build_script_intel))
	@mkdir -p "${_workspace_path}/.build/x86_64"
	@unzip -oq $(_bazel_bin)/tulsi.zip -d "${_workspace_path}/.build/x86_64"

	@# build for apple silicon
	$(if $(_is_ci),$(call build_script_apple_silicon, is_ci),$(call build_script_apple_silicon))
	@mkdir -p "${_workspace_path}/.build/apple_silicon"
	@unzip -oq $(_bazel_bin)/tulsi.zip -d "${_workspace_path}/.build/apple_silicon"

	@# create fat executable to contain both x86_64 and apple silicon binary
	@mkdir -p "${_workspace_path}/.build/universal_binary"
	@cp -r "${_workspace_path}/.build/x86_64/Tulsi++.app" "${_workspace_path}/.build/universal_binary"
	@lipo -create \
        "${_workspace_path}/.build/x86_64/Tulsi++.app/Contents/MacOS/Tulsi++" \
        "${_workspace_path}/.build/apple_silicon/Tulsi++.app/Contents/MacOS/Tulsi++" \
        -output "${_workspace_path}/.build/universal_binary/Tulsi++.app/Contents/MacOS/Tulsi++" \
	
	@# packing it back to bazel-bin
	@rm -f $(_bazel_bin)/tulsi.zip
	@cp -r .build/universal_binary/Tulsi++.app $(_bazel_bin)/Tulsi++.app

	@# additional processing
	@$(call processing_binary)

install: build
	$(call install)

xcode:
	@export TULSI_APP=/Applications/Tulsi++.app && src/tools/generate_xcodeproj.sh -- --genconfig ./Tulsi.tulsiproj:Tulsi --outputfolder .

release:
	$(if $(_version),@git tag ${_version} && git push origin main "${_version}",@echo spesify version)

test:
	bazel test //src/TulsiGeneratorTests --config=ci --compilation_mode=fastbuild --xcode_version=${_xcode_version}

.PHONY: build install clean xcode release

