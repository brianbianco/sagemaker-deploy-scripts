# Sagemaker Deployment Script

Allows for deploying a new model and endpoint configuration to an existing sagemaker endpoint

It defaults to doing a dry run, which will only output the AWS commands.

This scripts expects you to have your credentials setup in such a way that the aws cli default call will work

This is just a little toy deployment script and you should treat it appropriately

## Deployment expectations

- All prereqs are pips listed in a requirements.txt
- We are using an AWS provided docker image
- All model files can be loaded and served with pytorch
- The bundles will follow the expected layout (provided below)

Sagemaker does support custom docker image deployment, but this deployment script is expected
a model tarball in s3. It does allow you to specify any image, we suggest sticking to the
AWS supported one.

## PyTorch model file structure

https://sagemaker.readthedocs.io/en/stable/frameworks/pytorch/using_pytorch.html#deploy-pytorch-models

```
model_bundle.tar.gz
├── model.pt
└── code/
    ├── inference.py
    └── requirements.txt

inference.py is expected to at a minimum implement `model_fn` and `predict_fn`

```

## Usage

```bash
$ ./deploy.sh <configuration-file-1> <configuration-file-2>... [--no-dry-run] [--no-deploy-model] [--no-deploy-endpoint-config] [--no-deploy-endpoint]
```

### Options

- `<configuration-files>`: One or more configuration file paths.
- `--no-dry-run`: Disable dry-run mode and actually execute commands.
- `--no-deploy-model`: Skip the model deployment step.
- `--no-deploy-endpoint-config`: Skip the endpoint configuration deployment step.
- `--no-deploy-endpoint`: Skip the endpoint deployment step.
- `-h, --help`: Display this help message.

## Configuration Files

Configuration files should be placed in the `configs` directory and define the parameters needed for model deployment and endpoint setup.

Each configuration is sourced in a subshell to prevent inheriting the lasts settings

This does however mean the configuration files OVERRIDE any ENV VARS you set in your shell

### Example:

```bash
MODEL_NAME="my-model"
VARIANT_NAME="${MODEL_NAME}-$(date +'%Y%m%d%H%M%S')"
ENDPOINT_NAME="my-endpoint"
ENDPOINT_CONFIG_NAME="${MODEL_NAME}-$(date +'%Y%m%d%H%M%S')"
INSTANCE_COUNT=1
INSTANCE_TYPE="ml.t2.medium"
MODEL_DATA_URL="s3://path/to/model.tar.gz"
IMAGE_URI="763104351884.dkr.ecr.us-west-2.amazonaws.com/pytorch-inference:2.4.0-cpu-py311-ubuntu22.04-sagemaker"
EXECUTION_ROLE_ARN="arn:aws:iam::account-id:role/SageMakerExecutionRole"
```

# Calling the functions directly

If you don't want to use the sagemaker_deploy.sh script you can just set and call the functions directly like so


## create_model

```bash
export MODEL_NAME="my-model"
export IMAGE_URI="763104351884.dkr.ecr.us-west-2.amazonaws.com/pytorch-inference:2.4.0-cpu-py311-ubuntu22.04-sagemaker"
export MODEL_DATA_URL="s3://path/to/model.tar.gz"
export EXECUTION_ROLE_ARN="arn:aws:iam::account-id:role/SageMakerExecutionRole"
export DRY_RUN=true

source ./lib/model.sh

create_model "$MODEL_NAME" "$IMAGE_URI" "$MODEL_DATA_URL" "$EXECUTION_ROLE_ARN" "$ADDITIONAL_AWS_ARGS" "$ADDITIONAL_SAGEMAKER_ARGS" "$DRY_RUN"
```

## create_endpoint_config

```bash
export ENDPOINT_CONFIG_NAME="my-endpoint-config"
export MODEL_NAME="my-model"
export VARIANT_NAME="my-variant"
export INSTANCE_COUNT=1
export INSTANCE_TYPE="ml.t2.medium"
export DRY_RUN=true

source ./lib/endpoint_config.sh

create_endpoint_config "$ENDPOINT_CONFIG_NAME" "$MODEL_NAME" "$VARIANT_NAME" "$INSTANCE_COUNT" "$INSTANCE_TYPE" "$ADDITIONAL_AWS_ARGS" "$ADDITIONAL_SAGEMAKER_ARGS" "$DRY_RUN"
```

## update_endpoint

```bash
export ENDPOINT_NAME="my-endpoint"
export ENDPOINT_CONFIG_NAME="my-endpoint-config"
export DRY_RUN=true

source ./lib/endpoint.sh

update_endpoint "$ENDPOINT_NAME" "$ENDPOINT_CONFIG_NAME" "$ADDITIONAL_AWS_ARGS" "$ADDITIONAL_SAGEMAKER_ARGS" "$DRY_RUN"
```
