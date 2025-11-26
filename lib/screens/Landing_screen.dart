import 'package:flutter/material.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
    
            Column(
              children: [
                const SizedBox(height: 20),


                Center(
                  child: Image.asset(
                    "assets/images/novacane.png",
                    height:100 , 
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  "Welcome to your safe space",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

    
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 20),
            //   child: Image.asset(
            //     "", 
            //     height: 260,
            //     fit: BoxFit.contain,
            //   ),
            // ),

       
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
             
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade900,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text("Login"),
                  ),

                  const SizedBox(width: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade900,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text("Register"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
