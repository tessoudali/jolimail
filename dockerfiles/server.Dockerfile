ARG BUILD_TAG=master
FROM jdrouet/jolimail:$BUILD_TAG-client AS client-image

FROM rust:1-slim-buster AS server-builder

RUN apt-get update -y \
  && apt-get install -y curl make pkg-config libssl-dev \
  && rm -rf /var/lib/apt/lists/*

ENV USER=root

WORKDIR /code
RUN cargo init
COPY server/Cargo.toml /code/Cargo.toml
RUN cargo fetch

COPY server/src /code/src

RUN cargo build --release --offline

FROM debian:buster-slim

RUN apt-get update \
  && apt-get install -y ca-certificates libssl1.1 \
  && rm -rf /var/lib/apt/lists/*

ENV ADDRESS=0.0.0.0
ENV CLIENT_PATH=/client
ENV MIGRATION_PATH=/migrations
ENV PORT=3000
ENV RUST_LOG=info

COPY --from=client-image /static /client
COPY server/migrations /migrations
COPY --from=server-builder /code/target/release/jolimail /usr/bin/jolimail

EXPOSE 3000

ENTRYPOINT [ "/usr/bin/jolimail" ]
