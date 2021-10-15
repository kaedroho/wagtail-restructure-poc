#!/bin/bash
set -e

rm -rf wagtail
git clone git@github.com:wagtail/wagtail.git

cd wagtail

git checkout b3366749d9b068ea1bc4ae01495e9d1b77ae2333 -b restructure

echo "/.ropeproject" >> .gitignore


# Apply A couple of PRs that make the restructuring easier
# 7277 "Move Query model to search promotions" https://github.com/wagtail/wagtail/pull/7277
# 7564 "Move UserProfile into wagtailcore" https://github.com/wagtail/wagtail/pull/7564

git apply --reject --whitespace=fix ../patches/pr7277.patch
git add .
git commit -m "Apply PR7277"

git apply --reject --whitespace=fix ../patches/pr7564.patch
# git apply doesn't seem to like deleting stuff
rm wagtail/users/models.py
git add .
git commit -m "Apply PR7564"


# Rename wagtail.core to wagtail
# This part starts off with a few renames to resolves conflicts, then moves everthing under wagtail/core to the top level

roper rename-module --module wagtail/core/utils.py --to-name coreutils --do
find . -name '*.rst' -exec sed -i 's/wagtail.core.utils/wagtail.core.coreutils/g' {} \;
find . -name '*.md' -exec sed -i 's/wagtail.core.utils/wagtail.core.coreutils/g' {} \;
git add .
git commit -m "Move core.utils to core.coreutils"

roper rename-module --module wagtail/core/sites.py --to-name siteutils --do
find . -name '*.rst' -exec sed -i 's/wagtail.core.sites/wagtail.core.siteutils/g' {} \;
find . -name '*.md' -exec sed -i 's/wagtail.core.sites/wagtail.core.siteutils/g' {} \;
git add .
git commit -m "Move core.sites to core.siteutils"

roper rename-module --module wagtail/tests --to-name test --do
# Need to update .py files here since wagtail.tests appears a lot in strings
# Also, escaping . for this one since wagtail_tests appears often
find . -name '*.py' -exec sed -i 's/wagtail\.tests/wagtail\.test/g' {} \;
find . -name '*.rst' -exec sed -i 's/wagtail\.tests/wagtail\.test/g' {} \;
find . -name '*.md' -exec sed -i 's/wagtail\.tests/wagtail\.test/g' {} \;
sed -i "s/os.path.join(WAGTAIL_ROOT, 'tests', 'testapp', 'jinja2_templates'),/os.path.join(WAGTAIL_ROOT, 'test', 'testapp', 'jinja2_templates'),/g" wagtail/test/settings.py
git add .
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
git add .
git commit -m "Move wagtail.core to wagtail"


# Merge admin into core

roper move-module --source wagtail/admin/edit_handlers.py --target wagtail --do
find . -name '*.py' -exec sed -i 's/wagtail.admin.edit_handlers/wagtail.edit_handlers/g' {} \;
find . -name '*.rst' -exec sed -i 's/wagtail.admin.edit_handlers/wagtail.edit_handlers/g' {} \;
find . -name '*.md' -exec sed -i 's/wagtail.admin.edit_handlers/wagtail.edit_handlers/g' {} \;

git add .
git commit -m "Move edit handlers to wagtail.edit_handlers"

roper move-module --source wagtail/admin/models.py --target wagtail/models --do
roper rename-module --module wagtail/models/models.py --to-name admin --do
# Note --pythonpath=. stops Python from looking for pip-installed Wagtail
django-admin makemigrations --pythonpath=. --settings=wagtail.test.settings
git add .
git commit -m "Move admin models into core"
