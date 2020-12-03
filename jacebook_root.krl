ruleset jacebook_root {
  meta {
    shares __testing, get_user, alias_available, get_user_story, authenticate_token, get_following, get_followers, get_feed
    use module io.picolabs.wrangler alias wrangler
  }
  global {
    __testing = { "queries":
      [ { "name": "__testing" }
      , { "name": "get_user", "args": [ "alias" ] }
      , { "name": "get_following", "args": [ "alias" ] }
      , { "name": "get_followers", "args": [ "alias" ] }
      , { "name": "get_feed", "args": [ "alias" ] }
      , { "name": "get_user_story", "args": [ "alias" ] }
      , { "name": "alias_available", "args": [ "alias" ] }
      , { "name": "authenticate_token", "args": [ "authToken" ] }
      ] , "events":
      [ { "domain": "jacebook", "type": "add_user", "attrs": ["alias", "hash", "salt", "photo", "name"] }
      , { "domain": "jacebook", "type": "remove_user", "attrs": [ "alias" ] }
      , { "domain": "jacebook", "type": "add_post", "attrs": [ "post_id", "alias", "content", "timestamp", "image", "video" ] }
      , { "domain": "jacebook", "type": "add_token", "attrs": [ "authToken", "alias" ] }
      , { "domain": "jacebook", "type": "remove_token", "attrs": [ "authToken" ] }
      , { "domain": "jacebook", "type": "add_follow", "attrs": [ "alias", "followAlias" ] }
      ]
    }
    get_following = function(alias) {
      eci = wrangler:children().filter(function(x) {
        x{"name"} == alias
      }).head(){"eci"};

      http:get(<<#{meta:host}/sky/cloud/#{eci}/jacebook_user/get_following>>){"content"}.decode()
    }

    get_followers = function(alias) {
      eci = wrangler:children().filter(function(x) {
        x{"name"} == alias
      }).head(){"eci"};

      http:get(<<#{meta:host}/sky/cloud/#{eci}/jacebook_user/get_followers>>){"content"}.decode()
    }

    get_feed = function(alias) {
      eci = wrangler:children().filter(function(x) {
        x{"name"} == alias
      }).head(){"eci"};

      http:get(<<#{meta:host}/sky/cloud/#{eci}/jacebook_user/get_feed>>){"content"}.decode()
    }

    authenticate_token = function(authToken) {
      ent:tokens.defaultsTo({}).get(authToken)
    }

    get_user = function(alias) {
      eci = wrangler:children().filter(function(x) {
        x{"name"} == alias
      }).head(){"eci"};

      http:get(<<#{meta:host}/sky/cloud/#{eci}/jacebook_user/get_user>>){"content"}.decode()
    }

    get_user_story = function(alias) {
      eci = wrangler:children().filter(function(x) {
        x{"name"} == alias
      }).head(){"eci"};

      http:get(<<#{meta:host}/sky/cloud/#{eci}/jacebook_user/get_story>>){"content"}.decode()
    }

    alias_available = function(alias) {
      wrangler:children().filter(function(x) {
        x{"name"} == alias
      }).length() == 0;
    }
  }

  rule add_user {
    select when jacebook add_user

    pre {
      alias = event:attr("alias");
      hash = event:attr("hash");
      salt = event:attr("salt")
      photo = event:attr("photo");
      name = event:attr("name")
      attrs = {
        "content": {
          "alias": alias,
          "hash": hash,
          "salt": salt,
          "photo": photo,
          "name": name
        },
        "name": event:attr("alias"),
        "rids": "jacebook_user"
      }
    }

    if alias && hash && salt && name && photo then noop();

    fired {
      raise wrangler event "child_creation" attributes attrs
    }

  }

  rule remove_user {
    select when jacebook remove_user

    pre {
      alias = event:attr("alias")
    }

    if alias then noop();

    fired {
      raise wrangler event "child_deletion"
        attributes {"name": alias};
    }
  }

  rule add_post {
    select when jacebook add_post

    pre {
      alias = event:attr("alias")
      eci = wrangler:children().filter(function(x) {
        x{"name"} == alias
      }).head(){"eci"}
    }

    if eci then event:send({ "eci"   : eci,
                   "domain": "jacebook", "type": "add_post",
                   "attrs" : event:attrs })
  }

  rule add_token {
    select when jacebook add_token

    pre {
      attrs = event:attrs.klog("ATTRS")
      token = event:attr("authToken").klog("token")
      alias = event:attr("alias").klog("alias")
    }

    if token && alias then noop();

    fired {
      ent:tokens := ent:tokens.defaultsTo({}).put(token, alias)
    }
  }

  rule remove_token {
    select when jacebook remove_token

    pre {
      token = event:attr("authToken")
    }

    if token then noop();

    fired {
      ent:tokens := ent:tokens.defaultsTo({}).filter(function(v,k) {
        k != token
      })
    }
  }

  rule add_follow {
    select when jacebook add_follow

    pre {
      alias1 = event:attr("alias");
      alias2 = event:attr("followAlias")
      eci1 = wrangler:children().filter(function(x) {
        x{"name"} == alias1
      }).head(){"eci"};
      eci2 = wrangler:children().filter(function(x) {
        x{"name"} == alias2
      }).head(){"eci"};
    }

    if alias1 && alias2 && eci1 && eci2 then
    event:send({
        "eci": eci1,
        "domain": "jacebook",
        "type": "add_follow",
        "attrs" : { "followECI": eci2 }
      });


  }
}
