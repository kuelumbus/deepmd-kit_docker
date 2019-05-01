FROM nvidia/cuda:9.0-cudnn7-devel-centos7
LABEL maintainer "Christopher Kuenneth christopher.kuenneth@mse.gatech.edu"
# For now, only CentOS-Base.repo (USTC source, only users in China mainland should use it) and bazel.repo are in 'repo' directory with version 0.13.1. The latest version of bazel may bring failures to the installment.
COPY repo/*repo /etc/yum.repos.d/

# Add additional source to yum
RUN yum makecache && yum install -y epel-release \
    centos-release-scl 
RUN rpm --import /etc/pki/rpm-gpg/RPM*

# bazel, gcc, gcc-c++ and path are needed by tensorflow;   
# autoconf, automake, cmake, libtool, make, wget are needed for protobut et. al.;  
# epel-release, cmake3, centos-release-scl, devtoolset-4-gcc*, scl-utils are needed for deepmd-kit(need gcc5.x);
# unzip are needed by download_dependencies.sh.
RUN yum install -y automake \
    autoconf \
    bzip \
    bzip2 \
    cmake \
    cmake3 \
    devtoolset-4-gcc* \
    git \
    gcc \
    gcc-c++ \
    libtool \
    make \
    patch \
    scl-utils \
    unzip \
    vim \
    wget \
    openmpi-devel \
    python36-devel \
    texlive \
    texlive-dvipng && \
    rm -rf /var/cache/yum/* && \
    ln -s /usr/lib64/openmpi/bin/mpi* /usr/bin/
ENV tensorflow_root=/opt/tensorflow xdrfile_root=/opt/xdrfile \
    deepmd_root=/opt/deepmd deepmd_source_dir=/root/deepmd-kit \
    PATH="/opt/conda3/bin:${PATH}"
ARG tensorflow_version=1.8
ENV tensorflow_version=$tensorflow_version

# If download lammps with git, there will be errors during installion. Hence we'll download lammps later on.
RUN cd /root && \
    git clone https://github.com/deepmodeling/deepmd-kit.git deepmd-kit && \
    git clone https://github.com/tensorflow/tensorflow tensorflow -b "r$tensorflow_version" --depth=1 && \
    cd tensorflow
# install bazel for version 0.13.1
RUN wget https://github.com/bazelbuild/bazel/releases/download/0.13.1/bazel-0.13.1-installer-linux-x86_64.sh && \
    bash bazel-0.13.1-installer-linux-x86_64.sh

# install tensorflow C lib
COPY install_input /root/tensorflow

# libcuda.so.1 is required for compilaton
RUN ln -s /usr/local/cuda/lib64/stubs/libcuda.so /lib/libcuda.so.1 && \
    ldconfig && \
    cd /root/tensorflow && \
    ./configure < install_input && \
    bazel build --config=opt --config=cuda \
    --verbose_failures //tensorflow:libtensorflow_cc.so

# install the dependencies of tensorflow and xdrfile
COPY install_protobuf.sh install_eigen.sh install_nsync.sh install_xdrfile.sh copy_lib.sh /root/
RUN cd /root/tensorflow && tensorflow/contrib/makefile/download_dependencies.sh && \
    cd /root && sh -x install_protobuf.sh && sh -x install_eigen.sh && \
    sh -x install_nsync.sh && sh -x copy_lib.sh && sh -x install_xdrfile.sh 
# `source /opt/rh/devtoolset-4/enable` to set gcc version to 5.x, which is needed by deepmd-kit.

# install deepmd
COPY install_deepmd.sh /root/
RUN cd /root && source /opt/rh/devtoolset-4/enable && \ 
    sh -x install_deepmd.sh

# install lammps
COPY install_lammps.sh /root/
RUN cd /root && wget https://github.com/lammps/lammps/archive/stable.zip && \
    unzip stable.zip && source /opt/rh/devtoolset-4/enable && sh -x install_lammps.sh

ENV PATH="/opt/deepmd/bin:/root/lammps-stable/src:${PATH}"

# Install python lammps interface 
ENV PYTHONPATH="/root/lammps-stable/python:${PYTHONPATH}"
ENV LD_LIBRARY_PATH="/root/lammps-stable/src:${LD_LIBRARY_PATH}"

RUN wget https://bootstrap.pypa.io/get-pip.py && \
    python3.6 get-pip.py && \
    pip3.6 install numpy && \
    pip3.6 install phonoLAMMPS phonopy seekpath

# Input files must be in te /app directory to use them
WORKDIR /app

CMD ["/bin/bash"]
