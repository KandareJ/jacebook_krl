ruleset jacebook_user {
  meta {
    shares __testing, get_user, get_story, get_following, get_followers, get_feed
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.subscription alias subs
  }

  global {
    __testing = { "queries":
      [ { "name": "__testing" }
      , { "name": "get_user" }
      , { "name": "get_story" }
      , { "name": "get_following" }
      , { "name": "get_followers" }
      , { "name": "get_feed" }
      ] , "events":
      [ //{ "domain": "d1", "type": "t1" }
      //, { "domain": "d2", "type": "t2", "attrs": [ "a1", "a2" ] }
      ]
    }

    get_user = function() {
      {
        "alias": ent:content{"alias"},
        "name": ent:content{"name"},
        "photo": ent:content{"photo"}
      }
    }

    get_story = function() {
      wrangler:children().map(function(x) {
        http:get(<<#{meta:host}/sky/cloud/#{x{"eci"}}/jacebook_post/get_post>>){"content"}.decode()
      }).sort(function(a,b){
        a{"timestamp"} < b{"timestamp"}  => -1 | a{"timestamp"} == b{"timestamp"} =>  0 | 1
      })
    }

    get_following = function() {
      subs:established().filter(function(x) {
        x{"Rx_role"} == "follower"
      }).map(function(x) {
        http:get(<<#{meta:host}/sky/cloud/#{x{"Tx"}}/jacebook_user/get_user>>){"content"}.decode()
      })
    }

    get_followers = function() {
      subs:established().filter(function(x) {
        x{"Rx_role"} == "following"
      }).map(function(x) {
        http:get(<<#{meta:host}/sky/cloud/#{x{"Tx"}}/jacebook_user/get_user>>){"content"}.decode()
      })
    }

    get_feed = function() {
      subs:established().filter(function(x) {
        x{"Rx_role"} == "follower"
      }).map(function(x) {
        http:get(<<#{meta:host}/sky/cloud/#{x{"Tx"}}/jacebook_user/get_story>>){"content"}.decode()
      }).append(get_story()).reduce(function(a,b) {
        a.append(b)
      }).sort(function(a,b){
        a{"timestamp"} < b{"timestamp"}  => -1 | a{"timestamp"} == b{"timestamp"} =>  0 | 1
      })
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
    }
  }

  rule add_post {
    select when jacebook add_post

    pre {
      post_id = event:attr("post_id");
      alias = event:attr("alias");
      content = event:attr("content")
      timestamp = event:attr("timestamp");
      image = event:attr("image")
      video = event:attr("video")
      attrs = {
        "content": {
          "post_id": post_id,
          "alias": alias,
          "content": content,
          "timestamp": timestamp,
          "image": image,
          "video": video
        },
        "name": post_id,
        "rids": "jacebook_post"
      }
    }

    if post_id && alias && content && timestamp && image && video then noop();

    fired {
      raise wrangler event "child_creation" attributes attrs
    }
  }

  rule add_follow {
    select when jacebook add_follow

    pre {
      followECI = event:attr("followECI")
    }

    if followECI then noop();

    fired {
      raise wrangler event "subscription" attributes
       { "name" : "follow",
         "Rx_role": "follower",
         "Tx_role": "following",
         "channel_type": "subscription",
         "wellKnown_Tx" : followECI
       }
    }
  }

  rule auto_accept {
  select when wrangler inbound_pending_subscription_added
  fired {
    raise wrangler event "pending_subscription_approval"
      attributes event:attrs
    }
  }

}
