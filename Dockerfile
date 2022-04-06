FROM rust:1.59.0-bullseye AS model-convert

WORKDIR /work

# libtorch
RUN curl -o libtorch.zip -L "https://download.pytorch.org/libtorch/cpu/libtorch-cxx11-abi-shared-with-deps-1.11.0%2Bcpu.zip" \
    && unzip -q libtorch.zip \
    && cp -r libtorch/include/* /usr/local/include/ \
    && cp -r libtorch/lib/* /usr/local/lib/ \
    && cp -r libtorch/share/* /usr/local/share/ \
    && ldconfig

# convert
RUN git clone https://github.com/guillaume-be/rust-bert.git
RUN curl -o rinna-gpt2-small.bin -L "https://huggingface.co/rinna/japanese-gpt2-small/resolve/main/pytorch_model.bin"
RUN apt-get update && apt-get install -y --no-install-recommends pip
RUN pip install --no-cache-dir --upgrade pip \
    && pip install numpy torch --extra-index-url https://download.pytorch.org/whl/cpu
RUN python3 ./rust-bert/utils/convert_model.py ./rinna-gpt2-small.bin

ENTRYPOINT ["/bin/bash"]
