"""
Concatenates the contents of two separate locale folders.
The locale folders may have different languages
"""

import pathlib
import argparse
import shutil
import subprocess
from sys import exit


parser = argparse.ArgumentParser(description='Concatenates the contents of two locale folders which may have different locales.')
parser.add_argument('source', type=pathlib.Path)
parser.add_argument('destination', type=pathlib.Path)

args = parser.parse_args()

if not args.source.is_dir():
    print("'source' argument must be a path to a locale folder")
    exit()

if not args.destination.is_dir():
    print("'destination' argument must be a path to a locale folder")
    exit()

# Get list of locale files
source_locale_files = set(pofile.relative_to(args.source) for pofile in args.source.glob('*/LC_MESSAGES/*.po'))
dest_locale_files = set(pofile.relative_to(args.destination) for pofile in args.destination.glob('*/LC_MESSAGES/*.po'))

source_only = source_locale_files - dest_locale_files
source_and_dest = source_locale_files & dest_locale_files

# Copy files that only exist in the source to the destination
for path in source_only:
    from_path = args.source / path
    to_path = args.destination / path

    print("Copying", from_path, to_path)

    to_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(from_path, to_path)

# Merge files that exist in both
for path in source_and_dest:
    from_path = args.source / path
    to_path = args.destination / path

    print("Merging", from_path, to_path)

    subprocess.run(['msgcat', str(from_path), str(to_path), '-o', str(to_path)])
