FROM buildpack-deps:bullseye AS builder

USER root

ARG home=/root
ARG downloads=${home}/downloads
ARG ncpus=4

RUN apt-get update \
    && apt-get install -y \
    build-essential \
    cmake \
    cpio \
    && rm -rf /var/lib/apt/lists/*

############# NCBI-BLAST

ARG prefix_blast=/opt/blast
WORKDIR ${downloads}
RUN \curl -L \
    https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.12.0/ncbi-blast-2.12.0+-x64-linux.tar.gz \
    | tar xz
RUN mkdir -p ${prefix_blast}/bin
RUN mv ncbi-blast-2.12.0+/bin/rpsblast ${prefix_blast}/bin/rpsblast+
RUN mv ncbi-blast-2.12.0+/bin/makeprofiledb ${prefix_blast}/bin/makeprofiledb

################ MAFFT

ARG prefix_mafft=/opt/mafft
ENV APP_VERSION_MAFFT 7.490
WORKDIR ${downloads}
RUN \curl https://mafft.cbrc.jp/alignment/software/mafft-${APP_VERSION_MAFFT}-without-extensions-src.tgz | \
    tar xz
WORKDIR mafft-${APP_VERSION_MAFFT}-without-extensions/core
RUN sed -ibackup 's~PREFIX = /usr/local~PREFIX = /opt/mafft~' Makefile
RUN make -j${ncpus}
RUN make install

############## MMseqs2

ARG prefix_mmseqs=/opt/mmseqs
RUN git clone https://github.com/soedinglab/MMseqs2.git
WORKDIR MMseqs2
RUN git checkout tags/13-45111 -b 13-45111
WORKDIR build
RUN cmake -DCMAKE_BUILD_TYPE=RELEASE -DCMAKE_INSTALL_PREFIX=${prefix_mmseqs} ..
RUN make -j${ncpus}
RUN make install

################ Download InteinFinder

RUN \curl -L \
    https://github.com/mooreryan/InteinFinder/releases/download/1.0.0-SNAPSHOT-7a303c7/InteinFinder-linux.tar.gz \
    | tar xz
RUN mv InteinFinder-linux/InteinFinder /usr/local/bin
RUN chmod +x /usr/local/bin/InteinFinder

################ Now, setup the final image

FROM debian:bullseye-slim

USER root

# libgomp needed for blast
# libatomic needed for mmseqs
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    libatomic1 \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

ARG prefix_blast=/opt/blast
ARG prefix_mafft=/opt/mafft
ARG prefix_mmseqs=/opt/mmseqs

COPY --from=builder ${prefix_blast} ${prefix_blast}
COPY --from=builder ${prefix_mafft} ${prefix_mafft}
COPY --from=builder ${prefix_mmseqs} ${prefix_mmseqs}
COPY --from=builder /usr/local/bin/InteinFinder /usr/local/bin

ENV PATH "${PATH}:${prefix_blast}/bin"
ENV PATH "${PATH}:${prefix_mafft}/bin"
ENV PATH "${PATH}:${prefix_mmseqs}/bin"

RUN addgroup --system intein_finder \
    && adduser --system --disabled-password --shell /bin/sh \
    --ingroup intein_finder intein_finder \
    && echo 'intein_finder ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

USER intein_finder
WORKDIR /home/intein_finder

ENTRYPOINT [ "/usr/local/bin/InteinFinder" ]
