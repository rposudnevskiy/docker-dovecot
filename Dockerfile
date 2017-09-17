FROM centos:latest

RUN yum install -y dovecot dovecot-mysql

COPY conf /etc/dovecot

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

CMD ["bash"]
