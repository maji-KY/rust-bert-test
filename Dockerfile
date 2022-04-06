FROM rust:1.59.0-bullseye AS model-convert

WORKDIR /work

RUN apt-get update && apt-get install -y --no-install-recommends pip
RUN pip install --no-cache-dir --upgrade pip \
    && pip install numpy torch==1.10.0 --extra-index-url https://download.pytorch.org/whl/cpu
RUN git clone https://github.com/guillaume-be/rust-bert.git \
    && curl -o rinna-gpt2-small.bin -L "https://huggingface.co/rinna/japanese-gpt2-small/resolve/main/pytorch_model.bin" \
    && python3 ./rust-bert/utils/convert_model.py ./rinna-gpt2-small.bin \
    && rm -rf rust-bert \
    && rm rinna-gpt2-small.bin

FROM rust:1.59.0-bullseye AS builder

WORKDIR /app

# libtorch
RUN curl -o libtorch.zip -L "https://download.pytorch.org/libtorch/cpu/libtorch-cxx11-abi-shared-with-deps-1.10.0%2Bcpu.zip" \
    && unzip -q libtorch.zip \
    && cp -r libtorch/include/* /usr/local/include/ \
    && cp -r libtorch/lib/* /usr/local/lib/ \
    && cp -r libtorch/share/* /usr/local/share/ \
    && ldconfig

COPY Cargo.lock Cargo.toml Cargo.lock /app/
COPY src /app/src

RUN cargo build --release
RUN curl -o config.json -L "https://huggingface.co/rinna/japanese-gpt2-small/resolve/main/config.json" \
    && curl -o vocab.json -L "https://huggingface.co/gpt2-medium/resolve/main/vocab.json" \
    && curl -o merges.txt -L "https://huggingface.co/gpt2-medium/resolve/main/merges.txt"

FROM debian:bullseye-slim AS runner

WORKDIR /app

COPY --from=builder /app/libtorch/include/* /usr/local/include/
COPY --from=builder /app/libtorch/lib/* /usr/local/lib/
COPY --from=builder /app/libtorch/share/* /usr/local/share/
RUN ldconfig

COPY --from=model-convert /work/rust_model.ot /app/rust_model.ot
COPY --from=builder /app/config.json /app/config.json
COPY --from=builder /app/vocab.json /app/vocab.json
COPY --from=builder /app/merges.txt /app/merges.txt
COPY --from=builder /app/target/release/rust-bert-test /app/rust-bert-test

ENTRYPOINT ["/app/rust-bert-test"]
