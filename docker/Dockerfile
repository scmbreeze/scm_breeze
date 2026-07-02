FROM alpine:3.20

RUN apk add --no-cache \
      git \
      bash \
      zsh \
      ruby \
      grep \
      sed \
      gawk \
      coreutils \
      findutils \
      ncurses \
      shunit2 \
      patch

RUN adduser -D -s /bin/bash dev
USER dev
WORKDIR /home/dev

# install.sh appends to existing rc files only (uses `-s`, requires non-empty).
RUN printf '# scm_breeze sandbox\n' > .bashrc \
 && printf '# scm_breeze sandbox\n' > .bash_profile \
 && printf '# scm_breeze sandbox\n' > .zshrc

RUN git config --global user.name  "scm_breeze sandbox" \
 && git config --global user.email "sandbox@example.com" \
 && git config --global init.defaultBranch main

COPY --chown=dev:dev entrypoint.sh /home/dev/entrypoint.sh
RUN chmod +x /home/dev/entrypoint.sh

ENV SHELL=/bin/bash
ENTRYPOINT ["/home/dev/entrypoint.sh"]
CMD ["bash"]
