# 基础镜像
FROM ubuntu:latest
# 维护者信息
MAINTAINER Tony <i@iamsjy.com>

# 环境变量
ENV DEBIAN_FRONTEND=noninteractive \
    PASSWD=ubuntu \
    TZ=Asia/Shanghai \
    LANG=zh_CN.UTF-8 \
    LC_ALL=${LANG} \
    LANGUAGE=${LANG}
    
ARG user=ubuntu

# 设定密码
RUN echo "${user}:$PASSWD" | chpasswd

# 安装依赖
RUN apt-get update && apt-get install -y sudo 

# 添加用户：赋予sudo权限，指定密码
RUN useradd --create-home --no-log-init --shell /bin/bash ${user} \
    && adduser ${user} sudo \
    && echo "${user}:$PASSWD" | chpasswd

# 改变用户的UID和GID
# RUN usermod -u 1000 ${user} && usermod -G 1000 ${user}

# 指定容器起来的工作目录
WORKDIR /home/${user}

# 指定容器起来的登录用户
USER ${user}

# 安装
RUN apt-get -y update && \
    # tools
    apt-get install -y vim git wget curl net-tools locales bzip2 unzip iputils-ping traceroute firefox firefox-locale-zh-hans ttf-wqy-microhei gedit ibus-pinyin && \
    locale-gen zh_CN.UTF-8 && \
    # ssh
    apt-get install -y openssh-server && \
    mkdir -p /var/run/sshd && \
    sed -ri 's/^#?PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config && \
    mkdir -p /home/${user}/.ssh && \
    # x11vnc 
    apt-get install -y x11vnc && \
    mkdir -pv /home/${user}/.vnc && \
    x11vnc -storepasswd $PASSWD /home/${user}/.vnc/passwd && \
    # ubuntu-desktop
    apt-get install -y ubuntu-desktop && \
    apt-get install -y gnome-panel gnome-settings-daemon metacity nautilus gnome-terminal lightdm && \
    # clean
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 创建脚本文件
RUN echo "#!/bin/bash\n" > /home/${user}/startup.sh && \
    # 修改密码
    echo 'if [ $PASSWD ] ; then' >> /home/${user}/startup.sh && \
    echo '    echo "${user}:$PASSWD" | chpasswd' >> /home/${user}/startup.sh && \
    echo 'fi' >> /home/${user}/startup.sh && \
    # SSH
    echo "/usr/sbin/sshd -D & source /home/${user}/.bashrc" >> /home/${user}/startup.sh && \
    # VNC
    x11vnc -auth guess -forever -loop -noxdamage -repeat -rfbauth /home/${user}/.vnc/passwd -rfbport 5900 -shared && \
    # 可执行脚本
    chmod +x /home/${user}/startup.sh

# 用户目录不使用中文
RUN LANG=C xdg-user-dirs-update --force


# 导出特定端口
EXPOSE 22 5900

# 启动脚本
CMD ["/home/${user}/startup.sh"]
