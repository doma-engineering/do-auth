FROM node:17
RUN apt update
RUN apt install -y netcat-openbsd
RUN useradd -m user
WORKDIR /home/user
COPY --chown=user:user . /home/user/
RUN su user
RUN cd /home/user
RUN node --require tsm ./run.ts SimpleRegister.tsx build
