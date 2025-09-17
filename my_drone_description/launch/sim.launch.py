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

    px4_path = Path("/home/mobile/PX4-Autopilot")
    custom_model_path = Path("/home/mobile/ros2_ws/src/my_drone_description/models/standard_vtol")
    original_model_path = px4_path / "Tools/simulation/gz/models/standard_vtol"
    backup_model_path = px4_path / "Tools/simulation/gz/models/standard_vtol_original"

    setup_model_cmd = (
        "if [ -d '" + str(custom_model_path) + "' ]; then "
        "if [ ! -d '" + str(backup_model_path) + "' ]; then "
        "mv '" + str(original_model_path) + "' '" + str(backup_model_path) + "'; fi; "
        "ln -sf '" + str(custom_model_path) + "' '" + str(original_model_path) + "'; "
        "fi"
    )

    return LaunchDescription([
        ExecuteProcess(
            cmd=["bash", "-c", setup_model_cmd],
            output="log",
            shell=False
        ),
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
