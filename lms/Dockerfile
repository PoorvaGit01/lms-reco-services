# syntax = docker/dockerfile:1

ARG RUBY_VERSION=3.2.0
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client build-essential git libpq-dev libyaml-dev pkg-config gosu && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Create rails user first so bundle install can use it
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash

# Set development environment
ENV RAILS_ENV="development" \
    BUNDLE_PATH="/usr/local/bundle" \
    PATH="/usr/local/bundle/bin:$PATH"

# Install application gems as rails user
COPY Gemfile Gemfile.lock ./
RUN mkdir -p /usr/local/bundle && \
    chown -R rails:rails /usr/local/bundle && \
    su rails -c "bundle install"

# Copy application code
COPY . .

# Set ownership of application files
RUN chown -R rails:rails db log storage tmp /rails

# Note: We don't set USER here because docker-compose.yml will run commands as root
# and use gosu to switch to rails user when needed

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default
EXPOSE 3000
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
