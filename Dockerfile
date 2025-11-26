ARG IMAGE_EXT

ARG REGISTRY=ghcr.io/epics-containers
ARG RUNTIME=${REGISTRY}/ioc-asyn${IMAGE_EXT}-runtime:4.45ec2
ARG DEVELOPER=${REGISTRY}/epics-base${IMAGE_EXT}-developer:7.0.9ec5

##### build stage ##############################################################
FROM  ${DEVELOPER} AS developer

# Get the current version of ibek if a new version is required
# COPY requirements.txt requirements.txt
# RUN uv pip install --upgrade -r requirements.txt

WORKDIR ${SOURCE_FOLDER}/ibek-support

COPY ibek-support/_ansible _ansible
ENV PATH=$PATH:${SOURCE_FOLDER}/ibek-support/_ansible

COPY ibek-support/motor/ motor/
RUN ansible.sh motor

COPY ibek-support/motorMotorSim/ motorMotorSim/
RUN ansible.sh motorMotorSim

# get the ioc source and build it
COPY ioc ${SOURCE_FOLDER}/ioc
RUN ansible.sh ioc

##### runtime preparation stage ################################################
FROM developer AS runtime_prep

# get the products from the build stage and reduce to runtime assets only
# /python is created by uv and is needed in the runtime target
RUN ibek ioc extract-runtime-assets /assets /python

##### runtime stage ############################################################
FROM ${RUNTIME} AS runtime

# get runtime assets from the preparation stage
COPY --from=runtime_prep /assets /

# install runtime system dependencies, collected from install.sh scripts
RUN ibek support apt-install-runtime-packages

# launch the startup script with stdio-expose to allow console connections
CMD ["bash", "-c", "${IOC}/start.sh"]
