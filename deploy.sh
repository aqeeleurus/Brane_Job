sed -i "s|.format()|.format(\"$CODEBUILD_RESOLVED_SOURCE_VERSION\")|" setup.py
python3 brane_flows/setup.py bdist_wheel
aws s3 cp *.whl s3://${ENVIRONMENT}-${BUCKET_NAME}/$JOB_LIBRARY_PATH/
cd ..
mv main.py main-$CODEBUILD_RESOLVED_SOURCE_VERSION.py
aws s3 cp main-$CODEBUILD_RESOLVED_SOURCE_VERSION.py s3://${ENVIRONMENT}-${BUCKET_NAME}/$JOB_SCRIPT_PATH/
aws cloudformation describe-stacks --region us-east-1 --stack-name dev-brane-job > /dev/null 2>&1
if [ $? -ne 0 ] ; then
	echo -e "Stack does not exist\nCreating"
  aws cloudformation create-stack \
    --region us-east-1 \
    --stack-name ${ENVIRONMENT}-brane-job \
    --template-body file://glue-Job-v1.yaml \
    --parameters ParameterKey=Environment,ParameterValue=$ENVIRONMENT ParameterKey=ScriptLocation,ParameterValue=s3://${ENVIRONMENT}-${BUCKET_NAME}/$JOB_SCRIPT_PATH/main-$CODEBUILD_RESOLVED_SOURCE_VERSION.py ParameterKey=PythonLibraryPath,ParameterValue=s3://${ENVIRONMENT}-${BUCKET_NAME}/$JOB_LIBRARY_PATH/brane_flows_$CODEBUILD_RESOLVED_SOURCE_VERSION-0.9-py3-none-any.whl \
    --capabilities CAPABILITY_NAMED_IAM
  echo "Waiting for stack to finish creating..."
  aws cloudformation wait stack-create-complete \
    --region us-east-1 \
    --stack-name ${ENVIRONMENT}-brane-job
  echo "Finished creating stack"
  echo "Starting Brane Job"
  aws glue start-job-run --job-name $JOB_NAME
else
  echo "Stack already exists."
  aws cloudformation update-stack \
    --region us-east-1 \
    --stack-name ${ENVIRONMENT}-brane-job \
    --no-use-previous-template \
    --template-body file://glue-Job-v1.yaml \
    --parameters ParameterKey=Environment,ParameterValue=$ENVIRONMENT ParameterKey=ScriptLocation,ParameterValue=s3://${ENVIRONMENT}-${BUCKET_NAME}/$JOB_SCRIPT_PATH/main-$CODEBUILD_RESOLVED_SOURCE_VERSION.py ParameterKey=PythonLibraryPath,ParameterValue=s3://${ENVIRONMENT}-${BUCKET_NAME}/$JOB_LIBRARY_PATH/brane_flows_$CODEBUILD_RESOLVED_SOURCE_VERSION-0.9-py3-none-any.whl \
    --capabilities CAPABILITY_NAMED_IAM > /dev/null 2>&1
  if [ $? -ne 0 ] ; then
    echo "Stack already up-to-date"
  else
    echo "Updating stack..."
    aws cloudformation wait stack-update-complete \
      --region us-east-1 \
      --stack-name ${ENVIRONMENT}-brane-job
    echo "Waiting for stack to complete update..."
    if [ $? -eq 0 ] ; then
      echo "Finished updating stack successfully"
      aws glue start-job-run --job-name $JOB_NAME
    else
      echo "Error occured during stack update"
    fi
  fi
fi