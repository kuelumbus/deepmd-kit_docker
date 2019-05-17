# Docker image for DeePMD-kit (CPU & GPU)
[DeePMD-kit](https://github.com/deepmodeling/deepmd-kit#run-md-with-native-code) is a deep learning package for many-body potential energy representation, optimization, and molecular dynamics. 

This docker project is set up to simplify the installation process of DeePMD-kit.

Features
- Tensorflow works with CPU & GPU
- MPI version of Lammps

## Build the image
```bash
git clone https://github.com/kuelumbus/docker-deepmd-kit.git
cd deepmd-kit_docker && docker build -f Dockerfile -t deepmd-gpu .
```
The `ENV` statement in Dockerfile sets the install prefix of packages. These environment variables can be set by users themselves.

The `ARG tensorflow_version` specifies the version of tensorflow to install, which can be set during the build command through `--build-arg tensorflow_version=1.8`.

The [nvidia runtime](https://github.com/NVIDIA/nvidia-docker) for docker (`--runtime=nvidia` switch) must be installed to run the container.

## Run the container

A bash executable to run `dp_train | dp_test | dp_frz` should look like (e.g. `dp_train in.json`)
```bash
#!/bin/bash
docker run -it --rm  \
    --runtime=nvidia \
    --mount type=bind,source="$(pwd)",target=/app \
    -e CUDA_VISIBLE_DEVICES="$1" \
    deepmd-gpu:latest \
    dp_train ${@:2} 
```
Similar for lammps run as (`lmp_mpi n_cores -in in.lammps`). Make sure predictions during the lammps run are done on the CPU and not GPU by setting `CUDA_VISIBLE_DEVICES=""` - I am not sure if this is necessary.
```bash
#!/bin/bash
docker run -it --rm  \
    --runtime=nvidia \
    --mount type=bind,source="$(pwd)",target=/app \
    -e CUDA_VISIBLE_DEVICES="" \
    deepmd-gpu:latest \
    mpiexec --allow-run-as-root -n $1 lmp_mpi ${@:2}
```
The mount argument binds the current directory to `/app` in the docker container and thus must be executed in the directory with the `input json` file. 

 





