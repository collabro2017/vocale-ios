var fs = require('fs');
var layer = require('cloud/layer-parse-module/layer-module.js');

//main.js
var layerProviderID = 'layer:///providers/45eecffa-a10f-11e5-9f07-4e4f000000ac';  // Should have the format of layer:///providers/<GUID>
var layerKeyID = 'layer:///keys/18806c74-a180-11e5-abf2-4e4f00001560';   // Should have the format of layer:///keys/<GUID>
var privateKey = fs.readFileSync('cloud/layer-parse-module/keys/layer-key.js');
layer.initialize(layerProviderID, layerKeyID, privateKey);


//main.js
Parse.Cloud.define("generateToken", function(request, response) {
                   var currentUser = request.user;
                   if (!currentUser) throw new Error('You need to be logged in!');
                   var userID = currentUser.id;
                   var nonce = request.params.nonce;
                   if (!nonce) throw new Error('Missing nonce parameter');
                   response.success(layer.layerIdentityToken(userID, nonce));
                   });

Parse.Cloud.afterSave("Event", function(request) {
                      
                      if(request.object.existed() == false) {
                      
                      var filterRequest = request.object.get("filterRequest");
                      
                      filterRequest.fetch({
                                          success: function(filterRequest) {
                                          // The object was refreshed successfully.
                                          if (filterRequest != null) {
                                          console.log("3")
                                          var userQuery = new Parse.Query(Parse.User);
                                          var allowedGenders = new Array();
                                          if (filterRequest.get("allowFemale")== true) {
                                          allowedGenders.push("female");
                                          }
                                          if (filterRequest.get("allowMale")== true) {
                                          allowedGenders.push("male");
                                          }
                                          userQuery.containedIn("gender", allowedGenders);
                                          console.log(allowedGenders)
                                          
                                          var allowedSexualities = new Array();
                                          if (filterRequest.get("allowGay") == true) {
                                          allowedSexualities.push("gay");
                                          }
                                          if (filterRequest.get("allowStraight") == true) {
                                          allowedSexualities.push("straight");
                                          }
                                          if (filterRequest.get("allowBi")== true) {
                                          allowedSexualities.push("bisexual");
                                          }
                                          userQuery.containedIn("sexuality", allowedSexualities);
                                          console.log(allowedSexualities)
                                          var allowedRelationshipStatus = new Array();
                                          if (filterRequest.get("allowSingles")== true) {
                                          allowedRelationshipStatus.push("single");
                                          }
                                          if (filterRequest.get("allowTaken")== true) {
                                          allowedRelationshipStatus.push("taken");
                                          }
                                          userQuery.containedIn("relationshipStatus", allowedRelationshipStatus);
                                          
                                          var birthdayUpperBound = filterRequest.get("birthdateUpperBound")
                                          var birthdaylowerBound = filterRequest.get("birthdateLowerBound")
                                          var upperDate = new Date();
                                          upperDate.setDate(upperDate.getDate() - birthdaylowerBound*365.25);
                                          var lowerDate = new Date();
                                          lowerDate.setDate(lowerDate.getDate() - birthdayUpperBound*365.25);
                                          userQuery.greaterThan("birthdate", lowerDate);
                                          userQuery.lessThan("birthdate", upperDate);
                                          
                                          console.log(":::")
                                          console.log(upperDate)
                                          console.log(lowerDate)
                                          
                                          userQuery.withinKilometers("lastLocation", request.object.get("lastLocation"), filterRequest.get("lastLocationRadius") )
                                          console.log("to:::")
                                          userQuery.find({
                                                         success: function(users) {
                                                         console.log("*&*&*&*&*&*")
                                                         console.log(users.length)
                                                         // Do stuff
                                                         var acl = new Parse.ACL();
                                                         for (i = 0; i < users.length; i++) {
                                                         console.log(users[i])
                                                         acl.setReadAccess(users[i], true);
                                                         acl.setWriteAccess(users[i], true);
                                                         }
                                                         acl.setReadAccess(request.user, true)
                                                         acl.setWriteAccess(request.user, true)
                                                         request.object.setACL(acl)
                                                         request.object.save()
                                                         }
                                                         });
                                          }
                                          },
                                          error: function(filterRequest, error) {
                                          // The object was not refreshed successfully.
                                          // error is a Parse.Error with an error code and message.
                                          }
                                          });
                      
                     
                      }
                      var tags = request.object.get("tags");
                      for (i = 0; i < tags.length; i++) {
                      var tagName = tags[i];
                      var tag = Parse.Object.extend("Tag");
                      var query = new Parse.Query(tag);
                      query.equalTo("tagName", tags[i]);
                      query.first({
                                  success: function(object) {
                                  var tagString = tags[i];
                                  if (typeof object != "undefined") {
                                  console.log(tagName);
                                  object.increment("count");
                                  var location = request.object.get("location");
                                  object.set("location", location);
                                  object.set("tagName", tagName);
                                  object.save();
                                  } else {
                                  console.log(tagName);
                                  var object = new tag();
                                  object.set("count", 0);
                                  var location = request.object.get("location");
                                  object.set("location", location);
                                  object.set("tagName", tagName);
                                  object.save();
                                  }
                                  },
                                  error: function(error) {
                                  var tagString = tags[i];
                                  console.log(tagName);
                                  var object = new tag();
                                  object.set("count", 0);
                                  var location = request.object.get("location");
                                  object.set("location", location);
                                  object.set("tagName", tagName);
                                  object.save();
                                  }
                                  });
                      };
                      });


Parse.Cloud.afterSave("EventResponse", function(request) {
                      var respondent = request.object.get("repsondent");
                      if(request.object.existed() == false) {
                      request.object.set("isRead", false);
                      request.object.save();
                      }
                      respondent.fetch({ success: function(respondent) {
                                       
                                       var respondentName = respondent.get("name");
                                       var parentEvent = request.object.get("parentEvent");
                                       
                                       parentEvent.fetch({ success: function(parentEvent) {
                                                         var date = new Date();
                                                         parentEvent.set("lastResponseUpdate", date);
                                                         var user = parentEvent.get("owner");
                                                         var query = new Parse.Query(Parse.Installation);
                                                         query.equalTo("user", user);
                                                         if(request.object.existed() == false) {
                                                         Parse.Push.send({ where: query, data: {
                                                                         alert: respondentName + " responded to your event."
                                                                         }
                                                                         }, {
                                                                         success: function() {
                                                                         
                                                                         },
                                                                         error: function(error) {
                                                                         
                                                                         }
                                                                         });
                                                         }
                                                         
                                                         },
                                                         error: function(myObject, error) {
                                                         
                                                         }
                                                         });
                                       },
                                       error: function(respondent, error) {
                                       
                                       }
                                       });
                      });
