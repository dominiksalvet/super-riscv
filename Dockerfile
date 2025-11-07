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

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt-get install -y git make verilator gcc g++ libz-dev gcc-riscv64-unknown-elf texinfo

RUN git clone https://sourceware.org/git/newlib-cygwin.git /tmp/newlib-cygwin
WORKDIR /tmp/newlib-cygwin/build
RUN git checkout newlib-4.5.0
RUN ../configure --target=riscv64-unknown-elf --prefix=/opt/newlib
RUN make -j$(nproc)
RUN make install

WORKDIR /
RUN rm -rf /tmp/newlib-cygwin
