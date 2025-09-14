FROM intel4coro/jupyter-ros2:jazzy-py3.12

USER ${NB_USER}
# Setup up a ROS workspace
ENV ROS_WS=${HOME}/workspace/ros
RUN mkdir -p ${ROS_WS}/src

RUN pip install setuptools==68.1.2

# Clone pycram and its dependencies repos
WORKDIR ${ROS_WS}/src
RUN vcs import --input https://raw.githubusercontent.com/LucaKro/pycram/laboratory_demo/rosinstall/pycram-ros2-https.rosinstall

RUN touch ros2_robotiq_gripper/robotiq_controllers/COLCON_IGNORE
RUN touch ros2_robotiq_gripper/robotiq_driver/COLCON_IGNORE
RUN touch ros2_robotiq_gripper/robotiq_hardware_tests/COLCON_IGNORE
RUN touch iai_tracy/iai_tracy_ur/COLCON_IGNORE
RUN touch iai_tracy/iai_tracy_bringup/COLCON_IGNORE

# Building ROS workspace
WORKDIR ${ROS_WS}
RUN cd src/pycram && git pull && cd ../.. && \
    source /opt/ros/jazzy/setup.bash && \
    colcon build --symlink-install --parallel-workers 4
RUN echo "source ${ROS_WS}/install/setup.bash" >> ${HOME}/.bashrc

# # Install Python dependencies
WORKDIR ${ROS_WS}/src/pycram
RUN pip install -r requirements.txt

# Convenience for interactive shells
USER root
RUN apt install graphviz graphviz-dev -y && apt-get clean && rm -rf /var/lib/apt/lists/*
USER ${NB_USER}

WORKDIR ${ROS_WS}/src/
RUN source /opt/ros/jazzy/setup.bash && \
    pip install -r semantic_world/requirements.txt && \
    pip install -e semantic_world

# Steps copy from github CI
RUN pip install jupytext treon
RUN cd ${ROS_WS}/src/pycram/examples && \
    rm -rf ../notebooks && \
    mkdir ../notebooks && \
    jupytext --to notebook *.md && \
    mv *.ipynb ../notebooks

# Extra steps for binderhub
RUN git config --global --add safe.directory ${ROS_WS}/src/pycram
WORKDIR ${ROS_WS}/src/pycram/demos/laboratory_demo/

RUN pip uninstall -y jupyterlab_examples_cell_toolbar

COPY --chown=${NB_USER}:users utils.py ${ROS_WS}/src/pycram/demos/laboratory_demo/
COPY --chown=${NB_USER}:users pycram.rviz ${ROS_WS}/src/pycram/demos/laboratory_demo/
RUN ipython profile create && \
    ln -s ${ROS_WS}/src/pycram/demos/laboratory_demo/utils.py /home/jovyan/.ipython/profile_default/startup/00-first.py

COPY --chown=${NB_USER}:users entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
WORKDIR ${ROS_WS}/src/pycram/demos/laboratory_demo/
USER ${NB_USER}