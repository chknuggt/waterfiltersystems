import 'package:flutter/material.dart';

class CategoryModel {
  String name;
  String iconPath;
  Color boxColor;

  CategoryModel({
    required this.name,
    required this.iconPath,
    required this.boxColor,
  });

  static List<CategoryModel> getCategories() {
    List<CategoryModel> categories = [];

    categories.add(
      CategoryModel(
        name: 'Reverse Osmosis',
        iconPath: 'assets/icons/reverseOsmosis.svg',
        boxColor: Color(0xff9DCEFF),
      ),
    );

    categories.add(
      CategoryModel(
        name: 'Water Softener',
        iconPath: 'assets/icons/waterSoftener.svg',
        boxColor: Color(0xffEEA4CE),
      ),
    );

    categories.add(
      CategoryModel(
        name: 'Water Filters',
        iconPath: 'assets/icons/waterFilter.svg',
        boxColor: Color(0xff9DCEFF),
      ),
    );

    categories.add(
      CategoryModel(
        name: 'Water Coolers',
        iconPath: 'assets/icons/waterCooler.svg',
        boxColor: Color(0xffEEA4CE),
      ),
    );

    categories.add(
      CategoryModel(
        name: 'Water Makers',
        iconPath: 'assets/icons/waterMaker.svg',
        boxColor: Color(0xff9DCEFF),
      ),
    );

    categories.add(
      CategoryModel(
        name: 'Soda Stream',
        iconPath: 'assets/icons/sodaStream.svg',
        boxColor: Color(0xffEEA4CE),
      ),
    );

    categories.add(
      CategoryModel(
        name: 'Faucets',
        iconPath: 'assets/icons/faucet.svg',
        boxColor: Color(0xff9DCEFF),
      ),
    );

    categories.add(
      CategoryModel(
        name: 'Water Sterilization',
        iconPath: 'assets/icons/waterSterilization.svg',
        boxColor: Color(0xffEEA4CE),
      ),
    );

    categories.add(
      CategoryModel(
        name: 'Water Measuring',
        iconPath: 'assets/icons/waterMeasuring.svg',
        boxColor: Color(0xff9DCEFF),
      ),
    );

    return categories;
  }
}
