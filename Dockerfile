# This is the build stage for kylin-collator. Here we create the binary in a temporary image.
#FROM docker.io/paritytech/ci-linux:production as builder
FROM rust:1.61-slim as builder

WORKDIR /kylin-collator
COPY . /kylin-collator
RUN export http_proxy='http://127.0.0.1:1081'
RUN export https_proxy='https://127.0.0.1:1081' 
RUN apt-get update && apt-get install -y git cmake pkg-config libssl-dev git clang libclang-dev
RUN rustup default nightly && rustup target add wasm32-unknown-unknown
RUN cargo build --release

# This is the 2nd stage: a very small image where we copy the kylin-collator binary."
# FROM docker.io/library/ubuntu:20.04
FROM debian:bullseye-slim

LABEL description="Multistage Docker image for kylin-collator: Data certification for web3" \
	io.parity.image.type="builder" \
	io.parity.image.authors="chevdor@gmail.com, devops-team@parity.io" \
	io.parity.image.vendor="Parity Technologies" \
	io.parity.image.description="kylin-collator:  Data certification for web3" \
	io.parity.image.source="https://github.com/paritytech/kylin-collator/blob/${VCS_REF}/Dockerfile" \
	io.parity.image.documentation="https://github.com/kylinnetwork/kylin-collator/"

COPY --from=builder /kylin-collator/target/release/kylin-collator /usr/local/bin
COPY --from=builder /kylin-collator/pichiu-rococo-parachain-2102.json .
COPY --from=builder /kylin-collator/rococo.json .

RUN apt-get update && apt-get install -y ca-certificates
RUN update-ca-certificates
RUN mkdir -p /data /kylin-collator/.local/share && \
	ln -s /data /kylin-collator/.local/share/kylin-collator && \
# check if executable works in this container
	/usr/local/bin/kylin-collator --version

EXPOSE 40333 9977 8844 9615 
VOLUME ["/data"]

ENTRYPOINT ["/usr/local/bin/kylin-collator"]
