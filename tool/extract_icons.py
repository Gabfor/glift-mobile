import os
import re
import base64

def extract_png_from_svg(svg_path, png_path):
    try:
        with open(svg_path, 'r') as f:
            content = f.read()
        
        # Regex to find the base64 data
        match = re.search(r'xlink:href="data:image/png;base64,([^"]+)"', content)
        if not match:
            print(f"No base64 PNG data found in {svg_path}")
            return False
        
        base64_data = match.group(1)
        png_data = base64.b64decode(base64_data)
        
        with open(png_path, 'wb') as f:
            f.write(png_data)
        
        print(f"Successfully extracted {png_path}")
        return True
    except Exception as e:
        print(f"Error extracting from {svg_path}: {e}")
        return False

base_dir = '/Users/gabrielfort/Documents/glift-workspace/glift-mobile/assets/icons'
files = [
    ('smiley_jaune.svg', 'smiley_jaune.png'),
    ('smiley_vert.svg', 'smiley_vert.png'),
    ('smiley_rouge.svg', 'smiley_rouge.png')
]

for svg_name, png_name in files:
    svg_path = os.path.join(base_dir, svg_name)
    png_path = os.path.join(base_dir, png_name)
    extract_png_from_svg(svg_path, png_path)
