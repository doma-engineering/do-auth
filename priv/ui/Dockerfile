FROM node:17-alpine
RUN adduser -D user
WORKDIR /home/user
COPY --chown=user:user . /home/user/
RUN su user
RUN cd /home/user

EXPOSE 3000

ENTRYPOINT node --require tsm ./run.ts SimpleRegister.tsx
