# Nuero_Evolution_for_Approximate_SA_arch
This repository contains the codebase, hardware models, and optimization framework for our research on energy-efficient matrix multiplication accelerators. Our architecture synergistically combines Strassen’s algorithm, multi-systolic arrays, and approximate computing to create high-performance, low-power hardware tailored for modern workloads like image processing and deep learning inference.

```sh
├── src
    ├── hw /                   # RTL, synthesis scripts, STA estimation modules
    ├── mults/                  # All 10 approximate multipliers and exact baseline
    ├── sa/                     # Multi-SA simulation and configuration logic
├── nuero_evolution
    ├── vae/               # CatVAE model (encoder/decoder training)
    ├── moea/              # MOEA implementation: NSGA-II and AGE-MOEA-II
├── evaluation/            # ResNet50 and image processing evaluations
├── results/               # Saved Pareto fronts, SSIM/PSNR/accuracy plots, Convergence, Ablation study result
├── data/                  # EuroSAT dataset and image samples
└── README.md              # You are here
```

  How It Works
 ---------------

 ###  Architecture Encoding

 Each accelerator configuration is represented as a **4096-length vector**, where each element ∈ {0,...,9}, 
 corresponding to one of the 10 available approximate multipliers.

 ###  Performance Estimation

 Each configuration is evaluated using:

 - **Static Timing Analysis (STA)** for area, power, and delay
 - **Image Processing Pipelines** for SSIM and PSNR degradation
 - **CNN Inference** using a modified **ResNet50** on **EuroSAT** 
   (RGB version of Sentinel-2 satellite images)

 ###  CatVAE with Gumbel-Softmax

 The VAE learns to compress the discrete 4096D space into a **low-dimensional latent vector**, 
 enabling faster and meaningful exploration. 
 VAE is **co-evolved** with the search process to adapt to newer, high-performing configurations.

 ###  Multi-Objective Search

 - **NSGA-II** and **AGE-MOEA-II** are used to explore the latent space and maximize application quality 
   while minimizing hardware cost.
 - The decoder reconstructs 4096D configs from latent vectors for actual evaluation.
