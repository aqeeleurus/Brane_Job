#! /bin/bash
CODEBUILD_RESOLVED_SOURCE_VERSION=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -b -8)
sed -i "s|.format()|.format(\"$CODEBUILD_RESOLVED_SOURCE_VERSION\")|" brane_flows/setup.py
python3 brane_flows/setup.py bdist_wheel
cd dist
aws s3 cp *.whl s3://${ENVIRONMENT}-${BUCKET_NAME}/$JOB_LIBRARY_PATH/
cd ..
mv main.py main-$CODEBUILD_RESOLVED_SOURCE_VERSION.py
aws s3 cp main-$CODEBUILD_RESOLVED_SOURCE_VERSION.py s3://${ENVIRONMENT}-${BUCKET_NAME}/$JOB_SCRIPT_PATH/
bash ci/CreateUpdateStack.sh