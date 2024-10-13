function hook_pre_app_dependencies() {
  cd $build_path

  if [ -n "$hook_pre_fetch_dependencies" ]; then
    output_section "Executing hook before fetching app dependencies: $hook_pre_fetch_dependencies"
    $hook_pre_fetch_dependencies || exit 1
  fi

  cd - > /dev/null
}

function hook_pre_compile() {
  cd $build_path

  if [ -n "$hook_pre_compile" ]; then
    output_section "Executing hook before compile: $hook_pre_compile"
    $hook_pre_compile || exit 1
  fi

  cd - > /dev/null
}

function hook_post_compile() {
  cd $build_path

  if [ -n "$hook_post_compile" ]; then
    output_section "Executing hook after compile: $hook_post_compile"
    $hook_post_compile || exit 1
  fi

  cd - > /dev/null
}


function compile_app() {
  local git_dir_value=$GIT_DIR
  unset GIT_DIR

  cd $build_path
  output_section "Compiling"

  if [ -n "$hook_compile" ]; then
     output_section "(using custom compile command)"
     $hook_compile || exit 1
  else
     gleam export erlang-shipment
  fi

  mix deps.clean --unused

  export GIT_DIR=$git_dir_value
  cd - > /dev/null
}

#function export_var() {
#  local VAR_NAME=$1
#  local VAR_VALUE=$2
#
#  echo "export ${VAR_NAME}=${VAR_VALUE}"
#}

#function export_default_var() {
#  local VAR_NAME=$1
#  local DEFAULT_VALUE=$2
#
#  if [ ! -f "${env_path}/${VAR_NAME}" ]; then
#    export_var "${VAR_NAME}" "${DEFAULT_VALUE}"
#  fi
#}

#function echo_profile_env_vars() {
#  local buildpack_bin="$(runtime_platform_tools_path)"
#  buildpack_bin="$(runtime_erlang_path)/bin:${buildpack_bin}"
#  buildpack_bin="$(runtime_gleam_path)/bin:${buildpack_bin}"
#
#
#  export_var "PATH" "${buildpack_bin}:\$PATH"
#  export_default_var "LC_CTYPE" "en_US.utf8"
#
#  # Only write MIX_* to profile if the application did not set MIX_*
#  export_default_var "MIX_ENV" "${MIX_ENV}"
#  export_default_var "MIX_HOME" "$(runtime_mix_home_path)"
#  export_default_var "HEX_HOME" "$(runtime_hex_home_path)"
#}

#function echo_export_env_vars() {
#  local buildpack_bin="$(build_platform_tools_path)"
#  buildpack_bin="$(build_erlang_path)/bin:${buildpack_bin}"
#  buildpack_bin="$(build_gleam_path)/bin:${buildpack_bin}"
#
#
#  export_var "PATH" "${buildpack_bin}:\$PATH"
#  export_default_var "LC_CTYPE" "en_US.utf8"
#
#  # Only write MIX_* to profile if the application did not set MIX_*
#  export_default_var "MIX_ENV" "${MIX_ENV}"
#  export_default_var "MIX_HOME" "$(build_mix_home_path)"
#  export_default_var "HEX_HOME" "$(build_hex_home_path)"
#}

function write_profile_d_script() {
  output_section "Creating .profile.d with env vars"
  #mkdir -p $build_path/.profile.d
  #local profile_path="${build_path}/.profile.d/gleam_buildpack_paths.sh"

  #echo_profile_env_vars >> $profile_path
}

function write_export() {
  output_section "Writing export for multi-buildpack support"

  #echo_export_env_vars >> "${build_pack_path}/export"
}
