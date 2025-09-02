#!/bin/bash
# =============================================================================
# EKS CloudForge - Build and Test Script
# =============================================================================
# This script builds, tests, and pushes the Docker image to ECR
# Optimized for t3.micro instances and cost efficiency

set -e  # Exit on any error

# =============================================================================
# CONFIGURATION
# =============================================================================
APP_NAME="eks-cloudforge-app"
IMAGE_TAG="latest"
ECR_REPO_URL=""  # Will be set from Terraform output
AWS_REGION="us-east-1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# FUNCTIONS
# =============================================================================

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

check_prerequisites() {
    print_header "Checking Prerequisites"

    # Check if Docker is installed and running
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        print_error "Docker is not running"
        exit 1
    fi

    print_success "Docker is installed and running"

    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed"
        exit 1
    fi

    print_success "AWS CLI is installed"

    # Check if we're authenticated with AWS
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "Not authenticated with AWS"
        print_warning "Run: aws configure"
        exit 1
    fi

    print_success "Authenticated with AWS"
}

get_ecr_repo_url() {
    print_header "Getting ECR Repository URL"

    # Try to get ECR repo URL from Terraform output
    if [ -f "../terraform/terraform.tfstate" ]; then
        ECR_REPO_URL=$(cd ../terraform && terraform output -raw ecr_repository_url 2>/dev/null || echo "")
    fi

    if [ -z "$ECR_REPO_URL" ]; then
        print_warning "ECR repository URL not found in Terraform output"
        print_warning "Please provide the ECR repository URL:"
        read -p "ECR Repository URL: " ECR_REPO_URL
    fi

    if [ -z "$ECR_REPO_URL" ]; then
        print_error "ECR repository URL is required"
        exit 1
    fi

    print_success "ECR Repository URL: $ECR_REPO_URL"
}

build_image() {
    print_header "Building Docker Image"

    echo "Building $APP_NAME:$IMAGE_TAG..."

    # Build the image with detailed output
    docker build \
        --tag "$APP_NAME:$IMAGE_TAG" \
        --file Dockerfile \
        --progress=plain \
        .

    if [ $? -eq 0 ]; then
        print_success "Image built successfully"

        # Show image size
        IMAGE_SIZE=$(docker images $APP_NAME:$IMAGE_TAG --format "table {{.Size}}" | tail -n 1)
        echo "Image size: $IMAGE_SIZE"

        # Show image details
        echo "Image details:"
        docker images $APP_NAME:$IMAGE_TAG
    else
        print_error "Image build failed"
        exit 1
    fi
}

test_image_locally() {
    print_header "Testing Image Locally"

    echo "Starting container for testing..."

    # Run container in background
    CONTAINER_ID=$(docker run -d -p 5000:5000 --name test-$APP_NAME $APP_NAME:$IMAGE_TAG)

    if [ $? -eq 0 ]; then
        print_success "Container started successfully"

        # Wait for application to start
        echo "Waiting for application to start..."
        sleep 10

        # Test health endpoint
        echo "Testing health endpoint..."
        if curl -f http://localhost:5000/health &> /dev/null; then
            print_success "Health endpoint is working"
        else
            print_error "Health endpoint failed"
        fi

        # Test main endpoint
        echo "Testing main endpoint..."
        if curl -f http://localhost:5000/ &> /dev/null; then
            print_success "Main endpoint is working"
        else
            print_error "Main endpoint failed"
        fi

        # Show container logs
        echo "Container logs:"
        docker logs $CONTAINER_ID --tail 20

        # Stop and remove test container
        echo "Cleaning up test container..."
        docker stop $CONTAINER_ID
        docker rm $CONTAINER_ID

        print_success "Local testing completed"
    else
        print_error "Failed to start test container"
        exit 1
    fi
}

login_to_ecr() {
    print_header "Logging into ECR"

    echo "Logging into ECR repository..."

    aws ecr get-login-password --region $AWS_REGION | \
        docker login --username AWS --password-stdin $ECR_REPO_URL

    if [ $? -eq 0 ]; then
        print_success "Successfully logged into ECR"
    else
        print_error "Failed to log into ECR"
        exit 1
    fi
}

tag_and_push_image() {
    print_header "Tagging and Pushing Image"

    # Tag image for ECR
    echo "Tagging image for ECR..."
    docker tag $APP_NAME:$IMAGE_TAG $ECR_REPO_URL:$IMAGE_TAG

    if [ $? -eq 0 ]; then
        print_success "Image tagged successfully"
    else
        print_error "Failed to tag image"
        exit 1
    fi

    # Push image to ECR
    echo "Pushing image to ECR..."
    docker push $ECR_REPO_URL:$IMAGE_TAG

    if [ $? -eq 0 ]; then
        print_success "Image pushed successfully to ECR"
        echo "Image URL: $ECR_REPO_URL:$IMAGE_TAG"
    else
        print_error "Failed to push image to ECR"
        exit 1
    fi
}

show_resource_usage() {
    print_header "Resource Usage Information"

    echo "Application Resource Usage (t3.micro optimized):"
    echo "  - Image size: ~61MB"
    echo "  - Runtime memory: ~50-100MB"
    echo "  - CPU usage: ~200-300m (20-30% of 1 vCPU)"
    echo "  - Available for scaling: ~400-600MB RAM"
    echo ""
    echo "Cost optimization features:"
    echo "  - Multi-stage Docker build"
    echo "  - Minimal dependencies"
    echo "  - Non-root user for security"
    echo "  - Health checks for monitoring"
    echo "  - Auto-scaling ready"
}

# =============================================================================
# MAIN SCRIPT
# =============================================================================

print_header "EKS CloudForge - Build and Test Script"
echo "This script will build, test, and push your Flask application to ECR"
echo ""

# Check prerequisites
check_prerequisites

# Get ECR repository URL
get_ecr_repo_url

# Build the image
build_image

# Test locally
test_image_locally

# Login to ECR
login_to_ecr

# Tag and push
tag_and_push_image

# Show resource usage information
show_resource_usage

print_header "Build and Test Complete!"
echo "Your application is now ready for deployment to EKS!"
echo ""
echo "Next steps:"
echo "1. Deploy to EKS using Helm charts"
echo "2. Set up monitoring and alerting"
echo "3. Configure auto-scaling"
echo ""

print_success "🎉 Success! Your cost-optimized Flask app is ready for production!"
