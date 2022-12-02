#! /bin/bash
aws cloudformation describe-stacks --stack-name $ENVIRONMENT-brane-job > /dev/null 2>&1
if [ $? -ne 0 ] ; then
	echo -e "Stack does not exist\nCreating"
  aws cloudformation create-stack \
    --stack-name ${ENVIRONMENT}-brane-job \
    --template-body file://ci/glue-Job-v1.yaml \
    --parameters ParameterKey=Environment,ParameterValue=$ENVIRONMENT ParameterKey=ScriptLocation,ParameterValue=s3://${ENVIRONMENT}-${BUCKET_NAME}/$JOB_SCRIPT_PATH/main-$CODEBUILD_RESOLVED_SOURCE_VERSION.py ParameterKey=PythonLibraryPath,ParameterValue=s3://${ENVIRONMENT}-${BUCKET_NAME}/$JOB_LIBRARY_PATH/brane_flows_$CODEBUILD_RESOLVED_SOURCE_VERSION-0.9-py3-none-any.whl \
    --capabilities CAPABILITY_NAMED_IAM
  echo "Waiting for stack to finish creating..."
  aws cloudformation wait stack-create-complete \
    --stack-name ${ENVIRONMENT}-brane-job
  echo "Finished creating stack"
else
  echo "Stack already exists."
  aws cloudformation update-stack \
    --stack-name ${ENVIRONMENT}-brane-job \
    --no-use-previous-template \
    --template-body file://ci/glue-Job-v1.yaml \
    --parameters ParameterKey=Environment,ParameterValue=$ENVIRONMENT ParameterKey=ScriptLocation,ParameterValue=s3://${ENVIRONMENT}-${BUCKET_NAME}/$JOB_SCRIPT_PATH/main-$CODEBUILD_RESOLVED_SOURCE_VERSION.py ParameterKey=PythonLibraryPath,ParameterValue=s3://${ENVIRONMENT}-${BUCKET_NAME}/$JOB_LIBRARY_PATH/brane_flows_$CODEBUILD_RESOLVED_SOURCE_VERSION-0.9-py3-none-any.whl \
    --capabilities CAPABILITY_NAMED_IAM > /dev/null 2>&1
  if [ $? -ne 0 ] ; then
    echo "Stack already up-to-date"
  else
    echo "Updating stack..."
    aws cloudformation wait stack-update-complete \
      --stack-name ${ENVIRONMENT}-brane-job
    echo "Waiting for stack to complete update..."
  fi
fi