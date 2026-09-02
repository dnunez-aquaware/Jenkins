FROM jenkins/jenkins:lts

USER root

ARG DOCKER_GID=999

RUN apt-get update \
    && apt-get install -y ca-certificates curl unzip \
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg \
       -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian trixie stable" \
       > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y docker-ce-cli docker-compose-plugin \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
       -o "/tmp/awscliv2.zip" \
    && unzip /tmp/awscliv2.zip -d /tmp \
    && /tmp/aws/install \
    && rm -rf /tmp/aws /tmp/awscliv2.zip \
    && curl -fsSL \
       https://releases.hashicorp.com/terraform/1.13.3/terraform_1.13.3_linux_amd64.zip \
       -o /tmp/terraform.zip \
    && unzip /tmp/terraform.zip -d /usr/local/bin \
    && rm -f /tmp/terraform.zip \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -g ${DOCKER_GID} docker \
    && usermod -aG docker jenkins

USER jenkins

RUN jenkins-plugin-cli --plugins \
    configuration-as-code \
    job-dsl \
    workflow-aggregator \
    matrix-auth