#!/bin/bash

source ./lib/model.sh
source ./lib/endpoint_config.sh
source ./lib/endpoint.sh
source ./lib/util.sh

usage() {
  echo "Usage: $0 <configuration-file-1> <configuration-file-2>... [--no-dry-run] [--no-deploy-model] [--no-deploy-endpoint-config] [--no-deploy-endpoint]"
  echo ""
  echo "Options:"
  echo "  <configuration-files>         One or more configuration files"
  echo "  --no-dry-run                  Disable dry run and actually execute commands"
  echo "  --no-deploy-model             Skip model deployment"
  echo "  --no-deploy-endpoint-config   Skip endpoint configuration deployment"
  echo "  --no-deploy-endpoint          Skip endpoint deployment"
  echo "  -h, --help                    Display this help message"
  exit 1
}

check_configs_exist() {
  local result=0

  for CONFIG_FILE in "$@"; do
    if [ ! -f "$CONFIG_FILE" ]; then
      echo "Error: Configuration file $CONFIG_FILE not found." >&2
      result=1
    fi
  done

  return $result
}

deploy() {
  CONFIG_FILES="$@"

  for CONFIG_FILE in $CONFIG_FILES; do
    (
      source "$CONFIG_FILE"

      check_model_data_url_exists "$MODEL_DATA_URL" || echo "Error: $MODEL_DATA_URL does not exist." >&2
      check_model_exists "$MODEL_NAME" && echo "Error: Model $MODEL_NAME already exists." >&2

      sagemaker_env_vars=$(get_sagemaker_env_vars "$CONFIG_FILE")

      echo "Model Name: $MODEL_NAME" >&2
      echo "Variant Name: $VARIANT_NAME" >&2
      echo "Endpoint Name: $ENDPOINT_NAME" >&2
      echo "Endpoint Config Name: $ENDPOINT_CONFIG_NAME" >&2
      echo "Instance Count: $INSTANCE_COUNT" >&2
      echo "Instance Type: $INSTANCE_TYPE" >&2
      echo "Additional AWS Args: $ADDITIONAL_AWS_ARGS" >&2
      echo "Additional SageMaker Args: $ADDITIONAL_SAGEMAKER_ARGS" >&2
      echo "Sagemaker model passed through ENV: $sagemaker_env_vars" >&2
      echo "Dry run: $DRY_RUN" >&2

      TAGS="--tags Key=btn:initiative,Value=ml-decisioning"

      if [ "$DEPLOY_MODEL" != "false" ]; then
        create_model "$MODEL_NAME" "$IMAGE_URI" "$MODEL_DATA_URL" "$EXECUTION_ROLE_ARN" "$ADDITIONAL_AWS_ARGS" "$ADDITIONAL_SAGEMAKER_ARGS $TAGS" "$DRY_RUN" "$sagemaker_env_vars"
      fi

      if [ "$DEPLOY_ENDPOINT_CONFIG" != "false" ]; then
        create_endpoint_config "$ENDPOINT_CONFIG_NAME" "$MODEL_NAME" "$VARIANT_NAME" "$INSTANCE_COUNT" "$INSTANCE_TYPE" "$ADDITIONAL_AWS_ARGS" "$ADDITIONAL_SAGEMAKER_ARGS $TAGS" "$DRY_RUN"
      fi

      if [ "$DEPLOY_ENDPOINT" != "false" ]; then
        update_endpoint "$ENDPOINT_NAME" "$ENDPOINT_CONFIG_NAME" "$ADDITIONAL_AWS_ARGS" "$ADDITIONAL_SAGEMAKER_ARGS" "$DRY_RUN"
      fi
    )
  done
}

DRY_RUN=true
DEPLOY_MODEL=true
DEPLOY_ENDPOINT_CONFIG=true
DEPLOY_ENDPOINT=true

if [ $# -lt 1 ]; then
  usage
fi

CONFIG_FILES=()
while [ $# -gt 0 ]; do
  case $1 in
    --no-dry-run)
      DRY_RUN=false
      shift
      ;;
    --no-deploy-model)
      DEPLOY_MODEL=false
      shift
      ;;
    --no-deploy-endpoint-config)
      DEPLOY_ENDPOINT_CONFIG=false
      shift
      ;;
    --no-deploy-endpoint)
      DEPLOY_ENDPOINT=false
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      CONFIG_FILES="$CONFIG_FILES $1"
      shift
      ;;
  esac
done

which aws > /dev/null || { echo "AWS CLI is not installed or not in the PATH." >&2; exit 1; }
check_configs_exist $CONFIG_FILES || exit 1
deploy $CONFIG_FILES

