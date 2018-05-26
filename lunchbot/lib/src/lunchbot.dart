import 'dart:async';

import 'package:mattermost_dart/mattermost_dart.dart';
import 'restaurant.dart';

import 'annahotel.dart';
import 'cafecord.dart';
import 'parkcafe.dart';

class LunchBot {
  List<Restaurant> restaurants = [
    new AnnaHotel(),
    new CafeCord(),
    new ParkCafe(),
  ];

  Mattermost _mattermost;

  LunchBot(this._mattermost);

  listen() async {
    await _mattermost.listen(
        (sender, channelId, message) => _parse(sender, channelId, message));

    // Notify we're online via direct message
    _mattermost.postDirectMessage("daniel.cachapa", "ottobot online");

    // Schedule a post at 11:00 the next day
    _schedulePost();
  }

  _schedulePost() {
    var now = new DateTime.now();
    var then = new DateTime(now.year, now.month, now.day + 1, 11);

    var duration = then.difference(now);
    print("Posting menu in [$duration");
    new Timer(duration, () async {
      print("Posting scheduled menu...");

      // Don't post on the weekend
      if (then.weekday <= 5) {
        _postMenu(await _mattermost.getChannelId("lunch-it"));
      }

      // Schedule another post for tomorrow
      _schedulePost();
    });
  }

  _parse(String sender, String channelId, String message) {
    if (message.contains("about")) {
      _postAbout(channelId);
    } else {
      _postMenu(channelId);
    }
  }

  _postMenu(String channelId) async {
    _mattermost.notifyTyping(channelId);

    var weekday = new DateTime.now().weekday;
    var futures = new List<Future<Menu>>();
    restaurants.forEach((r) => futures.add(r.getMenu(weekday)));
    Future.wait(futures).then((menus) {
      var message = new List<Menu>();
      menus.forEach((menu) => message.add(menu));
      _mattermost.post(channelId, message.join("\n---\n"));
    });
  }

  _postHelp(String channelId) {
    var message = "**Currently available commands are:**\n";
    message += "* `lunch` Display lunch menus from nearby restaurants";
    message += "* `about` About ottobot";
    _mattermost.post(channelId, message);
  }

  _postAbout(String channelId) {
    var message = "version `0.1`\n";
    message += "[GitHub](https://github.com/cachapa/ottobot)";
    _mattermost.post(channelId, message);
  }
}