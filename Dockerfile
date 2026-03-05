#
#   Super RISC-V - superscalar dual-issue RISC-V processor
#   Copyright (C) 2025 Dominik Salvet
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

# stage 1
FROM ubuntu:24.04 AS newlib_build

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt-get install -y git make gcc gcc-riscv64-unknown-elf texinfo

RUN git clone https://sourceware.org/git/newlib-cygwin.git /tmp/newlib-cygwin
WORKDIR /tmp/newlib-cygwin/build
RUN git checkout newlib-4.5.0
RUN ../configure --target=riscv64-unknown-elf --prefix=/opt/newlib --disable-multilib --with-arch=rv32i --with-abi=ilp32
RUN make CFLAGS_FOR_TARGET="-O2 -march=rv32i -mabi=ilp32" -j $(nproc)
RUN make install

# stage 2
FROM ubuntu:24.04 AS super_riscv_env

ENV DEBIAN_FRONTEND=noninteractive NEWLIB_LIB=/opt/newlib/riscv64-unknown-elf/lib

RUN apt-get update && \
    apt-get install -y --no-install-recommends git ca-certificates make verilator g++ libz-dev gcc-riscv64-unknown-elf && \
    rm -rf /var/lib/apt/lists/*

COPY --from=newlib_build /opt/newlib /opt/newlib
