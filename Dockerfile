FROM rust:1.59.0-bullseye AS model-convert

WORKDIR /work

# convert
RUN git clone https://github.com/guillaume-be/rust-bert.git
RUN curl -o rinna-gpt2-small.bin -L "https://huggingface.co/rinna/japanese-gpt2-small/resolve/main/pytorch_model.bin"
RUN apt-get update && apt-get install -y --no-install-recommends pip
RUN pip install --no-cache-dir --upgrade pip \
    && pip install numpy torch==1.10.0 --extra-index-url https://download.pytorch.org/whl/cpu
RUN python3 ./rust-bert/utils/convert_model.py ./rinna-gpt2-small.bin

FROM ekidd/rust-musl-builder:1.57.0 AS builder

WORKDIR /app

COPY Cargo.lock Cargo.toml Cargo.lock /app/
COPY src /app/src

# libtorch
ENV LIBTORCH=/app/libtorch
ENV LD_LIBRARY_PATH=${LIBTORCH}/lib:$LD_LIBRARY_PATH
RUN curl -o libtorch.zip -L "https://download.pytorch.org/libtorch/cpu/libtorch-shared-with-deps-1.10.0%2Bcpu.zip" \
    && unzip -q libtorch.zip

RUN cargo build --release --target=x86_64-unknown-linux-musl
RUN curl -o config.json -L "https://huggingface.co/rinna/japanese-gpt2-small/resolve/main/config.json"

FROM debian:bullseye-slim AS runner

WORKDIR /app

COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/rust-bert-test /app/rust-bert-test
COPY --from=builder /app/config.json /app/config.json
COPY --from=model-convert /work/rust_model.ot /app/rust_model.ot

ENTRYPOINT ["/app/rust-bert-test"]
