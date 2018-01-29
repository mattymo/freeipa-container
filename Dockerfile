# Clone from the CentOS 7
FROM centos:centos7
MAINTAINER Jan Pazdziora

ENV K8S_VERSION=v1.8.4 \
    HELM_VERSION=v2.7.2 \
    IDRAC_FILE=OM-MgmtStat-Dell-Web-LX-9.1.0-2771_A00.tar.gz

# Add artifactory centos mirror
ADD CentOS-Base.repo /etc/yum.repos.d/CentOS-Base-artifactory.repo

# Upgrade and install EPEL
RUN rm /etc/yum.repos.d/CentOS-Base.repo && \
    yum -y upgrade --disableplugin=fastestmirror  && \
    yum -y install --disableplugin=fastestmirror \
        systemd \
        systemd-libs \
        epel-release && \
    yum clean all

# Install FreeIPA client and other utils
# Additional software packages should be added here
RUN yum -y install --disableplugin=fastestmirror \
         'perl(Data::Dumper)' \
         'perl(Time::HiRes)' \
         bind-utils \
         cpanminus \
         dbus-python perl \
         dos2unix \
         elinks \
         expect \
         file \
         firefox \
         git \
         glibc.i686 \
         gnome-terminal \
         icedtea-web \
         ipa-client \
         ipmitool \
         jq \
         less \
         mailx \
         make \
         man \
         mutt \
         nano \
         openldap-clients \
         openssh-clients \
         openssh-server \
         python-pip \
         python-virtualenv \
         python2 \
         pytz \
         samba \
         samba-client \
         screen \
         socat \
         sudo \
         tree \
         unzip \
         vim \
         which \
         x2goserver \
         x2goserver-xsession \
         xinetd \
         xterm \
         zip \
         zsh && \
    yum -y groupinstall --disableplugin=fastestmirror \
         xfce \
         mate \
         "Development Tools" && \
    yum -y install --disableplugin=fastestmirror \
         https://zoom.us/client/latest/zoom_x86_64.rpm && \
    yum clean all

# IPA Client tweaks
ADD dbus.service /etc/systemd/system/dbus.service
ADD systemctl /usr/bin/systemctl
ADD ipa-client-configure-first /usr/sbin/ipa-client-configure-first
RUN ln -sf dbus.service /etc/systemd/system/messagebus.service && \
    ln -sf /bin/true /bin/hostnamectl

# Custom PE scripts
ADD scripts/dex-k8s.sh /usr/local/bin/
ADD scripts/get_token.sh /usr/local/bin/
ADD scripts/kubectl.sh /etc/profile.d/
ADD scripts/pam_set_email.sh /usr/local/sbin/

RUN echo "session    optional     pam_exec.so /usr/local/sbin/pam_set_email.sh" >> /etc/pam.d/sshd

RUN chmod -v +x /usr/bin/systemctl /usr/sbin/ipa-client-configure-first /usr/local/bin/* /usr/local/sbin/*

# Add kubectl
ADD https://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/linux/amd64/kubectl /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl

# Install helm
ADD https://kubernetes-helm.storage.googleapis.com/helm-${HELM_VERSION}-linux-amd64.tar.gz /tmp
RUN tar -zxf /tmp/helm-${HELM_VERSION}-linux-amd64.tar.gz linux-amd64/helm && \
    mv linux-amd64/helm /usr/local/bin/helm && \
    chmod +x /usr/local/bin/helm && \
    rm /tmp/helm-${HELM_VERSION}-linux-amd64.tar.gz

# iDRAC
ADD https://downloads.dell.com/FOLDER04651962M/1/${IDRAC_FILE} /tmp
RUN tar -zxf /tmp/${IDRAC_FILE} && \
    rpm --import linux/RPM-GPG-KEY && \
    find linux -type f -name "*el7*" -exec yum -y localinstall --disableplugin=fastestmirror {} + && \
    rm -r linux docs /tmp/${IDRAC_FILE}

# Reset yum repo
RUN yum reinstall -y centos-release && rm -f /etc/yum.repos.d/CentOS-Base-artifactory.repo
ENTRYPOINT /usr/sbin/ipa-client-configure-first
