#!/usr/bin/env python3
"""Render the canonical mark into a bounded Plymouth turntable sequence."""
import argparse
import importlib.util
import io
import math
from pathlib import Path
import shutil
import subprocess

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    output = args.output.absolute()
    if output.exists() or output.is_symlink():
        parser.error('Choose a new output directory')
    renderer = shutil.which('rsvg-convert')
    if not renderer:
        parser.error('rsvg-convert is required')
    spec = importlib.util.spec_from_file_location('brand_export', ROOT / 'scripts/export-brand-assets.py')
    brand = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(brand)
    data = subprocess.run([renderer, '--width', '208', '--height', '208',
                           str(ROOT / 'shell/artwork/tessarchy-mark.svg')],
                          check=True, capture_output=True).stdout
    logo = Image.new('RGBA', (256, 256))
    logo.alpha_composite(Image.open(io.BytesIO(data)).convert('RGBA'), (24, 24))
    output.mkdir(parents=True)
    for index in range(64):
        brand.turn_frame(logo, index * math.tau / 64).save(output / f'logo-{index}.png')
    print('Rendered 64 Plymouth animation frames')


if __name__ == '__main__':
    main()
