from launch import LaunchDescription
from launch.actions import ExecuteProcess, TimerAction
from launch_ros.actions import Node
from launch_ros.substitutions import FindPackageShare
from launch.substitutions import PathJoinSubstitution
from pathlib import Path

def generate_launch_description():

    bridge_config = PathJoinSubstitution([
        FindPackageShare("my_drone_description"),
        "config",
        "bridge.yaml"
    ])

    return LaunchDescription([
        ExecuteProcess(
            cmd=["cd", "/home/mobile/PX4-Autopilot", "&&", "make", "px4_sitl", "gz_standard_vtol"],
            output="screen",
            shell=True
        ),
        TimerAction(
            period=10.0,
            actions=[ExecuteProcess(
                cmd=["MicroXRCEAgent", "udp4", "-p", "8888"],
                output="screen",
                shell=True
            )]
        ),
        TimerAction(
            period=15.0,
            actions=[ExecuteProcess(
                cmd=["cd", "/home/mobile/Q_ground_control/", "&&", "APPIMAGE_EXTRACT_AND_RUN=1", "./QGroundControl-x86_64.AppImage"],
                output="log",
                shell=True
            )]
        ),
        TimerAction(
            period=25.0,
            actions=[Node(
                package="ros_gz_bridge",
                executable="parameter_bridge",
                name="gz_ros_bridge",
                output="screen",
                parameters=[{"config_file": bridge_config}]
            )]
        ),
        Node(
            package="tf2_ros",
            executable="static_transform_publisher",
            arguments=["0.0", "0.0", "0.0", "0.0", "0.0", "0.0", "world", "map"],
            name="world_to_map_tf"
        )
    ])
