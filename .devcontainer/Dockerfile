FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Install prerequisites for Homebrew on Linux and general development.
# See: https://docs.brew.sh/Homebrew-on-Linux
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    file \
    git \
    gnupg \
    locales \
    make \
    procps \
    sudo \
    zsh \
    && rm -rf /var/lib/apt/lists/*

# Create the non-root user expected by VS Code dev containers.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=${USER_UID}
RUN if getent group ${USER_GID} >/dev/null; then \
    existing_group=$(getent group ${USER_GID} | cut -d: -f1); \
    groupmod -n ${USERNAME} "${existing_group}"; \
    else \
    groupadd --gid ${USER_GID} ${USERNAME}; \
    fi \
    && if id -u ${USER_UID} >/dev/null 2>&1; then \
    existing_user=$(getent passwd ${USER_UID} | cut -d: -f1); \
    usermod -l ${USERNAME} -d /home/${USERNAME} -m "${existing_user}"; \
    else \
    useradd --uid ${USER_UID} --gid ${USER_GID} --shell /usr/bin/zsh --create-home ${USERNAME}; \
    fi \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME} \
    && chsh -s /usr/bin/zsh ${USERNAME}

USER ${USERNAME}
WORKDIR /home/${USERNAME}

# Default shell for subsequent commands and interactive sessions.
SHELL ["/usr/bin/zsh", "-c"]
