
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
_is_ci=${is_ci}

define build_script
	$(if $(filter $(1),is_ci), \
		@$(_bazel_path) build //:tulsi \
			--config=ci -s \
			--verbose_failures --verbose_explanations \
			--use_top_level_targets_for_symlinks \
			--xcode_version=${_xcode_version}, \
		@$(_bazel_path) build //:tulsi \
			--verbose_failures \
			--use_top_level_targets_for_symlinks \
			--xcode_version=${_xcode_version} \
	)
endef

clean:
	@# remove previous
	@rm -f $(_bazel_bin)/tulsi.zip
	@rm -f $(_bazel_bin)/Tulsi++.zip
	@rm -rf $(_bazel_bin)/Tulsi++.app

build: clean
	@echo "===================================="
	@echo "|           BUILDING               |"
	@echo "===================================="
	@echo xcode=$(_xcode_version)
	@echo workspace_path=$(_workspace_path)
	@echo bazel_path=$(_bazel_path)
	@echo is_ci=$(if $(_is_ci), true, false)
	@echo ====================================	

	$(if $(_is_ci), $(call build_script, is_ci), $(call build_script))
	
	@unzip -oq $(_bazel_bin)/tulsi.zip -d "${_bazel_bin}"

	@# remove all frameworks, for some reason, dylib like `foundation` is included which should not.
	@rm -rf $(_bazel_bin)/Tulsi++.app/Contents/Frameworks/*

	@# for development, we use Sparkle framework which all symblink is replace with copy of the original file
	@# this is needed, to solve error when building tulsi on xcode
	@# this sparkle framework version is default sparkle with symlink
	@unzip -oq ${_workspace_path}/src/Sparkle/Sparkle.framework.zip -d $(_bazel_bin)/Tulsi++.app/Contents/Frameworks
	
	@# remove bazel's codesign, it's invalid codesign, apple notorization server unable to read the codesign
	@codesign --remove-signature --deep $(_bazel_bin)/Tulsi++.app
	@codesign --remove-signature --deep $(_bazel_bin)/Tulsi++.app/Contents/Frameworks/Sparkle.framework

install: build
	@echo "===================================="
	@echo "|           INSTALLING              |"
	@echo "===================================="
	@echo install_path=$(_unzip_dir)
	@echo ====================================	
	
	@rm -rf ${_unzip_dir}/Tulsi++.app
	@cp -R $(_bazel_bin)/Tulsi++.app ${_unzip_dir}/Tulsi++.app
	@open "${_unzip_dir}/Tulsi++.app"

.PHONY: build install