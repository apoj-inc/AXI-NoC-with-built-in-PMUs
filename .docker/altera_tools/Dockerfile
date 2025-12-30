FROM alpine:latest AS build
RUN apt-get update

ENV MAIN=/home/main

WORKDIR ${MAIN}

RUN apt install wget -y
RUN wget https://downloads.intel.com/akdlm/software/acdsinst/24.1std/1077/ib_installers/QuestaSetup-24.1std.0.1077-linux.run 2> /dev/null
RUN chmod +x ./QuestaSetup-24.1std.0.1077-linux.run
RUN ./QuestaSetup-24.1std.0.1077-linux.run --accept_eula 1 --mode unattended --installdir /home/altera/24.1std
RUN rm QuestaSetup-24.1std.0.1077-linux.run

RUN apt install build-essential python3.10 python3.10-venv libpython3.10 -y

COPY .qsim_license .qsim_license

RUN apt install vish libxext-dev libx11-dev libxft2 vis -y

ENV LM_LICENSE_FILE=/home/main/.qsim_license/LR-253982_License.dat
ENV MODELSIM_BIN_DIR=/home/altera/24.1std/questa_fse/bin

ENV PATH=${PATH}:${MODELSIM_BIN_DIR}
RUN echo "LM_LICENSE_FILE=\"${LM_LICENSE_FILE}\"" >> /etc/environment
RUN echo "SALT_LICENSE_SERVER=\"${LM_LICENSE_FILE}\"" >> /etc/environment

ENTRYPOINT ["/bin/bash", "-c"]
CMD ["echo Tools are ready!"]

FROM build AS test

FROM build AS production
