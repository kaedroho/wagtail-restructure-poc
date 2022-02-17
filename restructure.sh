#!/bin/bash
set -e

rm -rf wagtail
git clone git@github.com:wagtail/wagtail.git

cd wagtail

git checkout 52048ba0e8cbf812a1bdc2c219a2d829da52e10d -b rename-wagtailcore-to-wagtail

echo "/.ropeproject" >> .gitignore


# Rename wagtail.core to wagtail
# This part starts off with a few renames to resolves conflicts, then moves everthing under wagtail/core to the top level

poetry run roper rename-module --module wagtail/core/utils.py --to-name coreutils --do
find . -name '*.rst' -exec sed -i 's/wagtail.core.utils/wagtail.core.coreutils/g' {} \;
find . -name '*.md' -exec sed -i 's/wagtail.core.utils/wagtail.core.coreutils/g' {} \;
poetry run isort -rc wagtail
poetry run black wagtail
git add .
git checkout -- docs/releases
git commit -m "Move core.utils to core.coreutils"

poetry run roper move-by-name --name get_site_for_hostname --source wagtail/core/sites.py --target wagtail/core/models/sites.py --do
poetry run roper move-by-name --name MATCH_HOSTNAME --source wagtail/core/sites.py --target wagtail/core/models/sites.py --do
poetry run roper move-by-name --name MATCH_DEFAULT --source wagtail/core/sites.py --target wagtail/core/models/sites.py --do
poetry run roper move-by-name --name MATCH_HOSTNAME_DEFAULT --source wagtail/core/sites.py --target wagtail/core/models/sites.py --do
poetry run roper move-by-name --name MATCH_HOSTNAME_PORT --source wagtail/core/sites.py --target wagtail/core/models/sites.py --do
rm wagtail/core/sites.py
git apply --reject --whitespace=fix ../patches/fixup-sites-models.patch
poetry run isort -rc wagtail
poetry run black wagtail
git add .
git checkout -- docs/releases
git commit -m "Merge sites utilities into sites models"

poetry run roper rename-module --module wagtail/tests --to-name test --do
# Need to update .py files here since wagtail.tests appears a lot in strings
# Also, escaping . for this one since wagtail_tests appears often
find . -name '*.py' -exec sed -i 's/wagtail\.tests/wagtail\.test/g' {} \;
find . -name '*.rst' -exec sed -i 's/wagtail\.tests/wagtail\.test/g' {} \;
find . -name '*.md' -exec sed -i 's/wagtail\.tests/wagtail\.test/g' {} \;
sed -i "s/os.path.join(WAGTAIL_ROOT, 'tests', 'testapp', 'jinja2_templates'),/os.path.join(WAGTAIL_ROOT, 'test', 'testapp', 'jinja2_templates'),/g" wagtail/test/settings.py
poetry run isort -rc wagtail
poetry run black wagtail
git add .
git checkout -- docs/releases
git commit -m "Move tests to test"

cat wagtail/core/__init__.py >> wagtail/__init__.py
rm wagtail/core/__init__.py
git apply --reject --whitespace=fix ../patches/concantenate-core-init.patch
mv -n wagtail/core/* wagtail
find . -name '*.py' -exec sed -i 's/wagtail\.core/wagtail/g' {} \;
find . -name '*.rst' -exec sed -i 's/wagtail\.core/wagtail/g' {} \;
find . -name '*.md' -exec sed -i 's/wagtail\.core/wagtail/g' {} \;
sed -i "s/from ..core.coreutils/from wagtail.coreutils/g" wagtail/embeds/embeds.py
sed -i "s/self.assertRaises(ValueError, resolve_model_string, 'wagtail.Page')/self.assertRaises(ValueError, resolve_model_string, 'wagtail.core.Page')/g" wagtail/tests/tests.py
poetry run isort -rc wagtail
poetry run black wagtail
git add .
git checkout -- docs/releases
git commit -m "Move wagtail.core to wagtail"

find . -name '*.py' -exec sed -i 's/WagtailCoreAppConfig/WagtailAppConfig/g' {} \;
find . -name '*.rst' -exec sed -i 's/WagtailCoreAppConfig/WagtailAppConfig/g' {} \;
find . -name '*.md' -exec sed -i 's/WagtailCoreAppConfig/WagtailAppConfig/g' {} \;
poetry run isort -rc wagtail
poetry run black wagtail
git add .
git checkout -- docs/releases
git commit -m "Rename WagtailCoreAppConfig to WagtailAppConfig"

rm -rf wagtail/core
cp -r ../dummy_modules/core wagtail/core
poetry run isort -rc wagtail
poetry run black wagtail
git add .
git checkout -- docs/releases
git commit -m "Add dummy modules to maintain wagtail.core imports"
