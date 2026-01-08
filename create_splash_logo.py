#!/usr/bin/env python3
"""
Create a simple, Android-compatible splash logo PNG
"""
from PIL import Image, ImageDraw
import os

def create_splash_logo(output_path, size=512):
    """Create a simple splash logo that's guaranteed to be Android-compatible"""
    
    # Create a new image with white background
    img = Image.new('RGB', (size, size), color='white')
    draw = ImageDraw.Draw(img)
    
    # Define colors for the gradient effect
    colors = {
        'cyan': (0, 180, 216),      # #00B4D8
        'blue': (64, 118, 211),     # #4076D3
        'purple': (157, 78, 221)    # #9D4EDD
    }
    
    # Draw the network globe (simplified)
    center = size // 2
    radius = int(size * 0.35)  # 35% of image size
    
    # Draw outer circle
    circle_width = 8
    draw.ellipse([center - radius, center - radius, 
                  center + radius, center + radius],
                 outline=colors['cyan'], width=circle_width)
    
    # Draw nodes around the circle
    import math
    num_nodes = 12
    node_radius = 12
    
    for i in range(num_nodes):
        angle = (2 * math.pi * i) / num_nodes
        x = center + int(radius * math.cos(angle))
        y = center + int(radius * math.sin(angle))
        
        # Gradient color based on position
        if i < num_nodes // 3:
            color = colors['cyan']
        elif i < 2 * num_nodes // 3:
            color = colors['blue']
        else:
            color = colors['purple']
        
        draw.ellipse([x - node_radius, y - node_radius,
                     x + node_radius, y + node_radius],
                    fill=color)
    
    # Draw connecting lines
    line_width = 3
    for i in range(num_nodes):
        for j in range(i + 1, num_nodes):
            if (j - i) % 3 == 0:  # Only connect some nodes to avoid clutter
                angle1 = (2 * math.pi * i) / num_nodes
                angle2 = (2 * math.pi * j) / num_nodes
                x1 = center + int(radius * math.cos(angle1))
                y1 = center + int(radius * math.sin(angle1))
                x2 = center + int(radius * math.cos(angle2))
                y2 = center + int(radius * math.sin(angle2))
                draw.line([x1, y1, x2, y2], fill=colors['blue'], width=line_width)
    
    # Draw the central 'X' with arrows (exchange symbol)
    x_size = int(size * 0.15)
    arrow_width = 12
    
    # Top-left to bottom-right arrow (cyan)
    draw.polygon([
        (center - x_size, center - x_size),
        (center - x_size + arrow_width, center - x_size),
        (center + x_size, center + x_size - arrow_width),
        (center + x_size, center + x_size),
        (center + x_size - arrow_width, center + x_size),
        (center - x_size, center - x_size + arrow_width)
    ], fill=colors['cyan'])
    
    # Bottom-left to top-right arrow (purple)
    draw.polygon([
        (center - x_size, center + x_size),
        (center - x_size, center + x_size - arrow_width),
        (center + x_size - arrow_width, center - x_size),
        (center + x_size, center - x_size),
        (center + x_size, center - x_size + arrow_width),
        (center - x_size + arrow_width, center + x_size)
    ], fill=colors['purple'])
    
    # Save as PNG with no extra metadata
    img.save(output_path, 'PNG', optimize=True)
    print(f"Splash logo created at: {output_path}")

if __name__ == "__main__":
    # Create the splash logos
    base_path = "android/app/src/main/res"
    
    # Create for different densities
    densities = {
        'drawable-mdpi': 192,
        'drawable-hdpi': 288,
        'drawable-xhdpi': 384,
        'drawable-xxhdpi': 512,
        'drawable-xxxhdpi': 768,
        'drawable': 512  # Default
    }
    
    for folder, size in densities.items():
        folder_path = os.path.join(base_path, folder)
        os.makedirs(folder_path, exist_ok=True)
        output_path = os.path.join(folder_path, 'splash_logo.png')
        create_splash_logo(output_path, size)
