TAG = $(shell git describe --tags --always)
PREFIX = rdclda
REPO_NAME = ci-cloud-infra

all: push

container: image

image:
	# Build new image and automatically tag it as latest
	docker build -t $(PREFIX)/$(REPO_NAME) .
	
	# Add the version tag to the latest image	
	docker tag $(PREFIX)/$(REPO_NAME) $(PREFIX)/$(REPO_NAME):$(TAG)

push: image
	# Push image tagged as latest to repository
	docker push $(PREFIX)/$(REPO_NAME)

	# Push version tagged image to repository 
	#  -- since this image is already pushed it will simply create or update version tag
	docker push $(PREFIX)/$(REPO_NAME):$(TAG)