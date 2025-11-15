import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:async';

import 'onboarding_page.dart';



class SplashPage extends StatefulWidget {

  const SplashPage({super.key});



  @override

  State<SplashPage> createState() => _SplashPageState();

}



class _SplashPageState extends State<SplashPage>

    with SingleTickerProviderStateMixin {

  late final AnimationController _controller;

  late final Animation<double> _fadeAnimation;



  // 🌙 Dark navy background to make logo & text pop

  static const Color darkNavy = Color(0xFF0A1A2F);



  @override

  void initState() {

    super.initState();



    _controller = AnimationController(

      vsync: this,

      duration: const Duration(milliseconds: 900),

    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();



    _startSplashSequence();

  }



  Future<void> _startSplashSequence() async {

    await Future.delayed(const Duration(seconds: 2));

    await _checkUserStatus();

  }



  Future<void> _checkUserStatus() async {

    try {

      final userDoc = await FirebaseFirestore.instance

          .collection('users')

          .doc('local_user')

          .get();



      if (!mounted) return;



      final bool isExistingUser =

          userDoc.exists && (userDoc.data()?['name'] as String?)?.isNotEmpty == true;



      if (isExistingUser) {

        Navigator.of(context).pushReplacementNamed('/home');

      } else {

        Navigator.of(context).pushReplacement(

          MaterialPageRoute(builder: (_) => const OnboardingPage()),

        );

      }

    } catch (e) {

      if (!mounted) return;

      Navigator.of(context).pushReplacement(

        MaterialPageRoute(builder: (_) => const OnboardingPage()),

      );

    }

  }



  @override

  void dispose() {

    _controller.dispose();

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: darkNavy,

      body: Center(

        child: FadeTransition(

          opacity: _fadeAnimation,

          child: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              // --- Logo ---

              Image.asset(

                'assets/images/front.png',

                width: 155,

                height: 155,

                fit: BoxFit.contain,

              ),



              const SizedBox(height: 40),



              // --- Gradient Title ---

              ShaderMask(

                shaderCallback: (Rect bounds) {

                  return const LinearGradient(

                    begin: Alignment.topLeft,

                    end: Alignment.bottomRight,

                    colors: [

                      Color(0xFF1D75CF), // deep blue

                      Color(0xFF18C47F), // teal-green

                    ],

                  ).createShader(bounds);

                },

                child: const Text(

                  'FinTrackU',

                  style: TextStyle(

                    fontSize: 38,

                    fontWeight: FontWeight.w900,

                    fontStyle: FontStyle.italic,

                    color: Colors.white,

                    letterSpacing: 1.4,

                  ),

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

}