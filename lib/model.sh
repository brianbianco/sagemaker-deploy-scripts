#!/bin/bash

# Arguments:
#   $1 - model_name: Name of the model to deploy
#   $2 - image_uri: URI of the Docker image for inference
#   $3 - model_data_url: S3 URL for the model data
#   $4 - execution_role_arn: ARN of the execution role
#   $5 - additional_aws_args: Additional arguments for AWS CLI
#   $6 - additional_sagemaker_args: Additional arguments to pass to the sagemaker create-model subcommand
#   $7 - dry_run: Simply echoes the command to be run, doesn't actually execute it
#   $8 - sagemaker_container_env: Environment variables (formatted as key=value pairs) for the model container

create_model() {
  local model_name="$1"
  local image_uri="$2"
  local model_data_url="$3"
  local execution_role_arn="$4"
  local additional_aws_args="${5:-}"
  local additional_sagemaker_args="${6:-}"
  local dry_run="${7:-true}"
  local sagemaker_container_env="${8:-}"

  if [[ -z "$model_name" ]]; then
    echo "Error: Model name is required." >&2
    return 1
  fi

  local primary_container="Image=\"$image_uri\",ModelDataUrl=\"$model_data_url\""
  if [[ -n "$sagemaker_container_env" ]]; then
    primary_container="$primary_container,$sagemaker_container_env"
  fi

  local command="aws $additional_aws_args sagemaker create-model \
    --model-name \"$model_name\" \
    --primary-container $primary_container \
    --execution-role-arn \"$execution_role_arn\" \
    $additional_sagemaker_args"

  echo "$command" >&2

  if [[ "$dry_run" != "true" ]]; then
    eval "$command"
  fi
}

check_model_exists() {
  local model_name="$1"

  existing_model=$(aws sagemaker describe-model --model-name "$model_name" --query "ModelName" --output text 2>/dev/null)

  if [[ "$existing_model" == "$model_name" ]]; then
    return 0
  else
    return 1
  fi
}

check_model_data_url_exists() {
  local model_data_url="$1"

  # ${parameter#pattern} removes the shortest match of 'pattern' from the start of 'parameter'.
  # ${parameter%%pattern} removes the longest match of 'pattern' from the end of 'parameter'.
  local s3_path="${model_data_url#s3://}"
  local bucket_name="${s3_path%%/*}"
  local object_key="${s3_path#*/}"

  if aws s3api head-object --bucket "$bucket_name" --key "$object_key" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

