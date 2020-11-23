FROM ruby:2.7

RUN groupadd -r buildkite-agent && useradd -u 9999 -r -g buildkite-agent -G audio,video -d /home/gusto buildkite-agent

WORKDIR /home/gusto
ADD . /home/gusto/
RUN chown -R buildkite-agent /home/gusto
USER buildkite-agent

RUN bundle install
RUN gem build data_migrate.gemspec