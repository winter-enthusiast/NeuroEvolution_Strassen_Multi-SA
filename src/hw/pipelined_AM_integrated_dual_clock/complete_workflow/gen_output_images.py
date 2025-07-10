import os
import numpy as np
from PIL import Image
from scipy.signal import convolve2d
from scipy import fftpack
from skimage.filters import gabor_kernel
from skimage.transform import resize

# Configuration
INPUT_DIR = 'input_image'
OUTPUT_DIR_BASE = 'output_image'
FILTER_SAVE_DIR = 'filters'
PATCH = 16

os.makedirs(FILTER_SAVE_DIR, exist_ok=True)

# Function to load grayscale images
def load_images_from_directory(directory):
    images = []
    filenames = []
    for filename in os.listdir(directory):
        if filename.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp')):
            img_path = os.path.join(directory, filename)
            img = Image.open(img_path).convert('L')
            images.append(np.array(img, dtype=float))
            filenames.append(filename)
    return images, filenames

# Generate DCT Filters and quantize to signed 8-bit
def generate_dct_filters():
    dct_filters = []
    for u in range(PATCH):
        for v in range(PATCH):
            basis = np.zeros((PATCH, PATCH))
            basis[u, v] = 1.0
            f = fftpack.idct(fftpack.idct(basis.T, norm='ortho').T, norm='ortho')
            f = np.round(f / np.max(np.abs(f)) * 127).astype(np.int8)  # Quantize to int8
            dct_filters.append(f)
    return np.stack(dct_filters)  # shape: (256, 16, 16)

# Generate Gabor Filters and ensure all are 16x16 and int8
def generate_gabor_filters():
    thetas = np.linspace(0, np.pi, 16, endpoint=False)
    frequencies = np.linspace(0.1, 0.4, 16)
    gabor_filters = []

    for theta in thetas:
        for freq in frequencies:
            kernel = np.real(gabor_kernel(freq, theta=theta))
            kernel_resized = resize(kernel, (PATCH, PATCH), mode='reflect', anti_aliasing=True)
            kernel_int8 = np.round(kernel_resized / (np.max(np.abs(kernel_resized)) + 1e-8) * 127).astype(np.int8)
            gabor_filters.append(kernel_int8)

    return np.stack(gabor_filters)  # shape: (256, 16, 16)

# Save filters to a file
def save_filters(filters, path):
    with open(path, 'w') as f:
        for idx, filt in enumerate(filters):
            f.write(f'filter {idx}:\n')
            for row in filt:
                f.write(' '.join(map(str, row)) + '\n')

# Apply filters to images and save results
def apply_filters_and_save(images, filenames, filters, filter_type):
    output_dir = os.path.join(OUTPUT_DIR_BASE, filter_type)
    os.makedirs(output_dir, exist_ok=True)

    for img, fname in zip(images, filenames):
        for idx, filt in enumerate(filters):
            resp = convolve2d(img, filt, mode='valid')
            norm = (resp - resp.min()) / (resp.max() - resp.min() + 1e-6)
            img_out = (norm * 255).astype(np.uint8)
            out_fname = f"filtered_filter_{idx:03d}_{fname}"
            Image.fromarray(img_out).save(os.path.join(output_dir, out_fname))

# Main Execution
images, filenames = load_images_from_directory(INPUT_DIR)

# DCT
dct_filters = generate_dct_filters()
save_filters(dct_filters, os.path.join(FILTER_SAVE_DIR, 'dct_filters.dat'))
apply_filters_and_save(images, filenames, dct_filters, 'dct')

# Gabor
gabor_filters = generate_gabor_filters()
save_filters(gabor_filters, os.path.join(FILTER_SAVE_DIR, 'gabor_filters.dat'))
apply_filters_and_save(images, filenames, gabor_filters, 'gabor')
