#!/usr/bin/env python3
"""
Create launcher icons for Android from the existing logo
"""
from PIL import Image
import os

def create_launcher_icon(source_path, output_path, size):
    """
    Create a launcher icon at the specified size from the source image
    """
    # Open the source image
    img = Image.open(source_path)
    
    # Resize the image to the target size with high-quality resampling
    img_resized = img.resize((size, size), Image.Resampling.LANCZOS)
    
    # Save as PNG
    img_resized.save(output_path, 'PNG', optimize=True)
    print(f"Created launcher icon: {output_path} ({size}x{size})")

def main():
    """Generate all launcher icons"""
    source_logo = "assets/images/logo.png"
    
    if not os.path.exists(source_logo):
        print(f"Error: Source logo not found at {source_logo}")
        return
    
    # Android launcher icon sizes for different densities
    # Based on Material Design Icon Guidelines
    icon_sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192
    }
    
    base_path = "android/app/src/main/res"
    
    # Generate ic_launcher.png for each density
    for folder, size in icon_sizes.items():
        folder_path = os.path.join(base_path, folder)
        os.makedirs(folder_path, exist_ok=True)
        
        output_path = os.path.join(folder_path, 'ic_launcher.png')
        create_launcher_icon(source_logo, output_path, size)
    
    print("\n✅ All launcher icons created successfully!")
    print("The app icon will be updated on the next build.")

if __name__ == "__main__":
    main()
