##### Configuration ##########################################################

# MIT License
ARG NODE_VERSION=18.8.0

ARG MAINTAINER="Nicholas Elia <me@nichelia.com>"
ARG REFRESHED_AT=2022-09-04
ARG COMPILE_USER=node
ARG RUN_USER=nobody

###############################################################################

##### Environment #############################################################

FROM node:${NODE_VERSION}-alpine  AS base

ARG MAINTAINER
ARG REFRESHED_AT
ARG COMPILE_USER

LABEL maintainer=${MAINTAINER}

# Environment variables
ENV REFRESHED_AT=${REFRESHED_AT}
ENV USER=${COMPILE_USER}
ENV BASE_DIR="/usr/src/casa-rules"
ENV APP_DIR="${BASE_DIR}/casa-rules"

# Set working directory
RUN mkdir -p ${APP_DIR} && \
    chown -R ${USER}:${USER} ${APP_DIR}
WORKDIR ${BASE_DIR}

# Install machine dependencies
RUN apk add --no-cache \
  bash \
  git

# Install node dependencies
RUN npm i -g @angular/cli@14.2.0

# -----------------------------------------------------------------------------

FROM base AS env

COPY --chown=${USER}:${USER} . ${BASE_DIR}

RUN cd ${APP_DIR} && \
    npm install && \
    ng update

WORKDIR ${APP_DIR}

# Switch Non-root user
USER ${USER}

# -----------------------------------------------------------------------------

FROM env AS compile-prod

RUN ng build

###############################################################################

##### Release #################################################################

FROM env AS dev

ENTRYPOINT ["/bin/bash", "-c", "echo $'\n\t D E V \n' && sleep 5 && npm install && ng update && exec $@"]
CMD ["/bin/bash", "-c", "ng serve --live-reload --watch --verbose --host 0.0.0.0"]

# -----------------------------------------------------------------------------

FROM base AS prod

ARG RUN_USER

ENV USER=${RUN_USER}

# Copy needed files
COPY --chown=${USER}:${USER} --from=compile-prod ${APP_DIR}/dist ${APP_DIR}/dist
COPY --chown=${USER}:${USER} --from=compile-prod ${APP_DIR}/server.js ${APP_DIR}/server.js

# Install server
RUN npm i -s express@4

# Switch Non-root user
USER ${USER}

WORKDIR ${APP_DIR}

EXPOSE 8080
CMD [ "node", "server.js" ]

###############################################################################
