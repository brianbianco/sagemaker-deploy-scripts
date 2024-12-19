#!/bin/bash

get_sagemaker_env_vars() {
  # Extract and display environment variables matching a given prefix.
  # Arguments:
  #   config_file (optional): Path to a file to source environment variables from.
  #   env_var_prefix (optional): Prefix to filter environment variables (default: "SAGEMAKER_").

  local config_file="${1:-}"
  local env_var_prefix="${2:-SAGEMAKER_}"
  local environment_vars=""

  [[ -f "$config_file" ]] && source "$config_file"

	# We are using compgen because we specifically are looking for unexported
  # env vars
  for var in $(compgen -v); do
    value="${!var}"

    if [[ "$var" == "$env_var_prefix"* ]]; then
      if [[ -n "$environment_vars" ]]; then
        environment_vars="$environment_vars,"
      fi
      environment_vars="$environment_vars$var=\"$value\""
    fi
  done

  if [[ -n "$environment_vars" ]]; then
    echo "Environment={$environment_vars}"
  fi
}

