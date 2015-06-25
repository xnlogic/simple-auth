FROM ruby:latest

EXPOSE 80

ENV APP_HOME /app
ENV XN_ENV production
ENV RAILS_ENV production
RUN mkdir -p /app
WORKDIR /app

COPY . /app
RUN bundle install --without 'development test'

ENTRYPOINT [ "/app/script/entrypoint.sh" ]
