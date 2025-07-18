FROM alpine:3.22

ARG PREFIX=/usr/local

# Run as user
ARG USERNAME=firehol-update-ipsets
ARG USER_UID=6721
ARG USER_GID=6721

# Create the user
RUN addgroup -g $USER_GID $USERNAME \
    && adduser -u $USER_UID --disabled-password \
       --uid $USER_UID -G $USERNAME --ingroup $USERNAME $USERNAME

# Install run-time deps
RUN apk add --no-cache bash ipset iproute2 curl unzip grep gawk lsof


# Build and install iprange (remove build deps)

ARG IPRANGE_VERSION=1.0.4
RUN apk add --no-cache --virtual .iprange_builddep autoconf automake make gcc musl-dev && \
    curl -L https://github.com/firehol/iprange/releases/download/v${IPRANGE_VERSION}/iprange-${IPRANGE_VERSION}.tar.gz | tar zvx -C /tmp && \
    cd /tmp/iprange-${IPRANGE_VERSION} && \
    ./autogen.sh && \
    ./configure --prefix=${PREFIX} --disable-man && \
    make && \
    make install && \
    cd && \
    rm -rf /tmp/iprange-${IPRANGE_VERSION} && \
    apk del  --no-cache .iprange_builddep


# Build and install firehol (remove build deps)

#ARG FIREHOL_VERSION=3.1.8
#RUN apk add --no-cache --virtual .firehol_builddep autoconf automake make && \
#    curl -L https://github.com/firehol/firehol/releases/download/v${FIREHOL_VERSION}/firehol-${FIREHOL_VERSION}.tar.gz | tar zvx -C /tmp && \

# use my fork until fixes merged
ARG FIREHOL_VERSION=5dab3e4d92945456dae49021912a06a871d68c4c
RUN apk add --no-cache --virtual .firehol_builddep autoconf automake make && \
    curl -L https://github.com/ChrisHixon/firehol/archive/${FIREHOL_VERSION}.tar.gz | tar zvx -C /tmp && \
    cd /tmp/firehol-${FIREHOL_VERSION} && \
    ./autogen.sh && \
    ./configure --prefix=${PREFIX} --disable-doc --disable-man && \
    make && \
    make install && \
    cd && \
    rm -rf /tmp/firehol-$FIREHOL_VERSION && \
    apk del  --no-cache .firehol_builddep


# Upgrade packages weekly

ARG CACHE_BUST_WEEKLY
RUN apk update && apk upgrade --no-cache && rm -rf /var/cache/apk/*

# Make sure the update-ipsets is up to date daily (contains lists which may update often)
# (Disabled for now)
#ARG CACHE_BUST_DAILY
#RUN curl -sS -o /sbin/update-ipsets \
#    'https://raw.githubusercontent.com/firehol/firehol/master/sbin/update-ipsets'


# Switch to user

ENV HOME=/home/$USERNAME
ENV PATH=$HOME/bin:$PATH
WORKDIR $HOME
USER $USERNAME

