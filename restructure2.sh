#!/bin/bash
set -e

rm -rf wagtail
git clone git@github.com:wagtail/wagtail.git

cd wagtail

git checkout restructure
git checkout -b restructure2

# Move users into admin
poetry run roper move-module --source wagtail/users/views/groups.py --target wagtail/admin/views --do

poetry run roper move-module --source wagtail/users/views/users.py --target wagtail/admin/views --do

poetry run roper move-module --source wagtail/users/urls/users.py --target wagtail/admin/urls --do

poetry run roper rename-module --module wagtail/users/forms.py --to-name users --do
poetry run roper move-module --source wagtail/users/users.py --target wagtail/admin/forms --do

poetry run roper rename-module --module wagtail/users/widgets.py --to-name users --do
poetry run roper move-module --source wagtail/users/users.py --target wagtail/admin/widgets --do

poetry run roper rename-module --module wagtail/users/tests.py --to-name users --do
poetry run roper move-module --source wagtail/users/users.py --target wagtail/admin/tests --do

poetry run roper rename-module --module wagtail/users/utils.py --to-name usersutils --do
poetry run roper move-module --source wagtail/users/usersutils.py --target wagtail/admin --do

find . -name '*.py' -exec sed -i 's/wagtail.users.views.groups/wagtail.admin.views.groups/g' {} \;

poetry run isort -rc wagtail

git add .
git commit -m "Move users views into admin"

mv wagtail/users/static_src/wagtailusers wagtail/static_src/wagtailusers
sed -i "s/new App(path.join('wagtail', 'users'), {'appName': 'wagtailusers'}),/new App('wagtail', {'appName': 'wagtailusers'}),/g" gulpfile.js/config.js
find ./wagtail/static_src/wagtailusers -name '*.scss' -exec sed -i "s/\/..\/client\//\/client\//g" {} \;
#find . -name '*.js' -exec sed -i 's/wagtail\/users\/static_src/wagtail\/static_src/g' {} \;
poetry run isort -rc wagtail
git add .
git commit -m "Move users static into core"


poetry run roper rename-module --module wagtail/locales/views.py --to-name locales --do
poetry run roper move-module --source wagtail/locales/locales.py --target wagtail/admin/views --do
poetry run isort -rc wagtail
poetry run roper rename-module --module wagtail/locales/forms.py --to-name locales --do
poetry run roper move-module --source wagtail/locales/locales.py --target wagtail/admin/forms --do
poetry run roper rename-module --module wagtail/locales/tests.py --to-name locales --do
poetry run roper move-module --source wagtail/locales/locales.py --target wagtail/admin/tests --do
git add .
git commit -m "Move locales views into admin"

mv wagtail/locales/templates/wagtaillocales wagtail/templates/wagtaillocales
poetry run isort -rc wagtail
git add .
git commit -m "Move locales templates into core"

poetry run roper rename-module --module wagtail/snippets/models.py --to-name registry --do
poetry run roper move-module --source wagtail/snippets/blocks.py --target wagtail/blocks --do
poetry run roper rename-module --module wagtail/blocks/blocks.py --to-name snippets --do
cp ../dummy_modules/snippets/models.py wagtail/snippets/models.py
poetry run isort -rc wagtail
git add .
git commit -m "Move snippets into core"

poetry run roper rename-module --module wagtail/snippets/views --to-name snippets --do
poetry run roper move-module --source wagtail/snippets/snippets --target wagtail/admin/views --do
poetry run roper rename-module --module wagtail/snippets/urls.py --to-name snippets --do
poetry run roper move-module --source wagtail/snippets/snippets.py --target wagtail/admin/urls --do
poetry run roper rename-module --module wagtail/snippets/tests.py --to-name snippets --do
poetry run roper move-module --source wagtail/snippets/snippets.py --target wagtail/admin/tests --do
poetry run roper rename-module --module wagtail/snippets/widgets.py --to-name snippets --do
poetry run roper move-module --source wagtail/snippets/snippets.py --target wagtail/admin/widgets --do
poetry run isort -rc wagtail
git add .
git commit -m "Move snippets views into admin"

poetry run roper move-module --source wagtail/snippets/templatetags/wagtailsnippets_admin_tags.py --target wagtail/templatetags --do
rm wagtail/snippets/templatetags/__init__.py
poetry run isort -rc wagtail
git add .
git commit -m "Move snippets template tags into core"

mv wagtail/snippets/templates/wagtailsnippets wagtail/templates/wagtailsnippets
poetry run isort -rc wagtail
git add .
git commit -m "Move snippets templates into core"

mv wagtail/snippets/static_src/wagtailsnippets wagtail/static_src/wagtailsnippets
sed -i "s/new App(path.join('wagtail', 'snippets'), {'appName': 'wagtailsnippets'}),/new App('wagtail', {'appName': 'wagtailsnippets'}),/g" gulpfile.js/config.js
find ./wagtail/static_src/wagtailsnippets -name '*.scss' -exec sed -i "s/\/..\/client\//\/client\//g" {} \;
#find . -name '*.js' -exec sed -i 's/wagtail\/snippets\/static_src/wagtail\/static_src/g' {} \;
poetry run isort -rc wagtail
git add .
git commit -m "Move snippets static into core"

poetry run roper rename-module --module wagtail/sites/views --to-name sites --do
poetry run roper move-module --source wagtail/sites/sites --target wagtail/admin/views --do
poetry run roper rename-module --module wagtail/sites/tests.py --to-name sites --do
poetry run roper move-module --source wagtail/sites/sites.py --target wagtail/admin/tests --do
poetry run roper rename-module --module wagtail/sites/widgets.py --to-name sites --do
poetry run roper move-module --source wagtail/sites/sites.py --target wagtail/admin/widgets --do
poetry run isort -rc wagtail
git add .
git commit -m "Move sites views into admin"

# Temporary, run these to get the test set up
npm install
npm run build
