# Multi-stage Dockerfile for SharePoint Framework development
FROM node:14-bullseye as base

# Set working directory
WORKDIR /workspace

# Install system dependencies for SharePoint Framework
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    vim \
    bash-completion \
    && rm -rf /var/lib/apt/lists/*

# Install global npm packages for SPFx development
RUN npm install -g --force \
    gulp@4.0.2 \
    yo \
    @microsoft/generator-sharepoint \
    pnpm

# Development stage
FROM base as development

# Set environment variables
ENV NODE_ENV=development
ENV SPFX_SERVE_NOBROWSER=true

# Create a non-root user for development
RUN useradd -m -s /bin/bash spfxdev && \
    chown -R spfxdev:spfxdev /workspace

USER spfxdev

# Expose SharePoint Framework development server port
EXPOSE 4321 5432 35729

# Default command to keep container running
CMD ["bash"]

# Production/Build stage
FROM base as production

# Copy project files
COPY --chown=node:node . /workspace/

# Install dependencies using pnpm
RUN cd /workspace/SharePointFramework/@Shared && \
    pnpm install --shamefully-hoist && \
    pnpm run build

RUN cd /workspace/SharePointFramework/ProjectWebParts && \
    pnpm install --shamefully-hoist

RUN cd /workspace/SharePointFramework/PortfolioWebParts && \
    pnpm install --shamefully-hoist

RUN cd /workspace/SharePointFramework/ProjectExtensions && \
    pnpm install --shamefully-hoist

USER node

CMD ["bash"]
