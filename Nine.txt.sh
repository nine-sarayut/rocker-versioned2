docker build -t winuthayanon/cuda_4.3.0:ubuntu2204 . -f dockerfiles/cuda_4.3.0.Dockerfile
docker push winuthayanon/cuda_4.3.0:ubuntu2204
singularity pull docker://winuthayanon/cuda_4.3.0:ubuntu2204
singularity pull docker://rocker/ml

srun -p Gpu --ntasks-per-node 4 --mem 16G --nodes 1 --pty /bin/bash

export SINGULARITYENV_USER=$(id -un)
export SINGULARITYENV_PASSWORD=$(openssl rand -base64 20)
echo "user: ${SINGULARITYENV_USER}"
echo "password: ${SINGULARITYENV_PASSWORD}"

mkdir -p run var-lib-rstudio-server
printf 'provider=sqlite\ndirectory=/var/lib/rstudio-server\n' > database.conf
readonly PORT=$(python -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()')

RStudio_Server_Image=/home/sw7v6/data/singularity_cuda/cuda_4.3.0_ubuntu2204.sif

echo "ssh -N -L ${PORT}:${HOSTNAME}:${PORT} ${SINGULARITYENV_USER}@lewis42.rnet.missouri.edu"

PASSWORD=${SINGULARITYENV_PASSWORD} singularity exec \
   --bind /storage/hpc/data/sw7v6/git:/home/sw7v6/git,/storage/hpc/data/sw7v6/R:/home/sw7v6/R,run:/run,var-lib-rstudio-server:/var/lib/rstudio-server,database.conf:/etc/rstudio/database.conf \
   ${RStudio_Server_Image} \
   /usr/lib/rstudio-server/bin/rserver --www-port ${PORT} --auth-none=0 --auth-pam-helper-path=pam-helper --server-user=$(whoami) --auth-timeout-minutes=0 --auth-stay-signed-in-days=30