import 'package:flutter/material.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

   
              Center(
                child: Image.asset(
                  "assets/images/novacane.png",
                  height: 100,
                ),
              ),

              const SizedBox(height: 25),


              const Text(
                "Get Started",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),


              const SizedBox(height: 30),


              TextFormField(
                decoration: InputDecoration(
                  hintText: "Full name",
                  filled: true,
                  fillColor: const Color(0xffEFEDE7),
                  suffixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 15),


              TextFormField(
                decoration: InputDecoration(
                  hintText: "Valid email",
                  filled: true,
                  fillColor: const Color(0xffEFEDE7),
                  suffixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 15),


              TextFormField(
                decoration: InputDecoration(
                  hintText: "Phone number",
                  filled: true,
                  fillColor: const Color(0xffEFEDE7),
                  suffixIcon: const Icon(Icons.phone_android_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 15),

          
              TextFormField(
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Strong password",
                  filled: true,
                  fillColor: const Color(0xffEFEDE7),
                  suffixIcon: const Icon(Icons.visibility_off_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 10),

            
              Row(
                children: [
                  Checkbox(
                    value: false,
                    onChanged: (v) {},
                    visualDensity: VisualDensity.compact,
                  ),
                  const Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: "By checking the box you agree to our ",
                        style: TextStyle(fontSize: 12),
                        children: [
                          TextSpan(
                            text: "Terms and Conditions",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

     
              SizedBox(
                width: 160,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade900,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text(
                    "Register",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already a member? "),
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      "Login in",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
