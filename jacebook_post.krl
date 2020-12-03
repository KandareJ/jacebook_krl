ruleset jacebook_post {
  meta {
    shares __testing, get_post
  }
  global {
    __testing = { "queries":
      [ { "name": "__testing" }
      , { "name": "get_post" }
      ] , "events":
      [ //{ "domain": "d1", "type": "t1" }
      //, { "domain": "d2", "type": "t2", "attrs": [ "a1", "a2" ] }
      ]
    }

    get_post = function() {
      ent:content
    }
  }

  rule initialize {
    select when wrangler finish_initialization

    pre {
      content = event:attr("content");
    }

    if content then noop();

    fired {
      ent:content := content;
      raise visual event "update" attributes { "color": "#ffcc66" }
    }
  }
}
