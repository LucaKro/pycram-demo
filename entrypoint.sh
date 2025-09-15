#!/bin/bash

source ${ROS_PATH}/setup.bash
source ${ROS_WS}/install/setup.bash
cd ${ROS_WS}
cd src/semantic_world && git pull
cd ${ROS_WS}
cd src/pycram && git pull
cd ${ROS_WS}/src/pycram/demos/laboratory_demo/

exec "$@"