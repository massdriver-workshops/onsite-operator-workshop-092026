FROM ubuntu:24.04

# provisioner-echo. Touches no cloud. Prints what a provisioner step receives.
# Layout follows https://docs.massdriver.cloud/platform-operations/self-hosted/custom-provisioners

# Install your required tools
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates jq adduser && \
    rm -rf /var/lib/apt/lists/*

# Create the working dir
RUN mkdir -p -m 777 /massdriver

# Add the Massdriver user. This is the default user provisioners run as.
RUN adduser --disabled-password --gecos "" --uid 10001 massdriver && \
    chown -R massdriver:massdriver /massdriver

# The workflow orchestrator calls entrypoint.sh; keep it on the PATH.
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /massdriver
USER massdriver

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
