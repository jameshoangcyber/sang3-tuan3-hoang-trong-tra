import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'feed_screen.dart';
import 'market_screen.dart';
import 'translate_screen.dart';
import 'personal_screen.dart';

class NavigationStateManager {
  static final NavigationStateManager _instance =
      NavigationStateManager._internal();
  factory NavigationStateManager() => _instance;
  NavigationStateManager._internal();

  final Map<int, Widget> _screens = {};
  final Map<int, GlobalKey<State<StatefulWidget>>> _screenKeys = {};

  Widget getScreen(int index) {
    if (!_screens.containsKey(index)) {
      _createScreen(index);
    }
    return _screens[index]!;
  }

  void _createScreen(int index) {
    GlobalKey<State<StatefulWidget>> key = GlobalKey<State<StatefulWidget>>();
    _screenKeys[index] = key;

    switch (index) {
      case 0:
        _screens[index] = HomeScreen(key: key);
        break;
      case 1:
        _screens[index] = FeedScreen(key: key);
        break;
      case 2:
        _screens[index] = MarketScreen(key: key);
        break;
      case 3:
        _screens[index] = TranslateScreen(key: key);
        break;
      case 4:
        _screens[index] = PersonalScreen(key: key);
        break;
      default:
        _screens[index] = HomeScreen(key: key);
    }
  }

  void clearState() {
    _screens.clear();
    _screenKeys.clear();
  }

  void refreshScreen(int index) {
    if (_screens.containsKey(index)) {
      _screens.remove(index);
      _screenKeys.remove(index);
      _createScreen(index);
    }
  }
}
