import unittest

from apps.preferences import enhance_document_with_default_prefs


class DefaultUserPrefsTestCase(unittest.TestCase):
    def test_enhance(self):
        doc = {
            "user_preferences": {
                "workqueue:items": ["abc"],
                "editor:theme": {"label": "Editor"},
            }
        }
        enhance_document_with_default_prefs(doc)
        self.assertIn("email:notification", doc["user_preferences"])
