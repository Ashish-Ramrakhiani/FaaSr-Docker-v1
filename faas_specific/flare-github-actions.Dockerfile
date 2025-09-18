# BASE_IMAGE is the full name of the base image e.g. rocker/geospatial:4.3.1
ARG BASE_IMAGE
# Start from specified base image
FROM $BASE_IMAGE

# FAASR_VERSION FaaSr version to install from - this must match a tag in the GitHub repository e.g. 1.2.0
ARG FAASR_VERSION
# FAASR_INSTALL_REPO is the name of the user's GitHub repository to install FaaSr from e.g. faasr/FaaSr-package
ARG FAASR_INSTALL_REPO

# Copy package list and install missing CRAN packages
COPY flare_packages.txt /tmp/required_packages.txt
RUN Rscript -e "packages <- readLines('/tmp/required_packages.txt'); cat('Installing', length(packages), 'packages...\n'); install.packages(packages, dependencies = TRUE); cat('Package installation complete.\n')"

# Install FaaSr from specified repo and tag
RUN sleep 1
RUN Rscript -e "args <- commandArgs(trailingOnly=TRUE); library(devtools); install_github(paste0(args[1],'@',args[2]),force=TRUE)" $FAASR_INSTALL_REPO $FAASR_VERSION

# Install FLARE-specific packages
RUN sleep 1
RUN Rscript -e "library(remotes); install_github('Ashish-Ramrakhiani/FLAREr@v3.1-dev', dependencies = TRUE)"

RUN sleep 1
RUN Rscript -e "library(remotes); install_github('rqthomas/GLM3r')"

# Set GLM environment variable
ENV GLM_PATH=GLM3r

# Install supporting forecast packages
RUN sleep 1
RUN Rscript -e "library(remotes); install_github('eco4cast/neon4cast')"

RUN sleep 1
RUN Rscript -e "library(remotes); install_github('eco4cast/score4cast')"

RUN sleep 1
RUN Rscript -e "library(remotes); install_github('eco4cast/read4cast')"

# Create the action directory
RUN mkdir -p /action

ADD https://raw.githubusercontent.com/FaaSr/FaaSr-package/main/schema/FaaSr.schema.json /action/
ADD https://raw.githubusercontent.com/Ashish-Ramrakhiani/FaaSr-Docker-v1/main/base/faasr_start_invoke_helper.R /action/
ADD https://raw.githubusercontent.com/Ashish-Ramrakhiani/FaaSr-Docker-v1/main/base/faasr_start_invoke_github-actions.R /action/

# GitHub Actions specifics
WORKDIR /action

CMD ["Rscript", "faasr_start_invoke_github-actions.R"]
