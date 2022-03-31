#!/bin/bash
set -e

rm -rf wagtail
git clone https://github.com/wagtail/wagtail.git

cd wagtail

git checkout 97e781e31c3bb227970b174dc16fb7febb630571 -b restructure

echo "/.ropeproject" >> .gitignore


# Reorganise

poetry run roper move-module --source wagtail/compat.py --target wagtail/utils --do
poetry run roper move-module --source wagtail/telepath.py --target wagtail/utils --do
poetry run roper move-module --source wagtail/treebeard.py --target wagtail/utils --do
poetry run roper move-module --source wagtail/url_routing.py --target wagtail/utils --do
poetry run roper move-module --source wagtail/whitelist.py --target wagtail/utils --do
poetry run isort -rc wagtail
git add .
git checkout -- docs/releases
git commit -m "Move some modules into utils"

poetry run roper move-module --source wagtail/query.py --target wagtail/models --do
sed -i 's/from wagtail.models.sites import Site/from wagtail.models.sites import Site/g' wagtail/models/query.py
sed -i 's/from .models import WorkflowState/from .workflows import WorkflowState/g' wagtail/models/query.py
sed -i 's/from .models import PageRevision/from .pages import PageRevision/g' wagtail/models/query.py
sed -i 's/from wagtail.models import Page/from .pages import Page/g' wagtail/models/query.py
sed -i 's/from wagtail.models import PageViewRestriction/from .pages import PageViewRestriction/g' wagtail/models/query.py
find . -name '*.py' -exec sed -i 's/wagtail\.query/wagtail\.models\.query/g' {} \;
poetry run isort -rc wagtail
git add .
git checkout -- docs/releases
git commit -m "Move query into models"

poetry run roper rename-module --module wagtail/log_actions.py --to-name logging --do
poetry run isort -rc wagtail
git add .
git checkout -- docs/releases
git commit -m "Rename log_actions to logging"

poetry run roper move-by-name --name PageClassNotFoundError --source wagtail/exceptions.py --target wagtail/admin/views/pages/edit.py --do
rm wagtail/exceptions.py
poetry run isort -rc wagtail
git add .
git checkout -- docs/releases
git commit -m "Move PageClassNotFoundError to page edit view (the only place where it is thrown)"
# TODO: Fixup import https://github.com/wagtail/wagtail/pull/7656/commits/e93e9667a6e01c06f659babf95ce659c4a4611e0#diff-af279db108ccf16fa62b926938e314919e27b6df8919fa2dc07a7124f17dc9bdR16
