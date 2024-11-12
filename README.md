# Aether Engine
A Parameterized CNN Accelerator for FPGAs with Resource-Aware Scaling

## Overview
Aether Engine is a versatile CNN accelerator implementation for FPGAs that supports various neural network architectures. The accelerator is designed with flexibility in mind, allowing customization for both resource-constrained and high-performance FPGA targets.

## Key Features
- Parameterized design supporting various matrix sizes
- Scalable number of accelerator units
- Configurable for different FPGA resource profiles
- Support for variable input dimensions
- Flexible CNN operation support

## Supported Operations
- [x] Convolution layers
- [ ] Activation functions
  - [ ] Sigmoid
  - [x] ReLU
  - [ ] Softmax
- [ ] Dense (Fully connected) layers
- [ ] Maxpooling

## Tested Models
- [ ] MNIST (In Progress)
- [ ] YOLO (Planned)

## Build Instructions
```bash
git clone --recurse-submodules https://github.com/fpgabuilds/mnist-fpga.git
```
