ls /home/ros2_ws/src/my_drone_description/models/
rm -rf /home/mobile/PX4-Autopilot/Tools/simulation/gz/models/standard_vtol
cp -r /home/ros2_ws/src/my_drone_description/models/standard_vtol/ /home/mobile/PX4-Autopilot/Tools/simulation/gz/models/
source /opt/ros/humble/setup.bash
cd /home/ros2_ws/
colcon build
source install/setup.bash
ros2 launch my_drone_description sim.launch.py