#!/usr/bin/env python3
"""Export the canonical Tessarchy mark as a shareable logo kit."""
import argparse
import hashlib
import io
import json
import math
from pathlib import Path
import shutil
import subprocess
import xml.etree.ElementTree as ET
import zipfile

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SIZES = (16, 24, 32, 48, 64, 96, 128, 192, 256, 512, 1024, 2048)
NAVY = (9, 19, 37)


def inverse_perspective(points, size):
    rows = []
    for (x, y), (u, v) in zip(points, ((0, 0), (size, 0), (size, size), (0, size))):
        rows.append([x, y, 1, 0, 0, 0, -u*x, -u*y, u])
        rows.append([0, 0, 0, x, y, 1, -v*x, -v*y, v])
    for column in range(8):
        pivot = max(range(column, 8), key=lambda row: abs(rows[row][column]))
        rows[column], rows[pivot] = rows[pivot], rows[column]
        divisor = rows[column][column]
        rows[column] = [value / divisor for value in rows[column]]
        for row in range(8):
            if row != column:
                factor = rows[row][column]
                rows[row] = [a - factor*b for a, b in zip(rows[row], rows[column])]
    return tuple(row[-1] for row in rows)


def turn_frame(logo, angle):
    size = logo.width
    center = size / 2
    cosine, sine = math.cos(angle), math.sin(angle)
    if abs(cosine) < 0.025:
        cosine = math.copysign(0.025, cosine)
    canvas = Image.new('RGBA', logo.size)
    shade = Image.new('RGBA', logo.size, (45, 116, 106, 0))
    shade.putalpha(logo.getchannel('A'))
    layers = sorted(range(-8, 9, 4), key=lambda z: z*cosine, reverse=True)
    for index, depth in enumerate(layers):
        corners = []
        for u, v in ((0, 0), (size, 0), (size, size), (0, size)):
            x, y = u-center, v-center
            rotated_x = x*cosine + depth*sine
            rotated_z = -x*sine + depth*cosine
            scale = size*2.6 / (size*2.6 + rotated_z)
            corners.append((center + rotated_x*scale, center + y*scale))
        source = logo if index == len(layers)-1 else shade
        warped = source.transform(logo.size, Image.Transform.PERSPECTIVE,
                                  inverse_perspective(corners, size), Image.Resampling.BICUBIC)
        canvas = Image.alpha_composite(canvas, warped)
    return canvas


def save_gif(frames, destination, transparent=False):
    samples = Image.new('RGB', (frames[0].width*3, frames[0].height))
    for index, frame in enumerate((frames[0], frames[len(frames)//8], frames[len(frames)//4])):
        if transparent:
            rgb = frame.convert('RGB')
        else:
            background = Image.new('RGBA', frame.size, NAVY+(255,))
            rgb = Image.alpha_composite(background, frame).convert('RGB')
        samples.paste(rgb, (index*frame.width, 0))
    palette = samples.quantize(colors=255, method=Image.Quantize.MEDIANCUT)
    palette.putpalette(palette.getpalette()[:765] + [0, 0, 0])
    converted = []
    for frame in frames:
        background = Image.new('RGBA', frame.size, NAVY+(255,))
        rgb = frame.convert('RGB') if transparent else Image.alpha_composite(background, frame).convert('RGB')
        indexed = rgb.quantize(palette=palette, dither=Image.Dither.NONE)
        if transparent:
            indexed.paste(255, mask=frame.getchannel('A').point(lambda alpha: 255 if alpha < 128 else 0))
        converted.append(indexed)
    options = dict(save_all=True, append_images=converted[1:], duration=50,
                   loop=0, disposal=2, optimize=False)
    if transparent:
        options['transparency'] = 255
    converted[0].save(destination, **options)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True, type=Path, help='New directory for kit and ZIP')
    args = parser.parse_args()
    output = args.output.resolve()
    if output.exists():
        parser.error('Output already exists; choose a new directory')
    renderer = shutil.which('rsvg-convert')
    if not renderer:
        parser.error('rsvg-convert is required; install explicitly before export')
    canonical = ROOT / 'shell/artwork/tessarchy-mark.svg'
    source = canonical.read_bytes()
    rendered = subprocess.run([renderer, '--width', '2048', '--height', '2048', str(canonical)],
                              check=True, capture_output=True).stdout
    master = Image.open(io.BytesIO(rendered)).convert('RGBA')
    output.mkdir(parents=True)
    kit = output / 'Tessarchy-Official-Logo-Kit'
    kit.mkdir()
    for directory in ('SVG', 'PNG', 'WEBP', 'JPG', 'ICO', 'PDF', 'Animated'):
        (kit / directory).mkdir()
    shutil.copy2(canonical, kit / 'SVG/tessarchy-logo-mint.svg')
    for name, color in (('white', '#ffffff'), ('black', '#000000')):
        tree = ET.fromstring(source)
        for path in tree.iter('{http://www.w3.org/2000/svg}path'):
            path.set('fill', color)
        ET.ElementTree(tree).write(kit / f'SVG/tessarchy-logo-{name}.svg', encoding='utf-8', xml_declaration=True)
    for size in SIZES:
        image = master.resize((size, size), Image.Resampling.LANCZOS)
        image.save(kit / f'PNG/tessarchy-logo-mint-{size}.png')
        for name, color in (('white', 'white'), ('black', 'black')):
            variant = Image.new('RGBA', image.size, color)
            variant.putalpha(image.getchannel('A'))
            variant.save(kit / f'PNG/tessarchy-logo-{name}-{size}.png')
        if size >= 128:
            image.save(kit / f'WEBP/tessarchy-logo-mint-{size}.webp', lossless=True)
        if size >= 256:
            background = Image.new('RGBA', image.size, NAVY+(255,))
            flattened = Image.alpha_composite(background, image).convert('RGB')
            flattened.save(kit / f'JPG/tessarchy-logo-on-navy-{size}.jpg', quality=95, subsampling=0)
    master.save(kit / 'ICO/tessarchy-logo.ico', sizes=[(size, size) for size in (16, 24, 32, 48, 64, 128, 256)])
    subprocess.run([renderer, '--format', 'pdf', '--width', '1024', '--height', '1024',
                    '--output', str(kit / 'PDF/tessarchy-logo-mint.pdf'), str(canonical)], check=True)
    size = 512
    base = Image.new('RGBA', (size, size))
    small = master.resize((420, 420), Image.Resampling.LANCZOS)
    base.alpha_composite(small, (46, 46))
    turn = [turn_frame(base, index*math.tau/72) for index in range(72)]
    save_gif(turn, kit / 'Animated/tessarchy-logo-3d-spin-512.gif')
    save_gif([frame.resize((256, 256), Image.Resampling.LANCZOS) for frame in turn],
             kit / 'Animated/tessarchy-logo-3d-spin-256.gif')
    turn[0].save(kit / 'Animated/tessarchy-logo-3d-spin-512.webp', save_all=True,
                 append_images=turn[1:], duration=50, loop=0, lossless=True)
    flat = [base.rotate(-index*360/72, Image.Resampling.BICUBIC) for index in range(72)]
    save_gif(flat, kit / 'Animated/tessarchy-logo-flat-spin-transparent-512.gif', transparent=True)
    tree = ET.fromstring(source)
    namespace = '{http://www.w3.org/2000/svg}'
    tree.set('viewBox', '-24 -24 176 176')
    group = ET.SubElement(tree, namespace+'g')
    for path in list(tree):
        if path.tag == namespace+'path':
            tree.remove(path)
            group.append(path)
    ET.SubElement(group, namespace+'animateTransform', {'attributeName': 'transform', 'type': 'rotate',
                  'from': '0 64 64', 'to': '360 64 64', 'dur': '3.6s', 'repeatCount': 'indefinite'})
    ET.ElementTree(tree).write(kit / 'Animated/tessarchy-logo-spin.svg', encoding='utf-8', xml_declaration=True)
    shutil.copy2(ROOT / 'LICENSE', kit / 'LICENSE.txt')
    (kit / 'README.txt').write_text('''TESSARCHY OFFICIAL LOGO KIT

Source: shell/artwork/tessarchy-mark.svg, the existing official tessellated T.
The mint SVG is byte-identical to the repository source. Geometry is unchanged.

PNG: transparent mint/white/black at 16, 24, 32, 48, 64, 96, 128, 192, 256,
512, 1024 and 2048 pixels. WEBP: lossless transparent mint at 128–2048 pixels.
SVG: scalable mint, white and black. PDF: scalable vector mint. ICO: multi-size
Windows/favicon container. JPG: mint on midnight navy, 256–2048 pixels.

Animated: 3.6-second seamless loops, 72 frames at 20 fps. The 3D-style turntable
has shallow extrusion and a navy matte; GIFs are 256/512 pixels, plus lossless
animated WEBP. A transparent GIF and animated SVG provide a flat clockwise spin.
GIF transparency has a one-bit edge; use PNG/WEBP/SVG for clean static edges.
Use static versions where motion is unwanted. No external fonts or console
brand artwork are used. MIT license included.

Export: python scripts/export-brand-assets.py --output NEW_DIRECTORY
Requirements: Pillow and rsvg-convert; the exporter never installs dependencies
and refuses an existing output directory.
''')
    manifest = {'source': str(canonical.relative_to(ROOT)),
                'source_sha256': hashlib.sha256(source).hexdigest(), 'sizes': list(SIZES),
                'animation': {'frames': 72, 'frame_ms': 50, 'loop': True}, 'files': {}}
    for path in sorted(kit.rglob('*')):
        if path.is_file():
            manifest['files'][str(path.relative_to(kit))] = hashlib.sha256(path.read_bytes()).hexdigest()
    (kit / 'MANIFEST.json').write_text(json.dumps(manifest, indent=2)+'\n')
    archive = output / 'Tessarchy-Official-Logo-Kit.zip'
    with zipfile.ZipFile(archive, 'x', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as bundle:
        for path in sorted(kit.rglob('*')):
            if path.is_file():
                bundle.write(path, path.relative_to(output))
    with zipfile.ZipFile(archive) as bundle:
        if bundle.testzip() is not None:
            raise RuntimeError('ZIP validation failed')
    print(archive)
    print('SHA256 '+hashlib.sha256(archive.read_bytes()).hexdigest())


if __name__ == '__main__':
    main()
