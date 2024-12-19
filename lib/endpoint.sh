#!/bin/bash

# Arguments:
#   $1 - endpoint_name: The name of the existing endpoint
#   $2 - endpoint_config_name: The name of the new endpoint configuration
#   $3 - additional_aws_args: Additional arguments to pass to the AWS CLI
#   $4 - additional_sagemaker_args: Additional arguments to pass to the SageMaker update-endpoint command
#   $5 - dry_run: Set to "true" to perform a dry run (prints the command instead of executing it)

update_endpoint() {
  local endpoint_name="$1"
  local endpoint_config_name="$2"
  local additional_aws_args="${3:-}"
  local additional_sagemaker_args="${4:-}"
  local dry_run="${5:-true}"

  if [[ -z "$endpoint_name" || -z "$endpoint_config_name" ]]; then
    echo "Error: --endpoint-name and --endpoint-config-name are required." >&2
    return 1
  fi

  local update_command="aws $additional_aws_args sagemaker update-endpoint \
    --endpoint-name \"$endpoint_name\" \
    --endpoint-config-name \"$endpoint_config_name\" \
    $additional_sagemaker_args"

  echo "$update_command" >&2
  if [[ "$dry_run" != "true" ]]; then
    eval "$update_command"
	fi
}
