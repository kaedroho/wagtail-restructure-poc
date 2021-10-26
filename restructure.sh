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
poetry run isort -rc wagtail
git add .
git commit -m "Apply PR7277"

git apply --reject --whitespace=fix ../patches/pr7564.patch
# git apply doesn't seem to like deleting stuff
rm wagtail/users/models.py
poetry run isort -rc wagtail
git add .
git commit -m "Apply PR7564"


# Rename wagtail.core to wagtail
# This part starts off with a few renames to resolves conflicts, then moves everthing under wagtail/core to the top level

poetry run roper rename-module --module wagtail/core/utils.py --to-name coreutils --do
find . -name '*.rst' -exec sed -i 's/wagtail.core.utils/wagtail.core.coreutils/g' {} \;
find . -name '*.md' -exec sed -i 's/wagtail.core.utils/wagtail.core.coreutils/g' {} \;
poetry run isort -rc wagtail
git add .
git commit -m "Move core.utils to core.coreutils"

poetry run roper move-by-name --name get_site_for_hostname --source wagtail/core/sites.py --target wagtail/core/models/sites.py --do
poetry run roper move-by-name --name MATCH_HOSTNAME --source wagtail/core/sites.py --target wagtail/core/models/sites.py --do
poetry run roper move-by-name --name MATCH_DEFAULT --source wagtail/core/sites.py --target wagtail/core/models/sites.py --do
poetry run roper move-by-name --name MATCH_HOSTNAME_DEFAULT --source wagtail/core/sites.py --target wagtail/core/models/sites.py --do
poetry run roper move-by-name --name MATCH_HOSTNAME_PORT --source wagtail/core/sites.py --target wagtail/core/models/sites.py --do
rm wagtail/core/sites.py
git apply --reject --whitespace=fix ../patches/fixup-sites-models.patch
poetry run isort -rc wagtail
git add .
git commit -m "Merge sites utilities into sites models"

poetry run roper rename-module --module wagtail/tests --to-name test --do
# Need to update .py files here since wagtail.tests appears a lot in strings
# Also, escaping . for this one since wagtail_tests appears often
find . -name '*.py' -exec sed -i 's/wagtail\.tests/wagtail\.test/g' {} \;
find . -name '*.rst' -exec sed -i 's/wagtail\.tests/wagtail\.test/g' {} \;
find . -name '*.md' -exec sed -i 's/wagtail\.tests/wagtail\.test/g' {} \;
sed -i "s/os.path.join(WAGTAIL_ROOT, 'tests', 'testapp', 'jinja2_templates'),/os.path.join(WAGTAIL_ROOT, 'test', 'testapp', 'jinja2_templates'),/g" wagtail/test/settings.py
poetry run isort -rc wagtail
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
poetry run isort -rc wagtail
git add .
git commit -m "Move wagtail.core to wagtail"

find . -name '*.py' -exec sed -i 's/WagtailCoreAppConfig/WagtailAppConfig/g' {} \;
find . -name '*.rst' -exec sed -i 's/WagtailCoreAppConfig/WagtailAppConfig/g' {} \;
find . -name '*.md' -exec sed -i 's/WagtailCoreAppConfig/WagtailAppConfig/g' {} \;
poetry run isort -rc wagtail
git add .
git commit -m "Rename WagtailCoreAppConfig to WagtailAppConfig"

rm -rf wagtail/core
cp -r ../dummy_modules/core wagtail/core
poetry run isort -rc wagtail
git add .
git commit -m "Add dummy modules to maintain wagtail.core imports"


# Merge admin into core
# TODO: Merge signal handlers

poetry run roper move-module --source wagtail/admin/edit_handlers.py --target wagtail --do
find . -name '*.py' -exec sed -i 's/wagtail.admin.edit_handlers/wagtail.edit_handlers/g' {} \;
find . -name '*.rst' -exec sed -i 's/wagtail.admin.edit_handlers/wagtail.edit_handlers/g' {} \;
find . -name '*.md' -exec sed -i 's/wagtail.admin.edit_handlers/wagtail.edit_handlers/g' {} \;
cp -r ../dummy_modules/admin/edit_handlers.py wagtail/admin/edit_handlers.py
poetry run isort -rc wagtail
git add .
git commit -m "Move edit handlers to wagtail.edit_handlers"

poetry run roper move-module --source wagtail/admin/models.py --target wagtail/models --do
poetry run roper rename-module --module wagtail/models/models.py --to-name admin --do
# Note --pythonpath=. stops Python from looking for pip-installed Wagtail
poetry run django-admin makemigrations --pythonpath=. --settings=wagtail.test.settings
poetry run isort -rc wagtail
git add .
git commit -m "Move admin models into core"

# TODO: This migration doesn't copy the wagtailadmin.can_access_permission. It just creates a new one
cp ../patches/0070_create_admin_access_permissions.py wagtail/migrations/0070_create_admin_access_permissions.py
# Rename all occurances of wagtailadmin.can_access_admin permission
find . -name '*.py' -exec sed -i 's/wagtailadmin\.access_admin/wagtailcore\.access_admin/g' {} \;
find . -name '*.py' -exec sed -i "s/content_type__app_label='wagtailadmin'/content_type__app_label='wagtailcore'/g" {} \;
find . -name '*.json' -exec sed -i 's/\["access_admin", "wagtailadmin", "admin"\]/\["access_admin", "wagtailcore", "admin"\]/g' {} \;
sed -i "s/app_label='wagtailadmin',/app_label='wagtailcore',/g" wagtail/admin/tests/pages/test_revisions.py
sed -i "s/app_label='wagtailadmin',/app_label='wagtailcore',/g" wagtail/contrib/settings/tests/test_admin.py
poetry run isort -rc wagtail
git add .
git commit -m "Add wagtailcore.can_access_admin permisison"

mv wagtail/admin/templates/* wagtail/templates
git add .
git commit -m "Move admin templates into core"

mv wagtail/admin/static_src wagtail/static_src
sed -i 's/wagtail\/admin\/static_src/wagtail\/static_src/g' package.json
sed -i 's/wagtail\/wagtailadmin\/static_src/wagtail\/static_src/g' MANIFEST.in
sed -i "s/new App(path.join('wagtail', 'admin'), {'appName': 'wagtailadmin'}),/new App('wagtail', {'appName': 'wagtailadmin'}),/g" gulpfile.js/config.js
sed -i 's/wagtail\/wagtailadmin\/static\//wagtail\/static\//g' wagtail/utils/setup.py
git apply --reject --whitespace=fix ../patches/move-admin-static-to-top-level-app.patch
# TODO: Move this check into core instead
sed -i "s/os.path.dirname(__file__), 'static', 'wagtailadmin', 'css', 'normalize.css'/os.path.dirname(os.path.dirname(__file__)), 'static', 'wagtailadmin', 'css', 'normalize.css'/g" wagtail/admin/checks.py
find ./wagtail/static_src -name '*.scss' -exec sed -i "s/\/..\/client\//\/client\//g" {} \;
find . -name '*.js' -exec sed -i 's/wagtail\/admin\/static_src/wagtail\/static_src/g' {} \;
poetry run isort -rc wagtail
git add .
git commit -m "Move admin static into core"
# TODO: Update storybook.tsx files

poetry run roper move-module --source wagtail/admin/templatetags/wagtailadmin_tags.py --target wagtail/templatetags --do
# poetry run roper crashes if we don't make this particular import absolute
sed -i 's/from .templatetags.wagtailuserbar import wagtailuserbar/from wagtail.admin.templatetags.wagtailuserbar import wagtailuserbar/g' wagtail/admin/jinja2tags.py
poetry run roper move-module --source wagtail/admin/templatetags/wagtailuserbar.py --target wagtail/templatetags --do
rm wagtail/admin/templatetags/__init__.py
poetry run isort -rc wagtail
git add .
git commit -m "Move admin templatetags into core"

poetry run python ../catlocales.py wagtail/admin/locale wagtail/locale
rm -rf wagtail/admin/locale
pushd scripts
poetry run bash -C "./rebuild-translation-sources.sh"
popd
git add .
git commit -m "Move admin locale files into core"

mkdir wagtail/wagtail_hooks
poetry run roper rename-module --module wagtail/wagtail_hooks.py --to-name core --do
poetry run roper move-module --source wagtail/core.py --target wagtail/wagtail_hooks --do
poetry run roper rename-module --module wagtail/admin/wagtail_hooks.py --to-name admin --do
poetry run roper move-module --source wagtail/admin/admin.py --target wagtail/wagtail_hooks --do
touch wagtail/wagtail_hooks/utils.py
poetry run roper move-by-name --source wagtail/wagtail_hooks/core.py --name require_wagtail_login --target wagtail/wagtail_hooks/utils.py --do
cat << EOF > wagtail/wagtail_hooks/__init__.py
"""
Temporarily made this into a folder to make it easier to automate the merging
Will concatenate these files later
"""

from .core import *  # noqa
from .admin import *  # noqa
from .utils import *  # noqa
EOF
sed -i 's/from wagtail.wagtail_hooks import require_wagtail_login, utils/from wagtail.wagtail_hooks import utils/g' wagtail/contrib/documents/wagtail_hooks.py
git add .
poetry run isort -rc wagtail
git commit -m "Move admin wagtail_hooks.py into core"

git apply --reject --whitespace=fix ../patches/remove-admin-from-installed-apps.patch
git add .
poetry run isort -rc wagtail
git commit -m "No longer necessary to add 'wagtail.admin' to INSTALLED_APPS"


# Break up core models

touch wagtail/models/workflows.py
poetry run roper move-by-name --name TaskState --source wagtail/models/__init__.py --target wagtail/models/workflows.py --do
poetry run roper move-by-name --name TaskStateManager --source wagtail/models/__init__.py --target wagtail/models/workflows.py --do
poetry run roper move-by-name --name WorkflowState --source wagtail/models/__init__.py --target wagtail/models/workflows.py --do
poetry run roper move-by-name --name WorkflowStateManager --source wagtail/models/__init__.py --target wagtail/models/workflows.py --do
poetry run roper move-by-name --name GroupApprovalTask --source wagtail/models/__init__.py --target wagtail/models/workflows.py --do
poetry run roper move-by-name --name Workflow --source wagtail/models/__init__.py --target wagtail/models/workflows.py --do
poetry run roper move-by-name --name WorkflowManager --source wagtail/models/__init__.py --target wagtail/models/workflows.py --do
poetry run roper move-by-name --name Task --source wagtail/models/__init__.py --target wagtail/models/workflows.py --do
poetry run roper move-by-name --name TaskManager --source wagtail/models/__init__.py --target wagtail/models/workflows.py --do
poetry run roper move-by-name --name WorkflowTask --source wagtail/models/__init__.py --target wagtail/models/workflows.py --do

sed -i 's/import wagtail.workflows.forms//g' wagtail/models/__init__.py
sed -i 's/import wagtail.models.workflows//g' wagtail/models/__init__.py
sed -i 's/wagtail.models.workflows.WorkflowState/WorkflowState/g' wagtail/models/__init__.py

sed -i 's/import wagtail.models.workflows//g' wagtail/query.py
sed -i 's/wagtail.models.workflows.WorkflowState/WorkflowState/g' wagtail/query.py

sed -i 's/from wagtail.models import Page, UserProfile, WorkflowPage, workflows/from wagtail.models import Page, UserProfile, WorkflowPage, WorkflowTask, Workflow, WorkflowState, TaskState, Task, GroupApprovalTask/g' wagtail/admin/tests/test_workflows.py
sed -i 's/workflows.Workflow/Workflow/g' wagtail/admin/tests/test_workflows.py
sed -i 's/workflows.Task/Task/g' wagtail/admin/tests/test_workflows.py
sed -i 's/workflows.WorkflowTask/WorkflowTask/g' wagtail/admin/tests/test_workflows.py
sed -i 's/workflows.GroupApprovalTask/GroupApprovalTask/g' wagtail/admin/tests/test_workflows.py
sed -i 's/workflows.WorkflowState/WorkflowState/g' wagtail/admin/tests/test_workflows.py
sed -i 's/workflows.TaskState/TaskState/g' wagtail/admin/tests/test_workflows.py
sed -i 's/workflows.TaskState/TaskState/g' wagtail/admin/tests/test_workflows.py

git apply --reject --whitespace=fix ../patches/workflow-models-fixup-imports.patch

poetry run isort -rc wagtail

git add .
git commit -m "Extract workflows models into separate module"


touch wagtail/models/logging.py
poetry run roper move-by-name --name PageLogEntry --source wagtail/models/__init__.py --target wagtail/models/logging.py --do
poetry run roper move-by-name --name PageLogEntryManager --source wagtail/models/__init__.py --target wagtail/models/logging.py --do
poetry run roper move-by-name --name PageLogEntryQuerySet --source wagtail/models/__init__.py --target wagtail/models/logging.py --do

git apply --reject --whitespace=fix ../patches/logging-models-fixup-imports.patch

poetry run isort -rc wagtail
git add .
git commit -m "Extract logging models into separate module"


touch wagtail/models/commenting.py
poetry run roper move-by-name --name PageSubscription --source wagtail/models/__init__.py --target wagtail/models/commenting.py --do
poetry run roper move-by-name --name CommentReply --source wagtail/models/__init__.py --target wagtail/models/commenting.py --do
poetry run roper move-by-name --name Comment --source wagtail/models/__init__.py --target wagtail/models/commenting.py --do
poetry run roper move-by-name --name COMMENTS_RELATION_NAME --source wagtail/models/__init__.py --target wagtail/models/commenting.py --do

sed -i 's/import wagtail.models.commenting/from .commenting import COMMENTS_RELATION_NAME, Comment/g' wagtail/models/__init__.py
sed -i 's/wagtail.models.commenting.COMMENTS_RELATION_NAME/COMMENTS_RELATION_NAME/g' wagtail/models/__init__.py
sed -i 's/wagtail.models.commenting.Comment.DoesNotExist/Comment.DoesNotExist/g' wagtail/models/__init__.py

git apply --reject --whitespace=fix ../patches/fixup-commenting-models.patch
git apply --reject --whitespace=fix ../patches/commenting-models-fixup-imports.patch

poetry run isort -rc wagtail

git add .
git commit -m "Extract commenting models into separate module"


mv wagtail/models/__init__.py wagtail/models/pages.py
cat << EOF > wagtail/models/__init__.py
from .copying import _copy, _copy_m2m_relations  # noqa
from .i18n import Locale, TranslatableMixin, BootstrapTranslatableModel, get_translatable_models  # noqa
from .sites import Site, SiteRootPath  # noqa
from .view_restrictions import BaseViewRestriction  # noqa
from .pages import Page, PageRevision, PageManager, PageQuerySet, WAGTAIL_APPEND_SLASH, ParentNotTranslatedError, PAGE_MODEL_CLASSES, PageViewRestriction, PAGE_PERMISSION_TYPES, PAGE_PERMISSION_TYPE_CHOICES, get_default_page_content_type, UserPagePermissionsProxy, GroupPagePermission, WorkflowPage, Orderable, get_page_models, PAGE_TEMPLATE_VAR  # noqa
from .collections import Collection, CollectionViewRestriction, CollectionMember, get_root_collection_id, GroupCollectionPermission  # noqa
from .user_profile import UserProfile  # noqa
from .audit_log import ModelLogEntry  # noqa
from .workflows import WorkflowPage, WorkflowTask, Workflow, WorkflowState, TaskState, Task, GroupApprovalTask  # noqa
EOF
# There's a test that patches ContentType
find . -name '*.py' -exec sed -i 's/wagtail.models.ContentType/wagtail.models.pages.ContentType/g' {} \;

git apply --reject --whitespace=fix ../patches/fixup-pages-models.patch
git apply --reject --whitespace=fix ../patches/pages-models-fixup-imports.patch

poetry run isort -rc wagtail

git add .
git commit -m "Extract pages models into separate module"


# Reorganise

poetry run roper move-by-name --name UserProfile --source wagtail/models/user_profile.py --target wagtail/models/admin.py --do
poetry run roper move-by-name --name upload_avatar_to --source wagtail/models/user_profile.py --target wagtail/models/admin.py --do
rm wagtail/models/user_profile.py
sed -i 's/from .user_profile import/from .admin import/g' wagtail/models/__init__.py
rm wagtail/core/models/user_profile.py
cat << EOF > wagtail/core/models/user_profile.py
from wagtail.models.admin import UserProfile  # noqa
EOF
poetry run isort -rc wagtail
git add .
git commit -m "Move UserProfile into admin models"
# TODO: Some fixups to make https://github.com/wagtail/wagtail/pull/7656/commits/9f2926848e8439ab27950df6fe67f995baa1ff58

poetry run roper move-by-name --name ModelLogEntry --source wagtail/models/audit_log.py --target wagtail/models/logging.py --do
poetry run roper move-by-name --name ModelLogEntryManager --source wagtail/models/audit_log.py --target wagtail/models/logging.py --do
poetry run roper move-by-name --name BaseLogEntry --source wagtail/models/audit_log.py --target wagtail/models/logging.py --do
poetry run roper move-by-name --name BaseLogEntryManager --source wagtail/models/audit_log.py --target wagtail/models/logging.py --do
poetry run roper move-by-name --name LogEntryQuerySet --source wagtail/models/audit_log.py --target wagtail/models/logging.py --do
rm wagtail/models/audit_log.py
sed -i 's/from .audit_log import/from .logging import/g' wagtail/models/__init__.py
rm wagtail/core/models/audit_log.py
cat << EOF > wagtail/core/models/audit_log.py
from wagtail.models.logging import (  # noqa
    BaseLogEntry, BaseLogEntryManager, LogEntryQuerySet, ModelLogEntry)
EOF
poetry run isort -rc wagtail
git add .
git commit -m "Move ModelLogEntry into logging models"
# TODO: Fix https://github.com/wagtail/wagtail/pull/7656/commits/a5f0c7b78a1c0627dc02c9167729e9dd744b0344#diff-3ecb3133f5568a5901012a361d91dbfbdc0c46fdbf96cbe3c5f08db3c36d7ca2L194

find . -name '*.py' -exec sed -i 's/from wagtail.admin.forms import WagtailAdminPageForm/from wagtail.admin.forms.pages import WagtailAdminPageForm/g' {} \;
git apply --reject --whitespace=fix ../patches/fixup-edit-handlers-models-admin-forms.patch
poetry run isort -rc wagtail
git add .
git commit -m "Fixup edit handlers, admin forms, and page models"

poetry run roper move-module --source wagtail/compat.py --target wagtail/utils --do
poetry run roper move-module --source wagtail/telepath.py --target wagtail/utils --do
poetry run roper move-module --source wagtail/treebeard.py --target wagtail/utils --do
poetry run roper move-module --source wagtail/url_routing.py --target wagtail/utils --do
poetry run roper move-module --source wagtail/whitelist.py --target wagtail/utils --do
poetry run isort -rc wagtail
git add .
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
git commit -m "Move query into models"

poetry run roper rename-module --module wagtail/log_actions.py --to-name logging --do
poetry run isort -rc wagtail
git add .
git commit -m "Rename log_actions to logging"

poetry run roper move-by-name --name PageClassNotFoundError --source wagtail/exceptions.py --target wagtail/admin/views/pages/edit.py --do
rm wagtail/exceptions.py
poetry run isort -rc wagtail
git add .
git commit -m "Move PageClassNotFoundError to page edit view (the only place where it is thrown)"
# TODO: Fixup import https://github.com/wagtail/wagtail/pull/7656/commits/e93e9667a6e01c06f659babf95ce659c4a4611e0#diff-af279db108ccf16fa62b926938e314919e27b6df8919fa2dc07a7124f17dc9bdR16


# Move some apps into contrib
# TODO: don't update release notes

mv wagtail/images wagtail/contrib/images
find . -name '*.py' -exec sed -i 's/wagtail\.images/wagtail\.contrib\.images/g' {} \;
find . -name '*.rst' -exec sed -i 's/wagtail\.images/wagtail\.contrib\.images/g' {} \;
find . -name '*.md' -exec sed -i 's/wagtail\.images/wagtail\.contrib\.images/g' {} \;
sed -i "s/new App(path.join('wagtail', 'images'), {'appName': 'wagtailimages'}),/new App(path.join('wagtail', 'contrib', 'images'), {'appName': 'wagtailimages'}),/g" gulpfile.js/config.js
cp -r ../dummy_modules/images wagtail/images
poetry run isort -rc wagtail
git add .
git commit -m "Move images to contrib"

mv wagtail/documents wagtail/contrib/documents
find . -name '*.py' -exec sed -i 's/wagtail\.documents/wagtail\.contrib\.documents/g' {} \;
find . -name '*.rst' -exec sed -i 's/wagtail\.documents/wagtail\.contrib\.documents/g' {} \;
find . -name '*.md' -exec sed -i 's/wagtail\.documents/wagtail\.contrib\.documents/g' {} \;
sed -i "s/new App(path.join('wagtail', 'documents'), {'appName': 'wagtaildocs'}),/new App(path.join('wagtail', 'contrib', 'documents'), {'appName': 'wagtaildocs'}),/g" gulpfile.js/config.js
cp -r ../dummy_modules/documents wagtail/documents
poetry run isort -rc wagtail
git add .
git commit -m "Move documents to contrib"

mv wagtail/embeds wagtail/contrib/embeds
find . -name '*.py' -exec sed -i 's/wagtail\.embeds/wagtail\.contrib\.embeds/g' {} \;
find . -name '*.rst' -exec sed -i 's/wagtail\.embeds/wagtail\.contrib\.embeds/g' {} \;
find . -name '*.md' -exec sed -i 's/wagtail\.embeds/wagtail\.contrib\.embeds/g' {} \;
sed -i "s/new App(path.join('wagtail', 'embeds'), {'appName': 'wagtailembeds'}),/new App(path.join('wagtail', 'contrib', 'embeds'), {'appName': 'wagtailembeds'}),/g" gulpfile.js/config.js
cp -r ../dummy_modules/embeds wagtail/embeds
poetry run isort -rc wagtail
git add .
git commit -m "Move embeds to contrib"

mv wagtail/snippets wagtail/contrib/snippets
find . -name '*.py' -exec sed -i 's/wagtail\.snippets/wagtail\.contrib\.snippets/g' {} \;
find . -name '*.rst' -exec sed -i 's/wagtail\.snippets/wagtail\.contrib\.snippets/g' {} \;
find . -name '*.md' -exec sed -i 's/wagtail\.snippets/wagtail\.contrib\.snippets/g' {} \;
sed -i "s/new App(path.join('wagtail', 'snippets'), {'appName': 'wagtailsnippets'}),/new App(path.join('wagtail', 'contrib', 'snippets'), {'appName': 'wagtailsnippets'}),/g" gulpfile.js/config.js
cp -r ../dummy_modules/snippets wagtail/snippets
poetry run isort -rc wagtail
git add .
git commit -m "Move snippets to contrib"


# Merge users/locales/sites

# Move users into admin
# TODO: Importing admin.urls causes circular import issue
# https://github.com/wagtail/wagtail/pull/7656/commits/7ef7707062bdf3075c6ff7818bbf61dd80b08acf#diff-0b865de16d935928e64c9a1000b7cfbfa775457e0e703cb4ab83c50a79ad9e30R14
poetry run roper move-module --source wagtail/users/views/groups.py --target wagtail/admin/views --do

poetry run roper move-module --source wagtail/users/views/users.py --target wagtail/admin/views --do

poetry run roper move-module --source wagtail/users/urls/users.py --target wagtail/admin/urls --do
rm wagtail/users/urls/__init__.py

poetry run roper rename-module --module wagtail/users/forms.py --to-name users --do
poetry run roper move-module --source wagtail/users/users.py --target wagtail/admin/forms --do

poetry run roper rename-module --module wagtail/users/widgets.py --to-name users --do
poetry run roper move-module --source wagtail/users/users.py --target wagtail/admin/widgets --do

poetry run roper rename-module --module wagtail/users/tests.py --to-name test_users --do
poetry run roper move-module --source wagtail/users/test_users.py --target wagtail/admin/tests --do

poetry run roper rename-module --module wagtail/users/utils.py --to-name usersutils --do
poetry run roper move-module --source wagtail/users/usersutils.py --target wagtail/admin --do

find . -name '*.py' -exec sed -i 's/wagtail.users.views.groups/wagtail.admin.views.groups/g' {} \;
find . -name '*.py' -exec sed -i 's/wagtail.users.tests/wagtail.admin.tests.users/g' {} \;

git apply --reject --whitespace=fix ../patches/update-custom-users-models-docs.patch
git apply --reject --whitespace=fix ../patches/update-customising-group-views-docs.patch

rm wagtail/users/views/__init__.py

poetry run isort -rc wagtail

git add .
git commit -m "Move users views/forms/widgets/utils/tests into admin"

poetry run roper move-module --source wagtail/users/templatetags/wagtailusers_tags.py --target wagtail/templatetags --do
rm wagtail/users/templatetags/__init__.py
poetry run isort -rc wagtail
git add .
git commit -m "Move users templatetags into core"

mv wagtail/users/templates/wagtailusers wagtail/templates/wagtailusers
poetry run isort -rc wagtail
git add .
git commit -m "Move users templates into core"

mv wagtail/users/static_src/wagtailusers wagtail/static_src/wagtailusers
sed -i "s/new App(path.join('wagtail', 'users'), {'appName': 'wagtailusers'}),/new App('wagtail', {'appName': 'wagtailusers'}),/g" gulpfile.js/config.js
find ./wagtail/static_src/wagtailusers -name '*.scss' -exec sed -i "s/\/..\/client\//\/client\//g" {} \;
poetry run isort -rc wagtail
git add .
git commit -m "Move users static into core"

poetry run python ../catlocales.py wagtail/users/locale wagtail/locale
rm -rf wagtail/users/locale
pushd scripts
poetry run bash -C "./rebuild-translation-sources.sh"
popd
git add .
git commit -m "Move users locale files into core"

poetry run roper rename-module --module wagtail/users/wagtail_hooks.py --to-name users --do
poetry run roper move-module --source wagtail/users/users.py --target wagtail/wagtail_hooks --do
echo "from .users import *  # noqa" >> wagtail/wagtail_hooks/__init__.py
git apply --reject --whitespace=fix ../patches/allow-group_viewset-to-be-specified-on-WagtailAppCon.patch
poetry run isort -rc wagtail
git add .
git commit -m "Move users wagtail_hooks into core"

git apply --reject --whitespace=fix ../patches/wagtail.users-no-longer-needs-to-be-installed.patch
poetry run isort -rc wagtail
git add .
git commit -m "'wagtail.users' no longer needs to be added to INSTALLED_APPS"


poetry run roper rename-module --module wagtail/locales/views.py --to-name locales --do
poetry run roper move-module --source wagtail/locales/locales.py --target wagtail/admin/views --do
poetry run isort -rc wagtail
poetry run roper rename-module --module wagtail/locales/forms.py --to-name locales --do
poetry run roper move-module --source wagtail/locales/locales.py --target wagtail/admin/forms --do
poetry run roper rename-module --module wagtail/locales/tests.py --to-name test_locales --do
poetry run roper move-module --source wagtail/locales/test_locales.py --target wagtail/admin/tests --do
poetry run roper rename-module --module wagtail/locales/utils.py --to-name locales --do
poetry run roper move-module --source wagtail/locales/locales.py --target wagtail/admin --do
git add .
git commit -m "Move locales views into admin"

mv wagtail/locales/templates/wagtaillocales wagtail/templates/wagtaillocales
poetry run isort -rc wagtail
git add .
git commit -m "Move locales templates into core"

poetry run python ../catlocales.py wagtail/locales/locale wagtail/locale
rm -rf wagtail/locales/locale
pushd scripts
poetry run bash -C "./rebuild-translation-sources.sh"
popd
git add .
git commit -m "Move locales locale files into core"

poetry run roper rename-module --module wagtail/locales/wagtail_hooks.py --to-name locales --do
poetry run roper move-module --source wagtail/locales/locales.py --target wagtail/wagtail_hooks --do
echo "from .locales import *  # noqa" >> wagtail/wagtail_hooks/__init__.py
poetry run isort -rc wagtail
git add .
git commit -m "Move locales wagtail_hooks into core"

git apply --reject --whitespace=fix ../patches/wagtail.locales-no-longer-needs-to-be-installed.patch
poetry run isort -rc wagtail
git add .
git commit -m "'wagtail.locales' no longer needs to be added to INSTALLED_APPS"


poetry run roper rename-module --module wagtail/sites/views.py --to-name sites --do
poetry run roper move-module --source wagtail/sites/sites.py --target wagtail/admin/views --do
poetry run roper rename-module --module wagtail/sites/forms.py --to-name sites --do
poetry run roper move-module --source wagtail/sites/sites.py --target wagtail/admin/forms --do
poetry run roper rename-module --module wagtail/sites/tests.py --to-name test_sites --do
poetry run roper move-module --source wagtail/sites/test_sites.py --target wagtail/admin/tests --do
poetry run isort -rc wagtail
git add .
git commit -m "Move sites views into admin"

mv wagtail/sites/templates/wagtailsites wagtail/templates/wagtailsites
poetry run isort -rc wagtail
git add .
git commit -m "Move sites templates into core"

poetry run python ../catlocales.py wagtail/sites/locale wagtail/locale
rm -rf wagtail/sites/locale
pushd scripts
poetry run bash -C "./rebuild-translation-sources.sh"
popd
git add .
git commit -m "Move sites locale files into core"

poetry run roper rename-module --module wagtail/sites/wagtail_hooks.py --to-name sites --do
poetry run roper move-module --source wagtail/sites/sites.py --target wagtail/wagtail_hooks --do
echo "from .sites import *  # noqa" >> wagtail/wagtail_hooks/__init__.py
poetry run isort -rc wagtail
git add .
git commit -m "Move sites wagtail_hooks into core"

git apply --reject --whitespace=fix ../patches/wagtail.sites-no-longer-needs-to-be-installed.patch
poetry run isort -rc wagtail
git add .
git commit -m "'wagtail.sites' no longer needs to be added to INSTALLED_APPS"


# Move routable page into core

poetry run roper move-module --source wagtail/contrib/routable_page/templatetags/wagtailroutablepage_tags.py --target wagtail/templatetags --do
rm wagtail/contrib/routable_page/templatetags/__init__.py
poetry run roper rename-module --module wagtail/contrib/routable_page/models.py --to-name routable_page --do
poetry run roper move-module --source wagtail/contrib/routable_page/routable_page.py --target wagtail/models --do
poetry run roper rename-module --module wagtail/contrib/routable_page/tests.py --to-name test_routable_page --do
poetry run roper move-module --source wagtail/contrib/routable_page/test_routable_page.py --target wagtail/tests --do
poetry run isort -rc wagtail
git add .
git commit -m "Move routable page into core"
