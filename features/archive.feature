Feature: News Items Archive

    @auth
    Scenario: List empty archive
        Given empty "archive"
        When we get "/archive"
        Then we get list with 0 items

    @auth
    Scenario: Get archive item by guid
        Given "archive"
        """
        [{"guid": "tag:example.com,0000:newsml_BRE9A605"}]
        """
        When we get "/archive/tag:example.com,0000:newsml_BRE9A605"
        Then we get existing resource
        """
        {"guid": "tag:example.com,0000:newsml_BRE9A605", "state": "draft"}
        """

    @auth
    Scenario: Don't get published archive item by guid
        Given "archive"
        """
        [{"guid": "tag:example.com,0000:newsml_BRE9A605", "state": "published"}]
        """
        When we get "/archive"
        Then we get list with 0 items

    @auth
    Scenario: Update item
        Given "archive"
        """
        [{"_id": "xyz", "guid": "testid", "headline": "test"}]
        """

        When we patch given
        """
        {"headline": "TEST 2", "urgency": 2, "more_coming": true}
        """

        And we patch latest
        """
        {"headline": "TEST 3", "state": "in_progress", "body_html": "<p>some content</p>"}
        """

        Then we get updated response
        """
        {"word_count": 2, "operation": "update"}
        """
        And we get version 3
        And we get etag matching "/archive/xyz"
        When we get "/archive/xyz?version=all"
        Then we get list with 3 items

    @auth
    Scenario: Force update sign-off
        Given "archive"
        """
        [{"_id": "xyz", "guid": "testid", "headline": "test"}]
        """

        When we patch given
        """
        {"headline": "TEST 2", "sign_off": "abc"}
        """

        And we patch latest
        """
        {"headline": "TEST 3", "sign_off": "123"}
        """

        Then we get updated response
        """
        {"headline": "TEST 3", "sign_off": "123"}
        """

    @auth
    Scenario: Update item and keep version
        Given "archive"
        """
        [{"_id": "item-1", "guid": "item-1", "headline": "test"}]
        """

        When we patch given
        """
        {"headline": "another"}
        """

        And we post to "archive/item-1/autosave"
        """
        {"headline": "another one", "state": "in_progress"}
        """

        And we get "archive/item-1"
        Then we get version 2

	@auth
	Scenario: Restore version
        Given "archive"
        """
        [{"guid": "testid", "headline": "test"}]
        """
        When we patch given
        """
        {"headline": "TEST 2", "urgency": 2}
        """
		And we restore version 1
        Then we get updated response
        """
        {"operation": "restore"}
        """
        And we get version 3
        And the field "headline" value is "test"


    @auth
    @vocabulary
    Scenario: Upload image with point of interest into archive
        Given empty "archive"
        When we upload a file "bike.jpg" to "archive"
        Then we get new resource
        """
        {"guid": "__any_value__", "firstcreated": "__any_value__", "versioncreated": "__any_value__", "state": "draft"}
        """
        And we get "bike.jpg" metadata
        And we get "picture" renditions
        When we patch latest
        """
        {
        	"renditions": {
        		"4-3": {"CropBottom": 1100, "CropLeft": 100, "CropRight": 900, "CropTop": 500},
        		"thumbnail": {"width": 90, "height": 120}
        	},
        	"poi": {"x": 0.41, "y": 0.52}
        }
        """
        When we get "/archive"
        Then we get list with 1 items
        """
        {"_items": [{
	        	"renditions": {
	        		"4-3": {"CropBottom": 1100, "CropLeft": 100, "CropRight": 900, "CropTop": 500, "poi" : {"y" : 332, "x" : 391}},
	        		"thumbnail": {"width": 90, "height": 120, "poi": {"x": 36, "y": 62}}
	        	},
	        	"poi": {"x": 0.41, "y": 0.52}
        	}]
        }
        """

    @auth
    @vocabulary
    Scenario: Upload image into archive and validate metadata set by API
        Given empty "archive"
        When we upload a file "bike.jpg" to "archive"
        Then we get new resource
        """
        {"guid": "__any_value__", "firstcreated": "__any_value__", "versioncreated": "__any_value__", "state": "draft"}
        """
        And we get "bike.jpg" metadata
        And we get "picture" renditions
        When we patch latest
        """
        {"headline": "flower", "byline": "foo", "description_text": "flower desc"}
        """
        When we get "/archive"
        Then we get list with 1 items
        """
        {"_items": [{"headline": "flower", "byline": "foo", "description_text": "flower desc",
                     "pubstatus": "usable", "language": "en", "state": "draft", "sign_off": "abc", "expiry": "__no_value__"}]}
        """

    @auth
    Scenario: Upload audio file into archive and validate metadata set by API
        Given empty "archive"
        When we upload a file "green.ogg" to "archive"
        Then we get new resource
        """
        {"guid": "__any_value__", "state": "draft"}
        """
        And we get "green.ogg" metadata
        Then original rendition is updated with link to file having mimetype "audio/ogg"
        When we patch latest
        """
        {"headline": "green", "byline": "foo", "description_text": "green music"}
        """
        When we get "/archive"
        Then we get list with 1 items
        """
        {"_items": [{"headline": "green", "byline": "foo", "description_text": "green music", "state": "draft", "sign_off": "abc"}]}
        """

    @auth
    Scenario: Upload video file into archive and validate metadata set by API
        Given empty "archive"
        When we upload a file "this_week_nasa.mp4" to "archive"
        Then we get new resource
        """
        {"guid": "__any_value__", "state": "draft"}
        """
        And we get "this_week_nasa.mp4" metadata
        Then original rendition is updated with link to file having mimetype "video/mp4"
        When we patch latest
        """
        {"headline": "week @ nasa", "byline": "foo", "description_text": "nasa video"}
        """
        When we get "/archive"
        Then we get list with 1 items
        """
        {"_items": [{"headline": "week @ nasa", "byline": "foo", "description_text": "nasa video", "state": "draft", "sign_off": "abc"}]}
        """

    @auth
    Scenario: Browse private content
        Given the "archive"
        """
        [{"type":"text", "headline": "test1", "guid": "testid1"},
         {"type":"text", "headline": "test2", "guid": "testid2"}]
        """
        When we get "/archive"
        Then we get list with 0 items

    @auth
    Scenario: Browse public content
        Given "desks"
        """
        [{"name": "Sports Desk", "content_expiry": 60}]
        """
        Given "archive"
            """
            [{"_id": "testid1", "guid": "testid1", "task": {"desk": "#desks._id#"}}]
            """
        When we get "/archive"
        Then we get list with 1 items

        When we get "archive/testid1"
        Then we get global content expiry

    @auth
    @ticket-sd-360
    Scenario: Delete archive item with guid starting with "-"
        Given empty "archive"
        When we post to "/archive"
        """
        [{"guid": "-abcde1234567890", "type": "text"}]
        """
        And we delete latest
        Then we get response code 405

    @auth
    Scenario: Create new text item and validate metadata set by API
        Given empty "archive"
        When we post to "/archive"
        """
        [{"type": "text", "body_html": "<p>content</p>"}]
        """
        Then we get new resource
        """
        {
        	"_id": "__any_value__", "guid": "__any_value__", "type": "text",
        	"original_creator": "__any_value__", "word_count": 1, "operation": "create", "sign_off": "abc"
        }
        """

	@auth
	Scenario: Update text item with Metadata
	    Given the "archive"
	    """
        [{"type":"text", "headline": "test1", "_id": "xyz", "original_creator": "abc"}]
        """
        When we patch given
        """
        {"word_count" : "6", "keywords" : ["Test"], "urgency" : "4", "byline" : "By Line", "language": "en", "genre" : [{"name": "Test"}],
         "anpa_category" : [{"qcode" : "A", "name" : "Australian News"}],
         "subject" : [{"qcode" : "11007000", "name" : "human rights"},
                      {"qcode" : "11014000", "name" : "treaty and international organisation-DEPRECATED"}
                     ]
        }
        """
        Then we get updated response
        """
        { "headline": "test1", "pubstatus" : "usable", "byline" : "By Line", "genre": [{"name": "Test"}]}
        """
        And we get version 2

	@auth
	Scenario: Unique Name should be unique
	    Given the "archive"
	    """
        [{"type":"text", "headline": "test1", "_id": "xyz", "original_creator": "abc"},
         {"type":"text", "headline": "test1", "_id": "abc", "original_creator": "abc"}]
        """
        When we patch "/archive/xyz"
        """
        {"unique_name": "unique_xyz"}
        """
        And we patch "/archive/abc"
        """
        {"unique_name": "unique_xyz"}
        """
        Then we get response code 400

	@auth
	Scenario: Unique Name can be updated by administrator
	    Given the "archive"
	    """
        [{"type":"text", "headline": "test1", "_id": "xyz", "original_creator": "abc"},
         {"type":"text", "headline": "test1", "_id": "abc", "original_creator": "abc"}]
        """
        When we patch "/archive/xyz"
        """
        {"unique_name": "unique_xyz"}
        """
        Then we get response code 200

	@auth
	Scenario: Unique Name can be updated only by user having privileges
	    Given the "archive"
	    """
        [{"type":"text", "headline": "test1", "_id": "xyz", "original_creator": "abc"},
         {"type":"text", "headline": "test1", "_id": "abc", "original_creator": "abc"}]
        """
        When we patch "/users/#CONTEXT_USER_ID#"
        """
        {"user_type": "user", "privileges": {"metadata_uniquename": 0, "archive": 1, "unlock": 1, "tasks": 1, "users": 1}}
        """
        Then we get response code 200
        When we patch "/archive/xyz"
        """
        {"unique_name": "unique_xyz"}
        """
        Then we get response code 400
        When we setup test user
        When we patch "/users/#CONTEXT_USER_ID#"
        """
        {"user_type": "user", "privileges": {"metadata_uniquename": 1, "archive": 1, "unlock": 1, "tasks": 1, "users": 1}}
        """
        Then we get response code 200
        When we patch "/archive/xyz"
        """
        {"unique_name": "unique_xyz"}
        """
        Then we get response code 200

    @auth
    @vocabulary
    Scenario: State of an Uploaded Image, submitted to a desk when updated should change to in-progress
        Given empty "archive"
        And "desks"
        """
        [{"name": "Sports"}]
        """
        When we upload a file "bike.jpg" to "archive"
        Then we get new resource
        """
        {"guid": "__any_value__", "firstcreated": "__any_value__", "versioncreated": "__any_value__", "state": "draft"}
        """
        When we patch latest
        """
        {"headline": "flower", "byline": "foo", "description_text": "flower desc"}
        """
        When we get "/archive"
        Then we get list with 1 items
        """
        {"_items": [{"headline": "flower", "byline": "foo", "description_text": "flower desc",
                     "pubstatus": "usable", "language": "en", "state": "draft"}]}
        """
        When we patch "/archive/#archive._id#"
        """
        {"task": {"desk": "#desks._id#"}}
        """
        And we patch "/archive/#archive._id#"
        """
        {"headline": "FLOWER"}
        """
        And we get "/archive"
        Then we get list with 1 items
        """
        {"_items": [{"state": "in_progress"}]}
        """

    @auth
    Scenario: Cannot delete desk when it has article(s)
      Given empty "desks"
      And empty "archive"
      When we post to "/desks"
      """
      {"name": "Sports"}
      """
      And we post to "/archive"
      """
      [{"type": "text", "body_html": "<p>content</p>", "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#"}}]
      """
      And we delete "/desks/#desks._id#"
      Then we get error 412
      """
      {"_message": "Cannot delete desk as it has article(s) or referenced by versions of the article(s)."}
      """

    @auth
    Scenario: Cannot delete desk when it is still referenced in archive version
      Given empty "desks"
      And empty "archive"
      When we post to "/desks" with "SPORTS_DESK_ID" and success
      """
      {"name": "Sports", "desk_type": "authoring"}
      """
      And we post to "/archive"
      """
      [{"guid": "123", "type": "text", "body_html": "<p>content</p>", "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#"}}]
      """
      Then we get OK response
      When we post to "/desks"
      """
      {"name": "National", "desk_type": "authoring"}
      """
      And we post to "/archive/123/move"
      """
      [{"task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#"}}]
      """
      Then we get OK response
      When we delete "/desks/#SPORTS_DESK_ID#"
      Then we get error 412
      """
      {"_message": "Cannot delete desk as it has article(s) or referenced by versions of the article(s)."}
      """

    @auth
    Scenario: Sign-off is updated when multiple users modify the article
        When we post to "/archive"
        """
        [{"type": "text", "body_html": "<p>content</p>"}]
        """
        Then we get new resource
        """
        {"type": "text", "sign_off":"abc"}
        """
        When we switch user
        And we patch latest
        """
        {"headline": "test4"}
        """
        Then we get updated response
        """
        {"headline": "test4", "sign_off": "abc/foo"}
        """
        When we patch latest
        """
        {"headline": "test3"}
        """
        Then we get updated response
        """
        {"headline": "test3", "sign_off": "abc/foo"}
        """

    @auth
    Scenario: Sign-off is updated when same user updates story twice
        When we post to "/archive"
        """
        [{"_id": "123", "type": "text", "body_html": "<p>content</p>"}]
        """
        Then we get new resource
        """
        {"type": "text", "sign_off":"abc"}
        """
        When we switch user
        And we patch latest
        """
        {"headline": "test4"}
        """
        Then we get updated response
        """
        {"headline": "test4", "sign_off": "abc/foo"}
        """
        When we setup test user
        When we patch "/archive/123"
        """
        {"headline": "test5"}
        """
        Then we get updated response
        """
        {"headline": "test5", "sign_off": "foo/abc"}
        """

    @auth
    Scenario: Assign a default values to user created content Items
        When we post to "/archive"
        """
        [{"type": "text", "body_html": "<p>content</p>"}]
        """
        Then we get new resource
        """
        {"type": "text", "source":"AAP", "priority":6, "urgency":3,
        "genre": [{"qcode": "Article", "name": "Article (news)"}]}
        """

    @auth
    Scenario: Default Metadata is copied from user preferences for new articles
      Given empty "archive"
      And we have sessions "/sessions"
      When we get "/preferences/#SESSION_ID#"
      And we patch latest
      """
      {"user_preferences": {
          "dateline:located": {
              "located" : {
                  "dateline" : "city", "city" : "Sydney", "city_code" : "Sydney", "country" : "Australia",
                  "country_code" : "AU", "state" : "New South Wales", "state_code" : "NSW", "tz" : "Australia/Sydney"
              }
          },
          "article:default:place": {"place" : [{"qcode" : "ACT", "name" : "ACT"}]}
          }
      }
      """
      And we patch "/users/#CONTEXT_USER_ID#"
      """
      {"byline": "by Context User"}
      """
      And we post to "/archive"
      """
      [{"guid": "123", "headline": "Article with Dateline populated from preferences"}]
      """
      And we get "/archive/123"
      Then we get existing resource
      """
      {"byline": "by Context User", "dateline": {"located": {"city": "Sydney"}}, "place" : [{"qcode" : "ACT", "name" : "ACT"}]}
      """

    @auth
    Scenario: Sign-off is updated when other user restores version
        When we post to "/archive"
        """
        [{"type": "text", "headline": "test1", "body_html": "<p>content</p>"}]
        """
        Then we get new resource
        """
        {"type": "text", "sign_off":"abc"}
        """
        When we patch latest
        """
        {"headline": "test4"}
        """
        Then we get updated response
        """
        {"headline": "test4", "sign_off": "abc"}
        """
        When we switch user
		And we restore version 1
        And we get "/archive/#archive._id#"
        Then we get existing resource
        """
        {"headline": "test1", "sign_off": "abc/foo"}
        """

	@auth
	Scenario: Should not allow duplicate anpa category codes
	    Given the "archive"
	    """
        [{"type":"text", "headline": "test1", "_id": "xyz", "original_creator": "abc"}]
        """
        When we patch "/archive/xyz"
        """
        {"anpa_category": [{"qcode": "a"}, {"qcode": "a"}]}
        """
        Then we get error 400
        """
        {"_issues": {"validator exception": "400: Duplicate category codes are not allowed"}, "_status": "ERR"}
        """

	@auth
	Scenario: Should not allow duplicate subject codes
	    Given the "archive"
	    """
        [{"type":"text", "headline": "test1", "_id": "xyz", "original_creator": "abc"}]
        """
        When we patch "/archive/xyz"
        """
            { "subject" : [ { "name" : "bullfighting",
                    "parent" : "01000000",
                    "qcode" : "01003000"
                  },
                  { "name" : "bullfighting",
                    "parent" : "01000000",
                    "qcode" : "01003000"
                  }
                ] }
        """
        Then we get error 400
        """
        {"_issues": {"validator exception": "400: Duplicate subjects are not allowed"}, "_status": "ERR"}
        """

    @auth
 	Scenario: Create content on a desk with no source setting on the desk
 	    Given "desks"
 	    """
         [{"name": "sports"}]
         """
         And "archive"
         """
         [{  "type":"text", "headline": "test1", "guid": "123", "original_creator": "#CONTEXT_USER_ID#", "state": "submitted",
               "subject":[{"qcode": "17004000", "name": "Statistics"}], "body_html": "Test Document body",
               "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"}}]
         """
         When we get "archive/123"
         Then we get OK response
         Then we get existing resource
         """
         {"guid": "123", "source": "AAP", "dateline": {"source": "AAP"}}
         """

 	@auth
 	Scenario: Create content on a desk with source setting on the desk
 	    Given "desks"
 	    """
         [{"name": "sports", "source": "FOO"}]
         """
         And "archive"
         """
         [{  "type":"text", "headline": "test1", "guid": "123", "original_creator": "#CONTEXT_USER_ID#", "state": "submitted",
               "subject":[{"qcode": "17004000", "name": "Statistics"}], "body_html": "Test Document body",
               "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"}}]
         """
         When we get "archive/123"
         Then we get OK response
         Then we get existing resource
         """
         {"guid": "123", "source": "FOO", "dateline": {"source": "FOO"}}
         """

      @auth
      Scenario: Create content item based on a content type with default values
         Given "content_types"
          """
          [{"_id": "snap", "schema": {"headline": {"default": "default_headline"}, "priority": {"default": 10}}}]
          """
         When we post to "/archive"
          """
           [{  "type":"text", "guid": "123",  "profile": "snap" }]
          """
         When we get "archive/123"
         Then we get OK response
         Then we get existing resource
         """
         {"guid": "123", "headline": "default_headline", "priority": 10}
         """

         When we post to "/archive"
          """
           [{  "type":"text", "headline": "test1", "guid": "456",  "priority": 3, "profile": "snap" }]
          """
         When we get "archive/456"
         Then we get OK response
         Then we get existing resource
         """
         {"guid": "456", "headline": "test1", "priority": 3}
         """

    @auth
    Scenario: Hide version 0 items from lists
        When we post to "/archive"
        """
        {"version": 0, "type": "text"}
        """

        When we get "/archive"
        Then we get list with 0 items

    @auth
    Scenario: Upload image with custom crops
        Given "vocabularies"
        """
        [{"_id": "crop_sizes", "items": [{"is_active": true, "name": "3:2", "width": "3", "height": "2"}]}]
        """

        When we upload a file "bike.jpg" to "archive"
        Then we get new resource
