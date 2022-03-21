#!/bin/bash
set -e

rm -rf wagtail
git clone https://github.com/kaedroho/wagtail.git

cd wagtail

git checkout 3d04304d898f2bfe90fd5f483069711529eb7afa -b restructure

echo "/.ropeproject" >> .gitignore


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
git checkout -- docs/releases
git commit -m "Extract workflows models into separate module"


touch wagtail/models/logging.py
poetry run roper move-by-name --name PageLogEntry --source wagtail/models/__init__.py --target wagtail/models/logging.py --do
poetry run roper move-by-name --name PageLogEntryManager --source wagtail/models/__init__.py --target wagtail/models/logging.py --do
poetry run roper move-by-name --name PageLogEntryQuerySet --source wagtail/models/__init__.py --target wagtail/models/logging.py --do

git apply --reject --whitespace=fix ../patches/logging-models-fixup-imports.patch

poetry run isort -rc wagtail
git add .
git checkout -- docs/releases
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
git checkout -- docs/releases
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
git checkout -- docs/releases
git commit -m "Extract pages models into separate module"
