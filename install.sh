#!/bin/bash
set -e

echo $'\e[1;32mInstalling ROCm (with Polaris support)...\e[0m'

if (cat /proc/cpuinfo | grep avx2); then
    paru -S git wget python3 python-pip python-pytorch-opt-rocm python-torchvision-rocm opencl-mesa rocm-cmake rocblas rocm-core rocm-device-libs rocm-hip-runtime rocm-language-runtime rocm-llvm rocm-opencl-runtime rocminfo hip hsa-rocr rocm-clang-ocl roctracer rocm-smi-lib rocprofiler hsa-amd-aqlprofile --noconfirm --needed
else
    paru -S git wget python3 python-pip python-pytorch-rocm python-torchvision-rocm opencl-mesa rocm-cmake rocblas rocm-core rocm-device-libs rocm-hip-runtime rocm-language-runtime rocm-llvm rocm-opencl-runtime rocminfo hip hsa-rocr rocm-clang-ocl roctracer rocm-smi-lib rocprofiler hsa-amd-aqlprofile --noconfirm --needed
fi

export MAKEFLAGS="-j$(nproc)"
export NINJAFLAGS="-j$(nproc)"
export AMDGPU_TARGETS="gfx803"
export ROC_ENABLE_PRE_VEGA=1

sudo pacman -S asp --noconfirm --needed

rm -rf clone
mkdir clone
cd clone
asp export rocm-hip-runtime rocminfo rocm-opencl-runtime

function recursive_for_loop {
    for dir in *;  do
        if [ -d $dir  -a ! -h $dir ];
        then
            cd -- "$dir";
            if !(paru -Qqm | grep $dir); then
                paru -Ui --noconfirm --rebuild=all;
            fi
            recursive_for_loop;
            cd ..;
        fi;
    done;
};
recursive_for_loop

cd ..
cd rocblas-polaris-bin
paru -Ui --rebuild=all
cd ..
rm -rf clone

echo $'\e[1;32mInstalling Stable-Diffusion...\e[0m'

git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui --recursive
cd stable-diffusion-webui

python -m venv venv --system-site-packages
source ./venv/bin/activate
pip install -r requirements.txt
pip install markupsafe==2.0.1

echo $'#!/bin/bash\npython launch.py --skip-torch-cuda-test' > webui-py.sh
chmod +x ./webui-py.sh

echo $'\e[1;32mDone!\e[0m\nNow it can be launched via:\n$ source venv/bin/activate\n$ ./webui-py.sh'
