cd lambda/cognito_presignup
rm -rf lambda.zip
cd code
zip -r lambda.zip .
mv lambda.zip ../
cd ../../..