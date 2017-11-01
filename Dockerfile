# Clone from the CentOS 7
FROM centos:centos7

MAINTAINER Jan Pazdziora

RUN yum swap -y -- remove fakesystemd -- install systemd systemd-libs && yum clean all

# Install FreeIPA client
RUN yum install -y ipa-client dbus-python perl 'perl(Data::Dumper)' 'perl(Time::HiRes)' openssh-clients openssh-server openldap-clients && yum clean all

ADD dbus.service /etc/systemd/system/dbus.service
RUN ln -sf dbus.service /etc/systemd/system/messagebus.service
RUN ln -sf /bin/true /bin/hostnamectl

ADD systemctl /usr/bin/systemctl
ADD ipa-client-configure-first /usr/sbin/ipa-client-configure-first

RUN chmod -v +x /usr/bin/systemctl /usr/sbin/ipa-client-configure-first

ENTRYPOINT /usr/sbin/ipa-client-configure-first
