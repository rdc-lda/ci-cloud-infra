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

# Add the templates
ADD templates/ /usr/share/misc/

# Add the main scripts
ADD src/sempl.bash /usr/bin/sempl
ADD src/func.bash /usr/share/misc/func.bash
ADD src/infra-template.bash /usr/bin/cloud-infra
ADD src/infra-template.bash /usr/bin/openshift-infra
ADD src/infra-template.bash /usr/bin/channel-middleware-infra
ADD src/infra-template.bash /usr/bin/backend-middleware-infra

# AWS Cloud resources
ADD src/aws/aws-func.bash /usr/share/misc/aws-func.bash
ADD src/aws/aws-cloud-infra.bash /usr/bin/aws-cloud-infra
ADD src/aws/aws-openshift-infra.bash /usr/bin/aws-openshift-infra
ADD src/aws/aws-channel-middleware-infra.bash /usr/bin/aws-channel-middleware-infra
ADD src/aws/aws-backend-middleware-infra.bash /usr/bin/aws-backend-middleware-infra

# Google Cloud resources
# ADD src/gce/gce-func.bash /usr/share/misc/gce-func.bash
# ADD src/gce/gce-cloud-infra.bash /usr/bin/gce-cloud-infra

# Azure Cloud resources
# ADD src/azure/azure-func.bash /usr/share/misc/azure-func.bash
# ADD src/azure/azure-cloud-infra.bash /usr/bin/azure-cloud-infra

RUN chmod a+x /usr/bin/*-infra /usr/bin/sempl