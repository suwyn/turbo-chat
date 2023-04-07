FROM jruby:9

RUN groupadd appuser && useradd -m -g appuser appuser

RUN apt-get update \
  && apt-get install netbase \
  && rm -rf /var/lib/apt/lists/*

USER appuser
RUN mkdir -p /home/appuser/src
WORKDIR /home/appuser/src

ARG rails_env='production'
ARG bundle_without='development test'
ARG skip_precompile

ENV RUBY_YJIT_ENABLE=1 \
  BUNDLE_RETRY=5 \
  RAILS_ENV=${rails_env} \
  BUNDLE_SILENCE_ROOT_WARNING=1 \
  RAILS_LOG_TO_STDOUT=true \
  BUNDLE_WITHOUT=${bundle_without}

COPY --chown=appuser:appuser .ruby-version Gemfile Gemfile.lock ./
RUN gem install bundler -v 2.4.4 \
  && bundle install

COPY --chown=appuser:appuser . ./

RUN if [ -z "${skip_precompile}" ]; then \
  SECRET_KEY_BASE=1 bundle exec rails assets:precompile; \
fi

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "5000"]
