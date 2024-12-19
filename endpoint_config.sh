#!/bin/bash

# Arguments:
#   $1 - endpoint_config_name: The name of the endpoint configuration
#   $2 - model_name: The model name to associate with the endpoint
#   $3 - variant_name: The variant name for the model
#   $4 - instance_count: The number of instances
#   $5 - instance_type: The type of instance
#   $6 - additional_aws_args: Additional arguments to pass to the AWS CLI
#   $7 - additional_sagemaker_args: Additional arguments to pass to the SageMaker create-endpoint-config command
#   $8 - dry_run: Set to "true" to perform a dry run (prints the command instead of executing it)


#   This function doesn't account for any of the options you might want for a production variatn
#   nor does it account for shadow variants at all.  Here's what some options might look like
#   for future reference. These should be verifed as correct as they haven't been tested
##
#    --production-variants '[
#        {
#            "VariantName": "ModelA",
#            "ModelName": "ModelA",
#            "InitialInstanceCount": 1,
#            "InstanceType": "ml.m5.large",
#            "InitialVariantWeight": 1.0
#        }
#    ]' \
#    --shadow-variant '{
#        "ShadowModelVariantName": "ModelB",
#        "ShadowModelName": "ModelB",
#        "InitialInstanceCount": 1,
#        "InstanceType": "ml.m5.large",
#        "SamplingPercentage": 100
#    }'



create_endpoint_config() {
  local endpoint_config_name="$1"
  local model_name="$2"
  local variant_name="$3"
  local instance_count="$4"
  local instance_type="$5"
  local additional_aws_args="${6:-}"
  local additional_sagemaker_args="${7:-}"
  local dry_run="${8:-true}"

  if [[ -z "$endpoint_config_name" || -z "$model_name" || -z "$variant_name" ]]; then
    echo "Error: --endpoint-config-name, --model-name, and --variant-name are required." >&2
    return 1
  fi

  local create_command="aws $additional_aws_args sagemaker create-endpoint-config \
    --endpoint-config-name \"$endpoint_config_name\" \
    --production-variants VariantName=\"$variant_name\",ModelName=\"$model_name\",InitialInstanceCount=$instance_count,InstanceType=\"$instance_type\" \
    $additional_sagemaker_args"

  echo "$create_command" >&2
  if [[ "$dry_run" != "true" ]]; then
    eval "$create_command"
	fi
}

check_endpoint_config_exists() {
  local endpoint_config_name="$1"

  existing_config=$(aws sagemaker describe-endpoint-config --endpoint-config-name "$endpoint_config_name" --query "EndpointConfigName" --output text 2>/dev/null)

  if [[ "$existing_config" == "$endpoint_config_name" ]]; then
    echo "Endpoint config $endpoint_config_name already exists." >&2
    return 0
  else
    return 1
  fi
}
