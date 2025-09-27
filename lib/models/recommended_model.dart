import 'package:flutter/material.dart';

class RecommendationModels {
  String name;
  String iconPath;
  String price;
  String duration;
  String calorie;
  Color boxColor;
  bool viewIsSelected;

  RecommendationModels({
    required this.name,
    required this.iconPath,
    required this.price,
    required this.duration,
    required this.calorie,
    required this.boxColor,
    required this.viewIsSelected,
  });

  static List<RecommendationModels> getRecommendations() {
    List<RecommendationModels> diets = [];

    diets.add(
      RecommendationModels(
        name: 'Water Filter',
        iconPath: 'assets/icons/waterFilter.svg',
        price: 'Medium',
        duration: '1yr',
        calorie: '180kCal',
        viewIsSelected: true,
        boxColor: Color(0xff9DCEFF),
      ),
    );
    diets.add(
      RecommendationModels(
        name: 'water Softener',
        iconPath: 'assets/icons/waterSoftener.svg',
        price: 'Expensive',
        duration: '1yr',
        calorie: '230kCal',
        viewIsSelected: false,
        boxColor: Color(0xffEEA4CE),
      ),
    );

    return diets;
  }
}
