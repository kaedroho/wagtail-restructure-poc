#!/bin/bash
set -e

rm -rf wagtail
git clone https://github.com/wagtail/wagtail.git

cd wagtail

git checkout 97e781e31c3bb227970b174dc16fb7febb630571 -b restructure

# Reorganise

poetry run roper move-module --source wagtail/compat.py --target wagtail/utils --do
poetry run roper move-module --source wagtail/telepath.py --target wagtail/utils --do
poetry run roper move-module --source wagtail/treebeard.py --target wagtail/utils --do
poetry run roper move-module --source wagtail/url_routing.py --target wagtail/utils --do
poetry run roper move-module --source wagtail/log_actions.py --target wagtail/utils --do
poetry run roper move-module --source wagtail/coreutils.py --target wagtail/utils --do
poetry run roper move-module --source wagtail/widget_adapters.py --target wagtail/utils --do
poetry run roper move-module --source wagtail/models/copying.py --target wagtail/utils --do
poetry run roper move-module --source wagtail/admin/staticfiles.py --target wagtail/utils --do
poetry run isort .
poetry run black .
git add wagtail
git commit -m "Move some modules into utils"

touch wagtail/utils/models.py
poetry run roper move-by-name --name get_streamfield_names --source wagtail/models/__init__.py --target wagtail/utils/models.py --do
poetry run roper move-by-name --name get_concrete_descendants --source wagtail/workflows.py --target wagtail/utils/models.py --do
poetry run roper move-by-name --name resolve_model_string --source wagtail/utils/coreutils.py --target wagtail/utils/models.py --do
poetry run roper move-by-name --name get_model_string --source wagtail/utils/coreutils.py --target wagtail/utils/models.py --do
poetry run isort .
poetry run black .
git add wagtail
git commit -m "Create utils/models.py"

touch wagtail/utils/i18n.py
poetry run roper move-by-name --name reset_cache --source wagtail/utils/coreutils.py --target wagtail/utils/i18n.py --do
poetry run roper move-by-name --name get_locales_display_names --source wagtail/utils/coreutils.py --target wagtail/utils/i18n.py --do
poetry run roper move-by-name --name get_supported_content_language_variant --source wagtail/utils/coreutils.py --target wagtail/utils/i18n.py --do
poetry run roper move-by-name --name get_content_languages --source wagtail/utils/coreutils.py --target wagtail/utils/i18n.py --do
poetry run isort .
poetry run black .
git add wagtail
git commit -m "Create utils/i18n.py"

touch wagtail/utils/text.py
poetry run roper move-by-name --name camelcase_to_underscore --source wagtail/utils/coreutils.py --target wagtail/utils/text.py --do
poetry run roper move-by-name --name string_to_ascii --source wagtail/utils/coreutils.py --target wagtail/utils/text.py --do
poetry run roper move-by-name --name SLUGIFY_RE --source wagtail/utils/coreutils.py --target wagtail/utils/text.py --do
poetry run roper move-by-name --name cautious_slugify --source wagtail/utils/coreutils.py --target wagtail/utils/text.py --do
poetry run roper move-by-name --name safe_snake_case --source wagtail/utils/coreutils.py --target wagtail/utils/text.py --do
poetry run isort .
poetry run black .
git add wagtail
git commit -m "Create utils/text.py"

touch wagtail/utils/html.py
poetry run roper move-by-name --name escape_script --source wagtail/utils/coreutils.py --target wagtail/utils/text.py --do
poetry run roper move-by-name --name SCRIPT_RE --source wagtail/utils/coreutils.py --target wagtail/utils/text.py --do
poetry run isort .
poetry run black .
git add wagtail
git commit -m "Create utils/html.py"

touch wagtail/utils/batch.py
poetry run roper move-by-name --name BatchCreator --source wagtail/utils/coreutils.py --target wagtail/utils/batch.py --do
poetry run roper move-by-name --name BatchProcessor --source wagtail/utils/coreutils.py --target wagtail/utils/batch.py --do
poetry run isort .
poetry run black .
git add wagtail
git commit -m "Create utils/batch.py"

poetry run roper rename-module --module wagtail/utils/coreutils.py --to-name misc --do
poetry run isort .
poetry run black .
git add wagtail
git commit -m "Rename utils/coreutils.py to utils/misc.py"

poetry run roper move-by-name --name deep_update --source wagtail/utils/utils.py --target wagtail/utils/misc.py --do
rm wagtail/utils/utils.py
poetry run isort .
poetry run black .
git add wagtail
git commit -m "Move deep_update into utils/misc.py"

poetry run roper rename-module --module wagtail/utils/log_actions.py --to-name logging --do
poetry run isort .
poetry run black .
git add wagtail
git commit -m "Rename utils/log_actions.py to utils/logging.py"

poetry run roper move-module --source wagtail/query.py --target wagtail/models --do
find . -name '*.py' -exec sed -i 's/wagtail\.query/wagtail\.models\.query/g' {} \;
poetry run isort .
poetry run black .
git add wagtail
git commit -m "Move query into models"

poetry run roper move-module --source wagtail/whitelist.py --target wagtail/rich_text --do
poetry run roper rename-module --module wagtail/rich_text/whitelist.py --to-name cleaner --do
find . -name '*.py' -exec sed -i 's/Whitelister/HTMLCleaner/g' {} \;
find . -name '*.md' -exec sed -i 's/Whitelister/HTMLCleaner/g' {} \;
find . -name '*.rst' -exec sed -i 's/Whitelister/HTMLCleaner/g' {} \;
poetry run isort .
poetry run black .
git add wagtail
git commit -m "Move/Rename whitelister.Whitelist to rich_text.cleaner.HTMLCleaner"

poetry run roper move-by-name --name PageClassNotFoundError --source wagtail/exceptions.py --target wagtail/admin/views/pages/edit.py --do
rm wagtail/exceptions.py
poetry run isort .
poetry run black .
git add wagtail
git commit -m "Move PageClassNotFoundError to page edit view (the only place where it is thrown)"
