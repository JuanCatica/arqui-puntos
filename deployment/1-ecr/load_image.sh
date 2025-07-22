# LAOD IMAGE

# To load image follow the following steps (or view the push command from the console)
# Replace <AWS_ACCOUNT> and <ecr_repository_url>

# Retrieve an authentication token and authenticate your Docker client to your registry. Use the AWS CLI:
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <AWS_ACCOUNT>.dkr.ecr.us-east-1.amazonaws.com

# Build Docker image:
# acces to the app folder: cd ../../app/
docker build -t ecr-mcp-arquipuntos-<ARQUIEBRIO> .

# Tag the image:
docker tag ecr-mcp-arquipuntos-<ARQUIEBRIO>:latest <ecr_repository_url>

# Push image
docker push <ecr_repository_url>



docker build -t ecr-mcp-arquipuntos-<ARQUIEBRIO> .

docker run -p 8080:8080 -e DYNAMODB_TABLE_NAME=dynamo-mcp-arquipuntos-<ARQUIEBRIO> \
    -e AWS_ACCESS_KEY_ID= \
    -e AWS_SECRET_ACCESS_KEY= \
    -e AWS_SESSION_TOKEN= \
    ecr-mcp-arquipuntos-<ARQUIEBRIO>s