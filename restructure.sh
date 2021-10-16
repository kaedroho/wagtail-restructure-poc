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
isort -rc wagtail
git add .
git commit -m "Apply PR7277"

git apply --reject --whitespace=fix ../patches/pr7564.patch
# git apply doesn't seem to like deleting stuff
rm wagtail/users/models.py
isort -rc wagtail
git add .
git commit -m "Apply PR7564"


# Rename wagtail.core to wagtail
# This part starts off with a few renames to resolves conflicts, then moves everthing under wagtail/core to the top level

roper rename-module --module wagtail/core/utils.py --to-name coreutils --do
find . -name '*.rst' -exec sed -i 's/wagtail.core.utils/wagtail.core.coreutils/g' {} \;
find . -name '*.md' -exec sed -i 's/wagtail.core.utils/wagtail.core.coreutils/g' {} \;
isort -rc wagtail
git add .
git commit -m "Move core.utils to core.coreutils"

roper rename-module --module wagtail/core/sites.py --to-name siteutils --do
find . -name '*.rst' -exec sed -i 's/wagtail.core.sites/wagtail.core.siteutils/g' {} \;
find . -name '*.md' -exec sed -i 's/wagtail.core.sites/wagtail.core.siteutils/g' {} \;
isort -rc wagtail
git add .
git commit -m "Move core.sites to core.siteutils"

roper rename-module --module wagtail/tests --to-name test --do
# Need to update .py files here since wagtail.tests appears a lot in strings
# Also, escaping . for this one since wagtail_tests appears often
find . -name '*.py' -exec sed -i 's/wagtail\.tests/wagtail\.test/g' {} \;
find . -name '*.rst' -exec sed -i 's/wagtail\.tests/wagtail\.test/g' {} \;
find . -name '*.md' -exec sed -i 's/wagtail\.tests/wagtail\.test/g' {} \;
sed -i "s/os.path.join(WAGTAIL_ROOT, 'tests', 'testapp', 'jinja2_templates'),/os.path.join(WAGTAIL_ROOT, 'test', 'testapp', 'jinja2_templates'),/g" wagtail/test/settings.py
isort -rc wagtail
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
isort -rc wagtail
git add .
git commit -m "Move wagtail.core to wagtail"


# Merge admin into core

roper move-module --source wagtail/admin/edit_handlers.py --target wagtail --do
find . -name '*.py' -exec sed -i 's/wagtail.admin.edit_handlers/wagtail.edit_handlers/g' {} \;
find . -name '*.rst' -exec sed -i 's/wagtail.admin.edit_handlers/wagtail.edit_handlers/g' {} \;
find . -name '*.md' -exec sed -i 's/wagtail.admin.edit_handlers/wagtail.edit_handlers/g' {} \;
isort -rc wagtail
git add .
git commit -m "Move edit handlers to wagtail.edit_handlers"

roper move-module --source wagtail/admin/models.py --target wagtail/models --do
roper rename-module --module wagtail/models/models.py --to-name admin --do
# Note --pythonpath=. stops Python from looking for pip-installed Wagtail
django-admin makemigrations --pythonpath=. --settings=wagtail.test.settings
isort -rc wagtail
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
isort -rc wagtail
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
# TODO: Move this check into core instead
sed -i "s/os.path.dirname(__file__), 'static', 'wagtailadmin', 'css', 'normalize.css'/os.path.dirname(os.path.dirname(__file__)), 'static', 'wagtailadmin', 'css', 'normalize.css'/g" wagtail/admin/checks.py
find ./wagtail/static_src -name '*.scss' -exec sed -i "s/\/..\/client\//\/client\//g" {} \;
find . -name '*.js' -exec sed -i 's/wagtail\/admin\/static_src/wagtail\/static_src/g' {} \;
isort -rc wagtail
git add .
git commit -m "Move admin static into core"

roper move-module --source wagtail/admin/templatetags/wagtailadmin_tags.py --target wagtail/templatetags --do
# Roper crashes if we don't make this particular import absolute
sed -i 's/from .templatetags.wagtailuserbar import wagtailuserbar/from wagtail.admin.templatetags.wagtailuserbar import wagtailuserbar/g' wagtail/admin/jinja2tags.py
roper move-module --source wagtail/admin/templatetags/wagtailuserbar.py --target wagtail/templatetags --do
rm wagtail/admin/templatetags/__init__.py
isort -rc wagtail
git add .
git commit -m "Move admin templatetags into core"

git apply --reject --whitespace=fix ../patches/call-admin-signal-handlers-and-hooks-from-core.patch
git add .
isort -rc wagtail
git commit -m "Call admin signal handlers and hooks from core"

git apply --reject --whitespace=fix ../patches/remove-admin-from-installed-apps.patch
git add .
isort -rc wagtail
git commit -m "No longer necessary to add 'wagtail.admin' to INSTALLED_APPS"


# Extract pages/workflows into separate folders

mkdir wagtail/pages
touch wagtail/pages/__init__.py
roper move-module --source wagtail/admin/views/pages --target wagtail/pages --do
roper rename-module --module wagtail/pages/pages --to-name admin_views --do
# Flipped order to avoid roper crash
roper rename-module --module wagtail/admin/views/page_privacy.py --to-name privacy --do
roper move-module --source wagtail/admin/views/privacy.py --target wagtail/pages/admin_views --do
roper move-module --source wagtail/admin/urls/pages.py --target wagtail/pages --do
roper rename-module --module wagtail/pages/pages.py --to-name admin_urls --do
roper move-module --source wagtail/admin/forms/pages.py --target wagtail/pages --do
roper rename-module --module wagtail/pages/pages.py --to-name forms --do
roper move-module --source wagtail/admin/tests/pages --target wagtail/pages --do
roper rename-module --module wagtail/pages/pages --to-name tests --do
roper move-by-name --name PasswordViewRestrictionForm --source wagtail/forms.py --target wagtail/pages/forms.py
isort -rc wagtail
git add .
git commit -m "Extract pages admin views into new wagtail/pages folder"


mkdir wagtail/workflows
touch wagtail/workflows/__init__.py
roper move-module --source wagtail/workflows.py --target wagtail/workflows --do
roper rename-module --module wagtail/workflows/workflows.py --to-name utils --do
roper move-module --source wagtail/admin/views/workflows.py --target wagtail/workflows --do
roper rename-module --module wagtail/workflows/workflows.py --to-name admin_views --do
roper move-module --source wagtail/admin/urls/workflows.py --target wagtail/workflows --do
roper rename-module --module wagtail/workflows/workflows.py --to-name admin_urls --do
roper move-module --source wagtail/admin/forms/workflows.py --target wagtail/workflows --do
roper rename-module --module wagtail/workflows/workflows.py --to-name forms --do
roper move-module --source wagtail/admin/widgets/workflows.py --target wagtail/workflows --do
roper rename-module --module wagtail/workflows/workflows.py --to-name widgets --do
roper move-module --source wagtail/admin/tests/test_workflows.py --target wagtail/workflows --do
roper rename-module --module wagtail/workflows/test_workflows.py --to-name tests --do
roper move-by-name --name TaskStateCommentForm --source wagtail/forms.py --target wagtail/workflows/forms.py --do
# wagtail/forms.py should be empty now
if [ ! -s wagtail/forms.py ] ; then
  rm wagtail/forms.py
fi

sed -i 's/import wagtail.workflows.forms//g' wagtail/models/__init__.py
sed -i 's/return wagtail.workflows.forms.TaskStateCommentForm/from wagtail.workflows.forms import TaskStateCommentForm\n        return TaskStateCommentForm/g' wagtail/models/__init__.py
sed -i 's/wagtail.workflows.publish_workflow_state/wagtail.workflows.utils.publish_workflow_state/g' wagtail/models/__init__.py
sed -i 's/from wagtail.workflows import get_task_types/from .utils import get_task_types/g' wagtail/workflows/admin_views.py
sed -i 's/wagtail.admin.views.workflows/wagtail.workflows.admin_views/g' wagtail/workflows/tests.py

isort -rc wagtail

git add .
git commit -m "Extract workflows admin views into new wagtail/workflows folder"


# Break up core models

touch wagtail/models/workflows.py
roper move-by-name --name TaskState --source wagtail/models/__init__.py --target wagtail/models/workflows.py --do
roper move-by-name --name TaskStateManager --source wagtail/models/__init__.py --target wagtail/models/workflows.py --do
roper move-by-name --name WorkflowState --source wagtail/models/__init__.py --target wagtail/models/workflows.py --do
roper move-by-name --name WorkflowStateManager --source wagtail/models/__init__.py --target wagtail/models/workflows.py --do
roper move-by-name --name GroupApprovalTask --source wagtail/models/__init__.py --target wagtail/models/workflows.py --do
roper move-by-name --name Workflow --source wagtail/models/__init__.py --target wagtail/models/workflows.py --do
roper move-by-name --name WorkflowManager --source wagtail/models/__init__.py --target wagtail/models/workflows.py --do
roper move-by-name --name Task --source wagtail/models/__init__.py --target wagtail/models/workflows.py --do
roper move-by-name --name TaskManager --source wagtail/models/__init__.py --target wagtail/models/workflows.py --do
roper move-by-name --name WorkflowTask --source wagtail/models/__init__.py --target wagtail/models/workflows.py --do

sed -i 's/import wagtail.workflows.forms//g' wagtail/models/__init__.py
sed -i 's/import wagtail.models.workflows//g' wagtail/models/__init__.py
sed -i 's/wagtail.models.workflows.WorkflowState/WorkflowState/g' wagtail/models/__init__.py

sed -i 's/import wagtail.models.workflows//g' wagtail/query.py
sed -i 's/wagtail.models.workflows.WorkflowState/WorkflowState/g' wagtail/query.py

sed -i 's/from wagtail.models import Page, UserProfile, WorkflowPage, workflows/from wagtail.models import Page, UserProfile, WorkflowPage, WorkflowTask, Workflow, WorkflowState, TaskState, Task, GroupApprovalTask/g' wagtail/workflows/tests.py
sed -i 's/workflows.Workflow/Workflow/g' wagtail/workflows/tests.py
sed -i 's/workflows.Task/Task/g' wagtail/workflows/tests.py
sed -i 's/workflows.WorkflowTask/WorkflowTask/g' wagtail/workflows/tests.py
sed -i 's/workflows.GroupApprovalTask/GroupApprovalTask/g' wagtail/workflows/tests.py
sed -i 's/workflows.WorkflowState/WorkflowState/g' wagtail/workflows/tests.py
sed -i 's/workflows.TaskState/TaskState/g' wagtail/workflows/tests.py
sed -i 's/workflows.TaskState/TaskState/g' wagtail/workflows/tests.py

isort -rc wagtail

git add .
git commit -m "Extract workflows models into separate module"


touch wagtail/models/logging.py
roper move-by-name --name PageLogEntry --source wagtail/models/__init__.py --target wagtail/models/logging.py --do
roper move-by-name --name PageLogEntryManager --source wagtail/models/__init__.py --target wagtail/models/logging.py --do
roper move-by-name --name PageLogEntryQuerySet --source wagtail/models/__init__.py --target wagtail/models/logging.py --do
isort -rc wagtail
git add .
git commit -m "Extract logging models into separate module"


touch wagtail/models/commenting.py
roper move-by-name --name PageSubscription --source wagtail/models/__init__.py --target wagtail/models/commenting.py --do
roper move-by-name --name CommentReply --source wagtail/models/__init__.py --target wagtail/models/commenting.py --do
roper move-by-name --name Comment --source wagtail/models/__init__.py --target wagtail/models/commenting.py --do
roper move-by-name --name COMMENTS_RELATION_NAME --source wagtail/models/__init__.py --target wagtail/models/commenting.py --do

sed -i 's/import wagtail.models.commenting/from .commenting import COMMENTS_RELATION_NAME, Comment/g' wagtail/models/__init__.py
sed -i 's/wagtail.models.commenting.COMMENTS_RELATION_NAME/COMMENTS_RELATION_NAME/g' wagtail/models/__init__.py
sed -i 's/wagtail.models.commenting.Comment.DoesNotExist/Comment.DoesNotExist/g' wagtail/models/__init__.py

git apply --reject --whitespace=fix ../patches/fixup-commenting-models.patch

isort -rc wagtail

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

isort -rc wagtail

git add .
git commit -m "Extract pages models into separate module"
