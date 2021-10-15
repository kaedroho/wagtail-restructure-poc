#!/bin/bash
set -e

rm -rf wagtail
git clone git@github.com:wagtail/wagtail.git

cd wagtail

git checkout b3366749d9b068ea1bc4ae01495e9d1b77ae2333 -b restructure

git apply --reject --whitespace=fix ../patches/pr7277.patch
git add .
git commit -m "Apply PR7277"

git apply --reject --whitespace=fix ../patches/pr7564.patch
git add .
git commit -m "Apply PR7564"

mv wagtail/api wagtail/core/api
find . -name '*.py' -exec sed -i 's/wagtail.api/wagtail.core.api/g' {} \;
git add .
git commit -m "Move wagtail.api to wagtail.core.api"

mv wagtail/admin wagtail/core/admin
find . -name '*.py' -exec sed -i 's/wagtail.admin/wagtail.core.admin/g' {} \;
git add .
git commit -m "Move wagtail.admin to wagtail.core.admin"

git apply --reject --whitespace=fix ../patches/merge-admin-and-core-signal-handlers.patch
git add .
git commit -m "Merge admin and core signal handlers"

cat wagtail/core/admin/wagtail_hooks.py >> wagtail/core/wagtail_hooks.py
git apply --reject --whitespace=fix ../patches/fixup-core-wagtail_hooks.patch
git add .
git commit -m "Merge admin and core Wagtail hooks"

mv wagtail/core/admin/edit_handlers.py wagtail/core/edit_handlers.py
git apply --reject --whitespace=fix ../patches/fix-core-edit_handlers-relative-imports.patch
find . -name '*.py' -exec sed -i 's/wagtail.core.admin.edit_handlers/wagtail.core.edit_handlers/g' {} \;
git apply --reject --whitespace=fix ../patches/move-edit_handlers-import-into-apps.patch
git add .
git commit -m "Move edit handlers to core"

mv wagtail/core/utils.py wagtail/core/coreutils.py
find . -name '*.py' -exec sed -i 's/wagtail.core.utils/wagtail.core.coreutils/g' {} \;
sed -i 's/..core.utils/wagtail.core.coreutils/g' wagtail/embeds/embeds.py
git add .
git commit -m "Move core.utils to core.coreutils"

mv wagtail/core/sites.py wagtail/core/siteutils.py
find . -name '*.py' -exec sed -i 's/wagtail.core.sites/wagtail.core.siteutils/g' {} \;
git add .
git commit -m "Move core.sites to core.siteutils"

mv wagtail/tests wagtail/test
find . -name '*.py' -exec sed -i 's/wagtail\.tests/wagtail\.test/g' {} \;
find . -name '*.py' -exec sed -i "s/os.path.join(WAGTAIL_ROOT, 'tests', 'testapp', 'jinja2_templates'),/os.path.join(WAGTAIL_ROOT, 'test', 'testapp', 'jinja2_templates'),/g" {} \;
git add .
git commit -m "Move tests to test"

cat wagtail/core/__init__.py >> wagtail/__init__.py
rm wagtail/core/__init__.py
git add .
git commit -m "Merge wagtail.core.__init__ with wagtail.__init__"

mv wagtail/core/* wagtail
find . -name '*.py' -exec sed -i 's/wagtail\.core/wagtail/g' {} \;
git add .
git commit -m "Move wagtail.core to wagtail"
