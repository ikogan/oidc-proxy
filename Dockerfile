FROM centos:7

RUN yum -y upgrade; \
    yum -y install epel-release; \
    yum -y install httpd mod_ssl wget

ARG MOD_AUTH_OPENIDC_VERSION=2.3.11

ARG CJOSE_HASH=42974ee0d332c3d302f66ddacb0e344ce96c35d42182cf24a47dde248466b3c0
ARG MOD_AUTH_OPENIDC_HASH=721147a8244071e5fdd05d5e8e99049e3b46ff0df13e427bf60afe35c0ad0492

WORKDIR /root

RUN wget $(curl https://api.github.com/repos/zmartzone/mod_auth_openidc/releases/tags/v${MOD_AUTH_OPENIDC_VERSION} | \
           egrep http.*cjose-.*el7.*rpm | awk '{ print $2 }' | sed 's/"//g') && \
    wget https://github.com/zmartzone/mod_auth_openidc/releases/download/v${MOD_AUTH_OPENIDC_VERSION}/mod_auth_openidc-${MOD_AUTH_OPENIDC_VERSION}-1.el7.x86_64.rpm && \
    (echo "${CJOSE_HASH}  $(ls cjose*.rpm)" | sha256sum -c -) || \
        (sha256sum  $(ls /root/cjose*.rpm) && exit 1) && \
    (echo "${MOD_AUTH_OPENIDC_HASH}  $(ls mod_auth_openidc*.rpm)" | sha256sum -c -) || \
        (sha256sum  $(ls /root/mod_auth_openidc*.rpm) && exit 1) && \
    yum -y install /root/*.rpm && \
    rm -Rf /root/*.rpm && yum clean all


ARG J2TMPL_VERSION=0.0.8
ARG J2TMPL_HASH=bf563b4a0661fed586c4c6b1856d9b917082c3b000af7a11276f9f33a6d62cca

RUN wget https://github.com/ikogan/j2tmpl/releases/download/v${J2TMPL_VERSION}/j2tmpl -O /usr/bin/j2tmpl && chmod +x /usr/bin/j2tmpl
RUN (echo "${J2TMPL_HASH}  /usr/bin/j2tmpl" | sha256sum -c -) || (sha256sum /usr/bin/j2tmpl && exit 1)

COPY startup.sh /usr/sbin/proxy
RUN chmod +x /usr/sbin/proxy

COPY templates /usr/share/oidc-proxy/templates

EXPOSE 80
EXPOSE 443

ENTRYPOINT ["/usr/sbin/proxy"]
