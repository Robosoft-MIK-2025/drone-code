# Use ROS 2 Humble from Docker Hub as the base image
FROM osrf/ros:humble-desktop-full
# Set non-interactive frontend fodebconf
ENV DEBIAN_FRONTEND=noninteractive

ENV ROS_DISTRO=humble

# Set arguments for user creation
ARG USERNAME=mobile
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME


# Update and install necessary packages
RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y sudo curl gnupg2 lsb-release net-tools python3-pip \
    && curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add - \
    && echo "deb http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/ros2-latest.list

# Install slcan-utils from source if not available
RUN apt-get install -y git build-essential \
    && git clone https://github.com/linux-can/can-utils.git \
    && cd can-utils \
    && make \
    && make install

# Обновление и установка базовых пакетов
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    sudo \
    git \
    python3-pip \
    ros-${ROS_DISTRO}-tf2-tools \
    ros-${ROS_DISTRO}-gazebo-ros \
    ros-${ROS_DISTRO}-robot-state-publisher \
    ros-${ROS_DISTRO}-joint-state-publisher \
    ros-${ROS_DISTRO}-xacro \
    ros-${ROS_DISTRO}-rviz2 \
    ros-${ROS_DISTRO}-hardware-interface \
    ros-${ROS_DISTRO}-transmission-interface \
    ros-${ROS_DISTRO}-urdf \
    ros-${ROS_DISTRO}-urdfdom \
    ros-${ROS_DISTRO}-urdfdom-headers \
    ros-${ROS_DISTRO}-urdf-tutorial \
    ros-${ROS_DISTRO}-apriltag-ros \
    ros-${ROS_DISTRO}-gz-ros2-control \
    ros-${ROS_DISTRO}-v4l2-camera \
    ros-${ROS_DISTRO}-camera-calibration \
    ros-${ROS_DISTRO}-gazebo-ros-pkgs \
    ros-${ROS_DISTRO}-nav2-bringup \
    libcanberra-gtk-module \
    libcanberra-gtk3-module \
    at-spi2-core \
    x11-apps \
    xauth \
    --fix-missing

#Утановка PX4-Autopilot
RUN apt-get update && apt-get install -y wget
RUN cd /home/$USERNAME \
    && git clone https://github.com/PX4/PX4-Autopilot.git --recursive \
    && bash ./PX4-Autopilot/Tools/setup/ubuntu.sh
RUN cd /home/$USERNAME \
    && git clone -b v2.4.2 https://github.com/eProsima/Micro-XRCE-DDS-Agent.git \
    && cd Micro-XRCE-DDS-Agent \
    && sed -i '98s|2.12|2.13|' CMakeLists.txt \
    && sed -i '99s|2.12.x|2.13.3|' CMakeLists.txt \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make \
    && sudo make install \
    && sudo ldconfig /usr/local/lib/ 

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/*


# Initialize rosdep (run as user)
RUN sudo rosdep init || true \
    && rosdep update

# Добавляем source в .bashrc
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> /home/$USERNAME/.bashrc

CMD ["bash"]

