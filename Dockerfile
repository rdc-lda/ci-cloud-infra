FROM alpine:3.9

RUN apk update
RUN apk -Uuv add bash ca-certificates openssl git openssh util-linux && \
    rm /var/cache/apk/*

# Install aws-cli for CloudFormation
RUN apk -Uuv add groff less python py-pip && \
    pip install awscli && \
    apk --purge -v del py-pip && \
    rm /var/cache/apk/*

# Install JQ
RUN apk -Uuv add jq && \
    rm /var/cache/apk/*

# Add the libs
ADD src/func.bash /usr/share/misc/func.bash
ADD src/aws-func.bash /usr/share/misc/aws-func.bash
# ADD src/gce-func.bash /usr/share/misc/gce-func.bash
# ADD src/azure-func.bash /usr/share/misc/azure-func.bash

# Add the templates
ADD templates/ /usr/share/misc/

# Add the main scripts
ADD src/cloud-infra.bash /usr/bin/cloud-infra

# AWS Cloud resources
ADD src/aws-cloud-infra.bash /usr/bin/aws-cloud-infra

# Google Cloud resources
# ADD src/gce-cloud-infra.bash /usr/bin/gce-cloud-infra

# Azure Cloud resources
# ADD src/azure-cloud-infra.bash /usr/bin/azure-cloud-infra

RUN chmod a+x /usr/bin/*-infra