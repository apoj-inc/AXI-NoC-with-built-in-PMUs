FROM ubuntu:22.04 AS build
RUN apt-get update

ENV MAIN=/home/main

WORKDIR ${MAIN}

RUN apt install wget libxext-dev libxft2 build-essential python3.10 python3.10-venv libpython3.10 -y; \
    wget https://downloads.intel.com/akdlm/software/acdsinst/24.1std/1077/ib_installers/QuestaSetup-24.1std.0.1077-linux.run 2> /dev/null; \
    chmod +x ./QuestaSetup-24.1std.0.1077-linux.run; \
    ./QuestaSetup-24.1std.0.1077-linux.run --accept_eula 1 --mode unattended --installdir /home/altera/24.1std; \
    rm QuestaSetup-24.1std.0.1077-linux.run; \
    apt purge wget -y

COPY .qsim_license .qsim_license

ENV LM_LICENSE_FILE=/home/main/.qsim_license/LR-253982_License.dat
ENV MODELSIM_BIN_DIR=/home/altera/24.1std/questa_fse/bin
ENV PATH=${PATH}:${MODELSIM_BIN_DIR}

RUN echo "LM_LICENSE_FILE=\"${LM_LICENSE_FILE}\"" >> /etc/environment; \
    echo "SALT_LICENSE_SERVER=\"${LM_LICENSE_FILE}\"" >> /etc/environment

ENTRYPOINT ["/bin/bash", "-c"]

FROM build AS test
CMD ["echo Test ready!"]

FROM build AS production
CMD ["echo Tools are ready!"]
