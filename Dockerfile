# Clone from the CentOS 7
FROM centos:centos7

MAINTAINER Jan Pazdziora

#Add kubectl
ADD https://storage.googleapis.com/kubernetes-release/release/v1.8.3/bin/linux/amd64/kubectl /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl

RUN yum -y install systemd systemd-libs epel-release && yum clean all

# Install FreeIPA client and other utils
RUN yum install -y ipa-client dbus-python perl 'perl(Data::Dumper)' \
    'perl(Time::HiRes)' openssh-clients openssh-server openldap-clients \
    sudo less which jq screen vim xterm \
    git xinetd socat make dos2unix httpd nano elinks pytz glibc.i686 zip \
    unzip cpanminus file mailx mutt bind-utils vim python2 python-pip \
    python-virtualenv samba samba-client expect ipmitool \
    x2goserver x2goserver-xsession firefox icedtea-web gnome-terminal && \
    yum groupinstall -y xfce mate "Development Tools" && \
    yum install -y https://zoom.us/client/latest/zoom_x86_64.rpm && \
    yum clean all

# Install helm
RUN curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash

ADD dbus.service /etc/systemd/system/dbus.service
RUN ln -sf dbus.service /etc/systemd/system/messagebus.service
RUN ln -sf /bin/true /bin/hostnamectl

ADD systemctl /usr/bin/systemctl
ADD ipa-client-configure-first /usr/sbin/ipa-client-configure-first

ADD scripts/dex-k8s.sh /usr/local/bin/
ADD scripts/get_token.sh /usr/local/bin/
ADD scripts/kubectl.sh /etc/profile.d/
ADD scripts/pam_set_email.sh /usr/local/sbin/

RUN echo "session    optional     pam_exec.so /usr/local/sbin/pam_set_email.sh" >> /etc/pam.d/sshd

RUN chmod -v +x /usr/bin/systemctl /usr/sbin/ipa-client-configure-first /usr/local/bin/* /usr/local/sbin/*

ENTRYPOINT /usr/sbin/ipa-client-configure-first
