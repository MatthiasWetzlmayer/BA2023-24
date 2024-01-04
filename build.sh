cd lambda/hello-world-lambda
rm -rf lambda.zip
cd code
zip -r lambda.zip .
mv lambda.zip ../
cd ../../..