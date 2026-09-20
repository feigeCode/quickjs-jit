#!/bin/sh

build_target() {
    echo "Generating for $1"
    rustup target add "$1"
    cargo zigbuild --manifest-path sys/Cargo.toml --features=bindgen,update-bindings,logging,jit-abi,jit-test-support --target "$1"
}

# `cargo zigbuild` cannot reach the MSVC ABI, so MSVC descriptors are generated
# with plain cargo on a Windows host that has MSVC installed.
build_msvc_target() {
    echo "Generating for $1 (requires a Windows host with MSVC)"
    rustup target add "$1"
    cargo build --manifest-path sys/Cargo.toml --features=bindgen,update-bindings,logging,jit-abi,jit-test-support --target "$1"
}

copy_bindings() {
    echo "Copying bindings from $1 to $2"
    cp "sys/src/bindings/$1.rs" "sys/src/bindings/$2.rs"
}

# Generate bindings for unique size_t types only
build_target x86_64-unknown-linux-gnu    # c_ulong representative
build_target x86_64-apple-darwin         # __darwin_size_t representative  
build_target x86_64-pc-windows-gnu      # c_ulonglong representative
build_target i686-unknown-linux-gnu      # c_uint (unique)
build_target wasm32-wasip1
build_target armv7-unknown-linux-gnueabihf
build_target powerpc64-unknown-linux-gnu
build_target riscv64gc-unknown-linux-gnu

# Copy bindings for targets with same size_t as c_ulong
copy_bindings x86_64-unknown-linux-gnu aarch64-unknown-linux-gnu
copy_bindings x86_64-unknown-linux-gnu aarch64-unknown-linux-musl
copy_bindings x86_64-unknown-linux-gnu loongarch64-unknown-linux-gnu
copy_bindings x86_64-unknown-linux-gnu loongarch64-unknown-linux-musl
copy_bindings riscv64gc-unknown-linux-gnu riscv64a23-unknown-linux-gnu
copy_bindings wasm32-wasip1 wasm32-wasip1
copy_bindings x86_64-unknown-linux-gnu wasm32-wasip2
copy_bindings x86_64-unknown-linux-gnu x86_64-unknown-linux-musl

# Copy bindings for targets with same size_t as __darwin_size_t
copy_bindings x86_64-apple-darwin aarch64-apple-darwin

# Copy bindings for targets with same size_t as c_ulonglong
copy_bindings x86_64-pc-windows-gnu x86_64-pc-windows-msvc 
copy_bindings x86_64-pc-windows-gnu aarch64-pc-windows-msvc 

# 32-bit Windows has no descriptor to copy: the MSVC x86 ABI types C enums as
# `int` while every 64-bit Windows file above is generated from the mingw ABI
# and uses `unsigned int`, and the 32-bit `size_t` differs from both. CI
# regenerates it natively (see the `i686-pc-windows-msvc` entry in the
# `bindings` matrix of .github/workflows/ci.yml).
build_msvc_target i686-pc-windows-msvc

# Copy bindings for targets differing only in float ABI
copy_bindings armv7-unknown-linux-gnueabihf armv7-unknown-linux-gnueabi
