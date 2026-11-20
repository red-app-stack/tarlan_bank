class MenuItem {
  final String icon;
  final String title;
  final String? description;
  final List<String>? subItems;
  final String? endElement;
  final String? routeArg;
  final Map<String, dynamic>? args;
  final bool? requiresAuth;

  MenuItem({
    required this.icon,
    required this.title,
    this.description,
    this.subItems,
    this.endElement,
    this.routeArg,
    this.args,
    this.requiresAuth,
  });
}

class MenuSection {
  final String? title;
  final List<MenuItem> items;

  MenuSection({this.title, required this.items});
}
