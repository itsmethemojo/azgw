FROM buildkite/puppeteer:v1.15.0

COPY src/index.js /app/

WORKDIR /app

CMD node /app/index.js
