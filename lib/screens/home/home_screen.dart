import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:xpensia/screens/addExpense.dart';
import 'package:xpensia/screens/home/main_screen.dart';
import 'package:xpensia/screens/stat/stat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index=0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 10,right: 10,bottom: 20),
        child: ClipRRect(
          borderRadius: BorderRadiusGeometry.circular(50),
          child: GNav(
            activeColor: Theme.of(context).colorScheme.onPrimary,
            backgroundColor: Theme.of(context).brightness==Brightness.dark? Theme.of(context).colorScheme.tertiary:Theme.of(context).colorScheme.tertiary,
            haptic: true,
            duration: Duration(milliseconds: 350),
            onTabChange: (value) {
              setState(() {
                index=value;
              });
            },
            tabs: [
              GButton(icon: CupertinoIcons.home, gap: 10, text: "Home"),
              GButton(icon: CupertinoIcons.graph_square, gap: 10, text: "Analysis"),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return Addexpense();
          },));
        },
        shape: CircleBorder(),
        child: Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
              transform: const GradientRotation(pi / 4),
            ),
          ),
          child: Icon(CupertinoIcons.add,color: Colors.white,),
        ),
      ),
      body: index==0? MainScreen():StatScreen(),
    );
  }
}
