class PopularInstalation {
  String name;
  String iconPath;
  String price;
  String duration;
  bool boxIsSelected;

  PopularInstalation({
    required this.name,
    required this.iconPath,
    required this.price,
    required this.duration,
    required this.boxIsSelected,
  });

  static List<PopularInstalation> getPopularProducts() {
    List<PopularInstalation> popular = [];

    popular.add(
      PopularInstalation(
        name: 'Soda Stream ',
        iconPath: 'assets/icons/sodaStream.svg',
        price: 'Cheap',
        duration: '2wks',
        boxIsSelected: true,
      ),
    );

    popular.add(
      PopularInstalation(
        name: 'Faucets',
        iconPath: 'assets/icons/faucet.svg',
        price: 'Cheap',
        duration: '1yr',
        boxIsSelected: false,
      ),
    );

    return popular;
  }
}
