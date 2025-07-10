import numpy as np
from PIL import Image
import os

def process_image_to_patches(input_dir="input_image", output_file="./data/mat_A_rearranged.dat", patch_size=16, stride=1):
    """
    Process an image from input_image directory and generate patches in specified format.
    
    Args:
        input_dir (str): Directory containing the input image
        output_file (str): Output file path for the patches data
        patch_size (int): Size of each square patch (default 16x16 = 256 elements)
        stride (int): Step size between patches (default 1 for overlapping patches)
    """
    
    # Create output directory if it doesn't exist
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    
    # Find the first image file in the input directory
    image_files = []
    for file in os.listdir(input_dir):
        if file.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp', '.tiff')):
            image_files.append(file)
    
    if not image_files:
        raise FileNotFoundError(f"No image files found in {input_dir} directory")
    
    # Load the first image found
    image_path = os.path.join(input_dir, image_files[0])
    print(f"Processing image: {image_path}")
    
    # Load and convert image to grayscale
    img = Image.open(image_path)
    if img.mode != 'L':
        img = img.convert('L')  # Convert to grayscale
    
    # Convert to numpy array
    img_array = np.array(img)
    height, width = img_array.shape
    
    print(f"Image dimensions: {width}x{height}")
    print(f"Patch size: {patch_size}x{patch_size} ({patch_size*patch_size} elements)")
    
    # Calculate number of patches with stride
    patches_x = (width - patch_size) // stride + 1
    patches_y = (height - patch_size) // stride + 1
    total_patches = patches_x * patches_y
    
    print(f"Number of patches with stride {stride}: {patches_x}x{patches_y} = {total_patches}")
    
    # Extract patches and write to file
    with open(output_file, 'w') as f:
        patch_count = 1
        
        for y in range(patches_y):
            for x in range(patches_x):
                # Extract patch with stride
                start_y = y * stride
                end_y = start_y + patch_size
                start_x = x * stride
                end_x = start_x + patch_size
                
                patch = img_array[start_y:end_y, start_x:end_x]
                
                # Flatten patch to 1D array
                patch_flat = patch.flatten()
                
                # Write patch header
                f.write(f"patch {patch_count}:- \n")
                
                # Write patch data (space-separated values)
                patch_str = ' '.join(map(str, patch_flat))
                f.write(patch_str + '\n')
                
                patch_count += 1
    
    print(f"Successfully generated {output_file} with {total_patches} patches")
    print(f"Each patch contains {patch_size*patch_size} pixel values")

# Example usage
if __name__ == "__main__":
    try:
        # Process image with stride=1 (overlapping patches)
        process_image_to_patches(stride=1)
        
        # Alternative: specify custom patch size with stride=1
        # process_image_to_patches(patch_size=8, stride=1)  # 8x8 patches with stride 1
        
    except Exception as e:
        print(f"Error: {e}")
        print("\nMake sure:")
        print("1. 'input_image' directory exists")
        print("2. There's at least one image file (.png, .jpg, .jpeg, .bmp, .tiff) in the directory")
        print("3. You have write permissions for the './data/' directory")